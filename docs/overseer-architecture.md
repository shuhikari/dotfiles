# Overseer Architecture (Oracle Free Tier)

Documentação técnica do servidor de apoio. Decisão arquitetural geral em
[ADR-011](adr/011-overseer-oracle-free-tier.md).

## Provisionamento

### Recursos free tier

- **Compute**: 1x VM.Standard.A1.Flex
  - 4 OCPU ARM (Ampere Altra Neoverse N1)
  - 24 GB RAM
- **Storage**: até 200 GB block volume (default 50 GB já basta inicialmente)
- **Network**: 10 TB outbound/mês
- **IP**: 1 IPv4 público + IPv6

### Setup inicial

```bash
# Após criar VM no console Oracle:
ssh -i ~/.ssh/oracle_key ubuntu@<IP_PUBLICO>

# Update inicial
sudo apt update && sudo apt upgrade -y

# Hardening básico
sudo timedatectl set-timezone America/Sao_Paulo
sudo ufw allow 22/tcp        # SSH
sudo ufw allow 80/tcp        # HTTP
sudo ufw allow 443/tcp       # HTTPS
sudo ufw enable

# User não-root
sudo adduser deploy
sudo usermod -aG sudo,docker deploy
```

### Tailscale (acesso administrativo seguro)

Pra evitar expor SSH no IP público:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Após isso: SSH só pelo IP Tailscale interno. UFW pode bloquear `22/tcp` no público:

```bash
sudo ufw delete allow 22/tcp
```

## Stack base (camada 0)

### Docker + Compose

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# logout/login pra aplicar grupo
```

### Caddy (reverse proxy + TLS automático)

`/etc/caddy/Caddyfile`:

```caddyfile
{
    email seu@email.com
}

# Blog
blog.dominio.com.br {
    reverse_proxy localhost:3000
}

# Status page
status.dominio.com.br {
    reverse_proxy localhost:3001
}

# Coolify dashboard (acesso só Tailscale)
coolify.dominio.com.br {
    @internal {
        remote_ip 100.0.0.0/8
    }
    reverse_proxy @internal localhost:8080
    respond "Forbidden" 403
}
```

Instalação:

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy

sudo systemctl enable caddy
sudo systemctl start caddy
```

## Stack de plataforma (camada 1)

### Coolify (recomendado)

Self-hosted PaaS. UI pra deployar containers, webhooks GitHub, TLS, secrets.

```bash
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | sudo bash
```

Acessa em `http://localhost:8080` (via Tailscale ou tunneling SSH).

Alternativas:
- **Dokploy** — mais simples, foco em apps simples
- **CapRover** — interface mais antiga mas estável
- **Direto com docker-compose** — sem UI, mais controle

## Serviços (camada 2)

### Blog técnico (Astro)

```yaml
# docker-compose.yml em /opt/blog/
services:
  blog:
    build: .
    ports:
      - "127.0.0.1:3000:3000"
    restart: unless-stopped
```

Source via webhook GitHub: push em main → Coolify rebuilda.

Dockerfile típico:

```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./
EXPOSE 3000
CMD ["node", "dist/server/entry.mjs"]
```

### Uptime Kuma (monitoring)

```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    ports:
      - "127.0.0.1:3001:3001"
    volumes:
      - uptime-kuma-data:/app/data
    restart: unless-stopped
volumes:
  uptime-kuma-data:
```

Configura monitors via UI: ping, HTTP(s), keyword check, port check, certificado SSL.

### Status page público

Uptime Kuma tem status pages embutidos. Cria status page público via Settings → Status Pages.

## Limites e o que NÃO fazer

### Não rodar

- ❌ **LLM inference** — sem GPU, performance é miserável (~5-8 tok/s pra Llama 7B)
- ❌ **CI/CD pesado** — Oracle pode suspender se detectar abuse
- ❌ **Mineração** (óbvio, mas registrado)
- ❌ **Bancos de dados de produção crítica** — sem SLA
- ❌ **Streaming/transcoding de mídia** — bandwidth/CPU intensivo

### Pode rodar (com cuidado)

- ✅ Blog estático ou SSR leve (Astro, Next.js)
- ✅ Monitoring (Uptime Kuma, Healthchecks.io self-hosted)
- ✅ Knowledge base (BookStack, Outline self-hosted)
- ✅ Webhooks lightweight
- ✅ Cron jobs / scheduled tasks
- ✅ Status page
- ✅ Vaultwarden (Bitwarden compatible)
- ✅ Gitea mirror (read-only, espelho de repos)
- ✅ Plausible/Umami analytics

## Backup strategy

Free tier pode ser suspenso sem aviso. Backup é obrigatório:

```bash
# Backup diário pra S3-compatible externo (R2 da Cloudflare é gratuito até 10GB)
# Cron em crontab -e
0 3 * * * /opt/scripts/backup.sh
```

`backup.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="/tmp/backup-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Para todos os containers temporariamente pra consistência
docker compose -f /opt/blog/docker-compose.yml stop
docker compose -f /opt/uptime-kuma/docker-compose.yml stop

# Tar dos volumes
tar -czf "$BACKUP_DIR/volumes.tar.gz" -C /var/lib/docker/volumes .

# Tar dos configs
tar -czf "$BACKUP_DIR/configs.tar.gz" -C /opt .

# Sobe pro R2 (configurar rclone antes)
rclone copy "$BACKUP_DIR" r2:backup-overseer/

# Limpa local
rm -rf "$BACKUP_DIR"

# Reinicia services
docker compose -f /opt/blog/docker-compose.yml start
docker compose -f /opt/uptime-kuma/docker-compose.yml start
```

## Plano B: migração emergencial

Se Oracle suspender:

1. Hetzner Cloud CX22 (~$4/mês) — provisiona em minutos
2. Restaura backup do R2: `rclone copy r2:backup-overseer/ ./`
3. Sobe Caddy + docker-compose
4. Atualiza DNS dos subdomínios pra novo IP

Tempo total de migração estimado: ~1h se backup está em dia.

## Custos previstos

| Item | Free tier | Custo se exceder |
|---|---|---|
| Compute | 4 OCPU + 24GB | -- |
| Storage | 200 GB | $0.0255/GB/mês |
| Outbound | 10 TB/mês | $0.0085/GB |
| IPv4 | 1 reservado | $0.005/hora se ocioso |
| TLS certs | grátis (Caddy + Let's Encrypt) | -- |
| **Total esperado**: $0/mês | | |

R2 da Cloudflare pra backup: 10 GB grátis, $0.015/GB depois. Storage típico desse setup: <2GB. Total backup: $0.

## Roadmap proposto

| Fase | O quê | Quando |
|---|---|---|
| 0 | Provisionar VM + Tailscale + Caddy + Docker | Sprint 1 |
| 1 | Blog Astro deployado + DNS | Sprint 2 |
| 2 | Uptime Kuma + status page público | Sprint 3 |
| 3 | Knowledge base interna (Outline/BookStack) | Sprint 4 |
| 4 | Avaliar LiteLLM se critérios ADR-008 forem atingidos | Quando aplicável |
