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

# Step 2: Verify token exists (DO NOT print/echo the value)
if [ -z "$GITHUB_TOKEN" ]; then
  echo "FATAL: GITHUB_TOKEN not set. Cannot proceed."
  echo "Set it in ~/.zshrc and re-source, or export it manually."
  # STOP HERE — do not continue
fi

# Step 3: Verify token works (test call, discard response body)
curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/user
# Must return 200. Any other code → STOP and ask the operator.
```

**If any step fails, STOP and ask the human operator.** Do not proceed without a working token. Do not attempt partial scans. Do not fall back to unauthenticated API calls.

### Secret Protection Rules

These rules apply to `$GITHUB_TOKEN` and any other credential used during scanning:

1. **Never print, echo, or log the token value.** Not in shell output, not in debug messages, not in error messages. Use `$GITHUB_TOKEN` as an env var reference only — never interpolate it into strings that get displayed.
2. **Never save the token to any file.** Not in JSON results, not in evidence fields, not in learnings, not in commit messages, not in temp files.
3. **Never include the token in git operations.** Do not embed it in clone URLs (e.g., `https://{token}@github.com/...`). Use the env var form: `git clone` will pick up credentials from the git credential helper or from the `GITHUB_TOKEN` env var automatically.
4. **Scrub API responses before storing.** If any API response contains tokens, auth headers, or session data, strip them before writing to results JSON.
5. **Before every commit, scan staged changes** for token patterns: `git diff --cached | grep -iE '(ghp_|github_pat_|gho_|Bearer |token|secret|password|api[_-]?key)'`. If anything matches, unstage and fix before committing.
6. **curl calls use env var expansion**, which keeps the token out of `/proc` and shell history: `curl -s -H "Authorization: Bearer $GITHUB_TOKEN"`. Never use `-u` with a literal token string.

### Data Collection Strategy: API-First, git clone for Deep History

Use the GitHub REST API via `curl` for structured data. Use `git clone` only when deep commit history analysis is needed (learning signal assessment).

**Why API-first works:**
- 29 repos × ~12 calls each ≈ 350 calls — 7% of the 5,000/hour authenticated limit
- API returns structured JSON (PRs with authors, file trees, language stats) — no parsing needed
- No disk overhead from cloning 29 repos
- `git clone` reserved for the rare case where `git log --follow` on config files is needed

**Rate limit awareness:** After the pre-flight check, query rate limit status:
```bash
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/rate_limit \
  | jq '.rate.remaining'
# If < 500 remaining, warn the operator before proceeding
```

---

## Scan Execution Flow

### Step 1: Load Repo List

Read the tracked repos from `models/config.yaml`. This is the master list — do not duplicate it in this file.

For each repo, note: org, repo name, project, primary language.

### Step 2: For Each Repo — Collect Data

**API-first for structured data. `git clone` only for deep history.**

All `curl` calls use the pattern: `curl -s -H "Authorization: Bearer $GITHUB_TOKEN"`. Never inline the token literally.

#### Phase A: API calls (~8-12 per repo)

| Data | Purpose | API Call | Est. Calls |
|------|---------|----------|------------|
| File tree | Readiness scoring, AI config detection | `GET /repos/{owner}/{repo}/git/trees/{branch}?recursive=1` | 1 |
| Language stats | Language detection for Readiness bonuses | `GET /repos/{owner}/{repo}/languages` | 1 |
| README.md | R2 scoring | `GET /repos/{owner}/{repo}/contents/README.md` | 1 |
| AI config file contents | Adoption Stage 1 quality check | `GET /repos/{owner}/{repo}/contents/{path}` per config file found | 1-3 |
| Workflow YAML files | Condition A checks, Stage 3 detection | `GET /repos/{owner}/{repo}/contents/.github/workflows` then each file | 2-4 |
| Merged PRs (since lookback) | Stage 2+ adoption, AI bot detection | `GET /repos/{owner}/{repo}/pulls?state=closed&sort=updated&per_page=50` | 1 |
| PR reviews (sample) | Minimum viability check | `GET /repos/{owner}/{repo}/pulls/{number}/reviews` for 5 recent PRs | 1-5 |
| Recent issues | Delivery dimension signals | `GET /repos/{owner}/{repo}/issues?state=all&sort=updated&per_page=30` | 1 |
| Branch protection | Minimum viability check | `GET /repos/{owner}/{repo}/branches/{branch}/protection` (may 404) | 1 |
| Commits on AI config files | Learning signal assessment | `GET /repos/{owner}/{repo}/commits?path={file}&per_page=10` per config | 1-3 |

