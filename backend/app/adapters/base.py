from abc import ABC, abstractmethod
from typing import Any


class MarketplaceAdapter(ABC):
    """Abstract base class for marketplace integrations.

    Each marketplace (Mercado Livre, Shopee, Amazon, etc.) implements this interface
    so the collection pipeline can work with any marketplace uniformly.
    """

    marketplace_name: str

    @abstractmethod
    async def authenticate(self, credentials: dict[str, Any]) -> dict[str, Any]:
        """Authenticate with the marketplace and return access tokens."""
        ...

    @abstractmethod
    async def collect(self, data_type: str, access_token: str, params: dict[str, Any] | None = None) -> list[dict[str, Any]]:
        """Collect raw data of a given type from the marketplace."""
        ...

    @abstractmethod
    async def refresh_token(self, refresh_token: str) -> dict[str, Any]:
        """Refresh an expired access token."""
        ...
