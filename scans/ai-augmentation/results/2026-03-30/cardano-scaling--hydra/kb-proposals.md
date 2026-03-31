# KB Proposals — Learning Scan: cardano-scaling/hydra

> **Scan date:** 2026-03-30
> **Scan type:** Learning
> **Ecosystem:** Haskell
> **Repo:** cardano-scaling/hydra (master)
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
- 1 explicit Arbitrary module sampled: `hydra-cardano-api/testlib/Hydra/Cardano/Api/Gen.hs` — orphan Arbitrary instances for Address, ChainPoint, NetworkMagic, NetworkId, PolicyId, TxIn with custom generators
- `hydra-cluster/src/Hydra/Generator.hs` — Dataset generators using QuickCheck (`Test.QuickCheck.choose`, `generate`, `sized`)
- `hydra-node/test/Hydra/HeadLogicSpec.hs` (97K bytes) — massive property test suite for the Head protocol state machine
- `hydra-node/test/Hydra/BehaviorSpec.hs` (65K bytes) — behavioral property tests
- `hydra-tx/testlib/Test/Hydra/Tx/Gen.hs` (20K bytes) — transaction generators
- `hydra-tx/testlib/Test/Hydra/Tx/Mutation.hs` (37K bytes) — mutation-based testing infrastructure
- `hydra-node/test/Hydra/Model.hs` (36K bytes) — model-based testing of Hydra protocol
- 130 test files totaling substantial coverage across 12 packages

**Gaps observed:**
- `genTxIn` in `Hydra/Cardano/Api/Gen.hs` uses raw CBOR prefix construction (`[88, 32]` prefix) — a pragmatic but brittle approach that could benefit from review
- Mutation-based testing (`Mutation.hs` at 37K) is a sophisticated technique beyond standard QuickCheck — suggests a potential new KB pattern

### hs_haddock_generation — NOT VALIDATED

```yaml
id: hs_haddock_generation
validation: not_confirmed
confidence: MEDIUM
```

**Evidence against:**
- No dedicated Haddock CI workflow found. The 10 workflows are: `binaries.yaml`, `check-tutorial.yaml`, `ci-nix.yaml`, `docker.yaml`, `network-test.yaml`, `nightly-ci.yaml`, `publish-docs.yaml`, `smoke-test.yaml`, `tx-cost-diff.yaml`, `update-hydra-spec.yaml`
- `publish-docs.yaml` likely publishes Docusaurus documentation (extensive `docs/` directory with Docusaurus structure: `docs/src/`, `docs/static/`, `docs/helpers/`), not Haddock
- 12 cabal packages — significant API surface
- `.hlint.yaml` and `fourmolu.yaml` present — code quality tooling exists

**Gaps observed:**
- Documentation effort is focused on Docusaurus (user-facing docs, tutorials, ADRs) rather than API documentation (Haddock)
- The Haddock pattern may still apply but is not currently actioned — no evidence of Haddock being built or published

### hs_debug_state_transitions — VALIDATED

```yaml
id: hs_debug_state_transitions
validation: confirmed
confidence: HIGH
```

**Evidence:**
- `hydra-node/test/Hydra/HeadLogicSpec.hs` (97K bytes) — tests the Hydra Head protocol state machine
- `hydra-node/test/Hydra/HeadLogicSnapshotSpec.hs` (9K bytes) — snapshot state transition tests
- `hydra-node/testlib/Test/Hydra/HeadLogic/State.hs` — test fixtures for state machine states
- `hydra-node/testlib/Test/Hydra/HeadLogic/Input.hs` — test fixtures for state machine inputs
- `hydra-node/testlib/Test/Hydra/HeadLogic/Outcome.hs` — test fixtures for state machine outcomes
- `hydra-node/testlib/Test/Hydra/HeadLogic/StateEvent.hs` — state event test fixtures
- `hydra-node/test/Hydra/Model.hs` (36K bytes) — model-based testing of the protocol state machine
- The Hydra Head protocol is fundamentally a state machine (Init -> Open -> Close -> Contest -> FanOut)

