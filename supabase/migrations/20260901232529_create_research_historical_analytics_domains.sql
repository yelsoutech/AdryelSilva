/*
# Research, Historical & Analytics Domains

## Overview
Creates tables for marketplace research (searches, keywords, search results),
historical data (price history, metrics history), and analytics (product metrics,
market metrics, competitor metrics, opportunities, opportunity scores).

## New Tables

### Research Domain

1. `keywords` — Tracked keywords for marketplace search monitoring.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - keyword (text, not null)
   - marketplace_id (uuid, FK → marketplaces)
   - status (text, default 'active')
   - created_at, updated_at (timestamptz, auto)
   - Unique: (organization_id, keyword, marketplace_id)

2. `searches` — A search execution on a marketplace for a keyword.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - keyword_id (uuid, FK → keywords ON DELETE CASCADE)
   - marketplace_id (uuid, FK → marketplaces)
   - marketplace_account_id (uuid, FK → marketplace_accounts ON DELETE CASCADE)
   - search_term (text, not null)
   - status (text, default 'pending')
   - executed_at (timestamptz)
   - created_at, updated_at (timestamptz, auto)

3. `search_results` — Individual results from a search execution.
   - id (uuid, PK)
   - search_id (uuid, FK → searches ON DELETE CASCADE)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - product_listing_id (uuid, FK → product_listings ON DELETE SET NULL, nullable)
   - position (integer) — ranking position in search results
   - external_id (text) — listing ID from marketplace
   - title (text)
   - price_cents (bigint)
   - currency (text, default 'BRL')
   - seller_name (text)
   - raw_data (jsonb)
   - created_at (timestamptz)

### Historical Domain

4. `price_history` — Historical price snapshots for product listings.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - product_listing_id (uuid, FK → product_listings ON DELETE CASCADE)
   - price_cents (bigint, not null)
   - currency (text, default 'BRL')
   - recorded_at (timestamptz, not null)
   - created_at (timestamptz, default now())

5. `metrics_history` — Historical metrics snapshots.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - entity_type (text, not null) — 'product', 'market', 'competitor'
   - entity_id (uuid, not null) — FK to the relevant entity
   - metric_name (text, not null)
   - metric_value numeric
   - recorded_at (timestamptz, not null)
   - created_at (timestamptz, default now())

### Analytics Domain

6. `product_metrics` — Aggregated metrics for a product listing.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - product_listing_id (uuid, FK → product_listings ON DELETE CASCADE)
   - metric_date (date, not null)
   - views (integer, default 0)
   - sales (integer, default 0)
   - revenue_cents (bigint, default 0)
   - conversion_rate (numeric)
   - stock_quantity (integer)
   - created_at, updated_at (timestamptz, auto)
   - Unique: (product_listing_id, metric_date)

7. `market_metrics` — Aggregated market-level metrics.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - marketplace_id (uuid, FK → marketplaces ON DELETE CASCADE)
   - metric_date (date, not null)
   - total_listings (integer, default 0)
   - avg_price_cents (bigint)
   - currency (text, default 'BRL')
   - created_at, updated_at (timestamptz, auto)
   - Unique: (organization_id, marketplace_id, metric_date)

8. `competitor_metrics` — Metrics for competitor sellers.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - seller_id (uuid, FK → sellers ON DELETE CASCADE)
   - marketplace_id (uuid, FK → marketplaces ON DELETE CASCADE)
   - metric_date (date, not null)
   - total_listings (integer, default 0)
   - estimated_sales (integer, default 0)
   - estimated_revenue_cents (bigint, default 0)
   - created_at, updated_at (timestamptz, auto)
   - Unique: (organization_id, seller_id, metric_date)

9. `opportunities` — Identified market opportunities.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - marketplace_id (uuid, FK → marketplaces ON DELETE CASCADE)
   - product_listing_id (uuid, FK → product_listings ON DELETE SET NULL, nullable)
   - keyword_id (uuid, FK → keywords ON DELETE SET NULL, nullable)
   - opportunity_type (text, not null) — [DECISÃO DO PRODUTO: tipos de oportunidade]
   - description (text)
   - status (text, default 'open') — 'open', 'closed', 'dismissed'
   - created_at, updated_at (timestamptz, auto)

10. `opportunity_scores` — Scores for opportunities (table structure only, no scoring logic).
   - id (uuid, PK)
   - opportunity_id (uuid, FK → opportunities ON DELETE CASCADE, UNIQUE)
   - score (numeric, not null) — 0-100 range
   - confidence (numeric) — 0-1 range
   - factors (jsonb) — scoring factors breakdown
   - scored_at (timestamptz, default now())
   - created_at, updated_at (timestamptz, auto)

## Security
- keywords/searches/search_results: org-scoped via user_org_member(organization_id).
- price_history/metrics_history: org-scoped.
- product_metrics/market_metrics/competitor_metrics: org-scoped.
- opportunities/opportunity_scores: org-scoped (opportunity_scores scoped through opportunity_id).

## Important Notes
1. opportunity_scores table structure exists but NO scoring algorithm is implemented.
2. opportunity_type values are not defined yet — [DECISÃO DO PRODUTO].
3. metrics_history.entity_id is a loose FK (not a database FK constraint) because it
   can reference different tables depending on entity_type.
4. No data has been seeded.
*/

