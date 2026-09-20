# Architecture

## Arquitetura Aprovada — FASE 0 + ETAPA 8 (RBAC)

### Stack Tecnológica

| Camada | Tecnologia |
|--------|-----------|
| Frontend | Next.js, React, TypeScript |
| Backend | FastAPI, Python |
| Database | PostgreSQL (Supabase) |
| Auth | Supabase Auth (email/password) |
| AuthZ | RBAC (Role-Based Access Control) |

### Padrão de Arquitetura

- **Modular Monolith** inicialmente — monolito modular com separação clara de responsabilidades
- **Workers** para processamento assíncrono de dados
- **MarketplaceAdapter** — padrao de adapter para integracao com marketplaces
- **Multi-tenant** desde o primeiro dia — isolamento de dados por organizacao em todas as tabelas
- **RBAC** — Controle de acesso baseado em funcoes com 4 roles e 24 permissoes granulares

### Estrutura Conceitual

```
Frontend → API → Backend Services → PostgreSQL
```

### Fluxo de Autorizacao (RBAC)

```
Request → Authentication (Supabase Auth)
  → Current User (auth.uid)
  → Current Organization (organization_members)
  → Role (roles via organization_members.role_id)
  → Permissions (role_permissions → permissions)
  → Allow / Deny
```

### Estrutura de Processamento de Dados

```
Marketplace → Collector → Queue → Worker → Parser → Validator → Normalizer → Deduplication → Database
```

### Organizacao do Projeto

```
project/
├── app/                        # Frontend (Next.js App Router)
│   ├── dashboard/              # Interface do dashboard
│   │   ├── layout.tsx          # Shell com sidebar (nav filtrada por permissao)
│   │   ├── page.tsx            # Dashboard home
│   │   ├── marketplaces/       # Gestao de marketplaces (requer marketplaces.read)
│   │   ├── pipeline/           # Visualizacao do pipeline (requer research.read)
│   │   ├── reports/            # Relatorios (requer analytics.read)
│   │   ├── team/               # Gestao de membros (requer users.read)
│   │   └── settings/           # Configuracoes (requer organization.read)
│   ├── login/                  # Pagina de login
│   ├── signup/                 # Pagina de cadastro
│   ├── reset-password/         # Recuperacao de senha
│   ├── layout.tsx              # Root layout (AuthProvider)
│   └── page.tsx                # Redirect baseado em auth state
├── backend/                    # Backend (FastAPI)
├── lib/
│   ├── auth-context.tsx       # AuthProvider: sessao, organizacao, role, permissoes
│   ├── permissions.ts         # Centralizacao de permissoes (24 permissoes, 4 roles)
│   ├── supabase/
│   │   ├── client.ts          # Supabase browser client
│   │   └── server.ts          # Supabase SSR client
│   └── types.ts               # TypeScript types do schema
├── components/
│   ├── protected-route.tsx     # Componente de protecao de rota por permissao
│   └── ui/                     # shadcn/ui components
├── middleware.ts               # Protecao de rotas (auth check)
└── docs/                       # Documentacao
```

### RBAC — Roles e Permissoes

#### Roles (4 system roles)

| Role | Descricao | Permissoes |
|------|-----------|------------|
| owner | Proprietario da organizacao | 24 (todas) |
| admin | Administrador da organizacao | 22 (todas exceto organization.delete e roles.manage) |
| analyst | Analista | 12 (ferramentas analiticas, sem gestao de usuarios/org) |
| viewer | Visualizador | 5 (somente leitura) |

#### Permissoes (24 granulares)

| Permissao | Resource | Action |
|-----------|----------|--------|
| dashboard.read | dashboard | read |
| products.read | products | read |
| products.create | products | create |
| products.update | products | update |
| products.delete | products | delete |
| research.read | research | read |
| research.create | research | create |
| opportunities.read | opportunities | read |
| competitors.read | competitors | read |
| analytics.read | analytics | read |
| pricing.read | pricing | read |
| pricing.calculate | pricing | calculate |
| marketplaces.read | marketplaces | read |
| marketplaces.manage | marketplaces | manage |
| users.read | users | read |
| users.invite | users | invite |
| users.update | users | update |
| users.remove | users | remove |
| roles.read | roles | read |
| roles.manage | roles | manage |
| organization.read | organization | read |
| organization.update | organization | update |
| organization.delete | organization | delete |
| audit.read | audit | read |

