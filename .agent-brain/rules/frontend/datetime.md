# Datetime — Rules & Conventions

Rules for date/time handling on the frontend. Day.js is the one and only date library — no alternatives.

---

## Day.js Usage

### Plugin Initialization

All Day.js plugins are loaded once in a central file, typically `src/app/core/utils/dayjs-init.ts`, imported as a side-effect from `src/main.ts` **before** `bootstrapApplication(...)`. **Never** import a plugin or call `dayjs.extend()` in individual files.

When a new feature needs a plugin that isn't yet loaded:
1. Add the `import` + `dayjs.extend(...)` line to `dayjs-init.ts`.
2. Use the dayjs API from that plugin anywhere else in the app without re-extending.

Skeleton:

```typescript
// src/app/core/utils/dayjs-init.ts
import dayjs from 'dayjs';
import duration from 'dayjs/plugin/duration';
import relativeTime from 'dayjs/plugin/relativeTime';
import utc from 'dayjs/plugin/utc';
import timezone from 'dayjs/plugin/timezone';

dayjs.extend(duration);
dayjs.extend(relativeTime);
dayjs.extend(utc);
dayjs.extend(timezone);
```

```typescript
// src/main.ts
import './app/core/utils/dayjs-init'; // side-effect import — must come before bootstrapApplication
import { bootstrapApplication } from '@angular/platform-browser';
// ...
```

#### Vitest gotcha — plugins are not loaded in tests by default

`main.ts` never runs under Vitest, so the plugin side-effects in `dayjs-init.ts` are never applied. Any spec that transitively exercises `dayjs.duration(...)`, `dayjs.utc(...)`, `dayjs().tz(...)`, etc. will fail with `default.duration is not a function` (or the equivalent for the missing plugin).

Fix: add a side-effect import at the top of the spec file (or a shared test-setup helper):

```typescript
import '<relative-path>/core/utils/dayjs-init';
```

This is load-bearing even if the spec never imports `dayjs` itself — as long as the *code under test* reaches a plugin method, the init file must be evaluated first.

### Import

Always import dayjs as a default import:

```typescript
import dayjs from 'dayjs';
```

Never import from plugin paths (`dayjs/plugin/...`) outside of `dayjs-init.ts`.

### Immutability

Day.js objects are **immutable**. Every method that modifies the date (`.add()`, `.subtract()`, `.startOf()`, `.endOf()`, `.set()`, `.utc()`, `.local()`, `.tz()`) returns a **new** instance. You must reassign:

```typescript
// Correct
let date = dayjs();
date = date.add(1, 'day');
date = date.startOf('hour');

// Wrong — original is unchanged
const date = dayjs();
date.add(1, 'day'); // return value discarded
```

Inline chaining is fine when the result is consumed immediately:

```typescript
return dayjs().add(1, 'day').format('YYYY-MM-DD');
```

### Public API Contract

Day.js is the standard date type throughout the application. Utility functions, services, and domain models should accept and return `dayjs.Dayjs` objects. Raw `Date` or `string` values should be converted to `dayjs.Dayjs` at the boundary (e.g., in DTO mappers) and stay as `dayjs.Dayjs` from that point.

```typescript
// ✅ Good — dayjs.Dayjs throughout
export const subtractFromNow = (amount: number, unit: dayjs.ManipulateType): dayjs.Dayjs =>
  dayjs().subtract(amount, unit);

// ✅ Good — mapper converts string → dayjs at the boundary
export const toAuditEntry = (dto: AuditEntryDto): AuditEntry => ({
  timestamp: dayjs(dto.timestamp),
});

// ❌ Bad — converting back to Date or string unnecessarily
export const subtractFromNow = (amount: number, unit: string): Date =>
  dayjs().subtract(amount, unit).toDate();
```

### Timezone Handling

- **Timezone list:** Use `Intl.supportedValuesOf('timeZone')` (browser API). Do not use any library for timezone enumeration.
- **Timezone guessing:** Use `dayjs.tz.guess()`.
- **Timezone conversion:** Use `dayjs.tz(date, timezone)` or `dayjs(date).tz(timezone)`.
- **UTC handling:** Use `dayjs.utc(date)` to parse as UTC, `.utc()` to convert to UTC.
- **'UTC' validation:** Always accept `'UTC'` explicitly in addition to `Intl.supportedValuesOf('timeZone')` results, as some runtimes may not include it.

### Duration Formatting

For simple duration formatting, use `dayjs.duration(value).format(pattern)`. Day.js duration tokens:

| Meaning | Token |
|---------|-------|
| Years   | `Y`   |
| Days    | `D`   |
| Hours   | `H`   |
| Minutes | `m`   |
| Seconds | `s`   |

## Anti-patterns

- ❌ Installing `moment`, `moment-timezone`, `moment-duration-format`, `date-fns`, `luxon`, or any other date library — Day.js only.
- ❌ Calling `dayjs.extend(...)` outside `dayjs-init.ts`.
- ❌ Importing from `dayjs/plugin/...` outside `dayjs-init.ts`.
- ❌ Treating Day.js objects as mutable (`date.add(1, 'day')` without reassignment).
- ❌ Converting `dayjs.Dayjs` back to `Date` or `string` for internal passing — keep it as `dayjs.Dayjs` until final display formatting.
- ❌ Using a third-party library for timezone enumeration — stick with `Intl.supportedValuesOf('timeZone')`.
