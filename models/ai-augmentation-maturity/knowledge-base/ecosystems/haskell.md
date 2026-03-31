# Haskell Ecosystem — Opportunity Patterns + Readiness Criteria

## Corner case discovery in property-based tests

```yaml
id: hs_quickcheck_corner_cases
type: opportunity
ecosystem: haskell
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - QuickCheck or Hedgehog used for property-based testing
  - Arbitrary instances exist per domain type
  - High-churn modules with complex invariants

value: HIGH
value_context: "Property-test-heavy repos benefit most — AI can identify invariants humans miss, especially in cross-era state transitions"
effort: Low
evidence_to_look_for:
  - testlib/*/Arbitrary.hs or Gen*.hs files
  - Absence of shrinking implementations in existing generators
  - New modules added without corresponding generators
  - Formal spec modules with invariants not reflected in tests
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "identified gap in dijkstra era generators (2026-03-28 scan)"

learning_entry: |
  Start with one Arbitrary instance for a core data type. Ask Claude to:
  1. Read the formal spec for that type's invariants
  2. Identify which invariants the current generator doesn't cover
  3. Propose additional property tests targeting those gaps
  Review output against the formal spec before committing.
  Key: AI finds gaps in coverage, human validates against spec.

readiness_criteria:
  - criterion: "Arbitrary instances exist per domain type"
    type: Objective
    check: "testlib/ or test/ directories contain Arbitrary.hs or Gen*.hs files matching source modules"
  - criterion: "Shrinking implemented in generators"
    type: Objective
    check: "Arbitrary instances define shrink or derive via Generics"
  - criterion: "Formal spec exists for core invariants"
    type: Objective
    check: "formal-spec/ or spec/ directory exists with property definitions"
  - criterion: "CI runs property tests"
    type: Objective
    check: "CI workflow invokes cabal test or nix flake check covering test suites"
```

## Haddock documentation for underdocumented modules

```yaml
id: hs_haddock_generation
type: opportunity
ecosystem: haskell
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Haskell repo with exported public API
  - Doc comment coverage below 60% (sample 10 source files)
  - Modules with complex type signatures that benefit from explanation

value: HIGH
value_context: "Domain-specific Haddock docs are expensive to write manually; AI can draft accurate docs from type signatures + usage context"
effort: Low
evidence_to_look_for:
  - Source files without "-- |" or "{- |" doc comments on exported functions
  - Complex type signatures (3+ type parameters, GADTs, type families)
  - Modules that are imported by many other modules (high fan-in)
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "45.8% Haddock coverage across 38 packages — significant gap in era-specific modules"

learning_entry: |
  Pick one module with complex types and no Haddock. Ask Claude to:
  1. Read the module's exports and type signatures
  2. Read modules that import this one (usage context)
  3. Draft Haddock comments explaining purpose, invariants, and usage
  Review for accuracy — AI captures structure well but may miss domain subtleties.

readiness_criteria:
  - criterion: "Haddock tooling configured"
    type: Objective
    check: "cabal haddock works or haddock referenced in CI/nix"
  - criterion: "Module exports are explicit (not module re-exports of everything)"
    type: Semi-objective
    check: "Source files use explicit export lists, not 'module X (module Y)' re-exports"
  - criterion: "At least some existing Haddock as style reference"
    type: Semi-objective
    check: "At least 3 modules have substantive doc comments (not just '-- | TODO')"
```

## Debug assistance for complex state transitions

```yaml
id: hs_debug_state_transitions
type: opportunity
ecosystem: haskell
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - State machine or era-transition logic present
  - Cross-module state dependencies (state flows through multiple modules)
  - History of subtle bugs in state transition code (reverts, fix commits)

value: HIGH
value_context: "State transition debugging in formal-spec-aligned code is expert-level work; AI excels at tracing state through call chains"
effort: Low
evidence_to_look_for:
  - Modules with "Rules" or "Transition" in path (e.g., Rules/Cert.hs, Rules/Gov.hs)
  - Type-level era indexing (ShelleyEra, ConwayEra type parameters)
  - Revert commits or multi-commit fixes in state transition modules
  - STS (Signal-Transition-State) framework usage
seen_in: []

learning_entry: |
  When debugging a failing property test or unexpected state:
  1. Give Claude the failing test output + the relevant STS rule module
  2. Ask it to trace the state transition step by step
  3. Ask it to identify which precondition or postcondition is violated
  AI is very good at mechanical state tracing — use it for the tedious part,
  validate the conclusion against the formal spec yourself.

readiness_criteria:
  - criterion: "State transition modules are identifiable in file tree"
    type: Objective
    check: "Directories or files named *Rules*, *Transition*, or *STS* exist"
  - criterion: "Formal spec or invariant documentation exists"
    type: Objective
    check: "formal-spec/ directory or inline spec comments in transition modules"
  - criterion: "Test coverage exists for state transitions"
    type: Objective
    check: "Test files exist that exercise transition rules (property or unit tests)"
```

