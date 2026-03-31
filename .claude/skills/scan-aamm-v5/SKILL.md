---
name: scan-aamm-v5
description: Run AAMM v5 scan — AI agent assesses repo readiness (5 pillars) and adoption (5 zones) via rubric + depth, produces ROI-prioritized recommendations with mandatory adversarial review.
---

# AAMM v5 Scan

## Input

Target repo is specified either as:
- **Single repo:** User provides `owner/repo` directly
- **From config:** User says "scan all" or "scan next" — read `models/config.yaml` for the tracked repo list. Each entry has `repo`, `language` (= ecosystem), and `project`.

Set variables from input:
```
OWNER=<org name from config or user input>
REPO=<repo name from config or user input>
ECOSYSTEM=<language field from config, lowercased: haskell|typescript|rust|python|lean|nix|shell>
```

## Prerequisites

```bash
source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null
if [ -z "$GITHUB_TOKEN" ]; then
  echo "FATAL: GITHUB_TOKEN not set. Cannot proceed."
  # STOP — do not continue
fi
# Verify token works
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/user)
if [ "$HTTP_CODE" != "200" ]; then
  echo "FATAL: GITHUB_TOKEN invalid (HTTP $HTTP_CODE). Cannot proceed."
  # STOP — do not continue
fi
```

## Step 1: Load Context

Read these files (agent context, not bash):
1. `models/ai-augmentation-maturity/scoring-model.md` — rubric criteria, scoring rules, confidence model, output format
2. `models/ai-augmentation-maturity/knowledge-base/ecosystems/$ECOSYSTEM.md` — KB patterns for this ecosystem
3. `models/ai-augmentation-maturity/knowledge-base/cross-cutting.md` — universal patterns
4. `models/ai-augmentation-maturity/knowledge-base/anti-patterns.md` — what to watch for
5. `scans/ai-augmentation/config.yaml` — scan config, overrides
6. Previous results in `scans/ai-augmentation/results/` — for evolution

Read overrides for this repo from config.yaml `scan.repos[].overrides` if any.

## Step 2: Collect Repo Data

```bash
TMPDIR="/tmp/aamm-v5-$OWNER-$REPO"
mkdir -p "$TMPDIR"

# Repo metadata (language, topics, description)
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO" > "$TMPDIR/metadata.json"

# Check access
if grep -q '"message": "Not Found"' "$TMPDIR/metadata.json" 2>/dev/null; then
  echo "FATAL: Repo $OWNER/$REPO not accessible (404). Check token scope."
  # STOP — report failure, no assessment
fi

# Default branch
DEFAULT_BRANCH=$(jq -r '.default_branch' "$TMPDIR/metadata.json")

# Repo tree (recursive)
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/git/trees/$DEFAULT_BRANCH?recursive=1" \
  > "$TMPDIR/tree.json"

# Recent merged PRs (last 30)
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/pulls?state=closed&sort=updated&direction=desc&per_page=30" \
  > "$TMPDIR/prs.json"

# Recent commits (last 100)
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/commits?sha=$DEFAULT_BRANCH&per_page=100" \
  > "$TMPDIR/commits.json"
```

