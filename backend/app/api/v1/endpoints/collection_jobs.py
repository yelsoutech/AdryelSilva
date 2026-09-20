"""Collection job endpoints — enqueue and track data collection jobs."""

import uuid

from fastapi import APIRouter, Depends, Query

from app.core.deps import DbSession, TenantCtx, require_permission
from app.schemas.collection_job import CollectionJobCreate, CollectionJobResponse
from app.services.collection_service import CollectionService

router = APIRouter()


@router.get("", response_model=list[CollectionJobResponse])
async def list_collection_jobs(
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("marketplaces.read")),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    service = CollectionService(db, ctx)
    offset = (page - 1) * page_size
    return await service.list_jobs(offset=offset, limit=page_size)


@router.post("", response_model=CollectionJobResponse, status_code=201)
async def create_collection_job(
    payload: CollectionJobCreate,
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("marketplaces.manage")),
):
    service = CollectionService(db, ctx)
    return await service.enqueue_job(
        job_type=payload.job_type,
        marketplace_account_id=payload.marketplace_account_id,
        priority=payload.priority,
        payload=payload.payload,
    )


@router.get("/{job_id}", response_model=CollectionJobResponse)
async def get_collection_job(
    job_id: uuid.UUID,
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("marketplaces.read")),
):
    service = CollectionService(db, ctx)
    return await service.get_job(job_id)
