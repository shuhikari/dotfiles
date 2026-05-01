# ADR-004: Estrutura modular do dotfiles

## Status
Aceito

## Contexto

`.zshrc` original cresceu organicamente com aliases, exports, env vars de
frameworks (Android, Flutter, Java, Python) e configs de prompt todos
misturados em ~150 linhas. Problemas:

- Mudança em alias = scroll por arquivo grande
- Adição de novo SDK = risco de quebrar PATH existente
- Diff de PR difícil de revisar (muitas seções não-relacionadas)
- Nenhum mecanismo pra config específica por máquina sem comitar segredos
- `compinit` chamado 3 vezes (desperdício de startup time)
- Bug silencioso: `$CAPACITOR_ANDROID_STUDIO_AP` (typo) exportando vazio

## Decisão

Quebrar `.zshrc` em módulos com responsabilidade única:

```
zsh/
├── zshrc           Entrypoint: oh-my-zsh + source dos módulos + tools no final
├── exports.zsh     PATH e env vars
├── aliases.zsh     Atalhos de comando (categorizados)
├── functions.zsh   Funções zsh (lsn, tns, tcc, pr, cu, mkcd)
└── local.zsh       Config específica da máquina (gitignored)
```

Regras:
- `compinit` chamado uma vez só (oh-my-zsh já cuida)
- `local.zsh` no `.gitignore` — secrets ficam só localmente
- `local.zsh.example` comitado como template
- Paths usam `$HOME` em vez de `/Users/shuhikari/`
- Cada export setado uma vez só (sem sobrescritas silenciosas)

## Consequências

**Positivas:**
- Diff de mudança é cirúrgico
- Adicionar novo SDK = só mexe em `exports.zsh`
- API keys nunca acidentalmente comitadas (ficam em `local.zsh`)
- Portátil entre máquinas (sem hardcode de username)
- Startup mais rápido (1 compinit em vez de 3)

**Negativas:**
- Estrutura mais complexa pra novato seguir
- 5 arquivos em vez de 1 — precisa navegar mais

## Alternativas consideradas

- **Manter monolito** — simplicidade aparente, mas todos os problemas listados acima.
- **Usar GNU Stow ou chezmoi** — gestores de dotfiles full-featured. Overkill pra
  setup individual; symlinks simples via `install.sh` cobrem o caso.
- **Pure Bash sem oh-my-zsh** — mais leve mas perde plugins úteis (autosuggestions, completions).

## Quando reavaliar

- Se chezmoi/yadm provarem-se necessários (multi-machine sync com diferenças
  estruturais por máquina)
- Se startup do shell virar gargalo perceptível (>200ms)
- Se equipe adotar dotfiles compartilhados (aí faz sentido formato mais robusto)

## Data
2026-04-26
