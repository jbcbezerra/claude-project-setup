---
description: Bootstrap .agent-brain/ in the current repo — creates directory scaffold, detects stack, seeds context and patterns from real code.
user_invocable: true
---

# /brain-init

Bootstrap the `.agent-brain/` directory for this repository.

## Steps

### 1. Check for existing brain

```
glob: .agent-brain/**/*
```

If `.agent-brain/` already exists with content, warn the user and ask whether to:
- **Rebuild** — delete and recreate from scratch
- **Fill gaps** — only create missing directories and files
- **Abort**

### 2. Create directory scaffold

Create the full tier structure:

```
.agent-brain/
  REGISTRY.md
  context/
  rules/
  patterns/
  decisions/
  knowledge/
  workflows/
  commands/
  tasks/
  log/
  inbox/
```

### 3. Scale assessment

Before scanning the codebase, assess its size to determine parallelization strategy. See `.claude/reference/scaling-strategy.md` for full details.

```bash
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.kt" -o -name "*.rb" -o -name "*.php" -o -name "*.cs" -o -name "*.vue" -o -name "*.svelte" \) \
  -not -path "*/node_modules/*" -not -path "*/vendor/*" -not -path "*/dist/*" \
  -not -path "*/build/*" -not -path "*/.git/*" -not -path "*/target/*" \
  | wc -l
```

| Source files | Strategy |
|-------------|----------|
| < 200 | Inline — no subagents, do steps 4-7 sequentially |
| 200 — 1,000 | Launch 2 subagents: one for context generation (steps 4-6), one for pattern seeding (step 7) |
| 1,000 — 5,000 | Launch 3 subagents: context generation, architecture analysis, pattern seeding (partition source dirs across 2 pattern miners) |
| 5,000+ | Launch 4-6 subagents: context generation, architecture analysis, and one pattern miner per top-level domain directory (up to 4) |

Each subagent returns structured results. The coordinator (main session) merges them and writes all files.

### 4. Detect project type

Search for project config files to determine language/framework:

| File | Indicates |
|------|-----------|
| `package.json` | Node.js / JavaScript / TypeScript |
| `tsconfig.json` | TypeScript |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `pyproject.toml` / `setup.py` / `requirements.txt` | Python |
| `pom.xml` / `build.gradle` | Java / Kotlin |
| `Gemfile` | Ruby |
| `composer.json` | PHP |
| `*.csproj` / `*.sln` | C# / .NET |
| `Makefile` | Build system |
| `Dockerfile` / `docker-compose.yml` | Containerized |
| `angular.json` | Angular |
| `next.config.*` | Next.js |
| `vite.config.*` | Vite |

Read the detected config files to extract:
- Project name
- Framework and version
- Key dependencies
- Build / test / lint / format commands
- Entry points

### 5. Generate context/setup.md

Write an agent-focused setup guide based on detected config:
- How to install dependencies
- How to run the dev server
- How to run tests (and which test framework)
- How to build for production
- How to lint / format
- Any environment variables needed (from `.env.example`, `docker-compose.yml`, etc.)

### 6. Generate context/stack.md

Write a tech stack overview:
- Language and version
- Framework and version
- Key libraries with one-line purpose
- Build tooling
- Test framework
- Linter / formatter

### 7. Generate context/architecture.md (starter)

Analyze the directory structure to create a starter architecture doc:
- List top-level directories with inferred purpose
- Identify entry points
- Note any obvious patterns (e.g., `src/components/`, `src/services/`, `src/utils/`)
- Mark sections with `<!-- TODO: expand -->` for the user to fill in

**For large repos (Heavy/Massive tier):** If subagents were used for architecture analysis, merge their per-domain findings into a single cohesive architecture doc.

### 8. Seed patterns from real code

Scan the codebase for recurring structural patterns:

1. Pick 2-3 directories that contain multiple files with similar structure (e.g., `src/services/`, `src/components/`)
2. Read 3-5 files from each directory
3. Identify the common skeleton: imports, exports, class/function structure, naming
4. Strip business logic, keep the shape
5. Write each as a `patterns/<type>.md` file

If no clear patterns are found, skip this step and note it in the output.

**For large repos:** Subagents each scan their assigned partition of directories. The coordinator deduplicates overlapping patterns across partitions before writing.

### 9. Populate REGISTRY.md

Create `REGISTRY.md` with entries for all generated files:

```markdown
## Context
- [Architecture](context/architecture.md) — System design, module boundaries
- [Stack](context/stack.md) — Frameworks, versions, key dependencies
- [Setup](context/setup.md) — Install, run, test, deploy

## Rules
<!-- No rules yet — add with /brain-capture or manually -->

## Patterns
<!-- List seeded patterns here -->

## Decisions
<!-- No decisions yet — add with /brain-capture -->

## Knowledge
<!-- No knowledge docs yet -->

## Workflows
<!-- No workflows yet -->

## Commands
<!-- No commands yet -->
```

### 10. Update CLAUDE.md Project table

If CLAUDE.md exists at the repo root, update the Project table with detected values.

### 11. Report

Output a summary:
- Directories created
- Files generated (with one-line descriptions)
- Patterns seeded (if any)
- Scale tier used and number of subagents launched (if any)
- Suggested next steps: "Run `/brain-extract <file>` on your best code to seed more patterns"
