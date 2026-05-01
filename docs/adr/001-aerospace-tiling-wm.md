# ADR-001: AeroSpace como tiling window manager

## Status
Aceito

## Contexto

Workflow de desenvolvimento envolvia uso intensivo de Magnet pra gestão de janelas
e mouse pra arrastar entre Spaces do macOS. Dois pontos de fricção:

1. Não havia tiling automático keyboard-first — Magnet faz snap manual via atalhos,
   mas não rearranja janelas conforme abre/fecha.
2. Em apresentações, janelas frequentemente caem na tela errada (laptop em vez do
   projetor) porque os Spaces nativos do macOS não têm binding determinístico
   por monitor.

Avaliamos também ir além e adotar Linux com Hyprland (Omarchy), mas inviável no
M1 Pro como daily driver — Asahi Linux ainda parcial em M1 Pro, e abandonar
o ecossistema Mac pra ganhar tiling não vale a pena.

## Decisão

Adotar [AeroSpace](https://github.com/nikitabobko/AeroSpace) como tiling window
manager exclusivo no macOS. Substitui Magnet completamente.

Configuração foca em:
- Workspaces nomeados por intenção (T=Terminal, C=Code, B=Browser, M=Messages, P=Presentation)
- Workspace P fixado no monitor secundário via `workspace-to-monitor-force-assignment`
- Modifier `cmd-ctrl` em vez do default `option` (option colide com pt-BR para acentos)
- Sem dependência de SIP desabilitado

## Consequências

**Positivas:**
- Fluxo keyboard-first real, organização por intenção
- Janelas de apresentação sempre vão pro projetor (P sempre vive em `secondary`)
- Sem custos recorrentes (Magnet é pago)
- Config versionada em `aerospace.toml`

**Negativas:**
- Mission Control e gestos nativos de Spaces ficam inúteis
- Curva de aprendizado de ~1 semana antes de virar muscle memory
- Apps em fullscreen nativo do macOS conflitam (resolvemos usando `fullscreen` do
  AeroSpace em vez do nativo)

## Alternativas consideradas

- **yabai** — mais poderoso mas exige desabilitar SIP; risco de manutenção em updates do macOS.
- **Rectangle** — só snap manual, equivalente ao Magnet em essência.
- **OmniWM** — interessante mas projeto novo, sem track record.
- **Hyprland (Omarchy) em Asahi Linux** — descartado pelo M1 Pro ter suporte parcial
  e ser daily driver de produção.

## Quando reavaliar

- Se yabai voltar a funcionar sem desabilitar SIP em alguma versão futura do macOS
- Se OmniWM amadurecer (1 ano+ de track record)
- Se trocar de hardware pra Mac com macOS posterior que mude semântica de Spaces

## Data
2026-04-26
