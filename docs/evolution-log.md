<!-- Scope: Chronological record of significant design changes to the toolkit — what changed, when, and why. Different from ADRs (which capture point-in-time decisions) and learnings (which capture operational insights). -->

# Evolution Log

Newest entries first.

---

### 2026-03-17 — AAMM v3 implemented

- v3 model spec written: two-axis model (Readiness × Adoption), 7 adoption dimensions, sub-levels, quadrant model, Next Steps.
- Adoption scoring methodology defined: step-by-step agent-executable processes for all 7 dimensions with two-condition gates.
- Readiness scoring methodology defined: metric-to-score mappings for R1-R4, language bonuses, cross-pillar constraints.
- Scan prompt and config updated for v3 monthly execution.
- v1 and v2 directories deprecated (not deleted) with notices pointing to v3.
- ADR-002 documents the v3 architecture decisions.
- Changelog tracks v1 → v2 → v3 evolution.

---

### 2026-03-13 — Repository scaffolded

- Both `cbu-coe` and `cbu-coe-toolkit` repos scaffolded with directory structures per project brief v1.1 Section 3.
- Root CLAUDE.md files created for both repos.
- Notion page registry pre-populated from project brief.
- Adopted three-layer knowledge capture system (see ADR-001).
- Cleaned both repos for org-wide visibility: removed sensitive organizational context, kept professional operational content.
