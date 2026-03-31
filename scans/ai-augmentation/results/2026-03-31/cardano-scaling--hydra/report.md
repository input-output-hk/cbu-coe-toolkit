# AAMM Report: cardano-scaling/hydra
> Scan date: 2026-03-31 | Ecosystem: haskell | Schema: v6.0

## Executive Summary

Hydra is a high-potential, low-activity repo for AI augmentation. The project has excellent infrastructure for AI adoption -- property-based testing (Model.hs, HeadLogicSpec.hs), mutation testing (Mutation.hs), formal specification alignment, and a well-structured 10-package Cabal project -- but zero observable AI usage. A 14-byte CLAUDE.md placeholder and absent .aiignore are the only AI-related signals. The recent Hydra V2 refactor (PR #2536, removing the initialization phase) creates a timely moment to establish AI practices: the on-chain attack surface is simplified and the testing infrastructure needs updating.

ROI ordering is a heuristic based on estimated value and effort -- treat as suggested priority, not certainty.

**Top opportunities** (ROI-ordered):
1. AI-assisted corner case discovery in HeadLogic snapshot property tests -- HIGH value, Low effort
2. Substantive CLAUDE.md for 10-package architecture and protocol domain -- HIGH value, Low effort
3. .aiignore trust boundaries for on-chain validators and crypto -- HIGH value, Low effort

**Top recommendations** (ROI-ordered):
1. Write CLAUDE.md covering package architecture, validators, HeadLogic, testing, security paths -- start_now
2. Create .aiignore for hydra-plutus/, validators/, scripts/, Crypto.hs -- start_now
3. Use AI to discover untested snapshot liveness invariants from PR #2560 bug patterns -- start_now

**Risk flags:**
- No Risky Acceleration flags (no AI activity detected)
- Ad-hoc AI usage flag: Not triggered

**Quadrant:** High Potential, Low Activity -- Untapped opportunity: infrastructure ready, adoption not started

---

## Opportunity Map

All opportunities passed Stage A adversarial review. 7 approved, 0 rejected.

### #1: Use AI to discover untested corner cases in HeadLogic snapshot and state machine property tests
| Field | Value |
|-------|-------|
| **ID** | opp_hydra_headlogic_property_corners |
| **Value** | HIGH -- Hydra is heavily property-test-driven; PR #2560 proves subtle snapshot bugs exist |
| **Effort** | Low -- property test infrastructure fully in place (Model.hs, Gen.hs, HeadLogicSpec.hs) |
| **ROI Rank** | 1 |
| **KB Pattern** | hs_quickcheck_corner_cases |
| **Evidence** | hydra-node/test/Hydra/Model.hs (model-based testing), hydra-node/test/Hydra/HeadLogicSnapshotSpec.hs, hydra-node/test/Hydra/HeadLogicSpec.hs, testlib Gen.hs in 3 packages. PR #2560 describes 3 snapshot liveness bugs: version race in RequestedSnapshot, deposit dropped mid-snapshot, deposits from other heads leaking into snapshot selection. |
| **Seen in** | IntersectMBO/cardano-ledger (identified generator gaps, 2026-03-28) |

### #2: Write substantive CLAUDE.md covering Hydra's 10-package architecture, on-chain validators, and protocol state machine
| Field | Value |
|-------|-------|
| **ID** | opp_hydra_claude_md |
| **Value** | HIGH -- 10 packages, on-chain validators, L2 state machine, formal spec alignment. Maximum domain knowledge benefit. |
| **Effort** | Low -- one session to write |
| **ROI Rank** | 2 |
| **KB Pattern** | cc_claude_md_context |
| **Evidence** | CLAUDE.md exists at 14 bytes (placeholder/404). Packages: hydra-node, hydra-tx, hydra-plutus, hydra-plutus-extras, hydra-cardano-api, hydra-cluster, hydra-chain-observer, hydra-tui, hydra-prelude, hydra-test-utils. |
| **Seen in** | input-output-hk/lace-platform (comprehensive CLAUDE.md) |

### #3: Create .aiignore trust boundaries for Hydra on-chain validators and cryptographic operations
| Field | Value |
|-------|-------|
| **ID** | opp_hydra_aiignore |
| **Value** | HIGH -- on-chain validators handle real funds; crypto operations critical to protocol security |
| **Effort** | Low -- single file creation |
| **ROI Rank** | 3 |
| **KB Pattern** | cc_aiignore_boundaries |
| **Evidence** | .aiignore ABSENT. Critical paths: hydra-plutus/src/Hydra/Contract/Head.hs, Deposit.hs, HeadTokens.hs; hydra-plutus/validators/deposit.ak; hydra-tx/src/Hydra/Tx/Crypto.hs; hydra-plutus/scripts/vHead.plutus, mHead.plutus. |
| **Seen in** | -- |

### #4: Use AI to expand mutation tests for vHead and vDeposit validators after Hydra V2 init-phase removal
| Field | Value |
|-------|-------|
| **ID** | opp_hydra_mutation_expansion |
| **Value** | HIGH -- vHead and vDeposit are now the entire on-chain attack surface after V2 refactor |
| **Effort** | Low -- Mutation.hs framework exists with established patterns |
| **ROI Rank** | 4 |
| **KB Pattern** | null (novel -- candidate for KB expansion) |
| **Evidence** | hydra-tx/testlib/Test/Hydra/Tx/Mutation.hs (framework), hydra-tx/test/Hydra/Tx/Contract/Close/ (existing tests). PR #2536 (b7ad7a8) removed vInitial and vCommit validators. |
| **Seen in** | -- |

### #5: Use AI to generate Haddock documentation for hydra-tx transaction types and hydra-node HeadLogic modules
| Field | Value |
|-------|-------|
| **ID** | opp_hydra_haddock |
| **Value** | HIGH -- domain-specific Plutus/Hydra types are hard to document manually |
| **Effort** | Low -- Haddock tooling configured (publish-docs.yaml) |
| **ROI Rank** | 5 |
| **KB Pattern** | hs_haddock_generation |
| **Evidence** | hydra-tx/src/Hydra/Tx/*.hs (15+ modules), hydra-node/src/Hydra/HeadLogic/*.hs (4 submodules), hydra-plutus/src/Hydra/Contract/*.hs (12 modules). publish-docs.yaml workflow publishes to hydra.family. |
| **Seen in** | IntersectMBO/cardano-ledger (45.8% Haddock coverage gap) |

### #6: Use AI to trace HeadLogic state transitions when debugging snapshot liveness and deposit coordination bugs
| Field | Value |
|-------|-------|
| **ID** | opp_hydra_debug_state |
| **Value** | HIGH -- PR #2560 demonstrates 3 distinct snapshot liveness bugs from cross-module state interactions |
| **Effort** | Low -- no infrastructure changes needed |
| **ROI Rank** | 6 |
| **KB Pattern** | hs_debug_state_transitions |
| **Evidence** | hydra-node/src/Hydra/HeadLogic.hs + State.hs, Input.hs, Outcome.hs. PR #2560: version race in RequestedSnapshot, deposit dropped mid-snapshot, deposits from other heads leaking via unfiltered pendingDeposits. |
| **Seen in** | -- |

### #7: Use AI to generate structured PR descriptions beyond checklist template for Hydra protocol changes
| Field | Value |
|-------|-------|
| **ID** | opp_hydra_pr_descriptions |
| **Value** | MEDIUM -- template exists (checklist), some PRs well-described, but consistency varies |
| **Effort** | Low -- standard AI capability |
| **ROI Rank** | 7 |
| **KB Pattern** | cc_pr_descriptions |
| **Evidence** | .github/pull_request_template.md (270 bytes, checklist). PR #2536 has extensive description. PR #2555 has minimal "fix #2498". |
| **Seen in** | -- |

---

## Risk Surface

| Path | Detection Difficulty | Blast Radius | AI Exposure | Evidence |
|------|---------------------|--------------|-------------|----------|
| hydra-plutus/src/Hydra/Contract/ | LOW | HIGH | None | On-chain validators (Head.hs, Deposit.hs, HeadTokens.hs). Mutation tests in hydra-tx/test/Hydra/Tx/Contract/. |
| hydra-plutus/validators/ | MEDIUM | HIGH | None | Aiken validators (deposit.ak). No Aiken-specific test framework detected. |
| hydra-tx/src/Hydra/Tx/Crypto.hs | LOW | HIGH | None | Cryptographic operations. Test: hydra-node/test/Hydra/CryptoSpec.hs. |
| hydra-node/src/Hydra/HeadLogic.hs | LOW | HIGH | None | L2 protocol state machine. Extensive test coverage: HeadLogicSpec.hs, ModelSpec.hs, TxTraceSpec.hs. |

**Opportunity-risk intersections** (confidence: MEDIUM -- inferred):
- opp_hydra_headlogic_property_corners intersects with hydra-node/src/Hydra/HeadLogic.hs
- opp_hydra_mutation_expansion intersects with hydra-plutus/src/Hydra/Contract/, hydra-plutus/validators/
- opp_hydra_debug_state intersects with hydra-node/src/Hydra/HeadLogic.hs

**Note:** All risk paths currently have zero AI exposure. Recommendations #1 (CLAUDE.md) and #2 (.aiignore) establish boundaries before any AI work touches these paths.

---

## Recommendations

All recommendations passed Stage B adversarial review. 7 approved, 0 rejected.

### #1: Write CLAUDE.md covering Hydra's package architecture, validators, HeadLogic, testing, and security paths
| Field | Value |
|-------|-------|
| **Type** | start_now |
| **Effort** | Low |
| **Impact** | HIGH |
| **Opportunity** | opp_hydra_claude_md |
| **Measurable outcome** | CLAUDE.md exists with >500 words covering: (1) package architecture for all 10 packages, (2) on-chain validator paths in hydra-plutus, (3) HeadLogic state machine overview, (4) testing strategy (property, model-based, mutation), (5) build commands, (6) security-critical paths |
| **Recommended learning** | Review input-output-hk/lace-platform CLAUDE.md as reference. Start with one paragraph per package. Then add security paths (hydra-plutus/src/Hydra/Contract/*.hs, Crypto.hs). Then testing strategy (Model.hs, Mutation.hs, Gen.hs). |

### #2: Create .aiignore listing on-chain validators, compiled scripts, and crypto module
| Field | Value |
|-------|-------|
| **Type** | start_now |
| **Effort** | Low |
| **Impact** | HIGH |
| **Opportunity** | opp_hydra_aiignore |
| **Measurable outcome** | .aiignore at repo root contains: hydra-plutus/src/Hydra/Contract/, hydra-plutus/validators/, hydra-plutus/scripts/, hydra-tx/src/Hydra/Tx/Crypto.hs |
| **Recommended learning** | Create .aiignore using .gitignore syntax. One path per line. Review with team to add demo/*.sk (private keys) and any other sensitive paths. Preventive measure before AI adoption. |

### #3: Use AI to discover untested snapshot liveness invariants from PR #2560 bug patterns
| Field | Value |
|-------|-------|
| **Type** | start_now |
| **Effort** | Low |
| **Impact** | HIGH |
| **Opportunity** | opp_hydra_headlogic_property_corners |
| **Measurable outcome** | At least 3 new property tests in HeadLogicSnapshotSpec.hs or HeadLogicSpec.hs targeting: version race in RequestedSnapshot, deposit dropped mid-snapshot, cross-head deposit isolation |
| **Recommended learning** | Give Claude HeadLogic/State.hs + HeadLogicSnapshotSpec.hs + PR #2560 description. Ask: "What snapshot liveness invariants are not covered? Propose 3 property tests." Review against formal spec before committing. |

### #4: Use AI to generate mutation test variants for vHead and vDeposit validators post-V2
| Field | Value |
|-------|-------|
| **Type** | kb_gap |
| **Effort** | Low |
| **Impact** | HIGH |
| **Opportunity** | opp_hydra_mutation_expansion |
| **Measurable outcome** | At least 5 new mutation test cases in hydra-tx/test/Hydra/Tx/Contract/ for vHead (Head.hs) and vDeposit (Deposit.hs), targeting mutations not covered by existing CloseInitial.hs and CloseUnused.hs |
| **Recommended learning** | Give Claude Mutation.hs + one existing test (CloseInitial.hs) + validator source (Head.hs). Ask: "What mutations would bypass existing tests?" Focus on deposit/increment flow added in V2. |

### #5: Use AI to generate Haddock for underdocumented hydra-tx transaction modules
| Field | Value |
|-------|-------|
| **Type** | start_now |
| **Effort** | Low |
| **Impact** | MEDIUM |
| **Opportunity** | opp_hydra_haddock |
| **Measurable outcome** | At least 5 modules in hydra-tx/src/Hydra/Tx/ (Close.hs, Contest.hs, Deposit.hs, Increment.hs, Snapshot.hs) have doc comments on all exported functions and types |
| **Recommended learning** | Pick Deposit.hs (actively changed in V2). Give Claude the module + importing modules. Ask: "Draft Haddock for all exported functions." Review for domain accuracy. |

### #6: Document HeadLogic state machine in CLAUDE.md with AI debugging prompts
| Field | Value |
|-------|-------|
| **Type** | start_now |
| **Effort** | Low |
| **Impact** | MEDIUM |
| **Opportunity** | opp_hydra_debug_state |
| **Measurable outcome** | CLAUDE.md includes a "Debugging HeadLogic" section with: state machine overview, key module list, at least 2 example AI prompts for debugging snapshot/deposit issues |
| **Recommended learning** | When debugging: give Claude HeadLogic.hs + State.hs + failing test output. Ask: "Trace the state transition. Which precondition is violated?" Use AI for mechanical tracing, validate against formal spec. |

### #7: Use AI to generate structured PR descriptions for protocol changes
| Field | Value |
|-------|-------|
| **Type** | start_now |
| **Effort** | Low |
| **Impact** | LOW |
| **Opportunity** | opp_hydra_pr_descriptions |
| **Measurable outcome** | 5 consecutive merged PRs include "What changed / Why / How to test" sections beyond the checklist template |
| **Recommended learning** | Before submitting a PR, run diff through Claude: "Generate PR description with What changed, Why, How to test." Edit the output -- it captures "what" well but misses "why." |

---

## Adoption State

| Opportunity | State | Evidence |
|-------------|-------|----------|
| opp_hydra_headlogic_property_corners | Absent | Zero AI Co-authored-by trailers. No AI config references property testing. |
| opp_hydra_claude_md | Absent | CLAUDE.md exists at 14 bytes (placeholder). Per anti-pattern ap_generic_claude_md, scores as absent. |
| opp_hydra_aiignore | Absent | .aiignore does not exist. |
| opp_hydra_mutation_expansion | Absent | Zero AI-attributed commits touching mutation tests. |
| opp_hydra_haddock | Absent | Zero AI-attributed commits. No AI config referencing documentation. |
| opp_hydra_debug_state | Absent | Zero AI-attributed commits touching HeadLogic. |
| opp_hydra_pr_descriptions | Absent | No AI-generated PR descriptions detected. |

No observable AI attribution found across all opportunities. This does not confirm absence of AI use -- attribution is not universally enforced.

---

## Readiness per Use Case

| Opportunity | Level | Criteria Met | Confidence |
|-------------|-------|-------------|------------|
| opp_hydra_headlogic_property_corners | Practiced | 4/4: Arbitrary instances, shrinking (MEDIUM), formal spec, CI runs tests | HIGH (3 criteria), MEDIUM (1) |
| opp_hydra_claude_md | Practiced | 1/1: AI tool intent (CLAUDE.md placeholder exists) | HIGH |
| opp_hydra_aiignore | Exploring | 1/2: Security paths identifiable (YES), AI tools active (NO) | HIGH |
| opp_hydra_mutation_expansion | Not Assessable | No KB criteria for mutation-test-expansion | -- |
| opp_hydra_haddock | Practiced | 3/3: Haddock configured, exports explicit, existing docs as reference | MEDIUM |
| opp_hydra_debug_state | Practiced | 3/3: State modules identifiable, formal spec exists, test coverage exists | HIGH |
| opp_hydra_pr_descriptions | Practiced | 2/2: PR template exists, CI runs on PRs | HIGH |

No Risky Acceleration flags. No opportunity has Active adoption + Undiscovered readiness.

---

## Evolution

First assessment. No previous scan exists for cardano-scaling/hydra.

---

## Evidence Log

### Files read
- /tmp/aamm-v6-cardano-scaling-hydra/repo-data-summary.md
- /tmp/aamm-v6-cardano-scaling-hydra/tree.json (1153 entries)
- /tmp/aamm-v6-cardano-scaling-hydra/commits.json (100 commits)
- /tmp/aamm-v6-cardano-scaling-hydra/prs.json (30 PRs)

### KB patterns evaluated
- **Matched:** hs_quickcheck_corner_cases, hs_haddock_generation, hs_debug_state_transitions, cc_pr_descriptions, cc_claude_md_context, cc_aiignore_boundaries
- **Not matched:** hs_cross_era_review (no multi-era architecture), hs_cddl_conformance (no .cddl files), hs_agda_conformance (formal spec external, no conformance bridge), hs_imp_test_generation (no Imp framework), hs_constrained_generators (not used), hs_era_transition_docs (no era transitions), cc_commit_messages (good commit quality), cc_onboarding_docs (CONTRIBUTING.md substantive)
- **Novel:** mutation-test-expansion (proposed for KB)

### Anti-patterns checked
- ap_generic_claude_md: Applied -- CLAUDE.md 14 bytes treated as absent
- ap_attribution_absence: Applied -- all Absent states note attribution limitation
- ap_docs_not_architecture: Applied -- docs/ not counted as architecture docs
- ap_empty_pr_placeholders: No Cursor/AI markers found in PR data

### Confidence summary
- HIGH: file existence, AI attribution absence, security path identification, test file existence
- MEDIUM: Haddock coverage gap (cannot read source), shrinking in generators (file exists but unread), module export style
- LOW: effort estimates (subjective per scoring-model.md rules)

### Adversarial review outcomes
- Stage A: 7/7 opportunities approved
- Stage B: 7/7 recommendations approved (1 type corrected: opp_hydra_mutation_expansion from start_now to kb_gap)
