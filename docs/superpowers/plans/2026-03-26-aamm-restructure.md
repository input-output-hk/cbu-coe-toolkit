# AAMM Information Architecture Restructure — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure AAMM model files so each file has one clear purpose, audiences know what to read, agents know what's authoritative, and changes in one place trigger updates in all related places.

**Architecture:** Split model-spec.md (612 lines, 9 sections, 3 audiences) into purpose-specific files. Consolidate decisions from backlog.md into ADR format. Add dependency headers to every file. Update CLAUDE.md with read/sync protocol.

**Current → Target file map:**

| Current | Target | What moves |
|---|---|---|
| model-spec.md §1-2 (Purpose, Architecture) | **README.md** | Model overview for external audience |
| model-spec.md §3 (Readiness pillars overview) | **README.md** | Pillar descriptions (what, not how) |
| model-spec.md §4 (Adoption overview) | **README.md** | Dimension descriptions (what, not how) |
| model-spec.md §5 (Recommendations) | **README.md** | Recommendation principles |
| model-spec.md §6 (Output Structure) | **README.md** | Report format description |
| model-spec.md §7 (Domain Profiles) | **domain-profiles.md** | Extracted to own file |
| model-spec.md §8 (Automation) | stays in scripts README/CLAUDE.md | Pipeline docs |
| model-spec.md §9 (v3 Connection) | **README.md** appendix | Historical context |
| model-spec.md Glossary | **README.md** appendix | Reference |
| readiness-scoring.md | **readiness-scoring.md** (unchanged) | Authoritative scoring spec |
| adoption-scoring.md | **adoption-scoring.md** (unchanged) | Authoritative scoring spec |
| backlog.md Done sections | deleted (git history) | Session history |
| backlog.md Pending Decisions | **docs/decisions/** as ADRs | Architectural decisions |
| backlog.md Design Principles | **README.md** | Model principles |
| backlog.md Validation Repos | **backlog.md** (kept) | Active tracking |
| backlog.md Backlog | **backlog.md** (kept) | Active work |

---

### Task 1: Update ADR template for agent-optimized format

**Files:**
- Modify: `docs/decisions/000-template.md`

- [ ] **Step 1: Replace template with agent-optimized format**

```markdown
# ADR-XXXX: [Title]

**Date:** YYYY-MM-DD · **Status:** Proposed | Accepted | Superseded by ADR-XXXX
**Applies to:** [files and scripts affected by this decision]

## Rule

[1-2 sentences: what was decided. An agent reading only this section should know the rule.]

## Anti-patterns

- [What NOT to do — the mistake this decision prevents]

## Context

[Why this decision was needed — only enough to understand the rule]

## Consequences

- **Changed:** [files modified]
- **Must maintain:** [sync requirements]
```

- [ ] **Step 2: Commit**

```bash
git add docs/decisions/000-template.md
git commit -m "docs: update ADR template for agent-optimized format (Rule first, anti-patterns explicit)"
```

---

### Task 2: Create ADR-004 — Scoring methodology corrections (session 7)

**Files:**
- Create: `docs/decisions/004-scoring-methodology-corrections.md`

- [ ] **Step 1: Write consolidated ADR for all scoring fixes**

```markdown
# ADR-004: Scoring methodology corrections

**Date:** 2026-03-26 · **Status:** Accepted
**Applies to:** `scripts/aamm/score-readiness.sh`, `scripts/aamm/review-scores.sh`, `scripts/aamm/collect-readiness.sh`, `scripts/aamm/generate-report.sh`, `models/ai-augmentation-maturity/readiness-scoring.md`

## Rule

Scoring detection must use specific tool names (not generic keywords), check all plausible locations (not just one), and track per-tool CI enforcement (not a single boolean). Evidence strings in markdown must escape pipe characters.

## Anti-patterns

- **Generic regex matching:** `coverage` matches non-coverage strings, `--min` matches `--minimize-conflict-set`. Always use specific tool names (`codecov`, `hpc`, `tarpaulin`) and require context for threshold detection (`coverage.*threshold`, not `--min`).
- **Single-source detection:** Concluding "tool absent" from one check (e.g., `.hlint.yaml` in tree). Nix projects define tools in `flake.nix`. Always check: tree files → `flake.nix` → CI workflows → package manifests.
- **Single CI boolean:** `CI_LINT=1` can't distinguish "formatter in CI" from "linter in CI." Use `CI_LINTER` + `CI_FORMATTER` separately. Score 100 only when BOTH are CI-enforced.
- **Hardcoded heading level:** `## *` misses `#` (H1) headings. Use `#{1,6} *` for any heading level.
- **Unescaped pipes in markdown:** Haddock syntax `-- |` breaks markdown table columns. Escape `|` as `\|` in all evidence strings.

## Context

Exhaustive rescan of cardano-ledger (session 7) found 5 scoring bugs: N5 false negative (hlint in flake.nix invisible), U2 never sampled, U3 missed H1 headings, V4 false positive (generic regex), N5 CI over-counted (single boolean). Original score 80.07 had correct total by accident — composition was fundamentally wrong (V4=100 when actual=0).

## Consequences

- **Changed:** score-readiness.sh (N5 per-tool CI, U3 heading regex, V4 specific regex), collect-readiness.sh (flake.nix fetch), review-scores.sh (per-tool CI), generate-report.sh (pipe escaping), readiness-scoring.md (N5/U3/V4 spec updates)
- **Must maintain:** When adding new detection patterns, use specific tool names. When adding new regex for CI, test against real workflow files for false matches.
```

- [ ] **Step 2: Commit**

```bash
git add docs/decisions/004-scoring-methodology-corrections.md
git commit -m "docs: ADR-004 scoring methodology corrections from exhaustive rescan"
```

---

### Task 3: Create ADR-005 — Union-based adoption counting + V1 threshold

**Files:**
- Create: `docs/decisions/005-adoption-counting-and-thresholds.md`

- [ ] **Step 1: Write ADR consolidating D1 and D5 from backlog.md**

```markdown
# ADR-005: Union-based adoption counting and V1 threshold

**Date:** 2026-03-20 · **Status:** Accepted
**Applies to:** `scripts/aamm/score-adoption.sh`, `models/ai-augmentation-maturity/adoption-scoring.md`, `scripts/aamm/score-readiness.sh`

## Rule

1. **Adoption content-categories are counted across the union of all AI config files**, not per-file. An index-style CLAUDE.md that references `.claude/` files scores the same as a monolithic CLAUDE.md. We measure total coverage, not per-file density.

2. **V1 test/source ratio threshold stays at 0.7** for all languages. Test quality is captured by V2 (test categorization) and domain profiles (generator discipline), not V1.

## Anti-patterns

- **Per-file scoring:** Counting categories in each file separately and taking the max. This penalizes DRY architecture (e.g., lace-platform's `.claude/` with 30+ organized docs).
- **Language-specific V1 thresholds:** Lowering V1 for property-testing ecosystems. Property test quality belongs in V2 sub-signals, not V1 ratio adjustment.

## Context

D1 (session 3): lace-platform scored 9.9 adoption because score-adoption.sh only read the best single AI config file. With union-based counting across all `.claude/` files: 80.00. Validated session 4.

D5 (session 3): Considered lowering V1 to 0.4 for Haskell (property tests cover more space). Decided against — V2 and domain profile already capture test quality. V1 is a volume signal.

## Consequences

- **Changed:** score-adoption.sh, adoption-scoring.md
- **Must maintain:** Any new scoring that reads AI config files must use union-based approach.
```

- [ ] **Step 2: Commit**

```bash
git add docs/decisions/005-adoption-counting-and-thresholds.md
git commit -m "docs: ADR-005 union-based adoption counting and V1 threshold decisions"
```

---

### Task 4: Create ADR-006 — Learning signals design

**Files:**
- Create: `docs/decisions/006-learning-signals-design.md`

- [ ] **Step 1: Write ADR from L1-L5 decisions in backlog.md**

```markdown
# ADR-006: Learning signals design (v1)

**Date:** 2026-03-21 · **Status:** Accepted
**Applies to:** future `scripts/aamm/score-learning.sh` (not yet implemented)

## Rule

1. Learning state is tracked **per-repo, not per-dimension**. GitHub data doesn't decompose by SDLC dimension.
2. **90-day window** for static/evolving boundary (aligns with quarterly cycle).
3. **≥2 commits to AI config files** in window to qualify as "evolving" (filters noise).
4. **Two states for v1: static / evolving.** Self-improving (third state) deferred to v2.
5. **"Static" is descriptive, not pejorative.** A stable, well-tuned config is fine.

## Anti-patterns

- **Per-dimension attribution:** Assigning learning state per adoption dimension. AI config serves all dimensions simultaneously.
- **Content-diff analysis:** Comparing file content between commits. Too fragile. Commit count is simpler and sufficient.
- **180-day window:** Too generous for "learning." 180 days answers "is this dead?" not "is this evolving?"

## Context

Session 5 brainstorming. Head of CoE reviewer concurred on per-repo over per-dimension. Self-improving state requires temporal correlation analysis (outcomes → config changes) that needs scan history — deferred to v2.

## Consequences

- **Not yet implemented.** This ADR records design decisions for future implementation.
- **Must maintain:** When implementing, use commit count (not content diff) and 90-day window.
```

- [ ] **Step 2: Commit**

```bash
git add docs/decisions/006-learning-signals-design.md
git commit -m "docs: ADR-006 learning signals design decisions"
```

---

### Task 5: Create domain-profiles.md (extracted from model-spec.md §7)

**Files:**
- Create: `models/ai-augmentation-maturity/domain-profiles.md`
- Modify: `models/ai-augmentation-maturity/model-spec.md` (remove §7)

- [ ] **Step 1: Read model-spec.md §7 (lines 443-487)**

Read the full Domain Profiles section.

- [ ] **Step 2: Create domain-profiles.md with header bloc**

```markdown
# AAMM: Domain Profiles

> Supplementary signals and recommendation framing for specific repo categories. Profiles enrich reports — they don't change universal scores.
> **Depends on:** `README.md` (model overview), `readiness-scoring.md` (V2 sub-signals)
> **Read by:** agents (scanning), teams (understanding their report), CoE (adding new profiles)
> **Implemented in:** `scripts/aamm/collect-readiness.sh` (detection), `scripts/aamm/score-readiness.sh` (profile JSON), `scripts/aamm/generate-report.sh` (report sections)

---
```

Then copy the full §7 content (7.1 High-Assurance Profile, 7.2 Future Profiles) below this header. Preserve all content exactly.

- [ ] **Step 3: In model-spec.md, replace §7 with a pointer**

Replace the full §7 section with:

```markdown
## 7. Domain Profiles

See [domain-profiles.md](domain-profiles.md) for supplementary signals and recommendation framing per domain category (high-assurance, future: web apps, libraries, infra).
```

- [ ] **Step 4: Commit**

```bash
git add models/ai-augmentation-maturity/domain-profiles.md models/ai-augmentation-maturity/model-spec.md
git commit -m "refactor: extract domain profiles from model-spec.md to domain-profiles.md"
```

---

### Task 6: Transform model-spec.md → README.md

**Files:**
- Rename: `models/ai-augmentation-maturity/model-spec.md` → `models/ai-augmentation-maturity/README.md`

- [ ] **Step 1: Add header bloc to the file**

At the top, after the title, add:

```markdown
> What AAMM is, what it measures, and how to read your report. For external teams and CoE leadership.
> **Depends on:** nothing (this is the entry point)
> **Read by:** scanned teams, leadership, CoE operators, agents (for context before scoring)
> **Scoring details in:** `readiness-scoring.md`, `adoption-scoring.md`
> **Domain profiles in:** `domain-profiles.md`
> **Implemented in:** `scripts/aamm/` pipeline
```

- [ ] **Step 2: Remove §8 (Automation Requirements) — it's internal pipeline docs**

Replace §8 with:

```markdown
## 8. Automation

The scan pipeline is fully automated and non-interactive. See `scripts/aamm/` and `CLAUDE.md` for pipeline details. API budget: ≤50 calls per repo.
```

- [ ] **Step 3: Move Design Principles from backlog.md into README.md**

Add before the Glossary appendix:

```markdown
## Design Principles

- Formula = score. Zero discretionary adjustments.
- Domain profiles are supplementary — they enrich, they don't replace.
- AI as adversarial reviewer/challenger, not just code generator.
- Review step catches known blind spots; agent judgment handles the rest.
- Reports must produce action, not just numbers.
- Stages describe not just "is AI present?" but "is AI getting better over time?"
- CMM = foundation, AI Aug = amplifier, Vitals = outcome.
```

- [ ] **Step 4: Rename the file**

```bash
mv models/ai-augmentation-maturity/model-spec.md models/ai-augmentation-maturity/README.md
```

- [ ] **Step 5: Commit**

```bash
git add models/ai-augmentation-maturity/README.md
git add models/ai-augmentation-maturity/model-spec.md  # records deletion
git commit -m "refactor: rename model-spec.md to README.md, extract automation to CLAUDE.md"
```

---

### Task 7: Add header blocs to readiness-scoring.md and adoption-scoring.md

**Files:**
- Modify: `models/ai-augmentation-maturity/readiness-scoring.md`
- Modify: `models/ai-augmentation-maturity/adoption-scoring.md`

- [ ] **Step 1: Add header bloc to readiness-scoring.md**

After the title line, add:

```markdown
> Operational specification for computing Readiness scores. Every signal has a metric-to-score mapping. Every formula is explicit. This file + code in scripts is the source of truth for scoring.
> **Depends on:** `README.md` (model context)
> **Read by:** agents (before scoring), CoE (when updating scoring rules)
> **Implemented in:** `scripts/aamm/score-readiness.sh`, `scripts/aamm/review-scores.sh`
> **Sync rule:** Changes here MUST be reflected in the implementing scripts and vice versa.
```

- [ ] **Step 2: Add header bloc to adoption-scoring.md**

After the title line, add:

```markdown
> Operational specification for computing Adoption scores. Defines dimensions, stages, conditions, and detection layers.
> **Depends on:** `README.md` (model context)
> **Read by:** agents (before scoring), CoE (when updating scoring rules)
> **Implemented in:** `scripts/aamm/score-adoption.sh`, `scripts/aamm/collect-readiness.sh` (adoption signals)
> **Sync rule:** Changes here MUST be reflected in the implementing scripts and vice versa.
```

- [ ] **Step 3: Commit**

```bash
git add models/ai-augmentation-maturity/readiness-scoring.md models/ai-augmentation-maturity/adoption-scoring.md
git commit -m "docs: add dependency headers to scoring spec files"
```

---

### Task 8: Clean backlog.md — backlog only

**Files:**
- Modify: `models/ai-augmentation-maturity/backlog.md`

- [ ] **Step 1: Add header bloc**

Replace current header with:

```markdown
# AAMM — Backlog

> Active work items for the AI Augmentation Maturity Model. Prioritized, not historical.
> **Depends on:** `README.md` (model context), `readiness-scoring.md`, `adoption-scoring.md`
> **Read by:** agents (before starting work), CoE (prioritization)
> **Decisions in:** `docs/decisions/` (ADR format)
> **Session history in:** git log

**Agents: read this FIRST. When completing work, mark items done and remove them.**
```

- [ ] **Step 2: Remove all "Done" sections**

Delete everything between `## Done (2026-03-26, session 7)` and the `## Backlog — Prioritized` section. This is ~120 lines of session history that belongs in git.

- [ ] **Step 3: Remove "Pending Decisions" section**

D1 and D5 are now in ADR-005. D2, D3, D4 remain as backlog items (they're undecided). Move them to backlog if not already there.

- [ ] **Step 4: Remove "Design Principles" section**

Now lives in README.md.

- [ ] **Step 5: Remove "Spec-Decision Sync Protocol" section**

This protocol now lives in CLAUDE.md (Task 9).

- [ ] **Step 6: Keep "Validation Repos" and "Backlog — Prioritized" sections**

These are active tracking data.

- [ ] **Step 7: Commit**

```bash
git add models/ai-augmentation-maturity/backlog.md
git commit -m "refactor: clean backlog.md to backlog only, decisions moved to ADRs, history to git"
```

---

### Task 9: Update CLAUDE.md with model file protocol

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update the AAMM overview section**

Replace the current `## AAMM overview` and `Full methodology` line with:

```markdown
## AAMM model files

```
models/ai-augmentation-maturity/
├── README.md              # What AAMM is (start here)
├── readiness-scoring.md   # How readiness is scored (17 signals, formulas)
├── adoption-scoring.md    # How adoption is scored (5 dimensions, 4 stages)
├── domain-profiles.md     # Supplementary signals per domain (high-assurance, etc.)
├── backlog.md                # Active backlog only
```

**Read order for agents:**
1. `README.md` — understand what AAMM measures and why
2. `readiness-scoring.md` or `adoption-scoring.md` — the scoring spec you need
3. `domain-profiles.md` — if working on domain-specific features

**Source of truth:** Scoring specs (`readiness-scoring.md`, `adoption-scoring.md`) are authoritative on scoring details. `README.md` is authoritative on model purpose and architecture. When they conflict, scoring specs win on details, README wins on intent.
```

- [ ] **Step 2: Replace rule 5 and 6**

Replace:
```
5. **Read `backlog.md` first.** Each model directory has a `backlog.md` with prioritized backlog. Read it before starting work, update it when completing work.
6. **Read model files before scanning.** Load `model-spec.md`, `readiness-scoring.md`, `adoption-scoring.md`.
```

With:
```
5. **Read `backlog.md` first.** Check the active backlog before starting work. Remove completed items.
6. **Read model files before scanning.** Load `README.md` (context), then `readiness-scoring.md` + `adoption-scoring.md` (scoring rules), then `domain-profiles.md` (if domain-relevant).
```

- [ ] **Step 3: Add sync protocol**

Add after the Rules section:

```markdown
## Sync protocol

When changing scoring logic, update ALL of these in the same session:
1. **Scoring spec** (`readiness-scoring.md` or `adoption-scoring.md`) — the rule
2. **Script** (`scripts/aamm/score-*.sh`, `review-scores.sh`) — the implementation
3. **This file** (CLAUDE.md) — if the change affects how agents read/use model files
4. **ADR** (`docs/decisions/`) — if the change is a significant design decision

A change in one without the others is a bug. The scoring spec and script must always agree.
```

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with model file protocol and sync rules"
```

---

### Task 10: Update all references to model-spec.md

**Files:**
- Modify: any file referencing `model-spec.md`

- [ ] **Step 1: Search for all references**

```bash
grep -r "model-spec.md" --include="*.md" --include="*.sh" .
```

- [ ] **Step 2: Update each reference**

- `readiness-scoring.md` line 9: `[model-spec.md](model-spec.md)` → `[README.md](README.md)`
- `adoption-scoring.md`: similar reference update
- `CLAUDE.md`: already updated in Task 9
- Any other files found by grep

- [ ] **Step 3: Commit**

```bash
git add -u
git commit -m "refactor: update all references from model-spec.md to README.md"
```

---

### Task 11: Verify structure and run sanity check

- [ ] **Step 1: Verify final file structure**

```bash
ls -la models/ai-augmentation-maturity/
```

Expected:
```
README.md
readiness-scoring.md
adoption-scoring.md
domain-profiles.md
backlog.md
NEXT_SESSION.md
```

No `model-spec.md` (renamed to README.md).

- [ ] **Step 2: Verify no broken references**

```bash
grep -r "model-spec.md" --include="*.md" --include="*.sh" .
```

Expected: zero results (or only in scan results which are historical).

- [ ] **Step 3: Verify each file has header bloc**

Check README.md, readiness-scoring.md, adoption-scoring.md, domain-profiles.md, backlog.md all start with the `> depends on / read by / implemented in` header.

- [ ] **Step 4: Verify CLAUDE.md references correct files**

Read CLAUDE.md and confirm the model file section points to README.md (not model-spec.md) and includes the sync protocol.
