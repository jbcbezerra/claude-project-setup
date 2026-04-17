# Error Handling Refactoring Tasks

Comprehensive refactoring plan for error handling across the njams-frontend codebase. Tasks are numbered by recommended execution order, grouped into phases by dependency.

## Execution Phases

### Phase 1 — Foundation (observe before you improve)
| Task | Description | Effort |
|------|-------------|--------|
| [01](01-centralized-logging.md) | Centralized Logging — Eliminate direct console.* calls | ~87 files |
| [04](04-eliminate-silent-catches.md) | Eliminate Silent Catch Blocks + `safeJsonParse` utility | ~34 silent catches, 25 JSON.parse |

### Phase 2 — Standardize patterns, catch the gaps
| Task | Description | Effort |
|------|-------------|--------|
| [02](02-rxjs-error-operators.md) | Standardize RxJS Error Handling Operators | ~27 files |
| [03](03-global-error-handler.md) | Add Global Angular ErrorHandler | 2 new files, 1 modified |

### Phase 3 — UX consistency + code clarity
| Task | Description | Effort |
|------|-------------|--------|
| [05](05-unified-form-validation-display.md) | Unify Form Validation Error Display | ~30 templates |
| [08](08-interceptor-refactor.md) | Refactor HTTP Error Interceptor to Strategy Pattern | 7 new files, 1 refactored |

### Phase 4 — Legacy cleanup
| Task | Description | Effort |
|------|-------------|--------|
| [06](06-websocket-consolidation.md) | Consolidate WebSocket Error Handling | ~10 files, delete 4-5 |
| [07](07-template-to-reactive-forms.md) | Migrate Template-Driven Forms to Reactive Forms | ~8 components |

### Phase 5 — Capitalize on the above
| Task | Description | Effort |
|------|-------------|--------|
| [09](09-external-monitoring.md) | Add External Error Monitoring (Sentry) | 3 new files, 4 modified |

## Dependency Graph

```
01 ──> 03 ──> 09
 │      │
 └──> 04    08 ──> 09
             │
02          05
             │
        07 ──┘
06 (independent)
```

## Reference

- Full audit: [ERROR_HANDLING_AUDIT.md](../../../ERROR_HANDLING_AUDIT.md)
