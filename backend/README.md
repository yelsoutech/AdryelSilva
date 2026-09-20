# Marketplace Intelligence — Backend

FastAPI + Python backend for the Marketplace Intelligence platform.

## Architecture

```
app/
├── main.py              # FastAPI application entrypoint
├── core/
│   ├── config.py        # Settings (env-based)
│   ├── database.py      # Async SQLAlchemy engine & session
│   ├── security.py      # Supabase JWT verification (JWKS + fallback)
│   ├── tenant.py        # TenantContext: resolve org + role + permissions
│   ├── deps.py          # FastAPI dependencies (auth, tenant, permissions)
│   ├── errors.py        # Standardized error responses + handlers
│   ├── middleware.py    # Request ID + structured logging
│   └── logging.py       # Structured logging (structlog)
├── api/v1/
│   ├── router.py         # Aggregates all endpoint routers
│   └── endpoints/        # REST endpoints (organizations, marketplace_accounts,
│                         #   collection_jobs, members)
├── models/              # SQLAlchemy ORM models (Organization, User, Role,
│                        #   OrganizationMember, Marketplace, MarketplaceAccount, CollectionJob)
├── schemas/             # Pydantic request/response schemas
├── services/            # Business logic (BaseService, CollectionService,
│                        #   MarketplaceAccountService, MemberService)
├── adapters/            # Marketplace integration adapters
│   ├── base.py          # Abstract MarketplaceAdapter interface
│   ├── mercadolivre.py  # Mercado Livre adapter (structural placeholder)
│   └── registry.py      # Adapter registry for multi-marketplace support
└── workers/             # Async job processing workers
    ├── base.py          # Abstract Worker interface
    └── dispatcher.py    # Worker dispatcher (registry + router by job_type)
```

## Authentication & Authorization

- **Auth**: Supabase JWT verified via JWKS (with fallback to Supabase user API)
- **Multi-tenancy**: `X-Organization-Id` header resolves the active organization
- **RBAC**: Each endpoint declares a required permission via `require_permission()`
- **Deny by default**: Missing permission = `403 Forbidden`

## Request Flow

```
Request → CORS → RequestContextMiddleware (request ID + logging)
  → get_current_user (verify Supabase JWT)
  → get_tenant_context (resolve X-Organization-Id → TenantContext)
  → require_permission("permission.name") (RBAC check)
  → Endpoint → Service → SQLAlchemy → PostgreSQL
  → Response (with X-Request-ID header)
```

## Error Handling

All errors return `{ "code", "message", "details" }`:

| Code | Status | Description |
|------|--------|-------------|
| `unauthorized` | 401 | Missing or invalid token |
| `forbidden` | 403 | No permission for the action |
| `not_found` | 404 | Resource not found |
| `conflict` | 409 | Database constraint violation |
| `validation_failed` | 422 | Request validation failed |
| `internal_error` | 500 | Unexpected error |

## Data Pipeline

```
Marketplace → Collector → Queue → Worker → Parser → Validator → Normalizer → Database
```

- **Collector**: Fetches raw data from marketplace APIs via adapters
- **Queue**: Collection jobs in `pending` status
- **Worker**: Picks up jobs, runs the pipeline stages
- **Parser**: Extracts structured fields from raw payloads
- **Validator**: Ensures data integrity
- **Normalizer**: Maps marketplace-specific fields to a unified schema
- **Database**: Stores raw and normalized data

## Running

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload
```

API docs available at `http://localhost:8000/docs`.
