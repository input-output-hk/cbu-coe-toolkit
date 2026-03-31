---
name: synthesize
description: Generate a portfolio-level AAMM review aggregating v6 scan results across all tracked repos. Output is for CoE + CBU Leadership only — not distributed to teams.
---

# Synthesize — Portfolio Review

Aggregate AAMM v6 scan results into a portfolio-level review.

## Input

No arguments. Reads `models/config.yaml` and scans directory automatically.

## Step 1: Load Config

Read `models/config.yaml`. Extract all tracked repos as a list of `{org, repo, project, language}`.

Count total tracked repos (expected: 29).

## Step 2: Find Fresh Scans

For each tracked repo, search `scans/ai-augmentation/results/` for the most recent `assessment.json`:

```bash
# Pattern: scans/ai-augmentation/results/YYYY-MM-DD/ORG--REPO/assessment.json
find scans/ai-augmentation/results/ -name "assessment.json" -path "*/${ORG}--${REPO}/*" | sort -r | head -1
```

For each found `assessment.json`:
1. Read the file
2. Check `schema_version` = `"6.0"` — skip if not v6
3. Check `scan_date` is within last 90 days from today — mark as stale if older
4. If fresh and v6: add to `fresh_scans[]`

Classify each tracked repo into one of:
- **Fresh** — has v6 assessment.json with scan_date within 90 days
- **Stale** — has assessment.json but scan_date > 90 days ago
- **Not scanned** — no assessment.json found

## Step 3: Check Activation Threshold

If `fresh_scans.length < 5`:

Write stub to `scans/ai-augmentation/results/YYYY-MM-DD/portfolio-review.md`:

```markdown
# Portfolio Review — Insufficient Data
> Generated: {today}

{fresh count} of {total} tracked repos have fresh v6 scans (threshold: 5).

## Scanned repos
{for each fresh scan: - org/repo (scan_date)}

## Not yet scanned
{for each unscanned repo: - org/repo}

Run `/scan-aamm-v6 owner/repo` to add repos to the portfolio.
```

**STOP** — do not proceed to aggregation.

## Step 4: Extract Per-Repo Data

For each fresh `assessment.json`, extract:

```
repo_slug:       "{org}/{repo}"
scan_date:       assessment.scan_date
project:         from config.yaml
language:        from config.yaml
quadrant:        assessment.quadrant (ai_potential, ai_activity, position)
opportunities:   assessment.opportunity_map[] where adversarial_status = "approved"
                 → extract: id, title, kb_pattern, value
risk_accel:      assessment.flags.risky_acceleration[] (list of opportunity IDs)
adhoc_usage:     assessment.flags.adhoc_usage (boolean)
```

## Step 5: Aggregate

### 5a. Quadrant Distribution

Map each repo's `quadrant.position` to one of four categories based on `ai_potential` × `ai_activity`:
- HIGH × HIGH
- HIGH × LOW
- LOW × HIGH
- LOW × LOW

Count repos per category. Handle MEDIUM as: MEDIUM potential → LOW bucket, MEDIUM activity → LOW bucket (conservative).

### 5b. Cross-Portfolio Patterns

Group all approved opportunities across repos by `kb_pattern`:

```
pattern_counts = {}
for each repo:
  for each approved opportunity:
    key = opportunity.kb_pattern or "novel:" + normalize(opportunity.title)
    pattern_counts[key].repos.append(repo_slug)
    pattern_counts[key].values.append(opportunity.value)
    # Final value = highest across repos (HIGH > MEDIUM > LOW)
```

When writing the report, use the highest value seen across all repos for each pattern.

Keep patterns appearing in ≥2 repos. Sort by repo count descending.

For each pattern, generate an insight line: "{count} repos {have this gap / share this opportunity} — {actionable observation}".

### 5c. Risk Flags

Collect:
- Repos where `risk_accel` is non-empty → risky acceleration
- Repos where `adhoc_usage` is true → ad-hoc AI usage
- Repos where `cc_aiignore_boundaries` appears in approved opportunities → missing .aiignore

### 5d. Progress (if previous review exists)

Find previous `portfolio-review.md`:
```bash
TODAY=$(date +%Y-%m-%d)
ls scans/ai-augmentation/results/*/portfolio-review.md 2>/dev/null | sort -r | grep -v "$TODAY" | head -1
```

If found:
- Parse the previous review's Coverage section to get previously scanned repos
- Identify cohort: repos scanned in BOTH periods
- Compute deltas: coverage change, quadrant shifts, risk flag changes
- Only report on cohort repos for quadrant movement

If not found: note "First portfolio review — no progress data available."

## Step 6: Write Portfolio Review

Write to `scans/ai-augmentation/results/{today}/portfolio-review.md`.

Create the date directory if it doesn't exist.

**Linking rule:** Every repo reference must link to its report.md:
```
[org/repo](../{scan_date}/org--repo/report.md)
```
Use relative paths from the output directory.

Follow the exact section order from the spec:
1. Header with coverage stats and data window
2. Coverage table (fresh / stale / not scanned)
3. Quadrant Distribution table
4. Cross-Portfolio Patterns table + novel patterns
5. Risk Summary table
6. Progress table + quadrant movement (or "First review" note)

## Important

- **CoE + Leadership only** — this document is NOT for teams. Do not frame findings as team comparisons.
- **No judgment language** — "8 repos lack CLAUDE.md" not "8 teams haven't created CLAUDE.md"
- **Every claim links to evidence** — repo links go to report.md
- **Systemic patterns, not individual findings** — focus on what appears across ≥2 repos
- **No confirmations** — run fully autonomously end-to-end
- **Fail gracefully** — if a single assessment.json is broken, skip it and note in report
