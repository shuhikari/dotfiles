# ADR-012: Blog técnico para documentação pública

## Status
Proposto (depende ADR-011 ou alternativa de hospedagem)

## Contexto

Mudanças de processo (review pré-PR, repositório com spec antes de codar,
biome+knip, conventional commits) têm baixa adesão se simplesmente impostas.
Adesão alta vem com **contexto + razão + exemplo prático**.

Documentação interna (Notion, Confluence) tem dois problemas:
1. Vive em silo — quem sai da empresa perde acesso, quem entra demora pra encontrar
2. Esforço de escrever bem é alto e o leitor é um (a empresa); ROI baixo de polish

Conteúdo técnico público:
- Força clareza no pensamento (escrever pra estranho ≠ escrever pra colega)
- Vira recurso permanente referenciável (link no Slack/Discord vs explicar de novo)
- Constrói reputação técnica externa (útil pra contratação reversa)
- Permite que time mostre pra outras áreas/clientes "como pensamos"

## Decisão (proposta)

Lançar blog técnico como repositório público, hospedado no overseer Oracle
(ADR-011) ou Cloudflare Pages.

### Stack proposto
- **Astro** + **MDX** — site estático, performance excelente, suporte a
  componentes React/Vue se precisar
- **Tailwind** + **Catppuccin** ou similar pra estética consistente com terminal
- **Shiki** ou **Astro Code** pra syntax highlighting com themes terminal
- **Atom feed** + **RSS** pra distribuição
- **Comentários via giscus** (GitHub Discussions, sem dependência de Disqus)

### Estrutura inicial de conteúdo

```
posts/
├── 2026/
│   ├── 04-dotfiles-modular-setup.md          (visão geral do projeto)
│   ├── 04-aerospace-tiling-no-mac.md         (porque tiling pra dev)
│   ├── 05-claude-code-cli-workflow.md        (como uso, sem hype)
│   ├── 05-pre-pr-review-pipeline.md          (biome+knip+claude review)
│   ├── 05-tmux-sessoes-persistentes.md       (workflow ssh sobrevivente)
│   ├── 06-spec-before-code.md                (templates de feature spec)
│   └── 06-overseer-oracle-free-tier.md       (esse server)
├── adr-publicas/                             (ADRs traduzidas pro público)
└── about.md
```

### Princípios editoriais

1. **Valor antes de hype** — se um post não ensina algo prático, não publica
2. **Mostrar, não dizer** — code samples reais, não "considere o seguinte código..."
3. **Trade-offs, não doutrinação** — toda decisão tem custo, expor isso vira
   credibilidade
4. **PT-BR primário, EN opcional** — público alvo é Brasil; tradução
   selecionada se algum post tracionar
5. **Vincular dotfiles e team-standards** — cada post linka pro código que ele
   discute, vivem juntos

### Cadência

- Mínimo: 1 post/mês
- Não forçar — qualidade > volume
- Cada decisão grande do dotfiles ou team-standards vira post (ADR pública)

## Consequências

**Positivas:**
- Adesão do time maior porque eles veem o "porquê" antes de receberem o "o quê"
- Recurso público referenciável (Slack/Discord/email)
- Documentação que escreve uma vez, consulta sempre
- Portfolio público crescendo organicamente
- Externa decisões para validação ampla (commenters podem apontar erros)

**Negativas:**
- Esforço de escrita inicial (1-2h por post bem feito)
- Risco de cair em armadilha de "só blogo, não trabalho"
- Manutenção de domínio + hospedagem (mas Oracle Free + Cloudflare = ~zero)
- Exposição: erros públicos, pessoas vão criticar (parte do jogo)

## Alternativas consideradas

- **dev.to / Hashnode / Medium** — mais simples mas perde controle (paywalls,
  algoritmos, layout). Podem servir como crossposting se o post merecer alcance maior.
- **Notion público** — feio em comparação, sem comentários adequados, lock-in
- **Vídeos no YouTube** — esforço muito maior, áudio em PT-BR limita público técnico
- **Apenas docs internas** — não resolve adesão do time nem cria recurso permanente

## Quando reavaliar

- Se 6 meses depois nenhum post foi escrito → projeto morto, abandonar honestamente
- Se métricas (views, engagement) mostrarem zero retorno após 1 ano sustentado
- Se a empresa vetar (improvável dado que é conteúdo técnico, não confidencial)

## Data
2026-04-26
