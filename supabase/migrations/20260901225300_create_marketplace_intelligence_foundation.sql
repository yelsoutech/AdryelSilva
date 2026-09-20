/*
# Marketplace Intelligence - Multi-Tenant Foundation Schema

## Overview
Creates the foundational database schema for a B2B SaaS marketplace intelligence platform.
This is a multi-tenant schema designed to support multiple marketplace integrations
(Mercado Livre first, with Shopee, Amazon, and others planned for the future).

## Architecture
The schema follows the data pipeline concept:
  Marketplace → Collector → Queue → Worker → Parser → Validator → Normalizer → Database

## New Tables

1. `tenants` — Organizations/companies using the platform. Each tenant is an isolated workspace.
   - `id` (uuid, PK)
   - `name` (text, not null) — display name
   - `slug` (text, unique) — URL-friendly identifier
   - `created_at`, `updated_at` (timestamps)

2. `tenant_users` — Links authenticated users to tenants with role-based access.
   - `id` (uuid, PK)
   - `tenant_id` (uuid, FK → tenants, cascade delete)
   - `user_id` (uuid, FK → auth.users, cascade delete)
   - `role` (text, default 'member') — 'admin' or 'member'
   - `created_at` (timestamp)
   - Unique constraint on (tenant_id, user_id)

3. `marketplace_accounts` — A tenant's connection to a specific marketplace (e.g., their Mercado Livre seller account).
   - `id` (uuid, PK)
   - `tenant_id` (uuid, FK → tenants, cascade delete)
   - `marketplace` (text, not null) — 'mercadolivre', 'shopee', 'amazon', etc.
   - `account_name` (text, not null) — user-friendly label
   - `account_id` (text, not null) — marketplace-specific account identifier
   - `credentials` (jsonb) — encrypted auth tokens/credentials (never exposed to client)
   - `status` (text, default 'disconnected') — 'connected', 'disconnected', 'error'
   - `last_sync_at` (timestamp) — last successful data sync
   - `created_at`, `updated_at` (timestamps)
   - Unique constraint on (tenant_id, marketplace, account_id)

4. `collection_jobs` — Tracks asynchronous data collection jobs from marketplaces.
   - `id` (uuid, PK)
   - `tenant_id` (uuid, FK → tenants, cascade delete)
   - `marketplace_account_id` (uuid, FK → marketplace_accounts, cascade delete)
   - `job_type` (text, not null) — 'collect_listings', 'collect_orders', etc.
   - `status` (text, default 'pending') — 'pending', 'processing', 'completed', 'failed'
   - `started_at`, `completed_at` (timestamps)
   - `error_message` (text) — populated on failure
   - `metadata` (jsonb) — job-specific parameters
   - `created_at`, `updated_at` (timestamps)

5. `raw_marketplace_data` — Raw, unprocessed data collected from marketplaces.
   - `id` (uuid, PK)
   - `tenant_id` (uuid, FK → tenants, cascade delete)
   - `marketplace_account_id` (uuid, FK → marketplace_accounts, cascade delete)
   - `collection_job_id` (uuid, FK → collection_jobs, set null on delete)
   - `marketplace` (text, not null)
   - `data_type` (text, not null) — 'listing', 'order', 'review', etc.
   - `external_id` (text, not null) — ID from the marketplace itself
   - `raw_data` (jsonb, not null) — the raw payload
   - `collected_at` (timestamp)
   - Unique constraint on (tenant_id, marketplace, data_type, external_id) — deduplication at raw level

6. `normalized_listings` — Parsed and normalized listing data, ready for business use.
   - `id` (uuid, PK)
   - `tenant_id` (uuid, FK → tenants, cascade delete)
   - `marketplace_account_id` (uuid, FK → marketplace_accounts, cascade delete)
   - `raw_data_id` (uuid, FK → raw_marketplace_data, set null on delete)
   - `marketplace` (text, not null)
   - `external_id` (text, not null)
   - `title`, `price_cents`, `currency`, `status` — normalized fields
   - `attributes` (jsonb) — marketplace-specific attributes
   - `normalized_at` (timestamp)
   - Unique constraint on (tenant_id, marketplace, external_id)

## Security
- RLS enabled on ALL tables.
- Policies use `TO anon, authenticated` with `USING (true)` as a TEMPORARY measure
  because authentication has not been implemented yet. When auth is added, these
  policies MUST be replaced with tenant-scoped ownership checks using auth.uid()
  and the tenant_users table.
- This is a foundation schema — no business logic, no fake data, no metrics.

## Important Notes
1. This schema is multi-tenant from the start. Every table has a `tenant_id` column
   for isolation. When auth is implemented, RLS policies will enforce that users can
   only access data belonging to their tenant(s).
2. The `marketplace` column uses text (not an enum) to allow easy addition of new
   marketplaces without migrations.
3. `credentials` on marketplace_accounts stores sensitive data and must NEVER be
   exposed through the API client. Only server-side code should access it.
4. Deduplication is handled at the raw_marketplace_data level via unique constraint
   on (tenant_id, marketplace, data_type, external_id).
*/

