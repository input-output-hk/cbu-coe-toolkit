# ADR-002: Adopt AAMM v3 Two-Axis Architecture

**Date:** 2026-03-17
**Status:** Accepted
**Context session:** v3 model spec design, comparison of v1 single-axis and v2 formula-based approaches

## Context

v1 measured AI adoption only — repos with excellent engineering but no AI config scored Stage 0 with no credit for their readiness. v2 added Readiness (R1-R4 pillars) but used continuous 0-100 scoring for Adoption, which proved over-engineered: 35 formula definitions, hard to reproduce, and confusing when a "progress score" contradicted cumulative stage assignments.

The model needed to:
1. Credit codebase quality independently of AI adoption (Readiness axis)
2. Keep actionable, reproducible stage assignments (not continuous scores)
3. Provide within-stage granularity for tracking progress between monthly scans
4. Cover cross-cutting AI governance concerns (multi-tool, orchestration, policy)

## Decision

Adopt v3: a two-axis model merging v2's Readiness pillars with v1's SDLC-dimension stages.

Key choices:
- **AI Readiness stays in AAMM, not CMM.** The quadrant model requires co-location. CMM is broader (organizational capability); Readiness is specifically about AI-collaboration suitability. Overlap is acceptable if explicitly framed.
- **Adoption uses stages + sub-levels (Low/Mid/High), not continuous 0-100.** Sub-levels give 90% of v2's granularity at 30% of the complexity. They map cleanly to 0-100 for composite calculation.
- **7th dimension: AI Practices & Governance.** Multi-tool config, governance, orchestration don't belong in any single SDLC dimension. Labeled "cross-cutting."
- **Two-condition Stage 1 gate for all dimensions.** Requires both practice active (Condition A) AND AI config covering that dimension (Condition B). More rigorous than v1 (config-only). No backward-compatibility concern since model not yet introduced to org.
- **Next Steps = always top 3, ordered by impact/effort ratio.** Creates a flywheel: scan → 3 actions → progress → scan → 3 actions.
- **Learning signals enrich sub-levels, not a separate axis.** static/evolving/self-improving per dimension.

## Consequences

- New scoring methodology documents needed (adoption-scoring.md, readiness-scoring.md) — more complex than v1's single scoring.md.
- v1 and v2 directories preserved as reference but deprecated.
- Agent scoring requires more judgment (sub-levels) — reproducibility achieved through mandatory evidence recording.
- Monthly scans take longer (Readiness requires codebase structure analysis, not just AI config detection).
- Org-level summary is richer (quadrant distribution, portfolio view, trend tracking).
