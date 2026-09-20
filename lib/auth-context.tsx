'use client';

import { createContext, useContext, useEffect, useState, useCallback } from 'react';
import type { Session, User } from '@supabase/supabase-js';
import { supabase } from '@/lib/supabase/client';
import type { Organization } from '@/lib/types';
import type { PermissionName } from '@/lib/permissions';

interface AuthContextValue {
  session: Session | null;
  user: User | null;
  organization: Organization | null;
  role: string | null;
  permissions: PermissionName[];
  loading: boolean;
  signOut: () => Promise<void>;
  refreshOrganization: () => Promise<void>;
  hasPermission: (permission: PermissionName) => boolean;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [organization, setOrganization] = useState<Organization | null>(null);
  const [role, setRole] = useState<string | null>(null);
  const [permissions, setPermissions] = useState<PermissionName[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchOrganization = useCallback(async (userId: string) => {
    const { data: member } = await supabase
      .from('organization_members')
      .select('organization_id, role_id')
      .eq('user_id', userId)
      .eq('status', 'active')
      .order('joined_at', { ascending: true })
      .limit(1)
      .maybeSingle();

    const orgId = (member as { organization_id: string; role_id: string } | null)?.organization_id;
    const roleId = (member as { organization_id: string; role_id: string } | null)?.role_id;

    if (orgId) {
      const { data: org } = await supabase
        .from('organizations')
        .select('*')
        .eq('id', orgId)
        .maybeSingle();
      setOrganization(org as Organization | null);

      if (roleId) {
        const { data: roleData } = await supabase
          .from('roles')
          .select('name')
          .eq('id', roleId)
          .maybeSingle();
        setRole((roleData as { name: string } | null)?.name ?? null);

        const { data: perms } = await supabase
          .from('role_permissions')
          .select('permissions(name)')
          .eq('role_id', roleId);

        const permNames: PermissionName[] = (perms as unknown as { permissions: { name: string } | null }[] | null)
          ?.map((rp) => rp?.permissions?.name)
          .filter((n): n is string => !!n) as PermissionName[] ?? [];
        setPermissions(permNames);
      }
    } else {
      setOrganization(null);
      setRole(null);
      setPermissions([]);
    }
  }, []);

  const refreshOrganization = useCallback(async () => {
    if (user) {
      await fetchOrganization(user.id);
    }
  }, [user, fetchOrganization]);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchOrganization(session.user.id).finally(() => setLoading(false));
      } else {
        setLoading(false);
      }
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchOrganization(session.user.id);
      } else {
        setOrganization(null);
        setRole(null);
        setPermissions([]);
      }
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, [fetchOrganization]);

  const signOut = useCallback(async () => {
    await supabase.auth.signOut();
    setSession(null);
    setUser(null);
    setOrganization(null);
    setRole(null);
    setPermissions([]);
  }, []);

  const hasPermission = useCallback((permission: PermissionName) => {
    return permissions.includes(permission);
  }, [permissions]);

  return (
    <AuthContext.Provider value={{ session, user, organization, role, permissions, loading, signOut, refreshOrganization, hasPermission }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
