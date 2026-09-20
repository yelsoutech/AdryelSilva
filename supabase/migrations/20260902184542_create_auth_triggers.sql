/*
# Auth Triggers — Auto-create user profile, organization, and membership on signup

## Overview
When a new user signs up via Supabase Auth, three things must happen automatically:
1. A row in the `users` table (links to auth.users)
2. A new `organization` for this user (they become the owner)
3. A `organization_members` row linking user → organization with the 'owner' role

This migration also seeds the system roles ('owner', 'admin', 'member', 'viewer').

## Changes
1. Seeds 4 system roles into `roles` table.
2. Creates a `handle_new_user()` trigger function that:
   - Inserts into `users` (id, email from auth.users)
   - Creates a default organization (slug derived from email)
   - Inserts an `organization_members` row with the 'owner' role
3. Attaches the trigger to `auth.users` ON INSERT.

## Security
- The trigger function runs as SECURITY DEFINER (bypasses RLS) because auth.users
  inserts happen server-side and the helper tables have RLS enabled.
- The function only runs on INSERT — it cannot be called directly by users.
- Organization slug is derived from email prefix + random suffix to ensure uniqueness.

## Important Notes
1. Email confirmation is OFF — users can sign in immediately after signup.
2. Each user gets exactly one organization on signup. They can be invited to others later.
3. The 'owner' role is assigned to the creating user. System roles cannot be deleted.
*/

-- ============================================
-- SEED SYSTEM ROLES
-- ============================================
INSERT INTO roles (name, description, is_system) VALUES
  ('owner', 'Full access including billing and member management', true),
  ('admin', 'Manage marketplace accounts, products, and team members', true),
  ('member', 'Access to marketplace data and tools', true),
  ('viewer', 'Read-only access to dashboard and reports', true)
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- TRIGGER FUNCTION: Handle new user signup
-- ============================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_owner_role_id uuid;
  v_org_id uuid;
  v_slug text;
  v_email_prefix text;
BEGIN
  -- Get the 'owner' role ID
  SELECT id INTO v_owner_role_id FROM roles WHERE name = 'owner' LIMIT 1;
  IF v_owner_role_id IS NULL THEN
    RAISE EXCEPTION 'Owner role not found. Ensure roles are seeded.';
  END IF;

  -- Insert into users table
  INSERT INTO users (id, email, full_name)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', ''))
  ON CONFLICT (id) DO NOTHING;

  -- Generate a unique slug from email prefix
  v_email_prefix := split_part(NEW.email, '@', 1);
  v_slug := lower(v_email_prefix) || '-' || substr(replace(gen_random_uuid()::text, '-', ''), 1, 8);

  -- Create default organization
  INSERT INTO organizations (name, slug)
  VALUES (COALESCE(NEW.raw_user_meta_data->>'organization_name', v_email_prefix || '''s Workspace'), v_slug)
  RETURNING id INTO v_org_id;

  -- Create organization membership with owner role
  INSERT INTO organization_members (organization_id, user_id, role_id, status)
  VALUES (v_org_id, NEW.id, v_owner_role_id, 'active');

  RETURN NEW;
END;
$$;

-- ============================================
-- ATTACH TRIGGER TO auth.users
-- ============================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();