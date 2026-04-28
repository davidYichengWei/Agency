---
name: process-cr-comments
description: Process review comments on an MR, a design doc, or a spec — validate each finding independently with parallel validator subagents, apply fixes for the ones that hold up, and produce a reply report designed to earn reviewer sign-off. The report explains exactly how each confirmed issue was fixed, and for anything not fixed (dismissed, downgraded, deferred) it gives the reviewer the specific counter-evidence or rationale they need to approve anyway. Use this skill whenever the user shares review comments from any source — human reviewers or AI reviewers in CI, code diffs or prose docs — and wants them triaged and responded to (e.g. "here are the CR comments from CI", "respond to these review comments", "validate these review findings", a pasted list of `file:line — issue` items, or an MR URL whose review comments need handling). Also use when the user pastes any merge-request or design-doc review and asks what's real vs. noise, or asks for fixes and a reply based on review feedback.
---

# Process Review Comments

Review comments — whether from a human reviewer, an AI reviewer in CI, or a design-doc commenter — often mix real issues with things that won't survive a fresh read of the code or spec. Acting on everything bloats the diff; dismissing silently loses the reviewer's trust. This skill does the middle thing: validates each finding independently, fixes what holds up, and produces a reply that gives the reviewer enough context to approve.

**The report's purpose is consensus.** It's not a private log — it's the message you'll send back to the reviewer so they can click "Approve". That shapes two things:

- For every **fix**, explain *how* you fixed it — enough detail that the reviewer can confirm the fix matches what they were worried about, without re-reading the whole diff.
- For every **non-fix** (dismissed, downgraded, deferred, stylistic-only, not-this-MR), explain *why* in terms the reviewer can accept — specific counter-evidence, a citation, a design rationale, or a scope boundary. A reviewer won't approve on "we decided not to" alone; they will approve on "here's why that concern doesn't apply here."

A finding is only real if a fresh read of the code or spec can reproduce it. The skill does exactly that — in parallel, one validator per finding — before deciding anything.

## Workflow

1. **Ingest review comments** → parse into discrete findings
2. **Gather scope** → changed files / changed spec sections, PR or doc intent, related spec
3. **Dispatch validators in parallel** → one `validator` subagent per finding
4. **Final judgement** → main agent reconciles verdicts, handles disagreements, dedups
5. **Fix confirmed issues** → apply the suggestions (or write fresh fixes) in this session
6. **Reply report** → consensus-oriented markdown, one entry per finding, written *to the reviewer*

### Step 1 — Ingest review comments

Review comments arrive in a few shapes. Detect which and normalize into a list of findings.

**Shape A — An MR / PR / ticket URL or ID.** The user points at a hosted review (e.g. an MR URL, a PR number, a review ticket ID). Use whatever MCP or CLI the environment provides to fetch (a) the comments on the review — human and AI-authored — and (b) the diff or changed files, so validators can read current code. Don't assume a specific tool; pick the one that matches the host.

**Shape B — Pasted text / markdown.** The user pastes review comments directly, often as a list or `file:line — issue` blocks, or reviewer output with `severity`/`confidence`. Parse the text into findings; if the format is ambiguous, show the user your parsed list and confirm before dispatching.

**Shape C — Doc / spec review comments.** The findings reference a design doc or spec (e.g. `docs/design-docs/<module>/spec.md#section-4`) rather than source code. Treat each comment as a finding on that document — the "cited location" is a section / heading / paragraph rather than `file:line`, and validation means checking the prose, the spec's internal consistency, and any code the doc describes. Dispatch validators the same way; they'll read the doc fresh.

Each finding must carry (fill unknowns with "unspecified"):

- **location**: `file:line` for code, or `path#section` / quoted excerpt for prose
- one-line description
- reported `severity` (P0/P1/P2) if present
- reviewer/author (human name, AI bot, or "unknown")
- any repro hint, rule citation, or prose snippet the reviewer supplied
- optional: original comment ID (needed later only if the user asks you to post the reply back on the review)

If a comment doesn't cite a location, try to infer from the diff / doc + description. If you still can't locate the target, mark the finding `unlocatable` and skip validator dispatch — surface it in the report and ask the reviewer to clarify (this is itself part of earning consensus).

### Step 2 — Gather scope

Before dispatching validators, collect the context they need. Each validator will re-read the source but shouldn't reinvent the world:

- **Changed code + diff** (for MRs): from `git diff` locally, or from the review host via MCP/CLI. Point validators at specific paths, not the whole tree.
- **Changed doc / spec sections** (for doc reviews): the path + which sections were edited, so validators know what's new vs. pre-existing.
- **Intent**: PR/MR description, spec goals, or current task from `.agent/*/plan.md`. Intent lets validators distinguish regressions from deliberate changes — "this used to be X, now it's Y, the PR description says that's the point" is different from a regression.
- **Related spec** (optional for code MRs): if the MR references a design doc, include the path so spec-compliance findings can be checked.

Keep this block short — it's pasted into every validator prompt.

### Step 3 — Dispatch validators in parallel