**Total: ~350 calls for 29 repos (7% of 5,000/hour limit).**

#### Phase B: `git clone` (only when needed)

If learning signal assessment needs deeper commit history than the API provides (e.g., `git log --follow` to track renames, or diff analysis on config evolution):

```bash
# Shallow clone into temp directory — DO NOT embed token in URL
git clone --depth 50 "https://github.com/{owner}/{repo}.git" /tmp/scan/{repo}
cd /tmp/scan/{repo}

# Inspect config evolution
git log --follow --format="%H %ai %s" -- CLAUDE.md

# Cleanup after inspection
rm -rf /tmp/scan/{repo}
```

**Note:** `git clone` of public repos works without authentication. For private repos, git uses the credential helper or `$GITHUB_TOKEN` from the environment — never embed the token in the clone URL.

#### Error Handling

- **403/404 on a repo:** Score all dimensions as N/A, exclude from aggregates, note in report
- **403 on branch protection:** Note "branch protection data unavailable (insufficient permissions)" — this is common without admin access, not a blocker
- **Rate limit approaching:** Check `X-RateLimit-Remaining` header on each response. If < 200, pause and warn operator

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

For each repo, determine the **top 3 actions** ordered by impact-to-effort ratio.

#### 7.1 Identify Candidate Actions

For each dimension below its potential, determine what specific action would advance it. **Recommendations must be repo-specific and language-aware:**

- Reference actual file names, package names, and module structures from the collected data
- Explain WHY this action matters for AI effectiveness on THIS codebase, not just that it advances a score
- Connect the action to concrete problems an AI agent would face today without it
- Tailor to the language ecosystem (Haskell recommendations differ from Rust differ from TypeScript)

**BAD recommendation:** "Add CLAUDE.md covering architecture and coding conventions"
→ This is generic, incentivizes checkbox behavior, and doesn't explain what makes this repo special.

**GOOD recommendation:** "Document cardano-ledger's era-based validation pipeline: how `eras/conway/impl/` relates to `libs/cardano-ledger-core/`, what the CDDL specs in `eras/*/cddl-spec/` enforce, and how property-based tests in `*-test` packages verify ledger rules. Today an AI modifying a ledger rule has no way to know it must also update the CDDL spec and the property test."
→ This is specific, explains the gap, and connects to real AI effectiveness.

#### 7.2 Recommendation Quality Rules

Every recommendation MUST pass these checks:

1. **Specificity test:** Does it mention actual files, packages, or patterns from THIS repo? If you could copy-paste it to a different repo and it still makes sense, it's too generic.
2. **AI effectiveness test:** Would implementing this actually help an AI agent produce better output? Or is it just adding a file for a score? If a team could implement it as an empty gesture and still "pass", the recommendation is wrong.
3. **Language relevance test:** Does it reflect this language ecosystem's conventions and tooling? A Haskell repo needs different AI context than a Rust repo.
4. **Effort realism test:** Is the effort estimate honest? "Low" means a developer can do it in under a day with clear guidance. Don't understate effort to inflate the impact/effort ratio.
5. **Impact honesty test:** Does the projected Stage/Sub-level change reflect real capability improvement, or just a scoring technicality? If the repo wouldn't measurably benefit from the change, don't recommend it.

#### 7.3 Score Impact

For each candidate that passes quality checks:

1. **Estimate effort:** Low = <1 day (focused, clear scope). Medium = 1-5 days (integration work, tooling setup). High = 5+ days (architecture changes, org-wide coordination).
2. **Calculate impact:** Which dimensions advance (from Stage·Sub → to Stage·Sub), and the Adoption composite change.
3. **Rank by impact/effort ratio.** Select top 3.

