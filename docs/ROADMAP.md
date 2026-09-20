# Roadmap

## FASE 0 — Fundação (CONCLUÍDA)

- [x] Schema multi-tenant no PostgreSQL (6 tabelas)
- [x] RLS habilitado em todas as tabelas
- [x] Backend FastAPI com estrutura modular
- [x] REST endpoints para tenants, marketplace accounts, collection jobs
- [x] Interface abstrata MarketplaceAdapter
- [x] Adapter do Mercado Livre (placeholder estrutural)
- [x] Registry de adapters para múltiplos marketplaces
- [x] CollectionService para criação de jobs
- [x] Interface abstrata Worker
- [x] Frontend Next.js com dashboard shell e 5 páginas
- [x] Tipos TypeScript para o schema do banco
- [x] Documentação da arquitetura

## FASE 1 — Autenticação e Onboarding

- [ ] [DECISÃO DO PRODUTO] Fluxo de signup / login
- [ ] [DECISÃO DO PRODUTO] Criação automática de tenant no signup
- [ ] Substituir políticas RLS temporárias por policies baseadas em auth.uid()
- [ ] [DECISÃO DO PRODUTO] Convite de usuários para um tenant

## FASE 2 — Integração Mercado Livre

- [ ] [DECISÃO DO PRODUTO] OAuth flow do Mercado Livre
- [ ] Implementar autenticação no MercadoLivreAdapter
- [ ] Implementar coleta de dados (listings, orders, etc.)
- [ ] [DECISÃO DO PRODUTO] Quais tipos de dados coletar
- [ ] Implementar refresh de tokens
- [ ] Conectar UI de marketplaces ao fluxo de OAuth

## FASE 3 — Pipeline de Processamento

- [ ] Implementar Worker que processa jobs da fila
- [ ] Implementar Parser para dados do Mercado Livre
- [ ] Implementar Validator
- [ ] Implementar Normalizer (raw → normalized_listings)
- [ ] [DECISÃO DO PRODUTO] Tecnologia de fila
- [ ] [DECISÃO DO PRODUTO] Estratégia de retry

## FASE 4 — Relatórios e Visualização

- [ ] [DECISÃO DO PRODUTO] Quais métricas e relatórios
- [ ] [DECISÃO DO PRODUTO] Filtros e segmentação
- [ ] [DECISÃO DO PRODUTO] Exportação de dados

## FASE 5 — Pricing e Billing

- [ ] [DECISÃO DO PRODUTO] Modelo de pricing
- [ ] [DECISÃO DO PRODUTO] Gateway de pagamento
- [ ] [DECISÃO DO PRODUTO] Limites por plano

## FASE 6 — Marketplaces Adicionais

- [ ] [DECISÃO DO PRODUTO] Prioridade: Shopee vs Amazon
- [ ] Implementar ShopeeAdapter
- [ ] Implementar AmazonAdapter
- [ ] [DECISÃO DO PRODUTO] Outros marketplaces

## FASE 7 — IA e Features Avançadas

- [ ] [DECISÃO DO PRODUTO] Se haverá IA
- [ ] [DECISÃO DO PRODUTO] Opportunity Score
- [ ] [DECISÃO DO PRODUTO] Recomendações automáticas
- [ ] [DECISÃO DO PRODUTO] Análise preditiva

## Notas

- Cada fase depende de decisões de produto que ainda não foram tomadas
- Nenhuma funcionalidade deve ser implementada sem aprovação prévia
- A ordem das fases pode mudar conforme prioridades de produto
