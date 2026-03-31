# AAMM v6 Detailed Log: cardano-scaling/hydra
> Scan date: 2026-03-31 | Agent: Claude Opus 4.6 (1M context) | Schema: v6.0

## Data Collection

### API calls made
1. GitHub Trees API: `GET /repos/cardano-scaling/hydra/git/trees/b7ad7a8...` — 1153 entries
2. GitHub Commits API: `GET /repos/cardano-scaling/hydra/commits?per_page=100` — returned commits from 2026-01 through 2026-03-27
3. GitHub PRs API: `GET /repos/cardano-scaling/hydra/pulls?state=closed&sort=updated&per_page=30` — returned 30 PRs
4. Key file contents: README.md (EXISTS, 4338 bytes), CLAUDE.md (EXISTS, 14 bytes — 404/placeholder), CONTRIBUTING.md (EXISTS, 14827 bytes), CODEOWNERS (EXISTS, 19 bytes), .aiignore (ABSENT), .github/pull_request_template.md (EXISTS, 270 bytes)

### Ecosystem detection
- Primary: Haskell (cabal.project, .hs files throughout)
- Secondary: Aiken (hydra-plutus/aiken.toml, hydra-plutus/validators/deposit.ak)
- Build: Nix (flake.nix, ci-nix.yaml)
- Multi-package: hydra-node, hydra-tx, hydra-plutus, hydra-plutus-extras, hydra-cardano-api, hydra-cluster, hydra-chain-observer, hydra-tui, hydra-prelude, hydra-test-utils

### Key file excerpts

**CLAUDE.md:** 14 bytes only. Content returned 404: Not Found — file is either empty or a placeholder. Per anti-pattern `ap_generic_claude_md`, this counts as absent for Adoption State purposes.

**CONTRIBUTING.md:** 14827 bytes — substantive content covering development workflow.

**.hlint.yaml:** EXISTS at repo root (132 bytes).

**PR template:** `.github/pull_request_template.md` (270 bytes) — note lowercase path, the data summary listed it as ABSENT at the capitalized path `.github/PULL_REQUEST_TEMPLATE.md` but the tree shows it at lowercase.

### Git history summary
- Active authors in analysis set: noonio (Noon van der Silk), v0d1ch (Sasha Bogicevic)
- Date range of last commits: 2026-03-26 through 2026-03-27
- AI attribution: Zero Co-authored-by trailers mentioning any AI tool
- Bot PRs: 3 dependabot[bot] PRs (version updates only)
- Major recent change: PR #2536 "Directly open heads" — monumental refactor removing initialization phase, implementing ADR-33

### High-churn areas (inferred from recent commits)
- hydra-node/ (HeadLogic, protocol logic, tests, E2E)
- hydra-tx/ (transaction construction, Close, Contest, Deposit, Increment)
- hydra-plutus/ (on-chain validators, Aiken scripts)
- hydra-cluster/ (E2E tests, integration)
- hydra-tui/ (terminal UI)

### Test infrastructure
- **testlib/ directories:** hydra-cardano-api/testlib/ (Gen.hs), hydra-node/testlib/ (Chain, HeadLogic, Ledger generators), hydra-tx/testlib/ (Gen.hs, Mutation.hs), hydra-plutus/testlib/ (Gen.hs)
- **Model-based testing:** hydra-node/test/Hydra/Model.hs, Model/MockChain.hs, Model/Payment.hs, ModelSpec.hs
- **Mutation testing:** hydra-tx/testlib/Test/Hydra/Tx/Mutation.hs — mutation-based testing of Plutus validators
- **Property testing:** TxTraceSpec.hs, HeadLogicSnapshotSpec.hs, HeadLogicSpec.hs, CryptoSpec.hs
- **E2E tests:** hydra-cluster/test/Test/EndToEndSpec.hs, DirectChainSpec.hs, OfflineChainSpec.hs
- **Contract tests:** hydra-tx/test/Hydra/Tx/Contract/ (Close/CloseInitial.hs, Close/CloseUnused.hs, ...)
- **Golden tests:** hydra-node/golden/ (extensive JSON golden files for serialization)

### Security-sensitive paths identified
1. `hydra-plutus/src/Hydra/Contract/Head.hs` — main on-chain head validator
2. `hydra-plutus/src/Hydra/Contract/Deposit.hs` — deposit validator
3. `hydra-plutus/src/Hydra/Contract/HeadTokens.hs` — minting policy
4. `hydra-plutus/validators/deposit.ak` — Aiken on-chain validator
5. `hydra-tx/src/Hydra/Tx/Crypto.hs` — cryptographic operations
6. `hydra-node/src/Hydra/HeadLogic.hs` — L2 protocol state machine
7. `hydra-plutus/scripts/vHead.plutus`, `mHead.plutus` — compiled Plutus scripts

