"""Marketplace account service — manages marketplace connections per organization."""

import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import NotFoundError
from app.core.logging import logger
from app.models.marketplace_account import MarketplaceAccount
from app.services.base import BaseService


class MarketplaceAccountService(BaseService):
    """CRUD operations for marketplace accounts scoped to the current organization."""

    async def create_account(
        self,
        marketplace_id: uuid.UUID,
        account_name: str,
        account_id: str,
    ) -> MarketplaceAccount:
        account = MarketplaceAccount(
            organization_id=self.org_id,
            marketplace_id=marketplace_id,
            account_name=account_name,
            account_id=account_id,
            status="disconnected",
        )
        self.db.add(account)
        await self._commit_and_refresh(account)
        logger.info("marketplace_account_created", account_id=str(account.id), org_id=str(self.org_id))
        return account

    async def get_account(self, account_id: uuid.UUID) -> MarketplaceAccount:
        account = await self._get_by_id(MarketplaceAccount, account_id)
        if not account:
            raise NotFoundError("Marketplace account", str(account_id))
        return account

    async def list_accounts(self, offset: int = 0, limit: int = 20) -> list[MarketplaceAccount]:
        return await self._list(MarketplaceAccount, offset=offset, limit=limit)

    async def update_account(
        self,
        account_id: uuid.UUID,
        account_name: str | None = None,
        status: str | None = None,
    ) -> MarketplaceAccount:
        account = await self.get_account(account_id)
        if account_name is not None:
            account.account_name = account_name
        if status is not None:
            account.status = status
        await self._commit_and_refresh(account)
        return account

    async def delete_account(self, account_id: uuid.UUID) -> None:
        account = await self.get_account(account_id)
        await self.db.delete(account)
        await self.db.commit()
        logger.info("marketplace_account_deleted", account_id=str(account_id))
