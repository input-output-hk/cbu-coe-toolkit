# KB Proposals — Learning Scan: IntersectMBO/ouroboros-consensus
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: Haskell | Agent: Claude Opus 4.6

## Seed Pattern Validation

### hs_quickcheck_corner_cases
**VALIDATED.** QuickCheck infrastructure present with Arbitrary instances and dedicated QuickCheck extras module:
- `ouroboros-consensus/src/unstable-consensus-testlib/Test/Util/Orphans/Arbitrary.hs`
- `ouroboros-consensus/src/unstable-consensus-testlib/Test/Ouroboros/Consensus/QuickCheck/Extras.hs`
- `ouroboros-consensus-diffusion/src/unstable-diffusion-testlib/Test/ThreadNet/TxGen.hs` (transaction generators)

Note: User reported 6 Arbitrary files; tree search surfaced 1 Arbitrary.hs directly. Additional Arbitrary instances likely exist inline within test modules not named "Arbitrary". Pattern is validated based on dedicated QuickCheck infrastructure.

### hs_haddock_generation
**VALIDATED.** Multi-package repo (5 packages) with dedicated Haddock infrastructure:
- `.github/workflows/documentation.yml` — CI workflow for docs
- `docs/haddocks/` — Haddock output directory
- `scripts/docs/haddocks.sh` — Haddock generation script
- `scripts/docs/prologue.haddock` — Custom haddock prologue
- `docs/website/contents/references/haddocks.md` — Haddock reference docs

### hs_debug_state_transitions
**VALIDATED.** Rules and consensus protocol state transitions present:
- `ouroboros-consensus-cardano/src/unstable-byronspec/Ouroboros/Consensus/ByronSpec/Ledger/Rules.hs`
- `ouroboros-consensus/src/ouroboros-consensus/Ouroboros/Consensus/Peras/Voting/Rules.hs`
- `docs/formal-spec/sts-overview.tex` — STS formal specification
- `docs/formal-spec/rules.dot` / `rules.pdf` — Rule dependency diagrams

### hs_cross_era_review
**VALIDATED.** Multi-era golden test directories confirm cross-era support:
- `ouroboros-consensus-cardano/golden/cardano/QueryVersion2/CardanoNodeToClientVersion12/` (multiple era-specific files: WrongEraByron, WrongEraShelley, EraMismatchByron, EraMismatchShelley)
- Same pattern repeats for Version13, Version14
- `docs/website/contents/howtos/adding_an_era.md` — era addition howto

### hs_cddl_conformance
**VALIDATED.** 13 CDDL spec files in `ouroboros-consensus-cardano/cddl/`:
- `ouroboros-consensus-cardano/cddl/base.cddl`
- `ouroboros-consensus-cardano/cddl/disk/immutable/chunkFile.cddl`
- `ouroboros-consensus-cardano/cddl/disk/ledger/headerstate.cddl`
- `ouroboros-consensus-cardano/cddl/disk/ledger/ledgerstate.cddl`
- `ouroboros-consensus-cardano/cddl/disk/ledger/pbft.cddl`
- `ouroboros-consensus-cardano/cddl/disk/ledger/praos.cddl`
- `ouroboros-consensus-cardano/cddl/disk/ledger/stateFile.cddl`
- `ouroboros-consensus-cardano/cddl/disk/ledger/tpraos.cddl`
- `ouroboros-consensus-cardano/cddl/disk/volatile/blocksDatFile.cddl`
- `ouroboros-consensus-cardano/cddl/node-to-node/blockfetch/block.cddl`
- `ouroboros-consensus-cardano/cddl/node-to-node/chainsync/header.cddl`
- `ouroboros-consensus-cardano/cddl/node-to-node/txsubmission2/tx.cddl`
- `ouroboros-consensus-cardano/cddl/node-to-node/txsubmission2/txId.cddl`
Plus `nix/cddlc/` tooling for CDDL validation.

### hs_agda_conformance
**VALIDATED.** Agda formal specification with Haskell conformance tests:
- `docs/agda-spec/src/formal-consensus.agda-lib` — Agda library definition
- `docs/agda-spec/src/Spec/hs-src/test/ChainHeadSpec.hs`
- `docs/agda-spec/src/Spec/hs-src/test/OperationalCertificateSpec.hs`
- `docs/agda-spec/src/Spec/hs-src/test/ProtocolSpec.hs`
- `docs/agda-spec/src/Spec/hs-src/test/TickForecastSpec.hs`
- `docs/agda-spec/src/Spec/hs-src/test/TickNonceSpec.hs`
- `docs/agda-spec/src/Spec/hs-src/test/UpdateNonceSpec.hs`
- `docs/agda-spec/src/Spec/hs-src/cardano-consensus-executable-spec.cabal`
- `docs/agda-spec/src/Spec/Foreign/HSConsensus/OperationalCertificate.agda` — FFI bridge
- `docs/formal-spec/` — LaTeX formal specification (18 files)

### hs_imp_test_generation
**NOT APPLICABLE.** No Imp test directories found. Imp-style testing is a cardano-ledger pattern.

### hs_constrained_generators
**NOT APPLICABLE.** No constrained-generators package or references found.

### hs_era_transition_docs
**VALIDATED.** Era transition documentation present:
- `docs/website/contents/howtos/adding_an_era.md`
- `docs/website/contents/references/miscellaneous/era_transition_governance.md`

## Cross-Cutting Patterns

### cc_claude_md_context
**NOT PRESENT.** No CLAUDE.md file found.

### cc_aiignore_boundaries
**NOT PRESENT.** No .aiignore file found.

### cc_pr_descriptions
**PRESENT.** `.github/PULL_REQUEST_TEMPLATE.md` exists (294 bytes). Lightweight template.

## AI Attribution in Commits
Co-authored-by tags found (Nicolas Bacquey, Thomas Bagrel, Agustin Mista) but all human-to-human. No AI tool attribution detected in recent 30 commits.

## New Pattern Proposals

### Proposed: hs_agda_haskell_ffi_bridge
ouroboros-consensus has a unique pattern: Agda specs compiled to Haskell via FFI (`docs/agda-spec/src/Spec/Foreign/HSConsensus/`), then tested against the production Haskell implementation. AI agents could assist with maintaining the FFI bridge and ensuring conformance tests stay in sync when either the Agda spec or Haskell implementation changes.

## Summary

| Pattern | Status |
|---|---|
| hs_quickcheck_corner_cases | VALIDATED |
| hs_haddock_generation | VALIDATED |
| hs_debug_state_transitions | VALIDATED |
| hs_cross_era_review | VALIDATED |
| hs_cddl_conformance | VALIDATED |
| hs_agda_conformance | VALIDATED |
| hs_imp_test_generation | NOT APPLICABLE |
| hs_constrained_generators | NOT APPLICABLE |
| hs_era_transition_docs | VALIDATED |
| cc_claude_md_context | NOT PRESENT |
| cc_aiignore_boundaries | NOT PRESENT |
| cc_pr_descriptions | PRESENT |
