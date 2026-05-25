# Claude Code — Otimização de uso, segurança e replicação

**Audiência:** gestão
**Objetivo:** validar as mudanças aplicadas (eficiência + segurança) e o plano de replicação pra equipe
**Data:** 2026-05-25

---

## Contexto

O Claude Code é a ferramenta de IA usada pela engenharia pra acelerar desenvolvimento, code review e especificação de tarefas. Custo escala com:

1. **Tamanho do contexto** carregado em cada conversa
2. **Quantidade e potência dos subagentes** disparados
3. **Modelo usado** em cada operação (Opus é o mais caro e mais capaz)

Além de custo, existe **risco operacional**: o agente pode, em tese, executar ações destrutivas no repositório (force push, reset, rebase) se a instrução não for explícita.

A análise de uso (`/usage` nativo do Claude Code) revelou três ofensores principais nas últimas 24h:

| Métrica | % do uso | Diagnóstico |
|---|---|---|
| Sessões com >150k de contexto | 60% | Sessões longas sem reset, leituras desnecessárias |
| Sessões dominadas por subagentes | 67% | Subagentes herdam Opus + ferramentas pesadas |
| Subagente `general-purpose` | 44% | Usado pra busca simples (Explore basta) |

Esses três pontos são **independentes**: cada um responde por parte separada do custo, e cada um tem alavanca própria. A segurança (4ª dimensão) entra como governança transversal.

---

## O que foi feito

Seis entregas, todas em forma de **configuração persistente versionada** (não dependem de lembrar a cada sessão, e replicam entre máquinas):

| Entrega | Onde | Função |
|---|---|---|
| **Diretrizes globais** | `~/dotfiles/claude/CLAUDE.md` (symlinkado em `~/.claude/CLAUDE.md`) | Regras injetadas em toda conversa: subagente certo, modelo barato, gestão de contexto, padrão de commit, **ações destrutivas proibidas sem confirmação** |
| **Comando `/review` otimizado** | `~/dotfiles/claude/commands/review.md` | Para de ler arquivos completos no contexto principal; delega leitura a subagente leve |
| **Comando `/dotfiles-sync`** | `~/dotfiles/claude/commands/dotfiles-sync.md` | Atualiza config local em qualquer máquina via `git pull` + `install.sh`; nunca executa ações destrutivas |
| **`install.sh` cross-OS atualizado** | `~/dotfiles/install.sh` | Symlinka CLAUDE.md, comandos e skills em macOS, WSL e Linux; idempotente, com backup automático |
| **CLAUDE.md do projeto sintetiza** | `<repo>/CLAUDE.md` | Contexto específico (stack, package manager, decisões de produto) injetado no projeto |
| **Documentação interna** | `~/dotfiles/team-standards/docs/` | Guia técnico de replicação + esta apresentação |

---

## Princípios aplicados

### 1. Orquestração por custo/risco

Cada tarefa vai pro modelo proporcional ao risco:

- **Trabalho mecânico** (busca, leitura, listagem) → Sonnet ou Haiku (mais baratos)
- **Análise e síntese** (design, code review final, decisões) → Opus (mais caro, mais capaz)

Antes: tudo no Opus por default. Depois: Opus reservado pro que exige julgamento.

### 2. Contexto principal é recurso escasso

O contexto da conversa principal acumula custo a cada token. A regra nova:

- Leituras amplas (busca de arquivos, exploração de codebase) vão pra subagente isolado, que devolve só o resumo destilado
- O contexto principal recebe apenas o necessário pra decidir e editar

### 3. Configuração > disciplina

Regras vivem em arquivo versionado (`CLAUDE.md` em dotfiles), não na cabeça do dev. Quem usa a ferramenta segue o padrão automaticamente, sem precisar lembrar — e a replicação cross-máquina é um `git pull`.

### 4. Segurança por default (reversibilidade)

Nenhuma ação destrutiva (force push, reset --hard, rebase, rm -rf, drop) pode ser executada pelo agente sem confirmação explícita do usuário. A regra é inegociável e está formalizada no CLAUDE.md global.

- Autorização nunca é "geral": vale só pro escopo confirmado
- Diante de obstáculo, o agente investiga causa raiz; nunca usa destrutivo como atalho

---

## Impacto esperado

Estimativa conservadora baseada nos números atuais:

| Métrica | Atual | Esperado | Mecanismo |
|---|---|---|---|
| `>150k context` | 60% | 30-40% | `/clear` entre tarefas + paragem de leitura cega |
| `general-purpose` | 44% | <10% | Substituído por Explore (mais leve) |
| Custo médio de sessão | baseline | -30 a -45% | Combinação dos efeitos acima |
| Incidentes destrutivos acidentais | risco latente | 0 | Regra explícita + obrigação de confirmação |
| Tempo de setup de máquina nova | horas | minutos | `git clone dotfiles && ./install.sh` |

Validação: reanalisar `/usage` após 2 semanas de adoção + auditar logs de comandos sensíveis.

---

## Plano de replicação pra equipe

| Fase | Ação | Responsável | Prazo |
|---|---|---|---|
| 1 | Validação com gestão (essa apresentação) | Édipo | imediato |
| 2 | Distribuir guia técnico (`claude-code-token-efficiency.md`) ao time | Édipo | semana 1 |
| 3 | Cada dev clona dotfiles + roda `./install.sh` (ou setup manual) | Time | semana 1-2 |
| 4 | Cada repo principal recebe seu `CLAUDE.md` local | Owner do repo | semana 2-3 |
| 5 | Revisão coletiva: cada um roda `/usage` e compara | Time | semana 4 |
| 6 | Ajustes nas diretrizes com base nos números reais | Édipo + time | semana 4-5 |
| 7 | Atualização posterior: `/dotfiles-sync` em qualquer máquina | Time (auto) | contínuo |

---

## Riscos e mitigação

| Risco | Mitigação |
|---|---|
| Dev não adota o `CLAUDE.md` global (esquece de criar) | Setup unificado via dotfiles + `install.sh` — uma linha resolve tudo |
| Drift entre máquinas (config no Mac diverge do WSL) | Fonte única de verdade no dotfiles + `/dotfiles-sync` pra atualizar |
| Regra fica vaga e Claude continua usando Opus por default | Após 2 semanas, ajustar com base nos números reais de `/usage` |
| Subagente errado pra tarefa crítica (subestima risco) | Regra explícita: tarefas críticas (segurança, arquitetura) seguem em Opus |
| Time vê como burocracia e ignora | Comunicar o "porquê" (economia + segurança mensuráveis), não só o "como" |
| Ação destrutiva acidental do agente | Regra inegociável no CLAUDE.md global + memória de feedback persistente |

---

## Pedido à gestão

1. **Validar** a abordagem e os princípios aplicados
2. **Aprovar** dedicação de tempo do time pra fase de adoção (estimativa: 1-2h por dev na semana 1)
3. **Apoiar** a revisão coletiva da semana 4 como checkpoint formal de eficiência
4. **Endossar** a regra de segurança como política da empresa (não apenas preferência individual)

---

## Anexos / referências

- Guia técnico completo: `~/dotfiles/team-standards/docs/claude-code-token-efficiency.md`
- Template global aplicado: `~/dotfiles/claude/CLAUDE.md`
- Comando de replicação: `~/dotfiles/claude/commands/dotfiles-sync.md`
- Documentação oficial Claude Code: https://docs.claude.com/en/docs/claude-code
