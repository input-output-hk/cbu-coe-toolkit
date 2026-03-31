# KB Proposals — Learning Scan: input-output-hk/glyph
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: UPLC (Untyped Plutus Core) / Rust | Agent: Claude Opus 4.6

## Cross-Cutting Patterns

### cc_claude_md_context
**Status: NOT PRESENT**
No `CLAUDE.md`. Public repo (8520 files, 3 stars). UPLC-to-RISC-V compiler written in Rust. The large file count is driven by conformance test fixtures (`tests/conformance/` and `tests/semantics/`).

### cc_aiignore_boundaries
**Status: NOT PRESENT**
No `.aiignore`. The repo has extensive test fixture directories (thousands of `.uplc` and related files in `tests/conformance/v2/`, `tests/conformance/v3/`, `tests/semantics/`). These should be excluded from AI context to avoid token waste. Has `.cargo/config.toml`.

### cc_pr_descriptions
**Status: ACTIVE**
Active PR workflow. Recent PR #72 "Refactor" merged. Multiple CI workflows: `ci.yml`, `release.yml` (13568 bytes -- comprehensive multi-platform release), `runtime.yml`. 4 open issues. Commits use conventional-ish messages ("Chores: cargo fmt & clippy"). Has `CHANGELOG.md`.

### cc_onboarding_docs
**Status: PRESENT**
`CONTRIBUTING.md` present (1645 bytes). `README.md` present. `CHANGELOG.md` present. `LICENSE` present (Apache-2.0). Good contributor documentation for a compiler project.

## New Pattern Proposals

### Proposed: uplc_conformance_test_corpus
glyph has a massive conformance test suite (thousands of `.uplc` test files covering v2 and v3 builtins, semantics, BLS12-381 crypto operations). This pattern of compiler-conformance testing via large fixture corpora is relevant for AI-augmentation: AI agents should not read these files as context but could help generate new test cases.

### Proposed: rust_release_pipeline
The `release.yml` workflow (13.5 KB) implements comprehensive multi-platform binary releases. This Rust-specific CI pattern for cross-compilation and artifact publishing is a potential ecosystem KB signal.

## Summary
| Pattern | Status |
|---|---|
| cc_claude_md_context | Not present |
| cc_aiignore_boundaries | Not present (strongly recommended for test fixtures) |
| cc_pr_descriptions | Active (multi-workflow CI, release pipeline) |
| cc_onboarding_docs | Present (CONTRIBUTING.md, CHANGELOG.md, README) |
