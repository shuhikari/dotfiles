# Claude Code — uso eficiente de tokens

Guia interno pra reduzir custo, melhorar performance e operar com segurança o Claude Code no dia a dia. Baseado em análise de uso real (`/usage`) e nas alavancas que efetivamente movem o ponteiro.

## TL;DR — os principais ofensores

| Sintoma no `/usage` | Causa | Alavanca |
|---|---|---|
| `>150k context` em % alta | Sessão longa sem `/clear`, leituras de arquivo cheio | Hábito + comandos customizados |
| `subagent-heavy sessions` em % alta | Subagentes herdam Opus + ferramentas pesadas | Configurar modelo barato + escolher agente certo |
| `general-purpose` em % alta | Usado pra busca simples (onde Explore basta) | CLAUDE.md global com regra explícita |
| Acidentes destrutivos (force push, reset --hard, rm) | Falta de regra explícita; agente assume autorização | CLAUDE.md global com regra inegociável |

A solução é **configuração persistente** (não força de vontade). Quem depende de lembrar a cada sessão acaba não lembrando.

---

## Setup — opção 1 (recomendada): via dotfiles

Setup uniforme cross-machine (macOS, WSL, Linux). Quem já mantém um repo de dotfiles versionado já tem 80% do trabalho feito — basta adicionar o template + symlink no `install.sh`.

```bash
# 1. Clonar (uma vez por máquina nova)
git clone <seu-repo-dotfiles> ~/dotfiles

# 2. Rodar o instalador (cross-OS, idempotente, faz backup)
cd ~/dotfiles && ./install.sh

# 3. Pra atualizar depois (em qualquer máquina já configurada)
#    Dentro do Claude Code:
/dotfiles-sync
```

O `install.sh` cria symlinks:
- `~/.claude/CLAUDE.md` → `~/dotfiles/claude/CLAUDE.md` (diretrizes globais)
- `~/.claude/commands/*.md` → `~/dotfiles/claude/commands/*.md` (comandos customizados)
- `~/.claude/skills/*` → `~/dotfiles/claude/skills/*` (se houver)

O comando `/dotfiles-sync` (que vive em `~/dotfiles/claude/commands/dotfiles-sync.md`) faz `git pull --ff-only` + re-roda `install.sh` — nunca executa ações destrutivas (sem `reset`, `rebase`, `--force`); se houver conflito, pausa e pergunta.

## Setup — opção 2: manual (sem dotfiles)

Crie `~/.claude/CLAUDE.md` à mão, com o conteúdo abaixo. Cada dev mantém o seu — sem versionamento, sem replicação automática.

```markdown
# Diretrizes globais

## Subagentes e leitura de código
- PADRÃO: leitura ampla → subagente `Explore` (read-only, mais leve).
- Contexto principal Opus reservado pra design, edits críticos, síntese.
- `Plan` pra planejar sem executar.
- `general-purpose` só quando exige raciocínio + escrita + múltiplas ferramentas.
- Em chamadas `Agent` mecânicas, passe `model: "sonnet"` ou `"haiku"`.

## Code review
- Leituras de arquivo vão pro Explore.
- Síntese final no Opus, recebendo trechos destilados.
- Nunca leia arquivo completo se `diff` + `Read` com offset/limit resolve.

## Gestão de contexto
- Não releia arquivos recém-editados.
- `Read` com offset/limit em arquivos grandes.
- Sugira `/clear` ao trocar de assunto.
- Specs/notas longas vão pra arquivo .md, não pro chat.

## Chain of thought e comunicação
- Sucinto: menos tokens, mais objetividade.
- Updates entre tool calls: uma frase, não parágrafos.

## Git e commits
- NUNCA `Co-Authored-By`.
- Mensagem é uma linha só (commitlint), sem corpo.
- Formato: `<tipo>: <descrição curta no imperativo>`.

### Ações destrutivas — regra inegociável
- NUNCA `git push --force`, `reset --hard`, `rebase`, `branch -D`,
  `checkout .`, `clean -fd`, `restore .`, `rm -rf`, drop de tabela
  — sem confirmar com o usuário.
- SEMPRE pare e pergunte: "você tem certeza? a ação X é irreversível
  e pode causar Y. confirma?"
- Autorização vale só pro escopo confirmado. Não extrapola.
- Diante de obstáculo, nunca use destrutivo como atalho.
  Investigue causa raiz.

## Build e package managers
- bun > npm. Evite yarn.
- Se já travado em outro PM (lockfile), respeite e sinalize migração possível.
```

## CLAUDE.md por projeto

Independente da opção acima, cada repo principal deve ter seu próprio `CLAUDE.md` no root. Mantém curto — não duplica a global. Seções úteis:

- **Stack**: linguagens, frameworks, versões
- **Package manager**: qual usar (se diverge do default global)
- **Scripts úteis**: comandos mais usados
- **Estrutura mental rápida**: árvore com 1 linha por pasta
- **Convenções**: padrões específicos (i18n, testes, naming etc)
- **Gotchas**: armadilhas que custaram tempo no passado
- **Git nesse projeto**: restrições específicas (branch protegida etc)

---

## Comportamentos no dia a dia

Mesmo com tudo configurado, alguns hábitos só dependem do usuário:

