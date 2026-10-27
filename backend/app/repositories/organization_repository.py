"""Repository for the Organization model."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.tenant import TenantContext
from app.models.organization import Organization
from app.repositories.base import BaseRepository


class OrganizationRepository(BaseRepository[Organization]):
    """Organizations are not tenant-scoped (they ARE the tenant), so queries
    use the organization_id from the tenant context directly."""

    model = Organization

    def __init__(self, db: AsyncSession, tenant: TenantContext):
        self.db = db
        self.tenant = tenant

    async def get_current(self) -> Organization | None:
        result = await self.db.execute(
            select(Organization).where(Organization.id == self.tenant.organization_id)
        )
        return result.scalar_one_or_none()

    async def update(self, org: Organization) -> Organization:
        await self.db.commit()
        await self.db.refresh(org)
        return org