"""Collection service — enqueues and tracks data collection jobs."""

import uuid
from typing import Any

from app.core.errors import NotFoundError
from app.core.logging import logger
from app.core.tenant import TenantContext
from app.models.collection_job import CollectionJob
from app.repositories.collection_job_repository import CollectionJobRepository
from app.services.base import BaseService


class CollectionService(BaseService):
    """Coordinates the data collection pipeline: enqueue → poll → process → store."""

    def __init__(self, db, tenant: TenantContext):
        super().__init__(db, tenant)
        self.repo = CollectionJobRepository(db, tenant)

    async def enqueue_job(
        self,
        job_type: str,
        marketplace_account_id: uuid.UUID | None = None,
        priority: int = 0,
        payload: dict[str, Any] | None = None,
    ) -> CollectionJob:
        job = await self.repo.create(
            job_type=job_type,
            marketplace_account_id=marketplace_account_id,
            priority=priority,
            payload=payload,
        )
        logger.info(
            "collection_job_enqueued",
            job_id=str(job.id),
            job_type=job_type,
            org_id=str(self.org_id),
        )
        return job

    async def get_job(self, job_id: uuid.UUID) -> CollectionJob:
        job = await self.repo.get_by_id(job_id)
        if not job:
            raise NotFoundError("Collection job", str(job_id))
        return job

    async def list_jobs(self, offset: int = 0, limit: int = 20) -> list[CollectionJob]:
        return await self.repo.list(offset=offset, limit=limit)

    async def claim_next_pending(self) -> CollectionJob | None:
        """Atomically claim the next pending job for this org (used by workers)."""
        job = await self.repo.claim_next_pending()
        if job:
            logger.info("collection_job_claimed", job_id=str(job.id))
        return job

    async def complete_job(self, job_id: uuid.UUID, result_data: dict[str, Any] | None = None) -> CollectionJob:
        job = await self.get_job(job_id)
        job.status = "completed"
        job.result = result_data or {}
        await self.repo.commit_and_refresh(job)
        logger.info("collection_job_completed", job_id=str(job_id))
        return job

    async def fail_job(self, job_id: uuid.UUID, error_message: str) -> CollectionJob:
        job = await self.get_job(job_id)
        job.status = "failed"
        job.error_message = error_message
        await self.repo.commit_and_refresh(job)
        logger.error("collection_job_failed", job_id=str(job_id), error=error_message)
        return job