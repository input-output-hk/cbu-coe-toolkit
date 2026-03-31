# KB Proposals — Learning Scan: IntersectMBO/cardano-ledger

> **Scan date:** 2026-03-30
> **Scan type:** Learning
> **Ecosystem:** Haskell
> **Repo:** IntersectMBO/cardano-ledger (master)
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
- Arbitrary instances found per era: `eras/allegra/impl/testlib/Test/Cardano/Ledger/Allegra/Arbitrary.hs`, `eras/alonzo/impl/testlib/Test/Cardano/Ledger/Alonzo/Arbitrary.hs`, `eras/babbage/impl/testlib/Test/Cardano/Ledger/Babbage/Arbitrary.hs` (pattern repeats for all post-Byron eras)
- QuickCheck used extensively — `constrained-generators` repo pinned in cabal.project (specialized generator infrastructure)
- Formal spec conformance testing in `libs/cardano-ledger-conformance/` — Agda-extracted spec tested against Haskell impl
- Dijkstra era (newest, active development) has Arbitrary files being built — 2 AI-attributed commits from 2026-03-23 specifically added `plutusScriptGen` to dijkstra CDDL tests
- Imp tests (imperative property tests) exist per era per rule: `testlib/Test/Cardano/Ledger/{Era}/Imp/{Rule}Spec.hs`

**Gaps observed:**
- Dijkstra era `testlib/` is sparse compared to Conway — generators are being built but coverage is early
- No evidence of systematic shrinking implementation review across eras
- Byron-era generators (`Byron/Spec/Ledger/Core/Generators.hs`, `UTxO/Generators.hs`, `Update/Generators.hs`) use a different pattern than post-Shelley eras

**Proposed readiness criteria adjustment:**
- Add criterion: "constrained-generators or equivalent custom generator infrastructure exists" (this repo has its own generator library — more sophisticated than bare QuickCheck Arbitrary)
- Adjust check for "Formal spec exists" — this repo has Agda formal spec with conformance tests (`libs/cardano-ledger-conformance/`), not just inline spec comments

### hs_haddock_generation — VALIDATED

```yaml
id: hs_haddock_generation
validation: confirmed
confidence: MEDIUM
```

**Evidence:**
- 28 cabal packages in repo (eras + libs) — massive public API surface
- Haddock published at `cardano-ledger.cardano.intersectmbo.org` (linked in README)
- CI workflow `gh-pages.yml` builds and publishes Haddock
- Previous v5 scan found 45.8% Haddock coverage across 38 packages — significant gap

**Gaps observed:**
- Coverage varies widely by era (older eras like Byron have less Haddock, newer eras like Conway/Dijkstra have more active development but doc debt accumulates)
- Complex type signatures throughout (era-indexed types, type families, GADTs) — exactly the kind AI can document well

**Note:** The `seen_in` entry in the seed already references this repo. Validated with fresh evidence.

### hs_debug_state_transitions — VALIDATED

```yaml
id: hs_debug_state_transitions
validation: confirmed
confidence: HIGH
```

**Evidence:**
- STS (Signal-Transition-State) framework: `libs/small-steps/` is a dedicated library for defining state transition rules
- Rules modules per era: `eras/{era}/impl/src/Cardano/Ledger/{Era}/Rules/*.hs` — each era has 10-15 rule modules (Bbody, Cert, Certs, Deleg, Gov, GovCert, Ledger, Ledgers, Pool, Utxo, Utxow, etc.)
- Transition modules per era: `eras/{era}/impl/src/Cardano/Ledger/{Era}/Transition.hs`
- Era-indexed type parameters throughout (ShelleyEra, ConwayEra, DijkstraEra)
- Conformance testing against Agda formal spec (`libs/cardano-ledger-conformance/`) — provides ground truth for state transition correctness
- High complexity: 9 eras × 10-15 rules each = 100+ state transition modules

**Readiness criteria confirmed:**
- State transition modules identifiable: YES (Rules/ directories per era)
- Formal spec exists: YES (Agda formal spec, complete for Conway, partial for earlier eras)
- Test coverage for transitions: YES (Imp tests per rule per era, plus conformance tests)

