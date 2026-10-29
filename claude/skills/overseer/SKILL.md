---
name: overseer
description: Visão de supervisor sobre todos os agentes abertos no Orca — coleta, só em leitura, o estado de cada worktree (agente trabalhando ou parado, há quanto tempo, último pedido, última resposta, git, PR vinculado) e os handoffs abertos do ai-memory, e devolve uma triagem por prioridade (o que precisa de você agora, o que está rodando, o que está parado esperando retomada, o que só falta merge) com o próximo passo concreto de cada um e um plano de retomada em ordem. Use quando o usuário disser "overseer", "o que está rolando nos agentes", "o que cada agente está esperando", "o que é mais crítico agora", "resumo do Orca", "vou dormir, fecha o dia", "de onde eu paro/retomo", "bom dia, onde parei", "/overseer [agora|dormir|retomar]". Também cataloga as horas de cada sessão (suas e dos agentes) por cliente e task, para cobrança: use quando o usuário disser "quantas horas trabalhei pra X", "horas do mês", "planilha de cobrança", "/overseer horas". NÃO use para executar o trabalho dos outros agentes, mandar input para terminais deles ou coordenar workers despachados (isso é a skill orchestration), nem para resumir só a sessão atual.
---

# Overseer do Orca

O usuário mantém dezenas de worktrees e agentes abertos no Orca e precisa de uma
visão única: o que cada um estava fazendo, onde parou, o que espera dele e o que é
mais urgente. O overseer **lê e resume**. Ele não age nos outros agentes.

## Modos

| Modo | Quando | Saída |
|---|---|---|
| `agora` (padrão) | Triagem no meio do dia | Relatório no chat |
| `dormir` | Fechamento do dia | Relatório no chat, gravado em arquivo e enviado ao aparelho |
| `retomar` | Começo do dia | Compara com o último relatório salvo e propõe a ordem de retomada |

## Passos

1. **Coletar.** Rode o coletor. Ele é só leitura e leva poucos segundos:

   ```bash
   python3 ~/.claude/skills/overseer/scripts/collect.py > "$SCRATCH/overseer-snapshot.md"
   ```

   Em seguida, atualize o catálogo de horas (veja **Horas para cobrança**):
   `python3 ~/.claude/skills/overseer/scripts/horas.py sync`.

   Grave no scratchpad e leia o arquivo; a saída passa de 50 KB. `--all` detalha também
   as worktrees sem terminal vivo, e `--no-git` pula o git. Se o coletor disser que o
   Orca não responde, rode `orca open --json` e repita. Se falhar de novo, mostre o
   erro e pare: sem o `orca worktree ps` não existe overseer.

2. **Ler cada worktree** do snapshot. O mais forte é a **última resposta do agente**:
   quase sempre ela traz o que foi feito, o que ficou pendente e a pergunta em aberto.
   O **tema da sessão** e os **pedidos recentes** dão o contexto. Ignore a entrada
   marcada `ESTA SESSÃO`.

3. **Classificar** cada worktree com agente em **um** grupo:

   - 🔴 **Precisa de você agora.** O agente terminou com pergunta, decisão ou aprovação
     pendente, e o assunto é crítico: produção quebrada ou exposta, dinheiro,
     segurança, dado de cliente, prazo regulatório ou externo, ou um deploy ou PR que
     bloqueia outras pessoas. Também entram aqui sessões interrompidas no meio de uma
     ação que altera estado (deploy, migração, push).
   - 🟠 **Esperando você, sem urgência.** Há pergunta ou decisão em aberto, mas nada
     quebra se esperar.
   - 🔵 **Rodando.** O estado é `working`. Diga o que está fazendo e quando vale olhar.
   - 🟡 **Parado no meio.** Terminou o turno sem pergunta, mas o trabalho não acabou:
     há alterações não commitadas, commits não publicados, próximo passo citado ou
     handoff aberto.
   - 🟢 **Entregue, falta só fechar.** PR aberto aguardando merge ou review, ou
     confirmação final.
   - ⚪ **Ocioso.** Não há sinal de trabalho pendente. Liste numa linha só.

   A urgência vem do **conteúdo**, não do tempo parado. Justifique cada 🔴 com o trecho
   que a sustenta, por exemplo "a falha segue em produção até o deploy da API". Se o
   registro não deixa claro o que falta, escreva "não dá para saber pelo registro;
   abrir a sessão". Nunca invente próximo passo.

4. **Handoffs abertos.** Cruze cada handoff com as worktrees pelo `cwd`. Os que não
   correspondem a nenhum agente vivo vão para uma seção própria: são trabalho que
   ninguém retomou. Handoff de mais de 14 dias entra como "provavelmente velho;
   confirmar se ainda vale".

