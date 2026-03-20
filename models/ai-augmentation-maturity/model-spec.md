# AI Augmentation Maturity Model (AAMM)

**Owner:** CoE · Dorin Solomon · **Last updated:** March 2026

---

## 1. Purpose

This model gives visibility into how ready repositories are for AI collaboration (Readiness) and how present AI is in development workflows (Adoption) — per repo and across the organisation. Today we don't have this visibility.

**Why it matters:** AI adoption is not the goal. The goal is faster, more frequent, higher-quality delivery of value to users and business. AI is an amplifier — but it amplifies what exists. A codebase with weak foundations amplified by AI produces problems faster. A solid codebase without AI misses opportunity. This model identifies where each repo sits on that spectrum.

**What the model does:**

- Measures automatically, deterministically, reproducibly — same data = same score, always
- Identifies risks (security, quality) that must be addressed regardless of AI
- Recommends 1-3 actions with the highest return per repo, with measurable targets
- Tracks progress month-over-month

**What the model does NOT do:**

- **Judge teams.** A repo with zero adoption but high readiness is excellent engineering — it just hasn't configured AI tools yet.
- **Measure value delivered.** That is the Engineering Vitals dashboard's job. This model measures AI *presence and readiness*, not AI *business impact*.
- **Require human intervention for calculation.** Everything is computed from GitHub API data.
- **Reward presence of files without real usage.** A CLAUDE.md that nobody uses does not improve a score. Recommendations target measurable outcomes, not checkbox compliance.

### The Three-Model Architecture

| Question | Model | Measures |
|---|---|---|
| "Is your team engineering-mature?" | Capability Maturity Model | Processes, practices, standards |
| "Have you institutionalized AI?" | **This model (AAMM)** | AI readiness + adoption |
| "Is AI delivering value?" | Engineering Vitals | Delivery speed, cycle time, defects |

CMM is the foundation. AAMM is the AI amplifier. Vitals is the outcome measure.

---

## 2. Architecture: Two Axes, One Quadrant

### 2.1 The Two Axes

- **AI Readiness (0-100)** — Is this codebase structurally suitable for productive AI collaboration? Scored via 3 pillars. Independent of whether any AI tools are currently used.
- **AI Adoption (None / Configured / Active / Integrated)** — Is AI actively used in development workflows? Scored per SDLC dimension.

### 2.2 The Quadrant Model

```
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │  FERTILE    │  AI-NATIVE   │
              │  GROUND     │              │
AI Readiness  │  (ready,    │  (target     │
    ↑         │   invest    │   state)     │
              │   here)     │              │
              ├─────────────┼─────────────┤
              │             │  RISKY       │
         Low  │ TRADITIONAL │  ACCELERATION│
              │  (start     │  (AI on weak │
              │   here)     │   foundation)│
              └─────────────┴─────────────┘
```

**Quadrant boundaries:**
- Traditional: Readiness < 45, Adoption composite < 45
- Fertile Ground: Readiness ≥ 45, Adoption composite < 45
- Risky Acceleration: Readiness < 45, Adoption composite ≥ 45
- AI-Native: Readiness ≥ 45, Adoption composite ≥ 45

### 2.3 Design Constraints

1. **Observable only.** Score what can be seen in the repository tree, file contents, and GitHub API. No runtime analysis, no build execution.
2. **Deterministic.** Same repository state = same score. No agent judgment, no discretionary adjustments. Formulas only.
3. **Language-aware.** Universal signals adapt their thresholds per language ecosystem (e.g., Type Coverage scores differently for statically-typed vs dynamically-typed languages). No separate bonus system.
4. **Per-repository.** Organisation-level results are derived from the distribution of repo scores.
5. **Tool-agnostic.** Any AI tool counts equally.
6. **API-feasible.** Every signal must be computable from GitHub API within ~30-50 calls per repo. Signals requiring AST parsing or full source scanning are excluded.
7. **No double-counting.** Each artifact or file contributes to exactly one signal. A Nix flake does not boost multiple pillars.

---

## 3. AI Readiness Axis — 3 Pillars (0-100)

Readiness measures how well the codebase supports productive AI collaboration, regardless of whether any AI tools are currently used. Each pillar answers one question:

| Pillar | Question |
|---|---|
| **Navigate** | Poate AI-ul lucra eficient aici? / Can an AI agent work efficiently here? |
| **Understand** | Poate AI-ul înțelege intent-ul codului? / Can an AI agent understand the code's intent? |
| **Verify** | Poate AI-ul verifica ce produce? / Can an AI agent verify what it produces? |

