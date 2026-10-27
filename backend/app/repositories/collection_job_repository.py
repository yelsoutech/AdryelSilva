"""Repository for the CollectionJob model."""

from typing import Any
from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.tenant import TenantContext
from app.models.collection_job import CollectionJob
from app.repositories.base import BaseRepository


class CollectionJobRepository(BaseRepository[CollectionJob]):
    model = CollectionJob

    async def create(
        self,
        *,
        job_type: str,
        marketplace_account_id: UUID | None = None,
        priority: int = 0,
        payload: dict[str, Any] | None = None,
    ) -> CollectionJob:
        job = CollectionJob(
            organization_id=self.org_id,
            marketplace_account_id=marketplace_account_id,
            job_type=job_type,
            status="pending",
            priority=priority,
            payload=payload or {},
        )
        return await self.add(job)

    async def claim_next_pending(self) -> CollectionJob | None:
        """Atomically claim the next pending job for this org."""
        result = await self.db.execute(
            select(CollectionJob)
            .where(
                CollectionJob.organization_id == self.org_id,
                CollectionJob.status == "pending",
            )
            .order_by(CollectionJob.priority.desc(), CollectionJob.created_at.asc())
            .limit(1)
        )
        job = result.scalar_one_or_none()
        if job is None:
            return None

        await self.db.execute(
            update(CollectionJob)
            .where(CollectionJob.id == job.id, CollectionJob.status == "pending")
            .values(status="running")
        )
        await self.db.commit()
        await self.db.refresh(job)
        return job