# Team Standards

Padrões e ferramentas de qualidade pra projetos do time. **Cross-platform**:
funciona em Windows nativo, macOS e Linux.

## Para quem

- **Devs**: rodam `setup-project.sh` em projetos novos ou existentes pra
  ativar o pipeline de qualidade
- **Tech leads**: usam os templates pra padronizar repositórios novos

## O que tem aqui

```
team-standards/
├── setup-project.sh             Instala husky + biome + knip + commitlint num projeto
├── biome.json                   Config base (lint + format)
├── knip.json                    Config base (dead code detection)
├── commitlint.config.mjs        Conventional Commits
├── .editorconfig                Convenções por editor (universal)
├── husky/                       Scripts de hook
│   ├── pre-commit               lint-staged
│   ├── pre-push                 tsc + tests + knip
│   └── commit-msg               commitlint
├── github-templates/            Templates de PR/issues
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── tech_debt.md
│   └── CODEOWNERS.example
├── docs-templates/              Templates de doc por repo
│   ├── README-template.md
│   ├── CONTRIBUTING-template.md
│   ├── feature-spec-template.md
│   └── adr-template.md
└── conventions/                 Documentação das convenções
    ├── branch-naming.md
    ├── commit-conventions.md
    └── code-style.md
```

## Setup rápido (projeto novo)

```bash
# Em qualquer projeto Node.js/TypeScript
cd /path/to/project
bash <(curl -fsSL https://raw.githubusercontent.com/SEU-USER/dotfiles/main/team-standards/setup-project.sh)
```

Ou local, se já clonou os dotfiles:

```bash
~/dotfiles/team-standards/setup-project.sh
```

O script é idempotente — pode rodar de novo sem quebrar nada existente.

## Setup rápido (projeto existente)

Mesmo comando. Vai detectar o que já existe e:

- Mantém ESLint/Prettier se já tiver (pergunta antes de migrar pra Biome)
- Detecta package manager (npm/pnpm/yarn) e adapta scripts
- Não sobrescreve hooks existentes do husky sem confirmação

## Cross-platform

- **macOS / Linux**: tudo funciona out of the box
- **Windows nativo (sem WSL)**: husky usa `sh.exe` do Git for Windows
  internamente; tudo funciona desde que Git for Windows esteja instalado
- **WSL**: idêntico a Linux

Se algum dev tem problema no Windows nativo: confirmar Git for Windows e Node.js
instalados, e que ambos estão no PATH do PowerShell/CMD.

## Pré-requisitos

Em qualquer plataforma:

```
- Node.js 22 LTS (Node 20 tem bug de corepack/pnpm em alguns setups Windows)
- Git 2.40+ (Windows: Git for Windows com Git Bash)
- pnpm (preferência do time) ou bun; npm/yarn aceitos mas sem suporte ativo
- gh CLI (opcional, pra PR creation via terminal)
```

## Quando NÃO usar

Esses padrões são pra projetos **TypeScript/JavaScript**. Pra projetos em outras
linguagens (Python, Rust, Go) há equivalentes que devem ser adotados conforme
ferramenta nativa:

- Python: `ruff` (substitui flake8+black+isort) + `pytest` + pre-commit
- Rust: `cargo fmt` + `cargo clippy` + cargo-deny
- Go: `golangci-lint` + `go test` + revive

A filosofia é a mesma: pre-commit rápido, pre-push robusto, pre-PR semântico.

## Como evoluir essas regras

Mudanças nos padrões têm peso pro time inteiro. Processo:

1. Abre Discussion no repo dos dotfiles propondo a mudança
2. Documenta com ADR (template em `docs-templates/adr-template.md`)
3. Discute com o time (1 semana mínimo)
4. Se aprovado: atualiza este repo + comunica no canal interno
5. Devs rodam `setup-project.sh` de novo nos projetos pra absorver mudança

Não muda padrão sem ADR. Não cria padrão sem buy-in.