---

## KB Pattern Matching

### Haskell ecosystem patterns

#### hs_quickcheck_corner_cases — MATCHED
- **applies_when check:**
  - QuickCheck/Hedgehog used: YES — testlib/Gen.hs files across packages, Model-based testing with QuickCheck
  - Arbitrary instances per domain type: YES — hydra-cardano-api/testlib/Hydra/Cardano/Api/Gen.hs, hydra-tx/testlib/Test/Hydra/Tx/Gen.hs, hydra-plutus/testlib/Hydra/Plutus/Gen.hs
  - High-churn modules with complex invariants: YES — HeadLogic.hs, Tx modules actively changing in PR #2536
- **Evidence:** Gen.hs files in 3 testlib directories; Model.hs and ModelSpec.hs for model-based testing; Mutation.hs for validator mutation testing
- **Value adjustment:** HIGH — confirmed. Hydra is heavily property-test-driven (ADR 2021-11-25_012-top-down-test-driven-design.md, ADR 2022-12-06_022-model-based-testing.md)
- **Effort:** Low — infrastructure exists

#### hs_haddock_generation — MATCHED
- **applies_when check:**
  - Haskell repo with exported public API: YES — hydra-cardano-api, hydra-tx are consumed by other packages
  - Doc comment coverage: Cannot precisely sample, but hydra-plutus/README.md exists (small), large source surface across 10+ packages suggests documentation gaps likely
  - Complex type signatures: YES — era-indexed types, GADTs in HeadState, Plutus types
- **Evidence:** 10 packages, hydra-tx/src/ has 15+ modules exporting transaction construction types. hydra-plutus/src/Hydra/Contract/ has 12 modules with on-chain validator logic.
- **Value adjustment:** HIGH — domain-specific Plutus/Hydra types are hard to document manually
- **Effort:** Low

#### hs_debug_state_transitions — MATCHED
- **applies_when check:**
  - State machine logic: YES — HeadLogic.hs is the L2 protocol state machine with states (Idle, Open, Closed, etc.)
  - Cross-module state dependencies: YES — HeadLogic depends on Tx modules, Chain observation, Snapshot handling
  - History of subtle bugs: YES — PR #2560 "Various fixes" describes snapshot liveness bugs, version races, deposit leaks across heads
