# CLAUDE.md — cbu-coe-toolkit

> Root context file for AI agents working in this repository.
> Keep under 300 lines. Link to detail files rather than inlining everything.

## Repository Identity

- **Repo:** `cbu-coe-toolkit`
- **Purpose:** Measurement machinery — maturity models, scan prompts, scoring methodology, results history, and automation skills
- **Owner:** CoE (Centre of Excellence), Cardano Business Unit (CBU) at IOG
- **Primary consumers:** CoE operators and AI agents running scans
- **Sibling repo:** `cbu-coe` (knowledge, guidance, templates — the materials teams actually use)

## What This Repo Contains

```
cbu-coe-toolkit/
├── CLAUDE.md                         ← You are here
├── README.md                         # Project overview
├── models/                           # Measurement model definitions (source of truth)
│   ├── ai-augmentation-maturity-v3/  # Current model (v3)
│   │   ├── model-spec.md            # Two-axis architecture, stages, quadrant model
│   │   ├── adoption-scoring.md      # Adoption scoring methodology per dimension
│   │   ├── readiness-scoring.md     # Readiness scoring methodology (R1-R4 pillars)
│   │   └── changelog.md             # Model version history (v1 → v2 → v3)
│   ├── ai-augmentation-maturity/     # v1 (deprecated — see v3)
│   ├── ai-augmentation-maturity-v2/  # v2 experimental (deprecated — see v3)
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
    ├── decisions/                    # Architecture Decision Records (ADRs)
    │   └── NNN-title.md             # One file per decision (see 000-template.md)
    ├── learnings.md                  # Append-only operational insights log
    ├── architecture.md               # System architecture, how pieces connect
    ├── operating-rhythm.md          # Monthly cadence, who does what when
    └── evolution-log.md             # Chronological record of significant changes
```

## Knowledge Capture System

This repo uses a three-layer system to preserve learnings across agent sessions (see ADR-001):

1. **`docs/decisions/`** — Architecture Decision Records. One file per significant decision, numbered sequentially. Read these first to understand constraints you should not re-litigate.

2. **`docs/learnings.md`** — Append-only operational insights. Edge cases, technical discoveries, process improvements. Read this to avoid repeating mistakes.

3. **Session handoff protocol** — See "Before Ending Any Session" in Agent Instructions below.

**Start of every session:** Read `docs/learnings.md` and scan `docs/decisions/` to load accumulated context.

## The Three-Model Architecture

This toolkit serves three complementary measurement instruments. The power is in how they connect, not in any single model.

| Model | Measures | Status |
|---|---|---|
| **Engineering Vitals Dashboard** | On-time delivery, value, cycle time, defects | Exists in Power BI (external) |
| **AI Augmentation Model (v3)** | Institutional AI readiness + adoption per repo | **DRAFT** — `models/ai-augmentation-maturity-v3/` |
| **Capability Maturity Model** | Engineering practices, processes, standards | **DRAFT** — to be defined in `models/capability-maturity/` |

### Critical Design Principles

1. **AI Augmentation stages are informative/educational, not judgment.** The goal is clarity — showing teams what good looks like. Not a scorecard.
2. **Engineering Vitals is the authoritative measure of value delivery.** This toolkit measures AI *presence*, not AI *value*. Value is the Vitals dashboard's job.
3. **Capability Maturity covers non-AI engineering practices** — the prerequisites for AI to be effective. Repos with excellent engineering but no AI signals are not failures.
4. **Cross-model synthesis is done by agents under human review.** All outputs are reviewed before publishing.
5. **Both AI Augmentation and Capability Maturity models are drafts.** Expect significant iteration.

## AI Augmentation Model — Key Concepts

### Two-Axis Architecture (v3)

AAMM v3 is a two-axis model:
- **AI Readiness (0-100)** — Is this codebase structurally suitable for AI collaboration? Scored via 4 pillars: R1 Structural Clarity (30%), R2 Semantic Density (30%), R3 Verification Infrastructure (25%), R4 Developer Ergonomics (15%).
- **AI Adoption** — Is AI actively used in workflows? Scored per SDLC dimension with Stages (0-4) and Sub-levels (Low/Mid/High).

The two axes form a quadrant: Traditional, Fertile Ground, Risky Acceleration, AI-Native.

### Seven Adoption Dimensions

Each repo is scored 0-4 on: Code Quality, Security, Testing, Release, Ops/Monitoring, AI-Assisted Delivery, AI Practices & Governance (cross-cutting).

### Key Scoring Rules

