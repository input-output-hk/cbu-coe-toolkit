# KB Proposals — Learning Scan: IntersectMBO/cardano-cli
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: Haskell | Agent: Claude Opus 4.6

## Seed Pattern Validation

### hs_quickcheck_corner_cases
**NOT APPLICABLE.** No Arbitrary instance files. No Gen.hs files (only golden test KeyGen files which are CLI key generation tests, not QuickCheck generators). Single-package repo with golden tests, not property tests.

### hs_haddock_generation
**VALIDATED.** Single package (`cardano-cli/cardano-cli.cabal`) with `github-page.yml` workflow for Haddock publishing. Public API surface for CLI command construction. Evidence:
- `.github/workflows/github-page.yml`
- `cardano-cli/cardano-cli.cabal`

### hs_debug_state_transitions
**NOT APPLICABLE.** No Rules/ or Transition/ directories. CLI is a command parser/executor, not a state machine.

### hs_cross_era_review
**NOT APPLICABLE.** No multi-era directory structure. Era handling is delegated to cardano-api.

### hs_cddl_conformance
**NOT APPLICABLE.** No .cddl files.

### hs_agda_conformance
**NOT APPLICABLE.** No formal-spec directory.

### hs_imp_test_generation
**NOT APPLICABLE.** No Imp test directories.

### hs_constrained_generators
**NOT APPLICABLE.** No constrained-generators references.

### hs_era_transition_docs
**NOT APPLICABLE.** No NewEra.md or era transition documentation.

## Cross-Cutting Patterns

### cc_claude_md_context
**NOT PRESENT.** No CLAUDE.md file found.

### cc_aiignore_boundaries
**NOT PRESENT.** No .aiignore file found.

### cc_pr_descriptions
**PRESENT.** `.github/PULL_REQUEST_TEMPLATE.md` exists (1645 bytes). Structured PR template in use.

## AI Attribution in Commits
One Co-authored-by found: human-to-human (Mateusz Galazyn). No AI tool attribution detected in recent 30 commits.

## New Pattern Proposals

### Proposed: hs_golden_test_maintenance
This repo has extensive golden test infrastructure (`cardano-cli/test/cardano-cli-golden/`) with `Test/Golden/ErrorsSpec.hs` and many era-specific golden tests. AI agents could assist with golden file updates when CLI output format changes, which is a frequent maintenance burden during era transitions.

## Summary

| Pattern | Status |
|---|---|
| hs_quickcheck_corner_cases | NOT APPLICABLE |
| hs_haddock_generation | VALIDATED |
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
