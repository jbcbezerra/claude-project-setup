# Logger

Supporting pattern for [BaseComponent](base-component.md) and [BaseService](base-service.md). Provides a level-filtered, session-persistent logger that both base classes inject.

The skeleton below is a full reference implementation — drop it in, or substitute any logger that exposes `debug`/`info`/`warn`/`error` methods with the same signatures.

---

## Skeleton

### `src/app/core/logging/log-level.enum.ts`

```typescript
export enum LogLevel {
    DEBUG = 'DEBUG',
    INFO = 'INFO',
    WARN = 'WARN',
    ERROR = 'ERROR',
    OFF = 'OFF',
}
```

### `src/app/core/logging/logger-settings.type.ts`

```typescript
import { LogLevel } from './log-level.enum';

export type LoggerSettings = {
    logLevel: LogLevel;
    shouldLogHttp: boolean;
};
```

### `src/app/core/logging/logger.ts`

```typescript
import { Injectable, isDevMode } from '@angular/core';
import { LoggerSettings } from './logger-settings.type';
import { LogLevel } from './log-level.enum';

const LOGGER_SETTINGS_STORAGE_KEY = 'app-logger-settings';

/**
 * Level-filtered logger with session-persisted settings.
 * Defaults to DEBUG in dev mode and ERROR in production.
 */
@Injectable({
    providedIn: 'root',
})
export class Logger {
    private loggerSettings: LoggerSettings;

    constructor() {
        const loadedSettings = this.loadLoggerSettings();
        this.loggerSettings = loadedSettings ?? {
            logLevel: isDevMode() ? LogLevel.DEBUG : LogLevel.ERROR,
            shouldLogHttp: false,
        };
        this.saveLoggerSettings();
    }

    get shouldLogHttp(): boolean {
        return this.loggerSettings.shouldLogHttp;
    }

    // ── Configuration ────────────────────────────────

    setLoggerSettings(settings: Partial<LoggerSettings>) {
        this.loggerSettings = { ...this.loggerSettings, ...settings };
        this.saveLoggerSettings();
    }

    resetLoggerSettings() {
        sessionStorage.removeItem(LOGGER_SETTINGS_STORAGE_KEY);
        this.loggerSettings = {
            logLevel: isDevMode() ? LogLevel.DEBUG : LogLevel.ERROR,
            shouldLogHttp: false,
        };
    }

    // ── Logging ──────────────────────────────────────

    debug(message: unknown, ...optionalParams: unknown[]): void {
        if (this.shouldLog(LogLevel.DEBUG)) {
            console.debug('[DEBUG]', message, ...optionalParams);
        }
    }

    info(message: unknown, ...optionalParams: unknown[]): void {
        if (this.shouldLog(LogLevel.INFO)) {
            console.info('[INFO]', message, ...optionalParams);
        }
    }

    warn(message: unknown, ...optionalParams: unknown[]): void {
        if (this.shouldLog(LogLevel.WARN)) {
            console.warn('[WARN]', message, ...optionalParams);
        }
    }

    error(message: unknown, ...optionalParams: unknown[]): void {
        if (this.shouldLog(LogLevel.ERROR)) {
            console.error('[ERROR]', message, ...optionalParams);
        }
    }

    // ── Internal ─────────────────────────────────────

    private shouldLog(level: LogLevel): boolean {
        if (this.loggerSettings.logLevel === LogLevel.OFF) return false;
        const logLevels = [LogLevel.DEBUG, LogLevel.INFO, LogLevel.WARN, LogLevel.ERROR];
        return logLevels.indexOf(level) >= logLevels.indexOf(this.loggerSettings.logLevel);
    }

    private isValidLogLevel(value: string): value is LogLevel {
        return Object.values(LogLevel).includes(value as LogLevel);
    }

    private loadLoggerSettings(): LoggerSettings | null {
        try {
            const raw = sessionStorage.getItem(LOGGER_SETTINGS_STORAGE_KEY);
            if (!raw) return null;

            const parsed = JSON.parse(raw);
            if (this.isValidLogLevel(parsed.logLevel)) {
                return {
                    logLevel: parsed.logLevel,
                    shouldLogHttp: typeof parsed.shouldLogHttp === 'boolean' ? parsed.shouldLogHttp : false,
                };
            }
            return null;
        } catch (e) {
            console.warn('[Logger] Failed to load logger settings from sessionStorage:', e);
            return null;
        }
    }

    private saveLoggerSettings(): void {
        try {
            sessionStorage.setItem(LOGGER_SETTINGS_STORAGE_KEY, JSON.stringify(this.loggerSettings));
        } catch (e) {
            console.warn('[Logger] Failed to save logger settings to sessionStorage:', e);
        }
    }
}
```

---

## When to use

- Adopt once, at project bootstrap, alongside [BaseComponent](base-component.md) and [BaseService](base-service.md).
- Every component, service, and store resolves `Logger` via `inject(Logger)` — directly, or indirectly through the base classes.

---

## What it gives you

- **Level filtering.** `DEBUG` / `INFO` / `WARN` / `ERROR` / `OFF`, ordered by severity. Messages below the configured level are dropped at the call site — no console noise in production.
- **Environment-aware default.** Dev mode starts at `DEBUG`, production starts at `ERROR`. Neither requires reading `environment.ts` in each caller.
- **Session persistence.** Settings live in `sessionStorage` so toggling the log level in devtools survives page reloads within the tab.
- **HTTP log toggle.** `shouldLogHttp` flag consumed by an HTTP interceptor to turn request/response logging on and off without code changes.

---

## Variations

### Without session persistence

If you don't want `sessionStorage` coupling (e.g. SSR-heavy app, or multi-tab consistency matters), drop `loadLoggerSettings` / `saveLoggerSettings` and keep the in-memory defaults:

```typescript
constructor() {
    this.loggerSettings = {
        logLevel: isDevMode() ? LogLevel.DEBUG : LogLevel.ERROR,
        shouldLogHttp: false,
    };
}
```

### External log target

Replace the `console.*` calls with your own sink (Sentry, Datadog, in-memory ring buffer for test support). Keep the signatures identical so every caller — including `BaseComponent`/`BaseService` — continues to work unchanged.

### Prefix per caller

If you often want `[ClassName]` prefixes in every log line without each call spelling them out, use the *scoped log prefix* variation shown in [base-service.md](base-service.md) — the wrapper lives on the base class, not here.
