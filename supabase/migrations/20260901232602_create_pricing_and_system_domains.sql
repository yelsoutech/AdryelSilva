/*
# Pricing & System Domains

## Overview
Creates the pricing calculation tables (scenarios, costs, fees, taxes, shipping, ad costs)
and the system infrastructure tables (alerts, notifications, audit logs, jobs).

## New Tables

### Pricing Domain

1. `pricing_scenarios` — What-if pricing scenarios for products.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - product_id (uuid, FK → products ON DELETE CASCADE)
   - name (text, not null)
   - target_price_cents (bigint)
   - currency (text, default 'BRL')
   - status (text, default 'draft')
   - created_at, updated_at (timestamptz, auto)

2. `costs` — Cost components for products.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - product_id (uuid, FK → products ON DELETE CASCADE)
   - cost_type (text, not null) — 'manufacturing', 'packaging', 'logistics', etc.
   - amount_cents (bigint, not null)
   - currency (text, default 'BRL')
   - effective_from (timestamptz)
   - effective_to (timestamptz)
   - created_at, updated_at (timestamptz, auto)

3. `fees` — Marketplace fee structures (global reference data).
   - id (uuid, PK)
   - marketplace_id (uuid, FK → marketplaces ON DELETE CASCADE)
   - fee_type (text, not null) — 'commission', 'fixed', 'shipping', etc.
   - fee_percentage (numeric) — percentage of sale price
   - fee_fixed_cents (bigint) — fixed fee amount
   - category_id (uuid, FK → categories, nullable) — if fee is category-specific
   - created_at, updated_at (timestamptz, auto)
   - Unique: (marketplace_id, fee_type, category_id)

4. `taxes` — Tax configurations.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - tax_name (text, not null)
   - tax_percentage (numeric, not null)
   - region (text) — geographic scope
   - created_at, updated_at (timestamptz, auto)

5. `shipping_costs` — Shipping cost configurations.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - marketplace_id (uuid, FK → marketplaces ON DELETE CASCADE)
   - region (text)
   - min_days (integer)
   - max_days (integer)
   - cost_cents (bigint, not null)
   - currency (text, default 'BRL')
   - created_at, updated_at (timestamptz, auto)

6. `ad_costs` — Advertising cost tracking.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - marketplace_id (uuid, FK → marketplaces ON DELETE CASCADE)
   - marketplace_account_id (uuid, FK → marketplace_accounts ON DELETE CASCADE)
   - campaign_name (text)
   - campaign_id (text) — external campaign ID
   - spend_cents (bigint, not null)
   - currency (text, default 'BRL')
   - impressions (integer, default 0)
   - clicks (integer, default 0)
   - recorded_at (date, not null)
   - created_at, updated_at (timestamptz, auto)

### System Domain

7. `alerts` — System alerts for organizations.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - alert_type (text, not null)
   - severity (text, default 'info') — 'info', 'warning', 'error', 'critical'
   - message (text, not null)
   - entity_type (text)
   - entity_id (uuid)
   - is_read (boolean, default false)
   - created_at, updated_at (timestamptz, auto)

8. `notifications` — User notifications.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - user_id (uuid, FK → users ON DELETE CASCADE)
   - notification_type (text, not null)
   - title (text, not null)
   - body (text)
   - is_read (boolean, default false)
   - created_at (timestamptz, default now())

9. `audit_logs` — Audit trail for sensitive actions.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - user_id (uuid, FK → users ON DELETE SET NULL)
   - action (text, not null) — e.g., 'marketplace_account.connect', 'user.invite'
   - entity_type (text)
   - entity_id (uuid)
   - metadata (jsonb)
   - ip_address (inet)
   - created_at (timestamptz, default now())

10. `jobs` — Generic async job queue (replaces collection_jobs).
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - job_type (text, not null) — 'collect_listings', 'collect_searches', etc.
   - status (text, default 'pending') — 'pending', 'processing', 'completed', 'failed'
   - priority (integer, default 0)
   - payload (jsonb) — job-specific parameters
   - result (jsonb) — job result data
   - error_message (text)
   - started_at (timestamptz)
   - completed_at (timestamptz)
   - created_at, updated_at (timestamptz, auto)

## Security
- fees: readable by all authenticated users (global reference data).
- All other pricing tables: org-scoped via user_org_member(organization_id).
- alerts/notifications/audit_logs/jobs: org-scoped.
- notifications also scoped to user_id (user sees only their notifications).

## Important Notes
1. fees is global reference data — fee structures are marketplace-wide, not org-specific.
2. audit_logs.user_id uses ON DELETE SET NULL to preserve audit history when users are deleted.
3. jobs is a generic queue — job_type determines what worker processes it.
4. No data has been seeded.
*/

