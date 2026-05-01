/**
 * commitlint.config.mjs
 *
 * Conventional Commits: https://www.conventionalcommits.org
 *
 * Formato:
 *   <type>(<scope>): <subject>
 *
 *   <body opcional>
 *
 *   <footer opcional>
 *
 * Exemplos válidos:
 *   feat(auth): adiciona login via Google
 *   fix(api): corrige timeout em endpoint /users
 *   chore(deps): atualiza dependências
 *   docs(readme): adiciona seção de setup
 *   refactor(service): extrai validação pra util
 *
 * Tipos aceitos (override em rules abaixo):
 *   feat     — nova funcionalidade
 *   fix      — correção de bug
 *   docs     — só documentação
 *   style    — formatação (espaços, vírgulas, sem mudança de lógica)
 *   refactor — refactor sem mudança de comportamento
 *   perf     — melhoria de performance
 *   test     — adicionar/corrigir testes
 *   build    — build system, dependencies (npm, docker, etc)
 *   ci       — CI/CD configs
 *   chore    — manutenção, sem mudança de código produção
 *   revert   — reverte commit anterior
 *   wip      — work in progress (nunca chega a main)
 */

export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',
        'fix',
        'docs',
        'style',
        'refactor',
        'perf',
        'test',
        'build',
        'ci',
        'chore',
        'revert',
        'wip',
      ],
    ],
    'subject-case': [2, 'never', ['upper-case', 'pascal-case', 'start-case']],
    'subject-empty': [2, 'never'],
    'subject-full-stop': [2, 'never', '.'],
    'header-max-length': [2, 'always', 100],
    'body-leading-blank': [1, 'always'],
    'footer-leading-blank': [1, 'always'],
  },
};
