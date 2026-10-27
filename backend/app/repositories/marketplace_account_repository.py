"""Repository for the MarketplaceAccount model."""

from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.tenant import TenantContext
from app.models.marketplace_account import MarketplaceAccount
from app.repositories.base import BaseRepository


class MarketplaceAccountRepository(BaseRepository[MarketplaceAccount]):
    model = MarketplaceAccount

    async def create(
        self,
        *,
        marketplace_id: UUID,
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
        return await self.add(account)