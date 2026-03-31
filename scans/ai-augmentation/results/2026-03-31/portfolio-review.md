# AAMM Portfolio Review
> Generated: 2026-03-31 | Data window: 2026-03-31 | Schema: v6.0
> Coverage: 5/29 repos | Freshness: all scans from today

---

## 1. Coverage

| Status | Count | Repos |
|--------|-------|-------|
| Scanned (fresh) | 5 | [IntersectMBO/cardano-ledger](../2026-03-31/IntersectMBO--cardano-ledger/report.md), [IntersectMBO/cardano-node](../2026-03-31/IntersectMBO--cardano-node/report.md), [input-output-hk/lace-platform](../2026-03-31/input-output-hk--lace-platform/report.md), [input-output-hk/mithril](../2026-03-31/input-output-hk--mithril/report.md), [cardano-scaling/hydra](../2026-03-31/cardano-scaling--hydra/report.md) |
| Not scanned | 24 | cardano-cli, cardano-api, ouroboros-consensus, ouroboros-network, cardano-base, cardano-db-sync, plutus, cardano-haskell-packages, cardano-node-tests, lace (v1), ouroboros-leios, haskell.nix, io-sim, sc-fvt, Lean-blaster, Blaster-benchmarking, CardanoBlaster, sc-tools-experiments, plu-stan, Cardano-CWE-Research, CHA-react-FE-template, glyph, pluts-emulator, pebble-lsp |

**Ecosystems scanned:** Haskell (3), TypeScript (1), Rust (1)

---

## 2. Quadrant Distribution

| Quadrant | Count | Repos |
|----------|-------|-------|
| HIGH potential, LOW activity | 4 | [cardano-ledger](../2026-03-31/IntersectMBO--cardano-ledger/report.md), [cardano-node](../2026-03-31/IntersectMBO--cardano-node/report.md), [mithril](../2026-03-31/input-output-hk--mithril/report.md), [hydra](../2026-03-31/cardano-scaling--hydra/report.md) |
| HIGH potential, MEDIUM activity | 1 | [lace-platform](../2026-03-31/input-output-hk--lace-platform/report.md) |
| HIGH potential, HIGH activity | 0 | — |
| LOW potential, any activity | 0 | — |

**Key insight:** All 5 scanned repos have HIGH AI potential. 4 of 5 have LOW activity — significant untapped opportunity across the portfolio. Only lace-platform shows MEDIUM activity (CLAUDE.md, .claude/ agents, claude.yml workflow, .mcp.json configured).

---

## 3. Cross-Portfolio Patterns

Opportunities appearing in ≥2 repos. These are systemic patterns, not individual repo findings.

| KB Pattern | Count | Repos | Value | Insight |
|-----------|-------|-------|-------|---------|
| **cc_aiignore_boundaries** | 5/5 | [cardano-ledger](../2026-03-31/IntersectMBO--cardano-ledger/report.md), [cardano-node](../2026-03-31/IntersectMBO--cardano-node/report.md), [lace-platform](../2026-03-31/input-output-hk--lace-platform/report.md), [mithril](../2026-03-31/input-output-hk--mithril/report.md), [hydra](../2026-03-31/cardano-scaling--hydra/report.md) | HIGH | **Universal gap.** Zero repos have .aiignore. A single CoE-provided template per ecosystem could address all 5. |
| **cc_claude_md_context** | 4/5 | [cardano-ledger](../2026-03-31/IntersectMBO--cardano-ledger/report.md), [cardano-node](../2026-03-31/IntersectMBO--cardano-node/report.md), [mithril](../2026-03-31/input-output-hk--mithril/report.md), [hydra](../2026-03-31/cardano-scaling--hydra/report.md) | HIGH | 4 repos lack substantive CLAUDE.md. lace-platform is the exception (1516 bytes). CoE golden-path templates exist in cbu-coe — adoption gap. |
| **hs_haddock_generation** | 2/5 | [cardano-ledger](../2026-03-31/IntersectMBO--cardano-ledger/report.md), [hydra](../2026-03-31/cardano-scaling--hydra/report.md) | HIGH | Haskell repos have sub-1% Haddock doc coverage. Common gap across Haskell ecosystem. |
| **cc_pr_descriptions** | 2/5 | [lace-platform](../2026-03-31/input-output-hk--lace-platform/report.md), [hydra](../2026-03-31/cardano-scaling--hydra/report.md) | MEDIUM | PR description quality inconsistent in 2 repos despite existing templates. |

**Novel patterns** (not in KB, appeared in ≥2 repos):
- Config/test validation via AI — seen in: [cardano-node](../2026-03-31/IntersectMBO--cardano-node/report.md) (mainnet config), [hydra](../2026-03-31/cardano-scaling--hydra/report.md) (test generation)

---

## 4. Risk Summary

| Flag | Count | Repos |
|------|-------|-------|
| Risky Acceleration (Active + Undiscovered) | 0 | — |
| Ad-hoc AI Usage (no intentionality signals) | 0 | — |
| No .aiignore on repo with security-critical paths | **5/5** | [cardano-ledger](../2026-03-31/IntersectMBO--cardano-ledger/report.md), [cardano-node](../2026-03-31/IntersectMBO--cardano-node/report.md), [lace-platform](../2026-03-31/input-output-hk--lace-platform/report.md), [mithril](../2026-03-31/input-output-hk--mithril/report.md), [hydra](../2026-03-31/cardano-scaling--hydra/report.md) |

**Key insight:** No risky acceleration — adoption is too low for that. The primary risk is the universal absence of .aiignore on repos handling consensus, crypto, financial state, and wallet operations. As AI adoption grows (lace-platform is leading), this gap becomes increasingly urgent.

---

## 5. Progress

> First portfolio review — no previous data available for comparison.

| Metric | Current |
|--------|---------|
| Repos scanned (v6) | 5 / 29 (17%) |
| Total approved opportunities | 31 |
| Avg opportunities per repo | 6.2 |
| Total approved recommendations | 27 |
| Avg recommendations per repo | 5.4 |
| Repos with .aiignore | 0 / 5 (0%) |
| Repos with substantive CLAUDE.md | 1 / 5 (20%) — lace-platform |
| Repos with any AI attribution | 1 / 5 (20%) — cardano-ledger (2 Claude co-authored commits) |

---

## Strategic Observations (CoE + Leadership)

1. **The portfolio is uniformly HIGH potential, LOW activity.** Every scanned repo has strong engineering foundations (CI, tests, structured code) that make AI adoption straightforward. The barrier is activation, not infrastructure.

2. **.aiignore is the #1 systemic gap.** 5/5 repos handle security-critical code (consensus, crypto, wallet, financial state) with zero AI trust boundaries. CoE should provide ecosystem-specific .aiignore templates via golden-paths.

3. **lace-platform is the adoption leader.** It has CLAUDE.md, .claude/ directory with agents/skills/commands, claude.yml GitHub Action, and .mcp.json. Other teams can learn from this setup. CoE should document lace-platform as a reference implementation.

4. **CLAUDE.md golden-path templates exist but aren't adopted.** cbu-coe repo has by-role and by-project CLAUDE.md templates. 4/5 scanned repos don't have CLAUDE.md. The gap is awareness/distribution, not availability.

5. **24 repos remain unscanned.** Priority for next scan batch: cardano-cli, cardano-api, ouroboros-consensus (Cardano Core — same project group as ledger and node).
