"""Organization endpoints — read and update the current organization."""

from fastapi import APIRouter, Depends

from app.core.deps import DbSession, TenantCtx, require_permission
from app.models.organization import Organization
from app.schemas.organization import OrganizationResponse, OrganizationUpdate
from sqlalchemy import select

router = APIRouter()


@router.get("/current", response_model=OrganizationResponse)
async def get_current_organization(
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("organization.read")),
):
    """Return the organization the caller is currently scoped to."""
    result = await db.execute(
        select(Organization).where(Organization.id == ctx.organization_id)
    )
    org = result.scalar_one_or_none()
    return org