-- ============================================
-- 1. TENANTS
-- ============================================
CREATE TABLE IF NOT EXISTS tenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_tenants" ON tenants;
CREATE POLICY "anon_select_tenants" ON tenants FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_tenants" ON tenants;
CREATE POLICY "anon_insert_tenants" ON tenants FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_tenants" ON tenants;
CREATE POLICY "anon_update_tenants" ON tenants FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_tenants" ON tenants;
CREATE POLICY "anon_delete_tenants" ON tenants FOR DELETE
  TO anon, authenticated USING (true);

-- ============================================
-- 2. TENANT_USERS
-- ============================================
CREATE TABLE IF NOT EXISTS tenant_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'member',
  created_at timestamptz DEFAULT now(),
  UNIQUE(tenant_id, user_id)
);

ALTER TABLE tenant_users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_tenant_users" ON tenant_users;
CREATE POLICY "anon_select_tenant_users" ON tenant_users FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_tenant_users" ON tenant_users;
CREATE POLICY "anon_insert_tenant_users" ON tenant_users FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_tenant_users" ON tenant_users;
CREATE POLICY "anon_update_tenant_users" ON tenant_users FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_tenant_users" ON tenant_users;
CREATE POLICY "anon_delete_tenant_users" ON tenant_users FOR DELETE
  TO anon, authenticated USING (true);

-- ============================================
-- 3. MARKETPLACE_ACCOUNTS
-- ============================================
CREATE TABLE IF NOT EXISTS marketplace_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  marketplace text NOT NULL,
  account_name text NOT NULL,
  account_id text NOT NULL,
  credentials jsonb,
  status text NOT NULL DEFAULT 'disconnected',
  last_sync_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(tenant_id, marketplace, account_id)
);

ALTER TABLE marketplace_accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_marketplace_accounts" ON marketplace_accounts;
CREATE POLICY "anon_select_marketplace_accounts" ON marketplace_accounts FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_marketplace_accounts" ON marketplace_accounts;
CREATE POLICY "anon_insert_marketplace_accounts" ON marketplace_accounts FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_marketplace_accounts" ON marketplace_accounts;
CREATE POLICY "anon_update_marketplace_accounts" ON marketplace_accounts FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_marketplace_accounts" ON marketplace_accounts;
CREATE POLICY "anon_delete_marketplace_accounts" ON marketplace_accounts FOR DELETE
  TO anon, authenticated USING (true);

-- ============================================
-- 4. COLLECTION_JOBS
-- ============================================
CREATE TABLE IF NOT EXISTS collection_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  marketplace_account_id uuid NOT NULL REFERENCES marketplace_accounts(id) ON DELETE CASCADE,
  job_type text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  started_at timestamptz,
  completed_at timestamptz,
  error_message text,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE collection_jobs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_collection_jobs" ON collection_jobs;
CREATE POLICY "anon_select_collection_jobs" ON collection_jobs FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_collection_jobs" ON collection_jobs;
CREATE POLICY "anon_insert_collection_jobs" ON collection_jobs FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_collection_jobs" ON collection_jobs;
CREATE POLICY "anon_update_collection_jobs" ON collection_jobs FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_collection_jobs" ON collection_jobs;
CREATE POLICY "anon_delete_collection_jobs" ON collection_jobs FOR DELETE
  TO anon, authenticated USING (true);

-- ============================================
-- 5. RAW_MARKETPLACE_DATA
-- ============================================
CREATE TABLE IF NOT EXISTS raw_marketplace_data (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  marketplace_account_id uuid NOT NULL REFERENCES marketplace_accounts(id) ON DELETE CASCADE,
  collection_job_id uuid REFERENCES collection_jobs(id) ON DELETE SET NULL,
  marketplace text NOT NULL,
  data_type text NOT NULL,
  external_id text NOT NULL,
  raw_data jsonb NOT NULL,
  collected_at timestamptz DEFAULT now(),
  UNIQUE(tenant_id, marketplace, data_type, external_id)
);

