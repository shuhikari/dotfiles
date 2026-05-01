# Contributing

Como contribuir nesse projeto sem fricção.

## TL;DR

1. Branch a partir de `dev` (ou `main` se não há dev): `feat/CU-xxx-curto`
2. Spec antes de codar (template em `docs/specs/`)
3. Commits seguem [Conventional Commits](https://www.conventionalcommits.org/)
4. Hooks pré-commit/pré-push rodam automático
5. Antes de PR: `claude` → `/review`
6. PR pra `dev`. Aguarda review humano. Squash merge.

## Branch naming

```
<type>/<task-id>-<descricao-curta-em-kebab-case>
```

Tipos:
- `feat/` — feature nova
- `fix/` — bugfix
- `chore/` — manutenção
- `docs/` — só documentação
- `refactor/` — refactor sem mudança de comportamento
- `spike/` — exploração, sem garantia de merge
- `hotfix/` — urgência, vai pra `main` direto

Exemplos:
- `feat/CU-abc123-login-google`
- `fix/CU-def456-timeout-users-endpoint`
- `chore/CU-ghi789-bump-deps`

## Commits

[Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body opcional>

<footer opcional>
```

Tipos: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.

Exemplos:
- `feat(auth): adiciona login via Google`
- `fix(api): corrige timeout em /users`
- `chore(deps): atualiza nestjs pra 10.4.1`

`commitlint` valida automaticamente. Se reprovar, ajusta a mensagem.

## Spec antes de codar

Tarefas com mais de ~4h estimadas exigem spec antes do código.

Cria arquivo em `docs/specs/CU-xxxxxx-titulo-curto.md` usando o
[template de spec](../team-standards/docs-templates/feature-spec-template.md).

Spec passa por review (PR no próprio repo) antes da implementação começar.
Reduz retrabalho e alinha entendimento.

Use `/spec` no Claude Code pra ajudar a escrever a spec a partir da issue.

## Pre-commit / pre-push

Os hooks são instalados pelo `setup-project.sh`. Rodam automaticamente:

- **pre-commit**: biome check + format nos arquivos staged (~1-2s)
- **pre-push**: tsc + tests afetados + knip (~10-30s)
- **commit-msg**: commitlint

Não use `--no-verify` exceto em emergências reais documentadas no PR.

## Code review

### Pré-PR (local)

Antes de marcar como Ready for Review:

```bash
claude
> /review
```

Resolve issues críticos e high antes de pedir tempo de outro humano.

### PR review (humano)

Reviewer foca em:
- Design e arquitetura
- Trade-offs
- Edge cases não óbvios
- Aderência à spec

Reviewer NÃO precisa apontar coisas que biome/knip/Claude já cobriram.

### Critérios pra approve

- [ ] Todos os comentários respondidos
- [ ] CI verde
- [ ] Branch atualizada com `dev` (sem conflitos)
- [ ] Pelo menos 1 reviewer humano aprovou

## Testes

- **Unit**: `*.spec.ts` ao lado do arquivo testado
- **E2E**: `test/*.e2e-spec.ts`
- Coverage mínimo aceitável: **70%** em código novo

Não testar:
- Tipos (TypeScript já garante)
- Wrappers triviais (1 linha)
- Bibliotecas externas

Testar:
- Lógica de negócio (services)
- Edge cases (entradas inválidas, null, vazio)
- Integração entre camadas (e2e ou integration)

## Variáveis de ambiente

- Nunca commit `.env` — sempre `.env.example` com chaves vazias
- Documente cada var nova no `.env.example` com comentário curto
- Secrets sensíveis: use Doppler / GCP Secret Manager / AWS SSM, nunca hardcode

## Migrations DB

- Sempre **reversíveis** (com `down()`)
- Testa rollback localmente antes de mergear
- Migrations destrutivas (DROP COLUMN, DROP TABLE) precisam:
  - PR separado, não junto com feature
  - Aprovação de 2 reviewers
  - Plano de rollback documentado

## Quando perguntar vs decidir sozinho

**Decide sozinho:**
- Renomeações locais
- Pequenos refactors em código que tu escreveu
- Escolha de nome de variável

**Pergunta no PR ou Discord:**
- Mudança em interface pública
- Adição de dependência
- Mudança de padrão estabelecido
- Trade-off não óbvio (performance vs clareza)

**Pede ADR:**
- Mudança em arquitetura
- Adoção de nova tecnologia
- Mudança de processo de time
