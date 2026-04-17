# Query Date Service — Rules

## Single Service for Query Dates

`src/app/core/services/query-date/query-date.service.ts` (`QueryDateService`) is the **single source of truth** for all query-related date logic.

### What it consolidates

| Previous Source | Methods Moved |
|----------------|---------------|
| `QueryService` (date methods) | `getQueryFrom()`, `getQueryTo()`, `getDateBasedOnModifier()`, `getTimezoneOffset()` |
| `TimeRangeCalculatorService` | `getFromModifier()`, `getSelectedEntry()`, `updateStorage()` |
| `QueryTimepickerEntriesService` | `setEntry()`, `getCurrentEntry()`, `enable()`, `disable()`, `isDisabled()`, `setCustom()`, `updateEntryFromRouter()` |

### Deprecated (do not use in new code)

| Service | Replacement |
|---------|-------------|
| `TimeRangeCalculatorService` | `QueryDateService` (same methods) |
| `QueryTimepickerEntriesService` | `QueryDateService` (same methods) |
| `QueryService.getUnstableFrom()` | `QueryDateService.getQueryFrom()` (clearer name) |
| `QueryService.getUnstableTo()` | `QueryDateService.getQueryTo()` (clearer name) |
| `QueryService.getDateBasedOnModifier()` | `QueryDateService.getDateBasedOnModifier()` |
| `UtcOffsetFormatter` utility | `QueryDateService.getTimezoneOffset()` or `TimezoneService.userTimezoneOffset()` |

### Rules

1. **New code must use `QueryDateService`** — never import `TimeRangeCalculatorService` or `QueryTimepickerEntriesService` directly.
2. **Use `formatForSearchRequest(date)`** to format dates for API calls instead of manually calling `.format(DateFormatStringConstant)`.
3. **Use `getTimezoneOffset()`** from QueryDateService (backed by TimezoneService) instead of accessing `propertyMap.timezone` or using `UtcOffsetFormatter`.
4. **The `QueryService` delegation methods** (`getUnstableFrom`, `getUnstableTo`, `getDateBasedOnModifier`) exist only for backward compatibility. Prefer `QueryDateService` directly.
