"""Organization member service — team management within an organization."""

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.core.logging import logger
from app.models.organization_member import OrganizationMember
from app.models.role import Role
from app.services.base import BaseService


class MemberService(BaseService):
    """Manages organization members, roles, and invitations."""

    async def list_members(self) -> list[OrganizationMember]:
        result = await self.db.execute(
            select(OrganizationMember)
            .where(
                OrganizationMember.organization_id == self.org_id,
                OrganizationMember.status == "active",
            )
            .order_by(OrganizationMember.joined_at.asc())
        )
        return list(result.scalars().all())

    async def get_member(self, member_id: uuid.UUID) -> OrganizationMember:
        result = await self.db.execute(
            select(OrganizationMember).where(
                OrganizationMember.id == member_id,
                OrganizationMember.organization_id == self.org_id,
            )
        )
        member = result.scalar_one_or_none()
        if not member:
            raise NotFoundError("Organization member", str(member_id))
        return member

    async def update_member_role(self, member_id: uuid.UUID, role_id: uuid.UUID) -> OrganizationMember:
        member = await self.get_member(member_id)
        member.role_id = role_id
        await self._commit_and_refresh(member)
        logger.info("member_role_updated", member_id=str(member_id), role_id=str(role_id))
        return member

    async def remove_member(self, member_id: uuid.UUID) -> None:
        member = await self.get_member(member_id)
        member.status = "removed"
        await self._commit_and_refresh(member)
        logger.info("member_removed", member_id=str(member_id))

    async def list_roles(self) -> list[Role]:
        result = await self.db.execute(select(Role).order_by(Role.name))
        return list(result.scalars().all())
