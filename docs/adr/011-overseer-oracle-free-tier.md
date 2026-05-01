# ADR-011: Servidor "overseer" no Oracle Free Tier

## Status
Proposto (não implementado ainda)

## Contexto

Necessidade emergente: ter um ambiente sempre-online que centraliza
ferramentas de apoio ao desenvolvimento individual e do time:

- **Blog técnico** pra externalizar decisões e processos (facilita adoção do time)
- **Dashboard de monitoring** dos serviços que mantemos (uptime, alertas)
- **Self-hosted services** complementares (gitea mirror, status page, knowledge base)
- **Entry point de automações leves** (cron jobs, GitHub Actions runners
  self-hosted opcionais)
- **Futuro**: gateway pra LLMs (LiteLLM/OpenRouter) quando chegar nos critérios
  do ADR-008

Restrições do Oracle Free Tier (Always Free):
- 4 OCPU ARM (Ampere A1) + 24GB RAM
- 200GB block storage
- 10TB outbound/mês
- Sem GPU

## Decisão (proposta)

Provisionar uma instância A1 Flex 4-OCPU/24GB no Oracle Cloud, Ubuntu 22.04 LTS
ARM, e rodar:

### Stack base (camada 0)
- **Caddy** ou **Traefik** como reverse proxy + TLS automático
- **Tailscale** pra acesso administrativo seguro (sem expor SSH público)
- **Docker** + **docker-compose** pra orquestrar serviços

### Stack de plataforma (camada 1)
- **[Coolify](https://coolify.io)** ou **[Dokploy](https://dokploy.com)**
  como PaaS self-hosted (UI pra deployar containers, webhooks GitHub, TLS)
- **Watchtower** pra updates automáticos de containers

### Serviços iniciais (camada 2)
- **Blog técnico** (Astro + MDX, ver ADR-012)
- **Uptime Kuma** pra monitoring dos serviços teus + da empresa
- **Status page** público derivado do Uptime Kuma
- **Vaultwarden** ou **Bitwarden self-hosted** pra secrets compartilhados (opcional)

### NÃO rodar nesse servidor

- **LLM inference** (sem GPU, performance pra Llama 7B é ~5-8 tok/s, inviável)
- **CI/CD pesado** (Oracle não gosta de heavy compute, pode suspender conta)
- **Mineração ou qualquer compute abusivo** (Oracle suspende sem aviso)
- **Bancos de dados de produção crítica** (sem garantia SLA no free tier)

## Consequências

**Positivas:**
- Custo zero em hospedagem
- Centraliza ferramentas que de outro modo viveriam scatered
- Material publicado serve de documentação E ferramenta de adesão do time
- Plataforma pra crescer (adicionar serviços conforme necessidade)
- ARM é arquitetura do futuro (Apple Silicon, AWS Graviton, etc) — bom pra praticar

**Negativas:**
- Free tier pode ser suspenso a critério da Oracle (precaução: backup periódico
  do disco em S3-compatible externo)
- ARM exige imagens Docker compatíveis (a maioria já é multi-arch, mas alguns
  serviços ainda só têm x86)
- Maintenance overhead — server next door requer cuidado mínimo (updates, monitoring)
- 24GB RAM é o teto: se precisar mais, paga ou particiona

## Alternativas consideradas

- **Hetzner Cloud (~$4/mês CX22)** — pago, mas mais flexível e SLA confiável.
  Reavaliar se Oracle suspender ou limitar.
- **Fly.io / Railway** — bom DX mas pricing assusta com volume.
- **Self-host na própria casa** — complica acesso externo, energy cost, downtime
- **Cloudflare Workers + R2 + D1** — serverless, mas restringe muito o tipo de serviço

## Quando reavaliar

- Se Oracle suspender a conta (move pra Hetzner, plano B documentado)
- Se algum serviço exceder 24GB de RAM
- Se outbound passar 10TB/mês (improvável pra blog + monitoring)
- Se time crescer e demandar serviços de produção real (aí sai do free tier)

## Data
2026-04-26
