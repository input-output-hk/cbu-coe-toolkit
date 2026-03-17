# AI Augmentation Maturity Model v2 (AAMM-v2)

> **⚠️ DEPRECATED:** This is AAMM v2 (experimental). Insights merged into v3. See [`models/ai-augmentation-maturity-v3/model-spec.md`](../ai-augmentation-maturity-v3/model-spec.md).

## Model Specification — Logic & Scoring Framework

> **Status:** Local draft — alternative perspective under evaluation. NOT submitted to GitHub.
> **Location:** `models/ai-augmentation-maturity-v2/`
> **Predecessor:** `models/ai-augmentation-maturity/` (stage-based v1)

---

## 1. Foundational Design Decisions

### 1.1 Why Two Dimensions, Not a Ladder

Most maturity models use a single 1–5 scale. This obscures a critical distinction:

- **AI Readiness** — Is this codebase *structurally suitable* for productive AI collaboration? (modularity, types, tests, documentation, deterministic builds)
- **AI Adoption** — Is AI *actively used* in development workflows on this codebase? (tooling configs, AI-native patterns, AI in CI, governance around AI-generated code)

These are independent axes. A greenfield Haskell project with strong types and property-based tests but no `.cursorrules` file is high-readiness, zero-adoption. A legacy JavaScript monolith with Copilot everywhere but no tests is low-readiness, moderate-adoption.

Collapsing these into one number hides the most actionable insight: **where to invest next.**

### 1.2 The Quadrant Model

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

Each axis scores 0–100. The quadrant placement is derived from (Readiness, Adoption) coordinates.

**Quadrant boundaries:**
- Traditional: Readiness < 45, Adoption < 45
- Fertile Ground: Readiness ≥ 45, Adoption < 45
- Risky Acceleration: Readiness < 45, Adoption ≥ 45
- AI-Native: Readiness ≥ 45, Adoption ≥ 45

**Sub-levels within each quadrant** (Low/Mid/High) based on distance from center:
- Low: dominant axis score 45–60
- Mid: dominant axis score 61–75
- High: dominant axis score 76–100

Example output: "Fertile Ground — High Readiness (82), Low Adoption (23)"

### 1.3 Design Constraints

1. **Deterministic.** Same repo → same score. No randomness, no LLM calls in scoring.
2. **Language-aware.** Signals are mapped per language ecosystem. The model adapts its expectations based on detected primary language(s).
3. **Observable only.** Score what can be seen in the repository tree and file contents. No runtime analysis, no external API calls, no build execution.
4. **Proportional, not binary.** Signals contribute proportionally — a 200-line README scores differently from a 20-line one.
5. **Composable.** Multi-language repos score each language independently, then weighted-average by LOC proportion.

---

## 2. AI Readiness Axis — 4 Pillars

Readiness measures how well the codebase supports productive AI collaboration regardless of whether any AI tools are currently used.

### Pillar R1: Structural Clarity (weight: 30% of Readiness)

**What it measures:** Can an AI agent (or a new human developer) understand where things are and how they connect?

#### Universal Signals

| Signal | Metric | Scoring |
|--------|--------|---------|
| **File organization** | Depth and consistency of directory tree | 3+ levels of meaningful nesting = good. Flat dump of files at root = poor. |
| **File granularity** | Median source file size (lines) | <150 lines median = excellent. 150-300 = good. 300-500 = acceptable. >500 = poor. Files >1000 lines are penalized individually. |
| **Module boundaries** | Presence of explicit module/package definitions | Package files, module exports, public API surfaces explicitly defined. |
| **Separation of concerns** | Distinct directories for distinct responsibilities | E.g., routes/handlers separated from business logic separated from data access. Detected by directory naming heuristics + import analysis. |
| **Circular dependency risk** | Import/dependency graph structure | Measured by sampling: pick 10 random source files, trace their imports 2 levels deep. Cycles found = penalty. |
| **Entry point clarity** | How easy is it to find where execution starts | main/index/app file is identifiable. For libraries: clear public API module. |
| **Configuration isolation** | Config separated from logic | Config files (.env, yaml, toml) in dedicated locations, not hardcoded in source. |

