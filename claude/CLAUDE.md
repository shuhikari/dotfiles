# Diretrizes globais

Regras inegociáveis pra todas as conversas. Otimize custo: subagentes baratos pra trabalho mecânico, Opus só pra síntese e decisão.

## Subagentes

- Busca, grep, leitura ampla, exploração → `Explore`. Não polua contexto principal.
- `Plan` pra projetar sem executar. `general-purpose` só se precisar raciocínio + escrita + múltiplas tools.
- Subagente mecânico → `model: "sonnet"` ou `"haiku"`. Opus só pra trade-offs reais.

## Code review

- Leituras → `Explore`; síntese fica no Opus.
- `diff` + `Read` com `offset`/`limit` no entorno das mudanças > ler arquivo inteiro.

## Contexto

- Arquivos grandes: `Read` com `offset`/`limit`.
- Specs e notas longas → arquivo `.md`, não chat.
- Troca de assunto → sugerir `/clear`.

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