**Spawn one `validator` subagent per finding, all in the same message.** Serial validation wastes time, and validators returning together lets you do the final judgement with full information.

Each validator receives:

```
You are validating a single review-comment finding against the real source.

[Finding]
- location: {file:line or path#section}
- description: {one-line}
- claimed severity: {P0/P1/P2 or unspecified}
- reviewer: {name, AI bot, or "unknown"}
- reviewer's rationale: {why, if provided}
- repro-hint: {failing input / rule citation / prose quote / execution path, or "none"}

[Scope]
Changed files / sections: {list}
MR / doc intent: {one-liner}
Related spec: {path or N/A}

[Instructions]
Follow the validator agent's standard protocol: read the cited source fresh,
attempt a concrete reproduction (failing input, execution trace, exact rule
citation, or — for prose — quote the specific passage that is wrong or
inconsistent), check for upstream guards / framework guarantees / existing
tests / context the reviewer may have missed, and render verdict:
confirmed | dismissed | downgraded.

Return in the validator's standard output format (verdict / severity /
confidence / rationale / suggestion / handoff).
```

The `validator` subagent already knows its protocol — don't re-teach it here, just give it the finding and scope. Use `subagent_type: "validator"`.

**Unlocatable or malformed findings don't get validators** — they flow straight to the report, flagged for the reviewer to clarify.

### Step 4 — Final judgement

Once all validators return, reconcile:

1. **Take verdicts at face value by default.** The validator's confidence rating is the primary signal. `confirmed` with high confidence → act on it. `dismissed` with specific counter-evidence → trust it.

2. **Scrutinize ambiguous cases.** If two validators covered nearby code and disagree, or a validator's rationale is thin ("looks fine" without evidence), read the source yourself and break the tie. Don't ask the user to arbitrate what you can read. Thin dismissals are especially dangerous here — you'll be sending them to the reviewer, and "looks fine" won't earn approval.

3. **Dedup surviving findings.** Merge findings where:
   - Same file/section within close proximity (≤3 lines for code; same subsection for prose), AND
   - Same final severity, AND
   - Would be resolved by the same edit

   Record every reviewer that flagged the merged finding — multi-reviewer agreement is signal, and listing all reviewers in the reply acknowledges each of them.

