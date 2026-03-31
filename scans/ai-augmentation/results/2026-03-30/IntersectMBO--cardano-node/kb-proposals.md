# KB Proposals — Learning Scan: IntersectMBO/cardano-node
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: Haskell | Agent: Claude Opus 4.6

## Seed Pattern Validation

### hs_quickcheck_corner_cases
**NOT APPLICABLE.** Only 1 Gen file found (`cardano-node/test/Test/Cardano/Node/Gen.hs`). No Arbitrary instance files. Insufficient QuickCheck infrastructure for this pattern to apply meaningfully.

### hs_haddock_generation
**NOT APPLICABLE.** Multi-package repo (15 packages: cardano-node, cardano-testnet, cardano-tracer, locli, tx-generator, etc.) with `github-page.yml` workflow, but no dedicated haddock build scripts or haddock CI step found in tree. Haddock generation is likely handled downstream or via Nix.

### hs_debug_state_transitions
**NOT APPLICABLE.** No Rules/ or Transition/ directories. No STS modules. This repo is the node runtime, not the ledger/consensus rule engine.

### hs_cross_era_review
**NOT APPLICABLE.** No multi-era directory structure. Era-specific logic lives in cardano-ledger and ouroboros-consensus, not here.

### hs_cddl_conformance
**NOT APPLICABLE.** No .cddl files in tree. CDDL specs live in ouroboros-consensus and ouroboros-network.

### hs_agda_conformance
**NOT APPLICABLE.** No formal-spec directory. No ExecSpecRule references.

### hs_imp_test_generation
**NOT APPLICABLE.** No Imp test directories found.

### hs_constrained_generators
**NOT APPLICABLE.** No constrained-generators package or references.

### hs_era_transition_docs
**NOT APPLICABLE.** No NewEra.md or era transition documentation found.

## Cross-Cutting Patterns

### cc_claude_md_context
**NOT PRESENT.** No CLAUDE.md file in repository root or subdirectories.

### cc_aiignore_boundaries
**NOT PRESENT.** No .aiignore file found.

### cc_pr_descriptions
**PRESENT.** `.github/PULL_REQUEST_TEMPLATE.md` exists (1393 bytes). Structured PR template in use.

## AI Attribution in Commits
Co-authored-by tags found in recent commits but all are human-to-human co-authorship (e.g., Fraser Murray, Marcin Wojtowicz). No AI tool attribution detected.

## New Pattern Proposals

### Proposed: hs_performance_benchmarking
This repo has an unusually large benchmarking infrastructure (7 bench packages: cardano-profile, cardano-recon-framework, cardano-timeseries-io, cardano-topology, locli, plutus-scripts-bench, tx-generator). AI agents could assist with benchmark analysis, regression detection, and workload generation. Worth investigating as a Cardano-specific pattern.

## Summary

| Pattern | Status |
|---|---|
| hs_quickcheck_corner_cases | NOT APPLICABLE |
| hs_haddock_generation | NOT APPLICABLE |
| hs_debug_state_transitions | NOT APPLICABLE |
| hs_cross_era_review | NOT APPLICABLE |
| hs_cddl_conformance | NOT APPLICABLE |
| hs_agda_conformance | NOT APPLICABLE |
| hs_imp_test_generation | NOT APPLICABLE |
| hs_constrained_generators | NOT APPLICABLE |
| hs_era_transition_docs | NOT APPLICABLE |
| cc_claude_md_context | NOT PRESENT |
| cc_aiignore_boundaries | NOT PRESENT |
| cc_pr_descriptions | PRESENT |
