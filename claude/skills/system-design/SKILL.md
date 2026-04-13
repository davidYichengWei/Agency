---
name: system-design
description: Fills spec.md sections 4+ (design, alternatives, test plan, observability). Invoke after sections 1-3 are approved at gate 1. The agent researches the codebase, drafts the design, and presents at gate 2 for approval.
---

# System Design

## Prerequisite

spec.md sections 1-3 must be complete and approved. If not, invoke `requirements-clarification` first.

## Core Principle

The agent drafts the design, the user reviews it. Research the codebase thoroughly — especially adjacent and similar modules — before proposing anything. The design should follow existing patterns in the codebase unless there's a good reason to deviate, and trade-offs should be explicit.

## Workflow

1. Use researcher subagent to investigate: existing module structure, adjacent/similar modules' implementation patterns, interfaces, dependencies, constraints
2. Draft sections 4.1 (overview), 4.2 (key design decisions), 4.3 (trade-offs) — focusing on WHAT and WHY, not implementation details
3. Draft section 5 (alternatives considered)
4. Present sections 4-5 at Gate 2 (Solution Design) for approval
5. After gate 2 approval, draft section 6 (test plan) → present at Gate 3
6. Draft section 7 (observability & operations) if applicable → present at Gate 4, or mark N/A

## Abstraction Level

The design doc captures decisions and trade-offs, not code. Use this as a guide:

| Belongs in spec.md | Belongs in code / tasks.md |
|---|---|
| Module boundaries and dependencies | Specific file changes |
| Interface contracts and data models | Function signatures and implementations |
| Key algorithms (conceptual) | Line-by-line logic |
| Trade-offs and their rationale | Configuration values |

If you're writing function names or line numbers, it's too detailed for the spec.

## Common Pitfalls

| Mistake | Do this instead |
|---|---|
| Designing without researching existing patterns | Always investigate how adjacent modules solve similar problems — deviate only with explicit rationale |
| Writing implementation-level detail in the spec | Keep it at the architecture/interface level — implementation goes in tasks.md |
| Proposing a single approach without alternatives | Always consider at least one alternative and explain why you chose your approach |
| Skipping test plan or ops sections | These are quality gates — fill them or explicitly mark N/A with rationale |
