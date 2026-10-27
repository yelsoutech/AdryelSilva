'use client';

import { BarChart3 } from 'lucide-react';
import { ProtectedRoute } from '@/components/protected-route';
import { PERMISSIONS } from '@/lib/permissions';

export default function ReportsPage() {
  return (
    <ProtectedRoute permission={PERMISSIONS.ANALYTICS_READ}>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Relatórios</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            Análises e insights dos seus dados de marketplace.
          </p>
        </div>

        <div className="rounded-xl border bg-card p-8 shadow-sm">
          <div className="flex flex-col items-center text-center">
            <div className="flex h-14 w-14 items-center justify-center rounded-full bg-secondary">
              <BarChart3 className="h-7 w-7 text-muted-foreground" />
            </div>
            <h3 className="mt-4 text-base font-semibold">Sem dados para relatar ainda</h3>
            <p className="mt-1 max-w-sm text-sm text-muted-foreground">
              Os relatórios estarão disponíveis assim que os dados dos marketplaces forem coletados e normalizados.
            </p>
          </div>
        </div>
      </div>
    </ProtectedRoute>
  );
}