-- ============================================
-- RESEARCH: KEYWORDS
-- ============================================
CREATE TABLE IF NOT EXISTS keywords (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  keyword text NOT NULL,
  marketplace_id uuid NOT NULL REFERENCES marketplaces(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, keyword, marketplace_id)
);

-- ============================================
-- RESEARCH: SEARCHES
-- ============================================
CREATE TABLE IF NOT EXISTS searches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  keyword_id uuid NOT NULL REFERENCES keywords(id) ON DELETE CASCADE,
  marketplace_id uuid NOT NULL REFERENCES marketplaces(id) ON DELETE RESTRICT,
  marketplace_account_id uuid NOT NULL REFERENCES marketplace_accounts(id) ON DELETE CASCADE,
  search_term text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  executed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- RESEARCH: SEARCH_RESULTS
-- ============================================
CREATE TABLE IF NOT EXISTS search_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  search_id uuid NOT NULL REFERENCES searches(id) ON DELETE CASCADE,
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  product_listing_id uuid REFERENCES product_listings(id) ON DELETE SET NULL,
  position integer,
  external_id text,
  title text,
  price_cents bigint,
  currency text NOT NULL DEFAULT 'BRL',
  seller_name text,
  raw_data jsonb,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- HISTORICAL: PRICE_HISTORY
-- ============================================
CREATE TABLE IF NOT EXISTS price_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  product_listing_id uuid NOT NULL REFERENCES product_listings(id) ON DELETE CASCADE,
  price_cents bigint NOT NULL,
  currency text NOT NULL DEFAULT 'BRL',
  recorded_at timestamptz NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- HISTORICAL: METRICS_HISTORY
-- ============================================
CREATE TABLE IF NOT EXISTS metrics_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  metric_name text NOT NULL,
  metric_value numeric,
  recorded_at timestamptz NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- ANALYTICS: PRODUCT_METRICS
-- ============================================
CREATE TABLE IF NOT EXISTS product_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  product_listing_id uuid NOT NULL REFERENCES product_listings(id) ON DELETE CASCADE,
  metric_date date NOT NULL,
  views integer NOT NULL DEFAULT 0,
  sales integer NOT NULL DEFAULT 0,
  revenue_cents bigint NOT NULL DEFAULT 0,
  conversion_rate numeric,
  stock_quantity integer,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(product_listing_id, metric_date)
);

-- ============================================
-- ANALYTICS: MARKET_METRICS
-- ============================================
CREATE TABLE IF NOT EXISTS market_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  marketplace_id uuid NOT NULL REFERENCES marketplaces(id) ON DELETE CASCADE,
  metric_date date NOT NULL,
  total_listings integer NOT NULL DEFAULT 0,
  avg_price_cents bigint,
  currency text NOT NULL DEFAULT 'BRL',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, marketplace_id, metric_date)
);

