# ADR-005: Union-based adoption counting and V1 threshold

**Date:** 2026-03-20 · **Status:** Accepted
**Applies to:** `scripts/aamm/score-adoption.sh`, `models/ai-augmentation-maturity/adoption-scoring.md`, `scripts/aamm/score-readiness.sh`

## Rule

1. **Adoption content-categories are counted across the union of all AI config files**, not per-file. An index-style CLAUDE.md that references `.claude/` files scores the same as a monolithic CLAUDE.md. We measure total coverage, not per-file density.

2. **V1 test/source ratio threshold stays at 0.7** for all languages. Test quality is captured by V2 (test categorization) and domain profiles (generator discipline), not V1.

## Anti-patterns

- **Per-file scoring:** Counting categories in each file separately and taking the max. This penalizes DRY architecture (e.g., lace-platform's `.claude/` with 30+ organized docs).
- **Language-specific V1 thresholds:** Lowering V1 for property-testing ecosystems. Property test quality belongs in V2 sub-signals, not V1 ratio adjustment.

## Context

D1 (session 3): lace-platform scored 9.9 adoption because score-adoption.sh only read the best single AI config file. With union-based counting across all `.claude/` files: 80.00. Validated session 4.

D5 (session 3): Considered lowering V1 to 0.4 for Haskell (property tests cover more space). Decided against — V2 and domain profile already capture test quality. V1 is a volume signal.

## Consequences

- **Changed:** score-adoption.sh, adoption-scoring.md
- **Must maintain:** Any new scoring that reads AI config files must use union-based approach.
