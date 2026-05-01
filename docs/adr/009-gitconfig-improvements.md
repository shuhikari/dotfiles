# ADR-009: Melhorias no gitconfig

## Status
Aceito

## Contexto

`.gitconfig` original já era robusto: aliases extensos, color setup, LFS,
default branch main. Após review, identificamos 6 melhorias que reduzem
fricção diária ou previnem bugs sutis.

## Decisão

Adicionar as seguintes seções ao `gitconfig` core:

```ini
[pull]
    rebase = true                # rebase em vez de merge no pull (histórico linear)

[rerere]
    enabled = true               # reuse recorded resolutions
    autoUpdate = true

[branch]
    sort = -committerdate        # branches mais recentes primeiro

[column]
    ui = auto                    # listas em colunas (branch, tag)

[rebase]
    autoSquash = true            # auto-squash com fixup!/squash!
    autoStash = true             # stash automático antes de rebase

[commit]
    verbose = true               # diff visível no editor de mensagem

[diff]
    algorithm = histogram        # melhor que default em refactors
    colorMoved = default         # destaca código movido vs adicionado

[merge]
    conflictStyle = zdiff3       # mostra ancestor comum nos conflict markers
```

Adicionar conditional includes pra alternar identidade:

```ini
[includeIf "gitdir:~/ws/auditore/"]
    path = ~/dotfiles/git/gitconfig-auditore

[includeIf "gitdir:~/ws/tegra/"]
    path = ~/dotfiles/git/gitconfig-tegra
```

## Justificativa por mudança

| Setting | Por quê |
|---|---|
| `pull.rebase = true` | Histórico linear, sem merge commits "Merge branch 'main' of origin..." poluindo. |
| `rerere.enabled = true` | Resolve conflito 1 vez, Git lembra; reduz tempo em rebases recorrentes. |
| `branch.sort = -committerdate` | `git branch` lista as recém-trabalhadas no topo, não em ordem alfabética. |
| `rebase.autoSquash` | `git commit --fixup=<sha>` + `git rebase -i` = squash automático. Workflow mais rápido. |
| `commit.verbose = true` | Diff embaixo do editor da mensagem ajuda a escrever commits melhores. |
| `diff.algorithm = histogram` | Identifica melhor blocos movidos em refactors; reduz diffs visuais ruidosos. |
| `merge.conflictStyle = zdiff3` | Mostra o ancestor comum, não só "current vs incoming" — útil pra resolver conflitos sem confusão. |
| `includeIf` por workspace | Email e signing key trocam automaticamente conforme o repo. Sem `--config user.email` manual a cada clone. |

## Consequências

**Positivas:**
- Workflows recorrentes (pull, rebase) ficam mais fluidos
- Conflitos de merge resolvem-se mais rápido (rerere lembra; zdiff3 dá contexto)
- Identidade correta automática por contexto
- Diffs mais legíveis em refactors

**Negativas:**
- `pull.rebase = true` muda comportamento esperado de quem está acostumado com merge
  (precisa documentar pro time)
- `commit.verbose = true` requer scroll a mais em editor pra escrever mensagem

## Alternativas consideradas

- **Manter status quo** — funciona, mas perde ROI alto de configurações que
  são "set and forget".
- **Apenas as ergonômicas (sort, column, verbose)** — descartado, as outras (rerere,
  rebase.autoSquash, conflictStyle) também são baixíssimo risco de side effect.

## Quando reavaliar

- Se algum settings causar bug recorrente em workflow específico (improvável,
  todos são bem-estabelecidos)
- Se Git deprecar/renomear alguma dessas chaves em release futura

## Data
2026-04-26