#### Language-Specific Signals (Haskell)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| Module hierarchy | `src/` directory with meaningful module tree | +5 for 3+ levels of module nesting |
| Explicit exports | Modules export specific symbols, not `module X where` (export-all) | +8 for >70% of modules having explicit exports |
| Cabal/Stack structure | Well-organized `.cabal` file with library + executable + test stanzas | +5 |
| Internal modules | `Internal` module pattern for implementation hiding | +3 for using Internal convention |
| Package boundaries | Multi-package project (`cabal.project` with multiple packages) | +5 |
| Typeclass discipline | Typeclasses defined in own modules, orphan instances minimized | +3 |

#### Language-Specific Signals (Rust)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| Workspace structure | `Cargo.toml` with `[workspace]` and multiple crates | +5 for well-split workspace |
| Crate granularity | Number of crates vs total LOC | Reward: <2000 LOC/crate average |
| `pub` visibility discipline | Ratio of `pub` to total functions/structs | <40% pub = disciplined encapsulation |
| Module tree (`mod.rs` / `lib.rs`) | Clear `mod` declarations, not `#[path]` hacks | +3 for clean module tree |
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

### Pillar R2: Semantic Density (weight: 30% of Readiness)

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
| QuickCheck/Hedgehog properties | Property-based testing | +5 |

#### Language-Specific Signals (Rust)

| Signal | What to check | Score impact |
|--------|---------------|-------------|
| `#![deny(missing_docs)]` | Enforced documentation | +10 |
| `#![forbid(unsafe_code)]` or scoped `unsafe` | Safety discipline | +5 for forbid, +3 for minimal scoped unsafe |
| Doc comments (`///`) coverage | Doc comments on pub items | +8 for >70% coverage |
| `clippy.toml` or `#![warn(clippy::all)]` | Lint discipline | +5 |
| Type-state pattern usage | Complex state machines encoded in types | +5 |
| `serde` derive with explicit attributes | Structured serialization | +3 |
| Property-based testing (`proptest`, `quickcheck`) | Advanced testing | +3 |

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

### Pillar R3: Verification Infrastructure (weight: 25% of Readiness)

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

### Pillar R4: Developer Ergonomics (weight: 15% of Readiness)

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

### Readiness Composite Score

```
Readiness = R1 * 0.30 + R2 * 0.30 + R3 * 0.25 + R4 * 0.15
```

---

## 3. AI Adoption Axis — 4 Pillars

### Pillar A1: AI Tooling Configuration (weight: 30% of Adoption)

| Signal | Weight | Scoring Details |
|--------|--------|-----------------|
| **CLAUDE.md** | 0.15 | Absent = 0. Stub (<200 chars) = 20. Substantive (>500 chars) = 60. Detailed with conventions = 100. |
| **`.claude/` directory** | 0.10 | Skills, settings, or commands present. |
| **`.cursorrules` or `.cursor/rules/`** | 0.10 | Same graduated scoring. |
| **`.github/copilot-instructions.md`** | 0.10 | Same graduated scoring. |
| **Other AI tool configs** | 0.10 | `.aider*`, `.coderabbit.yaml`, `.windsurfrules`, `.continue/`, `.sourcegraph/cody`, `.codex/`. |
| **AI-specific dependencies** | 0.10 | AI SDKs in dev dependencies. |
| **MCP configuration** | 0.10 | `mcp.json`, MCP server definitions. |
| **Custom AI instructions quality** | 0.15 | Project-specific detail vs generic boilerplate. |
| **Multi-tool coverage** | 0.10 | 1 tool = 30. 2 = 60. 3+ = 100. |

### Pillar A2: AI Workflow Integration (weight: 25% of Adoption)

| Signal | Weight | Scoring Details |
|--------|--------|-----------------|
| **AI review bot in CI** | 0.25 | CodeRabbit, Codex review, Claude review action, custom AI review step. |
| **AI-powered CI steps** | 0.20 | AI-based test generation, changelog generation, PR description generation. |
| **PR template with AI guidance** | 0.10 | PR template referencing AI tools or AI-generated sections. |
| **AI commit patterns** | 0.15 | Co-authored-by patterns, AI tool attribution in commits. |
| **Automated dependency updates with AI** | 0.10 | Renovate/Dependabot + AI-assisted review. |
| **AI-assisted documentation generation** | 0.10 | Generated API docs, auto-generated README sections. |
| **Branch strategy accommodating AI** | 0.10 | AI-specific branching, automated branch cleanup. |

