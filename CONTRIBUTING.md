# Contributing to cbu-coe-toolkit

This repo contains the measurement machinery for the CBU Centre of Excellence — maturity models, scoring scripts, and scan results.

## How to contribute

1. Create a feature branch from `main`.
2. Make your changes.
3. Open a PR describing *why* the change is useful.
4. CoE (@dorin100) reviews and merges.

## What belongs here

- **Model definitions** — scoring rules, signal thresholds, stage criteria (see `models/`)
- **Scan scripts** — automation for data collection and scoring (see `scripts/`)
- **Results** — monthly scan snapshots (see `scans/`)
- **Skills** — Claude Code skills for CoE operators (see `.claude/skills/`)
- **ADRs** — decisions that affect models or methodology (see `docs/decisions/`)

## What belongs in cbu-coe

Guidance, templates, and standards for teams. If teams adopt it directly, it goes in [cbu-coe](https://github.com/input-output-hk/cbu-coe).

## Model changes require an ADR

Changes to scoring rules, signal definitions, or stage criteria must include an Architecture Decision Record in `docs/decisions/`.

## Questions?

Open an issue or reach out in `#ai-collaboration-circles` on Slack.
