# Diretrizes globais

Regras inegociáveis pra todas as conversas. Otimize custo: subagentes baratos pra trabalho mecânico, Opus só pra síntese e decisão.

## Subagentes

- Busca, grep, leitura ampla, exploração → `Explore`. Não polua contexto principal.
- `Plan` pra projetar sem executar. `general-purpose` só se precisar raciocínio + escrita + múltiplas tools.
- Subagente mecânico → `model: "sonnet"` ou `"haiku"`. Opus só pra trade-offs reais.

## Limites de execução local (16GB — 2 crashes por OOM em 11-12/08/2026)

- Até **4 agentes background por sessão**; destes, no máximo **2 executando teste/build simultaneamente** (os outros 2 em leitura/escrita/worktree). Frente pesada extra = fila.
- Test runners (jest/vitest/etc.) SEMPRE com limite de workers (`--maxWorkers=2` ou equivalente), em **foreground**, uma suíte por vez. Suíte COMPLETA de um projeto: 1 por vez na máquina inteira.
- Builds (ng/webpack/vite): contam como slot de execução; nunca 2 builds do mesmo app em paralelo.
- Prompts de agente devem embutir esses limites + proibição de rodar testes em background (agente esperando job morto = travamento clássico).
- Worktrees com schema/codegen divergente (ex.: Prisma client compartilhado): regenerar SÓ na própria vez de teste, com exclusividade (nenhum outro test runner ativo).
- Antes de nova onda: `ps aux | grep -cE '[n]ode'` — muito acima do normal (~15), investigar/matar órfãos antes de despachar. Pós-crash: sempre caçar processos órfãos primeiro.
- Tarefa focada com um único terminal ponta a ponta (com reviewer): pode exceder pontualmente, com monitoramento de memória.

## Code review

- Leituras → `Explore`; síntese fica no Opus.
- `diff` + `Read` com `offset`/`limit` no entorno das mudanças > ler arquivo inteiro.
- **Custo do reviewer**: o fork multi-agente do `/code-review` (herda o modelo da sessão, 9-10 finders) só pra mudança CRÍTICA — dinheiro, segurança, multi-tenant, schema/migração. PR rotineira → 1 agente `sonnet` com checklist focado. **Bypass**: se o usuário pedir "review profunda/pesada/completa", usar o fork multi-agente sem questionar, em qualquer PR.

## Contexto

- Arquivos grandes: `Read` com `offset`/`limit`.
- Specs e notas longas → arquivo `.md`, não chat.
- Troca de assunto → sugerir `/clear`.

## MCP (ClickUp, etc.)

- **Planeje antes de chamar.** Antes de usar o MCP do ClickUp (ou qualquer MCP externo pesado), mapeie todas as operações que serão feitas e estime o custo em tokens. Apresente o plano ao usuário se forem muitas chamadas (>5).
- `detail_level: 'summary'` **sempre**, exceto quando for estritamente necessário ler description/custom fields completos. `summary` corta ~85% dos tokens (~116k → ~18k na mesma task).
- `get_task` sem `detail_level` é a chamada mais cara do ClickUp (~30k tokens). Evite; use `summary` ou `filter_tasks` quando só precisa de status/id/nome.
- Batch updates em paralelo (reduz round-trips) mas cada resposta JSON ainda consome tokens — contabilize.
- `filter_tasks` traz até 100 tasks por página sem projeção de campos. Use filtros específicos (list_ids, statuses, tags) pra reduzir o volume.

## Comunicação

- Updates entre tool calls: uma frase.
- Final: direto, sem repetir o diff.

## Atribuição

- **NUNCA** assine, atribua ou indique co-autoria sua (Claude/Anthropic) em commit, código, comentário, PR ou doc.
- Inclui `Co-Authored-By`, footers `Generated with Claude Code`, `// AI-assisted`, etc. Se algum template inserir, remova.

## Git

- Commit: uma linha, conventional commits, sem corpo. Ex: `feat: add login button`.
- Nunca `--no-verify`, nunca amend de commit publicado, nunca push/merge sem autorização explícita.

## Ações destrutivas

- **Confirme antes** de executar: `push --force[-with-lease]`, `reset --hard`, `rebase`, `branch -D`, `checkout .`, `clean -fd`, `restore .`, `rm -rf`, drop de tabela, ou qualquer irreversível.
- Pergunte: "X é irreversível e pode Y. Confirma?" — espera resposta explícita.
- Autorização vale só pro escopo confirmado. Aprovar uma vez ≠ aprovar sempre.
- Obstáculo → investigue causa raiz. Nunca use destrutiva como atalho.

## Package managers

- **bun** > npm. Evite yarn.
- Lockfile existente manda — respeite, mas sinalize migração quando fizer sentido.

## Versionamento de config e skills

- Config do Claude Code (`CLAUDE.md`, comandos, skills) vive em **um de dois repos versionados**, nunca solta em `~/.claude/`:
  - **Pessoal / cross-projeto** → `~/dotfiles/claude/` (`git@github.com:shuhikari/dotfiles.git`)
  - **Skills de time (Auditore)** → `~/ws/auditore/auditore-skills/` — remote único `git@github.com:auditoreie/leap-of-faith-skills.git` (`origin`). O espelho da Sintetiza foi descontinuado; não há mais `SYNC.md` nem reconciliação entre remotes. Skills agrupadas por área sob `skills/<area>/` (`engenharia`, `gestao`, `integracoes`).
- Antes de criar/editar skill ou comando, **pergunte ao usuário em qual repo entra**. Não assuma.
- Escreva direto no repo; o `install.sh` de cada repo cuida do symlink pra `~/.claude/` (recursa `skills/**/SKILL.md`).
- Commit em `leap-of-faith-skills` tipicamente exige PR/review — confirme antes de pushar direto em main.
