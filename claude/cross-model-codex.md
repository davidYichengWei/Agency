## Cross-Model Collaboration

Proactively collaborate with Codex using the `codex-collaboration` skill. Two models working independently produce better results than one — Codex brings a different perspective that catches blind spots.

### Task Execution Addendum

When implementing tasks from `tasks.md`, use Codex review in the implement-review-fix loop:

```
For each task in tasks.md:
  1. Dispatch to implementer subagent
  2. Implementer completes → Codex reviews (via codex-collaboration skill)
  3. Review passes → mark task [x], move to next task
     Review fails  → send fixes back to the SAME implementer
                      (don't spawn a new one — continue the conversation)
                    → re-review → repeat until pass
```

### When to use parallel mode (both work independently, then compare)

Default to parallel mode for any task that involves judgment, analysis, or creative problem-solving:

- **Requirements/design**: Both draft independently → compare → synthesize the strongest parts
- **RCA/investigation**: Both analyze independently → compare hypotheses → stronger root cause
- **Architecture decisions**: Both propose approaches → compare trade-offs → more robust choice
- **Performance analysis**: Both investigate independently → cross-check findings
- **Complex bug diagnosis**: Both form hypotheses → compare → reduces tunnel vision

Launch Codex at the start of these tasks, not after you've already formed your opinion — that defeats the purpose of independent perspectives.

### When to use review mode (Codex reviews your work)

- **Code review**: After implementation, Codex reviews the diff
- **Final check before gates**: Codex validates your deliverable before presenting to user

### Mandatory consensus at quality gates

**Before presenting any deliverable at a quality gate, you MUST have Codex's agreement.** Do not escalate to the user while you and Codex still disagree. The consensus protocol (in the skill) handles iteration and escalation if consensus cannot be reached.

This means: at every gate, the user sees a unified position from both models, not just yours.

### When NOT to use Codex

- Simple, mechanical tasks (rename a variable, fix a typo, run a build)
- Tasks where the answer is deterministic (look up a config value, read a log)
- When latency matters more than quality (quick user questions)
