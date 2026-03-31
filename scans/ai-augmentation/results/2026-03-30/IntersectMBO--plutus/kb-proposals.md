# KB Proposals — Learning Scan: IntersectMBO/plutus

> **Scan date:** 2026-03-30
> **Scan type:** Learning
> **Ecosystem:** Haskell
> **Repo:** IntersectMBO/plutus (master)
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
- 3 Arbitrary/generator modules sampled:
  - `cardano-constitution/test/PlutusLedgerApi/V3/ArbitraryContexts.hs` — rich generators for ScriptContext, TxInfo, GovernanceAction with domain-specific invariants (parameter change contexts, treasury withdrawals)
  - `plutus-core/plutus-core/test/Generators/QuickCheck/Utils.hs` — multiSplit generators, Data generation with controlled leaf counts (`test_arbitraryDataExpectedLeafs`)
  - `plutus-core/cost-model/budgeting-bench/Generators.hs` — benchmark data generators
- 260+ test files across 13 packages — extensive property testing
- Sophisticated generator infrastructure: `PlutusCore.Generators.QuickCheck.Builtin`, custom Data generators with spine-based generation, `ArbitraryContexts` module generating valid Plutus script contexts
- `plutus-core/plutus-ir/test/PlutusIR/Generators/QuickCheck/Tests.hs` (10K bytes) — dedicated QuickCheck generator tests

**Gaps observed:**
- Generator quality varies: ArbitraryContexts uses domain-specific generation; other modules use simpler `arbitrary` derivations
- No evidence of systematic shrinking review across the 260+ test files

### hs_haddock_generation — VALIDATED

```yaml
id: hs_haddock_generation
validation: confirmed
confidence: HIGH
```

**Evidence:**
- 13 cabal packages (9 core + 4 doc/support) with extensive public API
- Dedicated Haddock CI workflow: `.github/workflows/haddock-site.yml`
- Combined Haddock build: `./scripts/combined-haddock.sh _haddock all` (60-90 min build per copilot-instructions.md)
- Complex type signatures throughout — Plutus IR, typed/untyped Plutus Core, type-level evaluation
- Large public API: `plutus-ledger-api` exports versioned APIs (V1, V2, V3) with Data representations

**Gaps observed:**
- The copilot-instructions.md explicitly calls out Haddock generation as a 60-90 minute build — this is a real operational concern
- As a programming language implementation, the type system modules have particularly complex signatures needing documentation

### hs_debug_state_transitions — NOT APPLICABLE

```yaml
id: hs_debug_state_transitions
validation: not_applicable
confidence: HIGH
```

Plutus is a programming language implementation, not a state machine system. It has an evaluator (CEK machine) which processes terms, but this is computation reduction, not STS-style state transitions. No STS framework, no Rules/ directories, no Transition.hs modules.

### hs_cross_era_review — NOT APPLICABLE

```yaml
id: hs_cross_era_review
validation: not_applicable
confidence: MEDIUM
```

Plutus has versioned APIs (V1, V2, V3 in plutus-ledger-api) which are conceptually related to ledger eras, but the architecture is version-additive (V3 adds to V2), not era-replacement (unlike cardano-ledger where each era replaces the previous). No era-indexed type parameters, no era directories.

### hs_cddl_conformance — NOT APPLICABLE

```yaml
id: hs_cddl_conformance
validation: not_applicable
confidence: HIGH
```

No .cddl files. CBOR serialization exists (`plutus-core/plutus-core/test/CBOR/DataStability.hs` at 56K bytes is a stability test) but conformance is tested via golden tests rather than CDDL schema validation.

### hs_agda_conformance — VALIDATED

```yaml
id: hs_agda_conformance
validation: confirmed
confidence: HIGH
```

**Evidence:**
- `plutus-metatheory/` — full Agda mechanized metatheory (formal proofs of the Plutus Core type system and evaluator)
- `plutus-conformance/` — dedicated conformance test package comparing Haskell vs Agda implementations
  - `plutus-conformance/agda/Spec.hs` — Agda conformance test runner
  - `plutus-conformance/haskell-steppable/Spec.hs` — Haskell steppable evaluator conformance
- copilot-instructions.md documents: "When modifying `.lagda` files, regenerate Haskell modules with `generate-malonzo-code`"
- `.github/workflows/metatheory-site.yml` — dedicated CI for metatheory documentation
- The copilot-instructions.md workflow: "When Modifying the Evaluator: 1. Make changes in untyped-plutus-core/ 2. Update corresponding Agda code in plutus-metatheory/src/ 3. Regenerate Haskell from Agda 4. Test conformance extensively"

**This is the strongest validation of hs_agda_conformance outside cardano-ledger.** The pattern was proposed from cardano-ledger; plutus confirms it applies to any repo with Agda formal verification.

### hs_imp_test_generation — NOT APPLICABLE

No Imp test framework. Testing uses Tasty + QuickCheck + HSpec.

### hs_constrained_generators — NOT APPLICABLE

No constrained-generators dependency. Generators use standard QuickCheck plus custom infrastructure in `PlutusCore.Generators.QuickCheck`.

### hs_era_transition_docs — NOT APPLICABLE

No era architecture.

---

## Cross-Cutting Patterns

### cc_claude_md_context — PARTIALLY PRESENT

AI config files detected:
- `.cursorignore` — excludes generated/golden files (`.uplc`, `.plc`, `.pir`, `.golden`, `.json`, `.js`, etc.)
- `.github/copilot-instructions.md` — **extensive** (335 lines): Nix setup, build commands with timing (45-90 min), test suite details, package structure, troubleshooting, development workflow examples

