# KB Proposals — Learning Scan: input-output-hk/haskell.nix
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: Nix | Agent: Claude Opus 4.6

## Cross-Cutting Patterns

### cc_claude_md_context
**Status: NOT PRESENT**
No `CLAUDE.md` found. This is a complex Nix infrastructure project (6524 files, 622 stars) where AI agent context would be particularly valuable given the non-standard build system and deep Nix expertise required.

### cc_aiignore_boundaries
**Status: NOT PRESENT**
No `.aiignore` found. The repo contains no secrets, but has generated/vendored content that AI agents should skip (e.g., materialized Nix plans, test fixtures).

### cc_pr_descriptions
**Status: ACTIVE**
Active PR workflow. Recent PRs (#2484, #2485, #2489) merged via GitHub with substantive descriptions. Commit messages are detailed and reference issue numbers. Multiple CI workflows: `pipeline.yml`, `lints.yml`, `publish.yaml`, `tag.yml`, `update-docs.yml`. Issue templates present (bug report, feature request).

### cc_onboarding_docs
**Status: PARTIAL**
`README.md` present (repo has GitHub Pages docs site at input-output-hk.github.io/haskell.nix). No `CONTRIBUTING.md` found in tree. No `CODEOWNERS`. Has `.envrc` for direnv integration. Stale issue management configured (`.github/stale.yml`).

## New Pattern Proposals

### Proposed: nix_flake_reproducibility
Nix-based repos have a unique pattern: `flake.nix` + `flake.lock` provide fully reproducible builds. This is analogous to lockfiles in other ecosystems but with stronger guarantees. Could be a Nix-ecosystem KB pattern for build reproducibility assessment.

### Proposed: nix_materialized_plans
haskell.nix uses materialized Nix plans (pre-computed dependency resolution). This pattern of caching expensive computations as committed artifacts is specific to Nix-Haskell tooling and affects how AI agents should reason about generated vs. authored files.

## Summary
| Pattern | Status |
|---|---|
| cc_claude_md_context | Not present |
| cc_aiignore_boundaries | Not present |
| cc_pr_descriptions | Active (detailed PRs, multi-workflow CI) |
| cc_onboarding_docs | Partial (README + docs site, no CONTRIBUTING.md) |
