'use client';

import { Database } from 'lucide-react';
import { ProtectedRoute } from '@/components/protected-route';
import { PERMISSIONS } from '@/lib/permissions';

export default function PipelinePage() {
  const stages = [
    { name: 'Collector', description: 'Fetches raw data from marketplace APIs' },
    { name: 'Queue', description: 'Collection jobs waiting for processing' },
    { name: 'Worker', description: 'Processes jobs through the pipeline' },
    { name: 'Parser', description: 'Extracts structured fields from raw payloads' },
    { name: 'Validator', description: 'Ensures data integrity and completeness' },
    { name: 'Normalizer', description: 'Maps marketplace fields to unified schema' },
    { name: 'Database', description: 'Stores raw and normalized data' },
  ];

  return (
    <ProtectedRoute permission={PERMISSIONS.RESEARCH_READ}>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">Data Pipeline</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            The collection and processing pipeline for marketplace data.
          </p>
        </div>

        <div className="rounded-xl border bg-card p-6 shadow-sm">
          <h2 className="text-base font-semibold">Pipeline Stages</h2>
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
              <h3 className="text-sm font-semibold">No collection jobs yet</h3>
              <p className="mt-1 text-sm text-muted-foreground">
                Jobs will appear here once marketplace accounts are connected and data collection begins.
              </p>
            </div>
          </div>
        </div>
      </div>
    </ProtectedRoute>
  );
}
