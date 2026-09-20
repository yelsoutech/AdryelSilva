# Database

## Visao Geral

O banco de dados e PostgreSQL, hospedado no Supabase. O schema e multi-tenant desde o primeiro dia — toda tabela de dados inclui uma coluna `organization_id` para isolamento.

## Migracoes

### Migracoes de Schema (Dominios)

1. `20260901232400_create_identity_domain.sql` — organizations, users, roles, permissions, role_permissions, organization_members
2. `20260901232427_create_marketplace_domain.sql` — marketplaces, marketplace_accounts, marketplace_credentials, encryption_keys
3. `20260901232453_create_products_domain.sql` — categories, brands, sellers, products, product_listings
4. `20260901232529_create_research_historical_analytics_domains.sql` — keywords, searches, search_results, price_history, metrics_history, product_metrics, market_metrics, competitor_metrics, opportunities, opportunity_scores
5. `20260901232602_create_pricing_and_system_domains.sql` — pricing_scenarios, costs, fees, taxes, shipping_costs, ad_costs, alerts, notifications, audit_logs, jobs

### Migracoes de Auth e RBAC

6. `20260901232529_create_auth_triggers.sql` — Trigger `handle_new_user()` que cria perfil + organizacao + membership automaticamente no signup
7. `20260902184542_create_rbac_foundation.sql` — Seeds 24 permissoes, mapeia role→permissions, cria `organization_invitations`, funcoes `user_has_permission()` e `user_org_permissions()`

## Tabelas de Identidade e RBAC

### organizations

Tenant boundary principal.

| Coluna | Tipo | Descricao |
|--------|------|-----------|
| id | uuid (PK) | Identificador unico |
| name | text | Nome de exibicao |
| slug | text (unique) | Identificador URL-friendly |
| status | text | 'active', 'suspended', 'deleted' |
| created_at | timestamptz | Data de criacao |
| updated_at | timestamptz | Ultima atualizacao (auto) |

### users

Perfil da aplicacao (separado de auth.users).

| Coluna | Tipo | Descricao |
|--------|------|-----------|
| id | uuid (PK, FK → auth.users) | Link para Supabase Auth |
| email | text (unique) | Email do usuario |
| full_name | text | Nome completo |
| avatar_url | text | URL do avatar |
| status | text | 'active', 'suspended' |
| created_at | timestamptz | Data de criacao |
| updated_at | timestamptz | Ultima atualizacao (auto) |

### roles

Funcoes do sistema (4 system roles).

| Coluna | Tipo | Descricao |
|--------|------|-----------|
| id | uuid (PK) | Identificador unico |
| name | text (unique) | 'owner', 'admin', 'analyst', 'viewer' |
| description | text | Descricao da funcao |
| is_system | boolean | Roles do sistema nao podem ser deletadas |
| created_at | timestamptz | Data de criacao |

### permissions

24 permissoes granulares.

| Coluna | Tipo | Descricao |
|--------|------|-----------|
| id | uuid (PK) | Identificador unico |
| name | text (unique) | e.g. 'products.read' |
| description | text | Descricao |
| resource | text | Recurso (e.g. 'products') |
| action | text | Acao (e.g. 'read', 'create', 'manage') |
| created_at | timestamptz | Data de criacao |

### role_permissions

N:N entre roles e permissions.

| Coluna | Tipo | Descricao |
|--------|------|-----------|
| role_id | uuid (FK → roles) | Role |
| permission_id | uuid (FK → permissions) | Permissao |
| PK | (role_id, permission_id) | Chave composta |

### organization_members

Vincula usuarios a organizacoes com role.

| Coluna | Tipo | Descricao |
|--------|------|-----------|
| id | uuid (PK) | Identificador unico |
| organization_id | uuid (FK → organizations) | Organizacao |
| user_id | uuid (FK → users) | Usuario |
| role_id | uuid (FK → roles) | Role do usuario na org |
| status | text | 'active', 'invited', 'removed' |
| invited_by | uuid (FK → users, nullable) | Quem convidou |
| joined_at | timestamptz | Data de entrada |
| Unique | (organization_id, user_id) | Um membro ativo por org |

### organization_invitations

Convites pendentes para novos membros.

| Coluna | Tipo | Descricao |
|--------|------|-----------|
| id | uuid (PK) | Identificador unico |
| organization_id | uuid (FK → organizations) | Organizacao |
| email | text | Email do convidado |
| role_id | uuid (FK → roles) | Role atribuida |
| status | text | 'pending', 'accepted', 'expired', 'revoked' |
| invited_by | uuid (FK → users) | Quem convidou |
| token | uuid | Token unico de aceitacao |
| expires_at | timestamptz | Expiracao (default 7 dias) |
| accepted_at | timestamptz | Quando aceito |
| Unique | (organization_id, email) WHERE pending | Um convite pendente por email |

## Funcoes de Seguranca (SECURITY DEFINER)

### user_org_member(org_id uuid) → boolean

Verifica se o usuario autenticado e membro ativo de uma organizacao.

### user_org_role(org_id uuid) → text

Retorna o nome da role do usuario autenticado em uma organizacao.

### user_has_permission(org_id uuid, perm_name text) → boolean

Verifica se o usuario autenticado tem uma permissao especifica em uma organizacao. Consulta: `organization_members → role_permissions → permissions`.

### user_org_permissions(org_id uuid) → TABLE(name text)

Retorna todas as permissoes do usuario autenticado em uma organizacao.

## RLS Policies

### organization_members (RBAC-reforcoado)

- **SELECT**: membros podem ver membros da sua org (`user_org_member`)
- **INSERT**: requer `users.invite` (`user_has_permission(organization_id, 'users.invite')`)
- **UPDATE**: requer `users.update` (`user_has_permission(organization_id, 'users.update')`)
- **DELETE**: requer `users.remove` (`user_has_permission(organization_id, 'users.remove')`)

### organization_invitations

- **SELECT**: membros da org podem ver convites
- **INSERT**: requer `users.invite`
- **UPDATE**: membros da org podem atualizar
- **DELETE**: requer `users.remove`

### Todas as tabelas de negocio

- 4 politicas por tabela (SELECT, INSERT, UPDATE, DELETE)
- Todas usam `user_org_member(organization_id)` para isolamento
- Scope: `TO authenticated`

## Trigger de Signup

`handle_new_user()` — executado apos INSERT em `auth.users`:

1. Cria perfil em `users` (id, email, full_name dos metadados)
2. Cria organizacao padrao (nome dos metadados ou derivado do email)
3. Cria `organization_members` com role 'owner'

## Indexes

- `organization_members`: organization_id, user_id, role_id
- `organization_invitations`: organization_id, email, token, status
- `role_permissions`: role_id, permission_id
- `permissions`: resource, action
- `organizations`: slug, status
- `users`: email, status

## Decisoes Pendentes

- [DECISAO DO PRODUTO] Estrategia de retencao de dados raw vs. normalizados
- [DECISAO DO PRODUTO] Politicas de limpeza / arquivamento de dados antigos
- [DECISAO DO PRODUTO] Estrategia de particionamento por organizacao para escala
- [DECISAO DO PRODUTO] Envio de emails de convite
