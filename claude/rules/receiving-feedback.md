---
name: receiving-feedback
description: How to process user feedback, code review comments, and corrections — verify independently, propagate changes, fix exactly what's needed
alwaysApply: true
---

# Receiving Feedback

When the user gives feedback, corrections, or review comments on your work:

1. **Verify independently** — don't assume feedback is correct just because it sounds reasonable. Trace through the code or re-read the doc to confirm the issue exists before changing anything.

2. **Understand the full impact** — a change to one place likely affects related code, sections, or tests. After making a change, re-read the surrounding context and propagate to all affected areas. For spec edits: sections are interdependent (goals → requirements → design → test plan).

3. **Fix exactly what's needed** — don't bundle "improvements", "defense-in-depth", or "while I'm here" changes into the fix. If you spot a separate issue, flag it explicitly rather than silently folding it in.
