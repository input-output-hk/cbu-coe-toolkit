# KB Proposals — Learning Scan: IntersectMBO/cardano-haskell-packages
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: Shell | Agent: Claude Opus 4.6

## Cross-Cutting Patterns

### cc_claude_md_context
**Status: NOT PRESENT**
No `CLAUDE.md` found in repository tree. This is a package registry repo (5755 files, mostly `.cabal` revisions); AI agent context could help contributors understand the packaging conventions and CI validation process.

### cc_aiignore_boundaries
**Status: NOT PRESENT**
No `.aiignore` found. The repo contains no secrets or security-critical code -- it is a Haskell package metadata registry. Low risk, but the `_repo/` build output directory and `flake.lock` could benefit from exclusion.

### cc_pr_descriptions
**Status: ACTIVE**
Active PR workflow confirmed. PR template present at `.github/PULL_REQUEST_TEMPLATE.md` (166 bytes). Recent PRs (e.g., #1318, #1319) use merge-via-GitHub with descriptive commit messages. High-cadence: multiple PRs merged same day (2026-03-30). Dependabot configured (`.github/dependabot.yml`).

### cc_onboarding_docs
**Status: PRESENT**
`CONTRIBUTING.md` present (2296 bytes). Also has `CODE-OF-CONDUCT.md`, `SECURITY.md`, `CODEOWNERS` (11509 bytes -- comprehensive ownership rules), and `README.md` (24366 bytes -- substantial). Good onboarding surface.

## New Pattern Proposals

### Proposed: cc_codeowners_coverage
This repo has an unusually detailed `CODEOWNERS` file (11.5 KB) mapping individual package paths to responsible maintainers. This pattern -- granular code ownership for package registries -- could be a cross-cutting KB signal for repos managing many independent components.

## Summary
| Pattern | Status |
|---|---|
| cc_claude_md_context | Not present |
| cc_aiignore_boundaries | Not present |
| cc_pr_descriptions | Active (PR template + high-cadence merges) |
| cc_onboarding_docs | Present (CONTRIBUTING.md, CODEOWNERS, README) |
