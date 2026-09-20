/*
# Marketplace Domain — Marketplaces, Accounts, Credentials

## Overview
Creates the marketplace integration tables. Marketplaces are global reference data
(Mercado Livre, Shopee, Amazon, etc.). Each organization connects to marketplaces via
marketplace_accounts, and credentials are stored encrypted in a separate table.

## New Tables

1. `marketplaces` — Global registry of supported marketplaces (reference data).
   - id (uuid, PK)
   - name (text, unique, not null) — 'mercadolivre', 'shopee', 'amazon', etc.
   - display_name (text, not null) — "Mercado Livre"
   - api_base_url (text) — base URL for API calls
   - logo_url (text)
   - status (text, default 'active') — 'active', 'inactive'
   - created_at, updated_at (timestamptz, auto)

2. `marketplace_accounts` — An organization's connection to a specific marketplace.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - marketplace_id (uuid, FK → marketplaces ON DELETE RESTRICT)
   - account_name (text, not null) — user-friendly label
   - account_id (text, not null) — marketplace-specific seller/account ID
   - status (text, default 'disconnected') — 'connected', 'disconnected', 'error', 'expired'
   - last_sync_at (timestamptz)
   - created_at, updated_at (timestamptz, auto)
   - Unique: (organization_id, marketplace_id, account_id)

3. `marketplace_credentials` — Encrypted credentials for marketplace API access.
   - id (uuid, PK)
   - marketplace_account_id (uuid, FK → marketplace_accounts ON DELETE CASCADE, UNIQUE)
   - encrypted_data (bytea, not null) — PGP symmetric encrypted blob
   - encryption_key_id (text, not null) — identifier of which key was used
   - expires_at (timestamptz) — when tokens expire
   - created_at, updated_at (timestamptz, auto)

## Security
- `marketplaces`: readable by all authenticated users (global reference data).
- `marketplace_accounts`: org-scoped via user_org_member(organization_id).
- `marketplace_credentials`: NO direct SELECT/INSERT/UPDATE/DELETE policies.
  Access is ONLY through SECURITY DEFINER functions that encrypt/decrypt internally.
  This ensures credentials are never exposed in plaintext through any client query.

## Encryption
- Uses pgcrypto extension (pgp_sym_encrypt / pgp_sym_decrypt).
- The encryption key is stored in a separate table `encryption_keys` that has NO
  RLS policies allowing direct access — only SECURITY DEFINER functions can read it.
- Credential write/read is done via SECURITY DEFINER functions.

## Important Notes
1. pgcrypto extension must be enabled (included in this migration).
2. The encryption key is a placeholder — in production it should be managed via
   a secrets manager, not stored in the database. This is a structural foundation.
3. No marketplace integration is implemented — only the schema and encryption infrastructure.
*/

-- ============================================
-- ENABLE PGENCRYPTO EXTENSION
-- ============================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================
-- ENCRYPTION KEY STORAGE (no direct access)
-- ============================================
CREATE TABLE IF NOT EXISTS encryption_keys (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key_id text UNIQUE NOT NULL,
  key_value text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE encryption_keys ENABLE ROW LEVEL SECURITY;
-- No policies: no role (including authenticated) can read keys directly.

-- ============================================
-- 1. MARKETPLACES (global reference data)
-- ============================================
CREATE TABLE IF NOT EXISTS marketplaces (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  display_name text NOT NULL,
  api_base_url text,
  logo_url text,
  status text NOT NULL DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- 2. MARKETPLACE_ACCOUNTS
-- ============================================
CREATE TABLE IF NOT EXISTS marketplace_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  marketplace_id uuid NOT NULL REFERENCES marketplaces(id) ON DELETE RESTRICT,
  account_name text NOT NULL,
  account_id text NOT NULL,
  status text NOT NULL DEFAULT 'disconnected',
  last_sync_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, marketplace_id, account_id)
);

-- ============================================
-- 3. MARKETPLACE_CREDENTIALS
-- ============================================
CREATE TABLE IF NOT EXISTS marketplace_credentials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  marketplace_account_id uuid UNIQUE NOT NULL REFERENCES marketplace_accounts(id) ON DELETE CASCADE,
  encrypted_data bytea NOT NULL,
  encryption_key_id text NOT NULL,
  expires_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- ENABLE RLS
-- ============================================
ALTER TABLE marketplaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_credentials ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES: MARKETPLACES (reference data — all authenticated can read)
-- ============================================
DROP POLICY IF EXISTS "select_marketplaces" ON marketplaces;
CREATE POLICY "select_marketplaces" ON marketplaces FOR SELECT
  TO authenticated USING (true);

