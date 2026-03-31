# Synthesize — Portfolio Review Design Spec

> Aggregates AAMM v6 scan results across tracked repos into a portfolio-level review for CoE and CBU Leadership.

---

## Problem

Individual scan reports (`report.md`) serve tech leads and repo owners well. But CoE and CBU Leadership need a portfolio-level view to answer: Where are the systemic opportunities? Which risks repeat across repos? Is the portfolio making progress? No artifact currently answers these questions.

## Scope

- **In scope:** `/synthesize` skill, `portfolio-review.md` output, activation threshold, freshness rules
- **Out of scope:** Team-facing comparisons (AAMM does not judge teams), Notion publishing, trend visualizations

## Audience

**CoE + CBU Leadership only.** This document is NOT distributed to individual teams. Teams receive their own `report.md` — the portfolio review is an internal strategic artifact.

Why: Cross-repo comparisons risk turning consultations into competitive scorecards, contradicting AAMM's "does not judge teams" principle.

---

## Architecture

### Invocation

```
/synthesize
```

No arguments. Reads config.yaml, finds latest scans, aggregates, writes output.

### Data Flow

```
config.yaml (29 repos)
  → For each repo: find most recent assessment.json within 90 days
  → Filter: only schema_version "6.0"
  → Check activation threshold: ≥5 fresh repos
  → If below threshold: write stub and STOP
  → Aggregate across fresh scans
  → Write portfolio-review.md
```

### Freshness Rules

- Only `assessment.json` files with `scan_date` within the last 90 days are included
- Repos with no fresh scan appear in "Coverage Gaps" — not in aggregations
- The report header states the exact date range of source data
- Repos with stale scans (>90 days) are listed separately as "Excluded — stale data"

### Activation Threshold

Minimum **5 repos** with fresh v6 `assessment.json` to produce a full review.

Below threshold: produce a stub file:

```markdown
# Portfolio Review — Insufficient Data
> Generated: YYYY-MM-DD

X of 29 tracked repos have fresh v6 scans (threshold: 5).

## Scanned repos
- owner/repo (scan date)

## Not yet scanned
- owner/repo
- ...

Run `/scan-aamm-v6 owner/repo` to add repos to the portfolio.
```

---

## Output Format

Written to: `scans/ai-augmentation/results/YYYY-MM-DD/portfolio-review.md`

```markdown
# AAMM Portfolio Review
> Generated: YYYY-MM-DD | Data window: YYYY-MM-DD to YYYY-MM-DD | Schema: v6.0
> Coverage: X/29 repos | Freshness: all scans within 90 days

## 1. Coverage

| Status | Count | Repos |
|--------|-------|-------|
| Scanned (fresh) | X | [repo1](link), [repo2](link), ... |
| Stale (>90 days) | Y | repo3, repo4, ... |
| Not scanned | Z | repo5, repo6, ... |

## 2. Quadrant Distribution

| Quadrant | Count | Repos |
|----------|-------|-------|
| High potential, High activity | N | [repo](link), ... |
| High potential, Low activity | N | [repo](link), ... |
| Low potential, High activity | N | [repo](link), ... |
| Low potential, Low activity | N | [repo](link), ... |

## 3. Cross-Portfolio Patterns

Opportunities appearing in ≥2 repos. These are systemic patterns, not individual repo findings.

| KB Pattern | Repos | Value | Insight |
|-----------|-------|-------|---------|
| cc_claude_md_context | [repo1](link), [repo2](link) | HIGH | X repos lack CLAUDE.md — single template could address all |
| hs_imp_test_generation | [repo1](link), [repo2](link) | HIGH | Common gap in Haskell repos with active era development |
| ... | | | |

**Novel patterns** (not in KB, appeared in ≥2 repos):
- pattern description — seen in: [repo1](link), [repo2](link)

## 4. Risk Summary

| Flag | Count | Repos |
|------|-------|-------|
| Risky Acceleration (Active + Undiscovered) | N | [repo](link), ... |
| Ad-hoc AI Usage (no intentionality signals) | N | [repo](link), ... |
| No .aiignore on high-assurance repo | N | [repo](link), ... |

## 5. Progress

> Cohort: repos scanned in both current and previous period.

| Metric | Previous | Current | Delta |
|--------|----------|---------|-------|
| Repos scanned | N | M | +X |
| Avg opportunities per repo | N | M | +/-X |
| Repos with risky acceleration | N | M | +/-X |
| Repos with .aiignore | N | M | +/-X |

### Quadrant Movement (cohort only)
- repo1: Low activity → High activity ([report](link))
- repo2: unchanged
```

### Linking Rules

Every repo name that references scan data MUST be a relative link to that repo's `report.md`:

```markdown
[owner/repo](../YYYY-MM-DD/owner--repo/report.md)
```

This makes every claim verifiable with one click.

---

## Implementation

### What the skill does (step by step)

1. **Read config.yaml** — get list of 29 tracked repos with org/repo/project/language
2. **Scan results directory** — for each repo, find the most recent `assessment.json` where:
   - `schema_version` = `"6.0"`
   - `scan_date` within last 90 days from today
3. **Check activation threshold** — if fewer than 5 repos have fresh scans, write stub and STOP
4. **Extract per-repo data** from each fresh `assessment.json`:
   - `quadrant.ai_potential`, `quadrant.ai_activity`, `quadrant.position`
   - `opportunity_map[]` — filter to `adversarial_status: "approved"`, extract `kb_pattern`, `value`
   - `flags.risky_acceleration[]`, `flags.adhoc_usage`
   - `recommendations[]` — filter to `adversarial_status: "approved"`, extract `type`, `title`
   - `adoption_state[]` — count Active/Partial/Absent
5. **Aggregate**:
   - Quadrant distribution: count repos per quadrant
   - Cross-portfolio patterns: group approved opportunities by `kb_pattern`, count repos, keep those with count ≥2
   - Risk flags: collect repos with non-empty `risky_acceleration` or `adhoc_usage: true`
   - .aiignore check: from opportunity data, find repos where `cc_aiignore_boundaries` is an approved opportunity (meaning .aiignore is absent)
6. **Progress** (if previous portfolio-review.md exists):
   - Find previous `portfolio-review.md` in an earlier date directory
   - Compare cohort: repos present in both current and previous
   - Compute deltas on: coverage, quadrant shifts, risk flag changes
7. **Write portfolio-review.md** with all links

### Error Handling

| Condition | Action |
|-----------|--------|
| config.yaml missing | Error: "Cannot find config.yaml" |
| No assessment.json files found | Write stub: "No v6 scans found" |
| Below activation threshold | Write stub with scan counts |
| assessment.json parse error | Skip repo, note in report: "Skipped: parse error" |
| No previous portfolio-review.md | Omit Progress section, note "First portfolio review" |

---

## What This Does NOT Do

- **Does not compare teams** — patterns are presented as systemic insights ("8 repos lack CLAUDE.md"), not rankings
- **Does not distribute to teams** — CoE + Leadership only
- **Does not trigger scans** — reports on existing data, suggests scanning gaps
- **Does not include v5 data** — v6 schema only
- **Does not call external APIs** — reads local files only

---

## Success Criteria

1. With ≥5 fresh v6 scans, produces a portfolio-review.md with all 5 sections
2. Every repo reference links to its report.md
3. Cross-portfolio patterns correctly identify opportunities appearing in ≥2 repos
4. Below threshold: produces a useful stub, not an empty file
5. Progress section compares same cohort, doesn't mix new repos into deltas
