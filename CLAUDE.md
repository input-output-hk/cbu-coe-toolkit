# CLAUDE.md — cbu-coe-toolkit

> Root context file for AI agents working in this repository.

## Repository Identity

- **Repo:** `cbu-coe-toolkit`
- **Purpose:** Measurement machinery — maturity models, scan prompts, scoring methodology, results history, and automation scripts
- **Owner:** CoE (Centre of Excellence), Cardano Business Unit (CBU) at IOG
- **Primary consumers:** CoE operators and AI agents running scans
- **Sibling repo:** `cbu-coe` (knowledge, guidance, templates — the materials teams actually use)

## What This Repo Contains

```
cbu-coe-toolkit/
├── CLAUDE.md                         ← You are here
├── models/                           # Measurement model definitions (source of truth)
│   ├── ai-augmentation-maturity/     # AAMM — two-axis AI readiness + adoption model
│   │   ├── model-spec.md            # Architecture, pillars, signals, stages, penalties
│   │   ├── readiness-scoring.md     # 17 signal scoring tables, formulas, worked examples
│   │   └── adoption-scoring.md      # 5 dimension decision trees, content-category checklist
│   ├── engineering-vitals/
│   │   ├── model.md                  # KPIs, thresholds, data sources
│   │   └── changelog.md
│   └── capability-maturity/
│       ├── model.md                  # Engineering practices maturity
│       └── changelog.md
├── scripts/aamm/                     # Automation scripts for AAMM scans
│   ├── scan-repo.sh                  # Single command: ./scan-repo.sh owner/repo
│   ├── collect-readiness.sh          # GitHub API data collection (readiness signals)
│   ├── collect-adoption.sh           # 5-layer AI detection (ADR-003)
│   ├── collect-all.sh                # Orchestrator for both collectors
│   ├── score-readiness.sh            # Signal→score mapping, composites, penalties
│   ├── score-adoption.sh             # Decision trees, Condition A/B, stages
│   └── generate-report.sh            # Score JSON → .md + .json report
├── scans/                            # Scan execution and history
│   ├── ai-augmentation/
│   │   ├── SCAN_PROMPT.md            # Monthly scan prompt (agent-ready)
│   │   ├── config.yaml               # Tracked repos, orgs, model references
│   │   └── results/                  # Machine-readable monthly snapshots (YYYY-MM.json)
│   └── capability-maturity/
├── skills/                           # Claude Code Skills
│   └── quality-gate/SKILL.md        # Universal quality gate (self-score + iterate)
├── notion/
│   ├── page-registry.yaml            # All Notion page IDs in one place
│   └── publishing-guide.md
└── docs/
    ├── decisions/                    # Architecture Decision Records (ADRs)
    ├── learnings.md                  # Append-only operational insights log
    └── evolution-log.md              # Chronological record of significant changes
```

## The Three-Model Architecture

| Model | Measures | Status |
|---|---|---|
| **Engineering Vitals Dashboard** | On-time delivery, value, cycle time, defects | Exists in Power BI (external) |
| **AI Augmentation Model (AAMM)** | Institutional AI readiness + adoption per repo | `models/ai-augmentation-maturity/` |
| **Capability Maturity Model** | Engineering practices, processes, standards | **DRAFT** — `models/capability-maturity/` |

### Critical Design Principles

1. **AI Augmentation stages are informative/educational, not judgment.** The goal is clarity — showing teams what good looks like.
2. **Engineering Vitals is the authoritative measure of value delivery.** This toolkit measures AI *presence*, not AI *value*.
3. **Capability Maturity covers non-AI engineering practices** — the prerequisites for AI to be effective.
4. **Cross-model synthesis is done by agents under human review.**

## AI Augmentation Model — Key Concepts

### Two-Axis Architecture

AAMM is a two-axis model:
- **AI Readiness (0-100)** — Is this codebase structurally suitable for AI collaboration? Scored via 3 pillars: Navigate (35%), Understand (35%), Verify (30%). 17 signals total.
- **AI Adoption (0-100)** — Is AI actively used in workflows? 5 dimensions: Code, Testing, Security, Delivery, Governance. 4 stages: None → Configured → Active → Integrated.

The two axes form a quadrant: Traditional, Fertile Ground, Risky Acceleration, AI-Native.

### Key Scoring Rules

