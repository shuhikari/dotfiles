#!/usr/bin/env bash
# setup-project.sh
#
# Instala o pipeline de code quality num projeto Node.js/TS:
#   - husky (git hooks)
#   - biome (lint + format, substitui ESLint+Prettier)
#   - knip (dead code detection)
#   - commitlint (Conventional Commits)
#   - .editorconfig
#   - GitHub templates (PR + issues)
#
# Idempotente: pode rodar várias vezes sem quebrar.
# Cross-platform: macOS, Linux, Windows com Git for Windows.

set -euo pipefail

# Cores (com fallback se terminal não suporta)
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; NC=''
fi

info()  { echo -e "${GREEN}[info]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*"; }
ask()   { echo -en "${YELLOW}[?]${NC} $* "; }

# ----- Paths -----

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"

# ----- Pré-checks -----

[[ -f "$PROJECT_ROOT/package.json" ]] || {
  error "Não é projeto Node.js (sem package.json no diretório atual)."
  exit 1
}

# Detecta package manager
if [[ -f "$PROJECT_ROOT/pnpm-lock.yaml" ]]; then
  PM="pnpm"
elif [[ -f "$PROJECT_ROOT/yarn.lock" ]]; then
  PM="yarn"
elif [[ -f "$PROJECT_ROOT/package-lock.json" ]]; then
  PM="npm"
else
  warn "Nenhum lockfile detectado. Usando pnpm (default do time)."
  PM="pnpm"
fi

info "Package manager detectado: $PM"

# Detecta Git
[[ -d "$PROJECT_ROOT/.git" ]] || {
  warn "Não é um repositório git. Inicializando..."
  git init
}

# ----- Instala dependências -----

DEV_DEPS=(
  "husky"
  "lint-staged"
  "@biomejs/biome"
  "knip"
  "@commitlint/cli"
  "@commitlint/config-conventional"
)

info "Instalando dev dependencies via $PM..."
case $PM in
  pnpm) pnpm add -D "${DEV_DEPS[@]}" ;;
  yarn) yarn add -D "${DEV_DEPS[@]}" ;;
  npm)  npm install -D "${DEV_DEPS[@]}" ;;
esac

# ----- Configurações -----

# .editorconfig
if [[ ! -f "$PROJECT_ROOT/.editorconfig" ]]; then
  cp "$SCRIPT_DIR/.editorconfig" "$PROJECT_ROOT/.editorconfig"
  info "Adicionado .editorconfig"
else
  info ".editorconfig já existe — preservado"
fi

# biome.json
if [[ ! -f "$PROJECT_ROOT/biome.json" ]]; then
  cp "$SCRIPT_DIR/biome.json" "$PROJECT_ROOT/biome.json"
  info "Adicionado biome.json"
else
  info "biome.json já existe — preservado"
fi

# knip.json
if [[ ! -f "$PROJECT_ROOT/knip.json" ]]; then
  cp "$SCRIPT_DIR/knip.json" "$PROJECT_ROOT/knip.json"
  info "Adicionado knip.json"
else
  info "knip.json já existe — preservado"
fi

# commitlint.config.mjs
if [[ ! -f "$PROJECT_ROOT/commitlint.config.mjs" ]]; then
  cp "$SCRIPT_DIR/commitlint.config.mjs" "$PROJECT_ROOT/commitlint.config.mjs"
  info "Adicionado commitlint.config.mjs"
fi

# ----- Verifica conflito com ESLint/Prettier existente -----

if [[ -f "$PROJECT_ROOT/.eslintrc.json" || -f "$PROJECT_ROOT/.eslintrc.js" || -f "$PROJECT_ROOT/eslint.config.js" ]]; then
  warn "ESLint detectado. Biome substitui ESLint + Prettier."
  ask "Remover configs ESLint/Prettier? [y/N]:"
  read -r yn
  if [[ $yn == "y" || $yn == "Y" ]]; then
    rm -f .eslintrc.json .eslintrc.js .eslintrc.cjs eslint.config.js .prettierrc .prettierrc.json prettier.config.js
    case $PM in
      pnpm) pnpm remove eslint prettier eslint-config-* eslint-plugin-* prettier-* 2>/dev/null || true ;;
      yarn) yarn remove eslint prettier 2>/dev/null || true ;;
      npm)  npm uninstall eslint prettier 2>/dev/null || true ;;
    esac
    info "ESLint/Prettier removidos."
  else
    warn "Mantidos. Você pode ter conflitos — recomendo remover depois."
  fi
