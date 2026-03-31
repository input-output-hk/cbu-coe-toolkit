---
name: scan-aamm-v6
description: Run AAMM v6 scan — AI agent derives repo-specific AI opportunities from KB + repo data, assesses adoption/readiness/risk per opportunity, produces ROI-ordered recommendations with two-stage adversarial review.
---

# AAMM v6 Scan

## Input

Target repo is specified either as:
- **Single repo:** User provides `owner/repo` directly
- **From config:** User says "scan all" or "scan next" — read `models/config.yaml` for the tracked repo list

Set variables from input:
```
OWNER=<org name from config or user input>
REPO=<repo name from config or user input>
ECOSYSTEM=<language field from config, lowercased: haskell|typescript|rust|python|lean|nix|shell>
SCAN_TYPE=<scoring (default) | learning>
```

## Prerequisites

```bash
source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null

# For private repos only — public repos don't need auth
if [ -n "$GITHUB_TOKEN" ]; then
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    https://api.github.com/user)
  if [ "$HTTP_CODE" != "200" ]; then
    echo "WARNING: GITHUB_TOKEN invalid (HTTP $HTTP_CODE). Proceeding without auth — private repos will fail."
  fi
fi
```

## Step 1: Load Context

Read these files (agent context, not bash):
1. `models/ai-augmentation-maturity/scoring-model.md` — **operational manual, follow step by step**
2. `models/ai-augmentation-maturity/knowledge-base/ecosystems/$ECOSYSTEM.md` — opportunity patterns + readiness criteria for this ecosystem
3. `models/ai-augmentation-maturity/knowledge-base/cross-cutting.md` — universal patterns
4. `models/ai-augmentation-maturity/knowledge-base/anti-patterns.md` — what to watch for
5. `models/config.yaml` — repo metadata (ecosystem, project)

**If KB file for ecosystem doesn't exist:** Use cross-cutting patterns only. Mark scan as: "Limited KB coverage for $ECOSYSTEM — learning scan recommended before scoring."

## Step 2: Collect Repo Data

```bash
TMPDIR="/tmp/aamm-v6-$OWNER-$REPO"
mkdir -p "$TMPDIR"

# Auth header (empty if no token)
AUTH_HEADER=""
if [ -n "$GITHUB_TOKEN" ]; then
  AUTH_HEADER="Authorization: Bearer $GITHUB_TOKEN"
fi

# Repo metadata
curl -s ${AUTH_HEADER:+-H "$AUTH_HEADER"} \
  "https://api.github.com/repos/$OWNER/$REPO" > "$TMPDIR/metadata.json"

# Check access
if grep -q '"message": "Not Found"' "$TMPDIR/metadata.json" 2>/dev/null; then
  echo "FATAL: Repo $OWNER/$REPO not accessible (404). Check token scope for private repos."
  # STOP — write failure report, no assessment
fi

# Default branch
DEFAULT_BRANCH=$(jq -r '.default_branch' "$TMPDIR/metadata.json")

# Repo tree (recursive)
curl -s ${AUTH_HEADER:+-H "$AUTH_HEADER"} \
  "https://api.github.com/repos/$OWNER/$REPO/git/trees/$DEFAULT_BRANCH?recursive=1" \
  > "$TMPDIR/tree.json"

# Recent commits (last 100)
curl -s ${AUTH_HEADER:+-H "$AUTH_HEADER"} \
  "https://api.github.com/repos/$OWNER/$REPO/commits?sha=$DEFAULT_BRANCH&per_page=100" \
  > "$TMPDIR/commits.json"

# Recent merged PRs (last 30)
curl -s ${AUTH_HEADER:+-H "$AUTH_HEADER"} \
  "https://api.github.com/repos/$OWNER/$REPO/pulls?state=closed&sort=updated&direction=desc&per_page=30" \
  > "$TMPDIR/prs.json"
```

Then read key file contents via the Contents API (agent reads these, not bash):

