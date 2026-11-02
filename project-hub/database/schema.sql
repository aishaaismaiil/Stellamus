-- Additive schema for Aisha's projects. Existing Stellamus docs/admins are untouched.
create table public.aisha_projects (
 slug text primary key check (slug ~ '^[a-z][a-z0-9-]{1,48}$'),
 name text not null check (length(name) between 1 and 100),
 status text not null check(status in ('development','prototype','research','active','archived')),
 description text not null default '' check(length(description)<=2000),
 site_url text check(site_url is null or site_url ~ '^https://'),
 is_public boolean not null default false,
 created_at timestamptz not null default now()
);
create table public.aisha_project_admins (
 project_slug text not null references public.aisha_projects(slug) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 primary key(project_slug,user_id)
);
create index aisha_project_admins_user_idx on public.aisha_project_admins(user_id,project_slug);
create table public.aisha_user_state (
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 project_slug text not null references public.aisha_projects(slug),
 state_key text not null check(length(state_key) between 1 and 100),
 payload jsonb not null default '{}'::jsonb check(octet_length(payload::text)<=524288),
 updated_at timestamptz not null default now(),
 primary key(user_id,project_slug,state_key)
);
create index aisha_user_state_project_idx on public.aisha_user_state(project_slug);
create table public.aisha_simulation_runs (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 project_slug text not null references public.aisha_projects(slug),
 title text not null check(length(title) between 1 and 200),
 mode text not null check(mode in ('guided','free','driving')),
 state jsonb not null default '{}'::jsonb check(octet_length(state::text)<=1048576),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(id,user_id,project_slug)
);
create index aisha_runs_owner_idx on public.aisha_simulation_runs(user_id,project_slug,updated_at desc);
create index aisha_runs_project_idx on public.aisha_simulation_runs(project_slug);
create table public.aisha_simulation_turns (
 id uuid primary key default gen_random_uuid(),
 run_id uuid not null,
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 project_slug text not null,
 turn_number integer not null check(turn_number>=0),
 payload jsonb not null check(octet_length(payload::text)<=131072),
 created_at timestamptz not null default now(),
 foreign key(run_id,user_id,project_slug) references public.aisha_simulation_runs(id,user_id,project_slug) on delete cascade,
 unique(run_id,turn_number)
);
create index aisha_turns_owner_idx on public.aisha_simulation_turns(user_id,project_slug);
create table public.aisha_feedback (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 project_slug text not null references public.aisha_projects(slug),
 category text not null default 'feedback' check(category in ('feedback','bug','testing')),
 message text not null check(length(message) between 5 and 3000),
 rating smallint check(rating between 1 and 5),
 created_at timestamptz not null default now()
);
create index aisha_feedback_owner_idx on public.aisha_feedback(user_id,project_slug);
create index aisha_feedback_project_idx on public.aisha_feedback(project_slug,created_at desc);
create table public.aisha_project_releases (
 id uuid primary key default gen_random_uuid(),
 project_slug text not null references public.aisha_projects(slug),
 version text not null check(length(version) between 1 and 80),
 notes text not null default '' check(length(notes)<=5000),
 download_url text check(download_url is null or download_url ~ '^https://'),
 published_at timestamptz,
 created_at timestamptz not null default now(),
 unique(project_slug,version)
);
create index aisha_releases_project_idx on public.aisha_project_releases(project_slug,published_at desc);

alter table public.aisha_projects enable row level security;
alter table public.aisha_project_admins enable row level security;
alter table public.aisha_user_state enable row level security;
alter table public.aisha_simulation_runs enable row level security;
alter table public.aisha_simulation_turns enable row level security;
alter table public.aisha_feedback enable row level security;
alter table public.aisha_project_releases enable row level security;

-- Explicit grants: new tables are not assumed safe by default.
revoke all on public.aisha_projects,public.aisha_project_admins,public.aisha_user_state,public.aisha_simulation_runs,public.aisha_simulation_turns,public.aisha_feedback,public.aisha_project_releases from anon,authenticated;
grant select on public.aisha_projects,public.aisha_project_releases to anon,authenticated;
grant select on public.aisha_project_admins to authenticated;
grant select,insert,update,delete on public.aisha_user_state,public.aisha_simulation_runs,public.aisha_simulation_turns to authenticated;
grant select,insert,delete on public.aisha_feedback to authenticated;
grant all on public.aisha_projects,public.aisha_project_admins,public.aisha_user_state,public.aisha_simulation_runs,public.aisha_simulation_turns,public.aisha_feedback,public.aisha_project_releases to service_role;

create policy aisha_public_projects on public.aisha_projects for select to anon,authenticated using(is_public);
create policy aisha_admin_self_read on public.aisha_project_admins for select to authenticated using(user_id=(select auth.uid()));
create policy aisha_state_read on public.aisha_user_state for select to authenticated using(user_id=(select auth.uid()));
create policy aisha_state_insert on public.aisha_user_state for insert to authenticated with check(user_id=(select auth.uid()));
create policy aisha_state_update on public.aisha_user_state for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy aisha_state_delete on public.aisha_user_state for delete to authenticated using(user_id=(select auth.uid()));
create policy aisha_runs_read on public.aisha_simulation_runs for select to authenticated using(user_id=(select auth.uid()));
create policy aisha_runs_insert on public.aisha_simulation_runs for insert to authenticated with check(user_id=(select auth.uid()));
create policy aisha_runs_update on public.aisha_simulation_runs for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy aisha_runs_delete on public.aisha_simulation_runs for delete to authenticated using(user_id=(select auth.uid()));
create policy aisha_turns_read on public.aisha_simulation_turns for select to authenticated using(user_id=(select auth.uid()));
create policy aisha_turns_insert on public.aisha_simulation_turns for insert to authenticated with check(user_id=(select auth.uid()));
create policy aisha_turns_update on public.aisha_simulation_turns for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));
create policy aisha_turns_delete on public.aisha_simulation_turns for delete to authenticated using(user_id=(select auth.uid()));
create policy aisha_feedback_read on public.aisha_feedback for select to authenticated using(
 user_id=(select auth.uid()) or exists(select 1 from public.aisha_project_admins a where a.project_slug=aisha_feedback.project_slug and a.user_id=(select auth.uid()))
);
create policy aisha_feedback_insert on public.aisha_feedback for insert to authenticated with check(user_id=(select auth.uid()));
create policy aisha_feedback_delete on public.aisha_feedback for delete to authenticated using(user_id=(select auth.uid()));
create policy aisha_public_releases on public.aisha_project_releases for select to anon,authenticated using(
 published_at is not null and published_at<=now() and exists(select 1 from public.aisha_projects p where p.slug=project_slug and p.is_public)
);

insert into public.aisha_projects(slug,name,status,description,site_url,is_public) values
 ('stellamus','Stellamus','development','Comunidade, atividades e oportunidades.','https://aishaaismaiil.github.io/Stellamus/',true),
 ('lifelab','LifeLab','prototype','Simulador geral de decisões de vida e guia de próximos passos.',null,true),
 ('sensora','SENSORA Social','research','Investigação e cocriação sobre participação social de pessoas surdocegas.',null,true),
 ('conduzpt','ConduzPT','prototype','Protótipos de aprendizagem de condução em contexto urbano.',null,true);
-- Grant project feedback access only to already configured Stellamus administrators.
insert into public.aisha_project_admins(project_slug,user_id)
select p.slug,u.id from public.aisha_projects p cross join auth.users u
join public.admins a on lower(a.email)=lower(u.email)
on conflict do nothing;
