# KB Proposals — Learning Scan: IntersectMBO/cardano-base

> **Scan date:** 2026-03-30
> **Scan type:** Learning
> **Ecosystem:** Haskell
> **Repo:** IntersectMBO/cardano-base (master)
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
- 3 Arbitrary modules found:
  - `cardano-base/testlib/Test/Cardano/Base/Arbitrary.hs` — Arbitrary instances for IPv4, IPv6
  - `cardano-binary/testlib/Test/Cardano/Binary/Arbitrary.hs` — rich Arbitrary instance for CBOR Term with custom shrinking, edge-case-aware generators (genHalf filters infinities/NaN/denormals), boundary values (firstUnreservedTag, simple values list)
  - `cardano-slotting/testlib/Test/Cardano/Slotting/Arbitrary.hs` — slot/epoch type generators
- QuickCheck used extensively across 39 test files spanning 8 packages
- Well-structured testlib/ pattern: each package exports Arbitrary instances via its own testlib sub-library
- Sophisticated generator techniques: `cardano-binary` uses `scale (\`div\` 5) arbitrary` for recursive Term generation, custom Half float generator with filtering

**Gaps observed:**
- `cardano-crypto-class/testlib/Test/Crypto/KES.hs` (32K bytes) uses QuickCheck + Hspec but generators are primarily in `Test/Crypto/Instances.hs` and `Test/Crypto/Util.hs` — not obvious from Arbitrary file naming
- Several packages lack explicit testlib Arbitrary files: `heapwords`, `base-deriving-via`, `orphans-deriving-via`, `cardano-git-rev`, `cardano-crypto-peras` (though some are too small to warrant them)

### hs_haddock_generation — VALIDATED

```yaml
id: hs_haddock_generation
validation: confirmed
confidence: HIGH
```

**Evidence:**
- 12 cabal packages with public API surface
- Dedicated Haddock CI workflow: `.github/workflows/gh-pages.yml` — builds and deploys to GitHub Pages
- Published at `base.cardano.intersectmbo.org` (CNAME in workflow)
- Haddock build script: `scripts/haddocks.sh haddocks all`
- Complex type signatures throughout — cryptographic primitives (`Cardano.Crypto.DSIGN`, `Cardano.Crypto.KES`, `Cardano.Crypto.VRF`) are exactly the kind AI documents well
- cardano-crypto-class alone has 30+ source directories under `src/Cardano/Crypto/`

**Gaps observed:**
- No evidence of Haddock coverage metrics — would need to sample source files for doc comment density
- Crypto modules (DSIGN, KES, VRF, Hash) have complex type families and constraints that benefit from explanatory docs

### hs_debug_state_transitions — NOT APPLICABLE

```yaml
id: hs_debug_state_transitions
validation: not_applicable
confidence: HIGH
```

This is a base library repo providing cryptographic primitives, binary serialization, and slotting types. No STS framework, no state machine logic, no era-indexed transition rules. State transition patterns are in downstream repos (cardano-ledger, cardano-node).

### hs_cross_era_review — NOT APPLICABLE

```yaml
id: hs_cross_era_review
validation: not_applicable
confidence: HIGH
```

No era-indexed architecture. Packages are organized by domain (crypto, binary, slotting) not by era. No era directories or era type parameters in the tree.

### hs_cddl_conformance — NOT APPLICABLE

```yaml
id: hs_cddl_conformance
validation: not_applicable
confidence: HIGH
```

No .cddl files in repo. Binary serialization is present (cardano-binary) but conformance testing against CDDL schemas happens in downstream repos that consume these types.

### hs_agda_conformance — NOT APPLICABLE

No formal spec, no Agda code, no conformance test infrastructure.

### hs_imp_test_generation — NOT APPLICABLE

No Imp test framework. Testing uses HSpec + QuickCheck directly.

### hs_constrained_generators — NOT APPLICABLE

No constrained-generators dependency. Standard QuickCheck Arbitrary instances only.

### hs_era_transition_docs — NOT APPLICABLE

No era architecture.

---

## Cross-Cutting Patterns

### cc_claude_md_context — CONFIRMED ABSENT

No CLAUDE.md, .cursorrules, AGENTS.md, or copilot-instructions.md. No AI config files detected. No AI-attributed commits. This is an opportunity for a repo that downstream projects depend on heavily.

### cc_aiignore_boundaries — CONFIRMED APPLICABLE

Security-critical code paths:
- `cardano-crypto-class/` — cryptographic primitives (DSIGN, KES, VRF, Hash, EllipticCurve BLS12-381)
- `cardano-crypto-praos/` — VRF implementation with C bindings (`cbits/` directory)
- `cardano-crypto-peras/` — Peras crypto
- No .aiignore exists. No AI tools currently in use (no AI commits detected), but if adopted, crypto paths must be protected.

---

## New Pattern Proposals

None. The seed patterns that apply (hs_quickcheck_corner_cases, hs_haddock_generation) are well-matched. The repo is a foundational library — its patterns are consumed by downstream repos rather than generating novel patterns.

---

## Summary

| Seed Pattern | Status | Confidence |
|---|---|---|
| hs_quickcheck_corner_cases | VALIDATED | HIGH |
| hs_haddock_generation | VALIDATED | HIGH |
| hs_debug_state_transitions | NOT APPLICABLE | HIGH |
| hs_cross_era_review | NOT APPLICABLE | HIGH |
| hs_cddl_conformance | NOT APPLICABLE | HIGH |
| hs_agda_conformance | NOT APPLICABLE | HIGH |
| hs_imp_test_generation | NOT APPLICABLE | HIGH |
| hs_constrained_generators | NOT APPLICABLE | HIGH |
| hs_era_transition_docs | NOT APPLICABLE | HIGH |

| Cross-Cutting | Status |
|---|---|
| cc_claude_md_context | ABSENT — opportunity |
| cc_aiignore_boundaries | APPLICABLE — crypto paths need protection |