-- ============================================
-- ANALYTICS: COMPETITOR_METRICS
-- ============================================
CREATE TABLE IF NOT EXISTS competitor_metrics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  seller_id uuid NOT NULL REFERENCES sellers(id) ON DELETE CASCADE,
  marketplace_id uuid NOT NULL REFERENCES marketplaces(id) ON DELETE CASCADE,
  metric_date date NOT NULL,
  total_listings integer NOT NULL DEFAULT 0,
  estimated_sales integer NOT NULL DEFAULT 0,
  estimated_revenue_cents bigint NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, seller_id, metric_date)
);

-- ============================================
-- ANALYTICS: OPPORTUNITIES
-- ============================================
CREATE TABLE IF NOT EXISTS opportunities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  marketplace_id uuid NOT NULL REFERENCES marketplaces(id) ON DELETE CASCADE,
  product_listing_id uuid REFERENCES product_listings(id) ON DELETE SET NULL,
  keyword_id uuid REFERENCES keywords(id) ON DELETE SET NULL,
  opportunity_type text NOT NULL,
  description text,
  status text NOT NULL DEFAULT 'open',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- ANALYTICS: OPPORTUNITY_SCORES
-- ============================================
CREATE TABLE IF NOT EXISTS opportunity_scores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  opportunity_id uuid UNIQUE NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
  score numeric NOT NULL,
  confidence numeric,
  factors jsonb DEFAULT '{}',
  scored_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================
