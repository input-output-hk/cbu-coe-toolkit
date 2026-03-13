# CLAUDE.md — cbu-coe-toolkit

> Root context file for AI agents working in this repository.
> Keep under 300 lines. Link to detail files rather than inlining everything.

## Repository Identity

- **Repo:** `cbu-coe-toolkit`
- **Purpose:** Measurement machinery — maturity models, scan prompts, scoring methodology, results history, and automation skills
- **Owner:** Dorin Solomon, CoE Head, Cardano Business Unit (CBU) at IOG
- **Primary consumers:** CoE operator (Dorin) and AI agents running scans
- **Sibling repo:** `cbu-coe` (knowledge, guidance, templates — the materials teams actually use)

## What This Repo Contains

```
cbu-coe-toolkit/
├── CLAUDE.md                         ← You are here
├── README.md                         # Project overview
├── models/                           # Measurement model definitions (source of truth)
│   ├── ai-augmentation/
│   │   ├── model.md                  # Stage definitions, SDLC matrix
│   │   ├── scoring.md               # Scoring methodology, anti-gaming, edge cases
│   │   └── changelog.md             # Model version history with rationale
│   ├── engineering-vitals/
│   │   ├── model.md                  # KPIs, thresholds, data sources
│   │   └── changelog.md
│   └── capability-maturity/
│       ├── model.md                  # Engineering practices maturity
│       └── changelog.md
├── scans/                            # Scan execution and history
│   ├── ai-augmentation/
│   │   ├── SCAN_PROMPT.md            # Monthly scan prompt (agent-ready)
│   │   ├── config.yaml               # Tracked repos, orgs, signal definitions
│   │   └── results/                  # Machine-readable monthly snapshots (YYYY-MM.json)
│   └── capability-maturity/
│       ├── SCAN_PROMPT.md
│       ├── config.yaml
│       └── results/
├── skills/                           # Claude Code Skills
│   ├── scan-ai-augmentation/         # Skill: run the monthly AI augmentation scan
│   ├── publish-to-notion/            # Skill: write results to Notion display pages
│   ├── review-model/                 # Skill: self-review model for edge cases
│   └── synthesize/                   # Skill: cross-model narrative generation
├── notion/
│   ├── page-registry.yaml            # All Notion page IDs in one place
│   └── publishing-guide.md          # How results map to Notion pages
└── docs/
    ├── architecture.md               # System architecture, how pieces connect
    ├── operating-rhythm.md          # Monthly cadence, who does what when
    └── evolution-log.md             # Design decisions, why, what changed
```

## The Three-Model Architecture

This toolkit serves three complementary measurement instruments. The power is in how they connect, not in any single model.

| Model | Measures | Status |
|---|---|---|
| **Engineering Vitals Dashboard** | On-time delivery, value, cycle time, defects | Exists in Power BI (external, owned by ERS team) |
| **AI Augmentation Model** | Institutional AI readiness per repo | **DRAFT** — being migrated to `models/ai-augmentation/` |
| **Capability Maturity Model** | Engineering practices, processes, standards | **DRAFT** — to be defined in `models/capability-maturity/` |

### Critical Design Principles

1. **AI Augmentation stages are informative/educational, not judgment.** The goal is clarity — showing teams what good looks like. Not a scorecard.
2. **Engineering Vitals is the authoritative measure of value delivery.** This toolkit measures AI *presence*, not AI *value*. Value is the Vitals dashboard's job.
3. **Capability Maturity covers non-AI engineering practices** — the prerequisites for AI to be effective. Repos with excellent engineering but no AI signals are not failures.
4. **Cross-model synthesis is done by agents under human supervision.** Dorin reviews all outputs.
5. **Both AI Augmentation and Capability Maturity models are drafts.** Expect significant iteration.

## AI Augmentation Model — Key Concepts

### Five Stages (Summary)

- **Stage 0 — Invisible:** AI used locally, no repo-level awareness
- **Stage 1 — Configured:** AI config files give tools project context
- **Stage 2 — Active in PRs:** AI participating in contribution/review process
- **Stage 3 — In CI/CD:** AI runs automatically in pipeline
- **Stage 4 — Standardised:** Org-wide defaults, humans define policy, AI executes

### Five SDLC Dimensions

