"""Abstract base class for async workers that process collection jobs."""

from abc import ABC, abstractmethod
from typing import Any

from app.core.logging import logger


class Worker(ABC):
    """Abstract base class for async workers that process collection jobs.

    Each worker type implements `process` to handle a specific job_type.
    The dispatcher registers workers by job_type and routes jobs to them.
    """

    job_type: str
    worker_name: str

    @abstractmethod
    async def process(self, job_data: dict[str, Any]) -> dict[str, Any]:
        """Process a single job. Returns result metadata.

        Raises an exception on failure — the dispatcher will mark the job as failed.
        """
        ...

    async def run(self, job_data: dict[str, Any]) -> dict[str, Any]:
        """Wrapper around process() with structured logging."""
        logger.info("worker_started", worker=self.worker_name, job_type=self.job_type, job_id=job_data.get("id"))
        try:
            result = await self.process(job_data)
            logger.info("worker_completed", worker=self.worker_name, job_id=job_data.get("id"))
            return result
        except Exception as exc:
            logger.error("worker_failed", worker=self.worker_name, job_id=job_data.get("id"), error=str(exc))
            raise
