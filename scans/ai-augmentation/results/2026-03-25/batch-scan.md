# AAMM Batch Scan — 2026-03-25

**Repos scanned:** 28 of 29 · **Model version:** v3.0 · **Scanned by:** CoE (Dorin Solomon)
**Failed:** 1 (afv-rpc-api — repo inaccessible/404)

---

## Org-Level Summary

### Quadrant Distribution

```
                        AI Adoption →
                   Low                High
              ┌─────────────────┬─────────────────┐
         High │  FERTILE GROUND │    AI-NATIVE     │
              │  16 repos       │  2 repos         │
              │                 │                  │
              │  ● ledger  80.1 │  ● lace-plat 57.7│
              │  ● consensus71.9│  ● plutus    67.4│
              │  ● hydra   67.0 │                  │
              │  ● plutus? 67.4 │                  │
              │  ...12 more     │                  │
              ├─────────────────┼─────────────────┤
         Low  │  TRADITIONAL    │ RISKY ACCEL.     │
              │  8 repos        │  0 repos         │
              │                 │                  │
              │  ● CHaP    37.5 │                  │
              │  ● sc-fvt  20.0 │                  │
              │  ...6 more      │                  │
              └─────────────────┴─────────────────┘
```

### Full Portfolio View

| # | Org | Repo | Readiness | Adoption | Quadrant | Project |
|---|-----|------|-----------|----------|----------|---------|
| 1 | IntersectMBO | **cardano-ledger** | **80.07** | 0 | Fertile Ground | Cardano Core |
| 2 | IntersectMBO | **ouroboros-consensus** | **71.89** | 0 | Fertile Ground | Cardano Core |
| 3 | IntersectMBO | **plutus** | **67.39** | **52.80** | **AI-Native** | Plutus Core |
| 4 | cardano-scaling | **hydra** | **67.01** | 0 | Fertile Ground | Hydra |
| 5 | IntersectMBO | **cardano-api** | **65.70** | 42.90 | Fertile Ground | Cardano Core |
| 6 | IntersectMBO | **ouroboros-network** | **64.15** | 0 | Fertile Ground | Cardano Core |
| 7 | input-output-hk | **sc-tools-experiments** | **63.07** | 0 | Fertile Ground | Plutus HA — PBT |
| 8 | IntersectMBO | **cardano-node** | **62.29** | 0 | Fertile Ground | Cardano Core |
| 9 | IntersectMBO | **cardano-cli** | **61.83** | 0 | Fertile Ground | Cardano Core |
| 10 | IntersectMBO | **cardano-base** | **60.66** | 0 | Fertile Ground | Cardano Core |
| 11 | IntersectMBO | **cardano-db-sync** | **60.73** | 0 | Fertile Ground | DB-Sync |
| 12 | input-output-hk | **mithril** | **59.95** | 21.45 | Fertile Ground | Mithril |
| 13 | input-output-hk | **lace-platform** | **57.66** | **80.00** | **AI-Native** | Lace Wallet (v2) |
| 14 | input-output-hk | **plu-stan** | **57.12** | 16.50 | Fertile Ground | Plutus HA — Static Analyzer |
| 15 | input-output-hk | **haskell.nix** | **54.99** | 0 | Fertile Ground | Infrastructure / Nix |
| 16 | IntersectMBO | **cardano-node-tests** | **53.32** | 16.50 | Fertile Ground | Cardano Core — E2E |
| 17 | input-output-hk | **ouroboros-leios** | **52.65** | 42.90 | Fertile Ground | Leios |
| 18 | input-output-hk | **lace** | **51.11** | 0 | Fertile Ground | Lace Wallet (v1) |
| 19 | input-output-hk | **io-sim** | **47.90** | 0 | Fertile Ground | io-sim |
| 20 | IntersectMBO | **cardano-haskell-packages** | 37.46 | 0 | Traditional | CHaP |
| 21 | input-output-hk | **glyph** | 26.97 | 0 | Traditional | Plutus HA — Glyph |
| 22 | HarmonicLabs | **pluts-emulator** | 25.83 | 0 | Traditional | Plutus HA — Plu-ts |
| 23 | input-output-hk | **CHA-react-FE-template** | 24.16 | 0 | Traditional | Plutus HA — Frontend |
| 24 | input-output-hk | **Lean-blaster** | 23.11 | 0 | Traditional | Plutus HA — FV |
| 25 | HarmonicLabs | **pebble-lsp** | 20.31 | 0 | Traditional | Plutus HA — Plu-ts |
| 26 | input-output-hk | **sc-fvt** | 19.96 | 0 | Traditional | Plutus HA — FV/PBT |
| 27 | input-output-hk | **CardanoBlaster** | 18.37 | 0 | Traditional | Plutus HA — FV |
| 28 | input-output-hk | **Blaster-benchmarking** | 0 | 0 | Traditional | Plutus HA — FV |
| — | input-output-hk | **Cardano-CWE-Research** | 0 | 0 | Traditional | Plutus HA — Static Analyzer |
| — | input-output-hk | ~~afv-rpc-api~~ | — | — | FAILED | Plutus HA — FV (inaccessible) |