This is one of the most comprehensive AI configuration files in the Cardano ecosystem. It functions as a de facto CLAUDE.md. Covers: build environment (Nix mandatory), timing constraints (NEVER CANCEL), package structure, test strategies, formatting requirements, HLS configuration, troubleshooting.

**Gap:** File is `.github/copilot-instructions.md` (Copilot-specific path). A `CLAUDE.md` or `AGENTS.md` at root would make this accessible to all AI tools. Content quality is HIGH.

### cc_aiignore_boundaries — CONFIRMED APPLICABLE

Security-relevant paths:
- `plutus-core/` — core language evaluator (CEK machine) — correctness is consensus-critical
- `plutus-ledger-api/` — on-chain script evaluation interface — serialization changes break consensus
- `cardano-constitution/` — Cardano governance constitution validator
- `.cursorignore` exists but covers generated files, not security-critical paths
- 5 AI-attributed commits from Copilot Autofix — AI is actively modifying code without explicit trust boundaries on security-critical paths

---

## New Pattern Proposals

### Conformance test generation for language evaluator

```yaml
id: hs_evaluator_conformance_tests
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30
source_scan: IntersectMBO/plutus (learning, 2026-03-30)

applies_when:
  - Language evaluator with formal metatheory
  - Multiple evaluation backends (Haskell CEK, Agda, steppable)
  - Conformance tests compare evaluation results across backends

value: HIGH
value_context: "Generating conformance test programs that exercise specific evaluator behaviors (error cases, resource limits, type boundaries) is tedious — AI can systematically generate programs targeting edge cases"
effort: Medium
evidence_to_look_for:
  - plutus-conformance/ or similar conformance test directory
  - Multiple evaluator backends
  - .uplc or .plc test programs as golden inputs
  - Cost model benchmarks (plutus-benchmark/)
seen_in:
  - repo: IntersectMBO/plutus
    outcome: "plutus-conformance/ package with agda/ and haskell-steppable/ test runners. 46K+ bytes of benchmark test specs in plutus-benchmark/uplc-evaluator/test/Spec.hs"
evidence_from_scan:
  - plutus-conformance/agda/Spec.hs — Agda conformance test runner
  - plutus-conformance/haskell-steppable/Spec.hs — steppable evaluator conformance
  - plutus-benchmark/uplc-evaluator/test/Spec.hs (46K) — benchmark evaluation tests

readiness_criteria:
  - criterion: "Multiple evaluator backends exist"
    type: Objective
    check: "At least 2 evaluation backends (e.g., Haskell CEK + Agda) with shared test interface"
  - criterion: "Conformance test infrastructure exists"
    type: Objective
    check: "Test runner that compares results across backends"
  - criterion: "Test program format is well-defined"
    type: Objective
    check: ".uplc or .plc file format for test programs"
```

### Golden test regeneration assistance

```yaml
id: hs_golden_test_regen
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30
source_scan: IntersectMBO/plutus (learning, 2026-03-30)

applies_when:
  - Large golden test suite (>100 golden files)
  - Golden tests break frequently due to output format changes
  - Regeneration is expensive (45-75 min for plutus)

value: MEDIUM
value_context: "AI can review golden test diffs to determine whether changes are intentional (new behavior) vs accidental (regression) — saving review time on large regeneration PRs"
effort: Low
evidence_to_look_for:
  - scripts/regen-goldens.sh or equivalent
  - .golden files in test directories
  - .cursorignore/.gitignore entries for golden file types
  - PRs with large golden file diffs
seen_in:
  - repo: IntersectMBO/plutus
    outcome: ".cursorignore excludes 20+ golden file extensions. scripts/regen-goldens.sh takes 45-75 minutes."

readiness_criteria:
  - criterion: "Golden test regeneration script exists"
    type: Objective
    check: "Script that regenerates all golden files in repo"
  - criterion: "Golden files are version-controlled"
    type: Objective
    check: ".golden or equivalent files tracked in git"
```

---

## Summary

| Seed Pattern | Status | Confidence |
|---|---|---|
| hs_quickcheck_corner_cases | VALIDATED | HIGH |
| hs_haddock_generation | VALIDATED | HIGH |
| hs_debug_state_transitions | NOT APPLICABLE | HIGH |
| hs_cross_era_review | NOT APPLICABLE | MEDIUM |
| hs_cddl_conformance | NOT APPLICABLE | HIGH |
| hs_agda_conformance | VALIDATED | HIGH |
| hs_imp_test_generation | NOT APPLICABLE | HIGH |
| hs_constrained_generators | NOT APPLICABLE | HIGH |
| hs_era_transition_docs | NOT APPLICABLE | HIGH |

| New Proposal | ID | Value |
|---|---|---|
| Evaluator conformance test generation | hs_evaluator_conformance_tests | HIGH |
| Golden test regeneration assistance | hs_golden_test_regen | MEDIUM |

| Cross-Cutting | Status |
|---|---|
| cc_claude_md_context | PARTIALLY PRESENT — .github/copilot-instructions.md (335 lines, high quality) |
| cc_aiignore_boundaries | APPLICABLE — consensus-critical evaluator + 5 AI commits without trust boundaries |

**Key finding:** Plutus is the only repo in this batch with active AI adoption (5 Copilot Autofix commits, .cursorignore, copilot-instructions.md). The copilot-instructions.md is exemplary and could serve as a template for other Cardano repos. The hs_agda_conformance pattern is strongly validated here — the Agda metatheory is a core part of the development workflow, not just an academic exercise.
