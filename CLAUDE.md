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
├── models/                        # Model definitions
│   ├── config.yaml                # Tracked repos (29 repos, 4 orgs)
│   ├── ai-augmentation-maturity/  # AAMM — full model home
│   │   ├── README.md              # What, how, scope, how to trigger
│   │   ├── scoring-model.md       # Operational manual for scanner agent (source of truth at runtime)
│   │   ├── spec.md                # Architecture + design rationale (for humans)
│   │   ├── changelog.md           # Model evolution
│   │   └── knowledge-base/        # Opportunity patterns + readiness criteria per ecosystem
│   │       ├── ecosystems/        # Per-language patterns (haskell, typescript, rust, python)
│   │       ├── cross-cutting.md   # Universal patterns
│   │       └── anti-patterns.md   # What doesn't work
│   ├── engineering-vitals/        # KPIs, thresholds (Power BI external)
│   └── capability-maturity/       # Engineering practices (draft)
├── scans/ai-augmentation/         # Scan config + results
├── .claude/skills/                # Claude Code skills (autodetected)
├── notion/                        # Page registry, publishing guide
└── docs/
    ├── decisions/                 # Architecture Decision Records
    ├── superpowers/               # Design specs + implementation plans
    └── learnings.md               # Operational insights log
```

## Three-model architecture

| Model | Question | Location |
|---|---|---|
| **AI Augmentation (AAMM)** | Where can AI add the most value, and what to do next? | `models/ai-augmentation-maturity/` |
| **Capability Maturity** | Are engineering practices solid? | `models/capability-maturity/` (draft) |
| **Engineering Vitals** | Is work delivering value? | Power BI (external) |

Design principles:
- **AAMM is a consultation, not a score.** It tells teams where they are and what to do next with highest ROI.
- **Does not judge teams** — informs and recommends.
- **Measure outcomes, not mechanisms.** Score what matters, not which tool is used. See ADR-011.
- **Tri-agent consensus — Claude + Gemini + Grok at every phase (ADR-020 + spec 2026-04-03).**
- **Report is official at completion.** CoE challenges post-publication, not pre-publication.

## AAMM v7

AAMM v7 uses tri-agent consensus (Claude + Gemini + Grok) with local clone + request/serve protocol. See ADR-020.

**Separation of concerns:**
- `spec.md` = design rationale (for humans)
- `scoring-model.md` = operational manual (for agents — read this at scan time)

**Key files:**
- `models/ai-augmentation-maturity/scoring-model.md` — **read first at scan time**
- `models/ai-augmentation-maturity/knowledge-base/` — opportunity patterns + readiness criteria
- `models/ai-augmentation-maturity/spec.md` — architecture + edge cases
- `models/config.yaml` — tracked repos (29 repos, 4 orgs) + reference_repos for KB enrichment

**Read order for agents:**
1. `scoring-model.md` — step-by-step operational manual
2. KB files for target ecosystem — opportunity patterns + readiness criteria
3. `models/config.yaml` — which repos to scan

## Scan flow (v7 — tri-agent consensus)

```
/scan-aamm-v7 owner/repo
  → Health-check Gemini CLI + Grok API (parallel)  # STOP if either unavailable
  → Access check via GitHub API                     # STOP if 403
  → Clone repo locally → /tmp/aamm-v7-$OWNER-$REPO/clone/
  → Detect repo type (library/web-app/cli-tool/infrastructure/mixed)
  → Detect monorepo subprojects (deny-list: vendor/, deps/, third_party/)
  → Generate neutral manifest (structure + stats, no content, no signals)

  → Phase 1: File Requests (independent, parallel)
    → Claude subagent: requests files based on manifest + KB
    → Gemini: requests files based on manifest + KB (--yolo, can browse beyond list)
    → Grok: requests files based on manifest + KB (batched, max 50/batch)
    → Orchestrator serves all requests unfiltered from /clone/

  → Phase 2: Independent Analysis
    → Claude subagent: produces opportunity-map-claude.json
    → Gemini: produces opportunity-map-gemini.json
    → Grok: produces opportunity-map-grok.json
    → No agent sees another's output

  → Phase 3: Consensus — Opportunity Map
    → Intersection-first (items all 3 found → auto-approved)
    → Consensus loop max 5 rounds (JSON structured, ~120 tokens/exchange)
    → Tiered outcome: HIGH (all ≥9) | MEDIUM (2/3 ≥9 + third ≥7, CoE flag) | consensus:false
    → MEDIUM cap: 10 items per scan; overflow downgraded to LOW
    → Component Assessment (adoption/readiness/risk): same pattern

  → Phase 4: Consensus — Recommendations
    → All 3 generate independently → intersection-first → loop
    → ROI ordering consensus

  → Phase 5: Report Generation (Claude subagent, fresh context)
    → Reads assessment.json (frozen) + previous scan for delta
    → Writes: report.md, assessment.json, detailed-log.md

  → Phase 6: Save to scans/ai-augmentation/results/YYYY-MM-DD/$OWNER--$REPO/
