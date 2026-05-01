# ADR-007: Pipeline de code review pré-PR

## Status
Aceito

## Contexto

Code reviews tradicionais via GitHub PR sofrem de:
- Reviewer cansado deixa passar coisas óbvias
- Round-trips de feedback bloqueiam merge por dias
- Bugs/security issues que poderiam ser pegos antes do reviewer humano olhar
- Inconsistência de critério entre PRs e reviewers

Decisão de arquitetura: **shift-left** — pegar problemas o mais cedo possível,
em fases automatizadas, antes de pedir tempo de outro humano.

## Decisão

Pipeline em 3 estágios pré-PR, cada um pegando classes diferentes de problemas:

### Estágio 1: Pre-commit (rápido, ~1-2s)
- husky + lint-staged
- biome (substitui ESLint+Prettier; Rust, ~25x mais rápido)
- commitlint pra Conventional Commits

### Estágio 2: Pre-push (robusto, ~10-30s)
- `tsc --noEmit` (type errors)
- `vitest related` (testes afetados pelas mudanças)
- `knip` (dead code, exports não usados)

### Estágio 3: Pre-PR (semântico, ~30-90s)
- Custom slash command `/review` no Claude Code
- Modelo: Haiku 4.5 default, Sonnet pra arquitetural
- Output estruturado: severity (Critical/High/Medium/Low/Nit) com arquivo:linha
- Critérios: Clean Code, OWASP, performance, KISS, testabilidade

Cada estágio pega o que o anterior não pegaria. Sem sobreposição.

## Consequências

**Positivas:**
- 80% dos issues bobos são pegos automaticamente, antes de humano revisar
- Reviewer humano foca em arquitetura/design, não vírgula
- Custo do `/review` em Haiku 4.5: ~$0.02 por PR. 50 PRs/mês = $1
- PR aprovado primeira vez aumenta significativamente
- Stack zero-infra (tudo CLI, sem servidor pra manter)

**Negativas:**
- Setup inicial (~2h pra calibrar husky + biome + knip + custom command)
- Cada commit fica marginalmente mais lento (1-2s não são free)
- Dependência de Claude API pra estágio 3 (mas é fallback graceful — pula se offline)

## Alternativas consideradas

- **SonarQube/SonarCloud** — poderoso mas requer servidor Java + DB. Overkill pra
  time pequeno. Biome + knip + Claude review cobrem 80% do valor sem infra.
- **Apenas humano review** — gargalo, inconsistente, cansa.
- **CI-only (sem pre-commit local)** — feedback mais lento, frustra.
- **Cursor Composer reviewing PR** — paga por feature duplicada com Claude Code.

## Quando reavaliar

- Se equipe crescer (>5 devs) e Sonar pago oferecer recursos compartilhados
  (security hotspots dashboards, technical debt tracking)
- Se Anthropic mudar estrutura de pricing inviabilizando reviews automatizados
- Se aparecer ferramenta agêntica especializada em review de PR (já existem várias
  emergindo em 2026)

## Data
2026-04-26
