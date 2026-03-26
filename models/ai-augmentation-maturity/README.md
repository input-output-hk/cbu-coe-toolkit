# AI Augmentation Maturity Model (AAMM)

> What AAMM is, what it measures, and how to read your report. For external teams and CoE leadership.
> **Depends on:** nothing (this is the entry point)
> **Read by:** scanned teams, leadership, CoE operators, agents (for context before scoring)
> **Scoring details in:** `readiness-scoring.md`, `adoption-scoring.md`
> **Domain profiles in:** `domain-profiles.md`
> **Implemented in:** `scripts/aamm/` pipeline

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

### AI Value Framing

**AI's highest value is as adversarial reviewer, challenger, and auditor — not just code generator.** This applies to ALL repos, but is especially critical for repos with formal specifications, security-critical code, or financial transactions.

For any repo, AI can:
- **Threat model:** "What happens if this input overflows? What if the collection is empty?"
- **Challenge PRs:** "This PR modifies validation logic but adds no test for the new branch."
- **Audit completeness:** "The spec defines 14 rules. Tests cover 11. Missing: rules 7, 12, 14."
- **Review generators:** "This generator never produces inputs >100 items. Distribution check shows 0% coverage on the large-input bracket."
- **Flag performance:** "This fold is O(n×m) per iteration. With production-scale data, that's ~3M operations."
- **Check security:** "This module imports unsafe operations — why? Is the FFI call constant-time?"

AI also drives **quality improvements** across the entire development lifecycle:
- **Documentation quality:** Generating and maintaining Haddock/JSDoc, README sections, ADRs, architecture docs
- **Test quality:** Reviewing generator coverage, suggesting missing properties, scaffolding test infrastructure
- **PR quality:** Structured descriptions, impact analysis, linking to specs/issues
- **Issue quality:** Decomposition, acceptance criteria, linking to code/specs
- **Tooling quality:** CI workflow improvements, build optimization, dependency management

AI also enables **research and discovery**:
- **Competitive/ecosystem research:** "What testing approaches do similar projects (Ethereum, Polkadot, Mina) use that we don't?"
- **Gap analysis:** "What's possible with our codebase structure that we're not doing yet?"
- **Best practice discovery:** "What CI/CD patterns are emerging in the Haskell ecosystem?"
- **Dependency analysis:** "Which of our 28 packages have the most transitive dependencies? Which are most at risk?"

Recommendations should frame AI adoption as a quality multiplier across the entire SDLC — adversarial reviewer on critical code, quality driver on docs/tests/process, research tool for discovery and gap analysis, and code generator on boilerplate and mechanical work.

### Out of Scope

This model operates within a 50-call GitHub API budget with no AST parsing. It fundamentally **cannot**:

- Verify that property test generators produce adversarial inputs
- Verify that formal specifications cover the implementation
- Detect subtle type-level errors in polymorphic code
- Assess cryptographic implementation quality (constant-time, side-channel resistance)
- Measure actual test effectiveness (only test presence and infrastructure)
- Detect consensus rule bugs or serialization mismatches
- Evaluate concurrency safety beyond framework detection

**A high readiness score means "structurally ready for AI collaboration" — NOT "comprehensively secure" or "well-tested."** Teams and leadership should understand this distinction. The model measures structure and infrastructure, not correctness.

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
| Ecosystem lacks mature scanning tools, team manages deps actively | **0** (risk flag only) | Haskell with index-state pinning + curated package overlay. No penalty — the team cannot adopt tooling that doesn't exist. Flagged as risk. |
| Scanning tool active for primary ecosystem | **0** | Dependabot npm configured with daily schedule |

**Principle:** Penalties are for things teams CAN fix but haven't. If no mature scanning tool exists for the ecosystem, the team is not negligent — the gap is flagged as a risk for visibility, not penalized as a failure.

```
Readiness = max(0, Readiness_raw - sum(applicable_penalties))
```

Penalties are deterministic. The vulnerability monitoring penalty has a graduated scale; all other penalties are binary.

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