5. **Escrever o relatório** neste formato:

   ```markdown
   # Overseer — <data hora>

   **Resumo:** <N> precisam de você (<M> críticos), <K> rodando, <J> parados no meio.

   ## 🔴 Precisa de você agora
   ### [N] «<nome da sessão>» — <o que é, em linguagem de negócio>
   - **Onde:** card «<nome do card>» no repo <repo> · `orca terminal switch --terminal <handle>`
   - **Onde parou:** <1–2 linhas>
   - **Espera de você:** <decisão/pergunta exata, com links de PR/task que vieram no texto>
   - **Por que é urgente:** <evidência>
   - **Próximo passo:** <ação concreta>

   ## 🟠 Esperando você, sem urgência
   ## 🔵 Rodando
   ## 🟡 Parado no meio
   ## 🟢 Entregue, falta só fechar
   ## Handoffs não retomados
   ## ⚪ Ociosos
   <uma linha: nomes separados por vírgula>

   ## Ordem sugerida de retomada
   1. [N] «<nome da sessão>»: <ação> (<motivo>)

   Para abrir: "abre o N".
   ```

   **Identifique cada item pelo que o usuário vê no Orca, nunca só pelo repo.** Use o
   número `[N]` do snapshot, o **nome da sessão** (título da aba, `sessão «…»`) e o
   **nome do card** da worktree. Vários cards podem ser do mesmo repo. Se a sessão não
   tiver título, use o nome do card. Nos grupos 🔵, 🟡 e 🟢 use uma ou duas linhas por
   item, começando por `[N] «nome»`, e detalhe só o 🔴. Mantenha os links que vieram no
   texto dos agentes (PRs, tasks); não monte URL que não está no snapshot.

5b. **Abrir um item.** Se o usuário disser "abre o N", "vai pro N" ou citar o nome de
    uma sessão, rode o `orca terminal switch --terminal <handle>` desse item, que
    está na linha `acesso` do snapshot, e confirme em uma linha. Isso só muda o foco
    da interface do Orca. Se o item não tiver terminal vivo, informe o
    `cd <caminho> && claude --resume <id>` da mesma linha.

6. **Modo `dormir`.** Grave o relatório em
   `~/.local/state/overseer/<AAAA-MM-DD-HHMM>.md` (crie a pasta se faltar) e envie o
   arquivo por Taildrop, como manda o CLAUDE.md global. Inclua a seção **"Horas de
   hoje"**, com a saída de `horas.py relatorio --de <hoje> --ate <hoje>`, e acrescente uma seção
   **"Antes de fechar"** com o que convém resolver ainda hoje: agentes `working` que vão
   ficar sem supervisão e mudanças não commitadas em branch compartilhada.

7. **Modo `retomar`.** Leia o relatório mais recente em `~/.local/state/overseer/`,
   colete de novo e mostre primeiro **o que mudou desde então** (agente que terminou,
   PR mergeado, worktree nova ou fechada). Depois mostre a ordem de retomada atualizada.

## Horas para cobrança

`scripts/horas.py` cataloga cada sessão do Claude Code, de qualquer pasta e não só do
Orca, em `~/.local/state/overseer/horas/sessoes/<sessão>.json`. O registro é
permanente, mesmo depois que o Claude Code apaga a transcrição (`cleanupPeriodDays`,
padrão de 30 dias: https://code.claude.com/docs/en/settings-reference#cleanupperioddays).
Ele é alimentado pelo hook `SessionEnd` em `~/.claude/settings.json` e por toda coleta
do overseer.

- **Relatório:** `horas.py relatorio --de AAAA-MM-DD --ate AAAA-MM-DD [--cliente X] [--csv]`.
  Agrupa por cliente, task e sessão, com o dia contado em America/Sao_Paulo.
- **Métricas:**
  - **agente:** tempo do agente trabalhando nos seus turnos, descartando pausas acima de 10 min;
  - **suas:** a espera antes de cada pedido seu, até 15 min (acima disso, você estava fora);
  - **subagentes:** tempo dos agentes em paralelo, mostrado à parte e fora do total.
- **Cliente:** vem de `~/.config/overseer/clientes.json` (regex sobre cwd, repo e
  branch). Esse arquivo fica fora do git, porque tem nomes de clientes.
- **Task:** chave tipo `PROJ-123` tirada da branch ou do título da sessão.
- A regra de cobrança mora só no relatório: o catálogo guarda os fatos de cada turno,
  então mudar teto ou pausa não exige recatalogar. Use `sync --force` só depois de
  mudar o que é extraído.
- Quando o usuário pedir horas ("quanto trabalhei pra X", "horas do mês", "planilha de
  cobrança"), rode `sync` e depois `relatorio`. Para planilha, use `--csv` e entregue
  o arquivo por Taildrop.

## Limites

- Só leitura. A única ação permitida é `orca terminal switch`, quando o usuário pede
  para abrir um item. Não use `orca terminal send`, não mexa em git e não aceite nem
  cancele handoffs. Mandar algo ao terminal de outro agente só com pedido explícito.
- O snapshot cobre só a sessão mais recente de cada worktree e só o que o agente
  escreveu. Não cobre raciocínio interno nem outras máquinas.
- Agentes que não são Claude (Codex e outros) aparecem com estado e última resposta
  do Orca, mas sem a transcrição.
