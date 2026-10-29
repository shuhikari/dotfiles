# Diretrizes globais

Regras inegociáveis pra todas as conversas. Otimize custo: subagentes baratos pra trabalho mecânico, Opus só pra síntese e decisão.

## Subagentes

- Busca, grep, leitura ampla, exploração → `Explore`. Não polua contexto principal.
- `Plan` pra projetar sem executar. `general-purpose` só se precisar raciocínio + escrita + múltiplas tools.
- Subagente mecânico → `model: "sonnet"` ou `"haiku"`. Opus só pra trade-offs reais.
- Subagente sem `model` explícito roda em Sonnet (`CLAUDE_CODE_SUBAGENT_MODEL=sonnet` no `settings.json`). O orquestrador escolhe outro modelo conforme complexidade e risco do que despacha, e responde por essa escolha. Despacho de desenvolvimento segue a skill `despachar-dev` (ficha + `model` explícito + tag `[C·R]`).

## Code review

- Leituras → `Explore`; síntese fica no Opus.
- `diff` + `Read` com `offset`/`limit` no entorno das mudanças > ler arquivo inteiro.

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
  - **Auditore (time)** → `~/ws/auditore/auditore-skills/` (`git@github.com:auditoreie/auditore-skills.git`, ver `HOWTO.md` local)
- Antes de criar/editar skill ou comando, **pergunte ao usuário em qual repo entra**. Não assuma.
- Escreva direto no repo; o `install.sh` de cada repo cuida do symlink pra `~/.claude/`.
- Commit em `auditore-skills` tipicamente exige PR/review — confirme antes de pushar direto em main.
