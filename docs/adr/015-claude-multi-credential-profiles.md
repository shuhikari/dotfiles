# ADR-015: Multi-perfil Claude Code via CLAUDE_CONFIG_DIR

## Status
Aceito

## Contexto

Atender múltiplas empresas + uso pessoal exige separar credenciais do Claude
Code (uma conta/org por cliente, mais a pessoal). Claude Code **não tem
"profiles" built-in** — autentica numa org por vez. Alternativas pra
multi-credencial:

1. `ANTHROPIC_API_KEY` por shell — funciona, mas paga por token (sem teto) e
   não aproveita plano Max/Teams via OAuth de cada cliente.
2. `/logout` + `/login` toda vez que troca de contexto — fricção alta, perde
   histórico, browser flow no WSL é instável.
3. `CLAUDE_CONFIG_DIR` apontando pra dir diferente por perfil — isola
   `.credentials.json` (OAuth), `projects/`, `.claude.json`, histórico. Compartilha
   o que precisa ser compartilhado via symlinks.

## Decisão

Adotar **opção 3**: cada perfil tem um `~/.claude-profiles/<nome>/` próprio
como `CLAUDE_CONFIG_DIR`. Dentro de cada perfil:

- **Per-profile (real, isolado):** `.credentials.json`, `projects/`,
  `.claude.json`, logs. Gerados pelo Claude Code naquele perfil.
- **Compartilhado (symlinks pro dotfiles):** `CLAUDE.md`, `settings.json`,
  `commands/`, `skills/`. Editado uma vez no repo, vale em todos os perfis.

Perfis padrão fixos no `install.sh`: `auditore`, `hmax`, `sintetiza`. Adicionar
ou remover requer commit no dotfiles (não é dinâmico em runtime — propositalmente,
pra manter sob versionamento).

`claude/profile-switch.zsh` expõe:

- `claude-profile <nome>` — exporta `CLAUDE_CONFIG_DIR` na sessão atual.
- `cc-auditore`, `cc-hmax`, `cc-sintetiza` — alias que troca + roda `claude` num shot.
- `claude-profile-list`, `claude-profile-current` — inspeção.
- `CLAUDE_DEFAULT_PROFILE` em `local.zsh` — perfil default por máquina.

## Justificativa por decisão

| Decisão | Por quê |
|---|---|
| `CLAUDE_CONFIG_DIR` vs `ANTHROPIC_API_KEY` | OAuth (Pro/Max/Teams) é muito mais barato pra uso pesado de Claude Code. Mecanismo continua suportando API key como override pontual. |
| Symlinks pros configs compartilhados | `CLAUDE.md` e `commands/` mudam pouco e devem ser idênticos entre perfis. Edit em 1 lugar > sync em 3. |
| `projects/` per-profile (não compartilhado) | Cada cliente tem repos distintos; histórico de conversa cruzado seria confuso e poderia vazar contexto entre orgs. |
| Perfis declarados no `install.sh` (não dinâmicos) | Filosofia do repo: tudo versionado. Adicionar perfil = commit + push. Previne perfis "fantasmas" que existem só numa máquina. |
| Dir permission `0700` | Credenciais OAuth devem ser inacessíveis a outros usuários do sistema. |
| Aliases `cc-<nome>` em vez de só função | Atalho num shot é o caso mais comum; `claude-profile <nome>` fica pra trocar sessão (rodar outros comandos no perfil). |

## Consequências

**Positivas:**
- Troca de credencial num comando — sem `/logout`/`/login` repetitivos.
- Isolamento real de histórico, projects, MCPs por org (se MCPs forem por-perfil no futuro).
- Funciona idêntico em WSL e macOS (mesmo `CLAUDE_CONFIG_DIR`).
- Setup novo: `./install.sh` + 3× `claude /login` resolve.
- Configs comuns ficam DRY (1 commit no dotfiles aplica em todos os perfis).

**Negativas:**
- Browser OAuth precisa rodar 1× por perfil por máquina (3× total no setup inicial).
- Em WSL2, OAuth callback ocasionalmente falha — exige paste manual do code.
- Esquecer de trocar perfil = usa credencial errada (mitigado por `CLAUDE_DEFAULT_PROFILE` + prompt do starship futuro).
- MCPs configurados via `claude mcp add` são por-perfil — se quiser MCP em todos, roda comando 3×.

## Alternativas consideradas

- **API key por shell (`ANTHROPIC_API_KEY=...`)** — descartado: caro pra uso
  pesado, e perde os benefícios do plano de cada cliente.
- **`apiKeyHelper` em `settings.json`** — script que retorna key dinâmica de
  vault. Overhead alto pra setup inicial; não cobre OAuth.
- **3 contas Unix separadas no mesmo host** — overkill, e quebra workflow tmux/IDE.
- **Symlinks pros credentials também** — defeito o propósito (isolamento).

## Quando reavaliar

- Claude Code adicionar `--profile` flag nativo (eliminaria a necessidade de
  `CLAUDE_CONFIG_DIR` + symlinks manuais).
- Mudar de OAuth pra API key dominante (raro, mas se Anthropic mudar pricing).
- Adicionar 4º+ cliente regularmente — talvez justifique config dinâmica
  (perfis declarados em YAML lido pelo install.sh).

## Data
2026-05-28
