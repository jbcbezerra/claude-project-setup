# Post-Migration Workflow

Run this workflow after completing a large migration or refactor (e.g., swapping a framework, replacing a library, restructuring directories).

## When to use

- After replacing a dependency (e.g., Moment.js -> Day.js, REST -> GraphQL)
- After a major refactor (e.g., class components -> functional, modules -> standalone)
- After restructuring directories or renaming modules
- After upgrading a framework to a new major version

## Steps

### 1. Refresh context

Run `/brain-refresh` to detect all changes to dependencies, commands, and project structure. Review and approve the proposed updates.

### 2. Extract new patterns

Identify 2-3 exemplar files that demonstrate the new approach. Run `/brain-extract` on each:

```
/brain-extract <path-to-exemplar-1>
/brain-extract <path-to-exemplar-2>
```

Review the generated patterns and adjust placeholders as needed.

### 3. Archive old patterns

Check `patterns/` for templates that reference the old approach:
- If the old pattern is fully replaced → delete the pattern file
- If the old pattern is partially replaced (migration in progress) → add a deprecation notice at the top:
  ```
  > **DEPRECATED**: This pattern is being replaced by [New Pattern](new-pattern.md). Use the new pattern for all new code.
  ```

### 4. Create ADR

Document the migration decision in `.agent-brain/decisions/ADR-YYYYMMDD-<migration-topic>.md`:
- What was migrated from and to
- Why the migration was done
- What trade-offs were accepted
- Any remaining cleanup work

### 5. Update or retire rules

Check `rules/` for constraints that reference the old approach:
- Update rules to reflect the new conventions
- Remove rules that are no longer applicable
- Add new rules for the new approach if needed

### 6. Verify migration completeness

Use `superpowers:verification-before-completion` to ensure all migration claims are backed by evidence:
- Run test suites and confirm all pass
- Verify build succeeds with no warnings related to old approach
- Check that no runtime errors occur in migrated code paths

### 7. Audit for remnants

Run the `brain-audit` agent to verify:
- No imports of the old library remain
- No code follows the old pattern where it should follow the new one
- ADRs are consistent with the current state

```
Use the brain-audit agent to scan for violations
```

### 8. Update REGISTRY.md

Ensure all new, modified, and deleted files are reflected in the registry.

## Done when

- Context files reflect the post-migration state
- New patterns exist for the new approach
- Old patterns are archived or deleted
- An ADR documents the decision
- Audit shows no remaining old-pattern violations (or known exceptions are documented)