**Readiness criteria confirmed:**
- State transition modules identifiable: YES (HeadLogic with Input/State/Outcome separation)
- Test coverage for transitions: YES (97K bytes of HeadLogicSpec + model-based testing)
- Formal spec exists: YES (42 ADRs in `docs/adr/`, Hydra paper, `update-hydra-spec.yaml` workflow)

### hs_cross_era_review — NOT APPLICABLE

```yaml
id: hs_cross_era_review
validation: not_applicable
confidence: HIGH
```

Hydra does not use era-indexed architecture. It interfaces with the Cardano ledger's eras through `hydra-cardano-api` but does not define era-specific modules internally.

### hs_cddl_conformance — NOT APPLICABLE

```yaml
id: hs_cddl_conformance
validation: not_applicable
confidence: HIGH
```

No .cddl files. Serialization uses JSON schemas (`hydra-node/json-schemas/` directory) rather than CBOR/CDDL.

### hs_agda_conformance — NOT APPLICABLE

No Agda formal spec. The Hydra protocol has a formal specification (updated via `update-hydra-spec.yaml`) but it is not Agda-based.

### hs_imp_test_generation — NOT APPLICABLE

No Imp test framework. Uses model-based testing via quickcheck-dynamic instead.

### hs_constrained_generators — NOT APPLICABLE

No constrained-generators dependency.

### hs_era_transition_docs — NOT APPLICABLE

No era architecture.

### Rust patterns — NOT APPLICABLE

```yaml
rs_unsafe_audit: not_applicable
rs_rustdoc_generation: not_applicable
rs_debug_async: not_applicable
confidence: HIGH
```

Despite the user noting "Haskell/Rust", the language breakdown shows 94.5% Haskell with no Rust in the top 10 languages. The repo contains Aiken (0.5%) which is a Cardano smart contract language, not Rust. No Cargo.toml files in package manifests. No .rs files in source tree.

---

## Cross-Cutting Patterns

### cc_claude_md_context — CONFIRMED ABSENT

No CLAUDE.md, .cursorrules, AGENTS.md, or copilot-instructions.md. No AI config files. No AI-attributed commits. CODEOWNERS exists. CONTRIBUTING.md exists. For a protocol implementation with 42 ADRs and complex state machine logic, a CLAUDE.md would significantly improve AI-assisted development.

### cc_aiignore_boundaries — CONFIRMED APPLICABLE

Security-critical code paths:
- `hydra-plutus/` — on-chain Plutus validators for the Hydra Head protocol (consensus-critical)
- `hydra-node/src/Hydra/Chain/` — chain interaction layer (real money transactions)
- `hydra-tx/` — transaction construction (spending/minting)
- `hydra-node/src/Hydra/` — HeadLogic (protocol state machine — correctness is safety-critical)
- No .aiignore exists. No AI tools currently in use.

---

## New Pattern Proposals

### Mutation-based test generation for Plutus validator testing

```yaml
id: hs_mutation_testing
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30
source_scan: cardano-scaling/hydra (learning, 2026-03-30)

applies_when:
  - Plutus validators with on-chain logic
  - Mutation testing infrastructure exists (systematic perturbation of valid transactions to test validators reject invalid ones)
  - High-assurance requirements for on-chain code

value: HIGH
value_context: "Mutation testing for Plutus validators systematically checks that validators reject all classes of invalid transactions — AI can propose novel mutations from the validator's logic"
effort: Medium
evidence_to_look_for:
  - Mutation.hs or similar mutation test infrastructure
  - Plutus validator test files with mutation-based test cases
  - Contract test directories (hydra-tx/test/Hydra/Tx/Contract/)
seen_in:
  - repo: cardano-scaling/hydra
    outcome: "hydra-tx/testlib/Test/Hydra/Tx/Mutation.hs (37K bytes) — comprehensive mutation testing framework. Contract tests per transaction type: Abort, Close, CollectCom, Commit, Contest, Decrement, Deposit, FanOut, Increment, Init, Recover."
evidence_from_scan:
  - hydra-tx/testlib/Test/Hydra/Tx/Mutation.hs — 37K bytes of mutation testing infrastructure
  - hydra-tx/test/Hydra/Tx/Contract/ — 16 contract test files covering all Head lifecycle transactions
  - hydra-tx/test/Hydra/Tx/Contract/ContractSpec.hs (11K) — contract specification tests

readiness_criteria:
  - criterion: "Mutation testing framework exists"
    type: Objective
    check: "Mutation.hs or equivalent infrastructure that systematically perturbs valid transactions"
  - criterion: "Plutus validators exist to test"
    type: Objective
    check: "On-chain validator modules with Plutus scripts"
  - criterion: "At least one complete mutation test suite as reference"
    type: Objective
    check: "Contract test file that uses mutation framework to test a specific validator"
```

