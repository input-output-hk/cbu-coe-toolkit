# AI Augmentation Maturity Model v3 (AAMM-v3)

**Owner:** CoE · Dorin Solomon · **Status:** Draft v3.0 · **Last updated:** March 2026

---

## 1. Purpose and Philosophy

This model measures **how well AI is institutionalized** in a software repository — not whether individual developers use AI tools, but whether the repository and its workflows are structured for durable, compounding AI value.

**This model is educational, not evaluative.** Stages describe what good looks like so teams know what to focus on next. They are not performance scores, not targets with deadlines, and not grounds for comparison between teams working in different contexts.

### What This Model Is NOT

- **Not a capability maturity model (CMM).** CMM measures engineering practices and team capability broadly. This model measures AI-specific readiness and adoption.
- **Not an engineering vitals dashboard.** Vitals measures business outcomes (delivery speed, defect rates). This model measures AI presence and integration.
- **Not a judgment.** A Stage 0 repo with Readiness 90 (like cardano-ledger) is world-class engineering — it just hasn't configured AI tools yet.

### The Three-Model Architecture

| Question | Model | Measures |
|---|---|---|
| "Is your team engineering-mature?" | CMM | Processes, practices, standards, team capability |
| "Have you institutionalized AI?" | **This model (AAMM-v3)** | AI readiness + adoption lifecycle |
| "Is AI delivering value?" | Engineering Vitals | Delivery speed, cycle time, defect rates |

The three models connect: CMM is the organizational foundation. AAMM is the AI amplifier. Vitals is the outcome measure. The power is in the connection, not any single model.

### Why AI Readiness Lives Here, Not in CMM

CMM and AI Readiness measure the same data through different lenses. CMM asks "is this good engineering?" AAMM asks "can an AI agent work effectively here?" Example: test coverage — CMM measures whether tests exist and are good; AI Readiness measures whether tests allow an AI agent to verify its own output. Same metric, different interpretation.

The quadrant model requires co-location. Readiness + Adoption side-by-side is what makes the model actionable. "Fertile Ground" (Readiness 90, Adoption 1) immediately says "invest here, ROI is maximum." If Readiness lives in CMM, you need cross-model joins to reconstruct this insight — fragile and hard to communicate.

There will be natural overlap between CMM and AI Readiness (modularity, test coverage, type safety appear in both). This is acceptable as long as the framing is clear: CMM evaluates the engineering practice, AI Readiness evaluates the AI-collaboration impact of that practice.

---

## 2. Architecture: Two Axes, One Quadrant

### 2.1 The Two Axes

- **AI Readiness (0-100)** — Is this codebase *structurally suitable* for productive AI collaboration? Modularity, types, tests, documentation, deterministic builds. Independent of whether any AI tools are currently used.
- **AI Adoption** — Is AI *actively used* in development workflows on this codebase? Configuration, workflow integration, pipeline automation, governance. Measured per SDLC dimension with stages (0-4) and sub-levels.

These axes are independent. A greenfield Haskell project with strong types and property-based tests but no AI config is high-readiness, zero-adoption. A legacy JavaScript monolith with Copilot everywhere but no tests is low-readiness, moderate-adoption.

### 2.2 The Quadrant Model

```
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │  FERTILE    │  AI-NATIVE   │
              │  GROUND     │              │
AI Readiness  │             │  (target     │
    ↑         │  (ready,    │   state)     │
              │   just add  │              │
              │   tooling)  │              │
              ├─────────────┼─────────────┤
              │             │  RISKY       │
         Low  │ TRADITIONAL │  ACCELERATION│
              │             │              │
              │  (start     │  (AI on weak │
              │   here)     │   foundation)│
              └─────────────┴─────────────┘
```

**Quadrant boundaries:**
- Traditional: Readiness < 45, Adoption < 45
- Fertile Ground: Readiness ≥ 45, Adoption < 45
- Risky Acceleration: Readiness < 45, Adoption ≥ 45
- AI-Native: Readiness ≥ 45, Adoption ≥ 45

**Sub-levels within each quadrant** (Low/Mid/High) based on the dominant axis score:
- Low: dominant axis score 45–60
- Mid: dominant axis score 61–75
- High: dominant axis score 76–100

### 2.3 Design Constraints

1. **Observable only.** Score what can be seen in the repository tree, file contents, and GitHub API. No runtime analysis, no build execution.
2. **Language-aware.** Signals are mapped per language ecosystem. The model adapts its expectations based on detected primary language(s).
3. **Composable.** Multi-language repos score each language independently on Readiness, then weighted-average by LOC proportion. Adoption dimensions are language-agnostic.
4. **Assessed per repository.** Organisation-level maturity is derived from the distribution of repo scores.
5. **Tool-agnostic.** GitHub Copilot, Claude Code, Cursor, Gemini, or any other AI tool count equally.
6. **Agent-scored with evidence.** Unlike v2 (which aimed for fully deterministic formula-only scoring), v3 accepts that sub-level assignment requires agent judgment. Reproducibility is achieved through mandatory evidence recording per dimension — the agent must cite specific files, PR numbers, and signals that justify each score. Two agents scoring the same repo should agree on stages; sub-levels may vary within one step.

---

## 3. AI Readiness Axis — 4 Pillars (0-100)

Readiness measures how well the codebase supports productive AI collaboration regardless of whether any AI tools are currently used.

### Readiness Composite Score

```
Readiness = R1 * 0.30 + R2 * 0.30 + R3 * 0.25 + R4 * 0.15
```

### Pillar R1: Structural Clarity (weight: 30%)

**What it measures:** Can an AI agent (or a new human developer) understand where things are and how they connect?

#### Universal Signals

| Signal | Metric | Scoring |
|--------|--------|---------|
| **File organization** | Depth and consistency of directory tree | 3+ levels of meaningful nesting = good. Flat dump of files at root = poor. |
| **File granularity** | Median source file size (lines) | <150 lines median = excellent. 150-300 = good. 300-500 = acceptable. >500 = poor. Files >1000 lines penalized individually. |
| **Module boundaries** | Presence of explicit module/package definitions | Package files, module exports, public API surfaces explicitly defined. |
| **Separation of concerns** | Distinct directories for distinct responsibilities | Routes/handlers separated from business logic separated from data access. |
| **Circular dependency risk** | Import/dependency graph structure | Select the 10 largest source files, trace imports 2 levels deep. Cycles = penalty. |
| **Entry point clarity** | How easy is it to find where execution starts | main/index/app file identifiable. For libraries: clear public API module. |
| **Configuration isolation** | Config separated from logic | Config files in dedicated locations, not hardcoded in source. |

#### Language-Specific Signals (Haskell)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| Module hierarchy | `src/` directory with meaningful module tree | +5 for 3+ levels of module nesting |
| Explicit exports | Modules export specific symbols, not `module X where` (export-all) | +8 for >70% of modules having explicit exports |
| Cabal/Stack structure | Well-organized `.cabal` file with library + executable + test stanzas | +5 |
| Internal modules | `Internal` module pattern for implementation hiding | +3 |
| Package boundaries | Multi-package project (`cabal.project` with multiple packages) | +5 |
| Typeclass discipline | Typeclasses defined in own modules, orphan instances minimized | +3 |

#### Language-Specific Signals (Rust)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| Workspace structure | `Cargo.toml` with `[workspace]` and multiple crates | +5 for well-split workspace |
| Crate granularity | Number of crates vs total LOC | Reward: <2000 LOC/crate average |
| `pub` visibility discipline | Ratio of `pub` to total functions/structs | <40% pub = disciplined encapsulation |
| Module tree | Clear `mod` declarations, not `#[path]` hacks | +3 for clean module tree |
| Feature flags | `[features]` in Cargo.toml | +3 for feature-gated functionality |
| Error type hierarchy | Custom error types with `thiserror`/manual impl | +5 for structured error types |

#### Language-Specific Signals (TypeScript)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| `tsconfig.json` path aliases | `paths` configured → clean imports | +5 if present |
| Barrel files (`index.ts` re-exports) | Explicit public API per module | +3 per module with barrel |
| Monorepo workspace config | `pnpm-workspace.yaml`, `nx.json`, `turbo.json` | +5 if well-structured |
| Shared types package | `packages/types/` or `@org/types` | +5 if present |
| Layered architecture evidence | Directories like `domain/`, `application/`, `infrastructure/` | +8 if 3+ layers identifiable |

