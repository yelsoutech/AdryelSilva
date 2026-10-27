"""Base repository — shared CRUD primitives scoped to the tenant organization.

Repositories own all DB access (queries, inserts, updates, deletes). Services
depend on repositories and contain only business rules and orchestration.
"""

from typing import Any, Generic, TypeVar
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.tenant import TenantContext

ModelT = TypeVar("ModelT")


class BaseRepository(Generic[ModelT]):
    """Generic tenant-scoped repository.

    Subclasses set ``model`` to the SQLAlchemy model class. All queries are
    automatically filtered by ``organization_id`` so a service can never
    accidentally leak data across tenants.
    """

    model: type[ModelT]

    def __init__(self, db: AsyncSession, tenant: TenantContext):
        self.db = db
        self.tenant = tenant

    @property
    def org_id(self) -> UUID:
        return self.tenant.organization_id

    async def get_by_id(self, item_id: UUID) -> ModelT | None:
        result = await self.db.execute(
            select(self.model).where(
                self.model.id == item_id,  # type: ignore[attr-defined]
                self.model.organization_id == self.org_id,  # type: ignore[attr-defined]
            )
        )
        return result.scalar_one_or_none()

    async def list(self, offset: int = 0, limit: int = 20) -> list[ModelT]:
        result = await self.db.execute(
            select(self.model)
            .where(self.model.organization_id == self.org_id)  # type: ignore[attr-defined]
            .order_by(self.model.created_at.desc())  # type: ignore[attr-defined]
            .offset(offset)
            .limit(limit)
        )
        return list(result.scalars().all())

    async def add(self, obj: ModelT) -> ModelT:
        self.db.add(obj)
        await self.db.commit()
        await self.db.refresh(obj)
        return obj

    async def update(self, obj: ModelT) -> ModelT:
        await self.db.commit()
        await self.db.refresh(obj)
        return obj

    async def delete(self, obj: ModelT) -> None:
        await self.db.delete(obj)
        await self.db.commit()

    async def commit_and_refresh(self, obj: Any) -> Any:
        await self.db.commit()
        await self.db.refresh(obj)
        return obj