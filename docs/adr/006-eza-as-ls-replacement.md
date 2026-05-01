# ADR-006: eza como replacement do `ls`

## Status
Aceito

## Contexto

`ls` puro do macOS tem deficiências de UX:
- Sem cores por default (precisa `-G`)
- Sem indicação de git status
- `ls -lt | head` funciona mas é workaround
- Sem ícones, formato de data inflexível, sem hyperlinks

Avaliamos alternativas modernas: `eza`, `lsd`, `exa` (descontinuado).

Critérios:
- Compatibilidade multi-plataforma (macOS local, Linux/WSL futuro em servers)
- Single binary, sem deps runtime
- Manutenção ativa
- Sem CVEs públicos registrados
- Performance comparável ao `ls`

## Decisão

Adotar `eza` como replacement padrão do `ls` via aliases no `aliases.zsh`.

Setup com fallback:
```bash
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --git --group-directories-first --icons=auto'
  alias la='eza -la --git --group-directories-first --icons=auto'
  alias lr='eza -l --sort=modified --reverse --git --icons=auto'
  alias lt='eza --tree --level=2 --git-ignore --icons=auto'
else
  alias ll='ls -lh'
  alias la='ls -lha'
  alias lr='ls -ltrh'
fi
```

Fallback garante que máquinas sem eza continuem funcionais.

## Consequências

**Positivas:**
- UX visual mais clara (cores, ícones, git inline)
- Sort flexível (`--sort=modified --reverse` resolve "ver os recentes")
- Single binary, ~5MB
- Memory safety por design (Rust)
- Funciona idêntico em Mac, Linux, WSL

**Negativas:**
- Sintaxe levemente diferente do `ls` clássico (não 100% drop-in)
- Adiciona uma dependência (instalável via brew/apt/cargo)
- Em diretórios muito grandes com git status, marginalmente mais lento que `ls` puro
- Servers minimalistas (Alpine) precisam instalar manualmente

## Alternativas consideradas

- **`ls` puro** — funciona mas UX limitada; `lr='ls -ltrh'` resolve o caso recente
  mas perde cores, git status, ícones.
- **`lsd`** (LSDeluxe) — similar ao eza, escrito em Rust também. Eza tem mais features
  (git status, hyperlinks) e melhor manutenção em 2026.
- **`exa`** (predecessor) — descontinuado em 2021. Eza é o fork ativo.

## Verificação de segurança

Pesquisa em CVE database (CVE.org, NVD, cvedetails.com) em 2026-04 não retornou
nenhum CVE público registrado contra eza. Vetor de ataque é mínimo (lê metadata
de filesystem, sem rede, sem parsing complexo). Risco residual: muito baixo.

## Quando reavaliar

- Se algum CVE relevante for publicado contra eza
- Se trocar de plataforma pra ambiente onde eza não está disponível
- Se equipe/empresa exigir vetting formal de software adicional

## Data
2026-04-26