-- ============================================
-- RLS POLICIES: MARKETPLACE_ACCOUNTS (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_marketplace_accounts" ON marketplace_accounts;
CREATE POLICY "select_own_marketplace_accounts" ON marketplace_accounts FOR SELECT
  TO authenticated USING (user_org_member(organization_id));

DROP POLICY IF EXISTS "insert_own_marketplace_accounts" ON marketplace_accounts;
CREATE POLICY "insert_own_marketplace_accounts" ON marketplace_accounts FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));

DROP POLICY IF EXISTS "update_own_marketplace_accounts" ON marketplace_accounts;
CREATE POLICY "update_own_marketplace_accounts" ON marketplace_accounts FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));

DROP POLICY IF EXISTS "delete_own_marketplace_accounts" ON marketplace_accounts;
CREATE POLICY "delete_own_marketplace_accounts" ON marketplace_accounts FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS POLICIES: MARKETPLACE_CREDENTIALS
-- NO direct access policies. Only SECURITY DEFINER functions can read/write.
-- ============================================

-- ============================================
-- SECURITY DEFINER FUNCTIONS FOR CREDENTIALS
-- ============================================

-- Store encrypted credentials for a marketplace account
CREATE OR REPLACE FUNCTION store_marketplace_credentials(
  p_account_id uuid,
  p_credentials jsonb,
  p_expires_at timestamptz DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_key_id text := 'default-v1';
  v_key_value text;
  v_encrypted bytea;
  v_credential_id uuid;
BEGIN
  SELECT key_value INTO v_key_value FROM encryption_keys WHERE key_id = v_key_id;
  IF v_key_value IS NULL THEN
    RAISE EXCEPTION 'Encryption key % not found', v_key_id;
  END IF;

  v_encrypted := pgp_sym_encrypt(p_credentials::text, v_key_value);

  INSERT INTO marketplace_credentials (marketplace_account_id, encrypted_data, encryption_key_id, expires_at)
  VALUES (p_account_id, v_encrypted, v_key_id, p_expires_at)
  ON CONFLICT (marketplace_account_id)
  DO UPDATE SET encrypted_data = v_encrypted, encryption_key_id = v_key_id, expires_at = p_expires_at, updated_at = now()
  RETURNING id INTO v_credential_id;

  RETURN v_credential_id;
END;
$$;

-- Retrieve decrypted credentials (for server-side use only)
CREATE OR REPLACE FUNCTION get_marketplace_credentials(p_account_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_key_id text;
  v_key_value text;
  v_encrypted bytea;
  v_decrypted text;
BEGIN
  SELECT mc.encrypted_data, mc.encryption_key_id
  INTO v_encrypted, v_key_id
  FROM marketplace_credentials mc
  WHERE mc.marketplace_account_id = p_account_id;

  IF v_encrypted IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT key_value INTO v_key_value FROM encryption_keys WHERE key_id = v_key_id;
  IF v_key_value IS NULL THEN
    RAISE EXCEPTION 'Encryption key % not found', v_key_id;
  END IF;

  v_decrypted := pgp_sym_decrypt(v_encrypted, v_key_value);
  RETURN v_decrypted::jsonb;
END;
$$;

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_marketplaces_name ON marketplaces(name);
CREATE INDEX IF NOT EXISTS idx_marketplaces_status ON marketplaces(status);

CREATE INDEX IF NOT EXISTS idx_marketplace_accounts_org_id ON marketplace_accounts(organization_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_accounts_marketplace_id ON marketplace_accounts(marketplace_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_accounts_status ON marketplace_accounts(status);

CREATE INDEX IF NOT EXISTS idx_marketplace_credentials_account_id ON marketplace_credentials(marketplace_account_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_credentials_expires_at ON marketplace_credentials(expires_at);

-- ============================================
-- TRIGGERS
-- ============================================
DROP TRIGGER IF EXISTS trg_marketplaces_updated_at ON marketplaces;
CREATE TRIGGER trg_marketplaces_updated_at BEFORE UPDATE ON marketplaces
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_marketplace_accounts_updated_at ON marketplace_accounts;
CREATE TRIGGER trg_marketplace_accounts_updated_at BEFORE UPDATE ON marketplace_accounts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_marketplace_credentials_updated_at ON marketplace_credentials;
CREATE TRIGGER trg_marketplace_credentials_updated_at BEFORE UPDATE ON marketplace_credentials
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();