# Component Output Naming

Never name a component's `output()` / `@Output()` after a native DOM event. Prefer action-describing past-tense or verb-phrase names.

**Banned names** (non-exhaustive): `click`, `copy`, `focus`, `blur`, `input`, `change`, `submit`, `close`, `search`, `scroll`, `load`, `error`.

**Preferred alternatives**: `pressed`, `copyRequest`, `focusIn`, `searchChanged`, `closed`, `valueChange`, `loaded`.

## Why

Two independent problems show up when an output shares a name with a native DOM event, and both hurt:

1. **ESLint rejects it.** `@angular-eslint/no-output-native` fires and the only ways around it are a per-declaration disable comment or a codebase-wide rule disable. Both are ugly, and the suppression propagates visually every time someone reads the component source.

2. **Double-fire at the call site.** When a consumer binds `(click)="..."` to a component that defines an `output<void>` named `click`, Angular fires the component output AND the native click bubbles up through the host element. Two emissions per user click. The component ends up needing `event.stopPropagation()` inside its own handler to absorb the native event, which is a workaround that shouldn't exist.

## The correct way

```typescript
@Component({
    selector: 'app-action-button',
    // ...
})
export class ActionButtonComponent extends BaseComponent {
    readonly pressed = output<MouseEvent>();

    protected onHostClick(event: MouseEvent): void {
        this.pressed.emit(event);
    }
}
```

Consumer:

```html
<app-action-button (pressed)="onAction($event)" />
```

No ESLint suppression. No `stopPropagation`. No double-fire.

## Anti-patterns

```typescript
// BAD — triggers no-output-native; requires stopPropagation inside the handler.
// eslint-disable-next-line @angular-eslint/no-output-native
readonly click = output<MouseEvent>();

protected onHostClick(event: MouseEvent): void {
    event.stopPropagation();  // workaround for native + output double-fire
    this.click.emit(event);
}
```

```typescript
// BAD — `copy` is a native clipboard event; same double-problem.
// eslint-disable-next-line @angular-eslint/no-output-native
readonly copy = output<{ value: string; event: Event }>();
```

## Cross-references

- Linting rules that flag these: [linting.md](linting.md).
- General component conventions: [component.md](component.md).
