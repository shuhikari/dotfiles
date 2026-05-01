# ADR-003: Claude Code CLI como agente principal

## Status
Aceito

## Contexto

Mercado de IA pra coding tem três paradigmas distintos:
1. **IA inline no editor** (Cursor, Copilot) — sugestões enquanto digita
2. **IA agêntica integrada ao editor** (Cursor Composer, Zed Edit Predictions)
3. **Agente CLI separado** (Claude Code, Aider)

Usuário tem assinatura Claude e prefere fluxo terminal-first. Já paga tokens
suficientes pra Claude — adicionar Cursor seria duplicar capacidade pagando duas vezes.

Para tarefas complementares (autocomplete inline, fallback quando Claude rate-limit):
- Não usar IA inline pesada — distrai mais que ajuda no fluxo Vim
- Gemini Flash via minuet-ai oferece autocomplete leve com free tier generoso
- Em produção/backend, Anthropic SDK direto no NestJS

## Decisão

Stack de IA por contexto de uso:

| Uso | Provider | Razão |
|---|---|---|
| Coding agent (CLI) | Claude Code | Já assinado, melhor pra agentic |
| Inline autocomplete (nvim) | Gemini 2.5 Flash via minuet-ai | Free tier, leve |
| Backend (classificação) | Anthropic SDK direto (Haiku 4.5) | Prompt caching + Batch API |
| Fallback emergencial | OpenRouter (key única) | Quando Claude rate-limited |

Sem proxy/gateway intermediário. Sem LiteLLM. Cada uso fala direto com seu provider.

## Consequências

**Positivas:**
- Custo otimizado por caso de uso
- Cada ferramenta especializada faz uma coisa bem
- Claude Code se beneficia direto de novas features (Agent Teams, prompt caching, etc)
- Zero infraestrutura adicional

**Negativas:**
- Múltiplas API keys pra gerenciar
- Sem cost tracking centralizado (vale aceitar até crescer)
- Sem fallback automático Claude→outro (precisa re-rodar manual em rate limit)

## Alternativas consideradas

- **OpenRouter como único provider** — markup pequeno mas reduz a 1 key. Descartado
  porque Claude Code precisa Anthropic API direto, não suporta OpenRouter.
- **LiteLLM como gateway** — overkill pra dev individual, ver ADR-008.
- **Apenas Claude pra tudo** — caro, e Claude rate limit pode bloquear fluxo.

## Quando reavaliar

- Se Claude Code ganhar suporte oficial a multi-provider via configuração
- Se equipe crescer e precisar cost tracking centralizado (aí entra LiteLLM)
- Se Anthropic mudar política de rate limit drasticamente

## Data
2026-04-26
