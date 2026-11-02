# Base de dados dos projetos de Aisha

Estado: esquema aplicado em 2 novembro 2026 à base de dados Supabase existente Stellamus, organização UniOrbis. Não foram criadas novas instâncias, organizações ou subscrições.

As tabelas `docs` e `admins` existentes não foram alteradas. As sete tabelas novas têm prefixo `aisha_` e RLS ativado.

- `aisha_projects`: registo público dos quatro projetos, sem dados pessoais.
- `aisha_project_admins`: acesso administrativo ao feedback por projeto; só membros já configurados como administradores da Stellamus foram associados.
- `aisha_user_state`: progresso explícito do utilizador por projeto e chave.
- `aisha_simulation_runs`: percursos e estado de simulação privados.
- `aisha_simulation_turns`: decisões de cada percurso; a chave estrangeira inclui o utilizador e o projeto.
- `aisha_feedback`: feedback privado do autor, legível pelos administradores desse projeto.
- `aisha_project_releases`: catálogo de versões; só versões publicadas são legíveis sem sessão.

O adapter em `backend/project-store.js` recebe um cliente Supabase autenticado. A configuração pública usa uma publishable key: não é uma service_role key. O adapter não envia automaticamente o armazenamento local nem ativa recolha de dados na SENSORA. A interface pública existente continua a funcionar localmente; login e botões de sincronização ainda precisam de ser ligados e testados no fluxo de autenticação do endereço definitivo.

`schema.sql` é a fonte do esquema inicial aplicado. Não o executar uma segunda vez numa base já preparada. A migração remota chama-se `aisha_projects_foundation`.

`tests/rls.sql` usa uma transação e termina com rollback. Foi executado com sucesso: leitura/edição pelo dono, isolamento de outro utilizador, rejeição de insert em nome de terceiro e bloqueio de acesso anónimo aos estados privados.

A autenticação já existente da Stellamus usa email. Não foram enviadas mensagens de login nem criadas contas de utilizadores por este trabalho.

## Avisos anteriores à alteração

O verificador de segurança da Supabase já assinalava antes desta alteração:
- Tabela `admins` com RLS e sem política de acesso direto (compatível com acesso apenas pela função administrativa).
- Função administrativa `is_admin()` com SECURITY DEFINER: rever separadamente sem quebrar as políticas da aplicação existente. https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable
- Proteção contra palavras-passe comprometidas desligada. https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

O verificador não identificou novos alertas nas tabelas `aisha_`.

## IA

Não foi configurada nem cobrada uma API de IA. Ter base de dados não ativa o motor de simulação livre. Essa ligação requer credenciais de um fornecedor no servidor e limites de utilização, nunca uma chave secreta no navegador.