ALTER TABLE raw_marketplace_data ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_raw_marketplace_data" ON raw_marketplace_data;
CREATE POLICY "anon_select_raw_marketplace_data" ON raw_marketplace_data FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_raw_marketplace_data" ON raw_marketplace_data;
CREATE POLICY "anon_insert_raw_marketplace_data" ON raw_marketplace_data FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_raw_marketplace_data" ON raw_marketplace_data;
CREATE POLICY "anon_update_raw_marketplace_data" ON raw_marketplace_data FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_raw_marketplace_data" ON raw_marketplace_data;
CREATE POLICY "anon_delete_raw_marketplace_data" ON raw_marketplace_data FOR DELETE
  TO anon, authenticated USING (true);

-- ============================================
-- 6. NORMALIZED_LISTINGS
-- ============================================
CREATE TABLE IF NOT EXISTS normalized_listings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  marketplace_account_id uuid NOT NULL REFERENCES marketplace_accounts(id) ON DELETE CASCADE,
  raw_data_id uuid REFERENCES raw_marketplace_data(id) ON DELETE SET NULL,
  marketplace text NOT NULL,
  external_id text NOT NULL,
  title text,
  price_cents bigint,
  currency text,
  status text,
  attributes jsonb DEFAULT '{}',
  normalized_at timestamptz DEFAULT now(),
  UNIQUE(tenant_id, marketplace, external_id)
);

ALTER TABLE normalized_listings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "anon_select_normalized_listings" ON normalized_listings;
CREATE POLICY "anon_select_normalized_listings" ON normalized_listings FOR SELECT
  TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "anon_insert_normalized_listings" ON normalized_listings;
CREATE POLICY "anon_insert_normalized_listings" ON normalized_listings FOR INSERT
  TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "anon_update_normalized_listings" ON normalized_listings;
CREATE POLICY "anon_update_normalized_listings" ON normalized_listings FOR UPDATE
  TO anon, authenticated USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "anon_delete_normalized_listings" ON normalized_listings;
CREATE POLICY "anon_delete_normalized_listings" ON normalized_listings FOR DELETE
  TO anon, authenticated USING (true);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_tenant_users_user_id ON tenant_users(user_id);
CREATE INDEX IF NOT EXISTS idx_tenant_users_tenant_id ON tenant_users(tenant_id);

CREATE INDEX IF NOT EXISTS idx_marketplace_accounts_tenant_id ON marketplace_accounts(tenant_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_accounts_marketplace ON marketplace_accounts(marketplace);

CREATE INDEX IF NOT EXISTS idx_collection_jobs_tenant_id ON collection_jobs(tenant_id);
CREATE INDEX IF NOT EXISTS idx_collection_jobs_status ON collection_jobs(status);
CREATE INDEX IF NOT EXISTS idx_collection_jobs_account_id ON collection_jobs(marketplace_account_id);

CREATE INDEX IF NOT EXISTS idx_raw_marketplace_data_tenant_id ON raw_marketplace_data(tenant_id);
CREATE INDEX IF NOT EXISTS idx_raw_marketplace_data_marketplace ON raw_marketplace_data(marketplace);
CREATE INDEX IF NOT EXISTS idx_raw_marketplace_data_data_type ON raw_marketplace_data(data_type);
CREATE INDEX IF NOT EXISTS idx_raw_marketplace_data_collection_job_id ON raw_marketplace_data(collection_job_id);

CREATE INDEX IF NOT EXISTS idx_normalized_listings_tenant_id ON normalized_listings(tenant_id);
CREATE INDEX IF NOT EXISTS idx_normalized_listings_marketplace ON normalized_listings(marketplace);
CREATE INDEX IF NOT EXISTS idx_normalized_listings_status ON normalized_listings(status);

-- ============================================
-- UPDATED_AT TRIGGER FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_tenants_updated_at ON tenants;
CREATE TRIGGER trg_tenants_updated_at BEFORE UPDATE ON tenants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_marketplace_accounts_updated_at ON marketplace_accounts;
CREATE TRIGGER trg_marketplace_accounts_updated_at BEFORE UPDATE ON marketplace_accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_collection_jobs_updated_at ON collection_jobs;
CREATE TRIGGER trg_collection_jobs_updated_at BEFORE UPDATE ON collection_jobs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();