# ADR-008: Não adotar LiteLLM no momento

## Status
Aceito

## Contexto

LiteLLM é um proxy/gateway open-source que oferece interface OpenAI-compatible
unificada pra 100+ LLM providers. Recursos: virtual keys, cost tracking, fallback
automático, rate limiting, audit log centralizado.

Avaliamos adoção no contexto:
- 1 dev individual + time pequeno em crescimento
- Casos de uso ativos: classificação backend, code review pré-PR, autocomplete inline
- Cada caso usa SDK ou plugin específico (Anthropic SDK no NestJS, minuet-ai com Gemini, Claude Code CLI)

## Decisão

Não adotar LiteLLM agora. Manter integração direta com cada provider.

Critérios pra reavaliação documentados abaixo (seção "Quando reavaliar").

## Consequências

**Positivas:**
- Zero infraestrutura adicional pra manter
- Sem latência de proxy (~10-20ms eliminados)
- Cada cliente fala com seu provider de forma direta e otimizada
- Menos pontos de falha (gateway down = tudo down)
- Custo zero adicional

**Negativas:**
- Múltiplas API keys pra rotacionar/gerenciar
- Sem cost tracking centralizado (cada serviço tem seu billing)
- Sem fallback automático Claude → outro provider em caso de rate limit
- Audit log fragmentado entre dashboards diferentes

## Alternativas consideradas

- **OpenRouter** — proxy SaaS, single key pra 200+ modelos. Útil pra fallback simples.
  Adotado como ferramenta auxiliar (não principal): teu serviço NestJS pode apontar
  pra OpenRouter quando Claude rate limit, sem montar gateway.
- **Portkey** — gateway enterprise, similar a LiteLLM com observabilidade superior.
  Mesmo problema: overkill pra escala atual.
- **Self-hosted no Oracle Free Tier** — viável tecnicamente, mas adiciona
  manutenção de servidor pra benefício marginal.

## Quando reavaliar

Adotar LiteLLM (ou alternativa similar) quando ao menos 2 desses forem verdade:

1. Time tem **5+ devs ativos** consumindo LLMs em diferentes apps/projetos
2. Existem **3+ aplicações distintas** chamando LLMs em produção (não só
   ferramentas dev-only)
3. Precisa de **budget tracking por dev/projeto** pra accountability
4. Compliance ou governance interna **exige audit log centralizado** de uso de IA
5. Outage de provider (Claude indisponível) **bloqueia operação crítica** e
   precisa de fallback automático

Antes desses gatilhos: adicionar LiteLLM é solucionar problema futuro com
complexidade real presente.

## Data
2026-04-26