Each repo is scored 0–4 on: Code Quality, Security, Testing, Release, Ops/Monitoring.

### Scoring Rules

- Stages are **cumulative** — Stage 2 requires satisfying Stage 1.
- Non-AI tooling does not count toward AI augmentation scores (noted as "infrastructure readiness").
- Stage 1 has a **quality threshold** — stub files don't count (guideline: 50+ substantive lines).
- Each dimension carries a **confidence level** (High/Medium/Low).
- The model distinguishes between "present" and "active" signals.

For full scoring methodology, see `models/ai-augmentation/scoring.md`.

### Known Gaps

1. Ops/Monitoring jumps from Stage 0 to Stage 3 — no incremental path.
2. Model is architecturally shaped around Copilot signals — needs to better capture Claude Code, Cursor, and other tools.
3. "Why This Matters" claims in the model are not yet backed by Vitals data.

## Tracked Repositories

29 repos across 4 GitHub orgs. Full list and configuration in `scans/ai-augmentation/config.yaml`.

**Current baseline (March 2026):** 24 repos at Stage 0, 3 at Stage 1 (cardano-node-tests, lace, mithril), 1 transitioning 0→1 (afv-rpc-api).

GitHub orgs: IntersectMBO, input-output-hk, cardano-scaling, HarmonicLabs.

## Agent Execution Model

The monthly AI Augmentation scan follows this flow:

1. Human (Dorin) triggers Claude Code in terminal.
2. Agent reads `scans/ai-augmentation/SCAN_PROMPT.md` + `config.yaml` + `models/ai-augmentation/scoring.md`.
3. Agent scans GitHub repos via `$GITHUB_TOKEN`.
4. Agent writes results to `scans/ai-augmentation/results/YYYY-MM.json`.
5. Agent compares with previous month's results.
6. Agent shows results to Dorin for approval.
7. On approval, agent publishes to Notion display pages (using `notion/page-registry.yaml`).
8. Agent runs validation checklist.

## Skills Architecture (Progressive Disclosure)

Skills follow Anthropic's three-level pattern:

- **Level 1 (metadata):** Skill name + description loaded at startup (~100 tokens each).
- **Level 2 (SKILL.md body):** Full instructions loaded when the agent determines a skill is relevant.
- **Level 3 (reference files):** Additional detail loaded only as needed during execution.

Available skills (to be built in Phase 3):

| Skill | Purpose |
|---|---|
| `scan-ai-augmentation` | Run the monthly AI augmentation scan |
| `publish-to-notion` | Write results to Notion display pages |
| `review-model` | Self-review model for edge cases and improvements |
| `synthesize` | Cross-model narrative generation |

## Source of Truth Hierarchy

1. **This repo (GitHub)** → model definitions, scoring rules, scan prompts, results.
2. **Notion** → display/presentation layer, rendered from GitHub content.
3. **When they diverge, GitHub wins.** Notion gets updated from GitHub, never the reverse.

## Notion Page Registry

All page IDs are centralized in `notion/page-registry.yaml`. When publishing results, always look up IDs from that file — never hardcode them.

## Agent Instructions

When working in this repo:

1. **Read the relevant model file before scanning.** Always load `models/ai-augmentation/model.md` and `scoring.md` before running a scan.
2. **Write results as JSON** to `scans/*/results/YYYY-MM.json`. Keep them machine-readable.
3. **Never publish to Notion without human approval.** Always show Dorin the results first.
4. **Log design decisions** in `docs/evolution-log.md` with date, decision, and rationale.
5. **Treat model definitions as mutable drafts.** If you find edge cases or inconsistencies, flag them — don't silently work around them.
6. **Use `notion/page-registry.yaml`** for all Notion page IDs. Never hardcode.
7. **Do not create guidance or template content here.** That belongs in `cbu-coe`.
8. **When unsure, ask.** The human operator (Dorin) reviews everything.

## Key References

- Project brief: ask the human operator (contains full organizational context, model definitions, implementation plan)
- Confluence CoE page: `https://input-output.atlassian.net/wiki/spaces/IOE/pages/5700845586/`
- Existing CMM draft: `https://input-output.atlassian.net/wiki/spaces/EN/pages/5046305438/`
- Sibling repo: `cbu-coe` (knowledge, guidance, templates)