#### 7.4 Output Format

Each Next Step must include:
- **Action:** Concrete, repo-specific description (what to do AND why it matters)
- **Effort:** Low / Medium / High
- **Impact:** Which dimensions advance, from→to, and Adoption composite change
- **Why this matters:** 1 sentence connecting the action to AI effectiveness on this codebase

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

### Step 11: Automated Validation (MANDATORY before presenting results)

Before showing results to the human operator, run this validation pass. **Do not skip this step.** If any check fails, fix the issue before proceeding.

#### 11.1 Score Consistency Checks

```
For each repo:
  □ Readiness composite matches R1*0.30 + R2*0.30 + R3*0.25 + R4*0.15 (±1 rounding)
  □ Adoption composite matches weighted sum of mapped scores (±1 rounding)
  □ No dimension at Stage 2+ without Stage 1 foundation
  □ Static learning signal → sub-level is not High
  □ Single AI tool → AI Practices sub-level is not above Mid
  □ Stale config (>180 days) → sub-level is not above Low
  □ Quadrant matches Readiness × Adoption coordinates
  □ Every dimension has non-empty evidence field
```

#### 11.2 Recommendation Validation

For EACH of the 3 Next Steps per repo, verify:

```
  □ SPECIFICITY: Does the recommendation mention actual file names, package
    names, or architectural patterns from THIS repo? Could you NOT copy-paste
    it to a different repo unchanged?
    FAIL example: "Add CLAUDE.md covering architecture and coding conventions"
    PASS example: "Document the 28-package era-based architecture in CLAUDE.md,
    explaining how eras/conway/impl/ depends on libs/cardano-ledger-core/"

  □ AI EFFECTIVENESS: Would this concretely improve AI agent output on this
    repo? What specific task would an AI do better after this change?
    FAIL: "Add AI config" (vague, no connection to outcomes)
    PASS: "Enable AI to generate correct cross-package changes by documenting
    which test packages verify which implementation packages"

  □ LANGUAGE RELEVANCE: Does the recommendation reflect this language's
    ecosystem? Haskell repos need different AI context than Rust or TypeScript.
    FAIL: Generic "add linting" for a Haskell repo that already has hlint+fourmolu
    PASS: "Document the QuickCheck property patterns used in ledger-test so AI
    can generate property-based tests matching the existing style"

  □ EFFORT HONESTY: Is the effort estimate realistic? Would a developer who
    knows this codebase agree with the time estimate?

  □ IMPACT HONESTY: Does the projected score change reflect genuine capability
    improvement, or just a scoring technicality? If someone implemented this
    recommendation minimally (checkbox style), would it STILL improve AI
    effectiveness?

  □ NOT REDUNDANT: Is this recommendation materially different from the other
    2 recommendations for this repo? No overlapping actions.
```

**If a recommendation fails any check, rewrite it.** Generic recommendations that could apply to any repo are always wrong.

#### 11.3 Cross-Repo Validation

```
  □ Repos with similar profiles have comparable scores (two Haskell repos
    with similar structure shouldn't differ by >15 on Readiness without
    clear explanation)
  □ Org-level top actions are genuinely the highest-leverage moves, not
    just the most repeated generic action
  □ Risk flags are actionable (specific repo, specific risk, specific fix)
```

#### 11.4 Validation Output

Record the validation results in the JSON output under a `validation` field:
```json
{
  "validation": {
    "score_consistency": "pass",
    "recommendation_quality": "pass — all 15 recommendations verified repo-specific",
    "cross_repo_consistency": "pass",
    "issues_found_and_fixed": ["mithril: rewrote Step 1 from generic to specific"]
  }
}
```

### Step 12: Human Review

**Show all results to the human operator before writing to disk or publishing.**

Present:
1. Per-repo reports (box format)
2. Org-level summary
3. Validation results (Step 11 output)
4. Any anomalies, edge cases, or judgment calls made during scoring
5. Proposed Next Steps — highlight which recommendations were rewritten during validation

Wait for approval before proceeding.

### Step 13: Publish to Notion (on approval)

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
