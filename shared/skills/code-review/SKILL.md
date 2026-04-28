---
name: code-review
description: Multi-agent code review aligned with ultrareview. Dispatches five specialist reviewers in parallel (perf, robustness, standards, spec, proof-obligations), then runs a per-finding validator pass that independently reproduces every finding before it reaches the report. Use when asked to perform a code review.
---

# Code Review

## Workflow

1. **Determine scope**: gather changed files, PR/task intent, spec path, current task
2. **Pre-review skip**: exit early for doc-only / config-only / trivial diffs
3. **Dispatch reviewers**: 5 parallel specialist subagents
4. **Validator pass**: 1 validator subagent per finding, dispatched in parallel — always runs, no short-circuit
5. **Dedup**: merge confirmed findings that share file:line±3, severity, and fix
6. **Verdict + report**

### Step 1 — Determine scope

Collect before dispatching anything:

- **Changed files** from `git diff` / `gh pr diff` (plus key context files: callers, interfaces, related modules)
- **Intent**: PR title + description (`gh pr view`) **OR** current task from `.agent/*/plan.md` + `tasks.md`
- **Spec**: path to `docs/design-docs/<module>/<feature>/spec.md` if the active task references one
- **Size metrics**: file count, total lines changed (used for sanity logging only)

### Step 2 — Pre-review skip

Emit `SKIPPED: <reason>` and stop if ANY holds:

- All changed files match `docs/**`, `*.md`, `*.txt`
- Changes are limited to `CMakeLists.txt`, `.ci/**`, config templates, licenses, generated files
- Single file, <10 lines changed, and the change is obviously mechanical (rename, comment-only, whitespace, import reorder)
- PR is marked draft / WIP

### Step 3 — Dispatch reviewers in parallel

Spawn all five in one message:

- `reviewer-perf`
- `reviewer-robustness`
- `reviewer-standards`
- `reviewer-spec`
- `reviewer-proof-obligations`

Each reviewer receives this prompt block:

```
Review the following code changes within your focus area.

[Scope]
Changed files: {files}
Context files: {callers, interfaces, related code}

[Intent]
PR / task: {pr_intent — from PR description or current task}
Spec: {spec path or N/A}
Current task: {task description or N/A}

Use [Intent] to distinguish intentional changes from regressions. If the diff
matches the stated intent, it is not an issue even if the old code was different.

[Severity]
- P0: Must fix before merge (correctness bug, crash, data corruption, critical spec deviation)
- P1: Should fix (specific conditions, contained impact, clear risk)
- P2: Improvement suggestion (no correctness/stability impact)

[Output format]
For each finding:
  file:line — <one-line description>
  severity: P0 | P1 | P2
  confidence: 0-100 (your initial estimate; the validator will re-score)
  why: <one-sentence rationale>
  (optional) repro-hint: <failing input or execution path, if you already have one>

Only report issues in your focus area. If you spot something outside your area,
add a one-line handoff note (not a finding).
```

### Step 4 — Per-finding validator pass (always runs)

After all reviewers return, flatten findings into a single list. Dispatch **one `validator` subagent per finding, all in parallel, in a single message**.

Each validator reads the cited code fresh, attempts a concrete reproduction (failing input / execution trace / exact rule citation), and returns:

```
verdict: confirmed | dismissed | downgraded
severity: P0 | P1 | P2      # final, after any downgrade
confidence: 0-100
rationale: <one paragraph — repro path or counter-evidence>
suggestion: |               # optional, confirmed-only, fixes ≤10 lines
  <committable replacement>
```

Only `confirmed` and `downgraded` findings proceed to Step 5. `dismissed` findings are logged in a transparent "Dismissed by validator" section of the report so the user can audit.

### Step 5 — Dedup after verification

Among surviving findings (`confirmed` or `downgraded`), merge those that:

- Cite the same file within 3-line proximity, AND
- Share the same final severity, AND
- Would be resolved by the same edit

Merged findings list every reviewer that flagged them — multi-reviewer agreement is signal.

### Step 6 — Verdict + report

Verdict rule — applied to the final set of findings that survived validation, using each finding's final `severity` (post-downgrade):

- Any surviving finding with final severity **P0** → **NEEDS_CHANGES**
- Any surviving finding with final severity **P1** and post-validation **confidence ≥ 75** → **NEEDS_CHANGES**
- Otherwise → **PASS**
- P2 findings are listed as suggestions, never block

## Report Format

```markdown
# Code Review Report

## Review Scope
- Changed files: {list}
- Intent: {pr_intent one-liner}
- Spec: {path or N/A}
- Size: {n} files, {m} lines changed

## Verdict: PASS / NEEDS_CHANGES

## Findings

### P0 (must fix)
- **F-1** [reviewer(s), conf={n}] `file:line` — {description}

  <details><summary>Validator repro</summary>

  {one paragraph — failing input, execution trace, or rule citation}
  </details>

  ```suggestion
  {committable replacement, if emitted}
  ```

### P1 (should fix)
- **F-2** [reviewer(s), conf={n}] `file:line` — {description}
  ...

### P2 (suggestions)
- **F-3** [reviewer(s), conf={n}] `file:line` — {description}

## Dismissed by validator
- [reviewer, conf-initial={n}] `file:line` — {original claim} → dismissed: {counter-evidence}
```