4. **Decide action per finding.** For each surviving finding, classify as `fix`, `report-only`, `user-decision`, or `defer`:
   - **fix**: validator confirmed, fix is clear (validator's suggestion or an obvious small edit). Apply it.
   - **report-only**: P2 / suggestion / style — note in report; the reply explains why it's not acted on (e.g., "tracked in follow-up", "codebase convention differs", "out of this MR's scope").
   - **user-decision**: confirmed but the fix is non-trivial, touches many files, or has meaningful design trade-offs. Stop, present the options, get direction before editing.
   - **defer**: real but out of scope for this MR/doc (separate bug, refactor, follow-up work). Capture exactly why it should be a separate change so the reviewer accepts deferring.

### Step 5 — Fix confirmed issues

For findings marked `fix`:

- Prefer the validator's `suggestion` block when it's present and ≤10 lines — validators already verified the fix is self-contained.
- When writing a fresh fix, keep it tight: address only the reported issue, no drive-by refactors. If you notice a related but separate problem, flag it in the report under "Observed during fix" — don't silently bundle. Reviewers get suspicious when a fix balloons.
- After applying, re-read the edited code/prose to confirm the fix matches what the validator reproduced. If the source has shifted since the reviewer ran (new commits, rebase, doc edits), the reported location may no longer mean the same thing — re-validate before fixing.
- For multi-finding edits in the same file, batch them into one Edit/MultiEdit operation so the file stays consistent.

As you fix, capture the information the report will need: the exact before/after, which lines/sections moved, and (if relevant) why this particular fix was chosen over an alternative. You'll need that in Step 6 — don't reconstruct it later from memory.

Do **not** compile, run tests, or open MRs from within this skill — those are separate workflows. The user decides what to do with the fixes afterwards.

### Step 6 — Reply report (written for the reviewer)

Produce the report in markdown, rendered inline in the conversation. **Address the reviewer directly** — this is the content that will go back to them (by the user, or by you if the host provides a reply tool). Two audiences read this:

1. The **reviewer** (primary) — needs enough detail to click Approve without re-reading everything.
2. The **user** (you're handing it off) — needs to see what was actually done and what they still need to decide.

Use the structure below so reports are comparable across runs.

```markdown
# Review Response

## Input
- Source: {MR URL / pasted comments / doc path + reviewer name}
- Comments received: {n} ({k} from {reviewer A}, {m} from {reviewer B}, ...)
- Scope: {changed files / sections}

## Summary for the reviewer

> Thanks for the review. Of the {n} comments, {a} are fixed in the latest commit(s), {b} I'm proposing not to address (rationale below — happy to revisit), and {c} need your call. Please skim the per-comment details and let me know if anything is unresolved.

(Adjust tone to match the project's norms; some teams prefer more formal, some less.)

## Per-comment response

### Fixed
- **C-1** `location` — {original comment, quoted or paraphrased}
  - **How it was fixed**: {specific description — what changed, in which function/section, and why this addresses the concern}.
    Before: `{minimal snippet or summary}`
    After:  `{minimal snippet or summary}`
  - **Why this fix**: {if the concern admits multiple fixes, explain the choice — e.g., "returning an error rather than panicking because this is a library API"}

### Not fixed — dismissed
- **C-2** `location` — {original comment}
  - **Why this isn't a bug**: {concrete counter-evidence — upstream guard, framework guarantee, test that covers the path, rule that doesn't actually say what was cited, etc.}. {Quote the specific code / doc / rule that proves it.}
  - {If the reviewer might still worry, add: "If you'd like, I can add an assertion / comment to make this precondition explicit."}

### Not fixed — downgraded
- **C-3** `location` — {original comment} (P{orig} → P{new})
  - **Why the severity is lower than claimed**: {specific scoping — cold path, narrow trigger condition, existing mitigations, etc.}
  - **Acted on?**: {yes with a small tweak / no because {reason}}

### Not fixed — deferred to a follow-up
- **C-4** `location` — {original comment}
  - **Why not in this MR**: {scope boundary — separate bug, refactor, depends on another change, etc.}
  - **Where it's tracked**: {issue link / TODO comment / follow-up MR planned / "I'll open an issue if you confirm this shouldn't block approval"}

### Needs your call
- **C-5** `location` — {original comment}
  - **What I'd do**: {recommended action}
  - **Trade-off**: {why I'm not just doing it — design tension, cross-cutting impact, etc.}
  - **Waiting on**: your preference between {option A} and {option B}

### Unlocatable
- {original comment, quoted}
  - I couldn't resolve where this applies. Could you point to the specific {file:line / section}? Happy to address once clarified.

## Observed during fix (not comment-driven)
- {optional — related issues spotted while editing, called out for transparency so the reviewer isn't surprised}
```

Writing principles for the report body:

- **Quote the original comment** (or a faithful paraphrase) for each entry. The reviewer shouldn't have to scroll back.
- **Be specific about fixes.** "Applied validator's suggestion" is fine in an internal log, not in a reply. Say what changed and where. Tiny before/after snippets are worth more than prose.
- **Anchor dismissals to evidence.** Vague rationales ("this is fine", "by design", "not a real issue") lose reviewer trust. Quote the guard, cite the test, point to the spec section, name the framework guarantee.
- **Acknowledge ambiguity.** If a dismissal is defensible but not ironclad, say so and offer a small compromise (an assertion, a comment, a test) rather than flatly refusing.
- **Keep the reviewer's ego out of it.** Wrong findings happen; the reply should make it easy for the reviewer to agree, not embarrassing. Avoid phrasing like "this is wrong because..." — prefer "on a fresh read, this path is guarded by..." which focuses on the code, not the reviewer.

## Principles

- **Validators do the reproduction; you do the judgement; the reviewer does the approval.** Your job is to turn validator verdicts into concrete actions *and* a persuasive explanation the reviewer can sign off on.
- **Don't re-litigate dismissals internally**, but *do* make them airtight for the reviewer. Second-guessing wastes your time; under-justifying wastes the reviewer's.
- **Fixes are scoped.** One finding = one small, targeted edit. If a "fix" starts growing tentacles, it's a user-decision finding, not a fix.
- **Be explicit about what you didn't do.** Dismissed, downgraded, deferred — each gets its own entry with a concrete reason. The reviewer's trust comes from visibility, not from a clean surface.
- **Stale comments are common.** Comments from CI or earlier review rounds are often against a base that's moved. When validating, you're always checking the current state — note in the reply when a comment appears to be against stale code ("since this comment was written, the function has been refactored to X, which resolves this concern").
- **Tone matches the project.** Match how the team normally replies on MRs — formal if they're formal, terse if they're terse. The skill's structure is fixed; the voice is not.

## Edge cases

- **All findings dismissed.** Still produce the full reply — a reviewer seeing "no changes" with no explanation won't approve. Each dismissal needs its counter-evidence, and the summary should acknowledge the review was read seriously.
- **Zero findings parsed.** Escalate: show the user what you extracted from the input and ask them to clarify format.
- **Validator output malformed.** If a validator returns without a verdict, re-dispatch once; if it fails again, mark the finding "couldn't validate cleanly — flagging for your review" in the reply and surface the raw output so the user / reviewer can decide.
- **Very large comment count (>20).** Still dispatch in parallel. The reply may need a "grouped" section if many comments resolve to the same edit — combine them in one entry listing all commenters.
- **Findings not in the diff.** If a comment cites code outside the MR's changed files, validate it anyway (the reviewer may have followed a call chain), but in the reply note "out of this MR's diff" and propose deferring if appropriate.
- **Reviewer is partially right.** Very common — the concern is valid but the proposed fix isn't. Fix the real concern your way, and in the reply explain why your fix addresses it better than the literal suggestion.