### Key Metrics

| Metric | Value |
|--------|-------|
| **Total repos scanned** | 28 |
| **Average Readiness** | **45.80** |
| **Median Readiness** | **53.99** |
| **Average Adoption** | **9.97** |
| **Repos with zero AI adoption** | **21 / 28** (75%) |
| **Repos with some AI adoption** | **7 / 28** (25%) |
| **AI-Native quadrant** | **2** (plutus, lace-platform) |
| **Fertile Ground quadrant** | **18** |
| **Traditional quadrant** | **8** |
| **Risky Acceleration** | **0** |

---

## Quadrant Breakdown

### AI-Native (2 repos) — High Readiness + High Adoption

| Repo | Readiness | Adoption | Notes |
|------|-----------|----------|-------|
| **plutus** | 67.39 | 52.80 | NEW — CLAUDE.md detected, AI PRs active |
| **lace-platform** | 57.66 | 80.00 | 26 AI config files, 4/5 dimensions Integrated |

### Fertile Ground (18 repos) — High Readiness + Low Adoption

The biggest opportunity bucket. Well-structured codebases waiting for AI activation.

**Top 5 by readiness (highest ROI for AI enablement):**
1. cardano-ledger (80.07) — exceptional test infrastructure, formal specs
2. ouroboros-consensus (71.89) — io-sim, strong property testing
3. hydra (67.01) — best Navigate score, 32 ADRs
4. cardano-api (65.70) — has some adoption (42.90) but below threshold
5. ouroboros-network (64.15) — solid Haskell infra

### Traditional (8 repos) — Low Readiness + Low Adoption

Mostly smaller/newer repos, research projects, or build tooling:
- cardano-haskell-packages (CHaP, 37.46) — package registry, limited AI surface
- Plutus HA research repos (sc-fvt, Lean-blaster, CardanoBlaster, glyph, etc.) — specialized/early-stage
- Blaster-benchmarking (0) / Cardano-CWE-Research (0) — minimal/empty repos

---

## Headline Insights

### 1. Portfolio este 64% Fertile Ground — oportunitatea principală e activarea AI

18 din 28 repo-uri au readiness ≥45 dar adoption zero sau low. Un singur CLAUDE.md bine scris pe fiecare repo ar muta instant 3+ dimensiuni de la None la Configured.

### 2. Plutus a intrat în AI-Native (NOU față de scan-ul din 22 martie)

plutus: 67.39 readiness, 52.80 adoption. Are CLAUDE.md și activitate AI (PRs/commits). Aceasta e o schimbare semnificativă — al doilea repo core care adoptă AI.

### 3. cardano-api și ouroboros-leios se apropie de AI-Native

Ambele au adoption ~42.90, imediat sub pragul de 45. Sunt la un pas de a trece în cadranul AI-Native.

### 4. 75% din repo-uri au zero adoption AI

21 din 28 nu au niciun config AI. Aceasta nu e o problemă de calitate a codului — readiness-ul mediu e decent (45.80). E pur și simplu neactivare.

### 5. Cardano Core domină Fertile Ground

Toate repo-urile IntersectMBO Cardano Core (ledger, consensus, node, cli, api, network, base) sunt Fertile Ground cu readiness 60-80. Sunt cele mai bine pregătite pentru AI.

### 6. Research repos sunt în mare parte Traditional

Plutus HA research repos (Lean, Blaster, glyph, etc.) au readiness <30. Acestea sunt proiecte de cercetare, nu engineering repos — e natural.

---

## Delta față de scan-ul din 22 martie

| Repo | Readiness Δ | Adoption Δ | Notes |
|------|-------------|------------|-------|
| cardano-ledger | 80.07 → 80.07 (=) | 0 → 0 (=) | Stabil |
| cardano-node | 62.29 → 62.29 (=) | 0 → 0 (=) | Stabil |
| hydra | 67.01 → 67.01 (=) | 0 → 0 (=) | Stabil |
| lace-platform | 57.66 → 57.66 (=) | 80.00 → 80.00 (=) | Stabil |
| ouroboros-consensus | 70.98 → 71.89 (+0.91) | 0 → 0 | Mica creștere readiness |
| **plutus** | **NEW** | **NEW** | **67.39 / 52.80 — AI-Native!** |
| **24 more repos** | **NEW** | **NEW** | First scan |

---

## Common Patterns

| Pattern | Count | Impact |
|---------|-------|--------|
| **Zero AI config** | 21/28 | Biggest single lever — adding CLAUDE.md moves 3+ dimensions |
| **Fertile Ground** | 18/28 | Codebases ready for AI but not using it |
| **No branch protection (penalty -5)** | ~all | Universal penalty, easy fix |
| **U2 doc coverage = 25 (default)** | ~all | Agent sampling needed — scores likely understated |
| **Navigate-Understand gap** | Most | Well-structured but poorly documented for AI context |