An AI config file satisfies Condition B only if it contains substantive content in **at least 3 of 8** categories:

| # | Category | Examples |
|---|---|---|
| 1 | Architecture | Module boundaries, dependency relationships, key abstractions, package structure |
| 2 | Conventions | Naming patterns, formatting, style preferences, preferred approaches, anti-patterns |
| 3 | Testing | Test frameworks, coverage expectations, test types, test conventions, how to run tests |
| 4 | Security | Security-critical modules, trust boundaries, sensitive data flows, where AI should NOT generate code |
| 5 | Delivery | Versioning, changelog format, release process, estimation approach, branching strategy |
| 6 | Operations | Deployment topology, monitoring, runbook locations, environment configuration |
| 7 | Build system | How to build, toolchain versions, package manager specifics, environment setup, CI/CD conventions |
| 8 | Formal specification | Which modules implement which spec rules, verification strategy, invariants, spec-to-code mapping |

Categories 7–8 are especially relevant for Haskell/high-assurance repos where build complexity (Nix + Cabal) and formal spec compliance are critical for AI effectiveness. The gate remains at ≥3 of 8 — the additional categories increase opportunity, not the bar.

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

1. **Risks** (first — severity-ordered, including domain-specific risk flags)
2. **Summary** — Readiness composite + per-pillar scores, Adoption per dimension (5 stages), Quadrant placement
3. **Domain Profile** (if applicable) — supplementary signals table, domain risk flags, AI value framing
4. **Readiness breakdown** — per-signal scores with evidence
5. **Adoption breakdown** — per-dimension Condition A/B + stage
6. **Principal Engineer Review** — corrections applied (with reasons), notes flagged for operator attention, adjusted readiness score (if corrections changed it)
7. **Actionable Recommendations** — language-specific, domain-specific, score-driven. Includes: what to do, why, concrete example. For high-assurance repos: AI role table (threat modeler, completeness auditor, generator reviewer, etc.)
8. **Evidence log** — metadata, score summary, formula breakdown

### 6.3 Evidence Log

For audit and transparency — available on demand:

- Per-signal evidence (file names, PR numbers, API data)
- Formula inputs and outputs for every score
- Full justification for every stage assignment
- Comparison with previous snapshot (delta)

---

## 7. Domain Profiles

See [domain-profiles.md](domain-profiles.md) for supplementary signals and recommendation framing per domain category (high-assurance, future: web apps, libraries, infra).

---

## 8. Automation

The scan pipeline is fully automated and non-interactive. See `scripts/aamm/` and the toolkit's `CLAUDE.md` for pipeline details. API budget: ≤50 calls per repo. Determinism guarantee: same repo state = same score, always.

---

## 9. Connection to v3

This is AAMM v4. Key changes from v3:

| Aspect | v3 | v4 |
|---|---|---|
| Readiness pillars | 4 (R1-R4) | 3 (Navigate, Understand, Verify) — each with a guiding question |
| Adoption dimensions | 7 | 5 (dropped Ops, merged Release+Delivery) |
| Adoption stages | 0-4 with sub-levels (Low/Mid/High) | 4 labeled stages, no sub-levels (None/Configured/Active/Integrated) |
| Stage 4 | Defined but unfalsifiable | Removed (not measurable in 2026) |
| Language bonuses | +0 to +15 per pillar, per language | Removed. Universal signals are language-aware where needed. |
| Penalties | None | 3 penalties for dangerous behaviors (-5 to -10 on Readiness) |
| AI config quality gate | ~50 lines (guideline, not hard cutoff) | Content-category checklist (≥3 of 8 categories) |
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

## Design Principles

- Formula = score. Zero discretionary adjustments.
- Domain profiles are supplementary — they enrich, they don't replace.
- AI as adversarial reviewer/challenger, not just code generator.
- Review step catches known blind spots; agent judgment handles the rest.
- Reports must produce action, not just numbers.
- Stages describe not just "is AI present?" but "is AI getting better over time?"
- CMM = foundation, AI Aug = amplifier, Vitals = outcome.

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