#### R1 Scoring Formula

```
R1_raw = (
    file_organization_score      * 0.15 +
    file_granularity_score       * 0.20 +
    module_boundaries_score      * 0.20 +
    separation_of_concerns_score * 0.20 +
    circular_dep_risk_score      * 0.10 +
    entry_point_clarity_score    * 0.05 +
    config_isolation_score       * 0.10
)

R1_language_bonus = sum(language_specific_signals)  # capped at +15

R1 = min(100, R1_raw + R1_language_bonus)
```

---

### Pillar R2: Semantic Density (weight: 30%)

**What it measures:** How much *meaning* is encoded in the codebase beyond the executable logic?

#### Universal Signals

| Signal | Metric | Scoring |
|--------|--------|---------|
| **Type coverage** | Proportion of code with type annotations/inference | Language-dependent threshold. |
| **Schema definitions** | Explicit data shape definitions at system boundaries | Protobuf, OpenAPI, JSON Schema, GraphQL SDL, Pydantic, Zod, etc. |
| **Documentation ratio** | Doc comments per public function/type | >70% documented = excellent. 40-70% = good. <40% = poor. |
| **README substance** | README length and structural quality | Sections scored: description, setup, usage, architecture, contributing. 1 point per meaningful section. |
| **ADRs or design docs** | `docs/`, `adr/`, `decisions/`, `rfcs/` | Count and recency. |
| **Naming quality** | Average identifier length and vocabulary | Heuristic: avg identifier length 8-25 chars = good. |
| **API documentation** | OpenAPI/Swagger, generated docs, API examples | Presence and completeness. |
| **CHANGELOG** | CHANGELOG.md or HISTORY.md | Present + follows Keep a Changelog or Conventional = bonus. |

#### Language-Specific Signals (Haskell)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| `-Wall -Werror` in ghc-options | Strict warnings | +8 |
| Haddock documentation coverage | Haddock comments on exported symbols | +8 for >70% coverage |
| Type signatures on all top-level bindings | Explicit types | +10 (critical in Haskell) |
| Newtypes for domain concepts | `newtype` usage vs raw primitives | +5 |
| `DerivingStrategies` extension | Explicit deriving strategy | +3 |
| Refined types or smart constructors | `refined` library or manual smart constructors | +5 |

#### Language-Specific Signals (Rust)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| `#![deny(missing_docs)]` | Enforced documentation | +10 |
| `#![forbid(unsafe_code)]` or scoped `unsafe` | Safety discipline | +5 for forbid, +3 for minimal scoped unsafe |
| Doc comments (`///`) coverage | Doc comments on pub items | +8 for >70% coverage |
| `clippy.toml` or `#![warn(clippy::all)]` | Lint discipline | +5 |
| Type-state pattern usage | Complex state machines encoded in types | +5 |
| `serde` derive with explicit attributes | Structured serialization | +3 |

#### Language-Specific Signals (TypeScript)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| `strict: true` in tsconfig | Full strict mode enabled | +10 (critical) |
| `noUncheckedIndexedAccess` | Extra strictness | +3 |
| Zod/io-ts/Valibot schemas | Runtime validation at boundaries | +8 |
| JSDoc on exported functions | Documentation beyond types | +5 for >50% coverage |
| Generic type usage | Meaningful generics | +3 if used in >10% of type defs |
| `any` count | Explicit `any` usage | -2 per 10 occurrences (cap -10) |
| Type-only imports | `import type { }` usage | +2 |

#### R2 Scoring Formula

```
R2_raw = (
    type_coverage_score         * 0.25 +
    schema_definitions_score    * 0.15 +
    documentation_ratio_score   * 0.20 +
    readme_substance_score      * 0.10 +
    design_docs_score           * 0.10 +
    naming_quality_score        * 0.10 +
    api_documentation_score     * 0.05 +
    changelog_score             * 0.05
)

R2_language_bonus = sum(language_specific_signals)  # capped at +15

R2 = min(100, R2_raw + R2_language_bonus)
```

---

### Pillar R3: Verification Infrastructure (weight: 25%)

**What it measures:** Can changes be validated automatically?

#### Universal Signals

| Signal | Metric | Scoring |
|--------|--------|---------|
| **Test existence** | Test directory or test files present | Binary gate: 0 tests = hard cap R3 at 15. |
| **Test/source ratio** | Number of test files ÷ number of source files | >0.7 = excellent. 0.4-0.7 = good. 0.2-0.4 = fair. <0.2 = poor. |
| **Test categorization** | Distinct unit/integration/e2e directories or naming | Each category present = +points. |
| **Test framework config** | Dedicated config file for test runner | Presence of jest.config, pytest.ini, etc. |
| **Coverage configuration** | Coverage tool configured | Config present = +points. |
| **CI test execution** | Tests run in CI pipeline | Evidence in workflow files. |
| **Test fixtures/factories** | Organized test data | fixtures/, factories/ directories. |
| **Build reproducibility** | Lockfile present + Dockerfile/Nix/devcontainer | Lockfile = baseline. Container = bonus. |

#### Language-Specific Signals (Haskell)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| `test-suite` stanza in .cabal | Test suite defined | +5 (gate: required for >30 score) |
| HSpec / Tasty / HUnit | Test framework | +5 |
| QuickCheck / Hedgehog properties | Property-based testing | +8 |
| `hpc` or coverage config | Coverage tooling | +3 |
| `stack test` or `cabal test` in CI | CI test execution | +3 |
| Doctest (`doctest` package) | Executable documentation | +5 |
| Golden tests | `tasty-golden` or similar | +3 |

#### Language-Specific Signals (Rust)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| `#[cfg(test)] mod tests` | Inline test modules | +5 |
| `tests/` integration test directory | Separate integration tests | +5 |
| `proptest` or `quickcheck` in dev-dependencies | Property testing | +5 |
| `criterion` or `divan` in dev-dependencies | Benchmark suite | +3 |
| `cargo-tarpaulin` or `llvm-cov` in CI | Coverage tooling | +3 |
| `cargo clippy` in CI | Lint as verification | +3 |

#### Language-Specific Signals (TypeScript)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| Jest/Vitest/Mocha config | Test framework present | +5 (gate) |
| `*.test.ts` or `*.spec.ts` convention | Consistent naming | +3 |
| `@testing-library/*` | Component testing | +3 for UI projects |
| Playwright/Cypress config | E2E testing | +5 |
| `package.json` test script | `npm test` works | +3 |
| Coverage tooling | `c8` / `istanbul` / `vitest --coverage` | +3 |

#### R3 Scoring Formula

```
R3_raw = (
    test_existence_gate          *  ∞   +   # Hard gate: 0 tests → cap at 15
    test_source_ratio_score      * 0.25 +
    test_categorization_score    * 0.15 +
    test_framework_config_score  * 0.10 +
    coverage_config_score        * 0.10 +
    ci_test_execution_score      * 0.20 +
    test_fixtures_score          * 0.10 +
    build_reproducibility_score  * 0.10
)

R3_language_bonus = sum(language_specific_signals)  # capped at +15

R3 = min(100, R3_raw + R3_language_bonus)
```

---

### Pillar R4: Developer Ergonomics (weight: 15%)

**What it measures:** How smooth is the development loop?

#### Universal Signals

| Signal | Metric | Scoring |
|--------|--------|---------|
| **Linter configured** | Language-appropriate linter with config file | Config present + rules customized |
| **Formatter configured** | Auto-formatter with config | Presence of prettier, black, rustfmt, ormolu config |
| **Pre-commit hooks** | `.husky/`, `.pre-commit-config.yaml`, `lefthook.yml` | Hooks present and not empty |
| **Editor config** | `.editorconfig` or IDE-specific settings committed | Present = +points |
| **CI/CD pipeline** | Workflow files present and non-trivial | Present + recent execution |
| **Reproducible environment** | Dockerfile, docker-compose, devcontainer.json, Nix flake | Any reproducibility mechanism |
| **Task runner** | Makefile, Taskfile, Justfile, scripts/ directory | Standardized way to run common tasks |
| **Env template** | `.env.example` or `.env.template` | Documented environment variables |
| **Dependency lockfile** | Appropriate lockfile present and committed | Present and committed |
| **Git hygiene** | `.gitignore` comprehensive, no large binaries tracked | Comprehensive .gitignore |

