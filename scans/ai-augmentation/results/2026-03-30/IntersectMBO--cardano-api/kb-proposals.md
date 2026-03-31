# KB Proposals — Learning Scan: IntersectMBO/cardano-api
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: Haskell | Agent: Claude Opus 4.6

## Seed Pattern Validation

### hs_quickcheck_corner_cases
**NOT APPLICABLE.** No Arbitrary instance files found in tree. The `cardano-api-gen` package exists but no Arbitrary.hs files surfaced. Insufficient evidence for this pattern.

### hs_haddock_generation
**VALIDATED.** Multi-package repo (4 packages: cardano-api, cardano-api-gen, cardano-rpc, cardano-wasm) with public API surface. Evidence:
- `cardano-api/cardano-api.cabal` — core public API package
- `cardano-api-gen/cardano-api-gen.cabal` — test generator package
- `.github/workflows/github-page.yml` (inferred from CLI sibling pattern)

### hs_debug_state_transitions
**VALIDATED.** Rule/Transition modules present in API internals for ledger state inspection:
- `cardano-api/src/Cardano/Api/LedgerState/Internal/Rule/BBODY/DELEGS.hs`
- `cardano-api/src/Cardano/Api/LedgerState/Internal/Rule/BBODY/LEDGER.hs`
- `cardano-api/src/Cardano/Api/LedgerState/Internal/Rule/BBODY/UTXOW.hs`
- `cardano-api/src/Cardano/Api/LedgerState/Internal/Rule/TICK/NEWEPOCH.hs`
- `cardano-api/src/Cardano/Api/LedgerState/Internal/Rule/TICK/RUPD.hs`

These wrap ledger STS rules for API consumers. AI could assist with debugging state transition failures surfaced through the API layer.

### hs_cross_era_review
**NOT APPLICABLE.** No multi-era directory structure in the tree. Era polymorphism is handled via type-level mechanisms, not directory separation.

### hs_cddl_conformance
**NOT APPLICABLE.** No .cddl files found.

### hs_agda_conformance
**NOT APPLICABLE.** No formal-spec directory or ExecSpecRule references.

### hs_imp_test_generation
**NOT APPLICABLE.** No Imp test directories.

### hs_constrained_generators
**NOT APPLICABLE.** No constrained-generators references.

### hs_era_transition_docs
**NOT APPLICABLE.** No NewEra.md or explicit era transition documentation.

## Cross-Cutting Patterns

### cc_claude_md_context
**NOT PRESENT.** No CLAUDE.md file. However, `.github/copilot-instructions.md` exists (1881 bytes) -- this is a Copilot-specific AI context file, functionally similar to CLAUDE.md but for GitHub Copilot.

### cc_aiignore_boundaries
**NOT PRESENT.** No .aiignore file found.

### cc_pr_descriptions
**PRESENT.** `.github/PULL_REQUEST_TEMPLATE.md` exists (1799 bytes).

## AI Attribution in Commits
**ACTIVE AI USAGE DETECTED.** Copilot SWE Agent commits found:
- `copilot-swe-agent[bot]` authored "Add Copilot instructions to ignore sha256 comment mismatches in cabal.project"
- PR #1145 merged from `IntersectMBO/copilot/sub-pr-1144`
This repo is actively using GitHub Copilot SWE Agent for automated contributions.

## New Pattern Proposals

### Proposed: cc_copilot_instructions
New cross-cutting pattern: `.github/copilot-instructions.md` provides AI agent context similar to CLAUDE.md but for GitHub Copilot. cardano-api is the first repo in this scan batch with this file. Worth tracking as an emerging AI-readiness signal across the Cardano ecosystem.

## Summary

| Pattern | Status |
|---|---|
| hs_quickcheck_corner_cases | NOT APPLICABLE |
| hs_haddock_generation | VALIDATED |
| hs_debug_state_transitions | VALIDATED |
| hs_cross_era_review | NOT APPLICABLE |
| hs_cddl_conformance | NOT APPLICABLE |
| hs_agda_conformance | NOT APPLICABLE |
| hs_imp_test_generation | NOT APPLICABLE |
| hs_constrained_generators | NOT APPLICABLE |
| hs_era_transition_docs | NOT APPLICABLE |
| cc_claude_md_context | NOT PRESENT (copilot-instructions.md present) |
| cc_aiignore_boundaries | NOT PRESENT |
| cc_pr_descriptions | PRESENT |
