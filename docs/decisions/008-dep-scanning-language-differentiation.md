# ADR-008: Dep Scanning Penalty — Language Differentiation

**Date:** 2026-03-26 · **Status:** Accepted
**Applies to:** `scripts/aamm/score-readiness.sh` (penalty 2 block)

## Rule

The "ecosystem lacks tooling" rationale for skipping the vulnerability monitoring penalty is now gated by language:

| Language | Condition | Penalty | Rationale |
|----------|-----------|---------|-----------|
| Haskell | Lockfile/cabal.project present, no CVE scanner | 0 | cabal-audit is early stage; Nix pins hashes but doesn't scan advisories — accepted tooling gap |
| Rust | Lockfile/flake present, no `cargo-deny check advisories` | **-5** | cargo-deny is mature, widely adopted, and expected |
| TypeScript/JS | Lockfile present, no dependabot/renovate covering npm | **-5** | Full Dependabot support exists for npm |
| Python/Go/etc. | Lockfile present, no scanner | **-5** | Mature tooling exists |

`cargo-deny check licenses` does **not** count as CVE scanning. Only `cargo-deny check advisories` or bare `cargo deny check` (which includes advisories) counts.

## Anti-patterns

- Do NOT credit `cargo-deny` presence in CI as `HAS_CI_SECURITY=1` without checking the subcommand — `check licenses` scans for license compliance, not vulnerabilities.
- Do NOT apply the Haskell rationale to Rust, TypeScript, or any other ecosystem — "ecosystem lacks tooling" is specifically scoped to Haskell/Nix.
- Do NOT treat `flake.lock` as equivalent to CVE scanning — Nix pins reproducibility at hash level; a pinned hash can still be a vulnerable version.

## Context

Previous script applied a single `HAS_DEP_STRATEGY=1` shortcut (any lockfile present → 0 penalty, "ecosystem lacks tooling") to all languages. This caused:
- mithril (Rust): 0 penalty despite no `cargo-deny check advisories`. cargo-deny is a mature tool with an official GitHub Action (`EmbarkStudios/cargo-deny-action`).
- lace-platform (TypeScript): 0 penalty despite no dependabot covering npm. npm has full Dependabot support; "ecosystem lacks tooling" is factually wrong.

Haskell retains 0 penalty: cabal-audit exists but is early-stage, and the Cardano ecosystem relies on Nix supply-chain integrity as its primary defence. This is a conscious team choice, not a tooling gap.

## Consequences

- **Changed:** `score-readiness.sh` — `HAS_DEP_STRATEGY` branch now splits by `$PRIMARY_LANG`
- **Score impact:** Rust repos without cargo-deny advisories: -5 from this session forward. TypeScript repos with only github-actions dependabot coverage: -5.
- **Must maintain:** If a new language is added to the scanner, explicitly decide its penalty tier in this ADR before adding it to the script.
