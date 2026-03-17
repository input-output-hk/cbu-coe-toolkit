# AAMM v3 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make AAMM v3 operational — from spec document to executable monthly scan that produces per-repo and org-level reports.

**Architecture:** The v3 spec (`models/ai-augmentation-maturity-v3/model-spec.md`) defines WHAT to measure. This plan implements the HOW: scoring methodology documents, scan prompt, config, and validation against real repos. No application code — all deliverables are markdown/yaml documents that guide an AI agent running monthly scans.

**Tech Stack:** Markdown, YAML, GitHub API (via `$GITHUB_TOKEN`), Claude Code agent execution.

**Spec:** `models/ai-augmentation-maturity-v3/model-spec.md` (1252 lines)

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `models/ai-augmentation-maturity-v3/readiness-scoring.md` | Operational scoring methodology for R1-R4: metric→score mappings, data collection, language bonus calculations |
| Create | `models/ai-augmentation-maturity-v3/adoption-scoring.md` | Step-by-step scoring process per dimension: what to check, in what order, bot names, file patterns, sub-level criteria |
| Create | `models/ai-augmentation-maturity-v3/changelog.md` | Version history documenting v1→v2→v3 evolution |
| Modify | `scans/ai-augmentation/SCAN_PROMPT.md` | Agent-executable scan instructions referencing v3 model and scoring docs |
| Modify | `scans/ai-augmentation/config.yaml` | Signal definitions, tracked repos, AI config file patterns, bot name lists |
| Modify | `CLAUDE.md` | Update model references from v1 to v3, update skill references, deprecate v1 directory |
| Modify | `docs/learnings.md` | Capture insights from v3 design process and pilot assessment |
| Modify | `docs/evolution-log.md` | Record v3 implementation milestone |
| Create | `docs/decisions/002-aamm-v3-architecture.md` | ADR documenting v3 design decisions |

---

## Task 1: Write Adoption Scoring Methodology

The most critical deliverable. Without this, an agent cannot execute a v3 scan on the Adoption axis. This carries forward v1's detailed scoring processes, updated for v3's two-condition gates, 7th dimension, and sub-level definitions.

**Files:**
- Create: `models/ai-augmentation-maturity-v3/adoption-scoring.md`
- Reference: `models/ai-augmentation-maturity/scoring.md` (v1 — the template to follow)
- Reference: `models/ai-augmentation-maturity-v3/model-spec.md` (v3 — stage definitions and two-condition gates)

- [ ] **Step 1: Write the general scoring rules section**

  Carry forward from v1 `scoring.md` lines 1-27 (general rules, overall stage calculation). Update for v3:
  - 7 dimensions instead of 6
  - Sub-levels (Low/Mid/High) per dimension
  - Adoption composite calculation with weights
  - Two-condition gate explanation with examples

- [ ] **Step 2: Write the data collection section**

  Carry forward from v1 `scoring.md` "What to Retrieve from GitHub" section. Add:
  - `.aiignore` / `.cursorignore` file detection (for AI Practices dimension)
  - `AGENTS.md` detection
  - `.claude/commands/` directory detection
  - MCP config file detection (`.mcp.json`, `mcp.json`)
  - Commit history on AI config files (for learning signal assessment)

- [ ] **Step 3: Write Code Quality scoring process**

  Follow v1's structure exactly (numbered decision tree). Update for v3:
  - Stage 1: Add Condition A check (linter/formatter/review process active)
  - Stage 1: Keep Condition B (AI config with quality threshold)
  - Sub-level criteria: define what Low/Mid/High means for CQ at each stage
  - Example: "Stage 1 Low = config covers coding conventions only. Mid = conventions + architecture + patterns. High = comprehensive config + custom commands + approaching Stage 2 signals."

