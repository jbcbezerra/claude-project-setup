# DTOs, Mappers & Domain Models

How we name, shape, and locate the three data types that flow between the backend and the UI: **DTO** (wire format, owned by the API layer), **Model** (domain representation, owned by the component), **Mapper** (DTO → Model, colocated with the model).

---

## Folder & File Layout (target)

DTOs and API services live together in the API layer. Domain models and mappers live together in the component's / domain's `models/` folder. The two layers are linked by one direction of import: **mappers import DTOs, API services expose them via `get<JobDto[]>(...)`.**

```
src/app/core/services/api/<domain>/
├── {domain}-api.ts                 # API service — see api-services.md
└── {domain}-dto.ts                 # Wire format (DTOs + request types)
    # Sub-folders allowed for complex domains (e.g. usermanagement/privileges/)

src/app/domain/<domain>/pages/<page>/{component}/
├── {component}.ts
├── {component}.html
├── {component}.scss
└── models/
    ├── index.ts                    # Barrel — exports types consumed outside this component
    ├── {component}-models.ts       # Domain types (internal representation)
    └── {component}-mapper.ts       # Pure DTO → Model functions
```

Key splits:

- See [file-organization.md](file-organization.md).
- **DTO belongs to the API**, not the component. Multiple components may consume the same DTO via their own mappers.
- **Model and Mapper belong to the component** that shapes the DTO into its presentation view.
- Domain types live in `models/`.
- A component without a mapper (or with only one or two trivial types) should skip `models/` entirely and keep types inline.

---

## DTOs (Data Transfer Objects)

DTOs represent the exact shape of data on the wire (API request/response bodies). They are owned by the API layer, not by any single component.

- **Location:** `src/app/core/services/api/<domain>/{domain}-dto.ts`.
- **Paired with:** `{domain}-api.ts` in the same folder.
- **Date/time fields:** `string` with a `// utc datetimestring` comment.
- **Optional fields:** `?:` (optional modifier).
- **Internal nested types:** keep in the same file, not exported.
- **Naming:** suffix the type with `Dto` (e.g. `JobDto`, not `Job`).

```typescript
// src/app/core/services/api/job/job-dto.ts

export type JobDto = {
  id: string;
  jobKeyName: string;
  lastExecutionTime?: string; // utc datetimestring
  status?: 'STARTED' | 'STOPPED' | 'BROKEN';
  jobKey: JobKey;
};

// Internal type (not exported)
type JobKey = {
  name: string;
  group: string;
};
```

### Request DTOs

For POST/PUT bodies, create separate request types **in the same DTO file**:

```typescript
export type JobCreateRequest = {
  name: string;
  schedule: string;
  enabled: boolean;
};
```

### Cross-component sharing

When several components need the same wire type, they all import from the one DTO file next to the API — no duplication, no per-component copy of the type. If multiple DTOs cluster around one domain, split them into sub-folders (e.g. `core/services/api/job/scheduling/`, `core/services/api/job/execution/`), keeping each DTO alongside the service that returns it.

---

## Domain Models

Domain models represent the internal application view of an entity — properly typed, nulls made explicit, derived fields pre-computed.

- **Location:** `models/{domain/component}-models.ts` inside the component's folder.
- **Date/time fields:** `dayjs.Dayjs | null`.
- **Optional fields:** `| null` (explicit null union — **not** `?:`).
- **May include** computed/derived properties not present in the DTO.
- **Export union types separately** when reused (e.g. `JobStatus`).
- **Re-export from `models/index.ts`** when the type is consumed outside the component's folder.
- **Naming:** no suffix (e.g. `Job`, not `JobModel`).

```typescript
// src/app/domain/administration/job/job-list/models/job-list-models.ts

import dayjs from 'dayjs';

export type JobStatus = 'STARTED' | 'STOPPED' | 'BROKEN' | 'PAUSED' | 'BLOCKED';

export type Job = {
  id: string;
  status: JobStatus | null;
  lastExecutionTime: dayjs.Dayjs | null;
  lastExecutionDurationDisplay: string; // computed during mapping
};
```

---

## DTO vs Domain Model — summary

| Aspect            | DTO                                                | Domain Model                             |
|-------------------|----------------------------------------------------|------------------------------------------|
| Location          | `core/services/api/<domain>/{domain}-dto.ts`       | `models/{domain/component}-models.ts`    |
| Owner             | The API service                                    | The component that consumes the data     |
| Purpose           | API request/response shape                         | Internal representation                  |
| Date/time fields  | `string` with `// utc datetimestring`              | `dayjs.Dayjs \| null`                    |
| Optional fields   | `?:`                                               | `\| null`                                |
| Can include       | Only API fields                                    | API fields + computed/derived properties |
| Type name suffix  | `Dto` (e.g. `JobDto`)                              | No suffix (e.g. `Job`)                   |

---

## Extension

Use intersection (`&`) instead of `extends`:

```typescript
type ExtendedComponentState = ComponentState & {
  shortname?: string;
  newState?: boolean;
};
```

---

## Mappers

Mapper functions convert DTOs to domain models. They live with the model in the component's `models/` folder — they encode component-specific reshaping and derived properties, so they belong to the consumer, not to the API layer.

### Location & naming

- **File:** `models/{component}-mapper.ts`.
- **Single item:** `to{Model}` (e.g. `toJob`, `toUser`).
- **List:** `to{Model}List` (e.g. `toJobList`) — always delegates to the single mapper.

```typescript
// ❌ Bad naming
export const mapJob = (dto: JobDto): Job => { ... };
export const convert = (dto: JobDto): Job => { ... };
```

