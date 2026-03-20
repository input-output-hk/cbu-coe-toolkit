---
name: scan-ai-augmentation
description: Run the AAMM AI Augmentation scan across tracked CBU repos. Scores Readiness (3 pillars, 17 signals) and Adoption (5 dimensions, 4 stages) per repo, generates recommendations.
---

# Scan AI Augmentation

Run the AAMM scan across tracked repositories.

## Prerequisites

- `$GITHUB_TOKEN` environment variable set with repo read access
- Working directory: `cbu-coe-toolkit/`

## Execution

1. **Read** the model documents:
   - `models/ai-augmentation-maturity/model-spec.md`
   - `models/ai-augmentation-maturity/readiness-scoring.md`
   - `models/ai-augmentation-maturity/adoption-scoring.md`
2. **Read** `scans/ai-augmentation/config.yaml` for tracked repos
3. **Run** `scripts/aamm/scan-repo.sh owner/repo` per repo
4. **Review** script output and override signals needing agent judgment
5. **Present** results to human operator before writing to disk

## Output

- Per-repo `.md` + `.json` reports
- Machine-readable snapshot: `scans/ai-augmentation/results/YYYY-MM.json`

## Important

- Never publish to Notion without human approval
- Never overwrite previous monthly snapshots
- Never print, log, or display the GitHub token
- All scoring decisions must include evidence citations

## Reference Files

| File | Purpose |
|------|---------|
| `models/ai-augmentation-maturity/model-spec.md` | Architecture, pillars, signals, stages, penalties |
| `models/ai-augmentation-maturity/readiness-scoring.md` | 17 signal scoring tables, formulas |
| `models/ai-augmentation-maturity/adoption-scoring.md` | 5 dimension decision trees |
| `scans/ai-augmentation/config.yaml` | Tracked repos, model references |
| `scripts/aamm/scan-repo.sh` | Automated scan pipeline |
| `notion/page-registry.yaml` | Notion page IDs for publishing |
