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
├── .claude/skills/                # Claude Code skills (autodetected)
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

## AAMM model files

```
models/ai-augmentation-maturity/
├── README.md              # What AAMM is (start here)
├── readiness-scoring.md   # How readiness is scored (17 signals, formulas)
├── adoption-scoring.md    # How adoption is scored (5 dimensions, 4 stages)
├── domain-profiles.md     # Supplementary signals per domain (high-assurance, etc.)
├── backlog.md             # Active backlog only
```

**Read order for agents:**
1. `README.md` — understand what AAMM measures and why
2. `readiness-scoring.md` or `adoption-scoring.md` — the scoring spec you need
3. `domain-profiles.md` — if working on domain-specific features

**Source of truth:** Scoring specs (`readiness-scoring.md`, `adoption-scoring.md`) are authoritative on scoring details. `README.md` is authoritative on model purpose and architecture. When they conflict, scoring specs win on details, README wins on intent.

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
5. **Read `backlog.md` first (if it exists).** Local working doc (gitignored). Check the active backlog before starting work. Remove completed items.
6. **Read model files before scanning.** Load `README.md` (context), then `readiness-scoring.md` + `adoption-scoring.md` (scoring rules), then `domain-profiles.md` (if domain-relevant).
7. **Use `scripts/aamm/scan-repo.sh`** for scans. Override signals via `overrides.json`.
8. **Results as JSON** to `scans/*/results/YYYY-MM.json`.
9. **Never publish to Notion without human approval.**
10. **Model definitions are mutable drafts.** Flag edge cases and inconsistencies.
11. **PRs explain why**, not just what.
12. **When unsure, ask.**

## Sync protocol

When changing scoring logic, update ALL of these in the same session:
1. **Scoring spec** (`readiness-scoring.md` or `adoption-scoring.md`) — the rule
2. **Script** (`scripts/aamm/score-*.sh`, `review-scores.sh`) — the implementation
3. **This file** (CLAUDE.md) — if the change affects how agents read/use model files
4. **ADR** (`docs/decisions/`) — if the change is a significant design decision

A change in one without the others is a bug. The scoring spec and script must always agree.

## Session handoff

Before ending a session, propose knowledge capture:

1. **Learnings** — draft entries for `docs/learnings.md`.
2. **Decisions** — if significant choices were made, draft an ADR following `docs/decisions/000-template.md`.
3. **Present to the operator for review.** Do not commit without approval.

## References

- [Confluence CoE page](https://input-output.atlassian.net/wiki/spaces/IOE/pages/5700845586/)
- Sibling repo: `cbu-coe`