#### Language-Specific Signals (Haskell)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| `ormolu` / `fourmolu` / `stylish-haskell` config | Formatter | +3 |
| `hlint.yaml` or `.hlint.yaml` | Linter | +5 |
| `stack.yaml` or `cabal.project` | Build tool config | +3 |
| `hie.yaml` or HLS config | IDE/LSP support | +3 |
| Nix flake for Haskell build | Reproducible builds | +8 |
| `ghcid` config or equivalent | Fast feedback loop | +3 |

#### Language-Specific Signals (Rust)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| `rustfmt.toml` or `.rustfmt.toml` | Formatter configured | +3 |
| `clippy.toml` | Lint customization | +3 |
| `rust-toolchain.toml` | Toolchain pinning | +5 |
| `cargo-make` or `just` | Task runner | +3 |
| `deny.toml` (cargo-deny) | Dependency license/advisory checking | +5 |

#### Language-Specific Signals (TypeScript)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| Prettier config | `.prettierrc` / `prettier.config.js` | +3 |
| ESLint config | `eslint.config.js` / `.eslintrc.*` | +3 |
| `engines` field in `package.json` | Node version pinned | +2 |
| `volta` or `fnm` or `.nvmrc` | Node version management | +3 |
| `turbo.json` or `nx.json` task caching | Build caching in monorepo | +3 |

#### R4 Scoring Formula

```
R4_raw = (
    linter_score              * 0.15 +
    formatter_score           * 0.10 +
    precommit_hooks_score     * 0.10 +
    editor_config_score       * 0.05 +
    ci_cd_score               * 0.20 +
    reproducible_env_score    * 0.15 +
    task_runner_score         * 0.10 +
    env_template_score        * 0.05 +
    lockfile_score            * 0.05 +
    git_hygiene_score         * 0.05
)

R4_language_bonus = sum(language_specific_signals)  # capped at +15

R4 = min(100, R4_raw + R4_language_bonus)
```

---

## 4. AI Adoption Axis — 7 Dimensions

### 4.1 Overview

Adoption is measured across **7 dimensions** — 6 SDLC dimensions plus one cross-cutting dimension:

| # | Dimension | What it measures |
|---|-----------|-----------------|
| 1 | Code Quality | AI understanding and improving the codebase |
| 2 | Security | AI protecting the codebase and supply chain |
| 3 | Testing | AI verifying correctness |
| 4 | Release | AI automating delivery to users |
| 5 | Ops & Monitoring | AI supporting production reliability |
| 6 | AI-Assisted Delivery | AI improving planning and predictability |
| 7 | AI Practices & Governance | AI tooling maturity, governance, orchestration *(cross-cutting)* |

### 4.2 Scoring: Stages + Sub-Levels

Each dimension carries **two values**:

- **Stage (0-4):** The highest stage fully achieved. Cumulative — a repo cannot score Stage 2 without satisfying Stage 1.
- **Sub-level (Low / Mid / High):** Within-stage progress.

```
Sub-level definitions (Stages 1-4):
  Low  — just cleared the stage gate, minimal signals beyond requirement
  Mid  — solid presence, multiple active signals within this stage
  High — approaching next stage, strong emerging signals for the next level

Sub-level definitions (Stage 0):
  (blank) — neither condition met, no relevant signals at all
  Low     — one condition has minimal or weak signals
  Mid     — one condition substantially met (practice active but no AI config,
            or AI config present but practice not active)
  High    — one condition fully met and other has emerging signals
```

**Mapping to 0-100 for Adoption composite:**

```
Stage 0: Low=0   Mid=7   High=13
Stage 1: Low=20  Mid=27  High=33
Stage 2: Low=40  Mid=47  High=53
Stage 3: Low=60  Mid=67  High=73
Stage 4: Low=80  Mid=90  High=100
```

**Adoption composite** = weighted average of mapped scores across 7 dimensions.

**When a dimension is n/a** (e.g., Ops/Monitoring for a library repo): its weight is redistributed proportionally across the remaining dimensions. The remaining weights are divided by (1 - excluded_weight) to maintain a sum of 1.0. Example: if Ops (0.10) is excluded, Code Quality weight becomes 0.18/0.90 = 0.200.

### 4.3 Dimension Weights

| Dimension | Weight | Rationale |
|-----------|--------|-----------|
| Code Quality | 0.18 | Foundation of AI workflow integration |
| Security | 0.15 | Critical for trust and production safety |
| Testing | 0.18 | AI verification capability |
| Release | 0.12 | Important but often org-constrained |
| Ops & Monitoring | 0.10 | Many repos are libraries, not services |
| AI-Assisted Delivery | 0.12 | Directly ties to business value |
| AI Practices & Governance | 0.15 | Increasingly important as AI matures |

### 4.4 Stage 1 Two-Condition Gate (All Dimensions)

Stage 1 on every dimension requires **both**:
- **(A) Relevant engineering practice is active** — the non-AI infrastructure exists and runs
- **(B) AI config covers that dimension** — AI tools have project context for this area

| Dimension | Condition A (practice active) | Condition B (AI config) |
|-----------|-------------------------------|------------------------|
| Code Quality | Linter/formatter or review process active | AI config covers coding conventions, architecture, module boundaries |
| Security | Automated dependency/security scanning in CI | AI config identifies security-critical modules, trust boundaries, sensitive data flows |
| Testing | Test suite runs in CI | AI config documents test standards, frameworks, coverage expectations, test types |
| Release | Automated build or release workflow exists | AI config documents versioning conventions, changelog format, release process |
| Ops & Monitoring | Monitoring/alerting infrastructure exists | AI config documents deployment topology, runbook locations, escalation paths |
| Delivery | Issue tracking active (GitHub Issues/Projects, or documented external tool) | AI config documents delivery workflow, estimation approach, DoD, sprint cadence |
| AI Practices | At least one AI tool actively configured | AI usage expectations documented, `.aiignore` for sensitive paths |

If only condition A is met: Stage 0 with annotation "infrastructure ready, no AI config."
If only condition B is met: Stage 0 with annotation "AI config present but practice not active."

### 4.5 Cumulative Enforcement

Stage 2 signals without Stage 1 foundation: score as **Stage 0** with annotation "Stage 2 signals emerging without Stage 1 foundation." This is demand signal, not a failure — record it and recommend completing Stage 1 first.

### 4.6 Learning Signals

Learning is not a separate axis — it enriches the sub-level assessment per dimension.

**Annotations:**
- **static** — AI config written once, no meaningful updates since creation
- **evolving** — AI config updated based on usage (commit history shows refinement, custom commands added, feedback patterns documented)
- **self-improving** — Automated feedback loops, cross-repo propagation, config evolves based on outcomes

**Impact on sub-levels:**
- A dimension with `static` learning cannot be rated `High` within its stage
- A dimension with `self-improving` learning gets a sub-level boost (Low → Mid, Mid → High)

**How the agent checks learning:**
- Commit history on AI config files: frequency and substance of updates since creation
- Custom commands/skills: present? showing iteration in commit history?
- Feedback patterns: documented in config ("when X doesn't work, do Y")?
- Cross-repo patterns: does config reference or inherit from other repos?

### 4.7 Scoring Methodology (Companion Documents)

This spec defines **what** each stage and sub-level means. The operational detail of **how** to score — what to fetch from GitHub, what API calls to make, what string patterns to match, step-by-step decision trees per dimension — will be defined in companion documents:

- **`readiness-scoring.md`** — How to compute R1-R4 scores: metric-to-score mappings for each universal signal (e.g., median file size <150 lines = 100, 150-300 = 75, 300-500 = 50, >500 = 25), data collection process, language bonus calculations.
- **`adoption-scoring.md`** — Step-by-step scoring process per dimension: what files to check, what bot names to search for, what workflow patterns indicate each stage. Carries forward v1's scoring methodology structure with updates for v3's two-condition gates and 7th dimension.

Until these companion documents are written, v1's `scoring.md` serves as the reference for Adoption dimension scoring methodology, with the understanding that v3's two-condition gates and AI Practices dimension extend it.

---

## 5. Stage Definitions per Dimension

### 5.1 Code Quality