### Rules

1. **Pure functions** — no side effects, no logging, no I/O.
2. **Handle null/undefined** — convert DTO `undefined` / optional fields to `null` via `?? null`.
3. **Compute derived properties** during mapping, never in templates.
4. **Use `dayjs`** for date parsing (see [datetime.md](datetime.md)).
5. **Extract reusable parsing logic** into helpers or utility functions if multiple mappers use the same (e.g. `parseUtcDate`).

### Skeleton

```typescript
// src/app/domain/administration/job/job-list/models/job-list-mapper.ts

import dayjs from 'dayjs';
import { formatDurationHumanized } from '../../../../core/utils/date';
import { JobDto } from '../../../../core/services/api/job/job-dto';
import { Job } from './job-list-models';

const parseUtcDate = (dateString: string | undefined): dayjs.Dayjs | null => {
  if (!dateString) return null;
  const parsed = dayjs.utc(dateString);
  return parsed.isValid() ? parsed : null;
};

export const toJob = (dto: JobDto): Job => ({
  id: dto.id,
  jobKeyName: dto.jobKeyName,
  status: dto.status ?? null,
  lastExecutionTime: parseUtcDate(dto.lastExecutionTime),
  nextExecutionTime: parseUtcDate(dto.nextExecutionTime),
  lastExecutionDuration: dto.lastExecutionDuration ?? null,
  amount: dto.amount,
  timeUnit: dto.timeUnit ?? null,
  interruptable: dto.interruptable,

  // Derived property — computed here, not in the template
  lastExecutionDurationDisplay: formatDurationHumanized(dto.lastExecutionDuration),
});

export const toJobList = (dtos: JobDto[]): Job[] =>
  dtos.map(dto => toJob(dto));
```

### Common patterns

```typescript
// Nested object mapping
const toAddress = (dto: AddressDto): Address => ({
  street: dto.street,
  city: dto.city,
});

export const toUser = (dto: UserDto): User => ({
  id: dto.id,
  name: dto.name,
  address: dto.address ? toAddress(dto.address) : null,
});

// Array of nested objects
export const toUser = (dto: UserDto): User => ({
  id: dto.id,
  permissions: dto.permissions?.map(p => toPermission(p)) ?? [],
});
```

### Where mapping happens

The API service returns **`Observable<Dto>`** — it does not apply the mapper. The **store/state** applies the mapper when it receives the API response. This keeps the API layer free of domain-specific reshaping while centralizing the DTO → Model conversion in the state layer, where it belongs.

```typescript
// In the store (e.g. FooStore.loadData()):
import { toFooList } from '../models/foo-mapper';

this.fooApi.getFoos().pipe(
  finalize(() => this._loading.set(false)),
).subscribe({
  next: dtos => this._foos.set(toFooList(dtos ?? [])),
  error: () => this._error.set('Failed to load foos'),
});
```

### Testing

```typescript
import '<relative-path>/core/utils/dayjs-init'; // plugins must be loaded — see datetime.md

describe('job-mapper', () => {
  const createJobDto = (overrides: Partial<JobDto> = {}): JobDto => ({
    id: 'job-123',
    // ... defaults
    ...overrides,
  });

  it('should map a complete DTO', () => {
    const result = toJob(createJobDto());
    expect(result.id).toBe('job-123');
  });

  it('should handle missing optional fields', () => {
    const result = toJob(createJobDto({ status: undefined }));
    expect(result.status).toBeNull();
  });
});
```

---

## Barrel exports (`models/index.ts`)

The `models/` folder is the one place where a barrel `index.ts` is expected — per [file-organization.md](file-organization.md). Re-export types and mappers the outside world consumes; leave internal types unexported. **DTOs do not appear here** — they're imported directly from `core/services/api/<domain>/`.

```typescript
// models/index.ts
export type { Job, JobStatus } from './job-list-models';
export { toJob, toJobList } from './job-list-mapper';
```

---

## Type Organization

**Extract and export types when:**
- Used in multiple files (shared union types like `JobStatus`, `JobGroup`).
- Part of the public API of the module.

**Keep types inline when:**
- Only used within the same file (nested types in DTOs).
- Internal implementation details.

---

## Anti-patterns

```typescript
// ❌ DTO file inside the component's `models/` folder
//    — DTOs belong in core/services/api/<domain>/

// ❌ DTO duplicated across components that consume the same endpoint
//    — one DTO file next to the API service, imported by all consumers

// ❌ Pure data shape defined as an interface
interface UserDto {
  name: string;
  email: string;
}

// ❌ `| null` in DTOs — wire format uses optional (`?:`)
type JobDto = {
  status: 'STARTED' | 'STOPPED' | null;
};

// ❌ `?:` in domain models — make nullability explicit with `| null`
type Job = {
  status?: JobStatus;
};

// ❌ Storing dates as `string` in domain models — use `dayjs.Dayjs | null`
type Job = {
  lastExecutionTime: string | null;
};

// ❌ Mapper in `core/services/api/<domain>/` — mappers belong with the model in `models/`
// ❌ Mapper applied inside the API service — the store applies the mapper
// ❌ Mapper applied in a component — mapping belongs in the store, not in templates or component code
// ❌ Domain model name ending in `Dto` (or DTO name missing the `Dto` suffix)
// ❌ Barrel `index.ts` re-exporting DTOs — DTOs aren't in models/, they're in core/services/api/<domain>/
// ❌ Barrel `index.ts` outside `models/` — other folders prefer explicit imports
```
