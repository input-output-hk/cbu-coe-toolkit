---
name: scan-ai-augmentation
description: Run the AAMM AI Augmentation scan across tracked CBU repos. Scores Readiness (3 pillars, 17 signals) and Adoption (5 dimensions, 4 stages) per repo, generates recommendations.
---

# Scan AI Augmentation

Run the AAMM scan across tracked repositories.

## Prerequisites

- `$GITHUB_TOKEN` environment variable set with repo read access. Source it: `source ~/.zshrc`
- Working directory: `cbu-coe-toolkit/` — always `cd` to it before running scripts

## Execution

### Step 0: Prepare environment
```bash
source ~/.zshrc
cd /home/devuser/repos/cbu-coe/cbu-coe-toolkit
```

### Step 1: Read model documents (agent context, not bash)
Read these files to understand the scoring model before running:
- `models/ai-augmentation-maturity/README.md`
- `models/ai-augmentation-maturity/readiness-scoring.md`
- `models/ai-augmentation-maturity/adoption-scoring.md`
- `models/ai-augmentation-maturity/domain-profiles.md`
- `scans/ai-augmentation/config.yaml` — for tracked repos and org/repo names

### Step 2: Run scan per repo
**Use `scan-repo.sh` — the single entry point.** It runs all 5 pipeline steps and saves JSON + MD reports.

```bash
# Single repo:
source ~/.zshrc && cd /home/devuser/repos/cbu-coe/cbu-coe-toolkit && \
  bash scripts/aamm/scan-repo.sh owner/repo 2>&1

# Multiple repos (sequential):
for repo in "IntersectMBO/cardano-node" "input-output-hk/mithril"; do
  bash scripts/aamm/scan-repo.sh "$repo" 2>&1
done
```

**CRITICAL invocation rules:**
- Always include `source ~/.zshrc &&` to ensure `$GITHUB_TOKEN` is set
- Always include `cd /home/devuser/repos/cbu-coe/cbu-coe-toolkit &&` before the script
- **Never pipe output** through `tail`, `head`, or `grep` — this causes SIGPIPE (exit 141) on large repos
- **Never run pipeline steps individually** (`score-readiness.sh`, `score-adoption.sh` etc.) — they write to stdout, not to files. Only `scan-repo.sh` does the correct redirects.
- Run from the **main conversation**, not from subagents — subagents do not inherit Bash permissions
- For background execution, do NOT truncate output: `bash scripts/aamm/scan-repo.sh owner/repo 2>&1` (no `| tail`)

### Step 3: Adversarial review (per repo)
After scan completes, dispatch an Agent subagent per repo to adversarially review the output:

The adversarial reviewer reads:
- `scans/ai-augmentation/results/YYYY-MM-DD/{repo}-report.json`
- `scans/ai-augmentation/results/YYYY-MM-DD/{repo}-report.md`
- `/tmp/aamm-{owner}-{repo}/readiness-scores.json`
- `/tmp/aamm-{owner}-{repo}/adoption-scores.json`
- `/tmp/aamm-{owner}-{repo}/review-notes.json`

The reviewer challenges every signal from **two perspectives**:
1. **CoE**: Is the score defensible to leadership? Methodology applied correctly?
2. **Repo owner/team**: Would the team find this fair and accurate?

Challenge dimensions: clarity, scope, desired outcome, completeness, accuracy.

Output per issue: signal, severity (HIGH/MEDIUM/LOW), what's wrong, CoE risk, team risk, proposed solution.

### Step 4: Present results
Present to human operator before writing to disk or publishing.

## Output

- Per-repo `.md` + `.json` reports in `scans/ai-augmentation/results/YYYY-MM-DD/`
- Raw data in `/tmp/aamm-{owner}-{repo}/`

## Important

- Never publish to Notion without human approval
- Never overwrite previous monthly snapshots
- Never print, log, or display the GitHub token
- All scoring decisions must include evidence citations
- **No confirmations during scans** — run fully autonomously

## Reference Files

| File | Purpose |
|------|---------|
| `models/ai-augmentation-maturity/README.md` | Architecture, pillars, signals, stages, penalties |
| `models/ai-augmentation-maturity/readiness-scoring.md` | 17 signal scoring tables, formulas |
| `models/ai-augmentation-maturity/adoption-scoring.md` | 5 dimension decision trees |
| `models/ai-augmentation-maturity/domain-profiles.md` | High-assurance supplementary signals |
| `scans/ai-augmentation/config.yaml` | Tracked repos, model references |
| `scripts/aamm/scan-repo.sh` | Automated scan pipeline (SINGLE ENTRY POINT) |
| `notion/page-registry.yaml` | Notion page IDs for publishing |