| Stage | What It Looks Like |
|-------|--------------------|
| **0** | Code review is entirely human. No AI awareness in the repo. |
| **1** | *Two conditions:* (A) Linter/formatter or code review process active. (B) AI config provides project context: coding conventions, architecture overview, module boundaries, preferred patterns, documentation standards. An AI assistant opening this repo understands the project before the developer types anything. |
| **2** | AI participates visibly in the development workflow: reviewing PRs for style/complexity/duplication, suggesting documentation improvements, flagging missing docs, opening fix or refactoring PRs, enforcing PR template compliance, co-authoring commits. AI contributions are visible in project history. |
| **3** | AI quality checks run in the pipeline on every push. Quality gates can block merges. AI-generated refactoring suggestions surface automatically. Documentation gaps detected in CI. Flaky tests diagnosed without human investigation. AI-generated bug fix PRs opened from issue analysis. |
| **4** | All coding standards enforced by AI across the org. Refactoring PRs raised on schedule. Documentation maintained automatically. AI effectiveness improves based on accumulated team feedback — accepted and rejected suggestions refine the AI's understanding of what this team considers quality. |

### 5.2 Security

| Stage | What It Looks Like |
|-------|--------------------|
| **0** | Security relies on manual audits or traditional scanning only. No AI config for security context. |
| **1** | *Two conditions:* (A) Automated dependency/security scanning active in CI (Dependabot, Renovate, CodeQL, Trivy, Snyk, cargo-deny, cargo-audit, cabal-audit). (B) AI config identifies security-critical modules, trust boundaries, and sensitive data flows. |
| **2** | AI surfaces vulnerabilities during code review — flagging CVEs in dependencies, identifying risky patterns in PRs, providing fix suggestions with context. |
| **3** | AI security analysis runs in pipeline and can block merges on new vulnerabilities. Auto-remediation PRs opened for known CVEs. AI-powered SAST scans every push. Continuous security scanning runs against production code. |
| **4** | Architecture continuously audited for threats — AI threat modelling runs against codebase and dependencies. CVE remediation automated within policy. Supply chain integrity verified on every build. |

### 5.3 Testing

| Stage | What It Looks Like |
|-------|--------------------|
| **0** | All tests are authored manually. No AI involvement in testing. |
| **1** | *Two conditions:* (A) Test suite runs in CI. (B) AI config documents test standards, frameworks, coverage expectations, and test types (unit, integration, property-based, E2E). |
| **2** | AI identifies untested code paths during review. AI suggests test cases and edge cases in PR comments. AI reviews coverage at PR and project level. AI flags missing test types. |
| **3** | AI-generated tests committed to repo and maintained. Coverage enforced per module in CI. Test framework improvements proposed by AI. Mutation testing or equivalent identifies dead assertions. |
| **4** | Test suites generated from types, specs, and formal properties. Mutation testing automated and gated. AI closes coverage gaps autonomously. Test debt surfaces as scheduled PRs. |

### 5.4 Release

| Stage | What It Looks Like |
|-------|--------------------|
| **0** | Changelogs, version bumps, and release notes are manual. |
| **1** | *Two conditions:* (A) Automated build or release workflow exists in CI. (B) AI config documents release process, versioning conventions, and changelog format. |
| **2** | AI assists with release preparation — generating draft changelogs from merged PRs, summarising changes for release notes, flagging breaking changes during review. Humans still drive the release. |
| **3** | AI generates changelogs, version bumps, and release notes automatically. Regression gating runs before merge to main. Breaking changes detected and flagged without human investigation. |
| **4** | Fully automated release pipeline: AI handles versioning, changelogs, regression gating, and rollback decisions within defined policy. Humans approve outcomes, not individual steps. |

### 5.5 Ops & Monitoring

| Stage | What It Looks Like |
|-------|--------------------|
| **0** | Monitoring is manual dashboards, reactive alerting, and human-driven incident response. |
| **1** | *Two conditions:* (A) Monitoring/alerting infrastructure exists (dashboards, alerting rules, runbooks). (B) AI config documents deployment topology, runbook locations, alert patterns, escalation paths. |
| **2** | AI assists during incidents — summarising logs, correlating alerts, suggesting root causes from historical patterns. AI-generated deployment risk assessments on infrastructure PRs. AI triage comments correlating recent deploys with observed issues. AI contributions visible in incident channels or issue comments. |
| **3** | AI anomaly detection active in staging or production. Alerting thresholds calibrated by AI baselines. AI-assisted incident triage reduces mean time to diagnosis. |
| **4** | Self-healing runbooks execute autonomously within defined policy. AI drafts post-mortems and proposes architectural mitigations. Engineers review AI decisions, not individual alerts. |

*Note: Repos that are libraries (not services) may score Stage 0 on Ops/Monitoring with annotation "(n/a — library, not a service)." This is informational, not a gap.*

### 5.6 AI-Assisted Delivery

| Stage | What It Looks Like |
|-------|--------------------|
| **0** | Work planning, decomposition, and estimation are entirely manual. No AI involvement. |
| **1** | *Two conditions:* (A) Issue tracking active — GitHub Issues/Projects enabled, or external tool documented in AI config ("we use Linear/Jira, here's how"). (B) AI config documents delivery workflow: issue templates, labelling conventions, estimation approach, definition of done, sprint cadence. |
| **2** | AI assists with delivery tasks: refining issue descriptions, suggesting work decomposition (epics → stories → tasks), proposing estimates based on historical patterns, generating status summaries, flagging blocked or stale items, creating well-structured issues from bug reports. |
| **3** | AI-driven delivery automation on schedule: status reports generated from project board state, overdue items flagged, estimation accuracy tracked, scope changes detected, dependency risks identified. |
| **4** | AI manages delivery workflow within policy: decomposition and estimation default to AI-assisted, delivery health AI-maintained, retrospective insights generated from data, estimation models improve from actual vs predicted. Teams focus on decisions, not status accounting. |

*Note for Gap 5: Stage 1 accepts documented external tools (Linear, Jira). Stage 2+ is measured only through GitHub-visible signals, with annotation "delivery tracking partially external" if relevant.*

### 5.7 AI Practices & Governance *(cross-cutting)*

This dimension measures cross-cutting AI adoption maturity — concerns that span all SDLC dimensions rather than belonging to any single one.

| Stage | What It Looks Like |
|-------|--------------------|
| **0** | No AI usage policy, no multi-tool awareness, no orchestration patterns. Individual developers may use AI but the repo has no institutional AI presence. |
| **1** | *Two conditions:* (A) At least one AI tool actively configured (config file present with substantive content). (B) AI usage expectations documented: which tools, when to use them, attribution expectations. `.aiignore` or equivalent excludes sensitive paths. |
| **2** | Multi-tool configuration (2+ AI tools configured). Agent orchestration patterns visible: `AGENTS.md` with specialized roles, `.claude/commands/` or equivalent custom commands, MCP server configurations. AI attribution in commits (Co-authored-by). Human-AI review gates documented in CONTRIBUTING.md. |
| **3** | AI governance policy enforced in CI. Agent workflows automated (skills triggered on events). AI output quality tracked (merge rates, review cycles). Version pinning on AI tools and models. Cross-dimension AI standards documented and maintained. |
| **4** | Org-wide AI governance framework. Cross-repo agent orchestration. Self-improving AI configuration with documented feedback loops. New repos inherit AI standards automatically. AI effectiveness compounds — it gets measurably better quarter over quarter from accumulated feedback. |

---

## 6. Cross-Pillar Constraints (Guardrails)

| Constraint | Rule | Rationale |
|------------|------|-----------|
| **No tests, capped readiness** | If R3 < 20, Readiness capped at 50 | Without tests, AI agents can't verify their work |
| **No types in typed language** | If type coverage < 30%, R2 capped at 50 | Ignoring available type safety is a strong negative signal |
| **AI tooling without readiness** | If Readiness < 30 and Adoption composite > 50, flag "Risky Acceleration" | Safety net for adoption on weak foundations |
| **Single AI tool ≠ full adoption** | If AI Practices Stage 1 from single tool only, AI Practices sub-level capped at Mid | One config file doesn't indicate team-wide AI commitment |
| **Stale AI configs penalty** | AI configs unchanged in >6 months: dimension cannot be rated above Low sub-level | Outdated AI instructions actively mislead |

---

## 7. Anti-Gaming Provisions

### AI Config Quality Threshold (Stage 1)

"File exists" is necessary but not sufficient. An AI config file counts toward Stage 1 only if it contains **meaningful project context.**