-- ============================================
-- PRICING: PRICING_SCENARIOS
-- ============================================
CREATE TABLE IF NOT EXISTS pricing_scenarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  name text NOT NULL,
  target_price_cents bigint,
  currency text NOT NULL DEFAULT 'BRL',
  status text NOT NULL DEFAULT 'draft',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- PRICING: COSTS
-- ============================================
CREATE TABLE IF NOT EXISTS costs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  cost_type text NOT NULL,
  amount_cents bigint NOT NULL,
  currency text NOT NULL DEFAULT 'BRL',
  effective_from timestamptz,
  effective_to timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- PRICING: FEES (global reference data)
-- ============================================
CREATE TABLE IF NOT EXISTS fees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  marketplace_id uuid NOT NULL REFERENCES marketplaces(id) ON DELETE CASCADE,
  fee_type text NOT NULL,
  fee_percentage numeric,
  fee_fixed_cents bigint,
  category_id uuid REFERENCES categories(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(marketplace_id, fee_type, category_id)
);

-- ============================================
-- PRICING: TAXES
-- ============================================
CREATE TABLE IF NOT EXISTS taxes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  tax_name text NOT NULL,
  tax_percentage numeric NOT NULL,
  region text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- PRICING: SHIPPING_COSTS
-- ============================================
CREATE TABLE IF NOT EXISTS shipping_costs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  marketplace_id uuid NOT NULL REFERENCES marketplaces(id) ON DELETE CASCADE,
  region text,
  min_days integer,
  max_days integer,
  cost_cents bigint NOT NULL,
  currency text NOT NULL DEFAULT 'BRL',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- PRICING: AD_COSTS
-- ============================================
CREATE TABLE IF NOT EXISTS ad_costs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  marketplace_id uuid NOT NULL REFERENCES marketplaces(id) ON DELETE CASCADE,
  marketplace_account_id uuid NOT NULL REFERENCES marketplace_accounts(id) ON DELETE CASCADE,
  campaign_name text,
  campaign_id text,
  spend_cents bigint NOT NULL,
  currency text NOT NULL DEFAULT 'BRL',
  impressions integer NOT NULL DEFAULT 0,
  clicks integer NOT NULL DEFAULT 0,
  recorded_at date NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- SYSTEM: ALERTS
-- ============================================
CREATE TABLE IF NOT EXISTS alerts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  alert_type text NOT NULL,
  severity text NOT NULL DEFAULT 'info',
  message text NOT NULL,
  entity_type text,
  entity_id uuid,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- SYSTEM: NOTIFICATIONS
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  notification_type text NOT NULL,
  title text NOT NULL,
  body text,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- SYSTEM: AUDIT_LOGS
-- ============================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  action text NOT NULL,
  entity_type text,
  entity_id uuid,
  metadata jsonb DEFAULT '{}',
  ip_address inet,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- SYSTEM: JOBS
-- ============================================
CREATE TABLE IF NOT EXISTS jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  job_type text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  priority integer NOT NULL DEFAULT 0,
  payload jsonb DEFAULT '{}',
  result jsonb,
  error_message text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================
