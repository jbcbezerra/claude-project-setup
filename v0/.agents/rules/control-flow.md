# Control Flow Syntax Rules

## Use built-in control flow (not structural directives)

All templates must use Angular's built-in control flow syntax. Do **not** use structural directives for control flow.

| Legacy (banned) | Modern (required) |
|---|---|
| `*ngIf="cond"` | `@if (cond) { ... }` |
| `*ngIf="cond; else elseRef"` | `@if (cond) { ... } @else { ... }` |
| `*ngFor="let x of xs"` | `@for (x of xs; track ...) { ... }` |
| `*ngSwitch` / `*ngSwitchCase` | `@switch (expr) { @case (val) { ... } }` |

## @for track expressions

Every `@for` block **must** include a meaningful `track` expression:

- Use `track item.id` (or another unique field like `name`, `key`) when iterating objects with identity.
- Use `track kv.key` when iterating `| keyvalue` pipe output.
- Use `track $index` **only** for primitive arrays (strings, numbers) or when items genuinely lack a unique identifier.
- Never leave the schematic default `track item` without reviewing it.

## CommonModule cleanup

After migrating to built-in control flow, `NgIf`, `NgFor`, and `NgSwitch` imports are no longer needed:

- Remove standalone `NgIf`, `NgFor`, `NgSwitch` imports from component `imports` arrays.
- Replace `CommonModule` with only the specific directives/pipes still in use (`NgClass`, `NgStyle`, `KeyValuePipe`, `DatePipe`, `DecimalPipe`, `AsyncPipe`, etc.).
- Remove `CommonModule` entirely if no Common features remain in the template.

## Component schematics defaults

`angular.json` is configured so `ng generate component` produces standalone, OnPush, SCSS, skip-tests components by default. Do not override these unless explicitly required.
