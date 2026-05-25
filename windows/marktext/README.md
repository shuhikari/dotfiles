# MarkText — integração com Windows Explorer

[MarkText](https://github.com/marktext/marktext) é um leitor/editor de markdown WYSIWYG, gratuito e open-source — equivalente Windows para quem usa Typora/Marked no macOS.

Esta pasta adiciona dois pontos de integração:

- **Menu de contexto do Windows Explorer**: "Abrir com MarkText" em qualquer pasta.
- **Função `mark` no zsh** (em `zsh/functions.zsh`): abre arquivo/pasta no MarkText direto do terminal WSL.

## Pré-requisito

MarkText instalado. Caminho default do installer per-user:

```
C:\Users\<seu-usuário>\AppData\Local\Programs\MarkText\MarkText.exe
```

Download: <https://github.com/marktext/marktext/releases>

## Aplicação automática (WSL)

```bash
bash ~/dotfiles/windows/marktext/apply.sh
```

O script:
- Detecta seu usuário do Windows via `cmd.exe`.
- Gera o `.reg` final substituindo o placeholder.
- Importa em `HKEY_CURRENT_USER` via `reg.exe` (sem prompt de UAC).

Para remover:

```bash
bash ~/dotfiles/windows/marktext/apply.sh --uninstall
```

## Aplicação manual (Windows puro, sem WSL)

1. Abra `install.reg.template` num editor.
2. Substitua `__WIN_USER__` pelo seu username do Windows (ex: `shuhi`).
3. Salve como `install.reg`.
4. Duplo-clique no `install.reg` no File Explorer, confirme o aviso.
5. Para remover: duplo-clique em `uninstall.reg`.

## O que adiciona

Duas entradas, ambas em `HKEY_CURRENT_USER\Software\Classes\`:

| Onde aparece | Texto | Comando |
|---|---|---|
| Clique direito **sobre** uma pasta | "Abrir com MarkText" | `MarkText.exe "%1"` |
| Clique direito no **fundo** de uma pasta | "Abrir esta pasta com MarkText" | `MarkText.exe "%V"` |

> No Windows 11, essas entradas ficam atrás de "Mostrar mais opções" no menu novo. Segura `Shift` ao clicar direito pra abrir o menu clássico direto, ou ative o menu clássico globalmente via [Winaero Tweaker / regedit](https://www.howtogeek.com/762903/how-to-get-the-old-context-menu-back-in-windows-11/).

## Companheiro WSL — função `mark`

Definida em `zsh/functions.zsh`, gated por `is_wsl`:

```bash
mark              # abre a pasta atual no MarkText
mark README.md    # abre arquivo específico
mark sagu-api     # abre subpasta
```

Converte o caminho com `wslpath -w` e dispara o `MarkText.exe` do Windows em background.

## Por que `HKEY_CURRENT_USER`?

Modificar `HKEY_CLASSES_ROOT` requer admin e afeta todos os usuários da máquina. Usar `HKCU\Software\Classes\` é a forma moderna recomendada pelo Windows pra extensões de menu de contexto per-user — sem prompt de UAC, fácil de reverter.
