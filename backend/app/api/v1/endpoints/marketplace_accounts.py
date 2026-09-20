"""Marketplace account endpoints — CRUD scoped to the current organization."""

import uuid

from fastapi import APIRouter, Depends, Query

from app.core.deps import DbSession, TenantCtx, require_permission
from app.schemas.marketplace_account import (
    MarketplaceAccountCreate,
    MarketplaceAccountResponse,
    MarketplaceAccountUpdate,
)
from app.services.marketplace_service import MarketplaceAccountService

router = APIRouter()


@router.get("", response_model=list[MarketplaceAccountResponse])
async def list_marketplace_accounts(
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("marketplaces.read")),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    service = MarketplaceAccountService(db, ctx)
    offset = (page - 1) * page_size
    return await service.list_accounts(offset=offset, limit=page_size)


@router.post("", response_model=MarketplaceAccountResponse, status_code=201)
async def create_marketplace_account(
    payload: MarketplaceAccountCreate,
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("marketplaces.manage")),
):
    service = MarketplaceAccountService(db, ctx)
    return await service.create_account(
        marketplace_id=payload.marketplace_id,
        account_name=payload.account_name,
        account_id=payload.account_id,
    )


@router.get("/{account_id}", response_model=MarketplaceAccountResponse)
async def get_marketplace_account(
    account_id: uuid.UUID,
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("marketplaces.read")),
):
    service = MarketplaceAccountService(db, ctx)
    return await service.get_account(account_id)


@router.patch("/{account_id}", response_model=MarketplaceAccountResponse)
async def update_marketplace_account(
    account_id: uuid.UUID,
    payload: MarketplaceAccountUpdate,
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("marketplaces.manage")),
):
    service = MarketplaceAccountService(db, ctx)
    return await service.update_account(
        account_id,
        account_name=payload.account_name,
        status=payload.status,
    )


@router.delete("/{account_id}", status_code=204)
async def delete_marketplace_account(
    account_id: uuid.UUID,
    db: DbSession,
    ctx: TenantCtx = Depends(require_permission("marketplaces.manage")),
):
    service = MarketplaceAccountService(db, ctx)
    await service.delete_account(account_id)