### hs_cross_era_review — VALIDATED

```yaml
id: hs_cross_era_review
validation: confirmed
confidence: HIGH
```

**Evidence:**
- 9 era directories: byron, shelley, allegra, mary, alonzo, babbage, conway, dijkstra, shelley-ma
- Era-indexed type parameters in all modern modules (post-Byron)
- Cross-era serialization: CDDL specs per era (`eras/{era}/impl/cddl/data/{era}.cddl`)
- Translation modules: `eras/{era}/impl/testlib/Test/Cardano/Ledger/{Era}/Translation/` (era transition testing)
- Shelley-MA test suite: `eras/shelley-ma/test-suite/` — cross-era testing for Mary/Allegra
- Active development on dijkstra (newest era) while conway is current production era — PRs regularly touch multiple eras

**Additional readiness criterion proposed:**
- "Translation tests exist between adjacent eras" — this repo has explicit Translation test modules per era. This is a stronger signal than just "era compatibility tests exist."

### hs_cddl_conformance — VALIDATED

```yaml
id: hs_cddl_conformance
validation: confirmed
confidence: HIGH
```

**Evidence:**
- CDDL files per era: `eras/{era}/impl/cddl/data/{era}.cddl` (allegra, alonzo, babbage, conway, dijkstra, mary, shelley)
- HuddleSpec per era: `eras/{era}/impl/cddl/lib/Cardano/Ledger/{Era}/HuddleSpec.hs` — Haskell-generated CDDL specs
- CddlSpec per era: `eras/{era}/impl/test/Test/Cardano/Ledger/{Era}/Binary/CddlSpec.hs` — conformance tests
- 2 AI-attributed commits (2026-03-23) specifically touched dijkstra CDDL tests and plutus script generators — this is an active area
- Golden test files: `eras/dijkstra/impl/golden/` (pparams-update.json, pparams.json, translations.cbor)

**Readiness criteria confirmed:**
- CDDL files exist: YES (7 eras)
- Conformance tests exist: YES (CddlSpec per era)
- Serialization modules identifiable: YES (ToCBOR/FromCBOR throughout, binary/ test directories)

---

## New Pattern Proposals

### Conformance testing against Agda formal specification

```yaml
id: hs_agda_conformance
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Agda or Coq formal specification exists for the protocol/system
  - Haskell implementation must conform to formal spec
  - Executable spec can be extracted and tested against implementation

value: HIGH
value_context: "Formal spec conformance is the gold standard for correctness in financial ledger systems — AI can help identify gaps between spec and impl"
effort: Medium
evidence_to_look_for:
  - formal-spec/ or formal-ledger-specifications/ referenced in cabal.project
  - ExecSpecRule modules (bridge between Agda-extracted spec and Haskell tests)
  - Conformance test directories (libs/cardano-ledger-conformance/)
  - source-repository-package pointing to formal spec repo
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "Complete Agda formal spec for Conway era, partial for earlier eras. Conformance testing via libs/cardano-ledger-conformance/ with ExecSpecRule modules per STS rule."
evidence_from_scan:
  - libs/cardano-ledger-conformance/src/Test/Cardano/Ledger/Conformance/ExecSpecRule/Conway/ — 10+ rule conformance modules
  - cabal.project source-repository-package pointing to formal-ledger-specifications repo (tag: 6158038b)
  - Conway conformance complete; earlier eras partially covered

learning_entry: |
  When a new STS rule is added or modified:
  1. Give Claude the Agda spec extract + the Haskell implementation of the rule
  2. Ask: "Where does the Haskell implementation diverge from the formal spec?"
  3. Ask: "What conformance test cases would exercise the divergence points?"
  This is particularly valuable during era transitions (e.g., Conway → Dijkstra)
  where rules are modified and conformance must be re-verified.

readiness_criteria:
  - criterion: "Formal spec exists and is extractable"
    type: Objective
    check: "source-repository-package in cabal.project pointing to formal spec, or formal-spec/ directory"
  - criterion: "Conformance bridge exists (ExecSpecRule or equivalent)"
    type: Objective
    check: "Conformance test modules that bridge extracted spec to Haskell implementation"
  - criterion: "CI runs conformance tests"
    type: Objective
    check: "Conformance test package included in CI test suite"
```

