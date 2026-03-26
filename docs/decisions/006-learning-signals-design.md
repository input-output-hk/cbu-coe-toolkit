# ADR-006: Learning signals design (v1)

**Date:** 2026-03-21 · **Status:** Accepted
**Applies to:** future `scripts/aamm/score-learning.sh` (not yet implemented)

## Rule

1. Learning state is tracked **per-repo, not per-dimension**. GitHub data doesn't decompose by SDLC dimension.
2. **90-day window** for static/evolving boundary (aligns with quarterly cycle).
3. **≥2 commits to AI config files** in window to qualify as "evolving" (filters noise).
4. **Two states for v1: static / evolving.** Self-improving (third state) deferred to v2.
5. **"Static" is descriptive, not pejorative.** A stable, well-tuned config is fine.

## Anti-patterns

- **Per-dimension attribution:** Assigning learning state per adoption dimension. AI config serves all dimensions simultaneously.
- **Content-diff analysis:** Comparing file content between commits. Too fragile. Commit count is simpler and sufficient.
- **180-day window:** Too generous for "learning." 180 days answers "is this dead?" not "is this evolving?"

## Context

Session 5 brainstorming. Head of CoE reviewer concurred on per-repo over per-dimension. Self-improving state requires temporal correlation analysis (outcomes → config changes) that needs scan history — deferred to v2.

## Consequences

- **Not yet implemented.** This ADR records design decisions for future implementation.
- **Must maintain:** When implementing, use commit count (not content diff) and 90-day window.
