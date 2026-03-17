# AAMM v3 — Monthly Scan Prompt

**Model version:** v3.0 · **Last updated:** March 2026

> This file is the agent-executable prompt for running the monthly AI Augmentation scan. Read the referenced documents before scanning.

---

## Pre-Scan: Load Context

Before scanning any repo, read these documents in order:

1. **Model spec:** `models/ai-augmentation-maturity-v3/model-spec.md` — what the stages, sub-levels, and quadrants mean
2. **Adoption scoring:** `models/ai-augmentation-maturity-v3/adoption-scoring.md` — step-by-step scoring per dimension
3. **Readiness scoring:** `models/ai-augmentation-maturity-v3/readiness-scoring.md` — R1-R4 metric-to-score mappings
4. **Config:** `scans/ai-augmentation/config.yaml` — tracked repos, signal patterns, bot names
5. **Previous results:** `scans/ai-augmentation/results/` — load the most recent snapshot for delta comparison

---

## Authentication — Pre-Flight Check (MANDATORY)

Before doing ANY GitHub work, the agent MUST run this pre-flight check:

```bash
# Step 1: Ensure GITHUB_TOKEN is loaded from shell profile
source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null

# Step 2: Verify token exists
if [ -z "$GITHUB_TOKEN" ]; then
  echo "FATAL: GITHUB_TOKEN not set. Cannot proceed."
  echo "Set it in ~/.zshrc and re-source, or export it manually."
  exit 1
fi

# Step 3: Verify token works with a test call
gh auth status
```

**If any step fails, STOP and ask the human operator.** Do not proceed without a working token. Do not attempt partial scans or fall back to unauthenticated API calls. Never print, log, display, or save the token value.

### Use `git` Commands, Not `gh` or `curl`

All repository data collection MUST use standard `git` commands — not `gh` CLI, not raw `curl`, not `fetch`.

**Approach:**
1. **Clone repos** with `git clone --depth 1` into a temp directory to inspect file trees, read file contents, check configs
2. **Inspect locally** using `git log`, `git show`, `ls`, `cat` — this gives you file trees, README, AI configs, workflow YAML, commit history, all without API rate limits
3. **For PR/issue data** (not in git), use `git log --merges` to detect merge activity, and authenticated API calls only when strictly necessary (branch protection, GitHub Projects)
4. **Authenticated API calls** (when needed) use the `$GITHUB_TOKEN` via: `curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/...`

**Why git over API:**
- No rate limiting for clone/local operations
- Full file tree and content available instantly after clone
- Commit history (including AI config evolution) inspectable via `git log`
- Avoids dependency on `gh` CLI installation
- Token exposure minimized (only used for API calls that cannot be done via git)

**If `git` cannot clone a repo** (auth failure, private repo), try the API. If both fail, mark the repo as inaccessible.

---

## Scan Execution Flow

### Step 1: Load Repo List

Read the tracked repos from `models/config.yaml`. This is the master list — do not duplicate it in this file.

For each repo, note: org, repo name, project, primary language.

### Step 2: For Each Repo — Collect Data

**Clone first, then inspect locally.** Use API calls only for data that cannot be obtained via git.

```bash
# Clone into temp directory (shallow clone for speed)
git clone --depth 50 "https://github.com/{owner}/{repo}.git" /tmp/scan/{repo}
cd /tmp/scan/{repo}
```

| Data | Purpose | How to Get |
|------|---------|------------|
| Full file tree | Readiness scoring, AI config detection | `find . -type f` or `git ls-tree -r --name-only HEAD` after clone |
| README.md content | R2 scoring | `cat README.md` after clone |
| AI config file contents | Adoption Stage 1 quality check | `cat {path}` for each detected config file after clone |
| Workflow YAML files | Condition A checks, Stage 3 detection | `ls .github/workflows/` and `cat` each file after clone |
| Recent commits | AI co-author detection, learning signals | `git log --since="{lookback_date}" --format="%H %an %s"` |
| Merge commits (proxy for PRs) | Stage 2+ adoption signals | `git log --merges --since="{lookback_date}" --format="%H %an %s %b"` |
| Commit history on AI config files | Learning signal assessment | `git log --follow -- {config_file}` |
| Language stats | Language detection for bonuses | API: `curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/{owner}/{repo}/languages` |
| PR details (authors, reviews) | Stage 2+ detection, min viability | API: `curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/{owner}/{repo}/pulls?state=closed&sort=updated&per_page=30` |
| Branch protection rules | Minimum viability check | API: `curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/{owner}/{repo}/branches/{branch}/protection` |
| Issues | Delivery dimension signals | API: `curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/repos/{owner}/{repo}/issues?state=all&sort=updated&per_page=30` |
| GitHub Projects | Delivery dimension | API (GraphQL): `projectsV2` query |

