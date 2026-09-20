/*
# Products Domain — Categories, Brands, Sellers, Products, Product Listings

## Overview
Creates the product catalog tables. Categories, brands, and sellers are global
reference data (shared across organizations). Products are org-scoped. Product
listings represent a product listed on a specific marketplace.

## New Tables

1. `categories` — Global category taxonomy (shared reference data).
   - id (uuid, PK)
   - name (text, not null)
   - parent_id (uuid, FK → categories, nullable) — hierarchical
   - marketplace_id (uuid, FK → marketplaces) — which marketplace this category belongs to
   - external_id (text) — category ID in the marketplace
   - created_at (timestamptz)

2. `brands` — Global brand registry (shared reference data).
   - id (uuid, PK)
   - name (text, unique, not null)
   - logo_url (text)
   - created_at (timestamptz)

3. `sellers` — Global seller registry (shared reference data).
   - id (uuid, PK)
   - marketplace_id (uuid, FK → marketplaces)
   - external_id (text, not null) — seller ID in the marketplace
   - name (text)
   - reputation_score (numeric)
   - created_at, updated_at (timestamptz, auto)
   - Unique: (marketplace_id, external_id)

4. `products` — Products tracked by an organization.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - brand_id (uuid, FK → brands, nullable)
   - name (text, not null)
   - description (text)
   - sku (text) — internal SKU
   - ean (text) — barcode
   - status (text, default 'active')
   - created_at, updated_at (timestamptz, auto)

5. `product_listings` — A product listed on a specific marketplace.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - product_id (uuid, FK → products ON DELETE CASCADE)
   - marketplace_id (uuid, FK → marketplaces ON DELETE RESTRICT)
   - marketplace_account_id (uuid, FK → marketplace_accounts ON DELETE CASCADE)
   - seller_id (uuid, FK → sellers, nullable)
   - category_id (uuid, FK → categories, nullable)
   - external_id (text, not null) — listing ID in the marketplace
   - external_url (text) — URL of the listing
   - title (text)
   - price_cents (bigint)
   - currency (text, default 'BRL')
   - status (text, default 'active')
   - raw_data (jsonb) — last raw payload from marketplace
   - collected_at (timestamptz) — when data was last collected
   - created_at, updated_at (timestamptz, auto)
   - Unique: (organization_id, marketplace_id, external_id)

## Security
- categories/brands/sellers: readable by all authenticated users (global reference data).
- products/product_listings: org-scoped via user_org_member(organization_id).

## Important Notes
1. Categories are marketplace-specific (a Mercado Livre category differs from an Amazon one).
2. Product listings link a product to a marketplace via the org's marketplace account.
3. raw_data stores the last raw payload — useful for debugging and re-parsing.
4. No data has been seeded. No marketplace integration is implemented.
*/

-- ============================================
-- 1. CATEGORIES (global reference data)
-- ============================================
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  parent_id uuid REFERENCES categories(id) ON DELETE SET NULL,
  marketplace_id uuid REFERENCES marketplaces(id) ON DELETE CASCADE,
  external_id text,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- 2. BRANDS (global reference data)
-- ============================================
CREATE TABLE IF NOT EXISTS brands (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  logo_url text,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- 3. SELLERS (global reference data)
-- ============================================
CREATE TABLE IF NOT EXISTS sellers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  marketplace_id uuid NOT NULL REFERENCES marketplaces(id) ON DELETE CASCADE,
  external_id text NOT NULL,
  name text,
  reputation_score numeric,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(marketplace_id, external_id)
);

-- ============================================
-- 4. PRODUCTS (org-scoped)
-- ============================================
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  brand_id uuid REFERENCES brands(id) ON DELETE SET NULL,
  name text NOT NULL,
  description text,
  sku text,
  ean text,
  status text NOT NULL DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- 5. PRODUCT_LISTINGS (org-scoped)
-- ============================================
CREATE TABLE IF NOT EXISTS product_listings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  marketplace_id uuid NOT NULL REFERENCES marketplaces(id) ON DELETE RESTRICT,
  marketplace_account_id uuid NOT NULL REFERENCES marketplace_accounts(id) ON DELETE CASCADE,
  seller_id uuid REFERENCES sellers(id) ON DELETE SET NULL,
  category_id uuid REFERENCES categories(id) ON DELETE SET NULL,
  external_id text NOT NULL,
  external_url text,
  title text,
  price_cents bigint,
  currency text NOT NULL DEFAULT 'BRL',
  status text NOT NULL DEFAULT 'active',
  raw_data jsonb,
  collected_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, marketplace_id, external_id)
);

