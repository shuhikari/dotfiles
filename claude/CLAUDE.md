# Diretrizes globais

Estas regras valem em todos os projetos e todas as conversas. Otimização de custo de tokens e qualidade da análise são objetivos simultâneos: orquestre modelos baratos pra trabalho mecânico e reserve Opus pra síntese, design e decisões.

## Subagentes e leitura de código

- **PADRÃO**: qualquer leitura ampla de código, busca de arquivos, grep de símbolos ou exploração de codebase → delegue a subagente `Explore` (read-only, mais leve). Não consuma contexto principal com isso.
- Contexto principal do Opus é reservado pra: design, edits críticos, síntese de resultados e decisões arquiteturais.
- Use `Plan` quando o objetivo é projetar implementação sem executar.
- Use `general-purpose` só quando a tarefa exige raciocínio profundo + escrita + múltiplas ferramentas (raro). Nunca pra busca simples — sempre Explore nesse caso.
- Em qualquer chamada `Agent` cujo subagente faz trabalho mecânico (busca, leitura, listagem, conversão simples), passe `model: "sonnet"` ou `model: "haiku"`. Reserve Opus pra subagentes que precisem julgar trade-offs.

## Code review

- Leituras de arquivo durante review vão pra subagente `Explore` (baixo custo de tokens). Não leia arquivos completos no contexto principal.
- A análise final e a síntese ficam no Opus, recebendo já trechos relevantes destilados pelo Explore.
- Nunca leia arquivo completo quando `diff` + `Read` com `offset`/`limit` em torno das mudanças é suficiente.
- O grau de robustez do agente segue o risco da tarefa: revisão de mudança crítica/segurança → Opus; lint/estilo/checks mecânicos → Sonnet ou Haiku.

## Gestão de contexto

- Não releia arquivos que você acabou de editar — o harness rastreia estado.
- Pra arquivos grandes, use `Read` com `offset`/`limit` em vez de ler tudo.
- Quando o usuário trocar de assunto/feature, sugira `/clear`.
- Specs, notas e documentos longos vão direto pra arquivo `.md`, não pro chat.

## Chain of thought e comunicação

- Reporte raciocínio sucintamente: menos tokens, mais objetividade.
- Updates entre tool calls: uma frase, não parágrafos.
- Resultado final: direto ao ponto, sem repetir o que o diff já mostra.

## Git e commits

- **NUNCA** adicione `Co-Authored-By` em commits.
- Mensagem é **uma linha só**, padrão commitlint/conventional commits, **sem corpo e sem detalhes**.
- Formato: `<tipo>: <descrição curta no imperativo>` — ex: `feat: add login button`, `fix: handle null user in header`, `refactor: extract auth middleware`.

### Ações destrutivas — regra inegociável

- **NUNCA** execute `git push --force`, `git push --force-with-lease`, `git reset --hard`, `git rebase`, `git branch -D`, `git checkout .`, `git clean -fd`, `git restore .`, drop de tabela, `rm -rf`, ou qualquer outra ação que possa apagar/sobrescrever trabalho — **diretamente**, sem antes confirmar com o usuário.
- **SEMPRE** pare e pergunte: "você tem certeza disso? a ação X é irreversível e pode causar Y. confirma?" — esperando resposta explícita antes de executar.
- Autorização vale **somente pro escopo confirmado**. Se o usuário aprovou um force push numa branch, isso NÃO autoriza outro force push depois, em outra branch, ou qualquer outra destrutiva.
- Diante de obstáculo, **nunca** use ação destrutiva como atalho. Investigue causa raiz (ex: resolver conflito de merge em vez de descartar mudanças; investigar lock file em vez de deletar).
- Regras adicionais de segurança git: não fazer push/merge sem autorização explícita; nunca pular hooks (`--no-verify`); nunca amend de commit já publicado.

## Build e package managers

- Ordem de preferência: **bun** > npm. **Evite yarn**.
- Comandos default: `bun install`, `bun add`, `bun run <script>`, `bun test`.
- Se o projeto já estiver travado em outro PM (lockfile incompatível como `package-lock.json` ou `yarn.lock` presente e em uso), respeite o existente mas sinalize ao usuário a possibilidade de migrar.
