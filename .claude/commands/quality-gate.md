---
name: quality-gate
description: >
  Universal quality gate for all CBU work — code, documents, plans, analysis,
  architecture, QA. Scores on 4 universal dimensions + domain extensions.
  Iterates to 9.0+ before delivering. Delivers the improved version directly,
  no approval step. Skip for trivial changes: typo fixes, simple lookups,
  single-line edits.
---

# Quality Gate

Claude defaults to ~7/10. This skill enforces 9.0+ on every non-trivial output
before delivery — code, documents, plans, architecture decisions, QA artefacts.

The trick: ask Claude to score its own work, then ask what it would change to
reach 9+. It surfaces improvements it knew about but didn't apply. The gap
between 7 and 9 is where quality lives.

---

## When This Runs

After completing any non-trivial task. Skip for: typo fixes, single-line edits,
simple lookups, direct factual questions.

---

## Pre-Task Checklist

Before producing output on non-trivial tasks:

- Is the approach clear? If not — outline first, then implement.
- Is the task complex (3+ moving parts)? If yes — break into steps, do not
  attempt in a single pass.
- Is an example of good output available? If yes — reference it explicitly
  before starting.

---

## Self-Scoring Rubric

### Universal dimensions (always scored, all task types)

| Dimension | What it measures |
|---|---|
| **Correctness** | Factually and logically right; edge cases handled |
| **Completeness** | All requirements met, including implicit ones |
| **Clarity** | Clear to the target audience — engineer, PM, or stakeholder |
| **User Intent** | Solves what was meant, not just what was literally asked |

### Domain extensions (activate based on task type)

**Code / technical implementation**
- Code Quality — readable, idiomatic, a senior engineer approves without comments
- Performance — efficient for the context, no obvious waste
- Security — no vulnerabilities introduced, inputs validated

**Architecture / design decisions**
- Trade-off Analysis — alternatives considered, reasoning explicit
- Simplicity — no unnecessary complexity introduced
- Future-proofing — handles foreseeable change without full rewrite

**Documents / plans / requirements**
- Actionability — reader knows exactly what to do next
- Risk Coverage — failure modes and mitigations identified
- Stakeholder Alignment — works for all audiences named in the task

**QA / testing**
- Coverage — happy path, edge cases, and failure paths addressed
- Reproducibility — steps are deterministic, environment assumptions stated
- Edge Case Handling — boundary conditions explicit, not assumed

---

## Scoring Rules

1. Score the 4 universal dimensions on every task.
2. Identify the task type → add the relevant domain dimensions.
3. Mark a dimension N/A only when it genuinely cannot apply.
4. If overall average ≥ 9.0 → deliver output + show scorecard.
5. If overall average < 9.0 → identify specific improvements, implement them,
   re-score, then deliver the improved version.
6. Maximum 2 improvement iterations. If still below 9.0 after 2 passes,
   deliver the best version and flag remaining gaps explicitly.

**Never surface the intermediate draft. Never ask for approval before
improving. Deliver the 9.0+ version directly.**

## Threshold

9.0 to complete. A first pass rarely hits 9.0+ on everything — that is
expected and correct. The point is the second pass, not the first score.

---

## Red Flags (score inflation patterns)

If you see these, the self-scoring is not honest:

| Pattern | Problem |
|---|---|
| Every dimension 9.0+ on first pass | Inflation — push back on yourself |
| All scores identical across dimensions | Lazy scoring — each dimension measures something different |
| N/A on 3+ dimensions | Wrong domain extension activated, or avoiding low scores |
| Scores jump without actual changes | Narrative improvement, not real improvement |
| Improvements proposed as full rewrites | Response is disproportionate — improvements must be targeted |

---

## Second-Pass Techniques

Use when the task warrants it. Each forces a deliberate second pass from a
different angle.

**Expose hidden shortcuts**
Ask: "What did you simplify, ignore, or assume?"
Claude is aware of trade-offs it makes but will not mention them unless asked.
When to use: complex tasks where completeness is critical.

**Challenge the first idea**
Ask: "What alternatives did you consider and why did you reject them?"
If Claude cannot give a convincing answer, it went with the first reasonable
idea, not the best one.
When to use: architecture decisions, design choices, strategy recommendations.

**Flip perspective**
Ask: "Now critique this as a sceptical senior engineer."
The shift from helper mode to critic mode surfaces issues it would not otherwise
mention.
When to use: code reviews, proposals, anything going to stakeholders.

**3 variants**
Ask: "Give me 3 different approaches."
Forces exploration beyond the most statistically probable path. The second or
third option is often better.
When to use: creative or design decisions — naming, architecture, copy,
problem-solving.

**Confidence score**
Ask: "How confident are you on this, from 1 to 10?"
Forces explicit acknowledgement of uncertainty. Reveals where Claude is on
solid ground and where it is guessing.
When to use: technical facts, data interpretation, recommendations where
accuracy matters.

---

## Session Hygiene

**Start fresh when quality drops.**
If responses become weaker, repetitive, or Claude forgets earlier context, the
context window is saturating. Before starting over, ask:
"Summarise the current state — files changed, decisions made, open issues —
as a prompt I can paste into a new conversation."
Clean handoff, no progress lost. Do this before context reaches 70%. At 90%
Claude is already working with a compressed view.

**Never paste secrets.**
API keys, tokens, passwords, PII — use placeholders or env variable references.
Once sent, cannot be unsent. Ask Claude to write code that reads from
environment variables from the start, never hardcoded values.

---

## Why This Works

LLMs structurally satisfice: they produce the most statistically probable
(good-enough) output rather than the best possible output. Any technique that
forces a deliberate second pass — evaluation, reflection, self-critique —
consistently produces better results than the first draft.

This is not peer review. It is the same model with the same blind spots. It
will not catch hallucinations or replace domain expertise. It adds a few
seconds per task. The trade-off is worth it for anything non-trivial.

---

## Credits

Built from a conversation in `#cbu-coe-chat` (March 2026):

- **Dorin Solomon** — self-scoring technique, tips catalog, CoE resource vision
- **Ivan Irakoze** — 7-dimension rubric, first skill implementation ([claude-self-score](https://github.com/augmentedivan/claude-self-score))
- **Dominik Guzei** — simplified command format (`improve.md`)
- **Stefano Leone** — skills + memory + hooks layered architecture
- **Konstantinos Kogkalidis, Piotr Krogulski** — critical feedback on self-review limitations
- **Sean Gillespie** — validation on test case generation
