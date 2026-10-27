"""Repository for the OrganizationMember model."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.tenant import TenantContext
from app.models.organization_member import OrganizationMember
from app.repositories.base import BaseRepository


class OrganizationMemberRepository(BaseRepository[OrganizationMember]):
    model = OrganizationMember

    async def list_active(self) -> list[OrganizationMember]:
        result = await self.db.execute(
            select(OrganizationMember)
            .where(
                OrganizationMember.organization_id == self.org_id,
                OrganizationMember.status == "active",
            )
            .order_by(OrganizationMember.joined_at.asc())
        )
        return list(result.scalars().all())

    async def get_by_id(self, member_id: UUID) -> OrganizationMember | None:
        result = await self.db.execute(
            select(OrganizationMember).where(
                OrganizationMember.id == member_id,
                OrganizationMember.organization_id == self.org_id,
            )
        )
        return result.scalar_one_or_none()