# Date Picker Consolidation — Rules

## Single Picker Component

`src/app/shared/components/date-time-picker/` is the **only** date/time picker component. Do not use alternatives.

### Deprecated (do not use in new code)

| Component | Replacement |
|-----------|-------------|
| `nj-date-time` (legacy picker) | `nj-date-time-picker` |
| PrimeNG `p-calendar` | `nj-date-time-picker` with `displayMode="date"` |
| `NjDateTimeModule` | Import `DateTimePicker` standalone component directly |
| `CalendarModule` from `primeng/calendar` | `DateTimePicker` + `OverlayPanelModule` |

### Available Inputs

| Input | Type | Default | Purpose |
|-------|------|---------|---------|
| `value` | `Dayjs` (required) | — | Current date/time value |
| `disabled` | `boolean` | `false` | Disable all interactions |
| `format` | `string` | `FullDateTimeWithSecondDateFormat` | Date format string |
| `minDate` | `Dayjs \| null` | `null` | Minimum selectable date (disables earlier calendar days) |
| `maxDate` | `Dayjs \| null` | `null` | Maximum selectable date (disables later calendar days) |
| `hideSeconds` | `boolean` | `false` | Hide seconds controls in time picker |
| `displayMode` | `'full' \| 'date' \| 'time'` | `'full'` | Show calendar+time, calendar only, or time only |

### Rules

1. **Always wrap in `p-overlayPanel`** when used as a popup picker (matches existing pattern in job-list, error-list, trace-settings, delete-dialog).
2. **Use `displayMode="date"`** for date-only scenarios (replaces p-calendar).
3. **Use `displayMode="time"`** for time-only scenarios.
4. **Use `minDate`/`maxDate`** for cross-constraint date ranges (e.g., "from" picker constrains "to" picker).
5. **Convert `Date` ↔ `Dayjs`** at the component boundary — the picker works with `Dayjs`, parent components may use `Date`.
6. **Never import `CalendarModule`** from PrimeNG for new date picking UI.
