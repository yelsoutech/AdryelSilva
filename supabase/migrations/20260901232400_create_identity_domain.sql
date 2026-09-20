/*
# Identity Domain — Organizations, Users, Roles, Permissions

## Overview
Creates the identity and access management foundation for multi-tenant isolation.
Organizations are the primary tenant boundary. Users belong to organizations via
organization_members with role-based access control (RBAC).

## New Tables

1. `organizations` — The primary tenant entity. Each organization is an isolated workspace.
   - id (uuid, PK)
   - name (text, not null)
   - slug (text, unique) — URL-friendly identifier
   - status (text, default 'active') — 'active', 'suspended', 'deleted'
   - created_at, updated_at (timestamptz, auto)

2. `users` — Application users (separate from auth.users). Links to Supabase auth.
   - id (uuid, PK, FK → auth.users ON DELETE CASCADE)
   - email (text, unique, not null)
   - full_name (text)
   - avatar_url (text)
   - status (text, default 'active')
   - created_at, updated_at (timestamptz, auto)

3. `roles` — Global role definitions (e.g., 'owner', 'admin', 'member', 'viewer').
   - id (uuid, PK)
   - name (text, unique, not null)
   - description (text)
   - is_system (boolean, default false) — system roles cannot be deleted
   - created_at (timestamptz)

4. `permissions` — Global permission definitions (e.g., 'products:read', 'marketplaces:write').
   - id (uuid, PK)
   - name (text, unique, not null)
   - description (text)
   - resource (text, not null)
   - action (text, not null) — 'read', 'write', 'delete', 'admin'
   - created_at (timestamptz)

5. `role_permissions` — Many-to-many between roles and permissions.
   - role_id (uuid, FK → roles ON DELETE CASCADE)
   - permission_id (uuid, FK → permissions ON DELETE CASCADE)
   - PK: (role_id, permission_id)

6. `organization_members` — Links users to organizations with a role.
   - id (uuid, PK)
   - organization_id (uuid, FK → organizations ON DELETE CASCADE)
   - user_id (uuid, FK → users ON DELETE CASCADE)
   - role_id (uuid, FK → roles ON DELETE RESTRICT)
   - status (text, default 'active')
   - invited_by (uuid, FK → users, nullable)
   - joined_at (timestamptz, default now())
   - Unique: (organization_id, user_id)

## Security
- RLS enabled on all tables.
- organizations: members can access orgs they belong to.
- users: users can read/update their own profile.
- roles/permissions/role_permissions: readable by all authenticated users (reference data).
- organization_members: members can see who's in their org.

## Important Notes
1. `users` table has FK to `auth.users` — a trigger to auto-create rows on signup
   is NOT included yet (auth not implemented).
2. System roles will be seeded in a later migration.
3. RLS policies use helper functions that check organization_members membership.
*/

-- ============================================
-- 1. ORGANIZATIONS
-- ============================================
CREATE TABLE IF NOT EXISTS organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  status text NOT NULL DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- 2. USERS
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text,
  avatar_url text,
  status text NOT NULL DEFAULT 'active',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- ============================================
-- 3. ROLES
-- ============================================
CREATE TABLE IF NOT EXISTS roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  description text,
  is_system boolean NOT NULL DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- 4. PERMISSIONS
-- ============================================
CREATE TABLE IF NOT EXISTS permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text UNIQUE NOT NULL,
  description text,
  resource text NOT NULL,
  action text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- ============================================
-- 5. ROLE_PERMISSIONS
-- ============================================
CREATE TABLE IF NOT EXISTS role_permissions (
  role_id uuid NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  permission_id uuid NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

-- ============================================
-- 6. ORGANIZATION_MEMBERS
-- ============================================
CREATE TABLE IF NOT EXISTS organization_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id uuid NOT NULL REFERENCES roles(id) ON DELETE RESTRICT,
  status text NOT NULL DEFAULT 'active',
  invited_by uuid REFERENCES users(id),
  joined_at timestamptz DEFAULT now(),
  UNIQUE(organization_id, user_id)
);

