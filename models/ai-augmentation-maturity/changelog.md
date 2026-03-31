# AAMM Changelog

## v6 — 2026-03-30 (spec + scoring-model complete, KB seed pending)

**ADR-019** — v5 answered the wrong question. v6 built around AI use-case spectrum.

### What changed from v5

**Architecture:**
- Replaced 25-criterion fixed rubric with KB-driven, per-use-case assessment
- Opportunity Map is the core driver — everything downstream depends on it
- Two adversarial review stages: Stage A (opportunity map) + Stage B (recommendations)
- Fully autonomous end-to-end — no mid-scan gates, no confirmations
- Report is official at completion; CoE challenges post-publication
- Two scan types: learning (KB population) + scoring (full assessment)

**Assessment model:**
- 5 pillars + 5 zones replaced by 5 components: Opportunity Map, Adoption State, Readiness per Use Case, Risk Surface, Recommendations
- Readiness criteria live in KB per use-case type (not fixed per pillar)
- Risk Surface mapped to concrete code paths with AI exposure calibration
- Ad-hoc AI Usage flag replaces scored Governance component
- Team Capability removed — replaced by recommended learning per recommendation
- Quadrant labels made neutral/descriptive (no judgmental names)
- Readiness level "Not Assessable" added for missing KB criteria

**Operational:**
- All opportunities and recommendations ROI-ordered (#1 = highest ROI)
- No artificial count targets (min 3 opportunities, no upper cap — Stage A filters)
- Opportunity-risk intersection explicitly marked as inferential (MEDIUM confidence)
- Mastered level requires CoE nomination (transferability is an org signal)
- KB bootstrapping defined as Phase 0 (mandatory before first scoring scan)
- Edge cases and failure modes documented in spec

**Files updated:** spec.md (rewritten), scoring-model.md (rewritten), README.md, changelog.md, CLAUDE.md, ADR-019.

**Pending:** KB restructure to v6 format (seed + learning scans), scan skill `/scan-aamm-v6`.

### Design insights (2026-03-28 → 2026-03-30)

- v5 measured "is this a well-run repo?" and called it "AI readiness." A 2015 repo with zero AI use could score HIGH.
- v6 asks "which AI use cases fit this repo, and is the team set up for them?" — correlated but different question.
- First draft of v6 had 7 components, 2 human gates (max 3 rounds each), Team Capability, scored Governance. Three rounds of aggressive adversarial review on the spec itself reduced to 5 components + 1 flag, zero mid-scan gates, fully autonomous.
- Key principle: human gates sound responsible but become rubber stamps under load. 29 repos × quarterly × iterative review = hundreds of hours for one person. An autonomous scan with post-publication challenge is more honest.
- Governance-as-component measured mechanisms (CLAUDE.md exists, attribution consistent) not outcomes — violated ADR-011. Replaced with a flag that notes absence of signals without judging.

## v5 — 2026-03-27

**ADR-018** — Single AI agent replaces bash pipeline.

Key changes from v4:
- Eliminated 9-script bash pipeline (scripts/aamm/)
- Single AI agent with rubric + depth methodology
- Knowledge Base introduced for cross-repo learning (22 pre-seeded patterns)
- Adversarial reviewer sub-agent (mandatory gate, ADR-012 extended)
- 25 readiness criteria across 5 pillars + 15 adoption criteria across 5 zones
- Confidence model: HIGH/MEDIUM/LOW with explicit ceilings per evidence type
- Inferred-evidence ceiling rule for adoption zones
- Quadrant simplified (from complex scoring to 3×3 grid)
- Model files consolidated under `models/ai-augmentation-maturity/`

Design insight (9 sessions of v4 refinement): the bash pipeline was a workaround for the fact that bash can count but cannot understand. The rubric provides reproducibility; the agent provides understanding.

## v4 — 2026-03-21 to 2026-03-26

Bash pipeline + AI agent (dual architecture). 9 sessions of refinement.
Key learnings: dual architecture creates maintenance burden and sync debt.
ADR-017 (superseded by ADR-018).

## v1–v3 — Earlier

Earlier iterations. Undocumented. v4 was the first versioned architecture.
