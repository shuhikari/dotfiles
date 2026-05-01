# Commit Conventions

[Conventional Commits](https://www.conventionalcommits.org) é a base. `commitlint`
valida automaticamente. Aqui está o resumo prático.

## Formato

```
<type>(<scope>): <subject>

<body opcional>

<footer opcional>
```

## Tipos

| Type | Quando |
|---|---|
| `feat` | Funcionalidade nova |
| `fix` | Correção de bug |
| `docs` | Só documentação |
| `style` | Formatação (espaços, vírgulas, sem mudança de lógica) |
| `refactor` | Refactor sem mudança de comportamento |
| `perf` | Melhoria de performance |
| `test` | Adicionar/corrigir testes |
| `build` | Build system, dependências |
| `ci` | CI/CD configs |
| `chore` | Manutenção, sem mudança em código de produção |
| `revert` | Reverte commit anterior |
| `wip` | Work in progress (NÃO chega em main) |

## Subject

- Imperativo, presente: "adiciona", não "adicionado" ou "adicionando"
- Minúsculo (a não ser que comece com substantivo próprio)
- Sem ponto final
- Máximo 72 caracteres no subject inteiro
- Português ou inglês — escolhe um e mantém consistente no projeto

## Scope (opcional)

Identifica a área afetada:
- Módulo: `feat(auth):`, `fix(orders):`
- Camada: `refactor(repository):`, `feat(api):`
- Stack: `chore(deps):`, `build(docker):`

## Body (opcional)

Use quando o "porquê" não cabe no subject. Linhas de até 72 caracteres.

```
feat(auth): adiciona login via Google

Substituímos o fluxo de login com email/senha pelo OAuth Google
porque 80% dos usuários já usavam Gmail e o reset de senha era
o bug mais reportado em Q1.

Mantemos email/senha como fallback até Q3.
```

## Footer (opcional)

Para metadados:

```
Closes #123
Refs CU-abc456
BREAKING CHANGE: endpoint /auth/login agora exige campo `provider`
Co-authored-by: João Silva <joao@example.com>
```

## BREAKING CHANGE

Se a mudança quebra contrato (API, schema, interface pública), sinaliza:

Opção 1 — `!` após o type:
```
feat(api)!: muda endpoint /users pra /v2/users
```

Opção 2 — footer:
```
feat(api): adiciona campo `phone` em /users

BREAKING CHANGE: endpoint /users agora requer `phone` no POST body
```

## Exemplos

✅ Bons:
```
feat(auth): adiciona login via Google
fix(api): corrige timeout em /users/:id
docs(readme): adiciona instruções de setup local
chore(deps): atualiza nestjs pra 10.4.1
refactor(orders): extrai cálculo de frete pra util
test(auth): adiciona cobertura pra reset password
```

❌ Ruins:
```
feat: stuff                              # sem scope nem subject útil
fix: Fixed bug                           # capitalização errada, "Fixed" passado
update users                             # sem type
"feat: novo recurso completo"            # subject vago demais
adicionei login                          # sem type, sem :
```

## Multi-commit em uma feature

Cada commit deve fazer sentido sozinho. Não:
- "wip" → "wip 2" → "fix wip" → "finalmente"

Sim, antes de PR:
- `git rebase -i HEAD~N` e squash dos wips
- Ou commit limpo desde o início

`git commit --fixup=<sha>` + `git rebase -i --autosquash` faz isso elegantemente
(habilitado no nosso `.gitconfig` via `rebase.autoSquash = true`).

## Commits que pulam validação

Em emergências reais (e raras):

```bash
git commit --no-verify -m "..."
```

Só usa quando justificado. Documenta no PR por que foi necessário.
