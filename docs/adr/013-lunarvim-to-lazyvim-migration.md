# ADR-013: Migração de LunarVim pra LazyVim

## Status
Aceito (substitui ADR-002)

## Contexto

ADR-002 escolheu LunarVim como editor primário em 2023. Decisão foi correta
pra época: out-of-the-box, defaults sane, comunidade boa.

Em abril/2026, situação mudou:

1. **LunarVim em manutenção residual** — última release 1.4.0 foi maio/2024.
   Mantenedor principal anunciou em discussion oficial que migrou para
   AstroNvim e que "no one is actively working on lunarvim".
2. **Mason registry desatualizado** no LunarVim 1.4 — pacotes modernos como
   `vtsls` não estão disponíveis, gerando erro `Cannot find package "vtsls"`.
3. **Locked em Neovim 0.9** — nvim 0.10 e 0.11 trazem features importantes
   (inlay hint API estável, ttrue color improvements, performance) que
   LunarVim 1.4 não aproveita.
4. **Resíduos legados** — referência a `packer_compiled.lua` aponta pra
   migrações antigas mal removidas.

Ferramenta crítica do workflow não pode estar em "manutenção residual" há
quase 2 anos.

## Decisão

Migrar pra **LazyVim**.

## Alternativas consideradas

### LazyVim (escolhida)

**Pra:**
- Mantida ativamente pelo Folke (autor de lazy.nvim, which-key, trouble.nvim,
  tokyonight) — exatamente o ecossistema que LunarVim já usa por baixo
- Menor abstração — config é Lua direto, override de plugins é transparente
- Mason registry sempre atualizado
- Suporte a Neovim mais recente
- Comunidade enorme, atividade alta no GitHub
- Atalhos default são quase idênticos aos do LunarVim que já estão na muscle memory
- Documentação excelente em lazyvim.org

**Contra:**
- Estrutura `lvim.X` não existe; configs precisam ser portadas pro estilo
  LazyVim (override de plugin spec via tabela Lua)
- Curva de aprendizado pra customizações avançadas (felizmente raras)

### AstroNvim

**Pra:** Ativa, polished, dashboard bonito, AstroCommunity packs prontos.

**Contra:** Mais "IDE-chromy" (statusline carregada, abstração via packs);
estilo não combina com perfil minimalista; atalhos diferem mais do LunarVim
que LazyVim.

### kickstart.nvim

**Pra:** Educativo, single-file, controle total.

**Contra:** Não é distro — é template inicial. Antitético ao "out-of-the-box"
que era o motivo original de escolher LunarVim. Custaria horas pra atingir
paridade.

### Continuar no LunarVim

**Pra:** Zero migração.

**Contra:** Aceitar atrasos progressivos; continuar com workarounds (ts_ls em
vez de vtsls); apostar em projeto sem mantenedor ativo.

### Bare Neovim com config próprio

**Pra:** Máximo controle, zero abstração.

**Contra:** Tempo de setup alto demais pra benefício marginal sobre LazyVim.

## Consequências

**Positivas:**
- Editor mantido ativamente, com release cycle previsível
- Acesso a vtsls, biome LSP, e outras ferramentas modernas no Mason
- Neovim 0.10+ destrava inlay hints API estável, snacks.nvim (pelo Folke),
  e melhor suporte a TypeScript
- Comunidade grande pra resolver problemas
- Customização gradual mais transparente (override de plugin direto via Lua)

**Negativas:**
- Pequena curva de adaptação a alguns atalhos diferentes (poucos)
- Custo único de migração (~1-2h pra config equivalente, feita uma vez)
- Plugins customizados precisam ser readicionados via spec do lazy.nvim
  (formato diferente do `lvim.builtin.X`)

**Neutras:**
- Visual padrão é tokyonight (igual o que muitos usam no LunarVim) — sem
  estranhamento estético
- Filosofia "use o que está no ecossistema, customiza só o necessário"
  permanece igual

## Migração

### Setup inicial

Script `macos/migrate-to-lazyvim.sh` faz:

1. Backup de `~/.local/share/lunarvim` (não destrutivo)
2. Adiciona plugin asdf-neovim e instala Neovim 0.11.2 (LazyVim master exige 0.11+)
3. Symlink `~/.config/nvim` → `~/dotfiles/nvim/`
4. Aguarda primeiro `nvim` pra Lazy clonar plugins e Mason instalar LSPs

Tempo total estimado: ~10 min com rede boa.

### Config portada

Estrutura nova em `~/dotfiles/nvim/`:

```
nvim/
├── init.lua                       entrypoint
├── lua/
│   ├── config/
│   │   ├── lazy.lua              setup do lazy.nvim + LazyVim spec
│   │   ├── options.lua           opções nvim
│   │   ├── keymaps.lua           keymaps custom
│   │   └── autocmds.lua          autocmds custom
│   └── plugins/
│       ├── lsp.lua               override LSP (vtsls, inlay hints)
│       ├── extras.lua            lsp_signature, aerial, trouble
│       └── claude.lua            <leader>cc pra Claude Code
```

### Paridade de atalhos

| Atalho                 | LunarVim       | LazyVim          | Status                |
|------------------------|----------------|------------------|-----------------------|
| `<leader>e`            | toggle nvim-tree| toggle Neo-tree | ✓ idêntico            |
| `<leader>E` (custom)   | NvimTreeFindFile| Neotree reveal  | ✓ portado             |
| `<leader>f`            | find files     | find files       | ✓ idêntico            |
| `<leader>F`            | live grep      | live grep (custom) | ✓ portado            |
| `<leader>sb`           | buffers        | (LazyVim usa `<leader>,`) | ⚠️ leve diff |
| `gd / gr / K`          | LSP nav        | idem             | ✓ idêntico            |
| `<C-k>`                | signature help | signature help   | ✓ idêntico            |
| `<leader>uh`           | inlay hints    | inlay hints      | ✓ idêntico            |
| `<leader>xx / xd / xs` | Trouble        | Trouble          | ✓ idêntico            |
| `<leader>o`            | aerial outline | aerial outline   | ✓ idêntico            |
| `<leader>cc`           | Claude Code    | Claude Code      | ✓ portado             |
| `<C-h/j/k/l>`          | window nav     | window nav       | ✓ idêntico            |

Diferenças de defaults LazyVim que valem aprender:
- `<leader>,` lista buffers (em vez de `<leader>sb`)
- `<leader>/` faz live grep (alternativo ao `<leader>F`)
- `<leader>l` é namespace pra Lazy (LunarVim era LSP)
- `<leader>cd` muda CWD pro arquivo atual (útil)

### Rollback plan

Se LazyVim não funcionar bem:

```bash
rm ~/.config/nvim
mv ~/.local/share/lunarvim.backup-<DATE> ~/.local/share/lunarvim
asdf global neovim 0.9.5
```

Volta ao estado anterior em <30 segundos.

## Quando reavaliar

- Se LazyVim entrar em manutenção residual (Folke é prolífico, baixa probabilidade)
- Se algum competidor (AstroNvim, ou novo projeto) ganhar tração e features
  notáveis que LazyVim não tenha
- Se preferências pessoais mudarem (ex: passar a querer máximo controle de
  cada plugin → bare nvim faria mais sentido)

## Data
2026-04-26
