# Code Style

Princípios e convenções pra código TypeScript/Node nos projetos do time.

## Princípios gerais

1. **KISS** — Código simples > código clever
2. **Clarity > Cleverness** — Se outro dev vai precisar de 5 minutos pra entender, simplifica
3. **Boring is good** — Evite abstrações exóticas. Padrões conhecidos são features
4. **Single source of truth** — Uma verdade vive em um lugar só
5. **Tipos fortes** — `any` é exceção justificada, não default

## Linting / formatting

`biome` é a fonte da verdade. `pnpm lint` valida, `pnpm lint:fix` corrige.

Não discutimos formatação em PR — biome decide. Se discordar de uma regra,
abre Discussion no repo de team-standards.

## Naming

### Variáveis e funções
- `camelCase` pra variáveis e funções
- Verbo pra função: `getUser`, `validateEmail`, não `userValidation`
- Substantivo pra variável: `userList`, não `getUsers` (a não ser que seja função)
- Boolean: prefixo `is`/`has`/`can`/`should`: `isActive`, `hasPermission`

### Classes e tipos
- `PascalCase` pra classes, types, interfaces, enums
- Sem prefixo `I` em interface: `User`, não `IUser`
- DTOs sufixados: `CreateUserDto`, `UpdateUserDto`

### Constants
- `UPPER_SNAKE_CASE` pra constantes verdadeiras (literais imutáveis)
- `camelCase` pra valores configurados em runtime

```ts
const MAX_RETRY_ATTEMPTS = 3;          // constante real
const config = loadConfig();           // não é constante (carregada em runtime)
```

### Files
- Componentes React: `PascalCase.tsx` → `UserCard.tsx`
- Demais: `kebab-case.ts` → `user-service.ts`, `validate-email.util.ts`
- Sufixos por tipo: `.service.ts`, `.controller.ts`, `.dto.ts`, `.util.ts`, `.spec.ts`

## TypeScript

### Tipos vs interfaces
- **`interface`** pra contratos de objetos que podem ser estendidos (DTOs, services)
- **`type`** pra unions, intersections, mapped types, primitivos compostos

```ts
interface User { id: string; email: string }
type UserRole = 'admin' | 'user' | 'guest';
type UserWithRole = User & { role: UserRole };
```

### Evite `any`
Se realmente precisa de tipo dinâmico, prefira `unknown` e valida:

```ts
// Ruim
function process(data: any) { /* ... */ }

// Bom
function process(data: unknown) {
  if (!isUserPayload(data)) throw new ValidationError();
  // data agora é UserPayload (type guard estreitou)
}
```

### Inferência > anotação
TypeScript já infere tipos óbvios. Não polua:

```ts
// Verboso
const count: number = 0;
const users: User[] = [];

// Limpo (igual seguro)
const count = 0;
const users: User[] = [];   // anotação útil aqui (array vazio sem inferência)
```

Anotação obrigatória em:
- Parâmetros de função (sempre)
- Return type de função pública (services, controllers — força revisão de mudanças)
- Variável onde inferência seria ambígua

### Null vs undefined
- **`undefined`** pra "valor não foi atribuído"
- **`null`** pra "explicitamente vazio"
- Evite ambos quando possível usando default values

```ts
// Bom
function getUser(id: string): User | undefined {
  return users.find(u => u.id === id);
}

// Ruim — qual a diferença entre os dois?
function getUser(id: string): User | null | undefined { /* */ }
```

## Estrutura de funções

### Tamanho
- **20 linhas é alerta**. Maior que isso, considere extrair.
- **50 linhas é problema**. Quase sempre tem responsabilidades misturadas.

### Single responsibility
Função faz uma coisa. Se o nome contém "and", quebra em duas:

```ts
// Ruim
function validateAndSaveUser(data: UserDto) { /* ... */ }

// Bom
function validateUser(data: UserDto): User { /* ... */ }
function saveUser(user: User): Promise<User> { /* ... */ }
```

### Early return
Reduz indentação e complexidade cognitiva:

