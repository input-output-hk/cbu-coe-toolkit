---
name: scan-ai-augmentation
description: Run the monthly AAMM v3 AI Augmentation scan across tracked CBU repos. Scores Readiness (R1-R4) and Adoption (7 dimensions) per repo, generates Next Steps, and produces org-level summary.
---

# Scan AI Augmentation

Run the monthly AAMM v3 scan across all tracked repositories.

## Prerequisites

- `$GITHUB_TOKEN` environment variable set with repo read access
- Working directory: `cbu-coe-toolkit/`

## Execution

Follow the scan prompt exactly:

1. **Read** `scans/ai-augmentation/SCAN_PROMPT.md` — the complete agent-executable instructions
2. **Read** the three model documents referenced in the scan prompt:
   - `models/ai-augmentation-maturity-v3/model-spec.md`
   - `models/ai-augmentation-maturity-v3/adoption-scoring.md`
   - `models/ai-augmentation-maturity-v3/readiness-scoring.md`
3. **Read** `scans/ai-augmentation/config.yaml` for signal patterns and scan settings
4. **Load** repo list from `models/config.yaml`
5. **Execute** the 12-step scan flow defined in SCAN_PROMPT.md
6. **Present** results to human operator for review before writing to disk

## Output

- Per-repo reports (box format + JSON)
- Org-level summary
- Machine-readable snapshot: `scans/ai-augmentation/results/YYYY-MM.json`

## Important

- Never publish to Notion without human approval
- Never overwrite previous monthly snapshots
- Never print, log, or display the GitHub token
- All scoring decisions must include evidence citations

## Reference Files

| File | Purpose |
|------|---------|
| `scans/ai-augmentation/SCAN_PROMPT.md` | Step-by-step scan instructions |
| `scans/ai-augmentation/config.yaml` | Signal patterns, bot names, thresholds |
| `models/ai-augmentation-maturity-v3/model-spec.md` | Stage definitions, quadrant model |
| `models/ai-augmentation-maturity-v3/adoption-scoring.md` | Adoption scoring per dimension |
| `models/ai-augmentation-maturity-v3/readiness-scoring.md` | Readiness scoring (R1-R4) |
| `models/config.yaml` | Tracked repo list |
| `notion/page-registry.yaml` | Notion page IDs for publishing |
