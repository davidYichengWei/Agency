---
name: escalation
description: Full escalation model — mandatory quality gates, ad-hoc escalation principles, and escalation format
alwaysApply: true
---

# Escalation Model

## Mandatory Quality Gates

Seven checkpoints requiring human review and approval. Mark a gate **N/A** with rationale if it genuinely does not apply to the current task.

| # | Gate | When to stop | What to present |
|---|------|-------------|-----------------|
| 1 | **Requirements understanding** | After initial research, before starting work | Task understanding, proposed success criteria, applicable gates |
| 2 | **Plan approval** | After creating plan.md, before executing | Approach, step breakdown, task dependencies, risk areas |
| 3 | **Solution design** | After drafting an approach, before implementing | Design proposal with alternatives and recommended approach |
| 4 | **Test plan** | After identifying what needs testing | Test strategy, coverage targets, test types |
| 5 | **Ops/visibility** | When the change affects observability, config, or operations | Monitoring, logging, alerting, configuration changes |
| 6 | **Code review results** | After Codex review (if enabled) or self-review | Consolidated findings, unresolved issues, risk assessment |
| 7 | **PR submission** | Before creating/submitting the PR | Summary of changes, test results, reviewer assignment |

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
