"""Organization service — read and update the current organization."""

from app.core.errors import NotFoundError
from app.core.tenant import TenantContext
from app.models.organization import Organization
from app.repositories.organization_repository import OrganizationRepository
from app.services.base import BaseService


class OrganizationService(BaseService):
    """Reads and updates the organization the caller is currently scoped to."""

    def __init__(self, db, tenant: TenantContext):
        super().__init__(db, tenant)
        self.repo = OrganizationRepository(db, tenant)

    async def get_current(self) -> Organization:
        org = await self.repo.get_current()
        if not org:
            raise NotFoundError("Organization", str(self.org_id))
        return org

    async def update(self, name: str | None = None, status: str | None = None) -> Organization:
        org = await self.get_current()
        if name is not None:
            org.name = name
        if status is not None:
            org.status = status
        return await self.repo.update(org)