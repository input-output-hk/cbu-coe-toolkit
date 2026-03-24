# cbu-coe-toolkit

Measurement machinery for the CBU Centre of Excellence at IOG.

This repo is the **measurement layer** — maturity models, scoring scripts, and scan results. The companion repo [cbu-coe](https://github.com/input-output-hk/cbu-coe) holds the guidance layer: templates, skills, and standards for teams.

---

## What's here

### Models — [`models/`](models/)

Three measurement instruments, each answering a different question:

| Model | Question | Status |
|---|---|---|
| **[AI Augmentation Maturity (AAMM)](models/ai-augmentation-maturity/)** | Is AI institutionalised in this repo? | Active |
| **[Capability Maturity](models/capability-maturity/)** | Are engineering practices solid? | Draft |
| **[Engineering Vitals](models/engineering-vitals/)** | Is work delivering value? | External (Power BI) |

AAMM is the primary active model. It measures two axes per repo: AI Readiness (structural suitability for AI collaboration) and AI Adoption (active AI usage in workflows). Full spec in [`models/ai-augmentation-maturity/`](models/ai-augmentation-maturity/).

### Scan pipeline — [`scripts/aamm/`](scripts/aamm/)

Automated scan pipeline. Single entry point:

```bash
./scripts/aamm/scan-repo.sh owner/repo
```

Produces a scored report in [`scans/ai-augmentation/results/`](scans/ai-augmentation/results/). Five steps: collect → score-readiness → score-adoption → review-scores → generate-report. Non-interactive.

### Scan history — [`scans/`](scans/)

- [`config.yaml`](scans/ai-augmentation/config.yaml) — 29 tracked repos across 4 GitHub orgs
- [`results/`](scans/ai-augmentation/results/) — monthly scan reports (Markdown + JSON)

### Skills — [`skills/`](skills/)

Claude Code skills for CoE operators:

- **quality-gate** — self-score and iterate to 9.0+
- **peer-review** — structured review at design, implementation, and output checkpoints
- **scan-ai-augmentation** — guided AAMM scan execution
- **review-model** — model spec review and consistency checking
- **synthesize** — cross-repo synthesis and trend analysis
- **publish-to-notion** — publish results to Notion dashboard

---

## Who this is for

CoE operators and AI agents running scans. Teams consuming results should use the Notion dashboard or request a report from the CoE.

---

## Contributing

Open a pull request. CoE ([@dorin100](https://github.com/dorin100)) reviews and merges. Changes to model definitions, scoring rules, or signal thresholds require an ADR in [`docs/decisions/`](docs/decisions/).

---

## Related

- [cbu-coe](https://github.com/input-output-hk/cbu-coe) — guidance layer: templates, skills, standards
- [CoE Confluence page](https://input-output.atlassian.net/wiki/spaces/IOE/pages/5700845586/) — entry point and published results

---

© Input Output Global, Inc.
