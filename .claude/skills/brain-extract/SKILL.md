---
description: "Mine a reusable code pattern from existing source files. Usage: /brain-extract <file-or-glob>"
user_invocable: true
args: target
---

# /brain-extract

Extract a reusable pattern template from one or more source files and save it to `.agent-brain/patterns/`.

## Input

The user provides a file path or glob pattern pointing to exemplar code:

```
/brain-extract src/services/user.service.ts
/brain-extract src/components/Button.tsx
/brain-extract "src/api/*.py"
/brain-extract src/handlers/order_handler.go
```

## Steps

### 1. Resolve targets

Expand the file path or glob to concrete files.
- If a single file → use it as the exemplar.
- If a glob matching multiple files → read up to 5 files to identify the common structure.
- If no files match → report the error and stop.

### 2. Scale assessment

If the glob resolves to many files, decide on parallelization:

| Matched files | Strategy |
|--------------|----------|
| 1-5 | Inline — read and analyze sequentially |
| 6-15 | Launch 2 subagents, each analyzing half the files. Coordinator merges the structural fingerprints. |
| 16-40 | Launch 3 subagents, each analyzing a third. Coordinator finds the intersection. |
| 40+ | Launch 4-5 subagents. Sample up to 8 files per subagent from their partition. Coordinator merges. |

Each subagent returns a structured fingerprint:
```
imports: [categories]
declarations: [shapes]
di_pattern: <description>
public_api: [method signatures]
lifecycle: [hooks]
error_handling: <pattern>
naming: <convention>
```

The coordinator finds the common intersection across all subagent results.

### 3. Analyze structure

Read the target file(s) and identify the structural skeleton:

- **Imports / dependencies** — what categories of imports are used (stdlib, framework, internal)
- **Declarations** — class, function, module, struct shape
- **Dependency injection / initialization** — how dependencies are wired
- **Public API** — exported functions, methods, endpoints
- **Lifecycle** — setup, teardown, hooks, middleware
- **Error handling** — pattern used (try/catch, Result type, error middleware)
- **Naming conventions** — file name, class/function name, variable naming
- **File location** — where in the directory tree this type of file lives

When analyzing multiple files (whether inline or via subagents):
- Find the **intersection** — what structure is common to all
- Note **variations** — where files diverge, document as named variants

### 4. Generalize

Strip all business logic. Keep only the structural shape:
- Replace specific names with descriptive placeholders (`<EntityName>`, `<endpoint-path>`)
- Replace specific types with category comments (`// your data type here`)
- Keep framework boilerplate intact (decorators, annotations, trait impls)
- Keep import patterns but genericize paths
- Preserve comments that explain *structural* choices, remove comments about business logic

### 5. Determine pattern name

Derive a clear, descriptive name:
- From the *type* of code, not the *specific* code: "API Service" not "UserService"
- Use the naming convention of the project: if files are `*.service.ts`, the pattern is "Service"
- Check existing patterns in `REGISTRY.md` to avoid duplicates or naming conflicts

### 6. Write pattern file

Create `.agent-brain/patterns/<name>.md`:

```markdown
# <Pattern Name>

Use this skeleton when creating a new <what this pattern is for>.

## Template

\```<language>
<the generalized skeleton>
\```

## When to use
- <trigger condition — what kind of task calls for this pattern>
- <file location — where this type of file lives in the project>

## Naming
- File: `<naming convention>` (e.g., `<name>.service.ts`)
- Class/function: `<naming convention>` (e.g., `<Name>Service`)

## Variations

### <Variation Name>
<When this variation applies and how the skeleton differs>
\```<language>
<variation diff or full alternative>
\```

## Derived from
- `<original file path(s) used as exemplars>`
```

### 7. Update REGISTRY.md

Add entry under `## Patterns`:
```
- [<Pattern Name>](patterns/<name>.md) — <one-line description>
```

### 8. Report

Output:
- Pattern name and file path
- Source file(s) it was derived from
- Key structural elements captured
- Any variations noted
- Number of subagents used (if any)
- Suggestion: "Review the generated pattern and adjust placeholders as needed"
