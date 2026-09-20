"""Shared FastAPI dependencies: database session, current user, tenant context, permission checks."""

from typing import Annotated
from uuid import UUID

from fastapi import Depends, Header, Query
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.errors import ForbiddenError, UnauthorizedError
from app.core.logging import logger
from app.core.security import verify_supabase_token
from app.core.tenant import TenantContext, resolve_tenant_context

DbSession = Annotated[AsyncSession, Depends(get_db)]


async def get_current_user(
    authorization: str | None = Header(None),
) -> dict:
    """Extract and verify the Supabase JWT from the Authorization header."""
    if not authorization or not authorization.startswith("Bearer "):
        raise UnauthorizedError("Missing or invalid Authorization header")
    token = authorization.removeprefix("Bearer ").strip()
    try:
        payload = await verify_supabase_token(token)
    except Exception:
        raise UnauthorizedError("Invalid or expired token")

    user_id = payload.get("sub")
    email = payload.get("email", "")
    if not user_id:
        raise UnauthorizedError("Token payload missing user ID")
    return {"id": UUID(user_id), "email": email, "raw": payload}


CurrentUser = Annotated[dict, Depends(get_current_user)]


async def get_tenant_context(
    db: DbSession,
    user: CurrentUser,
    x_organization_id: str | None = Header(None, alias="X-Organization-Id"),
    organization_id_query: UUID | None = Query(None, alias="organization_id"),
) -> TenantContext:
    """Resolve the tenant context from the X-Organization-Id header or query param."""
    org_id_str = x_organization_id or (str(organization_id_query) if organization_id_query else None)
    if not org_id_str:
        raise UnauthorizedError("No organization context provided. Set X-Organization-Id header.")

    try:
        org_id = UUID(org_id_str)
    except ValueError:
        raise UnauthorizedError("Invalid organization ID format")

    ctx = await resolve_tenant_context(db, user["id"], user["email"], org_id)
    if ctx is None:
        raise ForbiddenError("You are not a member of this organization")

    logger.debug("tenant_context_resolved", user_id=str(user["id"]), org_id=str(org_id), role=ctx.role_name)
    return ctx


TenantCtx = Annotated[TenantContext, Depends(get_tenant_context)]


def require_permission(permission: str):
    """Return a dependency that checks the tenant context has the given permission."""
    async def _check(ctx: TenantCtx) -> TenantContext:
        if not ctx.has_permission(permission):
            raise ForbiddenError(f"Missing permission: {permission}")
        return ctx
    return _check
