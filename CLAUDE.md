# CLAUDE.md — cbu-coe-toolkit

> Context file for AI agents. Under 200 lines. Use progressive disclosure.

## Project

- **Repo:** `cbu-coe-toolkit` — measurement models, scan automation, Knowledge Base
- **Owner:** Centre of Excellence (CoE), Cardano Business Unit, IOG
- **Consumers:** CoE operators and AI agents running scans
- **Sibling:** [`cbu-coe`](https://github.com/input-output-hk/cbu-coe) — guidance, templates, skills for teams

## Structure

```
cbu-coe-toolkit/
├── kb/                            # AAMM v5 Knowledge Base (live)
│   ├── ecosystems/                # Per-language patterns
│   ├── cross-cutting.md           # Universal patterns
│   └── anti-patterns.md           # What doesn't work
├── models/                        # Model definitions
│   ├── config.yaml                # Tracked repos (29 repos, 4 orgs)
│   ├── engineering-vitals/        # KPIs, thresholds (Power BI external)
│   └── capability-maturity/       # Engineering practices (draft)
├── scans/ai-augmentation/         # Scan config + results
├── .claude/skills/                # Claude Code skills (autodetected)
├── notion/                        # Page registry, publishing guide
└── docs/
    ├── decisions/                 # Architecture Decision Records
    ├── superpowers/specs/         # Design specs
    └── learnings.md               # Operational insights log
```

## Three-model architecture

| Model | Question | Location |
|---|---|---|
| **AI Augmentation (AAMM)** | Is AI institutionalised? | `kb/`, `.claude/skills/scan-aamm-v5/`, `docs/superpowers/specs/2026-03-27-aamm-v5-spec.md` |
| **Capability Maturity** | Are engineering practices solid? | `models/capability-maturity/` (draft) |
| **Engineering Vitals** | Is work delivering value? | Power BI (external) |

Design principles:
- **AAMM is a consultation, not a score.** It tells teams where they are and what to do next with highest ROI.
- Stages are **informative**, not judgment. The goal is showing teams what good looks like.
- **Measure outcomes, not mechanisms.** Score what matters, not which tool is used. See ADR-011.
- **Adversarial review is mandatory (ADR-012).** Nothing gets published without skeptical review.

## AAMM v5

AAMM v5 uses a single AI agent (not a bash pipeline) to assess repos. See ADR-018.

**Key files:**
- `docs/superpowers/specs/2026-03-27-aamm-v5-spec.md` — v5 spec (authoritative)
- `.claude/skills/scan-aamm-v5/SKILL.md` — scan skill (invoke with `/scan-aamm-v5`)
- `kb/` — Knowledge Base (live, enriched after each scan)
- `models/config.yaml` — tracked repo list (29 repos, 4 orgs)
- `scans/ai-augmentation/config.yaml` — scan configuration

**Read order for agents:**
1. v5 spec — understand rubric + depth methodology
2. KB files for target ecosystem — patterns and anti-patterns
3. `models/config.yaml` — which repos to scan

## Scan flow (v5)

```
/scan-aamm-v5 owner/repo
  → Load KB + config                    # Agent reads ecosystem patterns
  → Collect repo data via GitHub API     # Tree, PRs, commits, key files
  → Rubric assessment (5 pillars, 5 zones)  # Structured criteria, YES/NO
  → Depth assessment                     # Read files, produce grounded findings
  → Draft recommendations               # 5-7, ROI-prioritized
  → Adversarial review (separate agent)  # Spot-check rubric + challenge recs
  → Generate report (3 files)            # report.md, assessment.json, detailed-log.md
```

Non-interactive. No confirmations. Results go to `scans/ai-augmentation/results/YYYY-MM-DD/`.

Tracked repos: 29 across 4 orgs. See `models/config.yaml`.

## Source of truth

1. **This repo (GitHub)** — model definitions, KB, scan results
2. **Notion** — display layer, rendered from GitHub content
3. When they diverge, GitHub wins.

## Rules

0. **Show the data, challenge yourself, then conclude.**
   - **Data first:** "It's good" without evidence is an opinion, not an evaluation. Run the numbers, show the distribution, check the evidence, then conclude. If you can't show data, say "I don't have data for this" — don't fill the gap with confidence.
   - **Second pass:** Before delivering any non-trivial output, ask yourself: "What did I simplify, ignore, or assume? What would a skeptical senior engineer challenge here?" The gap between first draft and second pass is where quality lives.
   - **Confidence explicit:** When making evaluations or recommendations, state your confidence (HIGH/MEDIUM/LOW) and why. HIGH = concrete evidence. MEDIUM = pattern/heuristic. LOW = inference/absence. Don't present LOW confidence conclusions with HIGH confidence language.
1. **Never commit to `main`.** Branch → PR → owner review → merge.
2. **Never expose secrets.** No printing, logging, or committing API keys, tokens, passwords, or env variable values. Reference by name only (`$GITHUB_TOKEN`).
3. **Check for secrets before every commit.** Run `git diff --cached` and review every line.
4. **Quality gate = Rule 0.** Show data, challenge yourself, state confidence.
5. **Read `backlog.md` first (if it exists).** Local working doc (gitignored).
6. **Read v5 spec before scanning.** Load spec → KB → config → then scan.
7. **Use `.claude/skills/scan-aamm-v5/`** for scans. Target repo from `models/config.yaml` or manual input.
8. **Results as JSON + MD** to `scans/*/results/YYYY-MM-DD/`.
9. **Never publish to Notion without human approval.**
10. **Model definitions are mutable drafts.** Flag edge cases and inconsistencies.
11. **PRs explain why**, not just what.
12. **When unsure, ask.**
13. **Adversarial review before publishing (ADR-012).** Every scan result gets a skeptical reviewer agent. The default is circumspect — assume the assessment is wrong until challenged and confirmed.
14. **Don't patch broken architecture.** When a bug reveals a design flaw, stop. Audit the full affected area. Fix the design, then the implementation.

## Sync protocol

When changing AAMM assessment logic, update ALL of these in the same session:
1. **Spec** (`docs/superpowers/specs/2026-03-27-aamm-v5-spec.md`) — the rules
2. **Scanner prompt** (`.claude/skills/scan-aamm-v5/prompts/scanner-system.md`) — rubric tables
3. **This file** (CLAUDE.md) — if the change affects how agents use the model
4. **ADR** (`docs/decisions/`) — if the change is a significant design decision
5. **KB** (`kb/`) — if the change affects patterns or anti-patterns

A change in one without the others is a bug.

## Session handoff

Before ending a session, propose knowledge capture:

1. **Learnings** — draft entries for `docs/learnings.md`.
2. **Decisions** — if significant choices were made, draft an ADR following `docs/decisions/000-template.md`.
3. **Present to the operator for review.** Do not commit without approval.

## References

- [Confluence CoE page](https://input-output.atlassian.net/wiki/spaces/IOE/pages/5700845586/)
- Sibling repo: `cbu-coe`
