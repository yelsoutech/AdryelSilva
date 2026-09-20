# Marketplace Integration

## Visão Geral

A integração com marketplaces segue o padrão **Adapter**. Cada marketplace implementa a interface `MarketplaceAdapter`, permitindo que o pipeline de dados funcione com qualquer marketplace de forma uniforme.

## MarketplaceAdapter (Interface)

```python
class MarketplaceAdapter(ABC):
    marketplace_name: str

    async def authenticate(self, credentials: dict) -> dict
    async def collect(self, data_type: str, access_token: str, params: dict) -> list[dict]
    async def refresh_token(self, refresh_token: str) -> dict
```

## Marketplaces

### Mercado Livre (Primeiro marketplace)
- Adapter: `backend/app/adapters/mercadolivre.py`
- Status: Placeholder estrutural — métodos levantam `NotImplementedError`
- API base: `https://api.mercadolibre.com`
- Nenhuma integração real foi implementada

### Futuros Marketplaces
- Shopee
- Amazon
- Outros

## Registry

O `registry.py` mantém um dicionário de adapters registrados. Novos marketplaces podem ser adicionados via `register_adapter()` sem alterar o pipeline.

```python
registry = {
    "mercadolivre": MercadoLivreAdapter,
    # "shopee": ShopeeAdapter,       # futuro
    # "amazon": AmazonAdapter,       // futuro
}
```

## Tabela de Contas

A tabela `marketplace_accounts` armazena a conexão de cada tenant com um marketplace:
- `marketplace` (text): identificador do marketplace
- `account_id` (text): ID da conta no marketplace
- `credentials` (jsonb): tokens de autenticação (nunca expostos ao cliente)
- `status`: 'connected', 'disconnected', 'error'

## Decisões Pendentes

- [DECISÃO DO PRODUTO] Quais tipos de dados serão coletados de cada marketplace
- [DECISÃO DO PRODUTO] Frequência de sincronização por marketplace
- [DECISÃO DO PRODUTO] Tratamento de rate limits específicos de cada marketplace
- [DECISÃO DO PRODUTO] OAuth flow específico do Mercado Livre
