# AAMM Changelog

All notable changes to the AI Augmentation Maturity Model.

---

## v3.0 — March 2026

**Architecture: Two-axis model (Readiness × Adoption)**

The most significant evolution of the model. Merges v1's SDLC-dimension stages with v2's Readiness pillars into a unified quadrant model.

### What's New
- **AI Readiness axis (0-100)** with 4 scored pillars: Structural Clarity, Semantic Density, Verification Infrastructure, Developer Ergonomics
- **7th Adoption dimension:** AI Practices & Governance (cross-cutting)
- **Two-condition Stage 1 gate:** Every dimension requires practice active + AI config
- **Sub-levels (Low/Mid/High):** Within-stage progress for finer granularity
- **Learning signals:** static/evolving/self-improving annotation per dimension
- **Quadrant model:** Traditional / Fertile Ground / Risky Acceleration / AI-Native
- **Next Steps:** Always exactly 3 per repo, ordered by impact/effort
- **Ops/Monitoring Stage 2:** AI assists during incidents (was a gap in v1)
- **Delivery Stage 1 accepts external tools:** Teams using Jira/Linear not penalized
- **Language-aware Readiness:** Haskell, Rust, TypeScript bonus signals

### What Changed from v1
- Single-axis → two-axis architecture
- 6 dimensions → 7 (added AI Practices & Governance)
- No within-stage granularity → Sub-levels (Low/Mid/High)
- Learning signals only at Stage 4 → all stages
- Infrastructure readiness noted → Readiness scored 0-100
- Stage per dimension + overall → Quadrant + coordinates + Next Steps

### Design Decisions (ADR-002)
1. AI Readiness stays in AAMM, not CMM — quadrant model requires co-location
2. Adoption uses stages + sub-levels, not continuous 0-100
3. Two-condition Stage 1 gate for all dimensions
4. Learning signals enrich sub-levels, not a separate axis
5. Next Steps as flywheel: scan → actions → progress → scan

---

## v2.0 — March 2026 (experimental)

**Alternative design explored, insights merged into v3.**

v2 was developed as a parallel exploration emphasizing formula-based scoring (0-100 continuous) for both axes. Key insight: continuous scoring was over-engineering for adoption — 35 formula definitions, hard to reproduce, confusing when contradicting cumulative stages. v2's Readiness pillars (R1-R4) were adopted into v3 unchanged.

See `models/ai-augmentation-maturity-v2/comparison-assessment.md` for the detailed comparison.

---

## v1.0 — March 2026

**Initial model: Single-axis, 6 SDLC dimensions, Stages 0-4.**

The foundational design establishing:
- Per-repository scoring (not per-team)
- 6 SDLC dimensions: Code Quality, Security, Testing, Release, Ops/Monitoring, AI-Assisted Delivery
- Cumulative stages (Stage 2 requires Stage 1)
- Anti-gaming provisions (quality threshold for AI config)
- Infrastructure readiness tracking (non-AI tooling noted but not scored)
- Minimum viability thresholds (engineering hygiene baselines)

Known gaps addressed in v3: no readiness measurement, no within-stage granularity, Ops Stage 2 gap, Delivery assumed GitHub-only, no learning signals below Stage 4.