- [ ] **Steps 4-8: Write scoring processes for remaining 5 SDLC dimensions**

  **IMPORTANT: Each dimension MUST follow the same structure as Code Quality (Step 3):**
  1. Numbered decision tree (CHECK STAGE 0 → CHECK STAGE 1 → ... → CHECK STAGE 4)
  2. Condition A check with specific signals to look for and file patterns
  3. Condition B check with specific AI config content requirements
  4. Sub-level criteria table (what Low/Mid/High means at each stage for this dimension)
  5. Example annotations for common scenarios
  6. Replace v1's accepted AI config file list with the complete v3 list from spec Section 7 (17+ files)

  **Per-dimension specifics:**

  **Step 4 — Security:** Carry forward v1's decision tree (already has two-condition gate). Add sub-level criteria table. Update bot names list for Stage 2+ detection.

  **Step 5 — Testing:** Rewrite decision tree to add Condition A (test suite runs in CI — check workflow YAML for test execution step). v1 only checked Condition B. Sub-level criteria: Low = config mentions test framework only. Mid = config covers frameworks + coverage + test types. High = comprehensive + CI integration + approaching Stage 2.

  **Step 6 — Release:** Rewrite to add Condition A (automated build/release workflow — check `.github/workflows/` for release-related YAML). Sub-level criteria per stage.

  **Step 7 — Ops & Monitoring:** Rewrite with: Condition A (monitoring/alerting exists — dashboards, alerting rules, runbooks, OR documented external monitoring). New Stage 2 (AI assists during incidents: AI-generated deployment risk assessments, AI triage comments, AI log summaries visible in issues). n/a annotation for library repos (no production deployment).

  **Step 8 — AI-Assisted Delivery:** Rewrite with: Condition A (issue tracking active — GitHub Issues/Projects, OR external tool documented in AI config). Stage 1 accepts documented external tools (Gap 5). Annotation "delivery tracking partially external" when applicable.

- [ ] **Step 9: Write AI Practices & Governance scoring process (NEW)**

  Entirely new dimension. Define step-by-step:
  - Stage 0-4 checks: what files to look for, what patterns indicate each stage
  - Bot name list for attribution detection
  - Multi-tool detection logic
  - Agent orchestration signal detection (AGENTS.md, .claude/commands/, MCP configs)
  - Sub-level criteria per stage

- [ ] **Step 10: Write learning signal assessment process**

  Define how the agent checks learning signals per dimension:
  - What git history to inspect (commit frequency on AI config files)
  - How to distinguish "static" from "evolving" from "self-improving"
  - Thresholds: e.g., "no commits to AI config in 90+ days = static"
  - How learning affects sub-level assignment

- [ ] **Step 11: Write sub-level determination guidelines**

  Consolidated reference for how to assign Low/Mid/High at each stage for each dimension. This is the table agents will use most during scoring. Format as a lookup matrix:
  ```
  | Dimension | Stage | Low | Mid | High |
  |-----------|-------|-----|-----|------|
  | Code Quality | 0 | No signals | Cond A met | Cond A met + partial Cond B |
  | Code Quality | 1 | Basic config only | Config + patterns + architecture | Comprehensive + custom commands + emerging Stage 2 |
  | ... | ... | ... | ... | ... |
  ```

- [ ] **Step 12: Write minimum viability threshold checking process**

  Carry forward from v1 `scoring.md` the 7 minimum viability thresholds (spec Section 10):
  CI/CD, dependency scanning, security policy, test automation, branch protection, PR review enforcement, issue tracking. These are checked during EVERY assessment and flagged in the report regardless of AI adoption level. Define what API calls to make for each check.

- [ ] **Step 13: Write adoption-side cross-pillar constraints**

  Two constraints from spec Section 6 that affect Adoption scoring:
  - Single AI tool → cap AI Practices sub-level at Mid (check: how many distinct AI tools are configured)
  - Stale AI configs (>6 months unchanged) → dimension cannot be rated above Low sub-level (check: git log on AI config files)

- [ ] **Step 14: Write edge case handling section**

  Carry forward and extend v1's edge cases with v3 additions from spec Section 11:
  - Haskell/Nix repos (infra readiness → Readiness, not Adoption)
  - AI PRs without AI config (Stage 0, demand signal annotation)
  - Inaccessible repos (N/A, exclude from aggregates)
  - No CI/CD (cap at Stage 1 on pipeline-dependent dimensions)
  - Non-GitHub delivery (Stage 1 accepts documented external tools)
  - Multi-language repos (Readiness per-language weighted; Adoption language-agnostic)
  - Library repos (Ops n/a, weight redistributed)
  - Monorepos (single assessment, annotate sub-package differences)

