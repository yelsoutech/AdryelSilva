"""Tenant context — resolves the active organization for the authenticated user.

The frontend sends an `X-Organization-Id` header (or `?organization_id=` query param)
to scope every request to the user's active organization. We verify membership
and load permissions in a single DB round-trip.
"""

from dataclasses import dataclass, field
from typing import Any
from uuid import UUID

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


@dataclass
class TenantContext:
    """The resolved tenant context for a single request."""
    user_id: UUID
    email: str
    organization_id: UUID
    role_name: str
    permissions: set[str] = field(default_factory=set)

    def has_permission(self, name: str) -> bool:
        return name in self.permissions


async def resolve_tenant_context(
    db: AsyncSession,
    user_id: UUID,
    email: str,
    organization_id: UUID,
) -> TenantContext | None:
    """Resolve membership, role, and permissions for the user in the given org.

    Returns None if the user is not an active member of the organization.
    """
    result = await db.execute(
        text("""
            SELECT
                om.role_id,
                r.name AS role_name,
                COALESCE(
                    array_agg(p.name) FILTER (WHERE p.name IS NOT NULL),
                    ARRAY[]::text[]
                ) AS permissions
            FROM organization_members om
            JOIN roles r ON r.id = om.role_id
            LEFT JOIN role_permissions rp ON rp.role_id = om.role_id
            LEFT JOIN permissions p ON p.id = rp.permission_id
            WHERE om.organization_id = :org_id
              AND om.user_id = :user_id
              AND om.status = 'active'
            GROUP BY om.role_id, r.name
        """),
        {"org_id": organization_id, "user_id": user_id},
    )
    row = result.fetchone()
    if row is None:
        return None

    return TenantContext(
        user_id=user_id,
        email=email,
        organization_id=organization_id,
        role_name=row.role_name,
        permissions=set(row.permissions),
    )
