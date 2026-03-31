# KB Proposals — Learning Scan: IntersectMBO/cardano-db-sync

> **Scan date:** 2026-03-30
> **Scan type:** Learning
> **Ecosystem:** Haskell
> **Repo:** IntersectMBO/cardano-db-sync (master)
> **Agent:** Claude Opus 4.6
> **Purpose:** Validate seed KB patterns against repo evidence, propose new patterns

---

## Seed Pattern Validation

### hs_quickcheck_corner_cases — NOT APPLICABLE

```yaml
id: hs_quickcheck_corner_cases
validation: not_applicable
confidence: HIGH
```

0 Arbitrary instances found in the data collection. The repo uses QuickCheck minimally — `cardano-chain-gen/test/Test/Cardano/Db/Mock/Property/Property.hs` imports `Test.QuickCheck` and `Test.StateMachine` for state-machine-based property testing, but this is a different pattern (model-based testing via quickcheck-state-machine, not corner-case discovery via Arbitrary generators). The `cardano-db/test/Test/Property/Cardano/Db/Types.hs` has property tests but uses IO-based integration testing against PostgreSQL. No testlib/Arbitrary.hs pattern.

### hs_haddock_generation — VALIDATED

```yaml
id: hs_haddock_generation
validation: confirmed
confidence: MEDIUM
```

**Evidence:**
- 6 cabal packages with public API surface
- No dedicated Haddock CI workflow found — the 5 workflows are: `check-fourmolu.yml`, `check-git-dependencies.yml`, `haskell.yml`, `release-binaries.yml`, `release-ghcr.yml`
- The `haskell.yml` workflow runs build + test but no explicit haddock build step visible in the first 30 lines
- Public API exists in `cardano-db-sync/src/` and `cardano-db/src/` — database schema types, sync logic, PostgreSQL interaction layer

**Gaps observed:**
- No Haddock deployment to GitHub Pages (unlike cardano-base which has gh-pages.yml)
- As a PostgreSQL sync tool, the API surface is smaller than pure-library repos, but still benefits from documentation of schema types and sync state machine
- Confidence MEDIUM because Haddock tooling may exist in nix build but is not visible in GitHub Actions workflows

### hs_debug_state_transitions — NOT APPLICABLE

```yaml
id: hs_debug_state_transitions
validation: not_applicable
confidence: MEDIUM
```

The repo does have state management (chain sync state, rollback handling) but does not use the STS framework. State transitions are imperative PostgreSQL operations, not type-level state machines. The `Test/Cardano/Db/Mock/Property/Property.hs` uses quickcheck-state-machine for model-based testing of the sync process, which is adjacent but not the STS pattern this KB entry targets.

### hs_cross_era_review — NOT APPLICABLE

No era-indexed type architecture. The repo consumes era types from cardano-ledger but does not define era-specific modules.

### hs_cddl_conformance — NOT APPLICABLE

No .cddl files. Serialization is handled via downstream dependencies.

### hs_agda_conformance — NOT APPLICABLE

No formal spec.

### hs_imp_test_generation — NOT APPLICABLE

No Imp test framework.

### hs_constrained_generators — NOT APPLICABLE

No constrained-generators dependency.

### hs_era_transition_docs — NOT APPLICABLE

No era architecture.

---

## Cross-Cutting Patterns

### cc_claude_md_context — CONFIRMED ABSENT

No CLAUDE.md or AI config files. No AI-attributed commits. CODEOWNERS file exists. CONTRIBUTING.md absent (only SECURITY.md and LICENSE). This is a gap — the repo has complex PostgreSQL schema and chain-sync logic that would benefit from a CLAUDE.md for AI-assisted development.

### cc_aiignore_boundaries — CONFIRMED APPLICABLE

Security-relevant paths:
- Database schema and migration logic (data integrity for the Cardano chain index)
- `cardano-db/` — direct PostgreSQL operations
- No .aiignore exists. No AI tools currently in use, but if adopted, database migration paths should be protected.

---

## New Pattern Proposals

None. The repo's primary testing strategy (IO-based integration tests against PostgreSQL, model-based property testing) does not align with the current Haskell seed patterns which target pure functional patterns (QuickCheck generators, STS rules, era transitions). A potential future pattern could cover "AI-assisted database migration review" but insufficient evidence from this single repo.

---

## Summary

| Seed Pattern | Status | Confidence |
|---|---|---|
| hs_quickcheck_corner_cases | NOT APPLICABLE | HIGH |
| hs_haddock_generation | VALIDATED | MEDIUM |
| hs_debug_state_transitions | NOT APPLICABLE | MEDIUM |
| hs_cross_era_review | NOT APPLICABLE | HIGH |
| hs_cddl_conformance | NOT APPLICABLE | HIGH |

| Cross-Cutting | Status |
|---|---|
| cc_claude_md_context | ABSENT — opportunity |
| cc_aiignore_boundaries | APPLICABLE — database migration paths |
