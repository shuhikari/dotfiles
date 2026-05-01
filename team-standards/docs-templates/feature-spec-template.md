# Feature Spec: {Título da Feature}

> **Task**: [CU-xxxxxxxx](https://app.clickup.com/t/xxxxxxxx)
> **Status**: 🟡 Draft / 🔵 In Review / 🟢 Approved / 🔴 Rejected / 🟣 Implemented
> **Author**: @username
> **Reviewers**: @reviewer1 @reviewer2
> **Created**: YYYY-MM-DD
> **Updated**: YYYY-MM-DD

## Sumário

<!-- 2-3 frases. Se não der pra resumir nesse espaço, a feature está grande demais. -->

## Contexto

### Problema
<!-- Que dor estamos resolvendo? Quem sente? Como sabemos que existe? -->
<!-- Dados, métricas, citações de feedback de usuário ajudam aqui. -->

### Por que agora
<!-- Por que esta é a hora certa? O que mudou ou está mudando? -->

### Não-objetivos (escopo)
<!-- O que essa feature NÃO faz. Importante pra cortar scope creep. -->

-
-

## Solução proposta

### Visão geral
<!-- Descrição em prosa do que vai ser construído. -->

### Fluxo de usuário
<!-- Passo a passo de como o usuário vai interagir. Pode ser bullets ou diagrama. -->

1.
2.
3.

### Diagrama (se ajudar)

```
[Componente A] ──HTTP──> [Componente B]
                              │
                              ▼
                         [Database]
```

## Design técnico

### Arquitetura
<!-- Componentes envolvidos, novos vs existentes. -->

### Modelo de dados
<!-- Mudanças no schema. SQL ou prisma schema preferred. -->

```prisma
model NewEntity {
  id        String   @id @default(uuid())
  createdAt DateTime @default(now())
}
```

### API / contratos
<!-- Endpoints novos ou modificados. Inputs e outputs. -->

```
POST /api/feature
Body: { ... }
Response: 201 { ... }
Errors: 400 ValidationError, 401 Unauthorized
```

### Configuração
<!-- Env vars novas, feature flags, configs runtime. -->

| Var | Descrição | Default |
|---|---|---|
| `FEATURE_X_ENABLED` | Toggle da feature | `false` |

## Edge cases e validações

<!-- Lista o que pode dar errado e como tratar. -->

- O que acontece se input vier vazio?
- E se o usuário tentar duas vezes em sequência?
- Concorrência, race conditions?
- Rollback em caso de falha parcial?

## Segurança

<!-- Considerações OWASP relevantes pra esta feature. -->

- Authentication/authorization: quem pode chamar o endpoint?
- Validação de input: que campos vêm de usuário e precisam sanitização?
- Dados sensíveis: o que precisa logging mascarado?
- Rate limiting necessário?

## Performance

<!-- Estimativas e limites. -->

- **Esperado**: N requests/segundo, M usuários simultâneos
- **Limite aceitável**: P99 latência < 500ms
- **Pontos de atenção**: query N+1 potencial em XYZ — vamos usar `include` do Prisma

## Observabilidade

<!-- Como vamos saber que está funcionando em produção? -->

- **Métricas**: contador de chamadas, latência, taxa de erro
- **Logs**: o que registrar (sem PII)
- **Alertas**: condições que disparam página

## Testes

### Unit
- [ ] Cenário feliz
- [ ] Validação de input vazio/inválido
- [ ] Erro do downstream

### Integration / E2E
- [ ] Fluxo completo do endpoint
- [ ] Auth/authz funcionando

### Manual
- [ ] Smoke test em staging antes de produção

## Rollout

### Estratégia
- [ ] Feature flag inicial em `false`
- [ ] Deploy em staging, validação manual
- [ ] Habilita em produção pra subset (10%)
- [ ] Monitorar 24h
- [ ] Habilitar 100%

### Rollback plan
<!-- Se algo der errado, como reverter? -->
- Desligar feature flag (rollback instantâneo)
- Migrations reversíveis: `pnpm prisma migrate reset` + apply até versão X

## Alternativas consideradas

<!-- O que mais foi avaliado e por que descartado. Demonstra rigor. -->

### Alternativa A
- Como funcionaria
- Por que descartado

### Alternativa B
- Como funcionaria
- Por que descartado

## Dependências

<!-- O que precisa estar pronto antes desta feature ir pra produção. -->

- [ ] Feature X (CU-xxxxxxx)
- [ ] Migration Y aplicada em prod
- [ ] Aprovação Z

## Estimativa

| Fase | Esforço |
|---|---|
| Design (essa spec) | __h |
| Implementação | __h |
| Testes | __h |
| Documentação | __h |
| **Total** | __h |

## Open questions

<!-- O que ainda não está decidido. Lista pra forçar resolução antes de implementar. -->

- [ ] Pergunta 1
- [ ] Pergunta 2

---

## Histórico de revisões

| Data | Autor | Mudança |
|---|---|---|
| YYYY-MM-DD | @user | Versão inicial |
