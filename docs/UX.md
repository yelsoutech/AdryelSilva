# UX

## Visão Geral

A interface do usuário é construída com Next.js (App Router), React, TypeScript, Tailwind CSS e shadcn/ui.

## Estrutura Atual

### Dashboard Shell
- Sidebar de navegação escura (fixa em desktop, drawer em mobile)
- Logo "Marketplace Intel"
- Links de navegação com indicador de página ativa

### Páginas

| Página | Rota | Conteúdo |
|--------|------|----------|
| Dashboard | `/dashboard` | Status da fundação (database, adapters, pipeline) + próximos passos |
| Marketplaces | `/dashboard/marketplaces` | Empty state — pronto para conexão quando credenciais forem configuradas |
| Data Pipeline | `/dashboard/pipeline` | Visualização dos 7 estágios do pipeline |
| Reports | `/dashboard/reports` | Empty state — disponível quando houver dados coletados |
| Settings | `/dashboard/settings` | Empty state — configurações de tenant e workspace |

### Componentes UI
- shadcn/ui como biblioteca de componentes
- Lucide React para ícones
- Tema azul/neutral (sem roxo/violeta)

## Princípios de Design

1. **Responsividade** — mobile-first, com breakpoints para tablet e desktop
2. **Hierarquia visual clara** — tipografia e espaçamento consistentes
3. **Estados vazios informativos** — cada página sem dados explica o que vem a seguir
4. **Progressive disclosure** — complexidade revelada contextualmente

## Decisões Pendentes

- [DECISÃO DO PRODUTO] Fluxo de onboarding de novos tenants
- [DECISÃO DO PRODUTO] Tela de login / cadastro
- [DECISÃO DO PRODUTO] Layout e conteúdo dos relatórios
- [DECISÃO DO PRODUTO] Personalização de dashboard por usuário
- [DECISÃO DO PRODUTO] Notificações in-app
- [DECISÃO DO PRODUTO] Tema dark mode
