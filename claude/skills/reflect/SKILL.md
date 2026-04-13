---
name: reflect
description: Capture lessons that would make a similar future task faster, more accurate, or less error-prone, and suggest where each lesson should live (rule, skill, or memory) for human approval. Use proactively when you catch yourself making a wrong assumption, get corrected, hit a failure, or notice something non-obvious that would help next time. Don't wait to be told.
---

# Self-Improvement

## Why this exists

The harness's goal is a digital employee who **compounds knowledge over time** — each task should leave the harness slightly better equipped for the next one. Reflections are the capture step; promoting them into rules, skills, and memory is what closes the loop and reduces the amount of human intervention a similar future task needs.

Your job here: notice what would materially change how an agent approaches a *similar* future task, write it down, and suggest where it belongs.

## What to capture

Anything specific to this project, this codebase, this user, or this environment that would measurably reduce exploration, retries, mistakes, or missed details on a similar future task.

Use your judgment about what qualifies — don't work off a fixed checklist. If you can state the lesson in **one line that would materially change future behavior**, and a generic senior engineer arriving fresh to this project would NOT already know it, it's worth capturing.

Skip general software engineering advice. The model already has that.

## Where to write

Append to `.agent/<task-name>/reflection.md`.

## Format

Each entry:

```markdown
### [YYYY-MM-DD] <one-line lesson, phrased as guidance>
**Context**: <what happened or why this matters — 1-2 lines>
**Suggested promotion**: <rule | skill | memory> — <rationale; name the target file, or "new file: <name>" if none fits>
```

The three promotion targets:

- **rule** — always-on behavioral guardrail (`claude/rules/*.md`). Use for behaviors that should apply to every task.
- **skill** — on-demand knowledge or procedure (`claude/skills/<name>/SKILL.md`). Use for domain knowledge or workflow recipes loaded when needed.
- **memory** — persistent per-project fact or user preference (`~/.claude/projects/<repo>/memory/*.md`). Use for facts about this project or this user.

Promotion itself is **human-approved** — you suggest, the user confirms and moves the content into the target file. Never create rules or skills autonomously.

## Examples

```markdown
### [2026-04-17] When editing storage/tdstore/rocksdb/, always verify `is_tdstore_cf` guards first
**Context**: Added a change to SST iteration that regressed vanilla RocksDB behavior because the guard was missing. Build passed; MTR caught it.
**Suggested promotion**: rule — extend `rules/std-rocksdb-modification.md`
```

```markdown
### [2026-04-17] In TDSQL, "RG" (replication group) and "region" are distinct concepts — not interchangeable
**Context**: Assumed they were the same while reading tdstore_client output; led to a wrong hypothesis during RCA. Codex caught it.
**Suggested promotion**: memory — new file `memory/project_tdsql_vocabulary.md`
```

```markdown
### [2026-04-17] For MC scheduling questions, start at tdsql/mc/server/scheduler.cc — not the handlers
**Context**: Spent 20 min in handlers before finding the scheduling loop; the scheduler is the entry point for most scheduling bugs.
**Suggested promotion**: skill — extend navigation section of `skills/std-mc-module/SKILL.md`
```

```markdown
### [2026-04-17] User wants terse responses — no trailing "here's what I did" summaries, they read the diff
**Context**: User corrected me twice for adding closing summaries in the same session.
**Suggested promotion**: memory — check if `feedback_*.md` already covers this before creating a new file
```

## What NOT to write

- General software engineering knowledge the model already has ("always null-check")
- One-off typos or trivial mistakes without a pattern
- Implementation details — reflection captures principles and knowledge, not code
- Anything you can't state in one line that would change future behavior
