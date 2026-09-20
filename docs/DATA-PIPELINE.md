# Data Pipeline

## Visão Geral

O pipeline de dados é o núcleo do processamento no Marketplace Intelligence. Ele coleta dados brutos dos marketplaces, processa-os através de múltiplas etapas e armazena o resultado normalizado.

## Fluxo Conceitual

```
Marketplace → Collector → Queue → Worker → Parser → Validator → Normalizer → Deduplication → Database
```

## Estágios

### 1. Collector
Busca dados brutos das APIs dos marketplaces através dos adapters. Cada marketplace tem seu próprio adapter que implementa a interface `MarketplaceAdapter`.

### 2. Queue
Jobs de coleta em status `pending` aguardando processamento. Representados pela tabela `collection_jobs`.

### 3. Worker
Processa jobs da fila, executando os estágios subsequentes do pipeline. Implementa a interface `Worker` (abstract base class).

### 4. Parser
Extrai campos estruturados dos payloads brutos do marketplace.

### 5. Validator
Garante integridade e completude dos dados parseados.

### 6. Normalizer
Mapeia campos específicos de cada marketplace para um schema unificado.

### 7. Deduplication
Elimina duplicatas. A deduplicação ocorre em nível raw via constraint unique: `(tenant_id, marketplace, data_type, external_id)`.

### 8. Database
Armazena dados brutos em `raw_marketplace_data` e dados normalizados em `normalized_listings`.

## Estrutura no Código

```
backend/app/
├── adapters/
│   ├── base.py            # MarketplaceAdapter (interface abstrata)
│   ├── mercadolivre.py    # Adapter do Mercado Livre (placeholder estrutural)
│   └── registry.py        # Registry para múltiplos adapters
├── services/
│   └── collection_service.py  # Coordena a criação de jobs de coleta
└── workers/
    └── base.py            # Worker (interface abstrata)
```

## Status Atual

- Interfaces abstratas definidas: `MarketplaceAdapter`, `Worker`
- Adapter do Mercado Livre é um placeholder estrutural (métodos levantam `NotImplementedError`)
- CollectionService cria jobs em status `pending`
- Nenhum worker está processando jobs ainda

## Decisões Pendentes

- [DECISÃO DO PRODUTO] Tecnologia da fila (database polling vs. Redis/RabbitMQ)
- [DECISÃO DO PRODUTO] Frequência de coleta por tipo de dado
- [DECISÃO DO PRODUTO] Estratégia de retry para jobs falhos
- [DECISÃO DO PRODUTO] Limites de volume por tenant
