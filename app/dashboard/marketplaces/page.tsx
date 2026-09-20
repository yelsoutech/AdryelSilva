'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/lib/auth-context';
import { supabase } from '@/lib/supabase/client';
import { PERMISSIONS } from '@/lib/permissions';
import { ProtectedRoute } from '@/components/protected-route';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Store, Plus, Trash2, Loader2, RefreshCw, CheckCircle2, XCircle, AlertCircle } from 'lucide-react';
import type { Marketplace, MarketplaceAccount } from '@/lib/types';

type AccountWithMarketplace = MarketplaceAccount & {
  marketplaces: Marketplace | null;
};

const STATUS_CONFIG: Record<string, { label: string; variant: 'success' | 'warning' | 'destructive' | 'secondary'; icon: typeof CheckCircle2 }> = {
  connected: { label: 'Connected', variant: 'success', icon: CheckCircle2 },
  disconnected: { label: 'Disconnected', variant: 'secondary', icon: XCircle },
  error: { label: 'Error', variant: 'destructive', icon: AlertCircle },
  pending: { label: 'Pending', variant: 'warning', icon: AlertCircle },
};

export default function MarketplacesPage() {
  const { organization, hasPermission } = useAuth();
  const [accounts, setAccounts] = useState<AccountWithMarketplace[]>([]);
  const [marketplaces, setMarketplaces] = useState<Marketplace[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [selectedMarketplace, setSelectedMarketplace] = useState('');
  const [accountName, setAccountName] = useState('');
  const [accountId, setAccountId] = useState('');

  const canManage = hasPermission(PERMISSIONS.MARKETPLACES_MANAGE);

  const fetchData = useCallback(async () => {
    if (!organization) return;
    setLoading(true);

    const [accountsRes, marketplacesRes] = await Promise.all([
      supabase
        .from('marketplace_accounts')
        .select('*, marketplaces(*)')
        .eq('organization_id', organization.id)
        .order('created_at', { ascending: false }),
      supabase
        .from('marketplaces')
        .select('*')
        .eq('status', 'active')
        .order('display_name'),
    ]);

    setAccounts((accountsRes.data as AccountWithMarketplace[]) || []);
    setMarketplaces((marketplacesRes.data as Marketplace[]) || []);
    setLoading(false);
  }, [organization]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  async function handleConnect(e: React.FormEvent) {
    e.preventDefault();
    if (!organization || !selectedMarketplace || !accountName || !accountId) return;

    setSubmitting(true);
    setError(null);

    const insertData = {
      organization_id: organization.id,
      marketplace_id: selectedMarketplace,
      account_name: accountName,
      account_id: accountId,
      status: 'disconnected',
    };
    const { error: insertError } = await (supabase as unknown as {
      from: (table: string) => {
        insert: (values: Record<string, unknown>) => Promise<{ error: { message: string } | null }>;
      };
    }).from('marketplace_accounts').insert(insertData);

    if (insertError) {
      setError(insertError.message);
    } else {
      setDialogOpen(false);
      setSelectedMarketplace('');
      setAccountName('');
      setAccountId('');
      fetchData();
    }
    setSubmitting(false);
  }

  async function handleDelete(accountId: string) {
    if (!organization) return;
    await supabase
      .from('marketplace_accounts')
      .delete()
      .eq('id', accountId)
      .eq('organization_id', organization.id);
    fetchData();
  }

  return (
    <ProtectedRoute permission={PERMISSIONS.MARKETPLACES_READ}>
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold tracking-tight">Marketplaces</h1>
            <p className="mt-1 text-sm text-muted-foreground">
              Connect and manage your marketplace accounts.
            </p>
          </div>
          {canManage && (
            <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
              <DialogTrigger asChild>
                <Button>
                  <Plus className="mr-2 h-4 w-4" />
                  Add Account
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>Connect Marketplace Account</DialogTitle>
                  <DialogDescription>
                    Add a marketplace seller account to start collecting data.
                  </DialogDescription>
                </DialogHeader>
                <form onSubmit={handleConnect} className="space-y-4">
                  <div className="space-y-2">
                    <Label htmlFor="marketplace">Marketplace</Label>
                    <Select value={selectedMarketplace} onValueChange={setSelectedMarketplace}>
                      <SelectTrigger id="marketplace">
                        <SelectValue placeholder="Select a marketplace" />
                      </SelectTrigger>
                      <SelectContent>
                        {marketplaces.map((m) => (
                          <SelectItem key={m.id} value={m.id}>
                            {m.display_name}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="account-name">Account Name</Label>
                    <Input
                      id="account-name"
                      placeholder="My Seller Account"
                      value={accountName}
                      onChange={(e) => setAccountName(e.target.value)}
                      required
                      disabled={submitting}
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="account-id">Account ID</Label>
                    <Input
                      id="account-id"
                      placeholder="MLB123456789"
                      value={accountId}
                      onChange={(e) => setAccountId(e.target.value)}
                      required
                      disabled={submitting}
                    />
                  </div>
                  {error && (
                    <p className="text-sm text-destructive">{error}</p>
                  )}
                  <DialogFooter>
                    <Button type="submit" disabled={submitting}>
                      {submitting ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
                      Connect
                    </Button>
                  </DialogFooter>
                </form>
              </DialogContent>
            </Dialog>
          )}
        </div>

        {loading ? (
          <div className="flex h-64 items-center justify-center">
            <Loader2 className="h-6 w-6 animate-spin text-primary" />
          </div>
        ) : accounts.length === 0 ? (
          <Card>
            <CardContent className="flex flex-col items-center py-16 text-center">
              <div className="flex h-14 w-14 items-center justify-center rounded-full bg-secondary">
                <Store className="h-7 w-7 text-muted-foreground" />
              </div>
              <h3 className="mt-4 text-base font-semibold">No marketplace accounts connected</h3>
              <p className="mt-1 max-w-sm text-sm text-muted-foreground">
                {canManage
                  ? 'Click "Add Account" to connect your first marketplace seller account.'
                  : 'Ask an administrator to connect a marketplace account.'}
              </p>
            </CardContent>
          </Card>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {accounts.map((account) => {
              const status = STATUS_CONFIG[account.status] || STATUS_CONFIG['disconnected'];
              const StatusIcon = status.icon;
              return (
                <Card key={account.id}>
                  <CardHeader className="pb-3">
                    <div className="flex items-start justify-between">
                      <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
                          <Store className="h-5 w-5 text-primary" />
                        </div>
                        <div>
                          <CardTitle className="text-sm">{account.account_name}</CardTitle>
                          <CardDescription className="text-xs">
                            {account.marketplaces?.display_name || 'Unknown marketplace'}
                          </CardDescription>
                        </div>
                      </div>
                      {canManage && (
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-muted-foreground hover:text-destructive"
                          onClick={() => handleDelete(account.id)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      )}
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="flex items-center justify-between">
                      <Badge variant={status.variant} className="gap-1.5">
                        <StatusIcon className="h-3 w-3" />
                        {status.label}
                      </Badge>
                      <span className="text-xs text-muted-foreground">
                        ID: {account.account_id}
                      </span>
                    </div>
                    {account.last_sync_at && (
                      <div className="mt-3 flex items-center gap-1.5 text-xs text-muted-foreground">
                        <RefreshCw className="h-3 w-3" />
                        Last sync: {new Date(account.last_sync_at).toLocaleDateString()}
                      </div>
                    )}
                  </CardContent>
                </Card>
              );
            })}
          </div>
        )}
      </div>
    </ProtectedRoute>
  );
}
