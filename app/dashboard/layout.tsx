'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  LayoutDashboard,
  Store,
  Database,
  Settings,
  Menu,
  X,
  BarChart3,
  LogOut,
  ChevronDown,
  Users,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useAuth } from '@/lib/auth-context';
import { PERMISSIONS } from '@/lib/permissions';
import type { PermissionName } from '@/lib/permissions';
import { Button } from '@/components/ui/button';

interface NavItem {
  label: string;
  href: string;
  icon: typeof LayoutDashboard;
  permission?: PermissionName;
}

const navItems: NavItem[] = [
  { label: 'Dashboard', href: '/dashboard', icon: LayoutDashboard, permission: PERMISSIONS.DASHBOARD_READ },
  { label: 'Marketplaces', href: '/dashboard/marketplaces', icon: Store, permission: PERMISSIONS.MARKETPLACES_READ },
  { label: 'Data Pipeline', href: '/dashboard/pipeline', icon: Database, permission: PERMISSIONS.RESEARCH_READ },
  { label: 'Reports', href: '/dashboard/reports', icon: BarChart3, permission: PERMISSIONS.ANALYTICS_READ },
  { label: 'Team', href: '/dashboard/team', icon: Users, permission: PERMISSIONS.USERS_READ },
  { label: 'Settings', href: '/dashboard/settings', icon: Settings, permission: PERMISSIONS.ORGANIZATION_READ },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const pathname = usePathname();
  const router = useRouter();
  const { user, organization, role, loading, signOut, hasPermission } = useAuth();

  async function handleSignOut() {
    await signOut();
    router.push('/login');
    router.refresh();
  }

  const visibleNavItems = navItems.filter((item) => !item.permission || hasPermission(item.permission));
  const initials = (user?.email || '?').charAt(0).toUpperCase();

  return (
    <div className="min-h-screen bg-secondary/40">
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-50 flex w-64 flex-col bg-[hsl(var(--sidebar))] transition-transform duration-300 lg:translate-x-0',
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        )}
      >
        <div className="flex h-16 items-center justify-between px-6">
          <Link href="/dashboard" className="flex items-center gap-2.5">
            <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary">
              <BarChart3 className="h-5 w-5 text-white" />
            </div>
            <span className="text-sm font-semibold text-white">Marketplace Intel</span>
          </Link>
          <button
            className="text-white/70 hover:text-white lg:hidden"
            onClick={() => setSidebarOpen(false)}
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <nav className="flex-1 space-y-1 px-3 py-4">
          {visibleNavItems.map((item) => {
            const isActive = pathname === item.href || pathname.startsWith(item.href + '/');
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setSidebarOpen(false)}
                className={cn(
                  'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors',
                  isActive
                    ? 'bg-primary text-white'
                    : 'text-[hsl(var(--sidebar-foreground))] hover:bg-white/10'
                )}
              >
                <item.icon className="h-4.5 w-4.5" />
                {item.label}
              </Link>
            );
          })}
        </nav>

        <div className="border-t border-white/10 px-6 py-4">
          <p className="text-xs text-white/40">Marketplace Intelligence v0.1</p>
        </div>
      </aside>

      <div className="lg:pl-64">
        <header className="sticky top-0 z-30 flex h-16 items-center justify-between border-b bg-background px-4 lg:px-8">
          <button
            className="text-foreground lg:hidden"
            onClick={() => setSidebarOpen(true)}
          >
            <Menu className="h-5 w-5" />
          </button>

          <div className="hidden lg:block">
            {loading ? (
              <div className="h-5 w-40 animate-pulse rounded bg-secondary" />
            ) : organization ? (
              <div className="flex items-center gap-2">
                <span className="text-sm font-medium text-muted-foreground">{organization.name}</span>
                {role && (
                  <span className="rounded-md bg-primary/10 px-2 py-0.5 text-xs font-medium capitalize text-primary">
                    {role}
                  </span>
                )}
              </div>
            ) : null}
          </div>

          <div className="relative ml-auto">
            <button
              onClick={() => setUserMenuOpen(!userMenuOpen)}
              className="flex items-center gap-2 rounded-lg px-2 py-1.5 transition-colors hover:bg-secondary"
            >
              <div className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-sm font-semibold text-white">
                {initials}
              </div>
              <span className="hidden text-sm font-medium sm:block">
                {user?.email}
              </span>
              <ChevronDown className="h-4 w-4 text-muted-foreground" />
            </button>

            {userMenuOpen && (
              <>
                <div
                  className="fixed inset-0 z-40"
                  onClick={() => setUserMenuOpen(false)}
                />
                <div className="absolute right-0 top-full z-50 mt-2 w-56 rounded-lg border bg-popover shadow-lg">
                  <div className="border-b px-4 py-3">
                    <p className="text-sm font-semibold">{user?.email}</p>
                    {organization && (
                      <p className="mt-0.5 text-xs text-muted-foreground">{organization.name}</p>
                    )}
                    {role && (
                      <p className="mt-0.5 text-xs capitalize text-primary">{role}</p>
                    )}
                  </div>
                  <div className="p-2">
                    <Button
                      variant="ghost"
                      className="w-full justify-start gap-2 text-sm"
                      onClick={handleSignOut}
                    >
                      <LogOut className="h-4 w-4" />
                      Sair
                    </Button>
                  </div>
                </div>
              </>
            )}
          </div>
        </header>

        <main className="p-6 lg:p-8">{children}</main>
      </div>
    </div>
  );
}