Then read key file contents via the Contents API (agent reads these, not bash):
- Always: README.md, CI workflow files (all .github/workflows/*.yml)
- If present (check tree.json): CLAUDE.md, CONTRIBUTING.md, CODEOWNERS,
  ARCHITECTURE.md, .aiignore, .github/PULL_REQUEST_TEMPLATE.md,
  .github/ISSUE_TEMPLATE/, package manifests, tsconfig.json, ADRs
- Sample: 5-10 source files (for C2 doc comments, across packages for monorepos),
  5-10 test files (for SN depth — test quality assessment)

## Step 3: Assess — Rubric + Depth

Read `models/ai-augmentation-maturity/scoring-model.md` which contains all rubric tables,
scoring rules, confidence model, and output format.

Execute Phase 1 (rubric) then Phase 2 (depth) for each pillar and zone.
Produce the assessment JSON and draft 5-7 recommendations.

**Override handling:** If config.yaml has overrides for this repo:
- Evaluate the criterion independently (agent's own assessment)
- Record both: agent's evaluation AND the override
- If they conflict, flag in the report
- Override carries MEDIUM confidence
- Populate `overrides_applied` in assessment.json

## Step 4: Adversarial Review — MANDATORY

Dispatch a **separate Agent subagent** with the adversarial prompt.

**Invocation (Claude Code Agent tool):**
```
Agent tool call:
  prompt: [contents of prompts/adversarial-system.md]
         + "ASSESSMENT TO REVIEW:" + [full assessment JSON]
         + "REPO DATA:" + [key file contents that scanner read]
  description: "Adversarial review of AAMM scan for {OWNER}/{REPO}"
```

The adversarial agent:
1. Spot-checks 3-5 rubric criteria (re-reads files independently)
2. Spot-checks 3-5 depth findings (re-reads cited files)
3. Challenges each recommendation
4. Returns: rubric corrections + approved/rejected recommendations with reasons

Apply corrections to the assessment before generating the report.

## Step 5: Generate Report

Generate 3 output files:

### report.md (team-facing)
Structure: Summary → Recommendations (3-5) → Risk Flags → Skill Tree →
Findings → Cross-repo Insights → Evolution → Evidence Log.
See spec Section 5 for details.

Quadrant derivation:
```
Readiness: ≥4 pillars at Practiced/Mastered = High; 2-3 = Medium; ≤1 = Low
Adoption:  ≥3 zones at Exploring+ (with ≥1 at Practiced+) = High; 1-2 = Medium; 0 = Low

Quadrant grid:
  High readiness + Low adoption    = Fertile Ground
  High readiness + Medium adoption = Growing
  High readiness + High adoption   = AI-Native
  Medium readiness + Low adoption  = Traditional+
  Medium readiness + Medium        = Emerging
  Medium readiness + High          = Risky Acceleration
  Low readiness + Low              = Traditional
  Low readiness + Medium/High      = Risky Acceleration
```

Cross-pillar caveat: note that pillar difficulty varies (Structure criteria
are common; Purpose criteria are rare across the industry).

### assessment.json (structured data)
Follow `schema/assessment-v5.schema.json`. Include all rubric evaluations,
depth findings, recommendations with adversarial status, KB nominations.

### detailed-log.md (audit trail)
Everything: files read with excerpts, rubric reasoning per criterion,
all draft recommendations including rejected, adversarial dialogue.

## Step 6: Save Results

```bash
DATE=$(date +%Y-%m-%d)
RESULT_DIR="scans/ai-augmentation/results/$DATE/$OWNER--$REPO"
mkdir -p "$RESULT_DIR"
# Write report.md, assessment.json, detailed-log.md to $RESULT_DIR
```

## Step 7: Propose KB Updates

If new patterns or anti-patterns discovered, write proposed entries
(status: proposed) to `scans/ai-augmentation/results/$DATE/kb-updates.md`.
CoE lead reviews and merges into `models/ai-augmentation-maturity/knowledge-base/` files.

## Failure Handling

| Failure | Detection | Action |
|---------|-----------|--------|
| Repo inaccessible | 404 from metadata API | STOP. Write failure report (reason only). No assessment. |
| Rate limited | 429 from any API call | Wait 60s, retry. After 3 retries, write partial report with "incomplete" flag. |
| Context window exceeded | Agent can't fit all data | Skip depth phase for remaining pillars. Flag "partial depth" in report. |
| Adversarial rejects ALL recs | 0 approved | Include all rejected recs with reasons. Flag for CoE lead manual review. |
| Unknown language | Ecosystem not in kb/ | Use cross-cutting rubric only. Mark ecosystem-specific criteria as N/A. |
| Hallucination caught | Adversarial spot-check fails | Remove finding. Downgrade confidence. Log incident in detailed-log. |

## Important

- Never print, log, or display $GITHUB_TOKEN
- Adversarial review is MANDATORY — never present results without Step 4
- No confirmations during scans — run fully autonomously
- Mastered nominations require CoE lead confirmation
- Never publish to Notion without human approval