-- ============================================
-- HELPER FUNCTIONS (SECURITY DEFINER — bypass RLS for membership checks)
-- ============================================
CREATE OR REPLACE FUNCTION user_org_member(org_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_id = org_id
    AND user_id = auth.uid()
    AND status = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION user_org_role(org_id uuid)
RETURNS text
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT r.name FROM organization_members om
  JOIN roles r ON r.id = om.role_id
  WHERE om.organization_id = org_id
  AND om.user_id = auth.uid()
  AND om.status = 'active';
$$;

-- ============================================
-- ENABLE RLS ON ALL TABLES
-- ============================================
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;

-- ============================================
-- RLS POLICIES: ORGANIZATIONS
-- ============================================
DROP POLICY IF EXISTS "select_own_org" ON organizations;
CREATE POLICY "select_own_org" ON organizations FOR SELECT
  TO authenticated USING (user_org_member(id));

DROP POLICY IF EXISTS "insert_org" ON organizations;
CREATE POLICY "insert_org" ON organizations FOR INSERT
  TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "update_own_org" ON organizations;
CREATE POLICY "update_own_org" ON organizations FOR UPDATE
  TO authenticated USING (user_org_member(id)) WITH CHECK (user_org_member(id));

DROP POLICY IF EXISTS "delete_own_org" ON organizations;
CREATE POLICY "delete_own_org" ON organizations FOR DELETE
  TO authenticated USING (user_org_member(id));

-- ============================================
-- RLS POLICIES: USERS
-- ============================================
DROP POLICY IF EXISTS "select_own_user" ON users;
CREATE POLICY "select_own_user" ON users FOR SELECT
  TO authenticated USING (auth.uid() = id);

DROP POLICY IF EXISTS "insert_own_user" ON users;
CREATE POLICY "insert_own_user" ON users FOR INSERT
  TO authenticated WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "update_own_user" ON users;
CREATE POLICY "update_own_user" ON users FOR UPDATE
  TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- ============================================
-- RLS POLICIES: ROLES (reference data — readable by all authenticated)
-- ============================================
DROP POLICY IF EXISTS "select_roles" ON roles;
CREATE POLICY "select_roles" ON roles FOR SELECT
  TO authenticated USING (true);

-- ============================================
-- RLS POLICIES: PERMISSIONS (reference data — readable by all authenticated)
-- ============================================
DROP POLICY IF EXISTS "select_permissions" ON permissions;
CREATE POLICY "select_permissions" ON permissions FOR SELECT
  TO authenticated USING (true);

-- ============================================
-- RLS POLICIES: ROLE_PERMISSIONS (reference data — readable by all authenticated)
-- ============================================
DROP POLICY IF EXISTS "select_role_permissions" ON role_permissions;
CREATE POLICY "select_role_permissions" ON role_permissions FOR SELECT
  TO authenticated USING (true);

-- ============================================
-- RLS POLICIES: ORGANIZATION_MEMBERS
-- ============================================
DROP POLICY IF EXISTS "select_own_org_members" ON organization_members;
CREATE POLICY "select_own_org_members" ON organization_members FOR SELECT
  TO authenticated USING (user_org_member(organization_id));

DROP POLICY IF EXISTS "insert_own_org_members" ON organization_members;
CREATE POLICY "insert_own_org_members" ON organization_members FOR INSERT
  TO authenticated WITH CHECK (user_org_member(organization_id));

DROP POLICY IF EXISTS "update_own_org_members" ON organization_members;
CREATE POLICY "update_own_org_members" ON organization_members FOR UPDATE
  TO authenticated USING (user_org_member(organization_id)) WITH CHECK (user_org_member(organization_id));

DROP POLICY IF EXISTS "delete_own_org_members" ON organization_members;
CREATE POLICY "delete_own_org_members" ON organization_members FOR DELETE
  TO authenticated USING (user_org_member(organization_id));

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_organizations_slug ON organizations(slug);
CREATE INDEX IF NOT EXISTS idx_organizations_status ON organizations(status);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

CREATE INDEX IF NOT EXISTS idx_org_members_org_id ON organization_members(organization_id);
CREATE INDEX IF NOT EXISTS idx_org_members_user_id ON organization_members(user_id);
CREATE INDEX IF NOT EXISTS idx_org_members_role_id ON organization_members(role_id);

CREATE INDEX IF NOT EXISTS idx_role_permissions_role_id ON role_permissions(role_id);
CREATE INDEX IF NOT EXISTS idx_role_permissions_permission_id ON role_permissions(permission_id);

CREATE INDEX IF NOT EXISTS idx_permissions_resource ON permissions(resource);
CREATE INDEX IF NOT EXISTS idx_permissions_action ON permissions(action);

-- ============================================
-- UPDATED_AT TRIGGER
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_organizations_updated_at ON organizations;
CREATE TRIGGER trg_organizations_updated_at BEFORE UPDATE ON organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();