**Always read (if present in tree):**
- README.md
- All CI workflow files (.github/workflows/*.yml)
- Package manifests (cabal.project, package.json, Cargo.toml, pyproject.toml, etc.)

**Read if present:**
- CLAUDE.md, AGENTS.md, .cursorrules, .mcp.json, copilot-instructions.md
- CONTRIBUTING.md, CODEOWNERS
- ARCHITECTURE.md
- .aiignore
- .github/PULL_REQUEST_TEMPLATE.md
- tsconfig.json (TypeScript repos)
- ADR files (first 5 from docs/decisions/ or adr/)

**Derive from collected data:**
- High-churn modules: count files changed per directory in last 100 commits, top 10
- AI attribution: scan commits for Co-authored-by trailers mentioning AI tools
- AI bot activity: scan PRs for bot authors (copilot[bot], coderabbit-ai[bot], etc.)
- Last commit date per directory (for staleness detection)

## Step 3: Branch by Scan Type

### If SCAN_TYPE = learning

Follow learning scan flow:
1. Match KB patterns against repo data (same as scoring Step 4)
2. For each match: produce a KB proposal entry with full evidence
3. Look for patterns NOT in KB — novel patterns observed in this repo
4. Write output to `kb-proposals.md` (see Output section)
5. **STOP** — no adversarial review, no adoption/readiness/risk assessment

### If SCAN_TYPE = scoring

Continue to Step 4.

## Step 4: Generate Opportunity Map

Follow `scoring-model.md` Section 2 exactly.

For each KB pattern:
1. Check `applies_when` conditions against repo data
2. If match: locate specific evidence, assess value/effort for this repo
3. Generate opportunity with all required fields (id, title, value, effort, roi_rank, evidence, kb_pattern, seen_in)

Also look for opportunities not covered by KB patterns (flag as `kb_pattern: null`).

Order all opportunities by ROI descending.

**Self-check:** For each opportunity, ask: "Would this appear identically on any repo in this ecosystem?" If yes → make it specific or drop it.

## Step 5: Adversarial Review — Stage A

Dispatch a **separate Agent subagent** with the Stage A adversarial prompt.

**Invocation (Claude Code Agent tool):**
```
Agent tool call:
  prompt: [contents of prompts/adversarial-stage-a.md]
         + "OPPORTUNITY MAP TO REVIEW:" + [full opportunity map as JSON]
         + "REPO DATA:" + [file tree JSON + key file contents + git history summary + CI config]
  description: "AAMM Stage A adversarial review for {OWNER}/{REPO}"
```

**What the adversarial agent receives:**
- The opportunity map (all opportunities with evidence)
- Repo data: file tree, key file contents, git history summary, CI config
- It does NOT receive the primary agent's reasoning or internal notes

**What the adversarial agent returns:**
1. Approved opportunity map (opportunities that passed all 4 tests)
2. Rejection summary (3-5 lines per rejected opportunity: what + why)

**Apply results:** Use the approved map for all downstream assessment. Record rejections in detailed-log.

**If Stage A rejects ALL opportunities:** Scan terminates early. Write report with: Data Collection summary + Stage A rejection summary + finding: "No repo-specific AI opportunities identified." No further assessment. The report is still official.

## Step 6: Component Assessment

Follow `scoring-model.md` Section 3 exactly.

For each **approved** opportunity:
- **Adoption State:** Active / Partial / Absent (Section 3.1)
- **Readiness per Use Case:** KB criteria → level (Section 3.2). If no KB criteria → "Not Assessable"
- **Flag:** Active + Undiscovered → Risky Acceleration

Across all opportunities:
- **Risk Surface:** per code path (Section 3.3)
- **Flag:** Ad-hoc AI Usage check (Section 3.4)

**This is Phase 1 (scan-from-zero).** Do NOT read previous scan results during this step.

## Step 7: Generate Recommendations

Follow `scoring-model.md` Section 4 exactly.

Derive recommendations from: opportunity × readiness gap × adoption state.
Order by ROI descending. Include recommended learning from KB per recommendation.

**Self-check** each recommendation against 3 questions (scoring-model.md Section 4).

## Step 8: Adversarial Review — Stage B

Dispatch a **separate Agent subagent** with the Stage B adversarial prompt.

**Invocation (Claude Code Agent tool):**
```
Agent tool call:
  prompt: [contents of prompts/adversarial-stage-b.md]
         + "RECOMMENDATIONS TO REVIEW:" + [full recommendations as JSON]
         + "ASSESSMENT CONTEXT:" + [opportunity map + adoption state + readiness + risk surface]
         + "REPO DATA:" + [key file contents relevant to recommendations]
  description: "AAMM Stage B adversarial review for {OWNER}/{REPO}"
```

**What the adversarial agent receives:**
- All recommendations with full fields
- Assessment context (opportunity map, adoption, readiness, risk surface)
- Relevant repo data for verification
- It does NOT receive the primary agent's reasoning

**Apply results:** Mark each recommendation as approved/rejected with reasons. Keep rejected recommendations in assessment.json with `adversarial_status: "rejected"`.

## Step 9: Generate Report — Phase 1 (Assessment Frozen)

Write `assessment.json` with all component outputs. This file is **immutable after this step**.

Follow the schema in `schema/assessment-v6.schema.json` and `scoring-model.md` Section 6.

## Step 10: Generate Report — Phase 2 (Delta Computation)

**Now** (and only now) read the previous `assessment.json` if it exists:
```bash
# Find most recent previous scan
PREV=$(ls -d scans/ai-augmentation/results/*/$(echo "$OWNER--$REPO") 2>/dev/null | sort -r | head -1)
```

If previous scan exists:
- Compare opportunity IDs: new / discontinued / persisted
- Compare readiness levels: changed / held
- Compare adoption states: changed / held
- Compare recommendation statuses: verified / unverified / not applicable
- If previous scan was v5 (`schema_version: "5.0"`): include v5 quadrant as historical context only, do NOT compute delta

Write Evolution section in `report.md`. Do NOT modify `assessment.json`.

## Step 11: Write Report Files

Write `report.md` following the section order in `scoring-model.md` Section 6:
1. Executive Summary (first 15 lines)
2. Opportunity Map
3. Risk Surface
4. Recommendations
5. Adoption State
6. Readiness per Use Case
7. Evolution
8. Evidence Log

Write `detailed-log.md` with full audit trail.

## Step 12: Save Results

```bash
DATE=$(date +%Y-%m-%d)
RESULT_DIR="scans/ai-augmentation/results/$DATE/$OWNER--$REPO"
mkdir -p "$RESULT_DIR"
# Write report.md, assessment.json, detailed-log.md to $RESULT_DIR
```

## Step 13: KB Update Proposals

If new patterns or readiness criteria were discovered during the scan:
- Write proposed entries to `scans/ai-augmentation/results/$DATE/kb-updates.md`
- Format: identical to KB entry format (YAML blocks in markdown)
- Each entry: `status: proposed`, includes `evidence_from_scan`
- CoE reviews and merges into `knowledge-base/` files

## Failure Handling

| Failure | Detection | Action |
|---------|-----------|--------|
| Repo inaccessible | 404 from metadata API | STOP. Write failure note (reason only). No assessment. |
| Rate limited | 429 from any API call | Wait 60s, retry. After 3 retries, write partial report with "incomplete" flag. |
| Context window pressure | Agent running low on context | Prioritize: Opportunity Map + Recommendations over detailed Risk Surface. Flag "partial assessment" in report. |
| Stage A rejects ALL | 0 approved opportunities | Write report with rejection summary only. Flag for CoE attention. Still official. |
| Stage B rejects ALL | 0 approved recommendations | Keep full report (opportunities, adoption, readiness, risk still valuable). Flag for CoE attention. |
| No KB for ecosystem | Ecosystem file missing | Use cross-cutting only. Mark limitation. Recommend learning scan. |
| No AI attribution found | Zero Co-authored-by, zero bot PRs | Valid result: all Absent adoption. Report focuses on Opportunity Map + Readiness + Recommendations. |
| Archived/unmaintained repo | No commits in 6 months, no open PRs | Flag in executive summary. Frame recommendations as conditional: "If development resumes..." |
| Hallucination caught by adversarial | Spot-check fails | Remove finding. Log incident in detailed-log. Do not downgrade the entire scan. |

## Important

- **AAMM is strictly read-only on target repos** — NEVER create PRs, commits, issues, comments, branches, tags, or any writes to the scanned repository. All output goes to cbu-coe-toolkit only. GitHub API is used with read scope exclusively.
- **Never print, log, or display $GITHUB_TOKEN**
- **Adversarial reviews are MANDATORY** — both Stage A and Stage B. Never skip.
- **No confirmations during scans** — run fully autonomously end-to-end
- **Report is official at completion** — no approval gate before publishing
- **Scan-from-zero** — never read previous results before Phase 1 is frozen
- **ROI ordering** — opportunities and recommendations always ordered by ROI descending
- **Mastered nominations** — flag candidates, CoE confirms
- **Never publish to Notion without human approval**
