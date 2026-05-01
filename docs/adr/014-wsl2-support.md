# ADR-014: Suporte a WSL2 nos dotfiles

## Status
Aceito (refina ADR-010)

## Contexto

ADR-010 estabeleceu cross-platform strategy com Windows nativo (sem WSL) sendo
o caminho principal pro time. A realidade evoluiu: alguns devs do time
adotaram WSL2 voluntariamente porque preferem o ergonomia Linux/Unix mas
mantêm Windows como host (corporate-friendly, gaming, software exclusivo).

WSL2 é Ubuntu/Debian de verdade rodando em VM leve dentro do Windows. Diferente
do Git Bash (que é "shell-like" sobre Windows), WSL é Linux nativo — todos os
nossos scripts shell, ferramentas Unix, e configs zsh/tmux/nvim funcionam
sem modificação.

A pergunta: nossos dotfiles devem suportar WSL2 oficialmente?

## Decisão

Sim. Adicionar suporte oficial a WSL2 via:

1. **Detecção de OS no zshrc** — módulo `os-detect.zsh` carregado primeiro,
   exporta `$DOTFILES_OS` (`macos`/`wsl`/`linux`) e helpers `is_macos`/`is_wsl`/`is_linux`
2. **`exports.zsh` cross-OS** — paths e env vars condicionais por OS, fallback gracioso
3. **`aliases.zsh` com clipboard cross-OS** — `clip`/`paste` aliases que mapeiam
   pra `pbcopy`/`clip.exe`/`xclip` automaticamente
4. **`wsl/setup.sh` automatizado** — instala Ubuntu deps (zsh, asdf, node 20,
   neovim 0.11.2, eza, gh, starship, claude code) num único comando idempotente
5. **`install.sh` consciente de OS** — symlinks específicos só onde fazem
   sentido (ex: aerospace.toml só em macOS)
6. **`wsl/README.md`** — guia específico de WSL: pré-reqs Windows, performance
   (`~/` vs `/mnt/c/`), integração WSL↔Windows, equivalência de ferramentas

## Consequências

**Positivas:**
- Time tem 3 caminhos viáveis e bem suportados: macOS, WSL2, Windows nativo
- WSL2 herda automaticamente toda a paridade de ferramentas (Neovim, tmux,
  team-standards, scripts) — zero retrabalho
- Menos fricção pra dev que migra entre máquinas (mesma config funciona)
- Onboarding novo dev WSL: 1 comando (`bash wsl/setup.sh`) → 8-15min → ambiente completo
- Detecção de OS abre porta pra suportar Linux puro no futuro (já tá lá)

**Negativas:**
- Mais código/complexidade nos dotfiles (condicionais if/else no zsh)
- Mais 2 arquivos pra manter atualizados (`os-detect.zsh`, `wsl/setup.sh`)
- Risco de divergência sutil de comportamento entre OS (mitigado por testes
  manuais quando muda algo)

## Alternativas consideradas

### Continuar só macOS-first (status quo)
**Pra:** menos código, foco.
**Contra:** devs WSL ficam órfãos; perdem o investimento em padrões compartilhados.

### Suportar WSL via fork/branch separado
**Pra:** zero condicional no código main.
**Contra:** custo de manter dois branches em sincronia é alto e tende a deriva.

### Forçar todos pra WSL ou todos pra Windows nativo
**Pra:** simplicidade.
**Contra:** corporate IT decide isso, não o time. WSL pode ser bloqueado em
algumas empresas; obrigar adoção é fricção desnecessária.

### Container devcontainer compartilhado
**Pra:** ambiente 100% idêntico.
**Contra:** custo (Codespaces é caro), complexidade (dev offline?), latência.
Reavaliar futuramente quando time crescer.

## Trade-offs explicitados

**Performance:** WSL2 é fast pra disco interno (`~/`) mas 10x mais lento pra
disco Windows (`/mnt/c/`). Documentação reforça: clonar repos em `~/ws/`,
nunca em `/mnt/c/`. Quem ignorar terá experiência ruim e culpará os dotfiles.

**`/sandbox` do Claude Code:** WSL **funciona** com `/sandbox` (diferente do
Windows nativo). Vantagem real do WSL pra quem quer essa feature.

**GUI apps em WSL:** WSLg (vem ativo no Windows 11) suporta apps GUI Linux
nativamente, mas não usamos isso ativamente. Mantemos foco em CLI.

## Quando reavaliar

- Se Microsoft mudar significativamente a arquitetura WSL (improvável a curto prazo)
- Se time padronizar 100% pra um OS (não acontece em time corporate)
- Se aparecer diferença de comportamento entre OS que cause bug recorrente
  (aí avaliar se compensa simplificar pra um OS-first)

## Data
2026-04-26
