'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/lib/auth-context';
import { supabase } from '@/lib/supabase/client';
import { PERMISSIONS } from '@/lib/permissions';
import type { PermissionName } from '@/lib/permissions';
import { ProtectedRoute } from '@/components/protected-route';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { UserPlus, Trash2, Loader2, Mail, Shield } from 'lucide-react';
import type { OrganizationMember, Role } from '@/lib/types';

interface MemberWithRole extends OrganizationMember {
  roles: Role | null;
  users: { email: string; full_name: string | null } | null;
}

export default function TeamPage() {
  const { organization, hasPermission, user } = useAuth();
  const [members, setMembers] = useState<MemberWithRole[]>([]);
  const [roles, setRoles] = useState<Role[]>([]);
  const [loading, setLoading] = useState(true);
  const [inviteEmail, setInviteEmail] = useState('');
  const [inviteRoleId, setInviteRoleId] = useState('');
  const [inviting, setInviting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const canInvite = hasPermission(PERMISSIONS.USERS_INVITE);
  const canRemove = hasPermission(PERMISSIONS.USERS_REMOVE);
  const canUpdate = hasPermission(PERMISSIONS.USERS_UPDATE);

  useEffect(() => {
    if (!organization) return;
    fetchData();
  }, [organization]);

  async function fetchData() {
    if (!organization) return;
    setLoading(true);

    const { data: membersData } = await supabase
      .from('organization_members')
      .select('*, roles(*), users(email, full_name)')
      .eq('organization_id', organization.id)
      .eq('status', 'active')
      .order('joined_at', { ascending: true });

    setMembers((membersData as MemberWithRole[]) || []);

    const { data: rolesData } = await supabase
      .from('roles')
      .select('*')
      .order('name');

    setRoles(rolesData || []);
    setLoading(false);
  }

  async function handleInvite(e: React.FormEvent) {
    e.preventDefault();
    if (!organization || !inviteEmail || !inviteRoleId) return;

    setInviting(true);
    setError(null);

    const { error } = await (supabase as unknown as {
      from: (table: string) => {
        insert: (values: Record<string, unknown>) => Promise<{ error: { message: string } | null }>;
      };
    }).from('organization_invitations').insert({
      organization_id: organization.id,
      email: inviteEmail,
      role_id: inviteRoleId,
      invited_by: user?.id ?? null,
    });

    if (error) {
      setError(error.message === 'duplicate key value violates unique constraint'
        ? 'Ja existe um convite pendente para este email.'
        : error.message
      );
    } else {
      setInviteEmail('');
      setInviteRoleId('');
    }
    setInviting(false);
  }

  async function handleRemoveMember(memberId: string) {
    if (!organization) return;
    await supabase
      .from('organization_members')
      .delete()
      .eq('id', memberId);
    fetchData();
  }

  async function handleRoleChange(memberId: string, newRoleId: string) {
    if (!organization) return;
    await (supabase as unknown as {
      from: (table: string) => {
        update: (values: Record<string, unknown>) => { eq: (col: string, val: string) => Promise<void> };
      };
    }).from('organization_members').update({ role_id: newRoleId }).eq('id', memberId);
    fetchData();
  }

  return (
    <ProtectedRoute permission={PERMISSIONS.USERS_READ}>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Equipe</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Gerencie os membros da sua organizacao e suas permissoes.
          </p>
        </div>

        {canInvite && (
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <UserPlus className="h-4 w-4" />
                Convidar membro
              </CardTitle>
              <CardDescription>
                Envie um convite para um novo membro se juntar a sua organizacao.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleInvite} className="flex flex-col gap-4 sm:flex-row sm:items-end">
                <div className="flex-1 space-y-2">
                  <Label htmlFor="invite-email">Email</Label>
                  <Input
                    id="invite-email"
                    type="email"
                    placeholder="novo@empresa.com.br"
                    value={inviteEmail}
                    onChange={(e) => setInviteEmail(e.target.value)}
                    required
                    disabled={inviting}
                  />
                </div>
                <div className="flex-1 space-y-2">
                  <Label htmlFor="invite-role">Funcao</Label>
                  <select
                    id="invite-role"
                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm"
                    value={inviteRoleId}
                    onChange={(e) => setInviteRoleId(e.target.value)}
                    required
                    disabled={inviting}
                  >
                    <option value="">Selecione...</option>
                    {roles.map((r) => (
                      <option key={r.id} value={r.id}>{r.name}</option>
                    ))}
                  </select>
                </div>
                <Button type="submit" disabled={inviting}>
                  {inviting ? <Loader2 className="h-4 w-4 animate-spin" /> : 'Convidar'}
                </Button>
              </form>
              {error && (
                <p className="mt-3 text-sm text-destructive">{error}</p>
              )}
            </CardContent>
          </Card>
        )}

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-base">
              <Shield className="h-4 w-4" />
              Membros da organizacao
            </CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="flex h-32 items-center justify-center">
                <Loader2 className="h-6 w-6 animate-spin text-primary" />
              </div>
            ) : members.length === 0 ? (
              <p className="py-8 text-center text-sm text-muted-foreground">
                Nenhum membro encontrado.
              </p>
            ) : (
              <div className="space-y-3">
                {members.map((member) => (
                  <div
                    key={member.id}
                    className="flex items-center justify-between rounded-lg border p-4"
                  >
                    <div className="flex items-center gap-3">
                      <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-sm font-semibold text-white">
                        {(member.users?.email || '?').charAt(0).toUpperCase()}
                      </div>
                      <div>
                        <p className="text-sm font-medium">{member.users?.email}</p>
                        <p className="text-xs text-muted-foreground">
                          {member.users?.full_name || 'Sem nome'}
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      {canUpdate && member.user_id !== user?.id ? (
                        <select
                          className="flex h-9 rounded-md border border-input bg-background px-3 text-sm capitalize"
                          value={member.role_id}
                          onChange={(e) => handleRoleChange(member.id, e.target.value)}
                        >
                          {roles.map((r) => (
                            <option key={r.id} value={r.id}>{r.name}</option>
                          ))}
                        </select>
                      ) : (
                        <Badge variant="secondary" className="capitalize">
                          {member.roles?.name}
                        </Badge>
                      )}

                      {canRemove && member.user_id !== user?.id && (
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleRemoveMember(member.id)}
                        >
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </ProtectedRoute>
  );
}
