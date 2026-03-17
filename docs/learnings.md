<!-- Scope: Append-only log of operational insights discovered during agent sessions. Edge cases, technical discoveries, process improvements. Agents propose new entries at the end of each session. -->

# Learnings Log

Newest entries first. Each entry includes the date and a brief context tag.

---

### 2026-03-17 — AAMM v3 design and implementation

- **Two-condition gates are the right default for Stage 1.** Config-only Stage 1 (v1) allowed repos to "game" the model by adding a CLAUDE.md without any actual engineering practice. Requiring both practice active + AI config is more honest and more useful for recommendations.
- **Sub-levels beat continuous scores for adoption.** v2's 0-100 continuous scoring required 35+ formula definitions, was hard for agents to reproduce consistently, and confused stakeholders when "progress score 45" contradicted "Stage 1." Sub-levels (Low/Mid/High) give enough granularity for tracking month-over-month progress without the complexity.
- **Cross-cutting dimensions need explicit labeling.** AI Practices & Governance doesn't fit any single SDLC dimension. When it was distributed across other dimensions, scoring became inconsistent. Making it dimension 7 with explicit "cross-cutting" label resolved this.
- **The quadrant model is the communication tool, not the stages.** "Fertile Ground — Readiness 90, Adoption 5" communicates more in one line than any table of stage scores. The quadrant is what leadership remembers; stages are what teams act on.
- **Next Steps as flywheel.** Always 3 steps, always ordered by impact/effort, always showing projected dimension advancement and composite change. This turns the scan from a measurement event into an action generator.
- **Learning signals belong in sub-levels, not a separate axis.** Adding a "learning sophistication" axis would create a 3D model — too complex. Annotations (static/evolving/self-improving) affecting sub-level assignment give the same insight without the complexity.

---

### 2026-03-13 — Initial setup

- **Directory scaffolding complete:** Both repos scaffolded per project brief v1.1 Section 3. All placeholder files created with scope comments.
- **Knowledge capture system adopted:** Three-layer system (decisions, learnings, session handoff) in place for both repos. See ADR-001.
- **Notion page registry pre-populated:** All page IDs from project brief included in `notion/page-registry.yaml`.