- [ ] **Step 15: Write confidence levels and measurement cadence**

  Include from spec Sections 12-13: High/Medium/Low confidence definitions, monthly snapshot cadence, lookback window rules, historical immutability policy.

- [ ] **Step 16: Write scoring output format section**

  Define JSON output format per dimension including `mapped_score` field. Include the composite calculation formula with a worked example.

- [ ] **Step 17: Commit adoption-scoring.md**

  ```bash
  git add models/ai-augmentation-maturity-v3/adoption-scoring.md
  git commit -m "feat(v3): add adoption scoring methodology

  Step-by-step agent-executable scoring processes for all 7 dimensions.
  Includes two-condition gates, sub-level criteria, learning signal
  assessment, and output format."
  ```

---

## Task 2: Write Readiness Scoring Methodology

Defines how to compute R1-R4 scores operationally. Maps qualitative signal descriptions from the spec to numeric scores.

**Files:**
- Create: `models/ai-augmentation-maturity-v3/readiness-scoring.md`
- Reference: `models/ai-augmentation-maturity-v3/model-spec.md` Sections 3.1-3.4

- [ ] **Step 1: Write metric-to-score mapping tables for R1 (Structural Clarity)**

  For each universal signal, define:
  ```
  File granularity (weight: 0.20):
    Median source file size:
      <150 lines  → 100
      150-300     → 75
      300-500     → 50
      500-1000    → 25
      >1000       → 0 (with per-file penalty)
  ```
  Do this for all 7 universal signals in R1.

- [ ] **Step 2: Write metric-to-score mapping tables for R2 (Semantic Density)**

  Same format for all 8 universal signals in R2. Key mappings needed:
  - Type coverage → score (language-dependent thresholds)
  - Documentation ratio → score
  - README substance → score (per-section scoring)

- [ ] **Step 3: Write metric-to-score mapping tables for R3 (Verification Infrastructure)**

  Same format for all 8 universal signals in R3. Include the hard gate (0 tests → cap at 15).

- [ ] **Step 4: Write metric-to-score mapping tables for R4 (Developer Ergonomics)**

  Same format for all 10 universal signals in R4.

- [ ] **Step 5: Write language bonus calculation section**

  For each language (Haskell, Rust, TypeScript), define:
  - How to detect the primary language
  - How to check each language-specific signal
  - Bonus cap enforcement (+15 per pillar)

- [ ] **Step 6: Write data collection process for Readiness**

  What the agent needs to fetch:
  - Source file listing (for file organization, granularity)
  - README.md content (for README substance)
  - Config file listing (for configuration isolation)
  - Build/CI files (for reproducibility)
  - Language-specific files (cabal, Cargo.toml, tsconfig.json, etc.)

- [ ] **Step 7: Write cross-pillar constraint checking process**

  Step-by-step for each constraint:
  - No tests → cap Readiness at 50
  - No types in typed language → cap R2 at 50
  - Stale AI configs → penalty

- [ ] **Step 8: Write worked example (cardano-ledger)**

  Walk through the complete R1-R4 scoring process for cardano-ledger, showing every signal check and score assignment. Final result should match Readiness 90 from the spec.

- [ ] **Step 9: Commit readiness-scoring.md**

  ```bash
  git add models/ai-augmentation-maturity-v3/readiness-scoring.md
  git commit -m "feat(v3): add readiness scoring methodology

  Metric-to-score mappings for all R1-R4 signals, language bonus
  calculations, cross-pillar constraints, and worked example."
  ```

---

## Task 3: Write Scan Prompt and Config

Makes the monthly scan agent-executable.

**Files:**
- Modify: `scans/ai-augmentation/SCAN_PROMPT.md`
- Modify: `scans/ai-augmentation/config.yaml`

- [ ] **Step 1: Write SCAN_PROMPT.md header and context**

  Define: purpose, model version reference, authentication requirements, output locations.
  Reference the three scoring documents:
  - `models/ai-augmentation-maturity-v3/model-spec.md`
  - `models/ai-augmentation-maturity-v3/readiness-scoring.md`
  - `models/ai-augmentation-maturity-v3/adoption-scoring.md`