### Imp (imperative) test generation for new STS rules

```yaml
id: hs_imp_test_generation
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Imp test framework in use (imperative property test style)
  - New STS rules or rule modifications in active development
  - Existing Imp tests as template/reference per era

value: HIGH
value_context: "Imp tests are the primary testing strategy for STS rules in cardano-ledger — AI can generate new Imp tests from existing patterns + rule specifications"
effort: Low
evidence_to_look_for:
  - testlib/Test/Cardano/Ledger/{Era}/Imp/ directories with *Spec.hs files
  - New rules added without corresponding Imp tests
  - Dijkstra era Imp tests (newest, likely sparse)
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "Extensive Imp test suite for Conway (BbodySpec, CertsSpec, DelegSpec, EnactSpec, EpochSpec, GovCertSpec, GovSpec, LedgerSpec, UtxoSpec, UtxosSpec, UtxowSpec). Dijkstra coverage TBD."
evidence_from_scan:
  - eras/conway/impl/testlib/Test/Cardano/Ledger/Conway/Imp/ — 11+ Spec files covering all major rules
  - eras/allegra through babbage — Imp tests present but fewer per era
  - Pattern is consistent: each rule gets its own Imp*Spec.hs

learning_entry: |
  When adding a new STS rule to an era:
  1. Give Claude an existing ImpSpec from the same era (e.g., Conway/Imp/GovSpec.hs)
  2. Give Claude the new rule module (e.g., Dijkstra/Rules/NewRule.hs)
  3. Ask: "Generate an Imp test suite for this rule following the same patterns as the reference"
  Key: Imp tests follow a consistent style per era — AI can replicate the pattern accurately.
  Review: verify the generated test actually exercises the rule's preconditions and postconditions.

readiness_criteria:
  - criterion: "Imp test framework available for the target era"
    type: Objective
    check: "testlib/Test/Cardano/Ledger/{Era}/Imp/ directory exists with at least one Spec file"
  - criterion: "STS rule module exists to test"
    type: Objective
    check: "Rules/{RuleName}.hs exists in the era's src directory"
  - criterion: "Era test infrastructure builds"
    type: Objective
    check: "The era's test-suite or testlib compiles in CI"
```

### Constrained generator authoring assistance

```yaml
id: hs_constrained_generators
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - constrained-generators library in use (specialized generator infrastructure)
  - New data types added without corresponding generators
  - Complex invariants that must hold across generated values

value: HIGH
value_context: "constrained-generators is a specialized library for generating test data with inter-field constraints — AI can help write generators that satisfy complex invariants"
effort: Medium
evidence_to_look_for:
  - constrained-generators pinned in cabal.project as source-repository-package
  - HasSpec instances or constrained generator definitions
  - New data types in active eras without HasSpec instances
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "constrained-generators pinned at tag 966f65f3. Used for generating valid ledger states with inter-field constraints."
evidence_from_scan:
  - cabal.project: source-repository-package pointing to constrained-generators repo
  - Arbitrary.hs files per era use constrained generation for domain types
  - 2 AI-attributed commits (2026-03-23) added plutusScriptGen — an actual instance of AI assisting with generator authoring

learning_entry: |
  When adding a new data type that needs test generators:
  1. Give Claude the data type definition + its validation rules/invariants
  2. Give Claude an existing constrained generator for a similar type in the same era
  3. Ask: "Write a generator that produces valid instances satisfying these invariants"
  Key: the invariants are the hard part — AI can translate formal constraints into generator code.
  Always test the generator: does it actually produce valid instances? Does shrinking work?

readiness_criteria:
  - criterion: "constrained-generators library available"
    type: Objective
    check: "constrained-generators in cabal.project dependencies"
  - criterion: "Existing generators as reference"
    type: Objective
    check: "At least 3 Arbitrary.hs or generator modules exist in the target era"
  - criterion: "Data type invariants documented or in formal spec"
    type: Semi-objective
    check: "Formal spec or inline comments describe validity conditions for the data type"
```

