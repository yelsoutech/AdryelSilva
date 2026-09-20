"""Base service class providing common CRUD patterns scoped to the tenant context."""

from typing import Any, TypeVar
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.tenant import TenantContext
from app.core.logging import logger

ModelT = TypeVar("ModelT")


class BaseService:
    """Base for all domain services. Holds the DB session and tenant context."""

    def __init__(self, db: AsyncSession, tenant: TenantContext):
        self.db = db
        self.tenant = tenant

    @property
    def org_id(self) -> UUID:
        return self.tenant.organization_id

    async def _get_by_id(self, model: type[ModelT], item_id: UUID) -> ModelT | None:
        result = await self.db.execute(
            select(model).where(
                model.id == item_id,
                model.organization_id == self.org_id,
            )
        )
        return result.scalar_one_or_none()

    async def _list(self, model: type[ModelT], offset: int = 0, limit: int = 20) -> list[ModelT]:
        result = await self.db.execute(
            select(model)
            .where(model.organization_id == self.org_id)
            .order_by(model.created_at.desc())
            .offset(offset)
            .limit(limit)
        )
        return list(result.scalars().all())

    async def _commit_and_refresh(self, obj: Any) -> Any:
        await self.db.commit()
        await self.db.refresh(obj)
        logger.debug("entity_saved", table=obj.__tablename__, entity_id=str(obj.id))
        return obj