- [ ] **Step 2: Write scan execution flow**

  Step-by-step agent instructions:
  1. Read model spec and scoring docs
  2. Load repo list from config.yaml
  3. For each repo: collect data, score Readiness (R1-R4), score Adoption (7 dims), compute composites, determine quadrant, generate Next Steps
  4. Write per-repo JSON to results/
  5. Generate org-level summary
  6. Show results to human operator
  7. On approval, publish to Notion

- [ ] **Step 3: Write per-repo assessment template**

  The exact format the agent should produce per repo, matching Section 8.1 of the spec. Include the human-readable box format AND the JSON output.

- [ ] **Step 4: Write org-level summary template**

  The exact format for the org-level view, matching Section 8.2 of the spec.

- [ ] **Step 5: Write Next Steps generation guidelines**

  How the agent should determine the top 3 actions:
  - Priority ordering: impact/effort ratio
  - Impact calculation: which dimensions advance, composite change
  - Effort estimation guidelines (what qualifies as Low/Medium/High)
  - Template for presenting each step

- [ ] **Step 6: Populate config.yaml**

  **Reference** (do not duplicate) the repo list from `models/config.yaml` — the scan config should point to the master list, not copy it. Add:
  - AI config file patterns (the COMPLETE list from spec Section 7 — 17+ files)
  - Bot name patterns for Stage 2+ detection (copilot[bot], github-copilot[bot], etc.)
  - Language detection heuristics
  - Lookback window configuration (default: since previous snapshot)
  - Previous snapshot reference path
  - Notion publishing reference: point to `notion/page-registry.yaml` and `skills/publish-to-notion/` for the publishing step in the scan flow

- [ ] **Step 7: Commit scan prompt and config**

  ```bash
  git add scans/ai-augmentation/SCAN_PROMPT.md scans/ai-augmentation/config.yaml
  git commit -m "feat(v3): populate scan prompt and config for v3 monthly scans

  Agent-executable scan instructions, repo list, signal patterns,
  and output templates for v3 assessments."
  ```

---

## Task 4: Update Repository Documentation

Update CLAUDE.md, changelog, ADR, and learnings.

**Files:**
- Modify: `CLAUDE.md`
- Create: `models/ai-augmentation-maturity-v3/changelog.md`
- Create: `docs/decisions/002-aamm-v3-architecture.md`
- Modify: `docs/learnings.md`
- Modify: `docs/evolution-log.md`

- [ ] **Step 1: Update CLAUDE.md and handle legacy directory**

  Update the "AI Augmentation Model — Key Concepts" section to reference v3:
  - Two-axis model (Readiness × Adoption)
  - 7 Adoption dimensions (not 6)
  - Stages + Sub-levels
  - Quadrant model
  - Update ALL file references to point to `models/ai-augmentation-maturity-v3/`
  - Update "Known Gaps" section (most gaps resolved in v3)

  **Legacy directory handling:**
  - Add a deprecation notice to `models/ai-augmentation-maturity/model.md` header: "Superseded by v3. See `models/ai-augmentation-maturity-v3/model-spec.md`."
  - Add same notice to `models/ai-augmentation-maturity/scoring.md`
  - Do NOT delete v1 or v2 directories — they serve as reference and contain historical context
  - `models/ai-augmentation-maturity-v2/` gets same deprecation notice
  - CLAUDE.md should point exclusively to v3 paths

- [ ] **Step 2: Write changelog.md**

  Document the evolution:
  - v1.0 → v3.1 (initial) through v3.0 (current)
  - v2.0 (alternative explored, insights merged into v3)
  - v3.0: merged design, key decisions, what changed from v1 and v2

- [ ] **Step 3: Write ADR 002**

  Following `docs/decisions/000-template.md` format. Document:
  - Decision: Adopt AAMM v3 (two-axis model, 7 dimensions, sub-levels)
  - Context: v1 limitations, v2 experiment, comparison results
  - Consequences: new scoring methodology needed, backward compatibility approach

- [ ] **Step 4: Update learnings.md**

  Add dated entries for insights from the v3 design process:
  - CMM vs AI Readiness distinction
  - Two-condition gate rationale
  - Sub-levels vs continuous scores trade-off
  - Cross-cutting dimension justification
  - Next Steps as flywheel pattern

- [ ] **Step 5: Update evolution-log.md**

  Add dated entry: "v3 model spec written, scoring methodology defined, scan prompt populated."