**Priority: git first, API second.** Most scoring signals (file tree, configs, workflows, commit history) come from the cloned repo. API is needed only for PRs, issues, branch protection, and language stats.

**If a repo is inaccessible** (clone fails AND API returns 403/404), score all dimensions as N/A, exclude from aggregates, and note in the report.

**Cleanup:** Remove cloned repos from `/tmp/scan/` after scanning.

**Lookback window:** AI activity signals (PRs, commits, issues) since the previous snapshot date. Config files and workflows as of the current snapshot.

### Step 3: Score Readiness (R1-R4)

Follow `readiness-scoring.md` exactly:

1. Detect primary language from GitHub language stats
2. Score each R1 signal using the metric-to-score mapping tables
3. Apply language-specific bonuses (capped at +15 per pillar)
4. Repeat for R2, R3, R4
5. Apply cross-pillar constraints (no tests → cap at 50; no types → cap R2 at 50)
6. Compute composite: `Readiness = R1 * 0.30 + R2 * 0.30 + R3 * 0.25 + R4 * 0.15`

### Step 4: Score Adoption (7 Dimensions)

Follow `adoption-scoring.md` exactly:

1. For each dimension, walk the numbered decision tree
2. Check Condition A (practice active) and Condition B (AI config covers dimension)
3. If both met → Stage 1+. Determine stage by checking Stage 2, 3, 4 signals.
4. Assign sub-level (Low/Mid/High) using the sub-level determination guidelines
5. Check learning signals (static/evolving/self-improving)
6. Apply cross-pillar constraints (single tool cap, stale config penalty)
7. Map to 0-100 using the stage-to-score table
8. Compute composite: weighted average with dimension weights

### Step 5: Check Minimum Viability Thresholds

Check all 7 thresholds for every repo (see adoption-scoring.md Section 14):
- CI/CD, dependency scanning, security policy, test automation
- Branch protection, PR review enforcement, issue tracking

Flag unmet thresholds in `minimum_viability_risks`.

### Step 6: Determine Quadrant

```
Quadrant boundaries:
  Traditional:        Readiness < 45,  Adoption < 45
  Fertile Ground:     Readiness >= 45, Adoption < 45
  Risky Acceleration: Readiness < 45,  Adoption >= 45
  AI-Native:          Readiness >= 45, Adoption >= 45

Quadrant sub-level:
  Low:  dominant axis score 45-60
  Mid:  dominant axis score 61-75
  High: dominant axis score 76-100
```

### Step 7: Generate Next Steps

For each repo, determine the **top 3 actions** ordered by impact-to-effort ratio:

1. **Identify candidate actions:** For each dimension below its potential, determine what specific action would advance it.
2. **Estimate effort:** Low = <1 day (config change, enable tool). Medium = 1-5 days (workflow setup, bot integration). High = 5+ days (pipeline redesign, org-wide rollout).
3. **Calculate impact:** For each action, determine which dimensions advance (from stage·sub → to stage·sub) and compute the Adoption composite change.
4. **Rank by impact/effort:** Highest ratio first.
5. **Select top 3.**

Each Next Step must include:
- Concrete action description
- Effort level (Low / Medium / High)
- Impact: which dimensions advance, from→to, and Adoption composite change

### Step 8: Compute Delta from Previous Scan

If a previous snapshot exists:
- Compare Readiness scores (pillar-level and composite)
- Compare Adoption stages and sub-levels per dimension
- Compare quadrant placement
- Summarize: "Readiness +3 (R2 improved), Code Quality Stage 0→1, Adoption 5→18"

If no previous snapshot: "First v3 assessment"

### Step 9: Write Per-Repo Results

For each repo, produce:

1. **Human-readable report** — the box format from model-spec.md Section 8.1
2. **Machine-readable JSON** — matching the schema in model-spec.md Section 9

Write JSON to: `scans/ai-augmentation/results/YYYY-MM.json`

**Never overwrite previous snapshots.** Each month gets its own file.

### Step 10: Generate Org-Level Summary

After all repos are scored, produce the org-level summary (model-spec.md Section 8.2):

- Quadrant distribution
- Portfolio view (all repos ranked by Readiness and Adoption)
- Adoption by dimension (how many repos at each stage)
- Trend vs previous scan
- Top 3 org-level actions (aggregated from per-repo Next Steps — most common actions)
- Risk flags (Risky Acceleration repos, static learning 3+ months)
- Headline insight (1-2 sentence summary)

