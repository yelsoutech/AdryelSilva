/*
# RBAC Foundation — Permissions, Role Mapping, Invitations, Authorization Functions

## Overview
This migration implements the complete RBAC (Role-Based Access Control) foundation:
1. Seeds 24 granular permissions into the `permissions` table.
2. Replaces the 'member' role with 'analyst' (matching the spec).
3. Maps every role to its permissions via `role_permissions`.
4. Creates the `organization_invitations` table for future invite flows.
5. Adds `user_has_permission()` and `user_org_permissions()` SECURITY DEFINER functions.
6. Strengthens organization_members RLS policies to require specific permissions.

## Roles (4 system roles)
- **owner** — Full access including billing, member management, organization deletion
- **admin** — Manage marketplaces, users, operational settings, audit. Cannot delete org or transfer ownership.
- **analyst** — Research, products, opportunities, competitors, pricing, analytics. No user/org management.
- **viewer** — Read-only access to dashboard, products, opportunities, analytics.

## Permissions (24 granular permissions)
dashboard.read, products.read, products.create, products.update, products.delete,
research.read, research.create, opportunities.read, competitors.read,
analytics.read, pricing.read, pricing.calculate,
marketplaces.read, marketplaces.manage,
users.read, users.invite, users.update, users.remove,
roles.read, roles.manage,
organization.read, organization.update, organization.delete,
audit.read

## New Tables
- `organization_invitations` — Stores pending invitations to join an organization.

## Security
- `user_has_permission()` runs as SECURITY DEFINER — checks membership + role + permission in one call.
- `user_org_permissions()` returns all permission names for the current user in a given org.
- RLS enabled on `organization_invitations` — only org members can see invitations.
- Insert policy on `organization_invitations` requires `users.invite` permission.
- organization_members INSERT/UPDATE/DELETE policies now require specific permissions.

## Important Notes
1. The 'member' role is renamed to 'analyst'.
2. All role_permission mappings are idempotent (ON CONFLICT DO NOTHING).
3. No email sending is implemented — only the data structure.
*/

-- ============================================
-- 1. FIX ROLES: Replace 'member' with 'analyst'
-- ============================================
UPDATE roles SET name = 'analyst', description = 'Research, products, opportunities, competitors, pricing, analytics' WHERE name = 'member';

INSERT INTO roles (name, description, is_system) VALUES
  ('analyst', 'Research, products, opportunities, competitors, pricing, analytics', true)
ON CONFLICT (name) DO NOTHING;

UPDATE roles SET description = 'Full access including billing and member management' WHERE name = 'owner';
UPDATE roles SET description = 'Manage marketplace accounts, products, and team members' WHERE name = 'admin';
UPDATE roles SET description = 'Read-only access to dashboard and reports' WHERE name = 'viewer';

-- ============================================
-- 2. SEED PERMISSIONS (24 granular permissions)
-- ============================================
INSERT INTO permissions (name, description, resource, action) VALUES
  ('dashboard.read',      'View dashboard',              'dashboard',     'read'),
  ('products.read',       'View products',               'products',      'read'),
  ('products.create',     'Create products',             'products',      'create'),
  ('products.update',     'Update products',             'products',      'update'),
  ('products.delete',     'Delete products',             'products',      'delete'),
  ('research.read',       'View research data',          'research',      'read'),
  ('research.create',     'Create research searches',    'research',      'create'),
  ('opportunities.read',  'View opportunities',          'opportunities', 'read'),
  ('competitors.read',    'View competitor data',        'competitors',   'read'),
  ('analytics.read',      'View analytics',             'analytics',     'read'),
  ('pricing.read',        'View pricing scenarios',      'pricing',       'read'),
  ('pricing.calculate',   'Use pricing simulator',      'pricing',       'calculate'),
  ('marketplaces.read',   'View marketplace accounts',   'marketplaces',  'read'),
  ('marketplaces.manage', 'Manage marketplace accounts', 'marketplaces',  'manage'),
  ('users.read',          'View organization members',   'users',         'read'),
  ('users.invite',        'Invite users to organization','users',        'invite'),
  ('users.update',        'Update member roles',         'users',         'update'),
  ('users.remove',        'Remove members from organization','users',    'remove'),
  ('roles.read',          'View roles and permissions',  'roles',         'read'),
  ('roles.manage',        'Manage roles and permissions','roles',        'manage'),
  ('organization.read',   'View organization settings',  'organization', 'read'),
  ('organization.update', 'Update organization settings','organization', 'update'),
  ('organization.delete', 'Delete organization',         'organization', 'delete'),
  ('audit.read',          'View audit logs',            'audit',         'read')
ON CONFLICT (name) DO NOTHING;

-- ============================================
-- 3. MAP ROLE → PERMISSIONS
-- ============================================

-- OWNER: all permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'owner'
ON CONFLICT DO NOTHING;

-- ADMIN: everything except organization.delete and roles.manage
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'admin' AND p.name NOT IN ('organization.delete', 'roles.manage')
ON CONFLICT DO NOTHING;

