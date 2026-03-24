# ADR-001: Three-Layer Knowledge Capture

**Date:** 2026-03-13
**Status:** Accepted
**Confidence:** High

## Context

Work across contributors and agent sessions produces insights — edge cases, technical discoveries, design rationale — that are lost when a session ends. The next contributor starts from whatever static content exists in repo files. CLAUDE.md provides starting context but has no mechanism for accumulated operational knowledge.

## Decision drivers

- Knowledge continuity across contributors without manual documentation overhead
- Lightweight capture that integrates into existing workflows
- Human review as quality gate before anything is committed

## Considered alternatives

| Option | Pros | Cons |
|---|---|---|
| **Three-layer system** | Structured, reviewable, low overhead | learnings.md grows over time |
| Wiki / Confluence only | Familiar to teams | Disconnected from code, no review gate |
| CLAUDE.md only | Simple | Grows unbounded, no separation of concerns |

## Decision

Adopt a three-layer knowledge capture system:

1. **`docs/decisions/`** — Architecture Decision Records. One file per significant decision. Captures *why* choices were made.
2. **`docs/learnings.md`** — Append-only operational insights log. Captures *what was learned along the way*.
3. **Session handoff protocol** — Contributors propose additions to `learnings.md` and/or new ADR files before ending a session. The repo owner approves before committing.

## Consequences

- **Positive:** Every session has a lightweight "capture what you learned" step. Future contributors get richer context.
- **Negative:** `learnings.md` will grow and may need periodic summarization or archiving.
- **Risks:** Over-contribution of low-value entries. Mitigated by human review gate.
