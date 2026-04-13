---
name: activity-tracking
description: Task artifact conventions and activity log format — how to track progress for crash recovery and auditability
alwaysApply: true
---

# Activity Tracking

## Task Directory

For every non-trivial task, use `.agent/<task-name>/` at the project root. Use a short, descriptive kebab-case name (e.g., `.agent/fix-replication-lag/`, `.agent/add-conditional-mutation/`).

**Within a single session, prefer updating over creating.** Before creating a new task directory, check if an existing `.agent/` directory from this session already has a `plan.md` that covers related work. If yes, update the existing plan and append to the existing `activity.md` rather than creating a new directory. Only create a new directory when the task is clearly unrelated to any in-progress work.

## Artifacts

Create these files as needed:

| File | When | Purpose |
|------|------|---------|
| `plan.md` | At task start, before first gate | High-level strategy, success criteria, applicable quality gates |
| `activity.md` | Throughout execution | Append-only log of decisions, gate outcomes, errors |
| `tasks.md` | After design is approved (dev tasks) | Implementable task breakdown with checkboxes |
| `rca.md` | Troubleshooting / RCA tasks | Structured root cause analysis report |
| `reflection.md` | Written by hooks at compaction/session end | Principles learned from mistakes |

For dev tasks requiring design, `spec.md` goes to `docs/design-docs/<module>/<feature>/spec.md` (permanent documentation, not in `.agent/`).

## Activity Log Format

`activity.md` is append-only. Each entry has a timestamp, type, and relevant details:

```markdown
# Task: <task description>
Started: <timestamp>
Status: in-progress | completed | blocked | failed

## Activity

### [timestamp] — Decision
**Decision**: <what was decided>
**Rationale**: <why>

### [timestamp] — Gate: <gate name>
**Status**: Approved | Rejected | N/A
**User feedback**: <any adjustments>

### [timestamp] — Escalation: <reason>
**Question**: <what was asked>
**User decision**: <what the user chose>

### [timestamp] — Error: <error type>
**Error**: <error message>
**Root cause**: <analysis>
**Fix**: <what was done>
```

## What to Log

- Decisions with non-obvious rationale
- Quality gate outcomes and user feedback
- Escalations and user responses
- Errors, their root causes, and fixes
- Phase transitions (starting research, starting implementation, etc.)

Do NOT log routine actions (file reads, grep results, build commands) — only decisions and outcomes that matter for crash recovery and auditability.

## Crash Recovery

When resuming a task ("keep working on task X"):
1. Read `.agent/<task-name>/plan.md` (what should happen) and `activity.md` (what did happen)
2. Read `tasks.md` and/or `spec.md` if they exist
3. Diff plan vs. activity to figure out where to resume
4. Do NOT repeat already-approved quality gates
5. If artifacts are ambiguous, escalate to ask the user

## Starting a New Task

Before creating a new `.agent/` directory:
1. Glob `.agent/*/plan.md` to see what directories already exist
2. If an existing directory covers related work and is still in-progress, update it instead
3. Only create a new directory when the task is clearly distinct from existing work

If `.agent/` has accumulated multiple scattered dirs from topic drift, invoke the `consolidate-agent-dir` skill to reorganize and clean up before starting new work.
