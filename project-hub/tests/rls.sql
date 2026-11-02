begin;
select set_config('aisha.test_owner',(select u.id::text from auth.users u join public.admins a on lower(a.email)=lower(u.email) limit 1),true);
do $$ begin if nullif(current_setting('aisha.test_owner',true),'') is null then raise exception 'No configured project owner available for transactional test'; end if; end $$;
select set_config('aisha.test_key','__rls_probe_'||gen_random_uuid()::text,true);
insert into public.aisha_user_state(user_id,project_slug,state_key,payload)
values(current_setting('aisha.test_owner')::uuid,'lifelab',current_setting('aisha.test_key'),'{"test":true}');
set local role authenticated;
select set_config('request.jwt.claim.sub',current_setting('aisha.test_owner'),true);
do $$ begin
 if (select count(*) from public.aisha_user_state where state_key=current_setting('aisha.test_key'))<>1 then raise exception 'Owner read failed'; end if;
 update public.aisha_user_state set payload='{"test":"updated"}' where state_key=current_setting('aisha.test_key');
 if not found then raise exception 'Owner update failed'; end if;
end $$;
select set_config('request.jwt.claim.sub',gen_random_uuid()::text,true);
do $$ begin
 if exists(select 1 from public.aisha_user_state where state_key=current_setting('aisha.test_key')) then raise exception 'Cross-user read allowed'; end if;
 update public.aisha_user_state set payload='{}' where state_key=current_setting('aisha.test_key');
 if found then raise exception 'Cross-user update allowed'; end if;
 begin
  insert into public.aisha_user_state(user_id,project_slug,state_key,payload)
  values(current_setting('aisha.test_owner')::uuid,'lifelab',current_setting('aisha.test_key')||'_forged','{}');
  raise exception 'Forged ownership insert allowed';
 exception when insufficient_privilege then null;
 end;
end $$;
set local role anon;
do $$ begin
 if (select count(*) from public.aisha_projects)<>4 then raise exception 'Public registry read failed'; end if;
 begin
  perform count(*) from public.aisha_user_state;
  raise exception 'Anonymous access to private state allowed';
 exception when insufficient_privilege then null;
 end;
end $$;
rollback;
select 'PASS: owner read/update, other-user isolation, forged ownership rejected, anonymous state blocked; fixtures rolled back' as verification;
