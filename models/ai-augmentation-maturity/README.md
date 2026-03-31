# AI Augmentation Maturity Model (AAMM)

> **Version:** v6 (use-case spectrum architecture)
> **Owner:** Centre of Excellence (CoE), Cardano Business Unit, IOG
> **ADR:** [ADR-019](../../docs/decisions/019-aamm-v5-wrong-question.md) (supersedes ADR-018, ADR-017)

---

## What AAMM Does

AAMM is an AI-powered consultation per repository. It tells teams **where AI can add the most value** for their specific codebase, **where they currently are** on that journey, and **what to do next with the highest ROI**.

It does NOT produce numeric scores or rank teams. It produces leveled indicators, evidence-grounded findings, and ROI-ordered recommendations. The quality of findings and recommendations is the primary measure of AAMM's value.

**What AAMM is NOT:**
- Not a code quality model — that is Capability Maturity
- Not a business impact model — that is Engineering Vitals
- Not a judge — it informs and recommends

### Four Problems AAMM Solves

| # | Problem | How AAMM Solves It |
|---|---------|-------------------|
| 1 | **Awareness gap** — teams don't know what AI can do across the full SDLC | Agent derives specific opportunities from the repo itself with evidence |
| 2 | **Where to start** — teams don't know what to do first | Opportunities and recommendations ROI-ordered — #1 is the highest-ROI action |
| 3 | **No feedback loop** — learnings stay siloed per team | KB captures patterns with `seen_in` attribution across the portfolio |
| 4 | **Risk without guardrails** — AI on high-assurance code without boundaries | Risk Surface maps AI exposure to concrete code paths, not theoretical risk |

---

## How AAMM Works

### Five Assessment Components

| Component | Question |
|-----------|----------|
| **Opportunity Map** | Where would AI add the most value in this repo? |
| **Adoption State** | Which opportunities are currently in use? (Active / Partial / Absent) |
| **Readiness per Use Case** | Is the repo set up to make each opportunity effective? (KB criteria) |
| **Risk Surface** | Where would AI errors be hardest to detect and most damaging? |
| **Recommendations** | What should the team do next, ROI-ordered? |

Plus one flag: **Ad-hoc AI Usage** — triggered when AI is active but no intentionality signals exist.

### Two Scan Types

- **Learning Scan:** Populates KB from well-understood repos. Output: `kb-proposals.md`. Run before first scoring scan on an ecosystem.
- **Scoring Scan:** Full assessment. Output: `report.md` + `assessment.json` + `detailed-log.md`. Fully autonomous, no mid-scan gates.

### Architecture: Single AI Agent + Two Adversarial Reviews

```
/scan-aamm-v6 owner/repo
  │
  ├─ Load scoring-model.md + KB for ecosystem
  ├─ Collect repo data via GitHub API (tree, commits, PRs, key files, churn)
  ├─ Generate Opportunity Map (ROI-ordered)
  ├─ Adversarial Review — Stage A (filters platitudes from map)
  ├─ Assess: Adoption State, Readiness, Risk Surface per opportunity
  ├─ Generate Recommendations (ROI-ordered)
  ├─ Adversarial Review — Stage B (challenges recommendations)
  └─ Generate report (3 files) ✓ OFFICIAL at completion
```

The scan is fully autonomous — no confirmations, no human gates during execution. The report is official and publishable at completion. CoE can challenge findings post-publication with evidence.

### Quadrant (Leadership View)

**AI Potential** (readiness) × **AI Activity** (adoption) produces a descriptive position label. Labels are neutral, not judgmental. See spec.md Section 7.

---

## How to Trigger a Scan

### Single repo scan

In Claude Code (web or CLI), from the `cbu-coe-toolkit` root:

```
/scan-aamm-v6 IntersectMBO/cardano-ledger
```

The skill is defined in [.claude/skills/scan-aamm-v6/SKILL.md](../../.claude/skills/scan-aamm-v6/SKILL.md).

**Prerequisites:** `GITHUB_TOKEN` must be set for private repos. Public repos need no auth.

**Output:** Three files written to `scans/ai-augmentation/results/YYYY-MM-DD/owner--repo/`:
- `report.md` — team-facing report (summary, opportunities, risk, recommendations)
- `assessment.json` — structured data (schema v6.0)
- `detailed-log.md` — full audit trail

### Batch scan (all tracked repos)

```
/scan-aamm-v6 scan all
```

### Next repo in queue

```
/scan-aamm-v6 scan next
```

---

## Audiences

| Who | What they see | Time |
|-----|-------------|------|
| **Team / tech lead** | Executive summary (first 15 lines) | 5 min |
| **CoE lead** | Full report + portfolio view | 15 min |
| **Leadership / stakeholders** | Quadrant + delta + trajectory | 2 min |

---

## Knowledge Base

The KB (`knowledge-base/`) holds two things per ecosystem:
1. **Opportunity patterns** — AI use cases with `applies_when`, `evidence_to_look_for`, `learning_entry`
2. **Readiness criteria** — per use-case type, validated by CoE

KB must be populated via learning scans (Phase 0) before first scoring scan. See spec.md Section 9.

---

## Scope

**Unit of assessment:** One repository per scan.
**Tracked repos:** 29 repos across 4 orgs. See [models/config.yaml](../config.yaml).
**Supported ecosystems:** Haskell, TypeScript, Rust, Python (+ cross-cutting for others).
**Scan cadence:** Quarterly + ad-hoc.

---

## Files in This Model

| File | Purpose |
|------|---------|
| `README.md` | This file — model overview, how to trigger |
| `scoring-model.md` | Operational manual for the scanner agent (source of truth at runtime) |
| `spec.md` | Architecture, design rationale, edge cases (for humans) |
| `changelog.md` | Model evolution (v1→v6) |
| `knowledge-base/` | Opportunity patterns + readiness criteria per ecosystem |

**Skill:** [.claude/skills/scan-aamm-v6/](../../.claude/skills/scan-aamm-v6/SKILL.md)
**Scan results:** `scans/ai-augmentation/results/`
**Decisions:** `docs/decisions/` (ADR-017, ADR-018, ADR-019)

---

## Sync Protocol

When changing AAMM assessment logic, update ALL in the same session:

1. `scoring-model.md` — operational rules
2. `spec.md` — if architectural decision
3. `changelog.md` — version the change
4. `CLAUDE.md` (repo root) — if it affects agent navigation
5. `knowledge-base/` — if it affects patterns or criteria
6. ADR in `docs/decisions/` — if significant design decision

A change in one without the others is a bug.