### ADR-informed development assistance

```yaml
id: cc_adr_informed_dev
type: opportunity
ecosystem: cross-cutting
status: proposed
discovered: 2026-03-30
updated: 2026-03-30
source_scan: cardano-scaling/hydra (learning, 2026-03-30)

applies_when:
  - Repo has >10 ADRs documenting architectural decisions
  - Active development that should be consistent with existing ADRs
  - New PRs may inadvertently violate established architectural decisions

value: MEDIUM
value_context: "With 42 ADRs, developers cannot realistically remember all decisions — AI can check new code against relevant ADRs"
effort: Low
evidence_to_look_for:
  - docs/adr/ directory with >10 ADR files
  - ADRs covering architecture patterns that are enforceable in code review
  - History of PRs that violated ADR decisions (reverts, rework)
seen_in:
  - repo: cardano-scaling/hydra
    outcome: "42 ADRs spanning 2021-2026 covering protocol design, networking, testing strategy, API design"

readiness_criteria:
  - criterion: "ADR directory with substantive decisions"
    type: Objective
    check: "docs/adr/ or similar with >10 ADR files"
  - criterion: "ADRs reference code patterns (not just conceptual decisions)"
    type: Semi-objective
    check: "ADRs mention specific modules, patterns, or coding conventions"
```

---

## Summary

| Seed Pattern | Status | Confidence |
|---|---|---|
| hs_quickcheck_corner_cases | VALIDATED | HIGH |
| hs_haddock_generation | NOT VALIDATED | MEDIUM |
| hs_debug_state_transitions | VALIDATED | HIGH |
| hs_cross_era_review | NOT APPLICABLE | HIGH |
| hs_cddl_conformance | NOT APPLICABLE | HIGH |
| hs_agda_conformance | NOT APPLICABLE | HIGH |
| hs_imp_test_generation | NOT APPLICABLE | HIGH |
| hs_constrained_generators | NOT APPLICABLE | HIGH |
| hs_era_transition_docs | NOT APPLICABLE | HIGH |
| rs_unsafe_audit | NOT APPLICABLE | HIGH |
| rs_rustdoc_generation | NOT APPLICABLE | HIGH |
| rs_debug_async | NOT APPLICABLE | HIGH |

| New Proposal | ID | Value |
|---|---|---|
| Mutation-based test generation | hs_mutation_testing | HIGH |
| ADR-informed development | cc_adr_informed_dev | MEDIUM |

| Cross-Cutting | Status |
|---|---|
| cc_claude_md_context | ABSENT — opportunity (42 ADRs + complex state machine = high-value CLAUDE.md candidate) |
| cc_aiignore_boundaries | APPLICABLE — on-chain validators + chain interaction layer need trust boundaries |

**Key finding:** Hydra's mutation testing infrastructure (`Mutation.hs`, 37K bytes) is a novel testing pattern not covered by existing KB entries. It systematically perturbs valid transactions to verify that on-chain validators correctly reject all classes of invalid inputs. This is a high-value pattern for any repo with Plutus validators. The 42 ADRs also make this repo a strong candidate for ADR-informed development assistance.
