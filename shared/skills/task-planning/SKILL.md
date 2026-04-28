---
name: task-planning
description: Breaks a spec.md into an implementable task list (tasks.md) with dependencies, context, and acceptance criteria. Invoke after the design is approved at Gate: Solution Design, before starting implementation.
---

# Task Planning

## Prerequisite

spec.md must be complete (sections 1-7 filled or marked N/A) and approved at Gate: Solution Design. If not, invoke `system-design` first.

## Core Principle

Each task is a work unit for the implementer subagent. Since the implementer starts with a fresh context, the task must include everything it needs: what to change, what files to read for context (upstream callers + downstream consumers), and how to verify it's done.

## Workflow

1. Read spec.md fully — identify all design decisions and deliverables
2. Use researcher subagent to investigate: which files/functions need to change, who calls them, who consumes their output
3. Break into tasks using the template in `assets/tasks-template.md`, write to `.agent/<task-name>/tasks.md`
4. Verify: dependency DAG has no cycles, every spec section maps to at least one task

## Key Principles

**Build → Migrate → Delete**: When replacing existing code, always create the new implementation first, then migrate callers, then remove the old code. Never delete before the replacement is ready — every intermediate state must compile.

**Each task must compile**: After completing any single task, the codebase must compile. Use stubs for not-yet-implemented functions if needed.

**Context is critical**: Each task's `context` field lists the files and functions the implementer needs to read to understand the task. Include not just the files being modified, but upstream callers (who passes data in) and downstream consumers (who uses the output). Be specific — function-level, not just file-level.

**Flag parallelism**: After building the dependency DAG, derive parallel groups — sets of tasks with no dependency between them that can be dispatched to separate implementer subagents simultaneously. List these explicitly in the "并行组" section of tasks.md. The coordinator uses this to maximize parallelism during execution.

**Spec coverage**: Every design section in the spec must map to at least one task. The coverage mapping table at the bottom catches gaps.

## Common Pitfalls

| Mistake | Do this instead |
|---|---|
| Tasks too large (spanning 5+ unrelated files) | Split by design decision or module boundary |
| Tasks too small (single-line mechanical changes) | Merge with adjacent tasks in the same function/class |
| Missing context — implementer doesn't know what to read | List upstream callers and downstream consumers, not just the target file |
| Delete-then-create ordering | Always build → migrate → delete |
| Circular dependencies between tasks | Restructure: extract the shared dependency into its own task |
