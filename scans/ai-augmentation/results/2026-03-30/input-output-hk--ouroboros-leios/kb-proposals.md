# KB Proposals — Learning Scan: input-output-hk/ouroboros-leios
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: Mixed (Jupyter Notebook primary, Haskell, Rust, Lean) | Agent: Claude Opus 4.6

---

## Seed Pattern Validation

This is a multi-ecosystem research/prototyping repo. Primary language by GitHub: Jupyter Notebook. Components include Haskell simulation, Rust simulation (`sim-rs`), Lean formal proofs, and analysis notebooks.

### Ecosystem-specific patterns — MIXED APPLICABILITY

**Haskell patterns:** Partially applicable. The repo contains Haskell components (`.hlint.yaml` confirms), with CI workflows (`lean_action_ci.yml`, `conformance.yaml`, `conformance-linear.yaml`). However, this is a prototyping repo, not production Haskell — QuickCheck, Haddock, and CDDL patterns are less relevant than in cardano-ledger.

**Rust patterns:** Partially applicable. `sim-rs.yaml` CI workflow and `crypto-benchmarks-rs.yaml` confirm Rust components. The Rust simulation likely has async networking code. However, without Cargo.toml count or deny.toml confirmation, Rust patterns cannot be strongly validated.

**Python/Jupyter patterns:** The primary language is Jupyter Notebook. Analysis notebooks exist: `analysis/bandwidth/ReadMe.ipynb`. No Python seed patterns directly apply to notebook-based analysis work.

### Cross-cutting applicability

Given the research nature and 12 AI-attributed commits, cross-cutting patterns are more relevant than ecosystem-specific ones.

---

## Cross-Cutting Patterns

### cc_claude_md_context — CONFIRMED ABSENT

No CLAUDE.md found. **12 AI-attributed commits** — the highest AI usage in the scanned portfolio. This is a significant gap: active AI usage without context documentation means each AI session starts from zero on a complex multi-ecosystem, multi-component research repo.

Key context that CLAUDE.md should capture:
- Component architecture: Haskell simulation, Rust simulation (sim-rs), Lean formal spec, Jupyter analysis
- Build systems: Nix (`.envrc`, Dockerfile), Cabal (Haskell), Cargo (Rust), Lean toolchain
- Conformance testing approach (conformance.yaml, conformance-linear.yaml, formal-spec-listener.yaml)
- Coding standards (CODING-STANDARDS.md exists but AI needs explicit reference)

### cc_aiignore_boundaries — CONFIRMED APPLICABLE

Security-relevant paths:
- Formal specification and proofs (Lean) — AI should not modify without review
- Conformance tests — changes affect protocol correctness validation
- Cryptographic benchmarks (`crypto-benchmarks-rs.yaml`) — performance-critical crypto code
- `SECURITY.md` (5.8KB) exists — team is security-aware

12 AI commits without `.aiignore` means AI has modified code without explicit trust boundaries.

---

## New Pattern Proposals

### AI-assisted Jupyter notebook analysis

```yaml
id: mixed_jupyter_analysis
type: opportunity
ecosystem: cross-cutting
status: proposed
discovered: 2026-03-30

applies_when:
  - Research repo with Jupyter notebooks for analysis
  - Notebooks contain data analysis, visualization, or simulation results
  - Active development with frequent analysis iterations

value: MEDIUM
value_context: "AI can help draft analysis notebooks, generate visualizations, and explain simulation results — particularly valuable in protocol research"
evidence_to_look_for:
  - .ipynb files in analysis/ or similar directories
  - Data files (TSV, CSV) alongside notebooks
  - CI workflows that run or validate notebooks
seen_in:
  - repo: input-output-hk/ouroboros-leios
    outcome: "Jupyter Notebook is primary language. analysis/bandwidth/ReadMe.ipynb with measurements.tsv data. Logbook.md (303KB) tracks research progress."
```

### Multi-ecosystem conformance testing

```yaml
id: mixed_conformance_testing
type: opportunity
ecosystem: cross-cutting
status: proposed
discovered: 2026-03-30

applies_when:
  - Protocol with formal specification (Lean, Agda, Coq)
  - Implementation in different language than spec (Haskell, Rust)
  - Conformance tests bridge spec and implementation

value: HIGH
value_context: "AI can trace conformance gaps between formal spec and implementation across language boundaries"
evidence_to_look_for:
  - Formal spec in one language, implementation in another
  - CI workflows for conformance testing
  - formal-spec-listener or similar cross-language validation
seen_in:
  - repo: input-output-hk/ouroboros-leios
    outcome: "Lean formal spec, Haskell+Rust implementations, conformance.yaml and conformance-linear.yaml CI, formal-spec-listener.yaml"
```

---

## Summary

| Pattern | Status | Confidence |
|---------|--------|------------|
| Ecosystem-specific (HS/RS/PY) | MIXED — partially applicable | LOW-MEDIUM |
| cc_claude_md_context | ABSENT — HIGH priority | HIGH |
| cc_aiignore_boundaries | APPLICABLE — HIGH priority | HIGH |

**Key finding:** ouroboros-leios has the highest AI commit count (12) in the portfolio but NO AI configuration files (no CLAUDE.md, no .aiignore, no copilot-instructions.md). This is the inverse of mithril (which has copilot-instructions.md but 0 AI commits). The combination of heavy AI usage + complex multi-ecosystem architecture + security-relevant protocol code + zero AI configuration makes cc_claude_md_context the highest-ROI opportunity. The 303KB Logbook.md suggests the team values documentation — a CLAUDE.md would be a natural extension.
