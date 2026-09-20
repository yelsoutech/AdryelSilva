'use client';

import { useAuth } from '@/lib/auth-context';
import type { PermissionName } from '@/lib/permissions';
import { Loader2 } from 'lucide-react';

interface ProtectedRouteProps {
  permission?: PermissionName;
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

export function ProtectedRoute({ permission, children, fallback }: ProtectedRouteProps) {
  const { loading, hasPermission } = useAuth();

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <Loader2 className="h-6 w-6 animate-spin text-primary" />
      </div>
    );
  }

  if (permission && !hasPermission(permission)) {
    if (fallback) return <>{fallback}</>;
    return (
      <div className="flex flex-col items-center justify-center gap-3 py-16 text-center">
        <div className="flex h-14 w-14 items-center justify-center rounded-full bg-destructive/10">
          <svg className="h-7 w-7 text-destructive" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
          </svg>
        </div>
        <h3 className="text-base font-semibold">Acesso negado</h3>
        <p className="max-w-sm text-sm text-muted-foreground">
          Voce nao tem permissao para acessar esta pagina.
        </p>
      </div>
    );
  }

  return <>{children}</>;
}