- Stage 1 requires **two conditions**: (A) relevant practice active + (B) AI config covering that dimension.
- Stages are **cumulative** — Stage 2 requires satisfying Stage 1.
- Sub-levels (Low/Mid/High) provide within-stage granularity.
- Learning signals (static/evolving/self-improving) enrich sub-level assessment.
- Non-AI tooling contributes to Readiness, not Adoption (noted as "infrastructure readiness").
- Stage 1 has a **quality threshold** — stub files don't count (guideline: 50+ substantive lines).
- Each dimension carries a **confidence level** (High/Medium/Low).
- Always exactly 3 Next Steps per repo, ordered by impact/effort ratio.

For full scoring methodology, see `models/ai-augmentation-maturity-v3/model-spec.md`, `adoption-scoring.md`, and `readiness-scoring.md`.

### Known Gaps (v3)

1. Language-specific Readiness bonuses defined for Haskell, Rust, TypeScript only — other languages use universal signals only.
2. Delivery dimension Stage 2+ requires GitHub-visible signals — teams using Jira/Linear are measured only through documented external tools at Stage 1.
3. Readiness scoring requires agent judgment for some signals — reproducibility comes from mandatory evidence recording, not strict formulas.

## Tracked Repositories

29 repos across 4 GitHub orgs. Full list and configuration in `scans/ai-augmentation/config.yaml`.

GitHub orgs: IntersectMBO, input-output-hk, cardano-scaling, HarmonicLabs.

## Agent Execution Model

The monthly AI Augmentation scan follows this flow:

1. Human operator triggers Claude Code in terminal.
2. Agent reads `scans/ai-augmentation/SCAN_PROMPT.md` + `config.yaml` + `models/ai-augmentation-maturity-v3/model-spec.md` + `readiness-scoring.md` + `adoption-scoring.md`.
3. Agent scans GitHub repos via `$GITHUB_TOKEN`.
4. Agent writes results to `scans/ai-augmentation/results/YYYY-MM.json`.
5. Agent compares with previous month's results.
6. Agent shows results to human operator for approval.
7. On approval, agent publishes to Notion display pages (using `notion/page-registry.yaml`).
8. Agent runs validation checklist.

## Skills Architecture (Progressive Disclosure)

Skills follow Anthropic's three-level pattern:

- **Level 1 (metadata):** Skill name + description loaded at startup (~100 tokens each).
- **Level 2 (SKILL.md body):** Full instructions loaded when the agent determines a skill is relevant.
- **Level 3 (reference files):** Additional detail loaded only as needed during execution.

Available skills (to be built):

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

1. **Start by reading `docs/learnings.md` and scanning `docs/decisions/`.** This is accumulated context from all previous sessions.
2. **Read the relevant model file before scanning.** Always load `models/ai-augmentation-maturity-v3/model-spec.md`, `adoption-scoring.md`, and `readiness-scoring.md` before running a scan.
3. **Write results as JSON** to `scans/*/results/YYYY-MM.json`. Keep them machine-readable.
4. **Never publish to Notion without human approval.** Always show results to the human operator first.
5. **Treat model definitions as mutable drafts.** If you find edge cases or inconsistencies, flag them — don't silently work around them.
6. **Use `notion/page-registry.yaml`** for all Notion page IDs. Never hardcode.
7. **Do not create guidance or template content here.** That belongs in `cbu-coe`.
8. **Before every commit — check for secrets.** Scan for API keys, tokens, passwords, private keys, `.env` files, or any credentials. Run `git diff --cached` and review every line. Check `git status` for files that should not be tracked. No internal URLs with auth tokens, no personal data, no sensitive organizational context. If in doubt, ask before committing. A leaked secret is harder to fix than a delayed commit.
9. **When unsure, ask.** The human operator reviews everything.

### Before Ending Any Session

**This step is not optional.** Before wrapping up, propose knowledge capture:

1. **Learnings:** Draft specific entries for `docs/learnings.md` — things discovered, edge cases hit, technical insights, anything the next agent would benefit from knowing. Use the format: `- **Short title:** Description.` under a dated heading.

2. **Decisions:** If any significant choices were made during the session (architectural, methodological, process-related), draft an ADR file following `docs/decisions/000-template.md`. Number it sequentially.

3. **Evolution log:** If the toolkit itself changed (new files, restructured content, updated models), add a dated entry to `docs/evolution-log.md`.

4. **Present all proposed additions to the human operator for review.** Do not commit without approval.

If the session produced no new learnings (unlikely), state that explicitly so the human operator knows you considered it.

## Key References

- Confluence CoE page: `https://input-output.atlassian.net/wiki/spaces/IOE/pages/5700845586/`
- Existing CMM draft: `https://input-output.atlassian.net/wiki/spaces/EN/pages/5046305438/`
- Sibling repo: `cbu-coe` (knowledge, guidance, templates)
