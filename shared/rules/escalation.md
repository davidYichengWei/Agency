---
name: escalation
description: Full escalation model — mandatory quality gates, ad-hoc escalation principles, and escalation format
alwaysApply: true
---

# Escalation Model

## Quality Gates

The core loop has two **always-mandatory** gates: **Plan Approval** (after planning, before executing) and **Final Review** / **PR Submission** (before declaring done).

The gates below are **conditional** — invoke them when the task warrants, mark **N/A** with rationale otherwise. Listed in approximate firing order.

| Gate | When to stop | What to present |
|------|-------------|-----------------|
| **Requirements Understanding** | After initial research, before starting work | Task understanding, proposed success criteria, applicable gates |
| **Solution Design** | After drafting an approach, before implementing | Design proposal with alternatives and recommended approach |
| **Test Plan** | After identifying what needs testing | Test strategy, coverage targets, test types |
| **Ops/Visibility** | When the change affects observability, config, or operations | Monitoring, logging, alerting, configuration changes |
| **Code Review** | After Codex review (if enabled) or self-review | Consolidated findings, unresolved issues, risk assessment |

> **Note on Requirements Understanding.** The standard loop folds this gate into Plan Approval; present it separately only when initial research surfaces material uncertainty about the goal — i.e., when writing a detailed plan would risk going in the wrong direction.

## Ad-hoc Escalation Principles

Beyond mandatory gates, use your judgment to escalate when:

- **Missing human knowledge**: Information that cannot be derived from the codebase — business priorities, user intent, organizational context, deadlines.
- **Trade-off decisions**: Multiple valid approaches with different costs. Present options with your recommendation, but defer the final call to the user.
- **Irreversible actions**: Anything hard to undo — production deployments, data migrations, force pushes, deleting branches or files you didn't create.
- **Access/permission gaps**: You lack access to a required tool, environment, or system. Don't retry blindly — escalate with what you tried and what failed.
- **Uncertainty**: You are not confident in your approach after research. Escalate with what you know and what you're unsure about, rather than guessing.

## When NOT to Escalate

- Information derivable from the codebase — research it yourself.
- Standard software engineering decisions — use your judgment.
- Tool usage questions — read docs or try it.
- Choosing between approaches where one is clearly better — just do it.

## Escalation Format

Every escalation (gate or ad-hoc) must be **actionable**:

```
## [Gate name / Escalation reason]

### Context
[What you have done so far, what you found]

### Options
1. [Option A] — [pros/cons]
2. [Option B] — [pros/cons]

### Recommendation
[Your preferred option and why]

### What I need from you
[Specific question or approval requested]
```

Never ask open-ended questions like "what should I do?" Always provide context, options, and your recommendation.