**Counts:**
- Architecture overview, module boundaries, dependency relationships
- Coding conventions, naming patterns, preferred approaches
- Testing standards, build commands, CI expectations
- Security-critical areas, trust boundaries
- Delivery workflow, estimation approach, issue structure
- Operational context, deployment topology
- Approximately 50+ lines of substantive content (guideline, not hard cutoff)

**Does not count:**
- Empty or stub files ("TODO: add instructions")
- Generic boilerplate copied without project-specific adaptation
- Files containing only tool configuration with no project context

### Accepted AI Config Files

- `CLAUDE.md` or `claude.md` in repo root
- `AGENTS.md` in repo root
- `GEMINI.md` in repo root
- `.github/copilot-instructions.md`
- `.github/copilot-setup-steps.yml`
- `.cursor/rules` or `.cursorrules`
- `.claude/settings.json`
- `.claude/commands/` directory
- `ai_run.sh` in repo root
- `agent_docs/` directory in repo root
- `.mcp.json` or `mcp.json`
- `.aider*` files
- `.coderabbit.yaml`
- `.windsurfrules`
- `.continue/` directory
- `.sourcegraph/cody` directory
- `.codex/` directory
- `.aiignore` or `.cursorignore`

This list should be updated as new AI tools emerge.

### Present vs Active

For Stage 1+, we distinguish:
- **Present:** The artifact exists (file committed, bot installed)
- **Active:** The artifact is being used (recent edits, bot activity, pipeline runs)

Sub-levels incorporate this: a "present but not active" config gets Low sub-level. Active usage signals push toward Mid and High.

---

## 8. Output Format

### 8.1 Per-Repo Report

This is what a team sees for their repository.

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  {org}/{repo-name}                                     {language} {pct}%   ║
║  Quadrant: {quadrant} — {sub-level}                                        ║
║  Readiness {score} | Adoption {score}                                      ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  AI READINESS ({score}/100)             AI ADOPTION                        ║
║  ─────────────────────────              ──────────────────────────────────  ║
║  R1 Structural Clarity  {nn} {bar}      Code Quality    Stage {n} · {sl}   ║
║  R2 Semantic Density    {nn} {bar}      Security        Stage {n} · {sl}   ║
║  R3 Verification Infra  {nn} {bar}      Testing         Stage {n} · {sl}   ║
║  R4 Dev Ergonomics      {nn} {bar}      Release         Stage {n} · {sl}   ║
║                                         Ops/Monitoring  Stage {n} · {sl}   ║
║                                         Delivery        Stage {n} · {sl}   ║
║                                         ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌  ║
║                                         AI Practices    Stage {n} · {sl}   ║
║                                         learning: {static|evolving|...}    ║
║                                                                            ║
║  {Flags — if any}                                                          ║
║                                                                            ║
║  Insight: {1-2 sentence narrative summarizing the key finding}             ║
║                                                                            ║
║  NEXT STEPS (top 3, ordered by impact)                                     ║
║  ─────────────────────────────────────                                     ║
║  1. {action}                                                               ║
║     Effort: {Low|Medium|High}                                              ║
║     Impact: {dimension} Stage {n}·{sl} → {n}·{sl}                         ║
║             {dimension} Stage {n}·{sl} → {n}·{sl}  (if multi-dim)         ║
║             Adoption: {old} → {new}                                        ║
║                                                                            ║
║  2. {action}                                                               ║
║     Effort: {Low|Medium|High}                                              ║
║     Impact: {dimension} Stage {n}·{sl} → {n}·{sl}                         ║
║             Adoption: {old} → {new}                                        ║
║                                                                            ║
║  3. {action}                                                               ║
║     Effort: {Low|Medium|High}                                              ║
║     Impact: {dimension} Stage {n}·{sl} → {n}·{sl}                         ║
║             Adoption: {old} → {new}                                        ║
║                                                                            ║
║  Delta: {what changed since previous scan, or "First assessment"}          ║
║                                                                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

**Always 3 Next Steps.** Ordered by impact-to-effort ratio (highest first). Each step specifies: the concrete action, the effort level, and exactly which dimensions advance and to what level. The Adoption composite change is shown so teams can see their trajectory.

### 8.2 Org-Level Summary

This is what leadership sees.

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  {Org Name} AI Augmentation — {Month Year} ({n} repos assessed)            ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  QUADRANT DISTRIBUTION                                                     ║
║  ─────────────────────                                                     ║
║  Fertile Ground — High:  {n}  ({repo names})                               ║
║  Fertile Ground — Mid:   {n}  ({repo names})                               ║
║  Traditional:            {n}  ({repo names})                               ║
║  Risky Acceleration:     {n}  ({repo names})                               ║
║  AI-Native:              {n}  ({repo names})                               ║
║                                                                            ║
║                  Avg Readiness: {nn}    Avg Adoption: {nn}                 ║
║                                                                            ║
║  PORTFOLIO VIEW                                                            ║
║                            Readiness              Adoption                 ║
║  {repo-1}       {bar}  {nn}    {bar}  {nn}                                ║
║  {repo-2}       {bar}  {nn}    {bar}  {nn}                                ║
║  {repo-3}       {bar}  {nn}    {bar}  {nn}                                ║
║  ...                                                                       ║
║                                                                            ║
║  ADOPTION BY DIMENSION (how many repos at each stage)                      ║
║  ─────────────────────────────────────────────────────                      ║
║                     Stage 0    Stage 1    Stage 2    Stage 3    Stage 4    ║
║  Code Quality       {n}        {n}        {n}        {n}        {n}       ║
║  Security           {n}        {n}        {n}        {n}        {n}       ║
║  Testing            {n}        {n}        {n}        {n}        {n}       ║
║  Release            {n}        {n}        {n}        {n}        {n}       ║
║  Ops/Monitoring     {n}        {n}        {n}        {n}        {n}       ║
║  Delivery           {n}        {n}        {n}        {n}        {n}       ║
║  AI Practices       {n}        {n}        {n}        {n}        {n}       ║
║                                                                            ║
║  TREND (vs previous scan)                                                  ║
║  ─────────────────────────                                                 ║
║  Avg Readiness: {nn} → {nn} ({+/-n})                                      ║
║  Avg Adoption:  {nn} → {nn} ({+/-n})                                      ║
║  Stage advances: {n} dimensions across {n} repos                           ║
║                                                                            ║
║  TOP ORG-LEVEL ACTIONS (most common across repo Next Steps)                ║
║  ──────────────────────────────────────────────────────────                 ║
║  1. {action} — affects {n} repos                                           ║
║  2. {action} — affects {n} repos                                           ║
║  3. {action} — affects {n} repos                                           ║
║                                                                            ║
║  RISK FLAGS                                                                ║
║  ──────────                                                                ║
║  {flags — repos in Risky Acceleration, static learning 3+ months, etc.}    ║
║                                                                            ║
║  HEADLINE: {1-2 sentence org-level narrative}                              ║
║                                                                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

**Org-level view is always derived from per-repo data, never independently assessed.**

Key elements:
- **Quadrant distribution** — instant visual of portfolio health
- **Portfolio view** — all repos ranked, side-by-side comparison
- **Adoption by dimension** — shows where the org is weakest (e.g., "22 of 29 repos at Stage 0 on Ops")
- **Trend** — month-over-month progress
- **Top org-level actions** — aggregated from per-repo Next Steps, showing which actions would move the most repos
- **Risk flags** — repos in Risky Acceleration, stale configs, governance gaps

---

## 9. Machine-Readable Output Format

For each repo, the scan agent produces:

```json
{
  "repo": "org/repo-name",
  "snapshot_date": "2026-04-01",
  "model_version": "v3.0",
  "languages": [
    { "language": "Haskell", "percentage": 100 }
  ],
  "readiness": {
    "composite": 90,
    "pillars": {
      "structural_clarity":     { "score": 93, "evidence": "..." },
      "semantic_density":       { "score": 92, "evidence": "..." },
      "verification_infra":     { "score": 85, "evidence": "..." },
      "developer_ergonomics":   { "score": 89, "evidence": "..." }
    }
  },
  "adoption": {
    "composite": 18,
    "dimensions": {
      "code_quality":       { "stage": 1, "sub_level": "mid",  "mapped_score": 27, "learning": "static", "confidence": "high", "evidence": "..." },
      "security":           { "stage": 0, "sub_level": "mid",  "mapped_score": 7,  "learning": null,     "confidence": "medium", "evidence": "..." },
      "testing":            { "stage": 1, "sub_level": "low",  "mapped_score": 20, "learning": "static", "confidence": "high", "evidence": "..." },
      "release":            { "stage": 1, "sub_level": "low",  "mapped_score": 20, "learning": "static", "confidence": "high", "evidence": "..." },
      "ops_monitoring":     { "stage": 0, "sub_level": "low",  "mapped_score": 0,  "learning": null,     "confidence": "high", "evidence": "..." },
      "delivery":           { "stage": 1, "sub_level": "low",  "mapped_score": 20, "learning": "static", "confidence": "medium", "evidence": "..." },
      "ai_practices":       { "stage": 1, "sub_level": "low",  "mapped_score": 20, "learning": "static", "confidence": "high", "evidence": "..." }
    }
  },
  "quadrant": "Fertile Ground",
  "quadrant_sub_level": "High",
  "next_steps": [
    {
      "priority": 1,
      "action": "Confirm cargo-deny/cargo-audit runs in CI + add security trust boundaries to AI config",
      "effort": "low",
      "impact": [
        { "dimension": "security", "from_stage": 0, "from_sub": "high", "to_stage": 1, "to_sub": "low" }
      ],
      "adoption_change": { "from": 18, "to": 20 }
    },
    {
      "priority": 2,
      "action": "Add AI review bot (CodeRabbit or Claude) to PR workflow",
      "effort": "medium",
      "impact": [
        { "dimension": "code_quality", "from_stage": 1, "from_sub": "mid", "to_stage": 2, "to_sub": "low" }
      ],
      "adoption_change": { "from": 20, "to": 22 }
    },
    {
      "priority": 3,
      "action": "Update copilot-instructions based on team usage + add custom commands",
      "effort": "low",
      "impact": [
        { "dimension": "ai_practices", "from_stage": 1, "from_sub": "low", "to_stage": 1, "to_sub": "mid" }
      ],
      "adoption_change": { "from": 22, "to": 23 }
    }
  ],
  "flags": [],
  "minimum_viability_risks": [],
  "anomalies": [],
  "delta_from_previous": "New — first v3 assessment"
}
```

---

## 10. Minimum Viability Thresholds

These flag engineering risks **regardless of AI adoption**. Highlighted in every assessment.

| Area | Minimum Threshold | How Agent Checks | Risk if Unmet |
|------|-------------------|------------------|---------------|
| **CI/CD** | At least one automated build/test workflow | `.github/workflows/` contains at least one `.yml` file | No automated quality gate |
| **Dependency scanning** | Dependabot, Renovate, or equivalent | Config file present or workflow YAML references scanning | Unmonitored supply chain |
| **Security policy** | `SECURITY.md` or equivalent | `SECURITY.md` exists in repo root | No vulnerability reporting path |
| **Test automation** | At least one test suite in CI | Workflow YAML contains test execution step | No automated regression detection |
| **Branch protection** | Main/master requires PR review | Branch protection API check | Direct pushes bypass quality checks |
| **PR review enforcement** | No PRs merged without review | Sample recent merged PRs, check review count | Code reaches main without human review |
| **Issue tracking** | Issues or Projects active | Repo has issues enabled or linked to a GitHub Project | Work invisible to stakeholders |

---

## 11. Edge Cases

| Scenario | Handling |
|----------|----------|
| **Haskell/Nix repos** | Nix flakes, Hydra CI, hlint, fourmolu, `-Werror` contribute to Readiness scores (R1-R4) and satisfy Condition A for relevant adoption dimensions. They are NOT adoption signals by themselves. |
| **AI PRs without AI config** | Adoption Stage 0 with annotation "Stage 2 signals emerging without Stage 1 config." The activity is demand signal. |
| **Inaccessible repos** | Score all dimensions as N/A. Exclude from aggregates. |
| **Repos with no CI/CD** | Readiness R3/R4 penalized. Cannot progress beyond Stage 1 on adoption dimensions that require pipeline (Stage 3). |
| **Repos not using GitHub** | Score Delivery as 0 with annotation "delivery tracking not in GitHub" unless external tool is documented in AI config (Stage 1 eligible). |
| **Multi-language repos** | Readiness: score each language independently, weighted by LOC proportion. Adoption: language-agnostic (same stages regardless of language). |
| **Library repos (no production)** | Ops/Monitoring: Stage 0 with "(n/a — library)" annotation. Not counted as a gap. Weight redistributed to other dimensions for composite calculation. |
| **Monorepos** | Assess as a single repo. If sub-packages have significantly different AI adoption, note in annotations. |

---

## 12. Confidence Levels

| Confidence | Meaning | When to Use |
|------------|---------|-------------|
| **High** | Clear, unambiguous evidence | Observable signals match the stage definition directly |
| **Medium** | Partial signals or interpretation needed | Some signals present but not all, or in adjacent categories |
| **Low** | Inferred or file-only evidence | Config file present but no evidence of active use |

---

## 13. Measurement Cadence

- **Monthly snapshots** on or near the first working day of each month
- **Repo list** from `models/config.yaml` at snapshot time
- **Lookback window:** AI activity signals (PRs, commits, issues) checked since previous snapshot. Config files and workflows checked as of current snapshot.
- **Historical snapshots are immutable** — correct errors in the next snapshot
- **Model and scoring are versioned** — changes tracked in `changelog.md`

---

## 14. What Changed from v1 and v2

### From v1

| Aspect | v1 | v3 |
|--------|----|----|
| Architecture | Single axis (Adoption stages only) | Two axes (Readiness + Adoption) |
| Readiness visibility | "Infrastructure readiness" — noted, not scored | R1-R4 scored 0-100, language-aware |
| Adoption dimensions | 6 SDLC dimensions | 7 (added AI Practices & Governance) |
| Stage 1 gate | AI config exists with quality check | Two conditions: practice active + AI config |
| Within-stage granularity | None | Sub-levels (Low/Mid/High) |
| Learning signals | Stage 4 only (config commit history) | All stages (static/evolving/self-improving annotation) |
| Ops/Monitoring Stage 2 | Gap (jumped from 1 to 3) | Defined: AI assists during incidents |
| Delivery external tools | Score 0 if not GitHub | Stage 1 accepts documented external tools |
| Risk detection | Not captured | Risky Acceleration quadrant |
| Output | Stage per dimension + overall | Quadrant + coordinates + per-dimension + Next Steps |

### From v2

| Aspect | v2 | v3 |
|--------|----|----|
| Adoption structure | 4 generic pillars (A1-A4) | 7 SDLC dimensions with stages — recovers v1's per-dimension actionability |
| Adoption scoring | 0-100 continuous | Stage (0-4) + sub-level (Low/Mid/High) — simpler, more actionable |
| Stage progression | Not present | Cumulative stages from v1 — "do this next" clarity |
| SDLC visibility | Collapsed into single Adoption score | Per-dimension breakdown — "you're ahead on Testing, behind on Security" |
| Readiness | R1-R4 pillars (unchanged) | R1-R4 pillars (unchanged) |
| Next Steps | Not present | Top 3 prioritized actions with projected impact |
| Governance | A4 pillar (generic) | Dedicated cross-cutting dimension with stage definitions |

### Key Design Decisions (March 2026)

1. AI Readiness stays in AAMM, not CMM — quadrant model requires co-location
2. Adoption uses stages + sub-levels, not continuous 0-100 — simpler, more reproducible
3. 7th dimension (AI Practices & Governance) for cross-cutting concerns
4. Two-condition Stage 1 gate for all dimensions — more rigorous
5. Next Steps always exactly 3, ordered by impact/effort
6. Learning signals enrich sub-levels, not a separate axis

---

## 15. Example Assessment: 4 CBU Repos

> **Adoption composite formula verification:** All numbers below are computed using the
> dimension weights from Section 4.3 and the Stage-to-score mapping from Section 4.2.
> Weights: CQ=0.18, Sec=0.15, Test=0.18, Rel=0.12, Ops=0.10, Del=0.12, AIP=0.15.

### cardano-ledger (Haskell)

