from app.adapters.base import MarketplaceAdapter
from app.adapters.mercadolivre import MercadoLivreAdapter

_registry: dict[str, type[MarketplaceAdapter]] = {
    "mercadolivre": MercadoLivreAdapter,
}


def get_adapter(marketplace: str) -> MarketplaceAdapter:
    """Return an instance of the adapter for the given marketplace name."""
    adapter_cls = _registry.get(marketplace)
    if not adapter_cls:
        raise ValueError(f"No adapter registered for marketplace: {marketplace}")
    return adapter_cls()


def register_adapter(marketplace: str, adapter_cls: type[MarketplaceAdapter]) -> None:
    """Register a new marketplace adapter. Used to add Shopee, Amazon, etc. in the future."""
    _registry[marketplace] = adapter_cls
