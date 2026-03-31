# KB Proposals — Learning Scan: input-output-hk/Lean-blaster
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: Lean | Agent: Claude Opus 4.6

## Cross-Cutting Patterns

### cc_claude_md_context
**Status: NOT PRESENT**
No `CLAUDE.md` found. Public repo (35 stars, SMT-based reasoning core for Lean4, 251 files). 6 AI-attributed commits suggest active AI-assisted development. AI agent context would be valuable for this specialized domain.

### cc_aiignore_boundaries
**Status: NOT PRESENT**
No `.aiignore` found. Public repo with Apache-2.0 license. Low security risk, but SMT solver integration code may benefit from boundaries to prevent AI from modifying soundness-critical paths.

### cc_pr_descriptions
**Status: ACTIVE**
Active PR workflow. PR template at `.github/pull_request_template.md` (1920 bytes -- substantial). Issue templates for bug reports and feature requests. CI workflows: `ci-linux.yaml`, `ci-nightly-build.yaml`. Recent PR #104 merged 2026-03-30. 54 open issues. Has GitHub Pages enabled.

### cc_onboarding_docs
**Status: PARTIAL**
`README.md` present. `LICENSE` present (Apache-2.0). No `CONTRIBUTING.md` found. Issue templates provide some contributor guidance. No `CODEOWNERS`.

## New Pattern Proposals

### Proposed: lean_smt_solver_integration
This repo integrates Lean4 with external SMT solvers for automated theorem proving. The pattern of a functional proof assistant delegating to an external solver is architecturally unique. AI agents working here need to understand the boundary between Lean proof terms and SMT queries.

### Proposed: lean_nightly_ci
The `ci-nightly-build.yaml` workflow (3881 bytes) suggests compatibility testing against upstream Lean toolchain changes. This pattern of nightly builds against moving targets is common in language-tooling repos and could be a cross-cutting signal.

## Summary
| Pattern | Status |
|---|---|
| cc_claude_md_context | Not present |
| cc_aiignore_boundaries | Not present |
| cc_pr_descriptions | Active (PR template, issue templates, CI + nightly) |
| cc_onboarding_docs | Partial (README, no CONTRIBUTING.md) |
