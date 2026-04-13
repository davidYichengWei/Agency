---
name: measurement-driven-analysis
description: Require measurement and causal verification before proposing fixes — applies to performance optimization, RCA, and any diagnosis where hypotheses are involved
alwaysApply: true
---

# Measurement-Driven Analysis

When diagnosing performance issues, bugs, or any problem where you form hypotheses:

## The cycle is non-negotiable

```
Hypothesize → Measure → Verify causation → Optimize → Measure again
```

Never skip a step. Never propose fixes for unverified hypotheses. Never ask the user to judge what you can measure yourself.

## Rules

1. **Hypotheses are not conclusions.** A plausible explanation is not a confirmed root cause. When you identify a likely mechanism, your next action is to instrument or measure — not to present "options to fix."

2. **Verify before proposing.** Do not present optimization options based on unverified assumptions. If you think the bottleneck is write queue contention, prove it with data (queue depth, write latency, contention metrics) before suggesting solutions.

3. **Direct causation, not correlation.** "X happened and Y was slow" is not root cause. You need the causal chain: X causes Y because Z, measured here. Heuristics and educated guesses are starting points for investigation, not endpoints.

4. **Don't delegate verification to the user.** If you can add instrumentation, run a profiler, check metrics, or design an experiment to confirm your hypothesis — do it. Only escalate to the user when verification requires access or knowledge you don't have.

5. **Measure the effect.** After applying a fix, measure to confirm the improvement matches your prediction. If it doesn't, your model of the problem was wrong — go back to step 1.

6. **Design a falsification test before committing to an optimization.** Before you invest weeks implementing a fix for "X is the bottleneck," ask: *what one experiment would tell me X is NOT the bottleneck?* If you can't name one, your hypothesis is unfalsifiable and you're about to build on a guess. Examples of real falsification tests that take <1 day:
   - "Is the 10 Gbps NIC the QPS ceiling?" → rate-limit eth1 to 5 Gbps with `tc tbf` and see if QPS halves. If it stays flat, NIC isn't binding.
   - "Is it CPU-bound?" → pin half the cores offline and see if QPS halves.
   - "Is it lock contention?" → run at 2× the concurrency and see whether latency rises more than throughput.

   Running the falsification test cheaply is almost always better than shipping the optimization and discovering post-hoc that the hypothesis was wrong. Metrics that are *near-saturated* (e.g., avg TX at 94% of link capacity) are correlation, not proof — near-saturation of X and "X is the binding constraint" are different claims, and only the falsification test distinguishes them.

## Anti-patterns

- "The 22ms is likely caused by X. Options: (a) try Y, (b) try Z" — proposing fixes without verifying X
- "Increasing pool size should help because..." — predicting without measuring
- "Want me to add instrumentation to verify?" — asking permission to do what you should do by default
- Presenting a hypothesis as a finding: "The gap is..." vs. "I hypothesize the gap is..."
- "X is at 94% of capacity, so X is the bottleneck" — near-saturation ≠ binding. Run the falsification test (rule 6).
- Implementing before asking "what experiment would prove me wrong?"