### Step 11: Human Review

**Show all results to the human operator before writing to disk or publishing.**

Present:
1. Per-repo reports (box format)
2. Org-level summary
3. Any anomalies, edge cases, or judgment calls made during scoring
4. Proposed Next Steps

Wait for approval before proceeding.

### Step 12: Publish to Notion (on approval)

On human approval:
1. Look up page IDs from `notion/page-registry.yaml`
2. Use the `skills/publish-to-notion/` skill
3. Update Notion display pages with current results
4. Notion is the presentation layer — GitHub JSON is the source of truth

---

## Per-Repo Report Template

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  {org}/{repo-name}                                     {language} {pct}%   ║
║  Quadrant: {quadrant} — {sub-level}                                        ║
║  Readiness {score} | Adoption {score}                                      ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  AI READINESS ({score}/100)             AI ADOPTION                        ║
║  ─────────────────────────              ──────────────────────────────────  ║
║  R1 Structural Clarity  {nn} {bar}      Code Quality    Stage {n} · {sl}   ║
║  R2 Semantic Density    {nn} {bar}      Security        Stage {n} · {sl}   ║
║  R3 Verification Infra  {nn} {bar}      Testing         Stage {n} · {sl}   ║
║  R4 Dev Ergonomics      {nn} {bar}      Release         Stage {n} · {sl}   ║
║                                         Ops/Monitoring  Stage {n} · {sl}   ║
║                                         Delivery        Stage {n} · {sl}   ║
║                                         ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌  ║
║                                         AI Practices    Stage {n} · {sl}   ║
║                                         learning: {static|evolving|...}    ║
║                                                                            ║
║  {Flags — if any}                                                          ║
║                                                                            ║
║  Insight: {1-2 sentence narrative}                                         ║
║                                                                            ║
║  NEXT STEPS (top 3, ordered by impact)                                     ║
║  ─────────────────────────────────────                                     ║
║  1. {action}                                                               ║
║     Effort: {Low|Medium|High}                                              ║
║     Impact: {dimension} Stage {n}·{sl} → {n}·{sl}                         ║
║             Adoption: {old} → {new}                                        ║
║                                                                            ║
║  2. {action}                                                               ║
║     Effort: {Low|Medium|High}                                              ║
║     Impact: {dimension} Stage {n}·{sl} → {n}·{sl}                         ║
║             Adoption: {old} → {new}                                        ║
║                                                                            ║
║  3. {action}                                                               ║
║     Effort: {Low|Medium|High}                                              ║
║     Impact: {dimension} Stage {n}·{sl} → {n}·{sl}                         ║
║             Adoption: {old} → {new}                                        ║
║                                                                            ║
║  Delta: {change since previous scan, or "First assessment"}                ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

## Org-Level Summary Template

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  {Org Name} AI Augmentation — {Month Year} ({n} repos assessed)            ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  QUADRANT DISTRIBUTION                                                     ║
║  ─────────────────────                                                     ║
║  Fertile Ground — High:  {n}  ({repo names})                               ║
║  Fertile Ground — Mid:   {n}  ({repo names})                               ║
║  Traditional:            {n}  ({repo names})                               ║
║  Risky Acceleration:     {n}  ({repo names})                               ║
║  AI-Native:              {n}  ({repo names})                               ║
║                                                                            ║
║                  Avg Readiness: {nn}    Avg Adoption: {nn}                 ║
║                                                                            ║
║  PORTFOLIO VIEW                                                            ║
║                            Readiness              Adoption                 ║
║  {repo-1}       {bar}  {nn}    {bar}  {nn}                                ║
║  {repo-2}       {bar}  {nn}    {bar}  {nn}                                ║
║  ...                                                                       ║
║                                                                            ║
║  ADOPTION BY DIMENSION                                                     ║
║  ─────────────────────                                                     ║
║                     Stage 0    Stage 1    Stage 2    Stage 3    Stage 4    ║
║  Code Quality       {n}        {n}        {n}        {n}        {n}       ║
║  Security           {n}        {n}        {n}        {n}        {n}       ║
║  Testing            {n}        {n}        {n}        {n}        {n}       ║
║  Release            {n}        {n}        {n}        {n}        {n}       ║
║  Ops/Monitoring     {n}        {n}        {n}        {n}        {n}       ║
║  Delivery           {n}        {n}        {n}        {n}        {n}       ║
║  AI Practices       {n}        {n}        {n}        {n}        {n}       ║
║                                                                            ║
║  TREND (vs previous scan)                                                  ║
║  ─────────────────────────                                                 ║
║  Avg Readiness: {nn} → {nn} ({+/-n})                                      ║
║  Avg Adoption:  {nn} → {nn} ({+/-n})                                      ║
║  Stage advances: {n} dimensions across {n} repos                           ║
║                                                                            ║
║  TOP ORG-LEVEL ACTIONS                                                     ║
║  ─────────────────────                                                     ║
║  1. {action} — affects {n} repos                                           ║
║  2. {action} — affects {n} repos                                           ║
║  3. {action} — affects {n} repos                                           ║
║                                                                            ║
║  RISK FLAGS                                                                ║
║  ──────────                                                                ║
║  {flags}                                                                   ║
║                                                                            ║
║  HEADLINE: {1-2 sentence org-level narrative}                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

