# KB Proposals — Learning Scan: input-output-hk/plu-stan

> **Scan date:** 2026-03-30
> **Scan type:** Learning
> **Ecosystem:** Haskell
> **Repo:** input-output-hk/plu-stan
> **Agent:** Claude Opus 4.6
> **Purpose:** Validate seed KB patterns against repo evidence, propose new patterns

---

**DATA NOT COLLECTED.** No data directory found at `/tmp/aamm-input-output-hk-plu-stan/` or any variant. The data collection step did not run for this repo. All assessments below are based on the user-provided metadata only (1 package, Haskell, small repo).

---

## Seed Pattern Validation

### hs_haddock_generation — UNABLE TO VALIDATE

```yaml
id: hs_haddock_generation
validation: unable_to_validate
confidence: LOW
```

No data collected. User indicated this is a small 1-package Haskell repo. Haddock applicability is likely but cannot be confirmed without examining the repo's CI workflows, source files, and documentation state.

### hs_quickcheck_corner_cases — UNABLE TO VALIDATE

```yaml
id: hs_quickcheck_corner_cases
validation: unable_to_validate
confidence: LOW
```

No data collected. Cannot determine whether QuickCheck is used or Arbitrary instances exist.

### All other Haskell patterns — UNABLE TO VALIDATE

No data to assess.

---

## Cross-Cutting Patterns

### cc_claude_md_context — UNABLE TO VALIDATE

No data collected.

### cc_aiignore_boundaries — UNABLE TO VALIDATE

No data collected.

---

## New Pattern Proposals

None — insufficient data.

---

## Summary

| Seed Pattern | Status | Confidence |
|---|---|---|
| hs_haddock_generation | UNABLE TO VALIDATE | LOW |
| hs_quickcheck_corner_cases | UNABLE TO VALIDATE | LOW |

**Action required:** Re-run data collection for input-output-hk/plu-stan before this kb-proposals can be completed.