## AI-assisted code review for cross-era changes

```yaml
id: hs_cross_era_review
type: opportunity
ecosystem: haskell
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Multi-era architecture (era-indexed types, era-specific modules)
  - PRs frequently touch multiple eras simultaneously
  - Backward compatibility constraints between eras

value: MEDIUM
value_context: "Cross-era changes require understanding interactions between era-specific implementations — AI can surface missed interactions"
effort: Low
evidence_to_look_for:
  - Directory structure with era names (shelley/, allegra/, conway/, etc.)
  - Type-level era parameters in signatures
  - PRs that modify files across multiple era directories
seen_in: []

learning_entry: |
  When reviewing a PR that touches multiple eras:
  1. Give Claude the diff + the type signatures of affected functions across eras
  2. Ask: "Which era-specific invariants could this change violate?"
  3. Ask: "Does this change maintain backward compatibility with the previous era?"
  Focus on: serialization compatibility, state migration paths, and predicate changes.

readiness_criteria:
  - criterion: "Era modules are clearly separated in file tree"
    type: Objective
    check: "Directories or package names contain era identifiers"
  - criterion: "Era compatibility tests exist"
    type: Objective
    check: "Test files that exercise cross-era serialization or migration"
```

## CDDL/schema conformance testing assistance

```yaml
id: hs_cddl_conformance
type: opportunity
ecosystem: haskell
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - CDDL or similar schema definitions exist in repo
  - Serialization/deserialization code must conform to external specs
  - Conformance tests exist but may not cover all schema variants

value: MEDIUM
value_context: "CDDL conformance is tedious to verify exhaustively; AI can identify untested schema branches"
effort: Medium
evidence_to_look_for:
  - .cddl files in repo
  - CddlSpec.hs or similar conformance test files
  - Serialization modules (ToCBOR, FromCBOR instances)
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "CddlSpec.hs covers main types but some era-specific variants untested"

learning_entry: |
  Give Claude the CDDL schema + the corresponding CddlSpec test file.
  Ask: "Which schema alternatives are not covered by the existing tests?"
  Then: generate test cases for the uncovered alternatives.
  Verify generated tests compile and exercise the correct serialization paths.

readiness_criteria:
  - criterion: "CDDL or schema files exist"
    type: Objective
    check: ".cddl files or equivalent schema definitions in repo"
  - criterion: "Conformance tests exist"
    type: Objective
    check: "Test files that verify serialization against schema (CddlSpec, etc.)"
  - criterion: "Serialization modules are identifiable"
    type: Objective
    check: "Modules with ToCBOR/FromCBOR/ToJSON/FromJSON instances"
```

## Conformance testing against Agda formal specification

```yaml
id: hs_agda_conformance
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30
source_scan: IntersectMBO/cardano-ledger (learning, 2026-03-30)

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
  - Conformance test directories
  - source-repository-package pointing to formal spec repo
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "Complete Agda formal spec for Conway era, partial for earlier eras. Conformance testing via libs/cardano-ledger-conformance/ with ExecSpecRule modules per STS rule."

learning_entry: |
  When a new STS rule is added or modified:
  1. Give Claude the Agda spec extract + the Haskell implementation of the rule
  2. Ask: "Where does the Haskell implementation diverge from the formal spec?"
  3. Ask: "What conformance test cases would exercise the divergence points?"
  Particularly valuable during era transitions where rules are modified
  and conformance must be re-verified.

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

## Imp test generation for new STS rules

```yaml
id: hs_imp_test_generation
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30
source_scan: IntersectMBO/cardano-ledger (learning, 2026-03-30)

