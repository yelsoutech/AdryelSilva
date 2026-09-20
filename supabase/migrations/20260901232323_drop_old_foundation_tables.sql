/*
# Drop Old Foundation Tables

## Overview
Removes the 6 empty foundation tables from the initial FASE 0 schema.
They are being replaced by the new comprehensive multi-tenant schema.

## Tables Being Dropped (all empty, 0 rows)
- normalized_listings
- raw_marketplace_data
- collection_jobs
- marketplace_accounts
- tenant_users
- tenants

## Triggers/Functions Being Dropped
- trg_collection_jobs_updated_at trigger
- trg_marketplace_accounts_updated_at trigger
- trg_tenants_updated_at trigger
- update_updated_at_column() function

## Safety
All tables confirmed to have 0 rows. No data loss.
*/

DROP TABLE IF EXISTS normalized_listings CASCADE;
DROP TABLE IF EXISTS raw_marketplace_data CASCADE;
DROP TABLE IF EXISTS collection_jobs CASCADE;
DROP TABLE IF EXISTS marketplace_accounts CASCADE;
DROP TABLE IF EXISTS tenant_users CASCADE;
DROP TABLE IF EXISTS tenants CASCADE;

DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;