### Era transition documentation generation

```yaml
id: hs_era_transition_docs
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Multi-era architecture with active era transitions
  - NewEra.md or equivalent guide exists but may be incomplete
  - New era being developed (dijkstra) requires understanding of transition process

value: MEDIUM
value_context: "Era transitions require understanding the full checklist of what changes — AI can generate transition documentation from diff between adjacent eras"
effort: Low
evidence_to_look_for:
  - docs/NewEra.md (transition guide)
  - Transition.hs modules per era
  - Translation test modules
  - CHANGELOG.md per era package
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "docs/NewEra.md exists. Transition.hs per era. Translation tests per era. Dijkstra era actively being developed."
evidence_from_scan:
  - docs/NewEra.md — existing transition guide
  - eras/{era}/impl/src/Cardano/Ledger/{Era}/Transition.hs — per-era transition logic
  - eras/{era}/impl/testlib/Test/Cardano/Ledger/{Era}/Translation/ — translation test modules
  - eras/dijkstra/ — active development, newest era

learning_entry: |
  When starting a new era transition (e.g., Conway → Dijkstra):
  1. Give Claude the docs/NewEra.md guide + the previous Transition.hs + the new era's initial files
  2. Ask: "What's missing in the new era compared to what NewEra.md prescribes?"
  3. Ask: "Draft the Transition.hs for the new era based on the Conway→Dijkstra changes"
  Review against the formal spec — transition logic must match specification.

readiness_criteria:
  - criterion: "Era transition guide exists"
    type: Objective
    check: "docs/NewEra.md or equivalent transition documentation"
  - criterion: "Previous era transition modules exist as reference"
    type: Objective
    check: "At least one Transition.hs from a completed era transition"
```

---

## Cross-Cutting Pattern Validation

### cc_claude_md_context — CONFIRMED ABSENT

No CLAUDE.md, .aiignore, .cursorrules, AGENTS.md, or copilot-instructions.md found.
2 AI-attributed commits exist (Co-Authored-By: Claude Opus 4.6) but no AI config.
This is a clear opportunity: high-complexity repo actively using AI without any AI configuration.

### cc_aiignore_boundaries — CONFIRMED APPLICABLE

Security-critical code paths identifiable:
- Crypto: `eras/byron/crypto/` (cardano-crypto-wrapper)
- Consensus-adjacent: all `Rules/*.hs` modules implement ledger rules that consensus depends on
- Serialization: CDDL conformance is critical for on-chain compatibility
- No .aiignore exists

---

## Scan Summary

| Seed Pattern | Status | Confidence |
|-------------|--------|------------|
| hs_quickcheck_corner_cases | VALIDATED | HIGH |
| hs_haddock_generation | VALIDATED | MEDIUM |
| hs_debug_state_transitions | VALIDATED | HIGH |
| hs_cross_era_review | VALIDATED | HIGH |
| hs_cddl_conformance | VALIDATED | HIGH |

| New Proposal | ID | Value |
|-------------|-----|-------|
| Agda formal spec conformance | hs_agda_conformance | HIGH |
| Imp test generation for STS rules | hs_imp_test_generation | HIGH |
| Constrained generator authoring | hs_constrained_generators | HIGH |
| Era transition documentation | hs_era_transition_docs | MEDIUM |

**Key finding:** cardano-ledger is an exceptionally well-structured repo for AI opportunities. The combination of formal specifications, multiple test strategies (property-based, Imp, conformance, CDDL), and active multi-era development creates multiple high-value, low-risk AI use cases. The absence of any AI configuration (.aiignore, CLAUDE.md) despite active AI use is the primary gap.

**KB enrichment priority:** The 4 new patterns proposed are specific to repos with formal spec + STS architecture. They apply to cardano-ledger and potentially to ouroboros-consensus and cardano-node. They should be added to the Haskell ecosystem KB after CoE review.
