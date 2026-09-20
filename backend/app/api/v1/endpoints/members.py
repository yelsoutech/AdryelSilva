"""Organization member endpoints — team management within an organization."""

import uuid

from fastapi import APIRouter, Depends

from app.core.deps import DbSession, TenantCtx, require_permission
from app.schemas.user import OrganizationMemberResponse, RoleResponse
from app.services.member_service import MemberService

router = APIRouter()


@router.get("", response_model=list[OrganizationMemberResponse])
async def list_members(
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("users.read")),
):
    service = MemberService(db, ctx)
    return await service.list_members()


@router.get("/roles", response_model=list[RoleResponse])
async def list_roles(
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("roles.read")),
):
    service = MemberService(db, ctx)
    return await service.list_roles()


@router.patch("/{member_id}/role", response_model=OrganizationMemberResponse)
async def update_member_role(
    member_id: uuid.UUID,
    role_id: uuid.UUID,
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("users.update")),
):
    service = MemberService(db, ctx)
    return await service.update_member_role(member_id, role_id)


@router.delete("/{member_id}", status_code=204)
async def remove_member(
    member_id: uuid.UUID,
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("users.remove")),
):
    service = MemberService(db, ctx)
    await service.remove_member(member_id)
