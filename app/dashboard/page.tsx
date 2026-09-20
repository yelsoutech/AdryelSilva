'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/auth-context';
import { supabase } from '@/lib/supabase/client';
import { ArrowRight, Store, Database, BarChart3, Users, Briefcase, Activity } from 'lucide-react';

interface DashboardStats {
  accountCount: number;
  jobCount: number;
  memberCount: number;
  productCount: number;
}

export default function DashboardHome() {
  const { organization, role, loading } = useAuth();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [statsLoading, setStatsLoading] = useState(true);

  useEffect(() => {
    async function fetchStats() {
      if (!organization) return;
      setStatsLoading(true);

      const [accountsRes, jobsRes, membersRes, productsRes] = await Promise.all([
        supabase
          .from('marketplace_accounts')
          .select('id', { count: 'exact', head: true })
          .eq('organization_id', organization.id),
        supabase
          .from('jobs')
          .select('id', { count: 'exact', head: true })
          .eq('organization_id', organization.id),
        supabase
          .from('organization_members')
          .select('id', { count: 'exact', head: true })
          .eq('organization_id', organization.id)
          .eq('status', 'active'),
        supabase
          .from('products')
          .select('id', { count: 'exact', head: true })
          .eq('organization_id', organization.id),
      ]);

      setStats({
        accountCount: accountsRes.count || 0,
        jobCount: jobsRes.count || 0,
        memberCount: membersRes.count || 0,
        productCount: productsRes.count || 0,
      });
      setStatsLoading(false);
    }

    fetchStats();
  }, [organization]);

  const statCards = [
    {
      label: 'Marketplace Accounts',
      value: stats?.accountCount ?? 0,
      icon: Store,
      href: '/dashboard/marketplaces',
      color: 'text-blue-600',
      bg: 'bg-blue-50',
    },
    {
      label: 'Collection Jobs',
      value: stats?.jobCount ?? 0,
      icon: Activity,
      href: '/dashboard/pipeline',
      color: 'text-amber-600',
      bg: 'bg-amber-50',
    },
    {
      label: 'Products Tracked',
      value: stats?.productCount ?? 0,
      icon: Briefcase,
      href: '/dashboard/reports',
      color: 'text-emerald-600',
      bg: 'bg-emerald-50',
    },
    {
      label: 'Team Members',
      value: stats?.memberCount ?? 0,
      icon: Users,
      href: '/dashboard/team',
      color: 'text-violet-600',
      bg: 'bg-violet-50',
    },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          {organization
            ? `Welcome to ${organization.name}. Here's an overview of your workspace.`
            : 'Welcome to Marketplace Intelligence.'}
          {role && <span className="ml-1">You are signed in as <span className="font-medium capitalize">{role}</span>.</span>}
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {statCards.map((stat) => (
          <Link
            key={stat.label}
            href={stat.href}
            className="group rounded-xl border bg-card p-5 shadow-sm transition-all hover:shadow-md hover:border-primary/30"
          >
            <div className="flex items-center justify-between">
              <div className={`flex h-10 w-10 items-center justify-center rounded-lg ${stat.bg}`}>
                <stat.icon className={`h-5 w-5 ${stat.color}`} />
              </div>
              <ArrowRight className="h-4 w-4 text-muted-foreground opacity-0 transition-opacity group-hover:opacity-100" />
            </div>
            <div className="mt-4">
              {statsLoading ? (
                <div className="h-8 w-16 animate-pulse rounded bg-secondary" />
              ) : (
                <p className="text-2xl font-bold">{stat.value}</p>
              )}
              <p className="mt-0.5 text-sm text-muted-foreground">{stat.label}</p>
            </div>
          </Link>
        ))}
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <div className="rounded-xl border bg-card p-6 shadow-sm">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
              <Database className="h-5 w-5 text-primary" />
            </div>
            <div>
              <h3 className="text-base font-semibold">Pipeline Status</h3>
              <p className="text-sm text-muted-foreground">Data collection and processing</p>
            </div>
          </div>
          <div className="mt-4 space-y-3">
            <div className="flex items-center justify-between rounded-lg border px-4 py-3">
              <span className="text-sm font-medium">Collector</span>
              <span className="flex items-center gap-1.5 text-xs font-medium text-success">
                <span className="h-2 w-2 rounded-full bg-success" />
                Ready
              </span>
            </div>
            <div className="flex items-center justify-between rounded-lg border px-4 py-3">
              <span className="text-sm font-medium">Worker</span>
              <span className="flex items-center gap-1.5 text-xs font-medium text-warning">
                <span className="h-2 w-2 rounded-full bg-warning" />
                Awaiting jobs
              </span>
            </div>
            <div className="flex items-center justify-between rounded-lg border px-4 py-3">
              <span className="text-sm font-medium">Normalizer</span>
              <span className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
                <span className="h-2 w-2 rounded-full bg-muted-foreground" />
                Idle
              </span>
            </div>
          </div>
        </div>

        <div className="rounded-xl border bg-card p-6 shadow-sm">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10">
              <BarChart3 className="h-5 w-5 text-primary" />
            </div>
            <div>
              <h3 className="text-base font-semibold">Quick Actions</h3>
              <p className="text-sm text-muted-foreground">Jump to common tasks</p>
            </div>
          </div>
          <div className="mt-4 space-y-3">
            {[
              { label: 'Connect a marketplace account', href: '/dashboard/marketplaces' },
              { label: 'View data collection pipeline', href: '/dashboard/pipeline' },
              { label: 'Manage team members', href: '/dashboard/team' },
              { label: 'Edit organization settings', href: '/dashboard/settings' },
            ].map((action) => (
              <Link
                key={action.href}
                href={action.href}
                className="flex items-center justify-between rounded-lg border px-4 py-3 transition-colors hover:bg-secondary"
              >
                <span className="text-sm font-medium">{action.label}</span>
                <ArrowRight className="h-4 w-4 text-muted-foreground" />
              </Link>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
