# Security

## Visao Geral

A seguranca e prioridade fundamental. As decisoes de seguranca foram incorporadas desde a FASE 0 e reforcadas na ETAPA 8 (RBAC).

## Row Level Security (RLS)

- RLS habilitado em **todas** as 35+ tabelas do banco de dados
- Apos habilitar RLS, as tabelas ficam bloqueadas ate que politicas sejam adicionadas
- Todas as politicas usam `auth.uid()` (nunca `current_user`)
- 4 politicas por tabela (SELECT, INSERT, UPDATE, DELETE) — nunca `FOR ALL`
- Scope: `TO authenticated` (app com tela de login)
- Isolamento por `organization_id` via funcao `user_org_member()`

## RBAC — Role-Based Access Control

### Roles (4 system roles)

| Role | Permissoes | Restricoes |
|------|-----------|------------|
| owner | 24 (todas) | Nenhuma |
| admin | 22 | Nao pode deletar org, nao pode gerenciar roles |
| analyst | 12 | Nao pode gerenciar usuarios, org, marketplaces |
| viewer | 5 | Somente leitura |

### Politica: Deny by Default

Se uma operacao exige uma permissao e o usuario nao a possui, o acesso e negado.
O frontend oculta elementos visuais, mas a protecao real esta no banco (RLS) e no backend.

### Protecao contra IDOR

- Todas as tabelas de negocio tem `organization_id`
- RLS valida `organization_id` via `user_org_member(organization_id)`
- Um usuario da Org A nao pode acessar dados da Org B alterando um ID na requisicao
- O `organization_id` e validado no nivel do banco, nao no frontend

### Fortalecimento de organization_members

- **INSERT** (adicionar membro): requer `users.invite`
- **UPDATE** (alterar role): requer `users.update`
- **DELETE** (remover membro): requer `users.remove`
- Um analyst ou viewer nao pode adicionar, remover ou alterar membros

### Funcoes SECURITY DEFINER

| Funcao | Proposito |
|--------|-----------|
| `user_org_member(org_id)` | Verifica membership ativa |
| `user_org_role(org_id)` | Retorna nome da role |
| `user_has_permission(org_id, perm)` | Verifica permissao especifica |
| `user_org_permissions(org_id)` | Lista todas permissoes do usuario |

Estas funcoes bypassam RLS para consultar `organization_members`, `role_permissions`, e `permissions` — necessario porque essas tabelas tem RLS habilitado e as consultas de autorizacao precisam ler dados跨-tenant.

## Credenciais de Marketplace

- `marketplace_credentials` armazena credenciais criptografadas (pgcrypto)
- Funcoes `encrypt_credential()` e `decrypt_credential()` sao SECURITY DEFINER
- **Nunca** expostas ao cliente frontend
- Apenas codigo server-side deve acessar credenciais

## Autenticacao

- Supabase Auth (email/password)
- Email confirmation OFF
- Sessao persistida via cookies
- Middleware protege todas as rotas exceto `/login`, `/signup`, `/reset-password`
- `AuthProvider` carrega sessao, organizacao, role e permissoes

## Protecao de Rotas (Frontend)

### Middleware (server-side)

- Verifica `sb-access-token` cookie
- Redireciona para `/login` se nao autenticado
- Redireciona para `/dashboard` se autenticado em rotas publicas

### ProtectedRoute (client-side)

- Componente que envolve paginas protegidas
- Verifica permissao especifica antes de renderizar
- Mostra estado de "Acesso negado" se sem permissao
- Sidebar filtrada por permissoes do usuario

## Princípios

1. **Principio do menor privilegio** — acesso minimo necessario
2. **Negar por padrao** — RLS bloqueia tudo ate que uma politica permita
3. **Validacao em boundaries** — validar entrada em APIs e boundaries externas
4. **Confianca em codigo interno** — nao validar desnecessariamente entre modulos internos
5. **Defense in depth** — frontend + middleware + RLS + funcoes SECURITY DEFINER
6. **Nao confiar no frontend** — ocultar botoes nao substitui autorizacao do backend

## Isolamento Multi-Tenant

- Toda tabela de dados tem `organization_id`
- Foreign keys com `ON DELETE CASCADE` garantem limpeza quando uma organizacao e removida
- RLS policies isolem dados por `organization_id` via `user_org_member()`
- Um usuario pode pertencer a multiplas organizacoes com roles diferentes
- A organizacao ativa e carregada no `AuthProvider`

## Convites de Usuarios

- Tabela `organization_invitations` preparada para futuros convites
- Apenas usuarios com `users.invite` podem criar convites
- Token unico (uuid) para aceitacao
- Expiracao de 7 dias
- Nenhum envio de email implementado — apenas a estrutura de dados

## Auditoria

- Tabela `audit_logs` existe para registrar operacoes administrativas
- Preparada para integracao futura (alteracao de role, convite, remocao de membro)
- Nenhum sistema de auditoria ativo nesta etapa

## Decisoes Pendentes

- [DECISAO DO PRODUTO] Estrategia de criptografia de credenciais em repouso (pgcrypto implementado)
- [DECISAO DO PRODUTO] Rotacao de tokens de marketplace
- [DECISAO DO PRODUTO] Politica de senhas e MFA
- [DECISAO DO PRODUTO] Conformidade com LGPD / GDPR
- [DECISAO DO PRODUTO] Envio de emails de convite
- [DECISAO DO PRODUTO] Sistema de auditoria ativo
