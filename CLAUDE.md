# CLAUDE.md — cbu-coe-toolkit

> Context file for AI agents. Under 200 lines. Use progressive disclosure.

## Project

- **Repo:** `cbu-coe-toolkit` — measurement models, scoring scripts, scan automation
- **Owner:** Centre of Excellence (CoE), Cardano Business Unit, IOG
- **Consumers:** CoE operators and AI agents running scans
- **Sibling:** [`cbu-coe`](https://github.com/input-output-hk/cbu-coe) — guidance, templates, skills for teams

## Structure

```
cbu-coe-toolkit/
├── models/                        # Model definitions (source of truth)
│   ├── ai-augmentation-maturity/  # AAMM — readiness + adoption, two-axis
│   ├── engineering-vitals/        # KPIs, thresholds (Power BI external)
│   └── capability-maturity/       # Engineering practices (draft)
├── scripts/aamm/                  # Scan automation pipeline
├── scans/ai-augmentation/         # Config, prompts, results (YYYY-MM.json)
├── skills/                        # Claude Code skills for CoE operators
├── notion/                        # Page registry, publishing guide
└── docs/
    ├── decisions/                 # Architecture Decision Records
    └── learnings.md               # Operational insights log
```

## Three-model architecture

| Model | Question | Location |
|---|---|---|
| **AI Augmentation (AAMM)** | Is AI institutionalised? | `models/ai-augmentation-maturity/` |
| **Capability Maturity** | Are engineering practices solid? | `models/capability-maturity/` (draft) |
| **Engineering Vitals** | Is work delivering value? | Power BI (external) |

Design principles:
- Stages are **informative**, not judgment. The goal is showing teams what good looks like.
- Engineering Vitals measures value delivery. This toolkit measures AI *presence*, not AI *value*.
- No discretionary adjustments. The formula output is the score.

## AAMM overview

Two axes per repo:
- **Readiness (0–100)** — structural suitability for AI. 3 pillars: Navigate (35%), Understand (35%), Verify (30%). 17 signals.
- **Adoption (0–100)** — active AI usage. 5 dimensions, 4 stages: None → Configured → Active → Integrated.

Quadrant: Traditional | Fertile Ground | Risky Acceleration | AI-Native.

Full methodology: `models/ai-augmentation-maturity/model-spec.md`, `readiness-scoring.md`, `adoption-scoring.md`.

## Scan pipeline

```
scripts/aamm/scan-repo.sh owner/repo [overrides.json]
  → collect-all.sh          GitHub API data collection
  → score-readiness.sh      17 signals → JSON
  → score-adoption.sh       5 dimensions → JSON
  → review-scores.sh        Language/domain-aware validation
  → generate-report.sh      .md + .json report with recommendations
```

Non-interactive. No confirmations. Results go to `scans/ai-augmentation/results/YYYY-MM.json`.

Tracked repos: 29 across 4 orgs. See `scans/ai-augmentation/config.yaml`.

## Source of truth

1. **This repo (GitHub)** — model definitions, scoring rules, results
2. **Notion** — display layer, rendered from GitHub content
3. When they diverge, GitHub wins.

## Rules

1. **Never commit to `main`.** Branch → PR → owner review → merge.
2. **Never expose secrets.** No printing, logging, or committing API keys, tokens, passwords, or env variable values. Reference by name only (`$GITHUB_TOKEN`).
3. **Check for secrets before every commit.** Run `git diff --cached` and review every line.
4. **Quality gate.** Invoke the `quality-gate` skill before declaring any task complete. Skip for questions, explanations, and simple lookups.
5. **Read `plan.md` first.** Each model directory has a `plan.md` with prioritized backlog. Read it before starting work, update it when completing work.
6. **Read model files before scanning.** Load `model-spec.md`, `readiness-scoring.md`, `adoption-scoring.md`.
7. **Use `scripts/aamm/scan-repo.sh`** for scans. Override signals via `overrides.json`.
8. **Results as JSON** to `scans/*/results/YYYY-MM.json`.
9. **Never publish to Notion without human approval.**
10. **Model definitions are mutable drafts.** Flag edge cases and inconsistencies.
11. **PRs explain why**, not just what.
12. **When unsure, ask.**

## Session handoff

Before ending a session, propose knowledge capture:

1. **Learnings** — draft entries for `docs/learnings.md`.
2. **Decisions** — if significant choices were made, draft an ADR following `docs/decisions/000-template.md`.
3. **Present to the operator for review.** Do not commit without approval.

## References

- [Confluence CoE page](https://input-output.atlassian.net/wiki/spaces/IOE/pages/5700845586/)
- Sibling repo: `cbu-coe`