### Readiness Composite Score

```
Readiness_raw = Navigate * 0.35 + Understand * 0.35 + Verify * 0.30
Readiness = max(0, Readiness_raw - sum(applicable_penalties))
```

### 3.1 Pillar 1: Navigate (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

Can an AI agent find things, understand structure, and work productively in this codebase? Covers code organization, modularity, development tooling, CI/CD, and reproducible environments.

This pillar merges v3's R1 (Structural Clarity) and R4 (Developer Ergonomics) because both answer the same question. Merging eliminates double-counting of CI, lockfiles, and reproducible environment artifacts that appeared in both v3 pillars.

**Signals (each scored 0-100, then weighted):**

| # | Signal | What it measures | Weight |
|---|---|---|---|
| N1 | File organization | Depth and consistency of directory tree | 0.12 |
| N2 | File granularity | Median source file size (small enough for AI context) | 0.13 |
| N3 | Module boundaries | Explicit module/package definitions (workspace, manifests) | 0.15 |
| N4 | Separation of concerns | Distinct directories for distinct responsibilities | 0.12 |
| N5 | Code consistency | Linter and/or formatter configured | 0.13 |
| N6 | CI/CD pipeline | Build + deploy workflows (excludes test execution — scored in Verify) | 0.15 |
| N7 | Reproducible environment | Nix flake, Docker, devcontainer + dependency lockfile | 0.12 |
| N8 | Repo foundations | CODEOWNERS + .gitignore + SECURITY.md | 0.08 |

Weights sum to 1.00.

```
Navigate = sum(signal_score * signal_weight)
```

### 3.2 Pillar 2: Understand (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

Can an AI agent understand what the code does and why? Covers type systems, documentation, architectural context, and data contracts.

**Signals (each scored 0-100, then weighted):**

| # | Signal | What it measures | Weight |
|---|---|---|---|
| U1 | Type safety | Type annotations, strict mode, static typing | 0.30 |
| U2 | Documentation coverage | Doc comments on public functions/types (sampled) | 0.25 |
| U3 | README substance | README sections: description, setup, usage, architecture, contributing | 0.15 |
| U4 | Architecture documentation | ARCHITECTURE.md, docs/, ADRs present | 0.15 |
| U5 | Schema definitions | Explicit data contracts at boundaries (Zod, Protobuf, OpenAPI, etc.) | 0.15 |

Weights sum to 1.00.

```
Understand = sum(signal_score * signal_weight)
```

### 3.3 Pillar 3: Verify (weight: 0.30)

**Poate AI-ul verifica ce produce?**

Can an AI agent verify that what it produces is correct? Without verification, AI produces risk, not value. Covers test infrastructure, CI enforcement, and coverage monitoring.

**HARD GATE:** If zero tests exist, Verify is capped at 15 regardless of other signals.

**Signals (each scored 0-100, then weighted):**

| # | Signal | What it measures | Weight |
|---|---|---|---|
| V1 | Test/source ratio | Test files ÷ source files | 0.30 |
| V2 | Test categorization | Distinct categories (unit, integration, e2e, property) | 0.20 |
| V3 | CI test execution | Tests run on every PR + block merge on failure | 0.30 |
| V4 | Coverage configuration | Coverage tool configured, thresholds in CI | 0.20 |

Weights sum to 1.00. Test existence is a gate, not a weighted signal.

```
Verify_raw = sum(signal_score * signal_weight)

if no_tests_exist:
    Verify = min(15, Verify_raw)
else:
    Verify = Verify_raw
```

### 3.4 Penalties

Penalties reduce the Readiness composite for objectively dangerous behaviors. They are applied AFTER the pillar formula and constraints.

| Penalty | How detected | Impact | Why |
|---|---|---|---|
| PRs merged without review | Sample 10 most recent merged PRs; count those with 0 reviews | **-10** if >30% have 0 reviews | AI-generated changes without review go straight to production |
| No vulnerability monitoring | See graduated scale below | **-10** or **-5** | Unmonitored supply chain = material security risk |
| No branch protection | No required reviews or status checks on default branch | **-5** | Direct push to main = zero safety net |

**Vulnerability monitoring — graduated scale:**

