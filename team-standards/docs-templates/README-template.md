# {Nome do Projeto}

> {Frase de uma linha sobre o que o projeto faz}

## Contexto

<!-- Por que esse projeto existe? Qual problema resolve? Quem usa? -->

## Stack

- **Linguagem**: TypeScript 5.x
- **Runtime**: Node.js 22 LTS
- **Framework**: NestJS 10 / Angular 17 / Next.js 14 / etc.
- **DB**: PostgreSQL 16 / MongoDB 7 / etc.
- **ORM**: Prisma / TypeORM / etc.
- **Package manager**: pnpm (preferido) / bun

## Pré-requisitos

```bash
# Node (asdf é o gerenciador padrão do time — vide wsl/setup.sh)
asdf install nodejs latest:22
asdf set -u nodejs "$(asdf latest nodejs 22)"

# pnpm via asdf (não corepack — corepack do 20.19 falha em alguns setups)
asdf plugin add pnpm https://github.com/jonathanmorley/asdf-pnpm.git
asdf install pnpm latest
asdf set -u pnpm "$(asdf latest pnpm)"

# Docker (se necessário pro DB local)
# Mac: brew install --cask docker
# Windows: https://www.docker.com/products/docker-desktop
```

## Setup local

```bash
# 1. Clone e entra
git clone {url}
cd {nome-do-projeto}

# 2. Instala deps
pnpm install

# 3. Cópia de variáveis (NUNCA comita .env)
cp .env.example .env
# edita .env com valores reais

# 4. DB up (se aplicável)
docker compose up -d postgres
pnpm prisma migrate deploy

# 5. Setup de qualidade (uma vez por clone)
~/dotfiles/team-standards/setup-project.sh

# 6. Rodar
pnpm dev
```

## Estrutura

```
src/
├── modules/          features (auth, users, orders, etc)
├── common/           shared utils, decorators, guards
├── infrastructure/   adapters (db, http clients, queue)
├── config/           app config, env vars
└── main.ts           bootstrap
```

## Comandos comuns

```bash
pnpm dev               # dev server com watch
pnpm build             # build de produção
pnpm test              # testes unitários
pnpm test:e2e          # testes end-to-end
pnpm lint              # check lint
pnpm lint:fix          # corrige o que dá
pnpm type-check        # tsc --noEmit
pnpm dead-code         # knip
pnpm quality           # roda tudo: lint + type-check + dead-code
```

## Workflow de contribuição

1. Cria branch a partir de `dev`: `git checkout -b feat/CU-xxx-descricao`
2. Codifica seguindo o [feature spec](docs/specs/) (escrito antes de codar)
3. Hooks rodam automaticamente no commit/push (não desabilita)
4. Antes de PR: `claude` → `/review`
5. Abre PR pra `dev`. Reviewer humano valida design e contexto.
6. Merge: squash + rebase (não cria merge commits sem necessidade)

Detalhes em [CONTRIBUTING.md](CONTRIBUTING.md).

## Decisões arquiteturais

Decisões importantes ficam em [`docs/adr/`](docs/adr/). Uma decisão = uma ADR.

## Documentação adicional

- [Feature specs](docs/specs/) — antes de codar, define o que e como
- [Runbook](docs/runbook.md) — operações: deploy, rollback, debug em prod
- [Architecture](docs/architecture.md) — visão de alto nível dos componentes

## Suporte

- Issues: GitHub Issues (use os templates)
- Chat: #canal-do-time no Discord
- Owner: @SEU-USERNAME (CODEOWNERS)
