"""Worker dispatcher — routes jobs to the correct worker by job_type."""

from typing import Any

from app.core.logging import logger
from app.workers.base import Worker


class WorkerDispatcher:
    """Registry + router for async workers.

    Workers register themselves by job_type. The dispatcher looks up the
    correct worker and delegates execution with structured logging.
    """

    def __init__(self):
        self._workers: dict[str, Worker] = {}

    def register(self, worker: Worker) -> None:
        if not worker.job_type:
            raise ValueError(f"Worker {worker.__class__.__name__} must define job_type")
        self._workers[worker.job_type] = worker
        logger.info("worker_registered", worker=worker.worker_name, job_type=worker.job_type)

    def get_worker(self, job_type: str) -> Worker | None:
        return self._workers.get(job_type)

    async def dispatch(self, job_type: str, job_data: dict[str, Any]) -> dict[str, Any]:
        worker = self.get_worker(job_type)
        if worker is None:
            logger.error("no_worker_for_job_type", job_type=job_type)
            raise ValueError(f"No worker registered for job_type: {job_type}")
        return await worker.run(job_data)


dispatcher = WorkerDispatcher()
