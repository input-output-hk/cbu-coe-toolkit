# cbu-coe-toolkit

Measurement machinery for the CBU Centre of Excellence at IOG.

This repo is the **measurement layer** — maturity models, scoring scripts, and
scan results. The companion repo
[cbu-coe](https://github.com/input-output-hk/cbu-coe) holds the guidance
layer: templates, skills, and standards for teams.

---

## What's here

### `models/`

Three measurement instruments, each answering a different question:

| Model | Question | Status |
|---|---|---|
| **AI Augmentation Maturity (AAMM)** | Have you institutionalised AI? | Draft |
| **Capability Maturity** | Is your engineering practice solid? | Draft |
| **Engineering Vitals** | Is the work delivering value? | External (Power BI) |

AAMM is the primary active model. It measures two axes per repo: AI Readiness
(is this codebase structurally suitable for AI collaboration?) and AI Adoption
(is AI actively used in workflows?). Full spec in
`models/ai-augmentation-maturity/`.

### `scripts/aamm/`

Automated scan pipeline. Single entry point:

```bash
./scripts/aamm/scan-repo.sh owner/repo
```

Produces a scored report in `scans/ai-augmentation/results/`. The pipeline
runs five steps: collect → score-readiness → score-adoption → review-scores →
generate-report. No confirmations, no manual steps.

### `scans/`

Scan configuration and results history.

- `ai-augmentation/config.yaml` — 29 tracked repos across 4 GitHub orgs
- `ai-augmentation/results/` — monthly scan reports (Markdown + JSON)

### `skills/`

Claude Code skills for CoE operators:

- `quality-gate` — universal quality gate, self-score and iterate to 9.0+
- `peer-review` — structured peer review at design, implementation, and output checkpoints
- `scan-ai-augmentation` — guided AAMM scan execution
- `review-model` — model spec review and consistency checking
- `synthesize` — cross-repo synthesis and trend analysis
- `publish-to-notion` — publish results to the Notion dashboard

---

## Who this is for

CoE operators and AI agents running scans. Teams consuming results should look
at the Notion dashboard or ask the CoE for a report — they do not need to run
scans themselves.

---

## Contributing

Open a pull request. CoE (@dorin100) reviews and merges. Changes to model
definitions, scoring rules, or signal thresholds require an ADR in
`docs/decisions/`.

---

## Related

- [cbu-coe](https://github.com/input-output-hk/cbu-coe) — guidance layer:
  templates, skills, standards for teams
- [CoE Confluence page](https://input-output.atlassian.net/wiki/spaces/IOE/pages/5700845586/) —
  entry point and published results (internal)

---

© Input Output Global, Inc. Internal use.
