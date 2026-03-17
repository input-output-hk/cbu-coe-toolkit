<!-- Scope: Decision record for adopting a three-layer knowledge capture system across agent sessions. -->

# ADR-001: Three-Layer Knowledge Capture for Agent Sessions

**Date:** 2026-03-13
**Status:** Accepted
**Context session:** Initial repo scaffolding — discussing how to preserve learnings across agent interactions.

## Context

Every conversation between a human operator and an AI agent produces insights — edge cases, technical discoveries, design rationale — that are lost when the session ends. The next agent starts from zero plus whatever static content exists in repo files. CLAUDE.md provides starting context but has no mechanism for accumulated operational knowledge.

The system needs to capture learnings through agents proposing updates as part of their normal workflow, rather than depending on manual documentation effort.

## Decision

Adopt a three-layer knowledge capture system in both `cbu-coe` and `cbu-coe-toolkit`:

1. **`docs/decisions/`** — Architecture Decision Records (ADRs). One file per significant decision, numbered sequentially. For *why* choices were made. Agents read these to understand constraints they should not re-litigate.

2. **`docs/learnings.md`** — Append-only operational learnings log. Dated entries for insights, edge cases, things that failed, things that surprised us. For *what we discovered along the way*.

3. **Session handoff protocol in CLAUDE.md** — Every agent is instructed: before ending a session, propose specific additions to `learnings.md` and/or new ADR files. The human operator approves or edits before committing. This makes knowledge capture automatic.

Each file in `docs/` carries a 1–2 line scope comment at the top explaining what belongs there.

## Consequences

- Every agent session has a lightweight "save what you learned" step at the end.
- Future agents get richer context beyond just CLAUDE.md — they can read decisions and learnings.
- Trade-off: learnings.md will grow over time and may need periodic summarization or archiving.
- Trade-off: agents may over-propose entries. The human review step prevents noise accumulation.