| Situação | Ação |
|---|---|
| Iniciar tarefa nova | `/clear` antes de começar (zera contexto) |
| Continuar tarefa atual mas contexto inflou | `/compact` (resume e mantém o essencial) |
| Escrever spec/nota longa | Salve direto em `.md` no projeto. Não cole no chat |
| Pedir "leia o arquivo inteiro" sem motivo | Evite. Aponte a região (linha X a Y) |
| Loop de "tenta isso, agora aquilo" | Pare. Use `/spec` ou `Plan` antes de codar |
| Setup de máquina nova | `git clone dotfiles && ./install.sh` |
| Atualizar config após mudança em dotfiles | `/dotfiles-sync` |

---

## Escolha do subagente — referência rápida

| Tarefa | Subagente | Modelo sugerido |
|---|---|---|
| "Onde está definida a função X?" | `Explore` | sonnet |
| "Quais arquivos importam Y?" | `Explore` | sonnet/haiku |
| "Resumir o que faz esse módulo" | `Explore` | sonnet |
| Planejar implementação multi-arquivo | `Plan` | opus (default) |
| Pergunta sobre Claude Code/SDK | `claude-code-guide` | default |
| Pesquisa ampla, multi-step, exige escrita | `general-purpose` | sonnet (se mecânico) ou opus |
| Refactor mecânico em arquivo conhecido | Não use subagente — direto | — |
| Leitura de arquivo conhecido | Não use subagente — `Read` direto | — |

**Regra de ouro**: se o alvo já é conhecido (caminho, símbolo específico), use ferramenta direta. Subagente só compensa se o resultado bruto seria grande demais ou se há paralelismo real.

---

## Segurança — ações destrutivas

Regra inegociável no CLAUDE.md global: **nenhuma ação destrutiva é executada sem confirmação explícita do usuário**. Lista não-exaustiva:

- `git push --force` (e `--force-with-lease`)
- `git reset --hard`, `git rebase`, `git branch -D`
- `git checkout .`, `git restore .`, `git clean -fd`
- `rm -rf`
- Drop de tabela / truncate em DB
- Kill de processo em produção
- Sobrescrita de arquivo com mudanças não commitadas

Quando o agente encontrar uma situação que pareça pedir ação destrutiva (ex: conflito de merge, divergência de branches, lock file órfão), **a regra é investigar a causa raiz e propor alternativa não-destrutiva** — não usar o destrutivo como atalho.

Autorização nunca é "geral": vale só pro escopo confirmado naquele momento. Aprovação de force push em uma branch NÃO autoriza force push em outra depois.

---

## Estrutura de arquivos sugerida

```
~/dotfiles/                       # repo versionado, cross-OS
├── install.sh                    # cria todos os symlinks (idempotente, com backup)
├── claude/
│   ├── CLAUDE.md                 # diretrizes globais (fonte canônica)
│   ├── commands/
│   │   ├── spec.md               # /spec
│   │   ├── review.md             # /review (otimizado pra Explore)
│   │   └── dotfiles-sync.md      # /dotfiles-sync
│   └── skills/                   # (opcional) skills customizadas
└── team-standards/docs/          # docs internos (esse guia + apresentação)

~/.claude/                        # gerenciado pelo Claude Code
├── CLAUDE.md → ~/dotfiles/claude/CLAUDE.md      (symlink)
├── settings.json                 # config local (tema, permissions) — NÃO versionado
└── commands/
    ├── spec.md → ~/dotfiles/claude/commands/spec.md
    ├── review.md → ~/dotfiles/claude/commands/review.md
    └── dotfiles-sync.md → ~/dotfiles/claude/commands/dotfiles-sync.md

<projeto>/CLAUDE.md               # contexto específico do projeto (versionado no projeto)
```

---

## Checklist de adoção

Quando configurar uma máquina nova ou onboarding de novo dev:

- [ ] Clonar dotfiles e rodar `./install.sh` (ou seguir setup manual da opção 2)
- [ ] Validar: `ls -la ~/.claude/CLAUDE.md` deve mostrar symlink pra dotfiles
- [ ] Validar: `/dotfiles-sync` disponível em qualquer conversa Claude Code
- [ ] Para cada repo principal: `CLAUDE.md` no root criado
- [ ] Time alinhado em: `/clear` entre tarefas, `/compact` em sessão longa
- [ ] Acordo de não usar `general-purpose` pra busca (sempre Explore)
- [ ] Acordo de passar `model: sonnet/haiku` em subagentes mecânicos
- [ ] Time ciente da regra de ações destrutivas (sempre confirmar)

---

## Sinais de que está funcionando

Depois de 1-2 semanas de uso com essas práticas, esperamos ver no `/usage`:

- % de `>150k context` cai (sessões mais curtas, `/clear` mais frequente)
- % de `general-purpose` cai pra <10% (substituído por Explore)
- % de `subagent-heavy` segue alta mas com custo menor (modelos baratos)
- Zero incidentes de ação destrutiva acidental (vs. baseline anterior)

Se algum desses não melhorar, vale revisitar o CLAUDE.md global — talvez a regra esteja vaga ou um padrão novo apareceu que ainda não está documentado.

---

## Referências

- Docs oficiais Claude Code: https://docs.claude.com/en/docs/claude-code
- Subagentes: https://docs.claude.com/en/docs/claude-code/sub-agents
- Custom commands: https://docs.claude.com/en/docs/claude-code/slash-commands
- `/usage` no app: mostra breakdown da própria conta