## JSON Output Schema

Each monthly snapshot file (`results/YYYY-MM.json`) contains:

```json
{
  "snapshot_date": "2026-04-01",
  "model_version": "v3.0",
  "repos": [
    {
      "repo": "org/repo-name",
      "languages": [{"language": "Haskell", "percentage": 100}],
      "readiness": {
        "composite": 90,
        "pillars": {
          "structural_clarity":   {"score": 93, "evidence": "..."},
          "semantic_density":     {"score": 92, "evidence": "..."},
          "verification_infra":   {"score": 85, "evidence": "..."},
          "developer_ergonomics": {"score": 89, "evidence": "..."}
        }
      },
      "adoption": {
        "composite": 18,
        "dimensions": {
          "code_quality":   {"stage": 1, "sub_level": "mid",  "mapped_score": 27, "learning": "static", "confidence": "high", "evidence": "..."},
          "security":       {"stage": 0, "sub_level": "mid",  "mapped_score": 7,  "learning": null,     "confidence": "medium", "evidence": "..."},
          "testing":        {"stage": 1, "sub_level": "low",  "mapped_score": 20, "learning": "static", "confidence": "high", "evidence": "..."},
          "release":        {"stage": 1, "sub_level": "low",  "mapped_score": 20, "learning": "static", "confidence": "high", "evidence": "..."},
          "ops_monitoring":  {"stage": 0, "sub_level": "low", "mapped_score": 0,  "learning": null,     "confidence": "high", "evidence": "..."},
          "delivery":       {"stage": 1, "sub_level": "low",  "mapped_score": 20, "learning": "static", "confidence": "medium", "evidence": "..."},
          "ai_practices":   {"stage": 1, "sub_level": "low",  "mapped_score": 20, "learning": "static", "confidence": "high", "evidence": "..."}
        }
      },
      "quadrant": "Fertile Ground",
      "quadrant_sub_level": "High",
      "next_steps": [
        {
          "priority": 1,
          "action": "...",
          "effort": "low",
          "impact": [{"dimension": "security", "from_stage": 0, "from_sub": "mid", "to_stage": 1, "to_sub": "low"}],
          "adoption_change": {"from": 18, "to": 20}
        }
      ],
      "flags": [],
      "minimum_viability_risks": [],
      "anomalies": [],
      "delta_from_previous": "First v3 assessment"
    }
  ],
  "org_summary": {
    "total_repos": 29,
    "assessed": 27,
    "inaccessible": 2,
    "avg_readiness": 72,
    "avg_adoption": 8,
    "quadrant_distribution": {
      "fertile_ground_high": 5,
      "fertile_ground_mid": 8,
      "fertile_ground_low": 3,
      "traditional": 11,
      "risky_acceleration": 0,
      "ai_native": 0
    },
    "top_actions": [
      {"action": "Add CLAUDE.md", "affected_repos": 20},
      {"action": "Enable dependency scanning", "affected_repos": 12},
      {"action": "Add AI review bot", "affected_repos": 27}
    ],
    "risk_flags": [],
    "headline": "..."
  }
}
```

---

## Validation Checklist (Post-Scan)

Before presenting results to the human operator, verify:

- [ ] Every repo in `config.yaml` is accounted for (scored or marked inaccessible)
- [ ] No dimension scores Stage 2+ without Stage 1 foundation
- [ ] Sub-levels are consistent with learning signals (static ≠ High)
- [ ] Adoption composite matches manual calculation (spot-check 2-3 repos)
- [ ] Readiness composite matches R1-R4 weighted average
- [ ] Quadrant assignment matches Readiness × Adoption coordinates
- [ ] Every dimension has evidence cited (no empty evidence fields)
- [ ] Next Steps are ordered by impact/effort and show specific dimension advancement
- [ ] Minimum viability risks are flagged for every repo
- [ ] JSON output validates against the schema above
- [ ] No secrets, tokens, or sensitive URLs in output
- [ ] Delta from previous scan is computed (if previous exists)