- [ ] **Step 6: Commit all documentation updates**

  ```bash
  git add CLAUDE.md models/ai-augmentation-maturity-v3/changelog.md \
    docs/decisions/002-aamm-v3-architecture.md docs/learnings.md \
    docs/evolution-log.md
  git commit -m "docs: update repository documentation for v3

  Updated CLAUDE.md, added changelog, ADR-002 for v3 architecture,
  captured learnings from design process."
  ```

---

## Task 5: Pilot Assessment — Validate v3 on 2 Repos

Run v3 against 2 real repos (1 Haskell, 1 Rust) to validate that the scoring methodology produces sensible results matching the spec's examples.

**Files:**
- Create: `scans/ai-augmentation/results/2026-03-pilot.json`
- Modify: `docs/learnings.md` (capture validation insights)

- [ ] **Step 1: Run v3 assessment on mithril (Rust)**

  Follow SCAN_PROMPT.md step by step. Use GitHub API with `$GITHUB_TOKEN`.
  Score Readiness (R1-R4) and Adoption (7 dimensions).
  Compare results with spec example (Readiness ~86, Adoption ~18).

- [ ] **Step 2: Evaluate mithril results**

  Check:
  - Do Readiness pillar scores match v2's assessment (within ±5)?
  - Do Adoption stage assignments make sense?
  - Are sub-levels reasonable?
  - Are Next Steps actionable and correctly projected?
  - Does the two-condition gate work as designed for Security?

- [ ] **Step 3: Run v3 assessment on cardano-ledger (Haskell)**

  Same process. Compare with spec example (Readiness ~90, Adoption ~5).

- [ ] **Step 4: Evaluate cardano-ledger results**

  Key validation: Does v3 correctly distinguish this world-class Haskell repo from a throwaway repo? (Must show Readiness ~90 while Adoption ~5.)

- [ ] **Step 5: Document discrepancies and adjust**

  If scoring methodology produces unexpected results:
  - Note the discrepancy in `docs/learnings.md`
  - Determine if the methodology needs adjustment or the expectation was wrong
  - Update scoring docs if methodology is flawed
  - Do NOT adjust to match expected numbers — adjust to match reality

- [ ] **Step 6: Write pilot results JSON**

  Save to `scans/ai-augmentation/results/2026-03-pilot.json`.
  Include both repos with full per-dimension evidence.

- [ ] **Step 7: Commit pilot results and any scoring adjustments**

  ```bash
  git add scans/ai-augmentation/results/2026-03-pilot.json docs/learnings.md
  git commit -m "feat(v3): pilot assessment of mithril and cardano-ledger

  First v3 scan on 2 real repos. Validates scoring methodology
  against expected results from spec examples."
  ```

---

## Task 6: Update Scan Skill

Update the scan-ai-augmentation skill to reference v3.

**Files:**
- Modify: `skills/scan-ai-augmentation/SKILL.md`

- [ ] **Step 1: Read current SKILL.md**

  Understand what's there (may be placeholder).

- [ ] **Step 2: Write/update SKILL.md for v3**

  Skill metadata (name, description, trigger) + reference to SCAN_PROMPT.md.
  Follow Anthropic's three-level skill pattern (metadata → instructions → reference files).

- [ ] **Step 3: Commit**

  ```bash
  git add skills/scan-ai-augmentation/SKILL.md
  git commit -m "feat(v3): update scan skill for v3 model"
  ```

---

## Execution Order and Dependencies

```
Task 1 (Adoption Scoring) ──┐
                             ├──→ Task 3 (Scan Prompt) ──→ Task 5 (Pilot)
Task 2 (Readiness Scoring) ─┘                                    │
                                                                  ▼
Task 4 (Documentation) ──────────────────────────────────→ Task 6 (Skill)
```

- Tasks 1 and 2 are independent — can run in parallel
- Task 3 depends on Tasks 1 and 2 (scan prompt references scoring docs)
- Task 4 is independent of Tasks 1-3 (documentation updates)
- Task 5 depends on Task 3 (needs scan prompt to execute)
- Task 6 depends on Tasks 3 and 4

**Estimated effort:** Tasks 1-2 are the largest (~60% of total work). Task 5 requires GitHub API access.