-- ============================================
-- ENABLE RLS
-- ============================================
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE sellers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_listings ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES: CATEGORIES (reference data)
-- ============================================
DROP POLICY IF EXISTS "select_categories" ON categories;
CREATE POLICY "select_categories" ON categories FOR SELECT
  TO authenticated USING (true);

-- ============================================
-- RLS POLICIES: BRANDS (reference data)
-- ============================================
DROP POLICY IF EXISTS "select_brands" ON brands;
CREATE POLICY "select_brands" ON brands FOR SELECT
  TO authenticated USING (true);

-- ============================================
-- RLS POLICIES: SELLERS (reference data)
-- ============================================
DROP POLICY IF EXISTS "select_sellers" ON sellers;
CREATE POLICY "select_sellers" ON sellers FOR SELECT
  TO authenticated USING (true);

-- ============================================
-- RLS POLICIES: PRODUCTS (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_products" ON products;
CREATE POLICY "select_own_products" ON products FOR SELECT
  TO authenticated USING (user_org_member(organization_id));

DROP POLICY IF EXISTS "insert_own_products" ON products;
CREATE POLICY "insert_own_products" ON products FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));

DROP POLICY IF EXISTS "update_own_products" ON products;
CREATE POLICY "update_own_products" ON products FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));

DROP POLICY IF EXISTS "delete_own_products" ON products;
CREATE POLICY "delete_own_products" ON products FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- RLS POLICIES: PRODUCT_LISTINGS (org-scoped)
-- ============================================
DROP POLICY IF EXISTS "select_own_product_listings" ON product_listings;
CREATE POLICY "select_own_product_listings" ON product_listings FOR SELECT
  TO authenticated USING (user_org_member(organization_id));

DROP POLICY IF EXISTS "insert_own_product_listings" ON product_listings;
CREATE POLICY "insert_own_product_listings" ON product_listings FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));

DROP POLICY IF EXISTS "update_own_product_listings" ON product_listings;
CREATE POLICY "update_own_product_listings" ON product_listings FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));

DROP POLICY IF EXISTS "delete_own_product_listings" ON product_listings;
CREATE POLICY "delete_own_product_listings" ON product_listings FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_categories_parent_id ON categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_categories_marketplace_id ON categories(marketplace_id);
CREATE INDEX IF NOT EXISTS idx_categories_external_id ON categories(external_id);

CREATE INDEX IF NOT EXISTS idx_brands_name ON brands(name);

CREATE INDEX IF NOT EXISTS idx_sellers_marketplace_id ON sellers(marketplace_id);
CREATE INDEX IF NOT EXISTS idx_sellers_external_id ON sellers(external_id);

CREATE INDEX IF NOT EXISTS idx_products_organization_id ON products(organization_id);
CREATE INDEX IF NOT EXISTS idx_products_brand_id ON products(brand_id);
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_products_ean ON products(ean);

CREATE INDEX IF NOT EXISTS idx_product_listings_organization_id ON product_listings(organization_id);
CREATE INDEX IF NOT EXISTS idx_product_listings_product_id ON product_listings(product_id);
CREATE INDEX IF NOT EXISTS idx_product_listings_marketplace_id ON product_listings(marketplace_id);
CREATE INDEX IF NOT EXISTS idx_product_listings_marketplace_account_id ON product_listings(marketplace_account_id);
CREATE INDEX IF NOT EXISTS idx_product_listings_seller_id ON product_listings(seller_id);
CREATE INDEX IF NOT EXISTS idx_product_listings_category_id ON product_listings(category_id);
CREATE INDEX IF NOT EXISTS idx_product_listings_status ON product_listings(status);
CREATE INDEX IF NOT EXISTS idx_product_listings_external_id ON product_listings(external_id);

-- ============================================
-- TRIGGERS
-- ============================================
DROP TRIGGER IF EXISTS trg_sellers_updated_at ON sellers;
CREATE TRIGGER trg_sellers_updated_at BEFORE UPDATE ON sellers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_products_updated_at ON products;
CREATE TRIGGER trg_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_product_listings_updated_at ON product_listings;
CREATE TRIGGER trg_product_listings_updated_at BEFORE UPDATE ON product_listings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();