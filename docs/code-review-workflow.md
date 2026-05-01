# Code Quality Workflow

Pipeline em 3 estágios pra entregar PRs limpos sem fricção excessiva.

## Filosofia

Cada estágio resolve uma classe diferente de problema:
- **Pre-commit** — formatação e lint óbvios. Rápido (<2s).
- **Pre-push** — type errors, testes quebrados, dead code. Mais robusto (10-30s).
- **Pre-PR** — review semântico via agente. Análise profunda (30-90s).

Cada um pega o que o anterior não pegaria. Sem sobreposição.

---

## Estágio 1: Pre-commit (husky + lint-staged)

### Setup

```bash
npm i -D husky lint-staged @biomejs/biome
npx husky init
```

`package.json`:

```json
{
  "scripts": {
    "prepare": "husky"
  },
  "lint-staged": {
    "*.{js,ts,jsx,tsx,json,md}": [
      "biome check --write --no-errors-on-unmatched"
    ]
  }
}
```

`.husky/pre-commit`:

```bash
npx lint-staged
```

### Por que biome em vez de eslint+prettier

Biome é Rust-based, ~25x mais rápido, configuração unificada (lint + format num arquivo só). Reduz dependências, reduz tempo. Trade-off: ecossistema menor de regras custom — mas pra TS/JS/JSON cobre o que importa.

Se equipe já tem ESLint + Prettier robusto, mantém. Não troca por trocar.

### Commitlint (opcional mas vale)

```bash
npm i -D @commitlint/cli @commitlint/config-conventional
echo "export default { extends: ['@commitlint/config-conventional'] };" > commitlint.config.mjs
```

`.husky/commit-msg`:

```bash
npx commitlint --edit $1
```

Bloqueia commits com mensagem fora do padrão `feat: ...`, `fix: ...`, `chore: ...`.

---

## Estágio 2: Pre-push (testes + types + dead code)

`.husky/pre-push`:

```bash
#!/bin/sh

# Type check (sem emitir JS, só valida)
npx tsc --noEmit

# Testes afetados pelas mudanças (vitest)
npx vitest related --run $(git diff --name-only origin/main...HEAD | tr '\n' ' ')
# ou se for jest:
# npx jest --findRelatedTests $(git diff --name-only origin/main...HEAD | tr '\n' ' ') --passWithNoTests

# Dead code: exports/files não usados
npx knip --no-progress --reporter compact
```

### knip configuration

`knip.json`:

```json
{
  "$schema": "https://unpkg.com/knip@5/schema.json",
  "entry": ["src/main.ts", "src/**/*.spec.ts"],
  "project": ["src/**/*.ts"],
  "ignoreDependencies": ["@nestjs/cli"]
}
```

Knip mostra o que tu adicionou e ninguém usa. Pega "criou util mas esqueceu de chamar" antes do code review.

### CodeQL CLI (opcional, análise semântica)

Substitui SonarLint pra security scanning sem precisar montar SonarQube. Roda local:

```bash
brew install codeql
codeql database create db --language=javascript-typescript --source-root=.
codeql database analyze db --format=sarif-latest --output=results.sarif \
  codeql/javascript-queries:codeql-suites/javascript-security-extended.qls
```

Saída SARIF tu lê com `cat results.sarif | jq '.runs[0].results[].message.text'`. Roda só semanal ou pré-release, é caro pra pre-push.

---

## Estágio 3: Pre-PR (Claude Code review)

### Setup do custom command

```bash
mkdir -p ~/.claude/commands
cp ~/dotfiles/claude/commands/review.md ~/.claude/commands/
```

### Uso

Na branch da feature, depois do pre-push passar:

```bash
claude
> /review
```

Claude pega `git diff origin/main...HEAD`, lê arquivos completos pra contexto, retorna análise estruturada por severity (Critical/High/Medium/Low/Nit) com arquivo:linha e sugestões concretas.

### Quando usar Sonnet vs Haiku

- **Haiku 4.5** — review default. Rápido, barato (~$0.001 por review pequeno), pega 80% do que importa.
- **Sonnet 4.6** — review arquitetural, refactor grande, mudança em camada crítica de segurança.
- **Opus 4.7** — só pra código complexo de domínio crítico onde custo de bug é alto. Caro.

Tu controla via flag ao invocar Claude Code: `claude --model haiku`.

### Custo estimado

Review típico (PR de 200 linhas, 5 arquivos):
- Diff: ~3000 tokens
- Arquivos lidos pra contexto: ~8000 tokens
- Output (análise): ~1500 tokens
- **Custo Haiku 4.5**: ~$0.02 por review
- **Custo Sonnet 4.6**: ~$0.06 por review

Considera: 50 reviews/mês × $0.02 = $1/mês. Ridiculamente barato pra qualidade que entrega.

---

## Por que NÃO usar LiteLLM aqui

LiteLLM é proxy pra **plataforma multi-tenant**: time grande, múltiplos serviços consumindo LLM, virtual keys per dev, budget tracking, fallback automático.

Pra workflow local de code review:
- Adiciona ~10-20ms de latência por request
- Mais um servidor pra manter
- Resolve problema que dev individual não tem

Quando passa a fazer sentido:
- Equipe de 5+ devs com budgets separados
- Backend produção que precisa fallback Claude → Bedrock → outro
- Compliance que exige audit log centralizado

**Pra hoje**: Claude Code direto. Quando crescer, reavalia.

---

## Por que NÃO instalar SonarQube agora

SonarQube Community é poderoso mas:
- Java + servidor separado pra rodar
- Banco de dados (PostgreSQL ou H2)
- Dashboard que ninguém olha em time pequeno
- Setup de scanner por linguagem

**Substituto leve que cobre 80% do valor**:
- Biome → lint + format
- Knip → dead code
- tsc → type errors
- Claude Code review → smells, design, security
- CodeQL CLI → security deep scan (sob demanda)

Total: zero infra. Tudo CLI.

Se um dia tiver SonarQube empresarial pago e quiseres integrar: a stack acima continua valendo, Sonar vira complemento, não substituto.

---

## Checklist pra implantar

- [ ] husky instalado e `prepare` script no package.json
- [ ] biome configurado, eslint+prettier removidos (ou mantidos com decisão consciente)
- [ ] commitlint com Conventional Commits
- [ ] pre-push com tsc + tests related + knip
- [ ] knip.json configurado pro projeto
- [ ] `~/.claude/commands/review.md` instalado
- [ ] Equipe alinhada sobre quando usar `/review` (recomendado: antes de marcar PR como Ready for Review)
- [ ] Métrica medida no primeiro mês: % de PRs aprovados sem rounds de feedback (alvo: subir)
