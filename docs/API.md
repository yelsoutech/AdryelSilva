# API

## Visão Geral

A API é construída com FastAPI (Python). O prefixo base é `/api/v1`.

## Autenticação

Todas as rotas da API exigem um token JWT do Supabase no header `Authorization: Bearer <token>`.

O token é verificado contra as chaves públicas do Supabase (JWKS). Após a verificação,
o backend resolve a organização ativa do usuário via header `X-Organization-Id` e carrega
suas permissões (RBAC) do banco de dados.

## Multi-Tenancy

Cada request deve incluir o header `X-Organization-Id` com o UUID da organização ativa.
O backend verifica se o usuário é membro ativo da organização e carrega suas permissões.
Todos os dados retornados são automaticamente filtrados por `organization_id`.

## Autorização (RBAC)

Cada endpoint declara a permissão necessária via `require_permission("permission.name")`.
Se o usuário não tiver a permissão, recebe `403 Forbidden`.

| Permissão | Descrição |
|-----------|-----------|
| `organization.read` | Ver dados da organização |
| `organization.update` | Atualizar dados da organização |
| `marketplaces.read` | Ver contas de marketplace |
| `marketplaces.manage` | Criar/editar/remover contas de marketplace |
| `users.read` | Ver membros da organização |
| `users.update` | Alterar role de membros |
| `users.remove` | Remover membros |
| `roles.read` | Ver roles e permissões |

## Endpoints Atuais

### Health

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/health` | Health check do serviço (sem auth) |

### Organizations

| Método | Rota | Permissão | Descrição |
|--------|------|-----------|-----------|
| GET | `/api/v1/organizations/current` | `organization.read` | Dados da organização ativa |

### Marketplace Accounts

| Método | Rota | Permissão | Descrição |
|--------|------|-----------|-----------|
| GET | `/api/v1/marketplace-accounts` | `marketplaces.read` | Lista contas (paginado) |
| POST | `/api/v1/marketplace-accounts` | `marketplaces.manage` | Cria uma conta |
| GET | `/api/v1/marketplace-accounts/{id}` | `marketplaces.read` | Detalha uma conta |
| PATCH | `/api/v1/marketplace-accounts/{id}` | `marketplaces.manage` | Atualiza uma conta |
| DELETE | `/api/v1/marketplace-accounts/{id}` | `marketplaces.manage` | Remove uma conta |

### Collection Jobs

| Método | Rota | Permissão | Descrição |
|--------|------|-----------|-----------|
| GET | `/api/v1/collection-jobs` | `marketplaces.read` | Lista jobs (paginado) |
| POST | `/api/v1/collection-jobs` | `marketplaces.manage` | Enfileira um job |
| GET | `/api/v1/collection-jobs/{id}` | `marketplaces.read` | Detalha um job |

### Members

| Método | Rota | Permissão | Descrição |
|--------|------|-----------|-----------|
| GET | `/api/v1/members` | `users.read` | Lista membros da org |
| GET | `/api/v1/members/roles` | `roles.read` | Lista roles disponíveis |
| PATCH | `/api/v1/members/{id}/role` | `users.update` | Altera role de um membro |
| DELETE | `/api/v1/members/{id}` | `users.remove` | Remove um membro |

## Estrutura

```
backend/app/
├── core/
│   ├── config.py              # Settings (env vars)
│   ├── database.py            # SQLAlchemy async engine + session
│   ├── security.py            # Supabase JWT verification (JWKS)
│   ├── tenant.py              # TenantContext resolution
│   ├── deps.py                # FastAPI dependencies (auth, tenant, permissions)
│   ├── errors.py              # Standardized error responses
│   ├── middleware.py          # Request ID + structured logging
│   └── logging.py             # structlog configuration
├── models/                    # SQLAlchemy ORM models
├── schemas/                   # Pydantic request/response schemas
├── services/                  # Business logic (BaseService, CollectionService, etc.)
├── adapters/                 # Marketplace adapter pattern (base + registry)
├── workers/                   # Async worker base + dispatcher
└── api/v1/
    ├── router.py              # Agrega todos os routers
    └── endpoints/
        ├── organizations.py
        ├── marketplace_accounts.py
        ├── collection_jobs.py
        └── members.py
```

## Resposta de Erro Padronizada

Todos os erros seguem o formato:

```json
{
  "code": "error_code",
  "message": "Human-readable message",
  "details": {}
}
```

| Code | Status | Descrição |
|------|--------|-----------|
| `unauthorized` | 401 | Token ausente ou inválido |
| `forbidden` | 403 | Sem permissão para a ação |
| `not_found` | 404 | Recurso não encontrado |
| `conflict` | 409 | Violação de constraint |
| `validation_failed` | 422 | Validação de request falhou |
| `internal_error` | 500 | Erro inesperado |

## Paginação

Endpoints de listagem aceitam `page` (default 1) e `page_size` (default 20, max 100).

## Documentação Interativa

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

## Decisões Pendentes

- [DECISÃO DO PRODUTO] Rate limiting
- [DECISÃO DO PRODUTO] Webhooks para notificação de eventos
- [DECISÃO DO PRODUTO] Estratégia de deploy do backend FastAPI
- [DECISÃO DO PRODUTO] Estratégia de deploy dos workers assíncronos
