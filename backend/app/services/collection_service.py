"""Collection service — enqueues and tracks data collection jobs."""

import uuid
from typing import Any

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.core.logging import logger
from app.core.tenant import TenantContext
from app.models.collection_job import CollectionJob
from app.services.base import BaseService


class CollectionService(BaseService):
    """Coordinates the data collection pipeline: enqueue → poll → process → store."""

    async def enqueue_job(
        self,
        job_type: str,
        marketplace_account_id: uuid.UUID | None = None,
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
        self.db.add(job)
        await self._commit_and_refresh(job)
        logger.info(
            "collection_job_enqueued",
            job_id=str(job.id),
            job_type=job_type,
            org_id=str(self.org_id),
        )
        return job

    async def get_job(self, job_id: uuid.UUID) -> CollectionJob:
        job = await self._get_by_id(CollectionJob, job_id)
        if not job:
            raise NotFoundError("Collection job", str(job_id))
        return job

    async def list_jobs(self, offset: int = 0, limit: int = 20) -> list[CollectionJob]:
        return await self._list(CollectionJob, offset=offset, limit=limit)

    async def claim_next_pending(self) -> CollectionJob | None:
        """Atomically claim the next pending job for this org (used by workers)."""
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
        logger.info("collection_job_claimed", job_id=str(job.id))
        return job

    async def complete_job(self, job_id: uuid.UUID, result_data: dict[str, Any] | None = None) -> CollectionJob:
        job = await self.get_job(job_id)
        job.status = "completed"
        job.result = result_data or {}
        await self._commit_and_refresh(job)
        logger.info("collection_job_completed", job_id=str(job_id))
        return job

    async def fail_job(self, job_id: uuid.UUID, error_message: str) -> CollectionJob:
        job = await self.get_job(job_id)
        job.status = "failed"
        job.error_message = error_message
        await self._commit_and_refresh(job)
        logger.error("collection_job_failed", job_id=str(job_id), error=error_message)
        return job