ALTER TABLE pricing_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE costs ENABLE ROW LEVEL SECURITY;
ALTER TABLE fees ENABLE ROW LEVEL SECURITY;
ALTER TABLE taxes ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipping_costs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ad_costs ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS: PRICING_SCENARIOS (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_pricing_scenarios" ON pricing_scenarios;
CREATE POLICY "select_own_pricing_scenarios" ON pricing_scenarios FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_pricing_scenarios" ON pricing_scenarios;
CREATE POLICY "insert_own_pricing_scenarios" ON pricing_scenarios FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_pricing_scenarios" ON pricing_scenarios;
CREATE POLICY "update_own_pricing_scenarios" ON pricing_scenarios FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_pricing_scenarios" ON pricing_scenarios;
CREATE POLICY "delete_own_pricing_scenarios" ON pricing_scenarios FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: COSTS (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_costs" ON costs;
CREATE POLICY "select_own_costs" ON costs FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_costs" ON costs;
CREATE POLICY "insert_own_costs" ON costs FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_costs" ON costs;
CREATE POLICY "update_own_costs" ON costs FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_costs" ON costs;
CREATE POLICY "delete_own_costs" ON costs FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: FEES (global reference data)
-- ============================================
DROP POLICY IF EXISTS "select_fees" ON fees;
CREATE POLICY "select_fees" ON fees FOR SELECT
  TO authenticated USING (true);

-- ============================================
-- RLS: TAXES (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_taxes" ON taxes;
CREATE POLICY "select_own_taxes" ON taxes FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_taxes" ON taxes;
CREATE POLICY "insert_own_taxes" ON taxes FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_taxes" ON taxes;
CREATE POLICY "update_own_taxes" ON taxes FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_taxes" ON taxes;
CREATE POLICY "delete_own_taxes" ON taxes FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: SHIPPING_COSTS (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_shipping_costs" ON shipping_costs;
CREATE POLICY "select_own_shipping_costs" ON shipping_costs FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_shipping_costs" ON shipping_costs;
CREATE POLICY "insert_own_shipping_costs" ON shipping_costs FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_shipping_costs" ON shipping_costs;
CREATE POLICY "update_own_shipping_costs" ON shipping_costs FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_shipping_costs" ON shipping_costs;
CREATE POLICY "delete_own_shipping_costs" ON shipping_costs FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: AD_COSTS (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_ad_costs" ON ad_costs;
CREATE POLICY "select_own_ad_costs" ON ad_costs FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_ad_costs" ON ad_costs;
CREATE POLICY "insert_own_ad_costs" ON ad_costs FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_ad_costs" ON ad_costs;
CREATE POLICY "update_own_ad_costs" ON ad_costs FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_ad_costs" ON ad_costs;
CREATE POLICY "delete_own_ad_costs" ON ad_costs FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: ALERTS (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_alerts" ON alerts;
CREATE POLICY "select_own_alerts" ON alerts FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_alerts" ON alerts;
CREATE POLICY "insert_own_alerts" ON alerts FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_alerts" ON alerts;
CREATE POLICY "update_own_alerts" ON alerts FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_alerts" ON alerts;
CREATE POLICY "delete_own_alerts" ON alerts FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS: NOTIFICATIONS (org + user scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_notifications" ON notifications;
CREATE POLICY "select_own_notifications" ON notifications FOR SELECT
  TO authenticated USING (user_org_member(organization_id) AND user_id = auth.uid());
DROP POLICY IF EXISTS "insert_own_notifications" ON notifications;
CREATE POLICY "insert_own_notifications" ON notifications FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_notifications" ON notifications;
CREATE POLICY "update_own_notifications" ON notifications FOR UPDATE
  TO authenticated USING (user_org_member(organization_id) AND user_id = auth.uid()) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_notifications" ON notifications;
CREATE POLICY "delete_own_notifications" ON notifications FOR DELETE
  TO authenticated USING (user_org_member(organization_id) AND user_id = auth.uid());

-- ============================================
-- RLS: AUDIT_LOGS (org-scoped, read-only for users)
-- ============================================
DROP POLICY IF EXISTS "select_own_audit_logs" ON audit_logs;
CREATE POLICY "select_own_audit_logs" ON audit_logs FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_audit_logs" ON audit_logs;
CREATE POLICY "insert_own_audit_logs" ON audit_logs FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));

-- ============================================
-- RLS: JOBS (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_jobs" ON jobs;
CREATE POLICY "select_own_jobs" ON jobs FOR SELECT
  TO authenticated USING (user_org_member(organization_id));
DROP POLICY IF EXISTS "insert_own_jobs" ON jobs;
CREATE POLICY "insert_own_jobs" ON jobs FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "update_own_jobs" ON jobs;
CREATE POLICY "update_own_jobs" ON jobs FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));
DROP POLICY IF EXISTS "delete_own_jobs" ON jobs;
CREATE POLICY "delete_own_jobs" ON jobs FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_pricing_scenarios_organization_id ON pricing_scenarios(organization_id);
CREATE INDEX IF NOT EXISTS idx_pricing_scenarios_product_id ON pricing_scenarios(product_id);
CREATE INDEX IF NOT EXISTS idx_pricing_scenarios_status ON pricing_scenarios(status);

CREATE INDEX IF NOT EXISTS idx_costs_organization_id ON costs(organization_id);
CREATE INDEX IF NOT EXISTS idx_costs_product_id ON costs(product_id);
CREATE INDEX IF NOT EXISTS idx_costs_cost_type ON costs(cost_type);

CREATE INDEX IF NOT EXISTS idx_fees_marketplace_id ON fees(marketplace_id);
CREATE INDEX IF NOT EXISTS idx_fees_category_id ON fees(category_id);
CREATE INDEX IF NOT EXISTS idx_fees_fee_type ON fees(fee_type);

CREATE INDEX IF NOT EXISTS idx_taxes_organization_id ON taxes(organization_id);

CREATE INDEX IF NOT EXISTS idx_shipping_costs_organization_id ON shipping_costs(organization_id);
CREATE INDEX IF NOT EXISTS idx_shipping_costs_marketplace_id ON shipping_costs(marketplace_id);

CREATE INDEX IF NOT EXISTS idx_ad_costs_organization_id ON ad_costs(organization_id);
CREATE INDEX IF NOT EXISTS idx_ad_costs_marketplace_id ON ad_costs(marketplace_id);
CREATE INDEX IF NOT EXISTS idx_ad_costs_marketplace_account_id ON ad_costs(marketplace_account_id);
CREATE INDEX IF NOT EXISTS idx_ad_costs_recorded_at ON ad_costs(recorded_at);

CREATE INDEX IF NOT EXISTS idx_alerts_organization_id ON alerts(organization_id);
CREATE INDEX IF NOT EXISTS idx_alerts_severity ON alerts(severity);
CREATE INDEX IF NOT EXISTS idx_alerts_is_read ON alerts(is_read);

CREATE INDEX IF NOT EXISTS idx_notifications_organization_id ON notifications(organization_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

CREATE INDEX IF NOT EXISTS idx_audit_logs_organization_id ON audit_logs(organization_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs(created_at);

CREATE INDEX IF NOT EXISTS idx_jobs_organization_id ON jobs(organization_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_job_type ON jobs(job_type);
CREATE INDEX IF NOT EXISTS idx_jobs_priority ON jobs(priority);

-- ============================================
-- TRIGGERS
-- ============================================
DROP TRIGGER IF EXISTS trg_pricing_scenarios_updated_at ON pricing_scenarios;
CREATE TRIGGER trg_pricing_scenarios_updated_at BEFORE UPDATE ON pricing_scenarios
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_costs_updated_at ON costs;
CREATE TRIGGER trg_costs_updated_at BEFORE UPDATE ON costs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_fees_updated_at ON fees;
CREATE TRIGGER trg_fees_updated_at BEFORE UPDATE ON fees
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_taxes_updated_at ON taxes;
CREATE TRIGGER trg_taxes_updated_at BEFORE UPDATE ON taxes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_shipping_costs_updated_at ON shipping_costs;
CREATE TRIGGER trg_shipping_costs_updated_at BEFORE UPDATE ON shipping_costs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_ad_costs_updated_at ON ad_costs;
CREATE TRIGGER trg_ad_costs_updated_at BEFORE UPDATE ON ad_costs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_alerts_updated_at ON alerts;
CREATE TRIGGER trg_alerts_updated_at BEFORE UPDATE ON alerts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_jobs_updated_at ON jobs;
CREATE TRIGGER trg_jobs_updated_at BEFORE UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();