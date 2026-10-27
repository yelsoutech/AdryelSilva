"""Base service class — coordinates repositories and enforces business rules.

Services no longer access the database directly. They receive repositories in
their constructor and delegate all persistence concerns to them.
"""

from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.tenant import TenantContext


class BaseService:
    """Base for all domain services. Holds the DB session and tenant context."""

    def __init__(self, db: AsyncSession, tenant: TenantContext):
        self.db = db
        self.tenant = tenant

    @property
    def org_id(self) -> UUID:
        return self.tenant.organization_id