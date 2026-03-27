# Rust Ecosystem Patterns

## Inline test modules invisible to file-count ratio

```yaml
source: iog-scan
repos: [mithril]
category: safety-net
status: validated
discovered: 2026-03-26
updated: 2026-03-27
```

Rust `#[cfg(test)]` inline modules are invisible to file-based detection.
mithril: 53% of files had inline tests, 169+ `#[test]` not counted.
Depth must sample source files for `#[cfg(test)]` blocks.

**Applicability:** All Rust repos.

## clippy + rustfmt as standard tooling

```yaml
source: ecosystem-standard
repos: []
category: structure
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

Clippy (including `clippy::style`), rustfmt. Detection in CI or Makefile.

**Applicability:** All Rust repos.

## cargo workspace for multi-crate structure

```yaml
source: ecosystem-standard
repos: [mithril]
category: structure
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

Cargo workspaces (`[workspace]` in root `Cargo.toml` with `members` list) define
crate boundaries in multi-crate repos. Equivalent to cabal multi-package for Haskell.
Detection: `Cargo.toml` at root with `[workspace]` section.

**Applicability:** All Rust repos with multiple crates.

## cargo-deny advisories vs licenses

```yaml
source: iog-scan
repos: [mithril]
category: safety-net
status: validated
discovered: 2026-03-26
updated: 2026-03-27
```

`cargo deny check advisories` = CVE scanning. `cargo deny check licenses` = NOT CVE scanning.
Only `check advisories` or bare `check` counts for security.

**Applicability:** All Rust repos using cargo-deny.
