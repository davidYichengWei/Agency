# Agency

> What makes a human engineer 10x isn't raw skill — it's **agency**. The same turns out to be true of AI agents. This harness is named for the trait it's built to cultivate in them.

An agent harness that turns you into a manager of autonomous digital engineers.

[中文文档](README-zh.md)

---

## The Problem

If you've been building agent skills, you've probably been here:

**Procedural workflows that limit your agent.** You write step-by-step skills for every task type — dev tasks get one procedure, debugging gets another, testing gets a third. Each one encodes your assumptions about how the task should be done. These procedures become ceilings, not floors — the agent can't do better than what you prescribed, even when it could. And they rot: every model upgrade potentially invalidates steps you baked in months ago.

**"Magical prompts" you can't verify.** You add best practices, coding standards, and behavioral nudges to the prompt, hoping they help. But did the agent write better code because of your 500-token coding standard, or would it have done the same without it? You accumulate prompt cruft that nobody dares remove because nobody can prove it's not helping.

**You are the bottleneck, not the agent.** Without structure, every decision runs through you. The agent can reason and act, but it sits idle waiting for your next prompt. The constraint isn't the agent's capability — it's your bandwidth.

## The Approach

Agency is built on a few hard-earned convictions:

1. **Declarative over procedural** — Define boundaries (quality gates, exit criteria), not steps. The agent picks its own path. Don't tell it *how* to do its job.
2. **Minimal by default** — Don't tell the agent what it already knows. Every piece of injected context must earn its place through observed evidence, not speculation about what might help.
3. **Bottom-up growth** — Start nearly empty. Knowledge accumulates from real mistakes, not from upfront guessing. If the next-gen model can handle it without help, your skill was dead weight.
4. **High agency with guardrails** — The agent drives autonomously; you review only at phase boundaries. Maximum freedom within constraints.

```
Without Agency:   You drive, AI assists       →  You're in every decision loop
With Agency:      AI drives, you manage       →  You're only at quality gates
```

The result: agents that can run for hours — researching, designing, implementing, reviewing — under constraint but without constant hand-holding. You check in at gates, not at every step. And because each agent runs independently, you can manage multiple agents on multiple tasks in parallel, the same way a tech lead manages a team.

### What the agent does on its own

- Researches the codebase to understand context — doesn't ask you "where is X?"
- Proposes success criteria and a plan — doesn't ask you "what should I do?"
- Makes design decisions within constraints — doesn't ask you "which approach?"
- Dispatches subagents in parallel for implementation — doesn't serialize everything
- Runs builds, tests, and self-review before presenting to you
- Learns from mistakes and writes reflections without being told
- Escalates with context, options, and a recommendation — never open-ended questions

### What the agent stops for

Mandatory checkpoints where the agent presents its work and waits for your approval. Between them, it runs autonomously.

```
You: "Add pagination to the user list API"
  │
  ▼
Agent researches codebase ──► "Here's what I understand, here's my plan"
  │                                          You: ✓ Approved
  ▼
Agent drafts design ────────► "Here's my design with alternatives"
  │                                          You: ✓ Approved
  ▼
Agent implements ───────────► "Code review passed, here are findings"
  │                                          You: ✓ Approved
  ▼
Agent prepares PR ──────────► "Ready to submit"
                                             You: ✓ Ship it
```

Agency is pure Markdown — no runtime, no dependencies, no lock-in. It works with any coding agent that supports skills and subagents. Claude Code and Codex are supported out of the box; other agents (Cursor, Gemini, etc.) just need minor config adjustments.

## How It Works

### Quality Gates and Escalation

High agency doesn't mean uncontrolled. LLM outputs are probabilistic — each step in a long task carries a small chance of drifting from your intent. Without checkpoints, these drifts compound: the agent builds on a misunderstood requirement for hours, and you discover the problem only at the end when correction is most expensive.

Agency solves this with two mechanisms:

**Quality gates** are checkpoints at phase boundaries — where errors are cheapest to catch and most expensive to miss. The agent works freely between gates, but must stop and present at each one. You review, redirect if needed, and approve.

Two gates are **always-mandatory**: **Plan Approval** (after planning, before executing) and **Final Review / PR Submission** (before declaring done). The gates below are **conditional** — invoked when the task warrants, marked N/A with rationale otherwise.

| Gate | What it catches |
|------|----------------|
| Requirements Understanding | Wrong problem, missed scope, bad assumptions |
| Solution Design | Architectural mistakes, missed alternatives |
| Test Plan | Inadequate coverage, wrong test strategy |
| Ops/Visibility | Missing monitoring, config issues, deployment risk |
| Code Review | Implementation bugs, style violations, security issues |

A bug fix might only hit Code Review on top of the mandatory pair; a new feature typically hits all of them. The agent proposes which gates apply in `plan.md` and you dial.

**Ad-hoc escalation** handles the unexpected between gates. When the agent hits a trade-off with no clear winner, missing access, or genuine uncertainty, it escalates with context, options, and its recommendation — never open-ended questions. You make the call, the agent continues.

Together: maximum autonomy for decisions the agent can make well, human judgment only where it's actually needed.

### Cross-Model Collaboration

Claude and Codex can work together by default — two models working independently catch blind spots a single model misses:

- **Review mode**: the main agent implements, the peer agent reviews the diff
- **Parallel mode**: both models work independently on the same problem, then compare — reduces blind spots and anchoring bias

Before any quality gate, the main agent must reach consensus with its peer when cross-model collaboration is installed. You always see a unified position, not two unresolved opinions.

### Constraint-Based Orchestration

