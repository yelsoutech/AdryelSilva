"""Organization member service — team management within an organization."""

import uuid

from app.core.errors import NotFoundError
from app.core.logging import logger
from app.core.tenant import TenantContext
from app.models.organization_member import OrganizationMember
from app.models.role import Role
from app.repositories.member_repository import OrganizationMemberRepository
from app.repositories.role_repository import RoleRepository
from app.services.base import BaseService


class MemberService(BaseService):
    """Manages organization members, roles, and invitations."""

    def __init__(self, db, tenant: TenantContext):
        super().__init__(db, tenant)
        self.member_repo = OrganizationMemberRepository(db, tenant)
        self.role_repo = RoleRepository(db, tenant)

    async def list_members(self) -> list[OrganizationMember]:
        return await self.member_repo.list_active()

    async def get_member(self, member_id: uuid.UUID) -> OrganizationMember:
        member = await self.member_repo.get_by_id(member_id)
        if not member:
            raise NotFoundError("Organization member", str(member_id))
        return member

    async def update_member_role(self, member_id: uuid.UUID, role_id: uuid.UUID) -> OrganizationMember:
        member = await self.get_member(member_id)
        member.role_id = role_id
        await self.member_repo.update(member)
        logger.info("member_role_updated", member_id=str(member_id), role_id=str(role_id))
        return member

    async def remove_member(self, member_id: uuid.UUID) -> None:
        member = await self.get_member(member_id)
        member.status = "removed"
        await self.member_repo.update(member)
        logger.info("member_removed", member_id=str(member_id))

    async def list_roles(self) -> list[Role]:
        return await self.role_repo.list_all()