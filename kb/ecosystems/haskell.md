# Haskell Ecosystem Patterns

## Nix-wrapped CI hides tools from direct grep

```yaml
source: iog-scan
repos: [cardano-ledger, cardano-node, ouroboros-consensus]
category: structure
status: validated
discovered: 2026-03-26
updated: 2026-03-27
```

Haskell repos run hlint/fourmolu via `nix develop --command`. CI enforcement
checks must match `nix develop|nix build|nix flake check` patterns, not just
direct tool names. `flake.nix` is a first-class detection surface.

**Applicability:** All Haskell repos using Nix.

## QuickCheck property tests for state machine correctness

```yaml
source: iog-scan
repos: [cardano-ledger, plutus]
category: safety-net
status: validated
discovered: 2026-03-20
updated: 2026-03-27
```

Repos with QuickCheck generators per module have stronger boundary test
coverage. Pattern: `Gen*.hs` + `Arbitrary` instances per data type.

**Recommendation template:**
"Add QuickCheck generators for [module]. Start with Arbitrary instances
for your core data types. Effort: Low (days). Impact: HIGH."

**Applicability:** Haskell repos with algebraic data types at module boundaries.

## Haddock documentation coverage

```yaml
source: iog-scan
repos: [cardano-ledger, ouroboros-consensus]
category: clarity
status: validated
discovered: 2026-03-26
updated: 2026-03-27
```

Haddock `-- |` and `{- | -}` on exported functions. Sample source files
for doc comment density. cardano-ledger: 45.8% coverage across 38 packages.

**Applicability:** All Haskell repos.

## cabal multi-package as module boundary signal

```yaml
source: iog-scan
repos: [cardano-ledger]
category: structure
status: validated
discovered: 2026-03-20
updated: 2026-03-27
```

`cabal.project` with `packages:` listing multiple paths. cardano-ledger
has 38 packages with explicit boundaries.

**Applicability:** Haskell repos with multiple libraries.

## HLint + fourmolu as standard tooling

```yaml
source: ecosystem-standard
repos: []
category: structure
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

HLint for linting, fourmolu (or ormolu/stylish-haskell) for formatting.
Detection: `.hlint.yaml`, or `hlint`/`fourmolu` in `flake.nix` or CI.

**Applicability:** All Haskell repos.
