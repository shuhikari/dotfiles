# Branch Naming

## Formato

```
<type>/<task-id>-<descricao-kebab-case>
```

## Tipos

| Type | Quando usar | Exemplo |
|---|---|---|
| `feat/` | Feature nova | `feat/CU-abc-login-google` |
| `fix/` | Bugfix em código existente | `fix/CU-def-timeout-users` |
| `chore/` | Manutenção, deps, config | `chore/CU-ghi-bump-nestjs-10` |
| `docs/` | Só documentação | `docs/CU-jkl-readme-setup` |
| `refactor/` | Refactor sem mudança de comportamento | `refactor/CU-mno-extract-service` |
| `test/` | Adicionar/corrigir testes | `test/CU-pqr-coverage-auth` |
| `spike/` | Exploração / proof of concept | `spike/CU-stu-gateway-comparison` |
| `hotfix/` | Urgência em produção (sai pra `main` direto) | `hotfix/CU-vwx-broken-checkout` |
| `release/` | Branch de release pra prep e testes | `release/v2.5.0` |

## Regras

1. **Sempre minúsculas**, sem acentos, sem espaços
2. **Task ID obrigatório** quando há (CU-xxx do ClickUp). Exceção: `chore/` triviais
3. **Descrição em kebab-case**, máximo ~5 palavras
4. **Não use** `_underscore` ou `CamelCase`
5. **Não inclua** seu nome — branch é da task, não da pessoa

## Exemplos

✅ Bons:
- `feat/CU-abc123-export-csv`
- `fix/CU-def456-null-pointer-checkout`
- `chore/bump-eslint-9`  (sem task pra deps automáticos)

❌ Ruins:
- `feature_login` (sem task, snake_case)
- `joao/CU-abc-login` (nome do dev)
- `fix/Trying To Fix Login Bug` (espaços, capitalização)
- `feat/CU-abc-this-branch-name-is-way-too-long-and-keeps-going` (verbose)

## Branches especiais

- **`main`** — produção. Protegida. Só recebe merge de `dev`, `release/*`, `hotfix/*`.
- **`dev`** — integração. Onde features são mergeadas pra QA.
- **`staging`** — branch de staging environment (se existir).

## Lifecycle

1. Cria branch a partir de `dev` (ou `main` se não há `dev`)
2. Trabalha, commita
3. Push, abre PR pra `dev`
4. Após merge, branch é deletada (GitHub apaga automaticamente após merge)
5. Hotfix sai de `main`, volta pra `main` E é cherry-picked pra `dev`