-- ANALYST: analytical tools, no management
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'analyst' AND p.name IN (
  'dashboard.read',
  'products.read', 'products.create', 'products.update',
  'research.read', 'research.create',
  'opportunities.read',
  'competitors.read',
  'analytics.read',
  'pricing.read', 'pricing.calculate',
  'marketplaces.read'
)
ON CONFLICT DO NOTHING;

-- VIEWER: read-only
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.name = 'viewer' AND p.name IN (
  'dashboard.read',
  'products.read',
  'opportunities.read',
  'analytics.read',
  'marketplaces.read'
)
ON CONFLICT DO NOTHING;

-- ============================================
-- 4. AUTHORIZATION FUNCTIONS (must exist before RLS policies reference them)
-- ============================================

-- user_has_permission: check if current user has a specific permission in an org
CREATE OR REPLACE FUNCTION user_has_permission(org_id uuid, perm_name text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM organization_members om
    JOIN role_permissions rp ON rp.role_id = om.role_id
    JOIN permissions p ON p.id = rp.permission_id
    WHERE om.organization_id = org_id
    AND om.user_id = auth.uid()
    AND om.status = 'active'
    AND p.name = perm_name
  );
$$;

-- user_org_permissions: return all permission names for current user in an org
CREATE OR REPLACE FUNCTION user_org_permissions(org_id uuid)
RETURNS TABLE(name text)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.name
  FROM organization_members om
  JOIN role_permissions rp ON rp.role_id = om.role_id
  JOIN permissions p ON p.id = rp.permission_id
  WHERE om.organization_id = org_id
  AND om.user_id = auth.uid()
  AND om.status = 'active';
$$;

-- ============================================
-- 5. STRENGTHEN ORGANIZATION_MEMBERS RLS POLICIES
-- ============================================

-- Only users with users.invite permission can add members
DROP POLICY IF EXISTS "insert_own_org_members" ON organization_members;
CREATE POLICY "insert_own_org_members" ON organization_members FOR INSERT
  TO authenticated WITH CHECK (
    user_org_member(organization_id)
    AND user_has_permission(organization_id, 'users.invite')
  );

-- Only users with users.update permission can change member roles
DROP POLICY IF EXISTS "update_own_org_members" ON organization_members;
CREATE POLICY "update_own_org_members" ON organization_members FOR UPDATE
  TO authenticated USING (
    user_org_member(organization_id)
    AND user_has_permission(organization_id, 'users.update')
  )
  WITH CHECK (
    user_org_member(organization_id)
    AND user_has_permission(organization_id, 'users.update')
  );

-- Only users with users.remove permission can remove members
DROP POLICY IF EXISTS "delete_own_org_members" ON organization_members;
CREATE POLICY "delete_own_org_members" ON organization_members FOR DELETE
  TO authenticated USING (
    user_org_member(organization_id)
    AND user_has_permission(organization_id, 'users.remove')
  );

-- ============================================
-- 6. ORGANIZATION_INVITATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS organization_invitations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  email text NOT NULL,
  role_id uuid NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'pending',
  invited_by uuid REFERENCES users(id) ON DELETE SET NULL,
  token uuid NOT NULL DEFAULT gen_random_uuid(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '7 days'),
  accepted_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_org_invitations_pending_unique
  ON organization_invitations(organization_id, email)
  WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_org_invitations_org_id ON organization_invitations(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_invitations_email ON organization_invitations(email);
CREATE INDEX IF NOT EXISTS idx_org_invitations_token ON organization_invitations(token);
CREATE INDEX IF NOT EXISTS idx_org_invitations_status ON organization_invitations(status);

ALTER TABLE organization_invitations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "select_own_org_invitations" ON organization_invitations;
CREATE POLICY "select_own_org_invitations" ON organization_invitations FOR SELECT
  TO authenticated USING (user_org_member(organization_id));

DROP POLICY IF EXISTS "insert_own_org_invitations" ON organization_invitations;
CREATE POLICY "insert_own_org_invitations" ON organization_invitations FOR INSERT
  TO authenticated WITH CHECK (
    user_org_member(organization_id)
    AND user_has_permission(organization_id, 'users.invite')
  );

DROP POLICY IF EXISTS "update_own_org_invitations" ON organization_invitations;
CREATE POLICY "update_own_org_invitations" ON organization_invitations FOR UPDATE
  TO authenticated USING (user_org_member(organization_id))
  WITH CHECK (user_org_member(organization_id));

DROP POLICY IF EXISTS "delete_own_org_invitations" ON organization_invitations;
CREATE POLICY "delete_own_org_invitations" ON organization_invitations FOR DELETE
  TO authenticated USING (
    user_org_member(organization_id)
    AND user_has_permission(organization_id, 'users.remove')
  );

DROP TRIGGER IF EXISTS trg_org_invitations_updated_at ON organization_invitations;
CREATE TRIGGER trg_org_invitations_updated_at BEFORE UPDATE ON organization_invitations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();