---

## Top 5 Org-Level Actions

1. **Enable branch protection** on all repos — immediate +5 readiness each, zero effort
2. **Add CLAUDE.md to top 5 Fertile Ground repos** (ledger, consensus, hydra, cardano-api, ouroboros-network) — each gets 3-4 adoption dimensions activated instantly
3. **Push cardano-api and ouroboros-leios over AI-Native threshold** — both at 42.90, need minimal adoption boost
4. **Improve documentation** (Haddock/TSDoc) — U2 is the biggest drag on Understand pillar across all repos
5. **Consider excluding research repos from portfolio metrics** — they skew averages down; track separately

---

## Risk Flags

| Severity | Risk | Repos |
|----------|------|-------|
| 🟡 Medium | No branch protection | All repos |
| 🟡 Medium | afv-rpc-api inaccessible | Cannot be scanned |
| 🟡 Medium | 2 repos score 0 readiness | Blaster-benchmarking, Cardano-CWE-Research |
| 🟢 Low | Research repos in Traditional | Expected — not engineering repos |

---

## Per-Project Summaries

### Cardano Core (IntersectMBO) — 8 repos

| Repo | R | A | Quadrant |
|------|---|---|----------|
| cardano-ledger | 80.07 | 0 | Fertile Ground |
| ouroboros-consensus | 71.89 | 0 | Fertile Ground |
| cardano-api | 65.70 | 42.90 | Fertile Ground |
| ouroboros-network | 64.15 | 0 | Fertile Ground |
| cardano-node | 62.29 | 0 | Fertile Ground |
| cardano-cli | 61.83 | 0 | Fertile Ground |
| cardano-base | 60.66 | 0 | Fertile Ground |
| cardano-node-tests | 53.32 | 16.50 | Fertile Ground |

**Average Readiness: 64.99** · **Average Adoption: 7.43**
Strongest engineering cluster. All Fertile Ground. Zero AI-Native yet — massive opportunity.

### Lace Wallet (input-output-hk) — 2 repos

| Repo | R | A | Quadrant |
|------|---|---|----------|
| lace-platform (v2) | 57.66 | 80.00 | AI-Native |
| lace (v1, legacy) | 51.11 | 0 | Fertile Ground |

lace-platform leads the entire portfolio in AI adoption. lace v1 is legacy — no AI investment expected.

### Plutus Core — 1 repo

| Repo | R | A | Quadrant |
|------|---|---|----------|
| plutus | 67.39 | 52.80 | AI-Native |

Second AI-Native repo in portfolio. Strong signal that core Haskell repos can adopt AI.

### Mithril — 1 repo

| Repo | R | A | Quadrant |
|------|---|---|----------|
| mithril | 59.95 | 21.45 | Fertile Ground |

Rust repo with emerging AI adoption. Has some AI config but not yet at threshold.

### Hydra — 1 repo

| Repo | R | A | Quadrant |
|------|---|---|----------|
| hydra | 67.01 | 0 | Fertile Ground |

Excellent engineering (best Navigate score portfolio-wide). Zero AI adoption.

### Leios — 1 repo

| Repo | R | A | Quadrant |
|------|---|---|----------|
| ouroboros-leios | 52.65 | 42.90 | Fertile Ground |

Close to AI-Native threshold. Multi-language (Haskell/Rust).

### Plutus HA (research cluster) — 9 repos

| Repo | R | A | Quadrant |
|------|---|---|----------|
| sc-tools-experiments | 63.07 | 0 | Fertile Ground |
| plu-stan | 57.12 | 16.50 | Fertile Ground |
| glyph | 26.97 | 0 | Traditional |
| pluts-emulator | 25.83 | 0 | Traditional |
| CHA-react-FE-template | 24.16 | 0 | Traditional |
| Lean-blaster | 23.11 | 0 | Traditional |
| pebble-lsp | 20.31 | 0 | Traditional |
| sc-fvt | 19.96 | 0 | Traditional |
| CardanoBlaster | 18.37 | 0 | Traditional |

Mostly research/experimental. sc-tools-experiments is the standout (63.07 readiness).

### Infrastructure — 1 repo

| Repo | R | A | Quadrant |
|------|---|---|----------|
| haskell.nix | 54.99 | 0 | Fertile Ground |

Nix infrastructure. No AI adoption.

---

## Individual Reports

Full per-repo reports with evidence logs, pillar breakdowns, and recommendations available in `scans/ai-augmentation/results/`:
- `{repo}-report.md` / `.json` for each of the 28 scanned repos

---

## Caveats

- **U2 (doc coverage) = 25 default on all repos** — unsampled heuristic, agent-based file sampling would likely raise scores
- **Branch protection** may show as missing due to GitHub API limitation (requires admin access)
- **afv-rpc-api** failed — repo appears inaccessible (404/private)
- **Blaster-benchmarking & Cardano-CWE-Research** score 0 — may be empty or very minimal repos
- **N4 (separation of concerns)** is heuristic-based — override recommended after manual inspection
