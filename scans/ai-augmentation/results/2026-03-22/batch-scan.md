# AAMM Batch Scan — 2026-03-22

**Repos scanned:** 4 · **Model version:** 1.0 · **Scanned by:** CoE (Dorin Solomon)

---

## Org-Level Summary

### Quadrant Distribution

```
                        AI Adoption →
                   Low                High
              ┌─────────────────┬─────────────────┐
         High │  FERTILE GROUND │    AI-NATIVE     │
              │                 │                  │
              │  ● ledger  80.1 │  ● lace-plat 57.7│
              │  ● hydra   67.0 │                  │
              │  ● node    62.3 │                  │
              ├─────────────────┼─────────────────┤
         Low  │  TRADITIONAL    │ RISKY ACCEL.     │
              │                 │                  │
              └─────────────────┴─────────────────┘
```

### Portfolio View

| Repo | Readiness | Adoption | Quadrant | Navigate | Understand | Verify |
|------|-----------|----------|----------|----------|------------|--------|
| **cardano-ledger** | **80.07** | **0** | Fertile Ground | 94.02 | 68.50 | 94.00 |
| **hydra** | **67.01** | **0** | Fertile Ground | 98.28 | 50.50 | 66.50 |
| **cardano-node** | **62.29** | **0** | Fertile Ground | 94.95 | 46.75 | 59.00 |
| **lace-platform** | **57.66** | **80.00** | AI-Native | 88.70 | 44.50 | 53.50 |

### Key Metrics

| Metric | Value |
|--------|-------|
| Average Readiness | **66.76** |
| Average Adoption | **20.00** |
| Repos with zero AI adoption | **3 / 4** (75%) |
| Most common quadrant | **Fertile Ground** |
| Universal penalty | **-5** (no branch protection, all 4 repos) |

---

## Headline Insight

**3 din 4 repo-uri sunt "Fertile Ground" — codebase-uri bine structurate, cu zero adopție AI.** Oportunitatea principală nu e remedierea codului, ci **activarea AI** pe baze deja solide. Un singur CLAUDE.md bine scris pe fiecare repo ar muta instant 3 dimensiuni de la None la Configured.

**lace-platform este singurul repo AI-Native** cu Adoption 80/100 (4/5 dimensions Integrated), dar readiness-ul este cel mai scăzut (57.66) — predominantly din cauza Understand (44.50) și Verify (53.50).

---

## Common Patterns

| Pattern | Repos | Impact |
|---------|-------|--------|
| **No branch protection** | All 4 | -5 penalty fiecare |
| **U2 doc coverage = 25 (default)** | All 4 | Needs agent sampling — scoruri probabil understate |
| **Navigate-Understand gap** | node, hydra, lace-platform | Well-structured but poorly documented for AI |
| **Zero AI config** | ledger, node, hydra | Immediate opportunity |

---

## Top 3 Org-Level Actions

1. **Enable branch protection** on all 4 repos — immediate +5 readiness fiecare, zero effort
2. **Add CLAUDE.md** to ledger, node, hydra — moves 3-4 adoption dimensions from None to Configured per repo
3. **Improve documentation** (Haddock/TSDoc) — U2 is the single biggest drag on Understand across all repos

---

## Risk Flags

| Severity | Risk | Repos |
|----------|------|-------|
| 🟡 Medium | No branch protection | All 4 |
| 🟡 Medium | Benchmarks without CI regression | cardano-node |
| 🟡 Medium | No benchmark regression detection | lace-platform |

---

## Per-Repo Highlights

### cardano-ledger (80.07 / 0) — Fertile Ground

- **Best readiness overall** — strongest Verify pillar (94.00) thanks to exceptional test coverage (ratio .832)
- Formal specs: 6 formal-spec dirs, 8 CDDL files, 19 conformance dirs
- Generator discipline: cover/classify, custom Arbitrary, adversarial — all present
- **Weakness:** Understand 68.50 (U2 doc coverage default, U3 README missing usage/arch sections)
- **No AI adoption at all** — zero config files, zero AI PRs

### hydra (67.01 / 0) — Fertile Ground

- **Best Navigate score** (98.28) — median 59 lines/file, only 2 large files, excellent organization
- Strong engineering: 4 linter/formatter configs, weeder, fourmolu, hlint
- Generator discipline exemplary: cover/classify, custom Arbitrary, adversarial all present
- io-sim for concurrency, StrictData/BangPatterns enforced, benchmark CI regression
- 32 ADRs — strong decision documentation
- **Weakness:** Understand 50.50 (U2 default, U3 README sparse, U5 schema=0)
- **No AI adoption at all**

### cardano-node (62.29 / 0) — Fertile Ground

- Solid Navigate (94.95), good CI infrastructure (16 workflows)
- io-sim present, 464 benchmark files
- **Weaknesses:** Understand 46.75 (U3=20 sparse README, U4=0 no ADRs, U5=50), Verify 59.00 (V1=50 low test ratio .289, V4=0 no coverage config)
- PE Review flagged: 29 generator files not sampled (likely false negative on discipline)
- **No AI adoption at all**

### lace-platform (57.66 / 80.00) — AI-Native

- **Only repo with AI adoption** — 26 AI config files, custom agents (7), commands (5), skills (3)
- 4/5 dimensions Integrated (Code, Testing, Delivery, Governance)
- Security: None (dependabot exists but doesn't cover TypeScript)
- .aiignore present — mature governance signal
- **Lowest readiness** — Understand 44.50 (U1=40 TS type safety not verified, U5=0 no schema detection), Verify 53.50 (V1=25 low test ratio .171)
- **Key gap:** High adoption on a codebase that could be more AI-ready

---

## Caveats

- **U2 (doc coverage) = 25 default on all 4 repos** — this is an unsampled heuristic. Agent-based file sampling would likely raise scores, especially for Haskell repos with Haddock. This is the #1 accuracy improvement pending (P1 #8 in plan.md).
- **Branch protection** shows as missing for all repos — this may be a GitHub API limitation (requires admin access to read branch protection rules). Verify manually before reporting to teams.
- **N4 (separation of concerns)** is heuristic-based on all repos — override recommended after manual inspection.

---

## Individual Reports

Full per-repo reports with evidence logs, pillar breakdowns, and recommendations:
- `cardano-ledger-report.md` / `.json`
- `lace-platform-report.md` / `.json`
- `cardano-node-report.md` / `.json`
- `hydra-report.md` / `.json`

All in `scans/ai-augmentation/results/`.
