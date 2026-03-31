# KB Proposals — Learning Scan: IntersectMBO/ouroboros-network
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: Haskell | Agent: Claude Opus 4.6

## Seed Pattern Validation

### hs_quickcheck_corner_cases
**VALIDATED.** QuickCheck infrastructure present:
- `ouroboros-network/tests-lib/lib/Test/Ouroboros/Network/QuickCheck.hs`
- `quickcheck-monoids/src/Test/QuickCheck/Monoids.hs` — dedicated QuickCheck helper package (`quickcheck-monoids/quickcheck-monoids.cabal`)

Note: User reported 1 Arbitrary file. No standalone Arbitrary.hs found but QuickCheck test infrastructure exists. The `quickcheck-monoids` package is a novel test utility.

### hs_haddock_generation
**VALIDATED.** Multi-package repo (8 packages: ouroboros-network, cardano-diffusion, network-mux, cardano-ping, ntp-client, monoidal-synchronisation, acts-generic, quickcheck-monoids) with Haddock publishing:
- `.github/workflows/github-page.yml` — GitHub Pages workflow for docs

### hs_debug_state_transitions
**NOT APPLICABLE.** No Rules/ or Transition/ modules found. This repo implements network protocols (diffusion layer), not consensus state transitions.

### hs_cross_era_review
**NOT APPLICABLE.** No multi-era directory structure. Network protocols are era-agnostic at this layer.

### hs_cddl_conformance
**VALIDATED.** 22 CDDL spec files in `cardano-diffusion/protocols/cddl/specs/`:
- `cardano-diffusion/protocols/cddl/specs/block-fetch.cddl`
- `cardano-diffusion/protocols/cddl/specs/chain-sync.cddl`
- `cardano-diffusion/protocols/cddl/specs/handshake-node-to-client.cddl`
- `cardano-diffusion/protocols/cddl/specs/handshake-node-to-node-v14.cddl`
- `cardano-diffusion/protocols/cddl/specs/keep-alive.cddl`
- `cardano-diffusion/protocols/cddl/specs/local-state-query.cddl`
- `cardano-diffusion/protocols/cddl/specs/local-tx-monitor.cddl`
- `cardano-diffusion/protocols/cddl/specs/local-tx-submission.cddl`
- `cardano-diffusion/protocols/cddl/specs/network.base.cddl`
- `cardano-diffusion/protocols/cddl/specs/node-to-node-version-data-v14.cddl`
- `cardano-diffusion/protocols/cddl/specs/node-to-node-version-data-v16.cddl`
- `cardano-diffusion/protocols/cddl/specs/object-diffusion.cddl`
- `cardano-diffusion/protocols/cddl/specs/peer-sharing-v14.cddl`
- `cardano-diffusion/protocols/cddl/specs/tx-submission2.cddl`
- `cardano-diffusion/protocols/cddl/specs/obsolete/handshake-node-to-node-v11-12.cddl`
- `cardano-diffusion/protocols/cddl/specs/obsolete/handshake-node-to-node-v13.cddl`
- `cardano-diffusion/protocols/cddl/specs/obsolete/handshake-node-to-node.cddl`
- `cardano-diffusion/protocols/cddl/specs/obsolete/node-to-node-version-data-v11-12.cddl`
- `cardano-diffusion/protocols/cddl/specs/obsolete/node-to-node-version-data-v13.cddl`
- `cardano-diffusion/protocols/cddl/specs/obsolete/node-to-node-version-data.cddl`
- `cardano-diffusion/protocols/cddl/specs/obsolete/peer-sharing-v11-12.cddl`
- `cardano-diffusion/protocols/cddl/specs/obsolete/peer-sharing-v13.cddl`
Plus `cardano-diffusion/protocols/cddl/Main.hs` (CDDL test runner) and `nix/cddlc/` tooling.

### hs_agda_conformance
**NOT APPLICABLE.** No formal-spec directory or Agda files.

### hs_imp_test_generation
**NOT APPLICABLE.** No Imp test directories.

### hs_constrained_generators
**NOT APPLICABLE.** No constrained-generators references.

### hs_era_transition_docs
**NOT APPLICABLE.** No NewEra.md or era transition documentation. Network layer is era-agnostic.

## Cross-Cutting Patterns

### cc_claude_md_context
**NOT PRESENT.** No CLAUDE.md file found.

### cc_aiignore_boundaries
**NOT PRESENT.** No .aiignore file found.

### cc_pr_descriptions
**PRESENT.** `.github/PULL_REQUEST_TEMPLATE.md` exists (1007 bytes).

## AI Attribution in Commits
Extensive Co-authored-by tags found in Peras-related commits (ObjectDiffusion mini-protocol, NodeToNodeV_16, PerasSupport), all human-to-human multi-author collaboration across teams (Agustin Mista, Alexander Esgen, Georgy Lukyanov, Thomas Bagrel, Nicolas Bacquey, Nicolas Jeannerod). No AI tool attribution detected.

## New Pattern Proposals

### Proposed: hs_protocol_version_migration
ouroboros-network has a clear versioned protocol pattern visible in CDDL: `obsolete/` directory contains deprecated protocol versions (v11-12, v13) alongside current versions (v14, v16). AI agents could assist with protocol version bumps by generating new CDDL specs from existing ones, updating version negotiation logic, and ensuring backward compatibility tests cover the migration path.

## Summary

| Pattern | Status |
|---|---|
| hs_quickcheck_corner_cases | VALIDATED |
| hs_haddock_generation | VALIDATED |
| hs_debug_state_transitions | NOT APPLICABLE |
| hs_cross_era_review | NOT APPLICABLE |
| hs_cddl_conformance | VALIDATED |
| hs_agda_conformance | NOT APPLICABLE |
| hs_imp_test_generation | NOT APPLICABLE |
| hs_constrained_generators | NOT APPLICABLE |
| hs_era_transition_docs | NOT APPLICABLE |
| cc_claude_md_context | NOT PRESENT |
| cc_aiignore_boundaries | NOT PRESENT |
| cc_pr_descriptions | PRESENT |
