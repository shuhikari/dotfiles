---
description: Atualiza dotfiles na máquina atual (pull + re-aplica symlinks) — cross-OS macOS/WSL/Linux
---

Você vai sincronizar a config local de Claude Code (e demais dotfiles) com a versão canônica em `~/dotfiles`. Esse comando deve funcionar igual em macOS, WSL e Linux.

## Passos

1. **Confirmar com o usuário** antes de qualquer alteração:
   - "Vou rodar `git pull` em `~/dotfiles` e re-aplicar todos os symlinks via `install.sh`. Isso pode sobrescrever arquivos locais que divergiram (eles são salvos em backup). Confirma?"
   - **Só prossiga após "sim" explícito**.

2. Detectar e mostrar o estado atual:
   ```bash
   cd ~/dotfiles
   git status --short
   git log --oneline -5
   ```
   - Se houver mudanças locais não commitadas em `~/dotfiles`, **pare e pergunte ao usuário** o que fazer (commitar primeiro? descartar? guardar em stash?). Não pulle por cima de mudanças sujas.

3. **Pull com cuidado** (nunca destrutivo):
   ```bash
   cd ~/dotfiles && git pull --ff-only
   ```
   - Se o pull falhar (merge necessário, divergência), pare e mostre o erro. **Não force** rebase, reset, ou merge sem pedir.

4. **Aplicar symlinks**:
   ```bash
   cd ~/dotfiles && ./install.sh
   ```
   - Mostre a saída completa pro usuário (arquivos linkados, backups feitos).
   - O `install.sh` é idempotente e faz backup automático em `~/.dotfiles-backup-<timestamp>/`.

5. **Validar** que os arquivos críticos estão como symlink:
   ```bash
   ls -la ~/.claude/CLAUDE.md ~/.claude/commands/ 2>/dev/null
   ```
   - Confirme que `~/.claude/CLAUDE.md` aponta pra `~/dotfiles/claude/CLAUDE.md`.

6. **Resumo final**:
   - Lista o que mudou (compare `HEAD~1..HEAD` no dotfiles)
   - Indica se houve backup feito
   - Lembra: pra mudanças refletirem no Claude Code, recomendar `/clear` na próxima sessão

## Regras de segurança

- Esse comando **NUNCA** executa: `git reset --hard`, `git rebase`, `git clean`, `git checkout .`, `--force`, ou qualquer destrutivo.
- Se houver conflito, divergência ou qualquer estado que peça ação destrutiva pra resolver → **pare e pergunte ao usuário**.
- Se o usuário pediu pra sincronizar mas a máquina não tem dotfiles clonado, oriente como clonar (não tente adivinhar URL).
