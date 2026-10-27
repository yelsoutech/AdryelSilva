'use client';

import { Database } from 'lucide-react';
import { ProtectedRoute } from '@/components/protected-route';
import { PERMISSIONS } from '@/lib/permissions';

export default function PipelinePage() {
  const stages = [
    { name: 'Coletor', description: 'Busca dados brutos das APIs dos marketplaces' },
    { name: 'Fila', description: 'Trabalhos de coleta aguardando processamento' },
    { name: 'Worker', description: 'Processa trabalhos pelo pipeline' },
    { name: 'Parser', description: 'Extrai campos estruturados dos dados brutos' },
    { name: 'Validador', description: 'Garante a integridade e completude dos dados' },
    { name: 'Normalizador', description: 'Mapeia campos do marketplace para o schema unificado' },
    { name: 'Banco de Dados', description: 'Armazena dados brutos e normalizados' },
  ];

  return (
    <ProtectedRoute permission={PERMISSIONS.RESEARCH_READ}>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Pipeline de Dados</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            O pipeline de coleta e processamento de dados dos marketplaces.
          </p>
        </div>

        <div className="rounded-xl border bg-card p-6 shadow-sm">
          <h2 className="text-base font-semibold">Etapas do Pipeline</h2>
          <div className="mt-4 space-y-3">
            {stages.map((stage, index) => (
              <div key={stage.name} className="flex items-start gap-4">
                <div className="flex flex-col items-center">
                  <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10 text-sm font-semibold text-primary">
                    {index + 1}
                  </div>
                  {index < stages.length - 1 && <div className="mt-1 h-8 w-px bg-border" />}
                </div>
                <div className="pb-2">
                  <p className="text-sm font-semibold">{stage.name}</p>
                  <p className="text-sm text-muted-foreground">{stage.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="rounded-xl border bg-card p-6 shadow-sm">
          <div className="flex items-center gap-3">
            <Database className="h-5 w-5 text-muted-foreground" />
            <div>
              <h3 className="text-sm font-semibold">Nenhum trabalho de coleta ainda</h3>
              <p className="mt-1 text-sm text-muted-foreground">
                Os trabalhos aparecerão aqui assim que as contas de marketplace forem conectadas e a coleta de dados começar.
              </p>
            </div>
          </div>
        </div>
      </div>
    </ProtectedRoute>
  );
}