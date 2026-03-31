# KB Proposals — Learning Scan: input-output-hk/io-sim

> **Scan date:** 2026-03-30
> **Scan type:** Learning
> **Ecosystem:** Haskell
> **Repo:** input-output-hk/io-sim (main)
> **Agent:** Claude Opus 4.6
> **Purpose:** Validate seed KB patterns against repo evidence, propose new patterns

---

## Seed Pattern Validation

### hs_quickcheck_corner_cases — VALIDATED

```yaml
id: hs_quickcheck_corner_cases
validation: confirmed
confidence: HIGH
```

**Evidence:**
- Small focused library (2 packages: io-classes, io-sim) but extremely test-heavy
- Test files total ~155K bytes across 12 files — high test-to-source ratio for a library of this size
- `io-sim/test/Test/Control/Monad/IOSim.hs` (51K bytes) and `Test/Control/Monad/IOSimPOR.hs` (42K bytes) — massive property test suites
- `Test/Control/Monad/STM.hs` (27K bytes) — STM simulation tests
- `Test/Control/Monad/Utils.hs` (17K bytes) — shared test utilities/generators
- QuickCheck is the primary testing framework (visible in all test imports)
- The repo's core purpose is IO simulation for property testing — it is itself a QuickCheck infrastructure library

**Gaps observed:**
- No dedicated testlib/Arbitrary.hs files — generators appear to be inline in the large test modules
- No sampled Arbitrary files were collected, but the 17K Utils.hs likely contains shared generators

### hs_haddock_generation — VALIDATED

```yaml
id: hs_haddock_generation
validation: confirmed
confidence: HIGH
```

**Evidence:**
- Dedicated Haddock CI workflow: `.github/workflows/github-page.yml` — builds and deploys to GitHub Pages
- Uses `cabal haddock-project --prologue=README.haddock --hackage all`
- Converts README.md to Haddock format via pandoc before building
- Published as GitHub Pages with deploy-pages action
- 2 packages with public API: io-classes (typeclass abstractions for IO/STM/MVar) and io-sim (simulation implementation)
- CONTRIBUTING.md exists — signals project cares about documentation

**Gaps observed:**
- Small API surface (2 packages) but typeclasses with many methods benefit from detailed Haddock explaining semantics (especially for a simulation library where behavior differs from real IO)

### hs_debug_state_transitions — NOT APPLICABLE

```yaml
id: hs_debug_state_transitions
validation: not_applicable
confidence: HIGH
```

io-sim is an IO simulation framework, not a state machine system. It simulates concurrency primitives (STM, MVar, threads) for testing, but does not use STS-style state transitions.

### hs_cross_era_review — NOT APPLICABLE

No era architecture.

### hs_cddl_conformance — NOT APPLICABLE

No .cddl files. No serialization conformance testing.

### hs_agda_conformance — NOT APPLICABLE

No formal spec or Agda code.

### hs_imp_test_generation — NOT APPLICABLE

No Imp test framework.

### hs_constrained_generators — NOT APPLICABLE

No constrained-generators dependency.

### hs_era_transition_docs — NOT APPLICABLE

No era architecture.

---

## Cross-Cutting Patterns

### cc_claude_md_context — CONFIRMED ABSENT

No CLAUDE.md, .cursorrules, AGENTS.md, or copilot-instructions.md. No AI config files. No AI-attributed commits. CONTRIBUTING.md and SECURITY.md exist. For a simulation testing library, a CLAUDE.md explaining the typeclass hierarchy and how io-sim differs from real IO would be valuable.

### cc_aiignore_boundaries — NOT APPLICABLE

No security-critical code paths. io-sim is a testing library — it simulates IO for property tests. No crypto, no consensus logic, no financial transactions. No AI tools in use.

---

## New Pattern Proposals

None. This is a small, focused testing infrastructure library. The two applicable patterns (hs_quickcheck_corner_cases, hs_haddock_generation) cover the relevant opportunities.

---

## Summary

| Seed Pattern | Status | Confidence |
|---|---|---|
| hs_quickcheck_corner_cases | VALIDATED | HIGH |
| hs_haddock_generation | VALIDATED | HIGH |
| hs_debug_state_transitions | NOT APPLICABLE | HIGH |
| hs_cross_era_review | NOT APPLICABLE | HIGH |
| hs_cddl_conformance | NOT APPLICABLE | HIGH |

| Cross-Cutting | Status |
|---|---|
| cc_claude_md_context | ABSENT — opportunity |
| cc_aiignore_boundaries | NOT APPLICABLE |
