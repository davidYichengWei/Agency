---
name: requirements-clarification
description: Creates and fills spec.md sections 1-3 (background, goals, requirements) for new features and significant changes. Invoke when the task warrants a design doc — typically new features, significant refactors, or cross-module changes. Also triggered when the user explicitly asks to write a spec or clarify requirements.
---

# Requirements Clarification

This skill creates and fills spec.md sections 1-3 (background, goals, requirements). The goal is to produce a clear, agreed-upon problem statement before any design work begins — sections 4+ are handled by the `system-design` skill.

## Core Principle

The agent should do the research, the user should provide the intent. Only ask the user for information that cannot be derived from the codebase (goals, scope, priorities, business context). For everything else (current state, interfaces, constraints), use the researcher subagent to investigate and fill it yourself. This reduces the burden on the user — they review and adjust your draft rather than answering a long list of questions.

## Workflow

1. Copy `assets/spec-template.md` to `docs/design-docs/<module>/<feature>/spec.md`
2. Research the codebase to understand the current state, then draft each section
3. Ask the user only for human knowledge: why this is needed, what the goals are, what's in/out of scope
4. Present sections 1-3 at Gate: Requirements Understanding for approval

The section order (1.1 → 1.3 → 2.1 → 2.2 → 3.1 → 3.2) is a natural progression, but use your judgment — if the user leads with goals, start there.

## Common Pitfalls

| Mistake | Why it's wrong | Do this instead |
|---|---|---|
| Asking the user about current implementation | This is derivable from code — wasted user time | Research it yourself with the researcher subagent |
| Only exploring the module the user mentioned | Misses upstream/downstream dependencies, hidden constraints, and related modules | Start from the user's scope but proactively trace dependencies, call chains, and data flows into adjacent modules |
| Asking multiple questions at once | Overwhelms the user, gets shallow answers | One focused question per turn, dig deep before moving on |
| Writing implementation details in requirements | Mixes WHAT with HOW, constrains design prematurely | Requirements describe what the system should do, not how. See examples in the spec template |
| Accepting vague requirements without pushback | "Make it fast" or "add caching" isn't a requirement | Push for specifics: what's the target latency? What problem does caching solve? |