fi

# ----- husky -----

info "Configurando husky..."
case $PM in
  pnpm) pnpm exec husky init ;;
  yarn) yarn husky init ;;
  npm)  npx husky init ;;
esac

# Substitui hooks pelos templates
cp "$SCRIPT_DIR/husky/pre-commit" "$PROJECT_ROOT/.husky/pre-commit"
cp "$SCRIPT_DIR/husky/pre-push" "$PROJECT_ROOT/.husky/pre-push"
cp "$SCRIPT_DIR/husky/commit-msg" "$PROJECT_ROOT/.husky/commit-msg"
chmod +x "$PROJECT_ROOT/.husky/pre-commit" "$PROJECT_ROOT/.husky/pre-push" "$PROJECT_ROOT/.husky/commit-msg"
info "Hooks instalados em .husky/"

# ----- package.json: scripts e lint-staged -----

# Adiciona scripts via node (mais portátil que jq, que pode não estar em Windows)
node -e "
const fs = require('fs');
const path = require('path');
const pkgPath = path.join(process.cwd(), 'package.json');
const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));

pkg.scripts = pkg.scripts || {};
pkg.scripts.prepare = pkg.scripts.prepare || 'husky';
pkg.scripts.lint = 'biome check .';
pkg.scripts['lint:fix'] = 'biome check --write .';
pkg.scripts.format = 'biome format --write .';
pkg.scripts['type-check'] = 'tsc --noEmit';
pkg.scripts['dead-code'] = 'knip --no-progress --reporter compact';
pkg.scripts['quality'] = 'pnpm lint && pnpm type-check && pnpm dead-code';

pkg['lint-staged'] = pkg['lint-staged'] || {};
pkg['lint-staged']['*.{js,ts,jsx,tsx,json,md}'] = ['biome check --write --no-errors-on-unmatched'];

fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
console.log('package.json atualizado');
"

# ----- GitHub templates -----

mkdir -p "$PROJECT_ROOT/.github/ISSUE_TEMPLATE"

if [[ ! -f "$PROJECT_ROOT/.github/PULL_REQUEST_TEMPLATE.md" ]]; then
  cp "$SCRIPT_DIR/github-templates/PULL_REQUEST_TEMPLATE.md" "$PROJECT_ROOT/.github/PULL_REQUEST_TEMPLATE.md"
  info "Adicionado .github/PULL_REQUEST_TEMPLATE.md"
fi

for template in bug_report.md feature_request.md tech_debt.md; do
  if [[ ! -f "$PROJECT_ROOT/.github/ISSUE_TEMPLATE/$template" ]]; then
    cp "$SCRIPT_DIR/github-templates/ISSUE_TEMPLATE/$template" "$PROJECT_ROOT/.github/ISSUE_TEMPLATE/$template"
  fi
done
info "GitHub templates instalados em .github/"

# ----- .gitignore additions -----

if [[ -f "$PROJECT_ROOT/.gitignore" ]]; then
  for ignore in "node_modules" "dist" "build" ".env" ".env.local" "coverage"; do
    grep -qxF "$ignore" "$PROJECT_ROOT/.gitignore" || echo "$ignore" >> "$PROJECT_ROOT/.gitignore"
  done
fi

# ----- Verifica e roda -----

info "Rodando verificação inicial..."
case $PM in
  pnpm) pnpm lint || warn "Linter encontrou issues (esperado em projetos pré-existentes)" ;;
  yarn) yarn lint || warn "Linter encontrou issues" ;;
  npm)  npm run lint || warn "Linter encontrou issues" ;;
esac

# ----- Concluído -----

cat <<'EOF'

✅ Setup concluído!

Próximos passos:

  1. Roda `pnpm lint:fix` (ou yarn/npm equivalente) pra corrigir o que for
     auto-corrigível.

  2. Comita as mudanças com mensagem Conventional:
       git add .
       git commit -m "chore: add code quality pipeline"

  3. Documenta no README do projeto que o setup está ativo (template em
     ~/dotfiles/team-standards/docs-templates/README-template.md).

Hooks configurados:
  - pre-commit:  biome check --write nos arquivos staged
  - pre-push:    tsc + tests + knip
  - commit-msg:  commitlint

Pra rodar review com Claude antes do PR:
  claude
  > /review

Documentação completa: ~/dotfiles/docs/code-review-workflow.md
EOF
