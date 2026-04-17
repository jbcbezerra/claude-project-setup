# Day.js Usage — Rules & Conventions

Day.js is the **only** date library in this project. Moment.js has been fully removed. Never add moment, moment-timezone, or moment-duration-format as a dependency.

---

## Plugin Initialization

All Day.js plugins are loaded once in `src/app/core/utils/dayjs-init.ts`, which runs at app startup via `src/main.ts`. **Never** import or call `dayjs.extend()` in individual files.

Currently loaded plugins: `duration`, `utc`, `timezone`, `customParseFormat`, `advancedFormat`, `relativeTime`, `isSameOrBefore`.

## Import

Always import dayjs as a default import:

```typescript
import dayjs from 'dayjs';
```

Never import from plugin paths (`dayjs/plugin/...`) outside of `dayjs-init.ts`.

## Immutability

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

## Public API Contract

Date utility functions must accept `Date | string` and return `Date` or `string`. **No `dayjs.Dayjs` objects in public function signatures.** Day.js is an internal implementation detail.

Exception: Component-internal state may use `dayjs.Dayjs` (e.g., `nj-date-time` calendar model) when the type does not leak through `@Input()` / `@Output()` or service interfaces.

## Core Utilities (`src/app/core/utils/date.ts`)

- `formatDateInTimezone(dateValue, timezone?, format?, isUtc?)` — formats a date in a timezone, returns `string`
- `validateAndConvertDate(datetimeValue, returnDefault, label?, format?)` — validates and converts to `Date`
- `getTimeOffsetForTimezone(timezone?)` — returns offset string like `+02:00`
- Format constants: `DateFormatStringConstant`, `FullDateTimeWithSecondDateFormat`, etc.

Use these instead of writing ad-hoc dayjs formatting logic.

## Timezone Handling

- **Timezone list:** Use `Intl.supportedValuesOf('timeZone')` (browser API). Do not use any library for timezone enumeration.
- **Timezone guessing:** Use `dayjs.tz.guess()`.
- **Timezone conversion:** Use `dayjs.tz(date, timezone)` or `dayjs(date).tz(timezone)`.
- **UTC handling:** Use `dayjs.utc(date)` to parse as UTC, `.utc()` to convert to UTC.
- **'UTC' validation:** Always accept `'UTC'` explicitly in addition to `Intl.supportedValuesOf('timeZone')` results, as some runtimes may not include it.

## Duration Formatting

For simple duration formatting, use `dayjs.duration(value).format(pattern)`. Day.js duration tokens differ from moment-duration-format:

| Meaning   | Day.js | Moment |
|-----------|--------|--------|
| Years     | `Y`    | `y`    |
| Days      | `D`    | `d`    |
| Hours     | `H`    | `h`    |
| Minutes   | `m`    | `m`    |
| Seconds   | `s`    | `s`    |

For complex/humanized duration formatting, use `formatDurationHumanized()` from `date.ts`.

## Type Replacement Reference

| Moment.js             | Day.js equivalent          |
|-----------------------|----------------------------|
| `Moment` type         | `dayjs.Dayjs`              |
| `moment()`            | `dayjs()`                  |
| `moment.utc()`        | `dayjs.utc()`              |
| `moment.tz()`         | `dayjs.tz()`               |
| `moment.duration()`   | `dayjs.duration()`         |
| `moment.isMoment(x)`  | `dayjs.isDayjs(x)`         |
| `moment.tz.guess()`   | `dayjs.tz.guess()`         |
| `moment.tz.names()`   | `Intl.supportedValuesOf('timeZone')` |
| `unitOfTime.DurationConstructor` | `ManipulateType` from `dayjs` |