Excellent engineering, zero AI config. All SDLC practices active (Condition A met) but no AI config anywhere (Condition B not met) → all dimensions Stage 0 · Mid.

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  IntersectMBO/cardano-ledger                                Haskell 100%   ║
║  Quadrant: Fertile Ground — High                                           ║
║  Readiness 90 | Adoption 5                                                 ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  AI READINESS (90/100)                  AI ADOPTION                        ║
║  ─────────────────────                  ──────────────────────────────────  ║
║  R1 Structural Clarity   93 █████████░  Code Quality    Stage 0 · Mid      ║
║  R2 Semantic Density     92 █████████░  Security        Stage 0 · Mid      ║
║  R3 Verification Infra   85 █████████░  Testing         Stage 0 · Mid      ║
║  R4 Dev Ergonomics       89 █████████░  Release         Stage 0 · Mid      ║
║                                         Ops/Monitoring  Stage 0 · Low      ║
║                                         Delivery        Stage 0 · Mid      ║
║                                         ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌  ║
║                                         AI Practices    Stage 0            ║
║                                                                            ║
║  Insight: World-class Haskell engineering (Readiness 90) with zero AI      ║
║  adoption. All SDLC practices are active — the only missing piece is AI    ║
║  configuration. Highest ROI for AI investment in CBU.                      ║
║                                                                            ║
║  NEXT STEPS                                                                ║
║  ──────────                                                                ║
║  1. Add CLAUDE.md covering architecture, coding conventions, test          ║
║     standards, release process, and delivery workflow                      ║
║     Effort: Low                                                            ║
║     Impact: Code Quality   Stage 0 · Mid → 1 · Low                        ║
║             Testing        Stage 0 · Mid → 1 · Low                        ║
║             Release        Stage 0 · Mid → 1 · Low                        ║
║             Delivery       Stage 0 · Mid → 1 · Low                        ║
║             AI Practices   Stage 0 → 1 · Low                              ║
║             Adoption: 5 → 16                                               ║
║                                                                            ║
║  2. Enable Dependabot for Haskell deps + add security context              ║
║     to CLAUDE.md (trust boundaries, sensitive modules)                     ║
║     Effort: Low                                                            ║
║     Impact: Security       Stage 0 · Mid → 1 · Low                        ║
║             Adoption: 16 → 18                                              ║
║                                                                            ║
║  3. Add AI review bot (CodeRabbit or Claude) to PR workflow                ║
║     Effort: Medium                                                         ║
║     Impact: Code Quality   Stage 1 · Low → 2 · Low                        ║
║             Adoption: 18 → 22                                              ║
║                                                                            ║
║  Delta: First v3 assessment                                                ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

Adoption composite verification: 0.18×7 + 0.15×7 + 0.18×7 + 0.12×7 + 0.10×0 + 0.12×7 + 0.15×0 = 5.25 ≈ **5**
After Step 1: 0.18×20 + 0.15×7 + 0.18×20 + 0.12×20 + 0.10×0 + 0.12×20 + 0.15×20 = 16.05 ≈ **16**
After Step 2: swap Sec 7→20: +0.15×13 = +1.95 → **18**
After Step 3: swap CQ 20→40: +0.18×20 = +3.6 → **22**

### mithril (Rust)

Has high-quality copilot-instructions.md. Most SDLC practices active. 5 dimensions at Stage 1.

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  input-output-hk/mithril                                     Rust 100%    ║
║  Quadrant: Fertile Ground — High                                           ║
║  Readiness 86 | Adoption 18                                                ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  AI READINESS (86/100)                  AI ADOPTION                        ║
║  ─────────────────────                  ──────────────────────────────────  ║
║  R1 Structural Clarity   88 █████████░  Code Quality    Stage 1 · Mid      ║
║  R2 Semantic Density     88 █████████░  Security        Stage 0 · Mid      ║
║  R3 Verification Infra   84 ████████░░  Testing         Stage 1 · Low      ║
║  R4 Dev Ergonomics       81 ████████░░  Release         Stage 1 · Low      ║
║                                         Ops/Monitoring  Stage 0 · Low      ║
║                                         Delivery        Stage 1 · Low      ║
║                                         ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌  ║
║                                         AI Practices    Stage 1 · Low      ║
║                                         learning: static                   ║
║                                                                            ║
║  Insight: Best single AI config in CBU portfolio (copilot-instructions.md, ║
║  4KB). 5 dimensions at Stage 1. Security at Stage 0 — scanning active     ║
║  (deny.toml) but not confirmed in CI.                                     ║
║                                                                            ║
║  NEXT STEPS                                                                ║
║  ──────────                                                                ║
║  1. Confirm cargo-deny/cargo-audit runs in CI + add security               ║
║     trust boundaries to copilot-instructions                               ║
║     Effort: Low                                                            ║
║     Impact: Security       Stage 0 · Mid → 1 · Low                        ║
║             Adoption: 18 → 20                                              ║
║                                                                            ║
║  2. Add AI review bot (CodeRabbit or Claude) to PR workflow                ║
║     Effort: Medium                                                         ║
║     Impact: Code Quality   Stage 1 · Mid → 2 · Low                        ║
║             Adoption: 20 → 22                                              ║
║                                                                            ║
║  3. Update copilot-instructions based on team usage patterns               ║
║     + add .claude/commands/ for common workflows                           ║
║     Effort: Low                                                            ║
║     Impact: AI Practices   Stage 1 · Low → 1 · Mid                        ║
║             learning: static → evolving                                    ║
║             Adoption: 22 → 23                                              ║
║                                                                            ║
║  Delta: First v3 assessment                                                ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

Adoption composite: 0.18×27 + 0.15×7 + 0.18×20 + 0.12×20 + 0.10×0 + 0.12×20 + 0.15×20 = 18.21 ≈ **18**
After Step 1: swap Sec 7→20: +0.15×13 = +1.95 → **20**
After Step 2: swap CQ 27→40: +0.18×13 = +2.34 → **22**
After Step 3: swap AIP 20→27: +0.15×7 = +1.05 → **23**

### hydra (Haskell)

Excellent Haskell DX, zero AI config. Similar pattern to cardano-ledger.

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  cardano-scaling/hydra                                      Haskell 100%   ║
║  Quadrant: Fertile Ground — High                                           ║
║  Readiness 81 | Adoption 4                                                 ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  AI READINESS (81/100)                  AI ADOPTION                        ║
║  ─────────────────────                  ──────────────────────────────────  ║
║  R1 Structural Clarity   83 ████████░░  Code Quality    Stage 0 · Mid      ║
║  R2 Semantic Density     77 ████████░░  Security        Stage 0 · Mid      ║
║  R3 Verification Infra   78 ████████░░  Testing         Stage 0 · Mid      ║
║  R4 Dev Ergonomics       87 █████████░  Release         Stage 0 · Low      ║
║                                         Ops/Monitoring  Stage 0            ║
║                                         Delivery        Stage 0 · Low      ║
║                                         ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌  ║
║                                         AI Practices    Stage 0            ║
║                                                                            ║
║  Insight: Excellent Haskell DX (fourmolu + hlint + hie + direnv + Nix).    ║
║  Strong verification infra (hydra-test-utils, hydra-cluster). Zero AI      ║
║  adoption — similar pattern to cardano-ledger.                             ║
║                                                                            ║
║  NEXT STEPS                                                                ║
║  ──────────                                                                ║
║  1. Add CLAUDE.md covering the 11-package architecture, coding             ║
║     conventions, test patterns, and delivery workflow                      ║
║     Effort: Low                                                            ║
║     Impact: Code Quality   Stage 0 · Mid → 1 · Low                        ║
║             Testing        Stage 0 · Mid → 1 · Low                        ║
║             Delivery       Stage 0 · Low → 1 · Low                        ║
║             AI Practices   Stage 0 → 1 · Low                              ║
║             Adoption: 4 → 14                                               ║
║                                                                            ║
║  2. Enable Dependabot + add security context to CLAUDE.md                  ║
║     Effort: Low                                                            ║
║     Impact: Security       Stage 0 · Mid → 1 · Low                        ║
║             Adoption: 14 → 16                                              ║
║                                                                            ║
║  3. Add AI review bot (CodeRabbit or Claude) to PR workflow                ║
║     Effort: Medium                                                         ║
║     Impact: Code Quality   Stage 1 · Low → 2 · Low                        ║
║             Adoption: 16 → 20                                              ║
║                                                                            ║
║  Delta: First v3 assessment                                                ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