- **No discretionary adjustments.** The formula output is the score.
- **No language bonuses.** Universal signals are language-aware where needed.
- Stage 1 (Configured) requires **two conditions**: (A) practice active + (B) AI config with ≥3 of 6 content categories.
- Stages are **cumulative** — Active requires Configured.
- 3 penalties: PRs without review (-10), no vulnerability monitoring (-10 or -5), no branch protection (-5).
- **5-layer AI detection:** Tree → Commits → PR Author → PR Body → Submodules (ADR-003).
- API budget: ≤ 50 calls/repo.

For full scoring methodology, see `models/ai-augmentation-maturity/model-spec.md`, `readiness-scoring.md`, and `adoption-scoring.md`.

### Automation Scripts

```
scripts/aamm/scan-repo.sh owner/repo [overrides.json]
  ├── collect-all.sh        → GitHub API data collection (incl. blockchain domain signals)
  ├── score-readiness.sh    → 17 signals + domain profile → JSON
  ├── score-adoption.sh     → 5 dimensions (8 content categories) → JSON
  ├── review-scores.sh      → Principal engineer validation (language/domain-aware)
  ├── generate-report.sh    → .md + .json report (with recommendations)
  └── cross-repo-learn.sh   → Cross-repo best practice detection (run after batch scan)
```

Scripts run non-interactively. No confirmations. Agent delivers the final report.

**Plan files:** Each model directory has a `plan.md` with prioritized backlog. Read it first, update it when completing work.

## Tracked Repositories

29 repos across 4 GitHub orgs. Full list in `scans/ai-augmentation/config.yaml`.

GitHub orgs: IntersectMBO, input-output-hk, cardano-scaling, HarmonicLabs.

## Agent Instructions

1. **Never commit directly to `main`.** Always create a feature branch, push it, and open a PR. Only Dorin (repo owner) merges PRs into `main` after review. No exceptions.
2. **Never expose secrets.** Do not print, log, echo, commit, or include in any output: API keys, tokens, passwords, environment variable values, private keys, or credentials. Reference them by name only (e.g., `$GITHUB_TOKEN`), never by value.
2. **Quality gate** — invoke the `quality-gate` skill before declaring any task complete. Skip for questions, explanations, and simple lookups.
2. **Read `plan.md` first.** Each model has a `plan.md` (e.g., `models/ai-augmentation-maturity/plan.md`) with prioritized backlog, current status, and design decisions. Read it before starting any work to understand what's done, what's in progress, and what's next.
2. **Read the model files before scanning.** Load `models/ai-augmentation-maturity/model-spec.md`, `readiness-scoring.md`, and `adoption-scoring.md`.
3. **Use `scripts/aamm/scan-repo.sh`** for automated scans. The pipeline is 5 steps: collect → score-readiness → score-adoption → review-scores → generate-report. Override signal scores that need agent judgment via `overrides.json`.
4. **Update `plan.md` when completing work.** Move items from Backlog → Done, add new items discovered during implementation.
5. **Write results as JSON** to `scans/*/results/YYYY-MM.json`.
6. **Never publish to Notion without human approval.**
7. **Treat model definitions as mutable drafts.** Flag edge cases and inconsistencies.
8. **Before every commit — check for secrets.** No API keys, tokens, passwords, `.env` files, or credentials.
9. **When unsure, ask.**

## Peer Review Gate

All work must pass peer review before delivery. This is mandatory, not optional.

- **Checkpoint 1 (Design):** Before implementing non-trivial changes, invoke the
  peer-review skill with type=design. May be skipped with explicit justification.
- **Checkpoint 2 (Implementation):** After writing code/spec changes, invoke the
  peer-review skill with type=implementation. May be skipped with explicit justification.
- **Checkpoint 3 (Output):** After producing any deliverable, invoke the peer-review
  skill with type=output. Never skipped. Must score ≥9.0/10 (conditional pass at
  8.5-8.9 if all objections are cosmetic).

Skipped checkpoints are audited at checkpoint 3. See `skills/peer-review/SKILL.md` for the
full rubric, personas, escalation rules, and context requirements.

## Source of Truth Hierarchy

1. **This repo (GitHub)** → model definitions, scoring rules, scan prompts, results.
2. **Notion** → display/presentation layer, rendered from GitHub content.
3. **When they diverge, GitHub wins.**

## Key References

- Confluence CoE page: `https://input-output.atlassian.net/wiki/spaces/IOE/pages/5700845586/`
- Sibling repo: `cbu-coe` (knowledge, guidance, templates)
