# Scaling Strategy

Shared reference for how skills and agents decide whether to use subagents and how many.

## Scale Assessment

Before doing any scan-heavy work, run this assessment:

```bash
# Count source files (excluding generated/vendored dirs)
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.kt" -o -name "*.rb" -o -name "*.php" -o -name "*.cs" -o -name "*.vue" -o -name "*.svelte" \) \
  -not -path "*/node_modules/*" \
  -not -path "*/vendor/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" \
  -not -path "*/.git/*" \
  -not -path "*/target/*" \
  -not -path "*/__pycache__/*" \
  -not -path "*/venv/*" \
  | wc -l

# Count top-level source directories
ls -d src/*/ app/*/ lib/*/ packages/*/ 2>/dev/null | head -20
```

## Scaling Tiers

| Tier | Source files | Subagents | Strategy |
|------|-------------|-----------|----------|
| **Inline** | < 200 | 0 | Do everything in the main session. No subagents needed. |
| **Light** | 200 — 1,000 | 2-3 | Split by concern (e.g., one agent scans rules, another scans patterns). |
| **Heavy** | 1,000 — 5,000 | 3-5 | Split by directory partition. Each subagent owns a slice of the codebase. |
| **Massive** | 5,000+ | 5-8 | Split by top-level domain directory. Each subagent is scoped to one domain. Coordinator merges results. |

## Partitioning Strategies

### By concern (Light tier)
Each subagent handles a different *type* of work on the full codebase:
- Agent A: scan for rule violations
- Agent B: check pattern drift
- Agent C: audit decisions

Best when: the codebase is moderate-sized but the brain has many rules/patterns to check.

### By directory (Heavy tier)
Split the source tree into N roughly equal slices:
1. List top-level source directories
2. Estimate file count per directory
3. Group directories into N balanced partitions
4. Each subagent scans its partition for everything (rules, patterns, etc.)

Best when: the codebase is large and the work per-file is uniform.

### By domain (Massive tier)
Each subagent owns one top-level domain directory entirely:
- Agent A: `src/auth/` (850 files)
- Agent B: `src/payments/` (720 files)
- Agent C: `src/inventory/` (600 files)
- etc.

Best when: the repo is a monolith or monorepo with clear domain boundaries.

## Coordination Pattern

When using subagents:

1. **Coordinator** (main session) runs the scale assessment
2. **Coordinator** determines tier and partitioning strategy
3. **Coordinator** launches subagents in parallel with scoped instructions:
   - Each subagent receives: its partition (directory list or concern), the brain files to check against, and output format
   - Each subagent writes its results to a temp section in the output (or returns via agent result)
4. **Coordinator** merges results, deduplicates, and writes the final output

## Subagent Prompt Template

When spawning subagents, include:

```
You are a scoped subagent for [skill/agent name].
Your partition: [directory list or concern scope]
Brain files to check: [list of relevant .agent-brain/ files]

Do NOT:
- Read files outside your partition (except .agent-brain/ reference files)
- Write to .agent-brain/ (the coordinator handles writes)
- Create git commits

DO:
- Scan your partition thoroughly
- Return structured results in this format:
  [specify output format]
- Note confidence levels for each finding
```

## When NOT to parallelize

- The task is write-heavy (creating files, updating registry) — serialize to avoid conflicts
- The brain itself is small (< 5 rules, < 3 patterns) — overhead isn't worth it
- The user asked for a specific file or small scope — just do it inline