applies_when:
  - Imp test framework in use (imperative property test style)
  - New STS rules or rule modifications in active development
  - Existing Imp tests as template/reference per era

value: HIGH
value_context: "Imp tests are the primary testing strategy for STS rules — AI can generate new Imp tests from existing patterns + rule specifications"
effort: Low
evidence_to_look_for:
  - testlib/Test/Cardano/Ledger/{Era}/Imp/ directories with *Spec.hs files
  - New rules added without corresponding Imp tests
  - Newest era Imp tests (likely sparse compared to established eras)
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "Extensive Imp test suite for Conway (11+ Spec files). Dijkstra coverage in early stages."

learning_entry: |
  When adding a new STS rule to an era:
  1. Give Claude an existing ImpSpec from the same era as reference
  2. Give Claude the new rule module
  3. Ask: "Generate an Imp test suite following the same patterns as the reference"
  Imp tests follow a consistent style per era — AI replicates the pattern accurately.
  Review: verify the generated test exercises the rule's preconditions and postconditions.

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

## Constrained generator authoring assistance

```yaml
id: hs_constrained_generators
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30
source_scan: IntersectMBO/cardano-ledger (learning, 2026-03-30)

applies_when:
  - constrained-generators library in use (specialized generator infrastructure)
  - New data types added without corresponding generators
  - Complex invariants that must hold across generated values

value: HIGH
value_context: "constrained-generators produces test data with inter-field constraints — AI can help write generators that satisfy complex invariants"
effort: Medium
evidence_to_look_for:
  - constrained-generators pinned in cabal.project as source-repository-package
  - HasSpec instances or constrained generator definitions
  - New data types in active eras without HasSpec instances
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "constrained-generators pinned. 2 AI-attributed commits (2026-03-23) added plutusScriptGen — actual instance of AI assisting with generator authoring."

learning_entry: |
  When adding a new data type that needs test generators:
  1. Give Claude the data type definition + its validation rules/invariants
  2. Give Claude an existing constrained generator for a similar type
  3. Ask: "Write a generator that produces valid instances satisfying these invariants"
  The invariants are the hard part — AI translates formal constraints into generator code.
  Always test: does the generator produce valid instances? Does shrinking work?

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

## Era transition documentation generation

```yaml
id: hs_era_transition_docs
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30
source_scan: IntersectMBO/cardano-ledger (learning, 2026-03-30)

applies_when:
  - Multi-era architecture with active era transitions
  - NewEra.md or equivalent guide exists but may be incomplete
  - New era being developed requires understanding of transition process

value: MEDIUM
value_context: "Era transitions require understanding the full checklist — AI can generate transition documentation from diff between adjacent eras"
effort: Low
evidence_to_look_for:
  - docs/NewEra.md (transition guide)
  - Transition.hs modules per era
  - Translation test modules
  - CHANGELOG.md per era package
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "docs/NewEra.md exists. Transition.hs per era. Translation tests per era. Dijkstra era actively being developed."

learning_entry: |
  When starting a new era transition:
  1. Give Claude the transition guide + the previous Transition.hs + the new era's initial files
  2. Ask: "What's missing in the new era compared to what the guide prescribes?"
  3. Ask: "Draft the Transition.hs based on the changes from the previous era"
  Review against formal spec — transition logic must match specification.

readiness_criteria:
  - criterion: "Era transition guide exists"
    type: Objective
    check: "docs/NewEra.md or equivalent transition documentation"
  - criterion: "Previous era transition modules exist as reference"
    type: Objective
    check: "At least one Transition.hs from a completed era transition"
```

---

## Detection Notes (from v5 scans)

These are not opportunity patterns — they are agent instructions for accurate data collection in Haskell repos.

- **Nix-wrapped CI:** Haskell repos run hlint/fourmolu via `nix develop --command`. Match `nix develop|nix build|nix flake check` patterns, not just direct tool names. `flake.nix` is a first-class detection surface.
- **cabal multi-package:** `cabal.project` with `packages:` listing multiple paths indicates module boundaries. Count packages, not just "cabal exists."
- **HLint + fourmolu:** Standard Haskell tooling. Detection: `.hlint.yaml`, or `hlint`/`fourmolu` in `flake.nix` or CI.
