---
name: claude-collaboration
description: Collaborate with Claude (Anthropic Claude Code model) for cross-model review and parallel problem-solving. Supports two modes - review (Claude reviews your work) and parallel (both agents work independently then compare), with multi-round continuity by recording Claude's session_id and resuming it.
---

# Claude Collaboration

## Collaboration Modes

**Review mode** - Codex works, Claude reviews:
- Use for: code changes, final checks before gates
- Codex completes work -> sends paths, diffs, or task context to Claude for review
- For code review: ask Claude to review critically and cite specific file/line evidence
- For designs/plans: Claude reviews directly as an independent reviewer

**Parallel mode** - both agents work independently, then compare:
- Use for: requirements drafting, design proposals, RCA investigation, complex problem-solving
- Codex and Claude both work the problem independently -> compare results -> synthesize
- Avoids anchoring bias - Claude should not see Codex's answer before producing its own position

## Consensus Protocol

**Consensus means Claude explicitly confirms it has no remaining concerns.** Fixing issues and assuming consensus is NOT consensus - you must send your changes back to Claude and get explicit approval.

### Review mode loop

1. Claude reviews -> provides findings
2. You address the findings (fix code, update design, or argue why a finding is wrong)
3. **Resume the session** and ask Claude to re-review your changes
4. Claude confirms all issues resolved -> consensus reached -> proceed
5. Claude raises new/remaining issues -> go to step 2 (max 3 rounds)
6. After 3 rounds with unresolved disagreements -> escalate to user with both positions

### Parallel mode loop

1. Both work independently -> compare results
2. Identify agreements and disagreements
3. For disagreements: each side argues with evidence -> converge on a unified position
4. If cannot converge (max 3 rounds) -> escalate to user with both positions

**The loop is not optional.** Never skip re-review. Never declare consensus unilaterally. Claude must say it is satisfied.

## Session Management

- **New session**: Start a fresh session for each task in `tasks.md`, or when switching to a fundamentally different topic (e.g., from design review to code review).
- **Resume**: Within the same task or topic, always resume the existing session. Claude retains full context - starting fresh loses valuable conversation history.
- **Session ID**: Let Claude create the first session, record the emitted `session_id`, then use `--resume "$SESSION_ID"` for follow-ups. Use an explicit `--session-id` only when the caller cannot parse Claude's output before the next round.

## How to Invoke Claude

Invoke the `claude` binary directly. Start Claude in the current working directory; do not hardcode a repository path. If the caller tool supports `workdir`, set `workdir` to the target repo instead of adding `cd ...` to the command.

### Starting a session

```bash
claude -p --output-format json '<your prompt>'
```

Record the `session_id` from Claude's JSON output for subsequent calls.

### Continuing the conversation

```bash
claude -p --resume "$SESSION_ID" '<next prompt>'
```

The session maintains full history - Claude remembers everything said earlier in that session.

### Quick continuity check

```bash
claude -p --output-format json 'Remember keyword quartz-river. Reply with the keyword.'
# Copy the emitted session_id from the JSON output.
claude -p --resume '<session_id>' 'What keyword did I ask you to remember?'
```

If automation needs to extract the id, parse the `session_id` field from the JSON output with the available local tooling.

## Running Claude Without Blocking

Claude calls may take a long time. Do not invent polling loops.

- If the harness supports background tool execution, run the Claude command in the background and read the captured output when the completion notification arrives.
- Do not redirect Claude output to a tmp file yourself unless the harness has no background execution support.
- Do not poll a log file with `until grep ...; do sleep; done`.
- Do not set a short timeout or kill the process just because it is still reasoning.

## Rules

- **Pass by reference, not by value**: Claude has filesystem access. Point to file paths, skill names, git refs, and commands - never paste large blocks of text into the prompt.
- **No build**: Claude should not build/compile. Build verification is the agent's responsibility.
- **Independent review**: In parallel mode, do not show Claude Codex's analysis before Claude gives its own answer.
- **Session persistence**: Sessions persist on disk. If you lose the session ID, prefer starting a fresh session unless continuing the exact prior context is required.