No fixed pipeline. The agent navigates freely, bounded by four constraints:

```
                    ┌──────────────┐
                    │  Exit        │  "Am I done?"
                    │  Criteria    │  (pull toward completion)
                    └──────┬───────┘
                           │
    ┌──────────────┐       │       ┌──────────────┐
    │  Quality     │◄──────┼──────►│  Domain      │
    │  Gates       │       │       │  Knowledge   │
    │  (guardrails)│       │       │  (standards) │
    └──────────────┘       │       └──────────────┘
                           │
                    ┌──────┴───────┐
                    │  Operating   │  "How should I behave?"
                    │  Principles  │  (culture & judgment)
                    └──────────────┘
```

The agent chooses its own approach, order, and tools within these bounds.

## Quick Start

Tell your agent:

```
"Install the Agency harness from https://github.com/davidYichengWei/Agency —
 clone it, read the README, run install.sh, then read the installed root
 instructions, rules, and skills to understand how you should operate."
```

By default this installs Claude as the main agent and Codex as the collaborator. You can choose the main agent explicitly:

```bash
./install.sh --main claude           # Claude main + Codex collaborator
./install.sh --main codex            # Codex main + Claude collaborator
./install.sh --main codex --single   # Codex only, no cross-model addendum
./install.sh --reverse --main claude # pull live skills/rules back into the repo
```

That's it. The agent installs and learns its own operating model. From now on, give it tasks:

```
"Fix the race condition in the connection pool"
"Add rate limiting to the public API"
"Investigate why query latency spiked yesterday"
```

The agent will research, plan, and execute — stopping at quality gates for your approval.

## Architecture

```
Agency/
├── shared/                    # Assets shared across all agents
│   ├── rules/                 # Always-on behavioral constraints
│   │   ├── activity-tracking.md
│   │   ├── escalation.md
│   │   ├── measurement-driven-analysis.md
│   │   └── receiving-feedback.md
│   ├── agents/                # Specialist subagents
│   │   ├── researcher.md          # Read-only codebase exploration
│   │   ├── implementer.md         # Code changes in isolated context
│   │   ├── reviewer-*.md          # Specialist code reviewers (spec, standards, robustness, perf, proof-obligations)
│   │   └── validator.md           # Independent verification of completed work
│   ├── skills/                # On-demand capabilities
│   │   ├── planning/              # plan.md for non-trivial tasks
│   │   ├── requirements-clarification/  # spec.md sections 1-3
│   │   ├── system-design/         # spec.md sections 4+
│   │   ├── task-planning/         # tasks.md breakdown
│   │   ├── code-review/           # Multi-agent review orchestration
│   │   ├── codex-collaboration/   # Cross-model consensus protocol
│   │   ├── claude-collaboration/  # Cross-model consensus protocol
│   │   ├── process-cr-comments/   # Triage and respond to PR review comments
│   │   ├── consolidate-agent-dir/ # Clean up task artifact directories
│   │   └── reflect/               # Proactive reflection on mistakes and lessons
│   └── PROJECT.md             # (Optional) project-specific context appended to installs
├── claude/
│   ├── CLAUDE-main.md         # Claude as primary agent
│   ├── CLAUDE-collaborator.md # Claude as peer reviewer/problem-solver
│   └── cross-model-codex.md   # Addendum when Codex is installed as peer
├── codex/
│   ├── AGENTS-main.md         # Codex as primary agent
│   ├── AGENTS-collaborator.md # Codex as peer reviewer/problem-solver
│   └── cross-model-claude.md  # Addendum when Claude is installed as peer
└── install.sh                 # Install and sync script
```

### Three Layers

```
┌─────────────────────────────────────────────┐
│       Layer 3: Domain Knowledge             │
│  Project-specific skills (earned or manual) │
│  Your codebase conventions, module maps     │
├─────────────────────────────────────────────┤
│       Layer 2: Deliverable Templates        │
│  requirements-clarification, system-design, │
│  task-planning (structured output formats)  │
├─────────────────────────────────────────────┤
│       Layer 1: Core Harness                 │
│  Orchestration, quality gates, escalation,  │
│  activity tracking, reflection              │
├─────────────────────────────────────────────┤
│       Layer 0: Agent Runtime                │
│  Claude Code, Codex, or any compatible agent│
└─────────────────────────────────────────────┘
```

**Layer 1** ships with Agency. **Layer 2** provides optional templates for common deliverables. **Layer 3** starts empty and grows as you use it.

## Customization

### Adding Project-Specific Knowledge

Agency starts with zero project-specific knowledge — models already know general software engineering. Add skills only when you observe gaps:

```bash
mkdir -p ~/.claude/skills/my-convention/
cat > ~/.claude/skills/my-convention/SKILL.md << 'EOF'
---
name: my-convention
description: Our project's naming conventions for database models
---
# My Convention
...
EOF
```

### Bottom-Up Growth

The reflect skill captures lessons from mistakes into `reflection.md`. When a pattern recurs, promote it to a persistent rule or skill:

```
Day 0:  Core harness only
        ↓ agent works on real tasks, makes mistakes
Day N:  reflection.md captures "forgot backward compat check"
        ↓ you review and promote to a rule
Day M:  Harness has organically grown domain knowledge
        tailored to YOUR project's actual pitfalls
```

## Compatibility

Agency is pure Markdown with YAML frontmatter. It works with any agent that supports:
- **Claude Code**: skills, rules, and custom agents (`~/.claude/`)
- **Codex**: AGENTS.md and custom agents (`~/.codex/`)
- **Other agents**: Copy the Markdown files to your agent's configuration directory

## License

[MIT](LICENSE)
