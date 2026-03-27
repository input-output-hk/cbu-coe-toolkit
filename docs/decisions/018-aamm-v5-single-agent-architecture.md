# ADR-018: AAMM v5 — Single AI Agent Replaces Dual Architecture

**Date:** 2026-03-27 · **Status:** Accepted
**Supersedes:** ADR-017 (AAMM Purpose and Dual Architecture)
**Applies to:** All AAMM model files, pipeline scripts, scan workflow, KB

## Rule

AAMM v5 uses a **single AI agent** for both assessment and recommendations. The deterministic bash pipeline (`collect-all.sh`, `score-readiness.sh`, `score-adoption.sh`, `review-scores.sh`, `generate-report.sh`) is eliminated. Reproducibility is achieved through **structured rubric criteria embedded in the agent prompt**, not through a separate deterministic pipeline.

The agent follows a rubric + depth methodology:
1. **Rubric** — concrete, verifiable criteria per pillar/zone anchor the status level
2. **Depth** — qualitative exploration adds findings, nuance, and evidence

Both phases are performed by the same agent. The rubric is part of the prompt, not a separate system.

## Anti-patterns

- Maintaining two parallel systems (pipeline + agent) that must be kept in sync
- Using bash grep for qualitative assessment (bash counts but cannot understand)
- Using AI agent without structured criteria (vibes-based assessment with no anchoring)
- Claiming "deterministic" for evaluations that involve agent judgment — use "structured and reproducible" instead
- Reintroducing a global boolean for adoption (v4 flaw) — each zone has independent rubric criteria

## Context

ADR-017 proposed dual architecture: deterministic pipeline for scores + AI agent for findings. This was a reasonable compromise during session 9, but further analysis revealed:

1. **The pipeline was a workaround.** 9 sessions of complexity (50-call API budget, sampling strategies, grep patterns, signal weights, boundary logic, SIGPIPE fixes) existed because bash cannot understand — only count. Every session produced more fixes because the approach is fundamentally limited.

2. **Two systems is double maintenance.** Pipeline + agent means two things to build, sync, test, and debug. When scoring logic changes, both must be updated. CLAUDE.md sync protocol already identifies this as a bug source.

3. **Reproducibility via rubric.** ADR-017's core concern was that AI agent assessments are non-reproducible. The rubric solves this: concrete criteria (file exists? config parsed? count verified?) produce consistent baseline levels. The agent adds depth that bash couldn't provide, but the level anchoring comes from the rubric.

4. **ADR-017's insight is preserved.** "Use each mechanism for what it's best at" — the rubric IS the structured mechanism (embedded in the agent), and the depth IS the AI mechanism. Same principle, unified system.

5. **Leadership tracking works with rubric scores.** Instead of 0-100 composites, leadership sees rubric scores per pillar (e.g., Structure: 4/5 → 5/5) and status levels (Exploring → Practiced). These track progress honestly. Rubric score changes on objective criteria are comparable across scans.

### What changes from ADR-017

| ADR-017 said | ADR-018 says | Why |
|---|---|---|
| Pipeline stays, agent is added | Agent replaces pipeline | Pipeline was a workaround; maintaining both is waste |
| Deterministic scores for leadership | Structured rubric scores for leadership | Rubric provides comparable tracking without false precision |
| AI agent for findings only | AI agent for assessment + findings + recommendations | One system, structured methodology |
| Two mechanisms | One mechanism with two phases (rubric + depth) | Same principle, unified implementation |

## Consequences

- **Eliminated:** `collect-all.sh`, `score-readiness.sh`, `score-adoption.sh`, `review-scores.sh`, `generate-report.sh`, all weighted composite scoring
- **New:** AI agent with rubric + depth methodology, per-pillar and per-zone rubric criteria, Knowledge Base
- **Changed:** Reports use status levels (Undiscovered/Exploring/Practiced/Mastered) and rubric scores instead of 0-100 composites
- **Must maintain:** Rubric criteria in agent prompt must match spec. When criteria change, assessment schema version must be bumped.
- **Full spec:** `docs/superpowers/specs/2026-03-27-aamm-v5-spec.md`