- **Evidence:** hydra-node/src/Hydra/HeadLogic.hs, HeadLogic/State.hs, HeadLogic/Input.hs, HeadLogic/Outcome.hs. PR #2560 describes 3 distinct snapshot liveness bugs requiring cross-module debugging.
- **Value adjustment:** HIGH — confirmed. Protocol state debugging is expert-level (Hydra's state machine is formally specified)
- **Effort:** Low

#### hs_cross_era_review — NOT MATCHED
- Hydra is not a multi-era ledger. It uses Cardano's ConwayEra but does not have its own era-indexed architecture. The "era" in hydra-node/golden/ refers to Cardano eras for serialization, not Hydra-internal eras.
- **Decision:** Does not apply.

#### hs_cddl_conformance — NOT MATCHED
- No .cddl files found in tree. Hydra uses its own JSON/CBOR serialization but not CDDL-defined schemas.
- **Decision:** Does not apply.

#### hs_agda_conformance — PARTIALLY MATCHED
- **applies_when check:**
  - Formal specification exists: YES — PR #2536 references `hydra-formal-specification` repo (separate repo), and `docs/adr/2026-03-10_033-directly-open-head.md` was added alongside formal spec PR #24
  - Haskell implementation must conform: YES — the head protocol is formally specified
  - Executable spec extractable: UNKNOWN — the formal spec is in a separate repo (cardano-scaling/hydra-formal-specification), not in this repo
- **Decision:** The formal spec is external. No conformance bridge (ExecSpecRule) exists in this repo. The applies_when conditions are only partially met. Since there's no conformance test infrastructure in THIS repo, this pattern matches at MEDIUM value with High effort (would require building the bridge first).
- **Adjusted:** Value MEDIUM (formal spec is external, conformance bridge doesn't exist), Effort High

#### hs_imp_test_generation — NOT MATCHED
- No Imp test framework in this repo. This pattern is specific to cardano-ledger's testing infrastructure.
- **Decision:** Does not apply.

#### hs_constrained_generators — NOT MATCHED
- No constrained-generators library in cabal.project. Hydra uses standard QuickCheck generators.
- **Decision:** Does not apply.

#### hs_era_transition_docs — NOT MATCHED
- Hydra does not have its own era transitions. It tracks Cardano eras but doesn't manage era-specific transitions internally.
- **Decision:** Does not apply.

### Cross-cutting patterns

#### cc_pr_descriptions — MATCHED
- **applies_when check:**
  - Active PR workflow (>5 PRs/month): YES — 30 PRs in recent data, active PR workflow
  - PR descriptions inconsistent or thin: MIXED — PR #2536 has extensive description, PR #2555 has minimal "fix #2498"
  - PR template exists: YES — `.github/pull_request_template.md` (270 bytes, checklist format)
- **Evidence:** PR template exists but is a simple checklist (CHANGELOG, Documentation, Haddocks, TODOs). Some PRs like #2555 have minimal descriptions beyond the template.
- **Value adjustment:** MEDIUM — confirmed. Template exists but AI could help generate structured "what changed / why / how to test" descriptions.
- **Effort:** Low

#### cc_claude_md_context — MATCHED
- **applies_when check:**
  - Repo uses or plans to use AI tools: CLAUDE.md file exists (14 bytes, placeholder/empty)
  - No CLAUDE.md with substance: YES — 14 bytes, returned 404
  - Complex project with domain knowledge: YES — Hydra Head protocol, Plutus validators, L2 state machine, formal specification
- **Evidence:** CLAUDE.md is 14 bytes (placeholder). Per anti-pattern `ap_generic_claude_md`, this is not operational AI config. The project is highly complex: 10 packages, on-chain validators, L2 protocol logic, formal spec alignment.
- **Value adjustment:** HIGH — confirmed. Hydra is one of the most complex Cardano projects. A substantive CLAUDE.md would significantly improve any AI interaction.
- **Effort:** Low

#### cc_aiignore_boundaries — MATCHED
- **applies_when check:**
  - High-assurance repo with security-critical code: YES — on-chain validators handling financial state, cryptographic operations
  - AI tools in use without explicit trust boundaries: CLAUDE.md exists (intent to use AI), no .aiignore
  - Crypto/consensus/financial modules present: YES — hydra-plutus/ (validators), hydra-tx/Crypto.hs, HeadLogic.hs
- **Evidence:** .aiignore ABSENT. Security-critical paths: hydra-plutus/src/Hydra/Contract/*.hs (on-chain validators), hydra-tx/src/Hydra/Tx/Crypto.hs, hydra-plutus/validators/*.ak, hydra-plutus/scripts/*.plutus.
- **Value adjustment:** HIGH — confirmed. Hydra handles real funds on-chain. Trust boundaries are essential before AI adoption.
- **Effort:** Low

#### cc_commit_messages — NOT MATCHED
- Commit messages are generally informative (signed, descriptive). PR #2536 has extensive commit messages. Not a priority.
- **Decision:** Does not apply for this repo.

#### cc_onboarding_docs — NOT MATCHED
- CONTRIBUTING.md exists at 14827 bytes (substantive). README.md exists at 4338 bytes. docs/ directory has ADRs, specification, protocol documentation.
- **Decision:** Not a gap — onboarding docs already exist.

### Novel opportunities (not in KB)

#### Novel: AI-assisted mutation test expansion for Hydra V2 validators
- **Rationale:** hydra-tx/testlib/Test/Hydra/Tx/Mutation.hs provides mutation-based testing infrastructure. PR #2536 removed vInitial and vCommit validators and simplified the on-chain surface. The remaining validators (vHead, vDeposit) are now the sole attack surface. AI could help systematically identify mutation gaps in the remaining validators.
- **Evidence:** Mutation.hs exists, PR #2536 message states "Remove vInitial and vCommit on-chain validators, reducing the script surface." Contract test directory hydra-tx/test/Hydra/Tx/Contract/ has Close/ subdirectory but the post-refactor validator surface may have untested mutations.
- **Value:** HIGH — on-chain validator correctness is critical for security
- **Effort:** Low — mutation infrastructure already exists, AI generates new mutation variants
- **kb_pattern:** null — candidate for KB expansion

---

## Opportunity Map (Pre-Adversarial)

### Opportunity 1: AI-assisted corner case discovery in Hydra HeadLogic property tests
- **id:** opp_hydra_headlogic_property_corners
- **kb_pattern:** hs_quickcheck_corner_cases
- **value:** HIGH (3) — Hydra is heavily property-test-driven, HeadLogic is the L2 protocol state machine with recent subtle bugs (PR #2560 snapshot liveness)
- **effort:** Low (3)
- **ROI:** 9
- **evidence:** hydra-node/test/Hydra/Model.hs (model-based testing), hydra-node/test/Hydra/HeadLogicSpec.hs, hydra-node/test/Hydra/HeadLogicSnapshotSpec.hs, PR #2560 snapshot liveness bugs, testlib Gen.hs files in 3 packages

### Opportunity 2: Substantive CLAUDE.md for Hydra's 10-package architecture and protocol domain
- **id:** opp_hydra_claude_md
- **kb_pattern:** cc_claude_md_context
- **value:** HIGH (3) — 10-package project with on-chain validators, L2 state machine, formal spec alignment. Maximum domain knowledge benefit.
- **effort:** Low (3)
- **ROI:** 9
- **evidence:** CLAUDE.md 14 bytes (placeholder). Packages: hydra-node, hydra-tx, hydra-plutus, hydra-plutus-extras, hydra-cardano-api, hydra-cluster, hydra-chain-observer, hydra-tui, hydra-prelude, hydra-test-utils. Security-critical paths: hydra-plutus/src/Hydra/Contract/*.hs

### Opportunity 3: .aiignore trust boundaries for Hydra on-chain validators and crypto
- **id:** opp_hydra_aiignore
- **kb_pattern:** cc_aiignore_boundaries
- **value:** HIGH (3) — on-chain validators handle real funds, crypto operations critical to protocol security
- **effort:** Low (3)
- **ROI:** 9
- **evidence:** .aiignore ABSENT. Critical paths: hydra-plutus/src/Hydra/Contract/Head.hs, hydra-plutus/src/Hydra/Contract/Deposit.hs, hydra-plutus/validators/deposit.ak, hydra-tx/src/Hydra/Tx/Crypto.hs, hydra-plutus/scripts/vHead.plutus, hydra-plutus/scripts/mHead.plutus

### Opportunity 4: AI-assisted mutation test expansion for Hydra V2 on-chain validators
- **id:** opp_hydra_mutation_expansion
- **kb_pattern:** null (novel)
- **value:** HIGH (3) — validator correctness is the primary security surface for the protocol
- **effort:** Low (3)
- **ROI:** 9
- **evidence:** hydra-tx/testlib/Test/Hydra/Tx/Mutation.hs (mutation framework), hydra-tx/test/Hydra/Tx/Contract/Close/ (existing contract mutation tests), PR #2536 removed vInitial/vCommit leaving vHead and vDeposit as sole attack surface

### Opportunity 5: Haddock documentation for Hydra protocol types across hydra-tx and hydra-node
- **id:** opp_hydra_haddock
- **kb_pattern:** hs_haddock_generation
- **value:** HIGH (3) — domain-specific types (HeadState, Snapshot, ContestationPeriod) require expert knowledge to document
- **effort:** Low (3)
- **ROI:** 9
- **evidence:** hydra-tx/src/Hydra/Tx/*.hs (15+ modules with transaction types), hydra-node/src/Hydra/HeadLogic/*.hs (4 submodules), hydra-plutus/src/Hydra/Contract/*.hs (12 modules). Types like HeadState, Snapshot, ContestationPeriod, BlueprintTx are consumed by multiple packages.

### Opportunity 6: AI-assisted debugging of HeadLogic snapshot state transitions
- **id:** opp_hydra_debug_state
- **kb_pattern:** hs_debug_state_transitions
- **value:** HIGH (3) — PR #2560 demonstrates 3 distinct snapshot liveness bugs from cross-module state interactions
- **effort:** Low (3)
- **ROI:** 9
- **evidence:** hydra-node/src/Hydra/HeadLogic.hs (state machine), HeadLogic/State.hs, HeadLogic/Input.hs, HeadLogic/Outcome.hs. PR #2560: snapshot liveness after version race, deposit dropped mid-snapshot, deposits from other heads leaking.

### Opportunity 7: AI-assisted PR descriptions for complex Hydra protocol changes
- **id:** opp_hydra_pr_descriptions
- **kb_pattern:** cc_pr_descriptions
- **value:** MEDIUM (2) — PR template exists (checklist), some PRs already well-described, but consistency varies
- **effort:** Low (3)
- **ROI:** 6
- **evidence:** .github/pull_request_template.md (270 bytes, checklist). PR #2536 is very detailed. PR #2555 has minimal description "fix #2498". PR #2560 has structured description.

---

## Adversarial Stage A

### Submitted to adversarial reviewer:
All 7 opportunities above, plus repo data summary.

### Adversarial Stage A results:

**Opportunity 1 (HeadLogic property corners):** APPROVED
- Passes specificity: targets HeadLogic.hs specifically, cites PR #2560 snapshot liveness bugs
- Passes grounding: Model.hs, HeadLogicSpec.hs, Gen.hs files verified in tree
- Passes feasibility: property test infrastructure fully in place
- Passes relevance: HeadLogic actively changed in PR #2536, bugs found in PR #2560

**Opportunity 2 (CLAUDE.md):** APPROVED
- Passes specificity: names 10 packages, identifies security-critical paths specific to Hydra
- Passes grounding: CLAUDE.md 14 bytes confirmed in data summary
- Passes feasibility: Low effort, one-time documentation task
- Passes relevance: team has shown intent (created CLAUDE.md file, even if placeholder)

**Opportunity 3 (.aiignore):** APPROVED
- Passes specificity: lists exact paths (hydra-plutus/src/Hydra/Contract/Head.hs, Crypto.hs)
- Passes grounding: .aiignore ABSENT confirmed, security paths verified in tree
- Passes feasibility: trivial to create
- Passes relevance: Hydra is a financial protocol — trust boundaries are critical
- **Stage A note:** Particularly important given PR #2536 radically refactored on-chain validators. Before AI is adopted, boundaries must be set.

**Opportunity 4 (mutation test expansion):** APPROVED
- Passes specificity: targets post-V2 validator surface (vHead, vDeposit) specifically
- Passes grounding: Mutation.hs verified in tree, PR #2536 refactor confirmed
- Passes feasibility: mutation framework exists, AI generates new variants
- Passes relevance: PR #2536 just reduced the validator surface — perfect time to ensure remaining validators are thoroughly tested

**Opportunity 5 (Haddock):** APPROVED with adjustment
- Passes specificity: targets hydra-tx and hydra-node protocol types specifically
- Passes grounding: module paths verified in tree
- Passes feasibility: standard Haddock tooling
- Passes relevance: actively developed packages
- **Stage A note:** Cannot verify current Haddock coverage without reading source files. Confidence on coverage gap is MEDIUM.

**Opportunity 6 (debug state transitions):** APPROVED
- Passes specificity: targets HeadLogic state machine, cites 3 specific bugs from PR #2560
- Passes grounding: HeadLogic module paths verified, PR #2560 bug descriptions verified
- Passes feasibility: state machine tracing is a strong AI use case
- Passes relevance: snapshot liveness bugs are current active development concern

**Opportunity 7 (PR descriptions):** APPROVED
- Passes specificity: notes template exists but is checklist-only, cites specific PRs with thin descriptions
- Passes grounding: template verified in tree, PR descriptions verified in PR data
- Passes feasibility: standard AI capability
- Passes relevance: active PR workflow observed
- **Stage A note:** Lowest priority among approved opportunities. Value is MEDIUM.

### Rejections: None

---

## Component Assessment

### Adoption State

All 7 opportunities: **Absent**

**Evidence:** Zero AI Co-authored-by trailers in commit history. CLAUDE.md is 14 bytes (placeholder). No .aiignore, no .cursorrules, no AGENTS.md, no copilot-instructions.md. 3 dependabot[bot] PRs are version updates, not AI-assisted development.

**Per anti-pattern `ap_attribution_absence`:** No observable AI attribution found. This does not confirm absence of AI use — attribution is not universally enforced.

### Readiness per Use Case

#### Opportunity 1 (HeadLogic property corners) — hs_quickcheck_corner_cases criteria
| Criterion | Result | Confidence | Evidence |
|-----------|--------|------------|----------|
| Arbitrary instances exist per domain type | YES | HIGH | hydra-cardano-api/testlib/Hydra/Cardano/Api/Gen.hs, hydra-tx/testlib/Test/Hydra/Tx/Gen.hs, hydra-plutus/testlib/Hydra/Plutus/Gen.hs |
| Shrinking implemented in generators | MEDIUM-CONFIDENCE YES | MEDIUM | Gen.hs files exist but cannot read contents to verify shrink implementations |
| Formal spec exists for core invariants | YES | HIGH | cardano-scaling/hydra-formal-specification repo referenced in PR #2536; docs/dev/specification.md in this repo |
| CI runs property tests | YES | HIGH | ci-nix.yaml runs nix build/check which includes cabal test suites |

**Result:** 4/4 criteria met (3 YES at HIGH, 1 YES at MEDIUM) = **Practiced**
**Confidence note:** Shrinking assessment is MEDIUM because we infer from file existence, not content.

#### Opportunity 2 (CLAUDE.md) — cc_claude_md_context criteria
| Criterion | Result | Confidence | Evidence |
|-----------|--------|------------|----------|
| AI tool in use or planned | YES | HIGH | CLAUDE.md file exists (14 bytes, placeholder — but file creation indicates intent) |

**Result:** 1/1 criteria met = **Practiced**

#### Opportunity 3 (.aiignore) — cc_aiignore_boundaries criteria
| Criterion | Result | Confidence | Evidence |
|-----------|--------|------------|----------|
| Security-critical paths identifiable in file tree | YES | HIGH | hydra-plutus/src/Hydra/Contract/*.hs, hydra-tx/src/Hydra/Tx/Crypto.hs, hydra-plutus/validators/*.ak |
| AI tools in active use | NO | HIGH | Zero AI-attributed commits, CLAUDE.md is placeholder |

**Result:** 1/2 criteria met = 50% = **Exploring**
**Note:** AI is not yet in active use, so .aiignore is a preventive/foundation measure.

#### Opportunity 4 (mutation test expansion) — No KB criteria (novel)
**Result:** Not Assessable — "No KB criteria for use-case type: mutation-test-expansion"

#### Opportunity 5 (Haddock) — hs_haddock_generation criteria
| Criterion | Result | Confidence | Evidence |
|-----------|--------|------------|----------|
| Haddock tooling configured | YES | MEDIUM | Nix-based build likely includes haddock; CI publishes docs (publish-docs.yaml workflow) |
| Module exports are explicit | MEDIUM-CONFIDENCE YES | MEDIUM | Cannot read source files; Haskell conventions in multi-package projects typically use explicit exports |
| At least some existing Haddock as style reference | MEDIUM-CONFIDENCE YES | MEDIUM | publish-docs.yaml workflow suggests Haddock generation is active; cannot verify content |

**Result:** 3/3 criteria met at MEDIUM confidence = **Practiced** (with MEDIUM confidence ceiling)

#### Opportunity 6 (debug state transitions) — hs_debug_state_transitions criteria
| Criterion | Result | Confidence | Evidence |
|-----------|--------|------------|----------|
| State transition modules identifiable in file tree | YES | HIGH | hydra-node/src/Hydra/HeadLogic.hs, HeadLogic/State.hs, HeadLogic/Input.hs, HeadLogic/Outcome.hs |
| Formal spec or invariant documentation exists | YES | HIGH | External formal spec (hydra-formal-specification), docs/dev/specification.md, docs/dev/protocol.md |
| Test coverage exists for state transitions | YES | HIGH | hydra-node/test/Hydra/HeadLogicSpec.hs, HeadLogicSnapshotSpec.hs, Model.hs, ModelSpec.hs |

**Result:** 3/3 criteria met = **Practiced**

#### Opportunity 7 (PR descriptions) — cc_pr_descriptions criteria
| Criterion | Result | Confidence | Evidence |
|-----------|--------|------------|----------|
| PR template exists | YES | HIGH | .github/pull_request_template.md (270 bytes) |
| CI runs on PRs | YES | HIGH | ci-nix.yaml triggered on pull_request events |

**Result:** 2/2 criteria met = **Practiced**

### Risk Surface

#### Path 1: hydra-plutus/src/Hydra/Contract/
- **Detection difficulty:** LOW — mutation tests in hydra-tx/test/Hydra/Tx/Contract/, golden tests in hydra-node/golden/
- **Blast radius:** HIGH — on-chain validators control head state and funds
- **AI exposure:** None — zero AI commits, CLAUDE.md placeholder
- **Evidence:** hydra-plutus/src/Hydra/Contract/Head.hs (main validator), Deposit.hs, HeadTokens.hs. Mutation testing via hydra-tx/testlib/Test/Hydra/Tx/Mutation.hs provides coverage.

#### Path 2: hydra-plutus/validators/
- **Detection difficulty:** MEDIUM — Aiken validators (deposit.ak); no evidence of Aiken-specific test framework in tree
- **Blast radius:** HIGH — on-chain deposit validator
- **AI exposure:** None
- **Evidence:** hydra-plutus/validators/deposit.ak, hydra-plutus/validators/util.ak

#### Path 3: hydra-tx/src/Hydra/Tx/Crypto.hs
- **Detection difficulty:** LOW — hydra-node/test/Hydra/CryptoSpec.hs directly tests this module
- **Blast radius:** HIGH — cryptographic operations underpin protocol security
- **AI exposure:** None
- **Evidence:** Single crypto module with dedicated test file

#### Path 4: hydra-node/src/Hydra/HeadLogic.hs + submodules
- **Detection difficulty:** LOW — extensive test coverage: HeadLogicSpec.hs, HeadLogicSnapshotSpec.hs, Model.hs, ModelSpec.hs, TxTraceSpec.hs
- **Blast radius:** HIGH — L2 protocol state machine controlling all head operations
- **AI exposure:** None
- **Evidence:** 4 submodules (State.hs, Input.hs, Outcome.hs, StateEvent.hs), model-based and property-based testing

### Opportunity-Risk Intersections (MEDIUM confidence — inferred)
- Opportunity 1 (property corners) intersects with: hydra-node/src/Hydra/HeadLogic.hs
- Opportunity 4 (mutation expansion) intersects with: hydra-plutus/src/Hydra/Contract/, hydra-plutus/validators/
- Opportunity 6 (debug state) intersects with: hydra-node/src/Hydra/HeadLogic.hs

### Ad-hoc AI Usage Flag
**Not triggered.** No AI-attributed commits detected across any area. CLAUDE.md is a placeholder. No intentionality signals needed because no AI activity was observed.

---

## Recommendation Generation

### Recommendation 1: Write a substantive CLAUDE.md covering Hydra's 10-package architecture, on-chain validators, and protocol state machine
- **Type:** start_now (Absent + Practiced)
- **Opportunity:** opp_hydra_claude_md
- **Effort:** Low — one session to write
- **Impact:** HIGH — every future AI interaction benefits
- **ROI:** 3 (impact) x 3 (effort) x 3 (gap) = 27

### Recommendation 2: Create .aiignore listing hydra-plutus/src/Hydra/Contract/, hydra-plutus/validators/, hydra-plutus/scripts/, hydra-tx/src/Hydra/Tx/Crypto.hs
- **Type:** start_now (Absent + Exploring)
- **Opportunity:** opp_hydra_aiignore
- **Effort:** Low — single file creation
- **Impact:** HIGH — prevents AI modification of security-critical on-chain code
- **ROI:** 3 x 3 x 3 = 27

### Recommendation 3: Use AI to discover untested corner cases in HeadLogic snapshot property tests
- **Type:** start_now (Absent + Practiced)
- **Opportunity:** opp_hydra_headlogic_property_corners
- **Effort:** Low — infrastructure fully in place
- **Impact:** HIGH — PR #2560 proves snapshot bugs exist and are subtle
- **ROI:** 3 x 3 x 3 = 27

### Recommendation 4: Use AI to generate mutation test variants for vHead and vDeposit validators post-V2 refactor
- **Type:** start_now (Absent + Not Assessable — but novel, infrastructure exists)
- **Opportunity:** opp_hydra_mutation_expansion
- **Effort:** Low — Mutation.hs framework exists
- **Impact:** HIGH — remaining validators are the entire on-chain attack surface
- **ROI:** 3 x 3 x 3 = 27

### Recommendation 5: Use AI to generate Haddock documentation for underdocumented hydra-tx/src/Hydra/Tx/ modules
- **Type:** start_now (Absent + Practiced)
- **Opportunity:** opp_hydra_haddock
- **Effort:** Low
- **Impact:** MEDIUM — documentation improves onboarding and maintenance
- **ROI:** 2 x 3 x 3 = 18

### Recommendation 6: Use AI to trace HeadLogic state transitions when debugging snapshot liveness issues
- **Type:** start_now (Absent + Practiced)
- **Opportunity:** opp_hydra_debug_state
- **Effort:** Low — no infrastructure changes needed
- **Impact:** MEDIUM — accelerates debugging of specific bug class
- **ROI:** 2 x 3 x 3 = 18

### Recommendation 7: Use AI to generate structured PR descriptions from diffs for hydra protocol changes
- **Type:** start_now (Absent + Practiced)
- **Opportunity:** opp_hydra_pr_descriptions
- **Effort:** Low
- **Impact:** LOW — PR descriptions already good on major PRs
- **ROI:** 1 x 3 x 3 = 9

---

## Adversarial Stage B

### Submitted to adversarial reviewer:
All 7 recommendations, assessment context, repo data.

### Adversarial Stage B results:

**Recommendation 1 (CLAUDE.md):** APPROVED
- Grounded: traces to opp_hydra_claude_md, Absent + Practiced = start_now correct
- Measurable: "CLAUDE.md exists with >500 words covering: package architecture, on-chain validators, HeadLogic state machine, testing strategy, build commands, security-critical paths"
- Actionable: clear scope, any team member can write it
- Relevant: specific to Hydra's 10-package structure

**Recommendation 2 (.aiignore):** APPROVED
- Grounded: traces to opp_hydra_aiignore, Absent + Exploring = start_now is borderline but acceptable (one criterion met is "security paths identifiable" which is the prerequisite; the missing criterion is "AI tools in active use" which makes .aiignore preventive rather than reactive)
- Measurable: ".aiignore exists listing hydra-plutus/src/Hydra/Contract/, hydra-plutus/validators/, hydra-plutus/scripts/, hydra-tx/src/Hydra/Tx/Crypto.hs"
- Actionable: trivial to create
- Relevant: specific paths named

**Recommendation 3 (HeadLogic property corners):** APPROVED
- Grounded: traces to opp_hydra_headlogic_property_corners, Absent + Practiced = start_now correct
- Measurable: "At least 3 new property tests added to HeadLogicSnapshotSpec.hs or HeadLogicSpec.hs targeting snapshot liveness invariants"
- Actionable: specific starting point (snapshot liveness from PR #2560)
- Relevant: cites specific HeadLogic modules and recent bugs

**Recommendation 4 (mutation test expansion):** APPROVED
- Grounded: novel opportunity, Not Assessable readiness. Type should technically be kb_gap. Adjusted type to kb_gap.
- Measurable: "At least 5 new mutation test cases in hydra-tx/test/Hydra/Tx/Contract/ targeting vHead and vDeposit validators"
- Actionable: Mutation.hs framework provides clear pattern to follow
- Relevant: specific to post-V2 validator surface
- **Stage B note:** Type corrected from start_now to kb_gap per schema rules. Recommendation still valuable.

**Recommendation 5 (Haddock):** APPROVED
- Grounded: traces to opp_hydra_haddock, Absent + Practiced = start_now correct
- Measurable: "At least 5 modules in hydra-tx/src/Hydra/Tx/ have doc comments on all exported functions"
- Actionable: clear starting point
- Relevant: specific package and module path

**Recommendation 6 (debug state transitions):** APPROVED
- Grounded: traces to opp_hydra_debug_state, Absent + Practiced = start_now correct
- Measurable: Tricky — debugging assistance is hard to measure. Revised: "CLAUDE.md includes a 'Debugging HeadLogic' section with state machine overview and recommended AI prompts for state tracing"
- Actionable: starts with a documentation step
- Relevant: specific to HeadLogic state machine

**Recommendation 7 (PR descriptions):** APPROVED
- Grounded: traces to opp_hydra_pr_descriptions, Absent + Practiced = start_now correct
- Measurable: "5 consecutive PRs include AI-generated 'What changed / Why / How to test' sections beyond the template checklist"
- Actionable: low friction adoption
- Relevant: cites specific template and PR patterns

### ROI Order: Correct
- Recs 1-4 tied at ROI 27, ranked by impact (all HIGH — broken by specificity and immediacy of value)
- Recs 5-6 tied at ROI 18
- Rec 7 at ROI 9

### Consistency: No contradictions found
- Rec 2 (.aiignore) and Rec 4 (mutation test expansion) are complementary: boundaries protect, then AI works within boundaries.

---

## Quadrant Computation

**AI Potential:** HIGH
- 7 approved opportunities, 6 at HIGH value
- Property test infrastructure, mutation testing, formal spec alignment — all high-value AI use cases
- Complex domain with expert-level debugging needs

**AI Activity:** LOW
- Zero AI-attributed commits
- CLAUDE.md placeholder
- No .aiignore, no AI config files with substance
- 3 dependabot PRs (automated version updates, not AI development assistance)

**Position:** High Potential, Low Activity
- "Untapped opportunity — infrastructure ready, adoption not started"

---

## Anomalies and Limitations
1. CLAUDE.md returned 404 despite existing in tree — may be a collection artifact or the file contains only whitespace
2. Cannot read Haskell source files to verify Haddock coverage or shrinking implementations — confidence capped at MEDIUM for those assessments
3. Formal spec is in a separate repo (cardano-scaling/hydra-formal-specification) — cannot assess conformance bridge completeness
4. PR data shows only 2 PRs (#2560, #2555) in detail; the "last 30 merged" set may include PRs not shown in the truncated data
5. Commit history is heavily dominated by the PR #2536 "Directly open heads" mega-refactor — churn analysis reflects this singular change
