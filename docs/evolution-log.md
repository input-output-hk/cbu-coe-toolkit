<!-- Scope: Chronological record of significant design changes to the toolkit — what changed, when, and why. Different from ADRs (which capture point-in-time decisions) and learnings (which capture operational insights). -->

# Evolution Log

Newest entries first.

---

### 2026-03-20 — AAMM consolidated: v1/v2/v3 removed, single model

- **Consolidated to single version** — deleted v1, v2, v3 directories. Renamed `ai-augmentation-maturity-v4/` → `ai-augmentation-maturity/`. Git history preserves all prior versions.
- **Automation scripts completed** — `scripts/aamm/` with full pipeline: `scan-repo.sh owner/repo` → collect → score → report. No confirmations needed.
- **Vulnerability monitoring penalty redesigned** — graduated scale replaces binary -10. Ecosystems without scanning tools (Haskell) get -5 if team has active dep management strategy.
- **Haskell-specific audit** — 18 checks across all scoring logic. Fixed: V2 test categorization (added .cabal dep scanning), Spec.hs detection, block Haddock comments, Stack lockfile, stan/weeder tools.
- **Three sample reports validated** — lace v1 (68.6/0), cardano-ledger (77.6/0), lace-platform (76.9/9.9). Removed sample reports from model directory (generated on demand via scripts).
- **CLAUDE.md rewritten** for current architecture. All internal references updated.

---

### 2026-03-20 — AAMM v4 designed and validated

- Redesigned from v3 based on 57-finding audit (7 critical). Vision-first approach.
- 3 Readiness pillars (Navigate, Understand, Verify) with 17 signals. No language bonuses.
- 5 Adoption dimensions (Code, Testing, Security, Delivery, Governance) with 4 stages.
- Content-category checklist (≥3 of 6) replaces 50-line threshold for AI config quality.
- 5-layer AI detection methodology (ADR-003): Tree → Commits → PR Author → PR Body → Submodules.
- Validated on 3 repos: lace (TS monorepo), cardano-ledger (Haskell), lace-platform (TS/RN NX monorepo).

---

### 2026-03-17 — AAMM v3 implemented (superseded)

- Two-axis model (Readiness × Adoption), 7 adoption dimensions, sub-levels, quadrant model.
- Superseded by current AAMM based on 57-finding audit.

---

### 2026-03-13 — Repository scaffolded

- Both `cbu-coe` and `cbu-coe-toolkit` repos scaffolded.
- Root CLAUDE.md files created. Notion page registry pre-populated.
- Adopted three-layer knowledge capture system (ADR-001).
