# Datetime Centralization — Rules

## Utility Layer (Phase 1)

All datetime logic must use the centralized utilities in `src/app/core/utils/`:

| File                 | Purpose                                                                       |
| -------------------- | ----------------------------------------------------------------------------- |
| `date-constants.ts`  | All format strings + duration constants (MS_PER_SECOND, etc.)                 |
| `date-parse.ts`      | Parsing & validation (parseUtcDate, isValidDate, toDate, etc.)                |
| `date-format.ts`     | Formatting pure functions (formatInTimezone, formatChartTooltip, etc.)        |
| `date-compare.ts`    | Comparison & time-window utilities (isDateInPast, getTimeWindowStatus, etc.)  |
| `date-arithmetic.ts` | Date math (adjustTimeRange, getDefaultTimeRange, getUnixTimestamp)            |
| `duration.ts`        | Duration conversion & formatting (msToSeconds, formatDurationHumanized, etc.) |
| `date.ts`            | Barrel re-export — backward-compatible, imports from all above files          |

### Rules

1. **Never use magic numbers** for time division/multiplication. Use `MS_PER_SECOND`, `MS_PER_MINUTE`, `MS_PER_HOUR`, `MS_PER_DAY` from `date-constants.ts` or the conversion functions from `duration.ts`.
2. **Never hardcode format strings** — use the constants from `date-constants.ts`.
3. **Never duplicate `parseUtcDate()`** — import from `date-parse.ts`.
4. **Import from focused files** for new code (e.g., `import { msToSeconds } from '@core/utils/duration'`). Importing from `date.ts` barrel is also acceptable.

## TimezoneService (Phase 2)

`src/app/core/services/timezone/timezone.service.ts` is the **single source of truth** for user timezone.

### Rules

1. **Never use `.local()`** for UTC-to-display conversion. Always use `TimezoneService.toUserTimezone()` or `TimezoneService.formatUtcToLocal()`.
2. **Never access `propertyMap.timezone` directly** — use `TimezoneService.userTimezone()` signal.
3. **Never access `propertyMap` timezone offset directly** — use `TimezoneService.userTimezoneOffset()`.
4. For new components that display dates, prefer `TimezoneService.formatUtcToLocal()` with format presets ('complete', 'date', 'time') or custom format strings.

## Pipes & Directives (Phase 3)

### Active pipes (use these)

| Pipe           | Usage                                                                         | Source                     |
| -------------- | ----------------------------------------------------------------------------- | -------------------------- |
| `njUtcToLocal` | `{{ utcDate \| njUtcToLocal }}` or `{{ utcDate \| njUtcToLocal:'date' }}`     | Uses TimezoneService       |
| `njDuration`   | `{{ ms \| njDuration }}` (humanized) or `{{ iso \| njDuration:'breakdown' }}` | Uses duration.ts utilities |
| `njFromNow`    | `{{ date \| njFromNow }}`                                                     | Uses formatRelativeTime()  |

### Deprecated (do not use in new code)

| Item                       | Status                                | Replacement                                       |
| -------------------------- | ------------------------------------- | ------------------------------------------------- |
| `njDurationHumanize` pipe  | Deprecated (still has consumers)      | `njDuration` pipe (default behavior is humanized) |
| `UtcToLocal` service class | Deprecated (still has consumers)      | `TimezoneService`                                 |
| `nj-date-time` component   | Deprecated (still declared in module) | `date-time-picker` component                      |

### Removed in Phase 8 (2026-04-04)

| Item                                                                | Replacement                                                            |
| ------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| `njUtcOffsetFormatter` pipe (`shared/pipes/utc-offset-formatter/`)  | `TimezoneService.userTimezoneOffset()` or `getTimeOffsetForTimezone()` |
| `formatTimestamp` directive (`shared/directives/format-timestamp/`) | `TimezoneService.formatUtcToLocal()` or `njUtcToLocal` pipe            |
| `UtcOffsetFormatter` class (`shared/pipes/utc-offset-formatter/`)   | `getTimeOffsetForTimezone()` from `date.ts`                            |
| `MonthInYear` constant (`core/utils/date.ts`)                       | `getMonthsInYear()` from `date.ts`                                     |

## Chart Tooltips (Phase 4)

`src/app/argos/dashboard/utils/chart-tooltip.ts` provides shared tooltip factories for Highcharts metric charts.

### Rules

1. **Never write inline tooltip formatters** in metric files. Use `createChartTooltip()` or `createDualAxisChartTooltip()`.
2. **Never import dayjs in metric files** — the tooltip utility handles date formatting internally.
3. Pre-built formatters: `percentageFormatter`, `bytesFormatter`, `countFormatter`, `decimalFormatter`, `msFormatter`.
4. For custom value formats, pass an inline function: `createChartTooltip((p) => \`${p.point.y} custom\`)`
5. For dual-axis charts: `createDualAxisChartTooltip(primaryFormatter, oppositeFormatter)` where primary = left axis (opposite=false), opposite = right axis (opposite=true).
