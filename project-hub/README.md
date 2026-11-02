# Projetos de Aisha Ismail — base partilhada e código

Este ramo acrescenta o portefólio e as fontes dos projetos sem alterar os ficheiros da aplicação Stellamus no topo do repositório.

## Pastas

- `portfolio/`: portefólio completo, quatro páginas de projeto, demo de serviços e LifeLab geral embebido.
- `lifelab/`: protótipo geral independente com vida guiada.
- `sensora-social/`: apresentação de investigação, sem alegações de eficácia ou novidade comprovada.
- `conduzpt/`: projeto Godot 4 Chelas Protótipo 02 e mapa incluído.
- `database/`: esquema realmente aplicado na Supabase e notas de acesso.
- `backend/`: configuração pública e adapter de persistência autenticada.
- `tests/`: teste de isolamento RLS executado com rollback.

A Stellamus mantém-se nos ficheiros já existentes na raiz. Não foi alterada a versão pública nem a configuração de GitHub Pages.

## Supabase

Sete tabelas novas com prefixo `aisha_` na base existente Stellamus (organização UniOrbis). Os quatro projetos estão registados. Dados privados são protegidos por utilizador. Não houve criação de instâncias ou contratação de serviços pagos. `docs` e `admins` mantêm-se intactas.

Criar as tabelas não liga automaticamente a IA nem a sincronização da interface. Não foi introduzida uma API key de IA. Não existem segredos de servidor neste ramo. A publishable key da Supabase foi incluída intencionalmente para o cliente e depende das políticas RLS.

A configuração pública e o adapter permitem implementar login e gravação explícita. O frontend atual continua a guardar o progresso localmente; não exporta automaticamente dados pessoais para a base.

## Verificação realizada

- Migração `aisha_projects_foundation`: aplicada com sucesso.
- Sete tabelas com RLS.
- Teste em transação: dono lê/edita; terceiro não lê/edita; insert em nome de terceiro recusado; acesso anónimo ao estado privado bloqueado.
- Verificador Supabase: sem novos alertas nas tabelas adicionadas; avisos anteriores documentados em `database/README.md`.
- Portefólio: navegação, filtros, links, vista desktop e largura de telemóvel testados no trabalho anterior.

O ramo é uma organização inicial do código. Não o confundir com repositórios independentes ou uma publicação de todas as aplicações em produção.
