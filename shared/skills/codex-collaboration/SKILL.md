---
name: codex-collaboration
description: Collaborate with Codex (OpenAI GPT model) for cross-model review and parallel problem-solving. Supports two modes — review (Codex reviews your work) and parallel (both agents work independently then compare).
---

# Codex Collaboration

## Collaboration Modes

**Review mode** — Claude works, Codex reviews:
- Use for: code changes, final checks before gates
- Claude completes work → sends to Codex for review
- For code review: instruct Codex to use the `code-review` skill
- For designs/plans: Codex reviews directly (no subagent dispatch)

**Parallel mode** — both agents work independently, then compare:
- Use for: requirements drafting, design proposals, RCA investigation, complex problem-solving
- Claude and Codex both work the problem independently → compare results → synthesize
- Avoids anchoring bias — Codex isn't influenced by seeing Claude's approach first

## Consensus Protocol

**Consensus means Codex explicitly confirms it has no remaining concerns.** Fixing issues and assuming consensus is NOT consensus — you must send your changes back to Codex and get explicit approval.

### Review mode loop

1. Codex reviews → provides findings
2. You address the findings (fix code, update design, or argue why a finding is wrong)
3. **Resume the session** and ask Codex to re-review your changes
4. Codex confirms all issues resolved → consensus reached → proceed
5. Codex raises new/remaining issues → go to step 2 (max 3 rounds)
6. After 3 rounds with unresolved disagreements → escalate to user with both positions

### Parallel mode loop

1. Both work independently → compare results
2. Identify agreements and disagreements
3. For disagreements: each side argues with evidence → converge on a unified position
4. If cannot converge (max 3 rounds) → escalate to user with both positions

**The loop is not optional.** Never skip re-review. Never declare consensus unilaterally. Codex must say it's satisfied.

## Session Management

- **New session**: Start a fresh session for each task in `tasks.md`, or when switching to a fundamentally different topic (e.g., from design review to code review).
- **Resume**: Within the same task or topic, always resume the existing session. Codex retains full context — starting fresh loses valuable conversation history.

## How to Invoke Codex

Always include `--skip-git-repo-check` — Codex refuses to run outside a trusted git repo otherwise, and the current working directory often isn't one.

### Starting a session

```bash
codex exec --skip-git-repo-check "<your prompt>" </dev/null
```

Output includes `session id: <uuid>` — extract and save it for subsequent calls.

### Continuing the conversation

```bash
codex exec resume --skip-git-repo-check "$SESSION_ID" "<next prompt>" </dev/null
```

The session maintains full history — Codex remembers everything said earlier.

The `</dev/null` is mandatory — see "Running Codex Without Blocking" below.

## Running Codex Without Blocking

Codex calls may take 20+ minutes. You must not block the main agent waiting, and you must not invent your own polling scheme.

- **Use the Bash tool's `run_in_background: true`.** The harness captures Codex's stdout/stderr and sends you a completion notification when the process exits. Read the output from the notification's file path at that point — not before.
- **Always close stdin with `</dev/null`.** When Bash launches codex via `run_in_background: true`, stdin is a non-TTY pipe rather than closed, and the codex CLI will block reading additional input even when the prompt is supplied via argv. The hang is silent — the output file shows only `Reading additional input from stdin...` and the codex process never starts processing the prompt. If you forget the redirect, the task will run indefinitely until you kill it. Append `</dev/null` to every `codex exec` and `codex exec resume` call.
- **Do not redirect Codex output to a tmp file yourself** (e.g., `codex ... > /tmp/foo.log &`). The harness already does this correctly via `run_in_background`; doing it manually duplicates work and invites the next anti-pattern.
- **Do not poll a log file with `until grep ...; do sleep; done`.** These loops routinely grep for the wrong marker, run forever when Codex fails silently, and leak zombie shells that keep sleeping after the conversation moves on. If you find yourself reaching for `grep` + `sleep` to detect completion, stop — you should be waiting on the background task notification instead.
- **No timeout.** Don't set a `timeout` on the Bash call and don't kill the process. Codex finishes when it finishes; the completion notification is your signal.

## Rules

- **Pass by reference, not by value**: Codex has full filesystem access. Point to file paths, skill names, git refs — never paste large blocks of text into the prompt.
- **No build**: Codex should not build/compile. Build verification is the agent's responsibility.
- **Session persistence**: Sessions persist on disk. Resume with `codex exec resume --skip-git-repo-check --last` if you lose the session ID.