```ts
// Ruim
function process(user: User) {
  if (user.isActive) {
    if (user.email) {
      if (user.permissions.includes('write')) {
        // ... lógica
      }
    }
  }
}

// Bom
function process(user: User) {
  if (!user.isActive) return;
  if (!user.email) return;
  if (!user.permissions.includes('write')) return;
  // ... lógica
}
```

### Argumentos
- **Máximo 3 argumentos**. Mais que isso, vira object/options:

```ts
// Ruim
function createUser(name, email, age, role, isActive, permissions) { }

// Bom
function createUser(data: CreateUserData) { }
```

## NestJS específico

### Camadas
```
Controller → Service → Repository → Database
```

- **Controller**: parsing de request, validação inicial via DTO + class-validator,
  retorno de response. **Sem lógica de negócio**.
- **Service**: regras de negócio. Stateless. **Sem queries SQL** (delega ao repository).
- **Repository**: acesso a dados. Apenas operações de DB.

### Dependency Injection
- Sempre via construtor com `private readonly`
- Não use `static` em services (impede DI e mock em testes)

```ts
@Injectable()
export class UserService {
  constructor(
    private readonly userRepo: UserRepository,
    private readonly logger: LoggerService,
  ) {}
}
```

### DTOs
- Use `class-validator` + `class-transformer`
- Um DTO por operação: `CreateUserDto`, `UpdateUserDto`, `UserResponseDto`
- Nunca exponha entity do DB direto na response (use mapper)

## Erros

### Nunca esconda erros
```ts
// Ruim
try { doStuff() } catch {}

// Bom (loga + decide)
try { doStuff() }
catch (err) {
  logger.error('doStuff failed', { err });
  throw new ServiceUnavailableError();
}
```

### Custom errors com classe
```ts
export class UserNotFoundError extends Error {
  constructor(id: string) {
    super(`User with id ${id} not found`);
    this.name = 'UserNotFoundError';
  }
}
```

### Validação de input
Sempre na camada de entrada (controller via DTO). Não confie em chamadas internas.

## Comentários

### Quando escrever
- **Por quê**, não **o quê**. O código já mostra o quê.
- Decisões não óbvias (`// usamos N+1 aqui de propósito porque cardinality é baixa`)
- Workarounds (`// hack pra contornar issue #1234 do prisma`)
- TODOs com contexto (`// TODO(CU-xxx): refatorar quando endpoint v2 sair`)

### Quando não escrever
- Comentário que repete o nome da função/variável
- Comentário desatualizado (pior que sem comentário)
- "// função que retorna user" acima de `function getUser()`

## Imports

Ordem (biome organiza automático):
1. Built-in Node (`fs`, `path`)
2. External libs (`@nestjs/common`, `react`)
3. Internal absoluto (`@/services/user.service`)
4. Relativos (`./helper`, `../types`)

Evita import wildcard:
```ts
// Ruim
import * as utils from './utils';

// Bom (nomeado)
import { formatDate, parseDate } from './utils';
```

## Async / Promises

- Sempre `async/await`, não `.then().catch()` (mais legível, melhor stack trace)
- Sempre tratar promise rejeitada (try/catch ou propagação consciente)
- Não use `Promise.all` quando há dependência entre chamadas — usa sequencial

```ts
// Bom (paralelo sem dependência)
const [users, products] = await Promise.all([
  getUsers(),
  getProducts(),
]);

// Bom (sequencial com dependência)
const user = await getUser(id);
const orders = await getOrders(user.id);
```

## Tests

### Estrutura AAA
```ts
it('should create user with valid data', async () => {
  // Arrange
  const dto = { name: 'João', email: 'joao@test.com' };

  // Act
  const result = await service.create(dto);

  // Assert
  expect(result.id).toBeDefined();
  expect(result.email).toBe(dto.email);
});
```

### Test names descritivos
- Em inglês: `should X when Y`
- Em PT: `deve X quando Y`
- Não: `test1`, `users test`, `func works`

### Mocks
- Mocka boundaries (DB, HTTP externo, filesystem)
- NÃO mocka tudo (testes ficam fictícios)
- Use `vi.fn()` (vitest) ou `jest.fn()` consistente
