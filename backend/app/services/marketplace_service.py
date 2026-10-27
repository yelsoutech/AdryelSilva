"""Marketplace account service — manages marketplace connections per organization."""

import uuid

from app.core.errors import NotFoundError
from app.core.logging import logger
from app.core.tenant import TenantContext
from app.models.marketplace_account import MarketplaceAccount
from app.repositories.marketplace_account_repository import MarketplaceAccountRepository
from app.services.base import BaseService


class MarketplaceAccountService(BaseService):
    """CRUD operations for marketplace accounts scoped to the current organization."""

    def __init__(self, db, tenant: TenantContext):
        super().__init__(db, tenant)
        self.repo = MarketplaceAccountRepository(db, tenant)

    async def create_account(
        self,
        marketplace_id: uuid.UUID,
        account_name: str,
        account_id: str,
    ) -> MarketplaceAccount:
        account = await self.repo.create(
            marketplace_id=marketplace_id,
            account_name=account_name,
            account_id=account_id,
        )
        logger.info("marketplace_account_created", account_id=str(account.id), org_id=str(self.org_id))
        return account

    async def get_account(self, account_id: uuid.UUID) -> MarketplaceAccount:
        account = await self.repo.get_by_id(account_id)
        if not account:
            raise NotFoundError("Marketplace account", str(account_id))
        return account

    async def list_accounts(self, offset: int = 0, limit: int = 20) -> list[MarketplaceAccount]:
        return await self.repo.list(offset=offset, limit=limit)

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
        await self.repo.update(account)
        return account

    async def delete_account(self, account_id: uuid.UUID) -> None:
        account = await self.get_account(account_id)
        await self.repo.delete(account)
        logger.info("marketplace_account_deleted", account_id=str(account_id))