ALTER TABLE keywords ENABLE ROW LEVEL SECURITY;
ALTER TABLE searches ENABLE ROW LEVEL SECURITY;
ALTER TABLE search_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE metrics_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE market_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE competitor_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE opportunities ENABLE ROW LEVEL SECURITY;
ALTER TABLE opportunity_scores ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS: KEYWORDS (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_keywords" ON keywords;
CREATE POLICY "select_own_keywords" ON keywords FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_keywords" ON keywords;
CREATE POLICY "insert_own_keywords" ON keywords FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_keywords" ON keywords;
CREATE POLICY "update_own_keywords" ON keywords FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_keywords" ON keywords;
CREATE POLICY "delete_own_keywords" ON keywords FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: SEARCHES (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_searches" ON searches;
CREATE POLICY "select_own_searches" ON searches FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_searches" ON searches;
CREATE POLICY "insert_own_searches" ON searches FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_searches" ON searches;
CREATE POLICY "update_own_searches" ON searches FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_searches" ON searches;
CREATE POLICY "delete_own_searches" ON searches FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: SEARCH_RESULTS (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_search_results" ON search_results;
CREATE POLICY "select_own_search_results" ON search_results FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_search_results" ON search_results;
CREATE POLICY "insert_own_search_results" ON search_results FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_search_results" ON search_results;
CREATE POLICY "update_own_search_results" ON search_results FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_search_results" ON search_results;
CREATE POLICY "delete_own_search_results" ON search_results FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: PRICE_HISTORY (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_price_history" ON price_history;
CREATE POLICY "select_own_price_history" ON price_history FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_price_history" ON price_history;
CREATE POLICY "insert_own_price_history" ON price_history FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_price_history" ON price_history;
CREATE POLICY "update_own_price_history" ON price_history FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_price_history" ON price_history;
CREATE POLICY "delete_own_price_history" ON price_history FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: METRICS_HISTORY (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_metrics_history" ON metrics_history;
CREATE POLICY "select_own_metrics_history" ON metrics_history FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_metrics_history" ON metrics_history;
CREATE POLICY "insert_own_metrics_history" ON metrics_history FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_metrics_history" ON metrics_history;
CREATE POLICY "update_own_metrics_history" ON metrics_history FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_metrics_history" ON metrics_history;
CREATE POLICY "delete_own_metrics_history" ON metrics_history FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: PRODUCT_METRICS (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_product_metrics" ON product_metrics;
CREATE POLICY "select_own_product_metrics" ON product_metrics FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_product_metrics" ON product_metrics;
CREATE POLICY "insert_own_product_metrics" ON product_metrics FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_product_metrics" ON product_metrics;
CREATE POLICY "update_own_product_metrics" ON product_metrics FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_product_metrics" ON product_metrics;
CREATE POLICY "delete_own_product_metrics" ON product_metrics FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: MARKET_METRICS (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_market_metrics" ON market_metrics;
CREATE POLICY "select_own_market_metrics" ON market_metrics FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_market_metrics" ON market_metrics;
CREATE POLICY "insert_own_market_metrics" ON market_metrics FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_market_metrics" ON market_metrics;
CREATE POLICY "update_own_market_metrics" ON market_metrics FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_market_metrics" ON market_metrics;
CREATE POLICY "delete_own_market_metrics" ON market_metrics FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: COMPETITOR_METRICS (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_competitor_metrics" ON competitor_metrics;
CREATE POLICY "select_own_competitor_metrics" ON competitor_metrics FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_competitor_metrics" ON competitor_metrics;
CREATE POLICY "insert_own_competitor_metrics" ON competitor_metrics FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_competitor_metrics" ON competitor_metrics;
CREATE POLICY "update_own_competitor_metrics" ON competitor_metrics FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_competitor_metrics" ON competitor_metrics;
CREATE POLICY "delete_own_competitor_metrics" ON competitor_metrics FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: OPPORTUNITIES (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_opportunities" ON opportunities;
CREATE POLICY "select_own_opportunities" ON opportunities FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_opportunities" ON opportunities;
CREATE POLICY "insert_own_opportunities" ON opportunities FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_opportunities" ON opportunities;
CREATE POLICY "update_own_opportunities" ON opportunities FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_opportunities" ON opportunities;
CREATE POLICY "delete_own_opportunities" ON opportunities FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: OPPORTUNITY_SCORES (org-scoped via opportunity_id)
-- ============================================
DROP POLICY IF EXISTS "select_own_opportunity_scores" ON opportunity_scores;
CREATE POLICY "select_own_opportunity_scores" ON opportunity_scores FOR SELECT
  TO authenticated USING (
    EXISTS (
      SELECT 1 FROM opportunities
      WHERE opportunities.id = opportunity_scores.opportunity_id
      AND user_org_member(opportunities.organization_id)
    )
  );
DROP POLICY IF EXISTS "insert_own_opportunity_scores" ON opportunity_scores;
CREATE POLICY "insert_own_opportunity_scores" ON opportunity_scores FOR INSERT
  TO authenticated WITH CHECK (
    EXISTS (
      SELECT 1 FROM opportunities
      WHERE opportunities.id = opportunity_scores.opportunity_id
      AND user_org_member(opportunities.organization_id)
    )
  );
DROP POLICY IF EXISTS "update_own_opportunity_scores" ON opportunity_scores;
CREATE POLICY "update_own_opportunity_scores" ON opportunity_scores FOR UPDATE
  TO authenticated USING (
    EXISTS (
      SELECT 1 FROM opportunities
      WHERE opportunities.id = opportunity_scores.opportunity_id
      AND user_org_member(opportunities.organization_id)
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM opportunities
      WHERE opportunities.id = opportunity_scores.opportunity_id
      AND user_org_member(opportunities.organization_id)
    )
  );
DROP POLICY IF EXISTS "delete_own_opportunity_scores" ON opportunity_scores;
CREATE POLICY "delete_own_opportunity_scores" ON opportunity_scores FOR DELETE
  TO authenticated USING (
    EXISTS (
      SELECT 1 FROM opportunities
      WHERE opportunities.id = opportunity_scores.opportunity_id
      AND user_org_member(opportunities.organization_id)
    )
  );

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_keywords_organization_id ON keywords(organization_id);
CREATE INDEX IF NOT EXISTS idx_keywords_marketplace_id ON keywords(marketplace_id);
CREATE INDEX IF NOT EXISTS idx_keywords_status ON keywords(status);

CREATE INDEX IF NOT EXISTS idx_searches_organization_id ON searches(organization_id);
CREATE INDEX IF NOT EXISTS idx_searches_keyword_id ON searches(keyword_id);
CREATE INDEX IF NOT EXISTS idx_searches_marketplace_id ON searches(marketplace_id);
CREATE INDEX IF NOT EXISTS idx_searches_status ON searches(status);

CREATE INDEX IF NOT EXISTS idx_search_results_search_id ON search_results(search_id);
CREATE INDEX IF NOT EXISTS idx_search_results_organization_id ON search_results(organization_id);
CREATE INDEX IF NOT EXISTS idx_search_results_product_listing_id ON search_results(product_listing_id);

CREATE INDEX IF NOT EXISTS idx_price_history_organization_id ON price_history(organization_id);
CREATE INDEX IF NOT EXISTS idx_price_history_product_listing_id ON price_history(product_listing_id);
CREATE INDEX IF NOT EXISTS idx_price_history_recorded_at ON price_history(recorded_at);

CREATE INDEX IF NOT EXISTS idx_metrics_history_organization_id ON metrics_history(organization_id);
CREATE INDEX IF NOT EXISTS idx_metrics_history_entity_type ON metrics_history(entity_type);
CREATE INDEX IF NOT EXISTS idx_metrics_history_entity_id ON metrics_history(entity_id);
CREATE INDEX IF NOT EXISTS idx_metrics_history_recorded_at ON metrics_history(recorded_at);

CREATE INDEX IF NOT EXISTS idx_product_metrics_organization_id ON product_metrics(organization_id);
CREATE INDEX IF NOT EXISTS idx_product_metrics_product_listing_id ON product_metrics(product_listing_id);
CREATE INDEX IF NOT EXISTS idx_product_metrics_metric_date ON product_metrics(metric_date);

CREATE INDEX IF NOT EXISTS idx_market_metrics_organization_id ON market_metrics(organization_id);
CREATE INDEX IF NOT EXISTS idx_market_metrics_marketplace_id ON market_metrics(marketplace_id);
CREATE INDEX IF NOT EXISTS idx_market_metrics_metric_date ON market_metrics(metric_date);

CREATE INDEX IF NOT EXISTS idx_competitor_metrics_organization_id ON competitor_metrics(organization_id);
CREATE INDEX IF NOT EXISTS idx_competitor_metrics_seller_id ON competitor_metrics(seller_id);
CREATE INDEX IF NOT EXISTS idx_competitor_metrics_marketplace_id ON competitor_metrics(marketplace_id);
CREATE INDEX IF NOT EXISTS idx_competitor_metrics_metric_date ON competitor_metrics(metric_date);

CREATE INDEX IF NOT EXISTS idx_opportunities_organization_id ON opportunities(organization_id);
CREATE INDEX IF NOT EXISTS idx_opportunities_marketplace_id ON opportunities(marketplace_id);
CREATE INDEX IF NOT EXISTS idx_opportunities_status ON opportunities(status);
CREATE INDEX IF NOT EXISTS idx_opportunities_opportunity_type ON opportunities(opportunity_type);

CREATE INDEX IF NOT EXISTS idx_opportunity_scores_opportunity_id ON opportunity_scores(opportunity_id);
CREATE INDEX IF NOT EXISTS idx_opportunity_scores_score ON opportunity_scores(score);

-- ============================================
-- TRIGGERS
-- ============================================
DROP TRIGGER IF EXISTS trg_keywords_updated_at ON keywords;
CREATE TRIGGER trg_keywords_updated_at BEFORE UPDATE ON keywords
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_searches_updated_at ON searches;
CREATE TRIGGER trg_searches_updated_at BEFORE UPDATE ON searches
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_product_metrics_updated_at ON product_metrics;
CREATE TRIGGER trg_product_metrics_updated_at BEFORE UPDATE ON product_metrics
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_market_metrics_updated_at ON market_metrics;
CREATE TRIGGER trg_market_metrics_updated_at BEFORE UPDATE ON market_metrics
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_competitor_metrics_updated_at ON competitor_metrics;
CREATE TRIGGER trg_competitor_metrics_updated_at BEFORE UPDATE ON competitor_metrics
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_opportunities_updated_at ON opportunities;
CREATE TRIGGER trg_opportunities_updated_at BEFORE UPDATE ON opportunities
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_opportunity_scores_updated_at ON opportunity_scores;
CREATE TRIGGER trg_opportunity_scores_updated_at BEFORE UPDATE ON opportunity_scores
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();