### Pillar A3: AI-Native Patterns (weight: 25% of Adoption)

| Signal | Weight | Scoring Details |
|--------|--------|-----------------|
| **Structured AI rules directory** | 0.20 | `.ai/rules/` or equivalent with categorized rules. |
| **Spec-driven development artifacts** | 0.20 | `specs/`, `stories/`, structured feature descriptions. |
| **Progressive context disclosure** | 0.15 | Conditional loading in CLAUDE.md ("When working on auth, read X"). |
| **AI-friendly commit conventions** | 0.10 | Conventional commits + scoped commits. |
| **Context management files** | 0.15 | Architecture overviews, Mermaid diagrams, concise structured context. |
| **Skills or custom commands** | 0.10 | `.claude/commands/`, custom MCP tools, Cursor custom commands. |
| **Human-AI review gates** | 0.10 | Quality gates for AI-generated code in CI or CONTRIBUTING.md. |

### Pillar A4: AI Governance (weight: 20% of Adoption)

| Signal | Weight | Scoring Details |
|--------|--------|-----------------|
| **AI usage policy** | 0.20 | Documented policy on AI usage. |
| **AI attribution practices** | 0.20 | Co-authored-by in commits, AI-generated markers. |
| **AI output quality checks** | 0.20 | Specific CI checks for AI-generated code quality. |
| **Security considerations for AI** | 0.15 | `.aiignore`, `.cursorignore`, sensitive directories excluded. |
| **AI tool version pinning** | 0.10 | Specific model versions in config. |
| **Feedback loop documentation** | 0.15 | Updated rules based on past mistakes. |

### Adoption Composite Score

```
Adoption = A1 * 0.30 + A2 * 0.25 + A3 * 0.25 + A4 * 0.20
```

---

## 4. Cross-Pillar Constraints (Guardrails)

| Constraint | Rule | Rationale |
|------------|------|-----------|
| **No tests, capped readiness** | If R3 < 20, Readiness capped at 50 | Without tests, AI agents can't verify their work. |
| **No types in typed language** | If type coverage < 30%, R2 capped at 50 | Ignoring available type safety is a strong negative signal. |
| **AI tooling without readiness** | If Readiness < 30 and Adoption > 50, flag "Risky Acceleration" | Safety net. |
| **Single AI tool ≠ adoption** | If A1 from single tool only, A1 capped at 50 | One config file doesn't indicate team-wide adoption. |
| **Stale AI configs penalty** | AI configs unchanged in >6 months: -20% their contribution | Outdated AI instructions mislead. |

---

## 5. Assessment Output Format

### Primary Output: Quadrant + Coordinates

```
Repository:   org/repo-name
Languages:    Haskell (85%), Rust (15%)
Assessment:   Fertile Ground — High
Coordinates:  Readiness 78 | Adoption 12
```

### Pillar Breakdown

```
AI READINESS (78/100)                    AI ADOPTION (12/100)
─────────────────────────                ─────────────────────────
R1 Structural Clarity   82  ████████░░   A1 AI Tooling Config   18  ██░░░░░░░░
R2 Semantic Density     85  █████████░   A2 Workflow Integration  8  █░░░░░░░░░
R3 Verification Infra   71  ███████░░░   A3 AI-Native Patterns    5  █░░░░░░░░░
R4 Developer Ergonomics 68  ███████░░░   A4 AI Governance         8  █░░░░░░░░░
```

---

## 6. Key Differences from v1

| Aspect | v1 (ai-augmentation-maturity) | v2 (this model) |
|--------|-------------------------------|-----------------|
| Dimensions | Single 0–4 ladder per SDLC dimension | 2D: Readiness × Adoption |
| Pillars | 6 SDLC dimensions (CQ, Security, Testing, Release, Ops, Delivery) | 4 Readiness + 4 Adoption (8 total) |
| What it captures | Only AI adoption signals | Codebase quality AND AI adoption |
| Language support | Generic with infra-readiness notes | Explicit signal tables per language |
| Output | Stage 0–4 per dimension | Quadrant + 0–100 coordinates + per-pillar breakdown |
| "Good engineering but no AI" repos | Stage 0 (indistinguishable from bad repos) | Fertile Ground (high readiness, captures value) |
| Actionability | "Add AI config" | "R3 is 71 because test ratio is 0.3 — raising to 0.5 moves Readiness from 78 to 82" |