| Situation | Impact | Example |
|---|---|---|
| No scanning tool AND no alternative strategy | **-10** | TS repo with 1000+ npm deps, no Dependabot |
| Scanning tool exists but doesn't cover primary ecosystem | **-5** | Dependabot covers github-actions only, not npm |
| Ecosystem lacks mature scanning tools, but team has dependency management strategy | **-5** | Haskell with index-state pinning + curated package overlay (no mature automated CVE scanning tool exists for Hackage) |
| Scanning tool active for primary ecosystem | **0** | Dependabot npm configured with daily schedule |

The graduated scale recognizes that (a) not all ecosystems have equally mature scanning tooling, and (b) teams that actively manage dependencies (lockfiles, pinning, curated overlays) are in a fundamentally different risk posture than teams that do nothing — even if automated CVE monitoring is absent.

```
Readiness = max(0, Readiness_raw - sum(applicable_penalties))
```

Penalties are deterministic. The vulnerability monitoring penalty has a two-tier gradation; all other penalties are binary.

### 3.5 Cross-Pillar Constraints

Applied before penalties:

```
Readiness_raw = Navigate * 0.35 + Understand * 0.35 + Verify * 0.30

# Constraint 1: No tests → capped Readiness
if Verify < 20:
    Readiness_raw = min(50, Readiness_raw)

# Constraint 2: Weak types → capped Readiness
if type_coverage_score < 50:
    Readiness_raw = min(70, Readiness_raw)

# Then apply penalties
Readiness = max(0, Readiness_raw - sum(applicable_penalties))
```

### 3.6 Risk Flagging (Readiness)

Flagged in the output for visibility. These do NOT affect the score (penalties handle score impact).

| Risk | Condition | Severity |
|---|---|---|
| No SECURITY.md | Missing vulnerability disclosure path | 🟡 Medium |
| No test execution in CI | CI exists but does not run tests | 🟡 Medium |
| No lockfile | No dependency lockfile committed | 🟡 Medium |
| `strict: false` (TypeScript) | TypeScript repo without `strict: true` in tsconfig | 🟡 Medium |

---

## 4. AI Adoption Axis — 5 Dimensions × 4 Stages

### 4.1 Overview

Adoption is measured across 5 dimensions covering the SDLC areas where AI has measurable impact:

| # | Dimension | What it measures |
|---|-----------|-----------------|
| 1 | Code | AI assisting in writing, reviewing, and refactoring code |
| 2 | Testing | AI generating tests and verifying correctness |
| 3 | Security | AI protecting the codebase and supply chain |
| 4 | Delivery | AI improving planning, releases, and predictability |
| 5 | Governance | AI tooling maturity, attribution, review gates (cross-cutting) |

### 4.2 The Four Stages

Every dimension is scored with one of four stages:

| Stage | Label | Meaning |
|---|---|---|
| 0 | **None** | No AI signals for this dimension |
| 1 | **Configured** | Engineering practice active + AI tools configured with project context |
| 2 | **Active** | AI participates visibly in workflows (PRs, commits, reviews) |
| 3 | **Integrated** | AI quality checks run in pipeline, automated gates |

**Stages are cumulative.** A repo cannot be Active without being Configured. If Active-level signals appear without Configured foundation, score as None and annotate: "Active signals emerging without Configured foundation."

### 4.3 The Configured Gate (All Dimensions)

Stage 1 (Configured) requires **both**:
- **(A) Relevant engineering practice is active** — the non-AI infrastructure exists
- **(B) AI config covers this dimension** — AI tools have project-specific context