```

Mid-scan failure: Gemini or Grok unavailable after 5 retries → continue PARTIAL with ⚠ WARNING in report.
Results go to `scans/ai-augmentation/results/YYYY-MM-DD/`.

## Gemini reviewer

Independent reviewer powered by Gemini 3.1 Pro. Available on-demand and as pre-commit gate.

- `/review-model <file-or-dir>` — on-demand review with scored findings
- Pre-commit hook on `models/` — blocks commit if score < 9.0
- GEMINI.md defines persona, perspectives, behavior rules, output format
- Fail-open: missing CLI or unparseable output → warn, don't block
- Bypass: `GEMINI_REVIEW=0 git commit` or `--no-verify`

## Source of truth

1. **This repo (GitHub)** — model definitions, KB, scan results
2. **Notion** — display layer, rendered from GitHub content
3. When they diverge, GitHub wins.

## Rules

0. **Show the data, challenge yourself, then conclude.**
   - **Data first:** "It's good" without evidence is an opinion, not an evaluation.
   - **Second pass:** "What did I simplify, ignore, or assume? What would a skeptic challenge?"
   - **Confidence explicit:** HIGH = concrete evidence. MEDIUM = pattern/heuristic. LOW = inference/absence.
1. **Never commit to `main`.** Branch → PR → owner review → merge.
2. **Never expose secrets.** Reference by name only (`$GITHUB_TOKEN`).
3. **Check for secrets before every commit.** Run `git diff --cached` and review every line.
4. **Quality gate = Rule 0.** Show data, challenge yourself, state confidence.
5. **Read `backlog.md` first (if it exists).** Local working doc (gitignored).
6. **Read scoring-model.md before scanning.** Load `scoring-model.md` → KB → config → then scan.
7. **Results as JSON + MD** to `scans/*/results/YYYY-MM-DD/`.
8. **Never publish to Notion without human approval.**
9. **Model definitions are mutable drafts.** Flag edge cases and inconsistencies.
10. **PRs explain why**, not just what.
11. **When unsure, ask.**
12. **Tri-agent consensus is mandatory (ADR-020 + spec 2026-04-03).** Claude + Gemini + Grok participate in every scoring scan. Health check failure at start → STOP. Mid-scan failure after 5 retries → PARTIAL with WARNING.
13. **Don't patch broken architecture.** When a bug reveals a design flaw, stop. Audit. Fix the design, then the implementation.

## Sync protocol

When changing AAMM assessment logic, update ALL of these in the same session:
1. **Scoring model** (`models/ai-augmentation-maturity/scoring-model.md`) — operational rules
2. **Spec** (`models/ai-augmentation-maturity/spec.md`) — if architectural decision
3. **Changelog** (`models/ai-augmentation-maturity/changelog.md`) — version the change
4. **This file** (CLAUDE.md) — if the change affects how agents navigate the model
5. **ADR** (`docs/decisions/`) — if significant design decision
6. **KB** (`models/ai-augmentation-maturity/knowledge-base/`) — if it affects patterns or criteria

A change in one without the others is a bug.

## Session handoff

Before ending a session, propose knowledge capture:

1. **Learnings** — draft entries for `docs/learnings.md`.
2. **Decisions** — if significant choices were made, draft an ADR following `docs/decisions/000-template.md`.
3. **Present to the operator for review.** Do not commit without approval.

## References

- [Confluence CoE page](https://input-output.atlassian.net/wiki/spaces/IOE/pages/5700845586/)
- Sibling repo: `cbu-coe`
