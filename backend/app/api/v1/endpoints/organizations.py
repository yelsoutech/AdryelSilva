"""Organization endpoints — read and update the current organization."""

from fastapi import APIRouter, Depends

from app.core.deps import DbSession, TenantCtx, require_permission
from app.schemas.organization import OrganizationResponse, OrganizationUpdate
from app.services.organization_service import OrganizationService

router = APIRouter()


@router.get("/current", response_model=OrganizationResponse)
async def get_current_organization(
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("organization.read")),
):
    """Return the organization the caller is currently scoped to."""
    service = OrganizationService(db, ctx)
    return await service.get_current()


@router.patch("/current", response_model=OrganizationResponse)
async def update_current_organization(
    payload: OrganizationUpdate,
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("organization.update")),
):
    """Update the organization the caller is currently scoped to."""
    service = OrganizationService(db, ctx)
    return await service.update(name=payload.name, status=payload.status)