Adoption composite: 0.18×7 + 0.15×7 + 0.18×7 + 0.12×0 + 0.10×0 + 0.12×0 + 0.15×0 = 3.57 ≈ **4**
After Step 1 (CQ→20, Test→20, Del→20, AIP→20; Sec stays 7, Rel stays 0, Ops stays 0):
0.18×20 + 0.15×7 + 0.18×20 + 0.12×0 + 0.10×0 + 0.12×20 + 0.15×20 = 13.65 ≈ **14**
After Step 2: swap Sec 7→20: +0.15×13 = +1.95 → **16**
After Step 3: swap CQ 20→40: +0.18×20 = +3.6 → **20**

Note: hydra Step 1 does not advance Release because release.sh is a manual script (Condition A not met for Release — no automated workflow). A follow-up CLAUDE.md covering release process satisfies only Condition B; Condition A requires adding an automated release workflow.

### lace (TypeScript)

Has .mcp.json with 3 MCP servers but no instructional AI config (no CLAUDE.md, no .cursorrules). MCP config doesn't satisfy Condition B for most dimensions because it doesn't contain project-specific context about coding conventions, testing standards, etc.

Ops/Monitoring is n/a (browser extension — no server-side production). Weights redistributed proportionally: remaining weights divided by 0.90.

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  input-output-hk/lace                                  TypeScript 100%     ║
║  Quadrant: Fertile Ground — Mid                                            ║
║  Readiness 71 | Adoption 12                                                ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  AI READINESS (71/100)                  AI ADOPTION                        ║
║  ─────────────────────                  ──────────────────────────────────  ║
║  R1 Structural Clarity   75 ████████░░  Code Quality    Stage 0 · High     ║
║  R2 Semantic Density     58 ██████░░░░  Security        Stage 0 · High     ║
║  R3 Verification Infra   80 ████████░░  Testing         Stage 0 · High     ║
║  R4 Dev Ergonomics       71 ███████░░░  Release         Stage 0 · High     ║
║                                         Ops/Monitoring  Stage 0   (n/a)    ║
║                                         Delivery        Stage 0 · High     ║
║                                         ╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌  ║
║                                         AI Practices    Stage 0 · Mid      ║
║                                         learning: static                   ║
║                                                                            ║
║  ⚠ MCP servers use npx -y — supply-chain risk for crypto wallet            ║
║  ⚠ Dependabot covers only github-actions, not npm packages                 ║
║  ⚠ R2 Semantic Density 58 — weakest foundation in portfolio                ║
║                                                                            ║
║  Insight: All SDLC practices active (Stage 0 · High) + MCP config shows   ║
║  AI tool usage. But .mcp.json doesn't provide project context — no coding  ║
║  conventions, test standards, or architecture documented for AI tools.     ║
║  Adding CLAUDE.md would unlock Stage 1 on 5 dimensions simultaneously.    ║
║                                                                            ║
║  NEXT STEPS                                                                ║
║  ──────────                                                                ║
║  1. Add CLAUDE.md with architecture, coding standards, test conventions,   ║
║     release process, delivery workflow + pin MCP server versions           ║
║     Effort: Low                                                            ║
║     Impact: Code Quality   Stage 0 · High → 1 · Low                       ║
║             Testing        Stage 0 · High → 1 · Low                       ║
║             Release        Stage 0 · High → 1 · Low                       ║
║             Delivery       Stage 0 · High → 1 · Low                       ║
║             AI Practices   Stage 0 · Mid → 1 · Low                        ║
║             Adoption: 12 → 19                                              ║
║                                                                            ║
║  2. Add security trust boundaries to CLAUDE.md + expand                    ║
║     Dependabot to cover npm packages                                       ║
║     Effort: Low                                                            ║
║     Impact: Security       Stage 0 · High → 1 · Low                       ║
║             Adoption: 19 → 20                                              ║
║                                                                            ║
║  3. Improve R2 Semantic Density: add CHANGELOG, enable strict mode,        ║
║     add ADRs for key decisions                                             ║
║     Effort: Medium                                                         ║
║     Impact: Readiness      71 → ~77 (R2: 58 → ~72)                        ║
║             Quadrant remains Fertile Ground — High (76+)                   ║
║                                                                            ║
║  Delta: First v3 assessment                                                ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

Adoption composite (Ops excluded, weights ÷ 0.90):
CQ=0.200, Sec=0.167, Test=0.200, Rel=0.133, Del=0.133, AIP=0.167
0.200×13 + 0.167×13 + 0.200×13 + 0.133×13 + 0.133×13 + 0.167×7 = 11.13 ≈ **12**
After Step 1 (CQ→20, Test→20, Rel→20, Del→20, AIP→20; Sec stays 13):
0.200×20 + 0.167×13 + 0.200×20 + 0.133×20 + 0.133×20 + 0.167×20 = 18.84 ≈ **19**
After Step 2: swap Sec 13→20: +0.167×7 = +1.17 → **20**

### Org-Level Summary

```
╔══════════════════════════════════════════════════════════════════════════════╗
║  CBU AI Augmentation — March 2026 (4 repos assessed)                       ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  QUADRANT DISTRIBUTION                                                     ║
║  ─────────────────────                                                     ║
║  Fertile Ground — High:  3  (cardano-ledger, mithril, hydra)               ║
║  Fertile Ground — Mid:   1  (lace)                                         ║
║  Risky Acceleration:     0                                                 ║
║  AI-Native:              0                                                 ║
║  Traditional:            0                                                 ║
║                                                                            ║
║                  Avg Readiness: 82    Avg Adoption: 10                     ║
║                                                                            ║
║  PORTFOLIO VIEW                                                            ║
║                            Readiness              Adoption                 ║
║  cardano-ledger  ████████████████████░  90    █  5                         ║
║  mithril         ███████████████████░░  86    ████  18                     ║
║  hydra           ████████████████░░░░░  81    █  4                         ║
║  lace            ██████████████░░░░░░░  71    ███  12                      ║
║                                                                            ║
║  ADOPTION BY DIMENSION                                                     ║
║  ─────────────────────                                                     ║
║                     Stage 0    Stage 1    Stage 2    Stage 3    Stage 4    ║
║  Code Quality         3          1          0          0          0        ║
║  Security             4          0          0          0          0        ║
║  Testing              3          1          0          0          0        ║
║  Release              3          1          0          0          0        ║
║  Ops/Monitoring       4          0          0          0          0        ║
║  Delivery             3          1          0          0          0        ║
║  AI Practices         3          1          0          0          0        ║
║                                                                            ║
║  TOP ORG-LEVEL ACTIONS                                                     ║
║  ─────────────────────                                                     ║
║  1. Add comprehensive CLAUDE.md — affects 3 repos (ledger, hydra, lace)    ║
║  2. Enable dependency scanning — affects 2 repos (ledger, hydra)           ║
║  3. Add AI review bot to PRs — affects 4 repos                             ║
║                                                                            ║
║  RISK FLAGS                                                                ║
║  ──────────                                                                ║
║  ⚠ lace: unpinned MCP server versions (supply-chain risk, crypto wallet)   ║
║  ⚠ mithril: learning signal static — AI config not updated since creation  ║
║                                                                            ║
║  HEADLINE: All 4 repos are Fertile Ground — strong engineering foundations  ║
║  with minimal AI adoption. The CBU's primary opportunity is activation,    ║
║  not remediation. Single highest-leverage action: add CLAUDE.md to the     ║
║  3 repos that don't have one.                                              ║
║                                                                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
```

---

## Appendix A: Glossary

| Term | Definition |
|------|-----------|
| **Readiness** | How well the codebase supports AI collaboration (0-100) |
| **Adoption** | How much AI is actively used in workflows (stages + sub-levels) |
| **Quadrant** | Position on the Readiness × Adoption grid |
| **Stage** | Certified adoption level per dimension (0-4, cumulative) |
| **Sub-level** | Within-stage progress (Low/Mid/High) |
| **Learning signal** | Annotation indicating config evolution (static/evolving/self-improving) |
| **Two-condition gate** | Stage 1 requires both active practice AND AI config |
| **Next Steps** | Top 3 prioritized actions with projected impact |
| **Adoption composite** | Weighted average of dimension scores mapped to 0-100 |
| **Cross-cutting dimension** | AI Practices & Governance — spans all SDLC phases |
