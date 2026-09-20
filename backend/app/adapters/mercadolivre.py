from typing import Any

from app.adapters.base import MarketplaceAdapter


class MercadoLivreAdapter(MarketplaceAdapter):
    """Mercado Livre marketplace adapter.

    NOTE: This is a structural placeholder. The actual API integration
    (OAuth flow, item collection, order collection) will be implemented
    when the Mercado Livre credentials are configured and the integration
    is approved for development.
    """

    marketplace_name = "mercadolivre"
    base_url = "https://api.mercadolibre.com"

    async def authenticate(self, credentials: dict[str, Any]) -> dict[str, Any]:
        raise NotImplementedError("Mercado Livre OAuth flow not yet implemented")

    async def collect(self, data_type: str, access_token: str, params: dict[str, Any] | None = None) -> list[dict[str, Any]]:
        raise NotImplementedError("Mercado Livre data collection not yet implemented")

    async def refresh_token(self, refresh_token: str) -> dict[str, Any]:
        raise NotImplementedError("Mercado Livre token refresh not yet implemented")
