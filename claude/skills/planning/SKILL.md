---
name: planning
description: Use this skill BEFORE starting any software engineering task that will span more than one step. It creates `.agent/<task-name>/plan.md` with goal, success criteria, and stepwise plan; presents the plan for approval; and drives execution step by step. Invoke when starting or resuming a new feature, investigative bug fix, multi-file refactor, performance investigation, RCA or incident diagnosis, OOM/crash post-mortem, or any work likely to cross quality gates, even if the user does not say "plan". On resume (`pick up where we left off`, `what step are we on`, context compaction), re-read `plan.md` and `activity.md` to reconstruct state. Revise the existing plan when scope expands mid-task. This is the umbrella skill before narrower siblings like requirements-clarification, system-design, task-planning, and troubleshooting - plan first, then dispatch. Skip only for atomic asks - typo or one-line fixes, read-only lookups, single direct tool runs, submit/deploy/test commands, and trivial config tweaks.
---

# Planning

## When to plan

Create a plan when the task involves **multiple steps that span more than one quality gate**:
- New feature (requirements → design → implement → test → review → submit) — yes
- Bug fix with investigation needed — yes
- Significant refactor across modules — yes
- Performance optimization (profile → optimize → benchmark) — yes
- Simple config change, one-line fix, quick code review — no, just do it

When in doubt, create a plan — the overhead is small and the crash recovery benefit is significant.

## Creating a plan

1. Research the codebase to understand scope and complexity
2. Copy `assets/plan-template.md` to `.agent/<task-name>/plan.md`
3. Fill in: goal, success criteria, steps
4. Present the plan at Gate 1 (Requirements Understanding) for user approval
5. After approval, start executing — you drive the process

## Following a plan

- Always know which step you're on. Mark `[~]` when starting a step, `[x]` when done.
- After the user approves at a quality gate, continue to the next step autonomously.
- If you lose track (e.g., after context compaction), re-read `plan.md` and `activity.md` to reconstruct where you are.

## Revising a plan

The plan is a living document. Update it when:

| Situation | What to do |
|---|---|
| Scope expands during a task | Update the existing plan — add steps, revise goal/success criteria. Do NOT create a second plan for overlapping work. |
| Approach changes after a gate | Update the remaining steps. Mark outdated steps as skipped with rationale. |
| Task naturally splits into independent work streams | Split into separate `.agent/<task>/` directories, close the original. |
| User gives a completely new, unrelated task | New `.agent/<new-task>/plan.md`. |
| Previous task's plan is stale/superseded | Mark it complete or delete it. |

**One task directory = one plan = one coherent work stream.** Never have two active plans for overlapping work. If a new plan subsumes an old one, close the old directory.

## Feature Development: the canonical step sequence

Most task types are fluid — you pick the approach based on what the task needs. **Feature development is the exception.** When the user is building a new feature or significant new functionality, follow this exact sequence and invoke the named skill at each step. Each skill produces the artifact the next one consumes (e.g., `system-design` reads the spec that `requirements-clarification` wrote), so the ordering is not decorative.

1. [ ] Clarify requirements → invoke **`requirements-clarification`** → writes `spec.md` sections 1-3 (background, goals, requirements) → **Gate 1** (user review)
2. [ ] Design the solution → invoke **`system-design`** → fills `spec.md` sections 4+ (design, alternatives, test plan, observability) → **Gate 2** (user review)
3. [ ] Break the design into tasks → invoke **`task-planning`** → produces `tasks.md` with dependencies, context, acceptance criteria
4. [ ] Implement. **Prefer TDD / red-green-refactor when the behavior you're building is test-able ahead of time.** Writing tests first forces you to pin down the behavior before you commit to an implementation, and you end up with the regression guard for free. The *granularity* is your call — sometimes one failing test per task, sometimes a whole feature-level test suite written up front and then the code to satisfy it; judge based on how stable the interface is and how naturally the tests decompose. Skip TDD when it honestly doesn't fit (exploratory spike with an unclear interface, pure refactor under existing coverage, UI polish, perf work measured by benchmarks) — but the test plan in `spec.md` is the contract either way, so don't close the feature without its tests written and green. Dispatch work to the `implementer` subagent (one task per implementer; parallelize any tasks flagged as independent in `tasks.md`). Run the full suite after each task goes green to catch regressions early.
5. [ ] Code review → invoke **`code-review`** → runs the five-reviewer panel + per-finding validator → **Gate 6** (user review of consolidated findings)
6. [ ] Prepare submission → use the project's submit/publish workflow if one is installed; exclude agent artifacts and present the final diff/test summary → **Gate 7** (user review before submit)

**Why invoke the skills instead of improvising each stage?** Each of these skills encodes conventions the harness relies on — `spec.md` section layout, `tasks.md` schema, the ultrareview reviewer panel, and artifact-exclusion expectations. Re-deriving any of them ad-hoc is how subtle drift creeps into the codebase. The skills know the format; you shouldn't have to.

**Other task types stay flexible.** Bug fix, RCA, performance investigation, refactor, or a standalone code-review request — reorder, skip, or add steps based on what you discover. Individual skills from the list above (especially `code-review`) still apply where they fit; just don't force the whole 6-step pipeline onto a task that doesn't need it. The TDD preference in step 4 carries over whenever you're adding behavior that's test-able ahead of time — a bug fix, for example, is a natural red-green case (write the failing repro first).

## Key Points

- **Steps are guidance, not rigid** — you may reorder, skip, or add steps based on what you discover.
- **Success criteria must be verifiable** — "code works" is too vague; "all existing tests pass + new regression test added" is concrete.