**AI config quality check — content-category checklist (replaces v3's 50-line threshold):**

An AI config file satisfies Condition B only if it contains substantive content in **at least 3** of these categories:

| Category | Examples |
|---|---|
| Architecture | Module boundaries, dependency relationships, key abstractions |
| Conventions | Naming patterns, formatting, style preferences, preferred approaches |
| Testing | Test frameworks, coverage expectations, test types, test conventions |
| Security | Security-critical modules, trust boundaries, sensitive data flows |
| Delivery | Versioning, changelog format, release process, estimation approach |
| Operations | Deployment topology, monitoring, runbook locations |

Files that do NOT satisfy Condition B:
- Empty or stub files
- Generic boilerplate without project-specific adaptation
- Tool configuration only (e.g., `.mcp.json` with only server definitions, no project context)

**Note:** `.mcp.json` and `.aiignore` count toward Governance Condition A (AI tool presence) but do NOT satisfy Condition B for any dimension.

### 4.4 Condition A and B Per Dimension

| Dimension | Condition A (practice active) | Condition B (AI config covers) |
|---|---|---|
| Code | Linter or formatter active, or code review process (branch protection + CODEOWNERS) | AI config contains architecture overview + coding conventions |
| Testing | Test suite runs in CI | AI config contains test standards, frameworks, coverage expectations |
| Security | Automated dependency or security scanning in CI | AI config identifies security-critical modules OR trust boundaries OR sensitive data flows (any 1 of 3) |
| Delivery | Automated build/release workflow + issue tracking active | AI config documents release process + delivery workflow |
| Governance | At least one AI tool actively configured (config file present) | AI usage expectations documented + `.aiignore` or equivalent for sensitive paths |

### 4.5 Stage-to-Score Mapping

For computing the Adoption composite:

| Stage | Score |
|---|---|
| None | 0 |
| Configured | 33 |
| Active | 66 |
| Integrated | 100 |

### 4.6 Dimension Weights and Composite

| Dimension | Weight | Rationale |
|---|---|---|
| Code | 0.25 | Largest surface area for AI impact on delivery speed and quality |
| Testing | 0.25 | Critical for safe AI-generated changes — without verification, AI is risk |
| Security | 0.20 | Material risk area — security gaps are non-negotiable regardless of AI |
| Delivery | 0.15 | Directly ties to the goal (faster, more frequent delivery) but partly org-constrained |
| Governance | 0.15 | Sustainability and risk management — increasingly important as AI matures |

```
Adoption = Code_score * 0.25 + Testing_score * 0.25 + Security_score * 0.20
         + Delivery_score * 0.15 + Governance_score * 0.15
```

**When a dimension is n/a** (e.g., Delivery for a repo with no release process by design): its weight is redistributed proportionally across remaining dimensions.

### 4.7 Risk Flagging (Adoption)

| Risk | Condition | Severity |
|---|---|---|
| AI usage without governance | Active or Integrated on any dimension but Governance = None | 🔴 High |
| Risky Acceleration | Adoption composite ≥ 45 but Readiness < 45 | 🔴 High |
| AI config stale | AI config file unchanged for 180+ days | 🟡 Medium |
| Active signals without foundation | Stage 2+ signals detected but Stage 1 not met | 🟡 Medium |

---

## 5. Recommendations

Every repo report includes exactly 3 recommendations, ordered by expected return on investment.

### Recommendation Format

Each recommendation must include:

| Field | Purpose |
|---|---|
| **What** | The action to take (specific, not vague) |
| **Why** | Why this matters for delivery speed/quality (connected to the goal) |
| **Measure** | How to know it worked (specific metric + target) |
| **Timeline** | When to expect results (30/60/90 days) |

### Recommendation Principles

1. **Outcome-oriented.** Not "create CLAUDE.md" but "institutionalize AI project context so AI tools have the architectural context needed to generate correct code across your 8-package monorepo. Measure: >10% of commits include AI co-authorship within 60 days."
2. **Highest ROI first.** Energy invested must produce significant return. Fixing a missing npm Dependabot scan on a crypto wallet is higher ROI than improving JSDoc coverage.
3. **Measurable.** Every recommendation has a metric and a target. If it can't be measured in the next scan, it's not a recommendation.
4. **Risks before improvements.** Security and quality risks always rank above adoption improvements.

---

## 6. Output Structure

### 6.1 Org-Level Summary

For leadership and CoE — scannable in 30 seconds:

- Total repos scanned, repos per quadrant
- Readiness distribution per pillar (how many repos above/below threshold)
- Adoption distribution per dimension and stage
- Risks flagged across org (count by severity)
- Top 3 org-wide patterns ("8 of 29 repos lack npm dependency scanning")

### 6.2 Repo-Level Report

For tech leads — actionable in 2 minutes:

- Readiness composite + per-pillar scores (3 numbers)
- Adoption per dimension (5 stages)
- Risks (flagged automatically)
- 3 recommendations with measured outcomes
- Quadrant placement

### 6.3 Evidence Log

For audit and transparency — available on demand:

- Per-signal evidence (file names, PR numbers, API data)
- Formula inputs and outputs for every score
- Full justification for every stage assignment
- Comparison with previous snapshot (delta)

---

## 7. Automation Requirements

### 7.1 API Budget

Target: **≤ 50 GitHub API calls per repo.** For 29 repos: ≤ 1,450 calls (well within 5,000/hour rate limit).

| Call type | Estimated count | Used for |
|---|---|---|
| Repo metadata | 1 | Languages, description, settings |
| Tree (recursive) | 1 | File listing, sizes, structure |
| Config file contents | 5-10 | AI config, tsconfig, package.json, CI workflows |
| README.md | 1 | README substance |
| Recent PRs | 1-2 | AI activity detection, bot authors |
| Recent commits | 1 | Co-authorship patterns |
| Releases | 1 | Changelog signal |
| Source file samples | 10-15 | Doc coverage, naming, type analysis |
| **Total** | **~25-35** | |

### 7.2 Signals Excluded from v3

The following v3 signals are removed because they require AST parsing or excessive API calls:

| Dropped signal | Reason | Replacement |
|---|---|---|
| Circular dependency analysis | Requires 100+ file content reads, language-specific parsing | Module boundary analysis from build manifests |
| Doc comment coverage (precise) | Requires AST to identify public functions | Regex-based heuristic on sampled files |
| `any` count (exhaustive) | Requires scanning all .ts files | Sample-based estimation (15-20 files) |
| `pub` visibility ratio (Rust) | Requires scanning all .rs files | Sample-based estimation |
| Explicit Haskell exports (precise) | Requires parsing module declarations | Sample-based estimation |

### 7.3 Determinism Guarantee

Two agents scoring the same repository at the same point in time MUST produce identical scores. This is achieved by:

1. **No discretionary adjustments.** The formula output IS the score.
2. **Fixed sampling strategy.** When sampling source files, the agent uses a deterministic selection: the N largest files by size from the tree API, plus the N most recently modified. No random sampling.
3. **Explicit thresholds.** Every metric-to-score mapping is a table lookup or formula, never a judgment call.
4. **Content-category checklist for AI config.** Not a line count, not a quality judgment — a checklist of categories present/absent.

---

## 8. Connection to v3

This is AAMM v4. Key changes from v3:

| Aspect | v3 | v4 |
|---|---|---|
| Readiness pillars | 4 (R1-R4) | 3 (Navigate, Understand, Verify) — each with a guiding question |
| Adoption dimensions | 7 | 5 (dropped Ops, merged Release+Delivery) |
| Adoption stages | 0-4 with sub-levels (Low/Mid/High) | 4 labeled stages, no sub-levels (None/Configured/Active/Integrated) |
| Stage 4 | Defined but unfalsifiable | Removed (not measurable in 2026) |
| Language bonuses | +0 to +15 per pillar, per language | Removed. Universal signals are language-aware where needed. |
| Penalties | None | 3 penalties for dangerous behaviors (-5 to -10 on Readiness) |
| AI config quality gate | ~50 lines (guideline, not hard cutoff) | Content-category checklist (≥3 of 6 categories) |
| Agent judgment | ±5 discretionary adjustments per pillar | Eliminated. Formula = score. |
| Double-counting | CI, lockfiles, Nix scored in multiple pillars | Each artifact → exactly one signal |
| Infeasible signals | Circular deps, full-source scanning | Removed or replaced with sampling heuristics |
| Total signals | 29 | 17 + gate |
| Output structure | Score-first | Risks first, outcome-oriented recommendations |
| API budget | Undefined | ≤ 50 calls per repo |
| Reproducibility | ±5 points claimed but mathematically impossible | Identical scores guaranteed by deterministic design |
| MCP config status | Ambiguous (accepted but doesn't count) | Explicit: Governance Condition A only, not Condition B |
| Recommendations | "Create CLAUDE.md" | Measured outcomes with targets and timelines |

---

## Appendix: Glossary

| Term | Definition |
|---|---|
| **Readiness** | How structurally suitable a codebase is for AI collaboration (0-100) |
| **Adoption** | How actively AI tools are used in development workflows |
| **Navigate** | Readiness pillar: can an AI agent find things and work efficiently |
| **Understand** | Readiness pillar: can an AI agent understand code intent |
| **Verify** | Readiness pillar: can an AI agent verify its own output |
| **Condition A** | Engineering practice is active (non-AI infrastructure exists) |
| **Condition B** | AI config contains project-specific context for this dimension |
| **SDLC** | Software Development Lifecycle |
| **MCP** | Model Context Protocol — standard for AI tool integrations |
| **ADR** | Architecture Decision Record |
| **CVE** | Common Vulnerabilities and Exposures |