### Relacionamento User → Organization → Role → Permissions

```
User (auth.users)
  ↓
users (perfil da aplicacao)
  ↓
organization_members (vinculo user ↔ org com role)
  ↓
organizations (tenant boundary)
  ↓
roles (owner, admin, analyst, viewer)
  ↓
role_permissions (N:N)
  ↓
permissions (24 permissoes granulares)
```

Um usuario pode pertencer a multiplas organizacoes com roles diferentes.

### Organizacao Ativa

O `AuthProvider` carrega a primeira organizacao do usuario automaticamente.
Toda operacao de negocio respeita a organizacao ativa.
No futuro, o usuario podera alternar entre organizacoes.

### Principios

1. **Separacao clara de responsabilidades** — cada modulo tem um proposito unico
2. **Seguranca** — RLS habilitado em todas as tabelas, credenciais nunca expostas ao cliente
3. **Deny by default** — se uma permissao nao existe, o acesso e negado
4. **Escalabilidade** — multi-tenant desde o inicio, adapters extensveis para novos marketplaces
5. **Manutenibilidade** — codigo limpo, modular, sem acoplamento desnecessario
6. **Sem funcionalidades nao solicitadas** — apenas a fundacao foi construida

### Backend (ETAPA 9 — Fundacao da API)

O backend FastAPI foi reestruturado com camadas claras:

```
backend/app/
├── core/
│   ├── config.py        # Settings centralizadas (env vars, CORS, pool)
│   ├── database.py      # SQLAlchemy async engine + session factory
│   ├── security.py      # Verificacao de JWT do Supabase (JWKS + fallback)
│   ├── tenant.py        # TenantContext: resolve org + role + permissoes
│   ├── deps.py          # Dependencies: CurrentUser, TenantCtx, require_permission()
│   ├── errors.py        # AppError hierarquia + handlers padronizados
│   ├── middleware.py    # Request ID + logging estruturado por request
│   └── logging.py       # structlog com context vars
├── models/              # ORM: Organization, User, Role, OrganizationMember,
│                        #   Marketplace, MarketplaceAccount, CollectionJob
├── schemas/             # Pydantic: common, organization, user, marketplace, job
├── services/            # BaseService (CRUD scoped), CollectionService,
│                        #   MarketplaceAccountService, MemberService
├── adapters/            # MarketplaceAdapter (ABC) + Registry + MercadoLivre placeholder
├── workers/             # Worker (ABC) + WorkerDispatcher (registry + router)
└── api/v1/
    ├── router.py
    └── endpoints/       # organizations, marketplace_accounts, collection_jobs, members
```

#### Fluxo de uma Request

```
Request → CORS → RequestContextMiddleware (request ID + logging)
  → get_current_user (verifica JWT do Supabase)
  → get_tenant_context (resolve X-Organization-Id → TenantContext)
  → require_permission("permission.name") (RBAC check)
  → Endpoint → Service → SQLAlchemy → PostgreSQL
  → Response (com X-Request-ID header)
```

#### Multi-Tenancy no Backend

- O header `X-Organization-Id` identifica a organizacao ativa
- `TenantContext` carrega user_id, org_id, role_name, e permissoes
- `BaseService` filtra automaticamente por `organization_id`
- Se o usuario nao for membro ativo da org → `403 Forbidden`

#### Autorizacao no Backend

- `require_permission("perm")` e uma dependency do FastAPI
- Verifica `TenantContext.has_permission()` antes de executar o endpoint
- Deny by default: sem permissao = `403 Forbidden`

#### Error Handling Padronizado

Todos os erros retornam `{ "code", "message", "details" }`:
- `AppError` → base para todos os erros de negocio
- `NotFoundError`, `ForbiddenError`, `UnauthorizedError`, `ConflictError`
- Handlers para `RequestValidationError` e `IntegrityError`
- Handler global para excecoes nao tratadas (`500 internal_error`)

### Decisoes Pendentes

- [DECISAO DO PRODUTO] Estrategia de deploy do backend FastAPI
- [DECISAO DO PRODUTO] Estrategia de deploy dos workers assincronos
- [DECISAO DO PRODUTO] Monitoramento e observabilidade
- [DECISAO DO PRODUTO] Alternancia entre multiplas organizacoes (switcher)
- [DECISAO DO PRODUTO] Envio de emails de convite
