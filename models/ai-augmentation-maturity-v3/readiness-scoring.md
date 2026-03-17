# AAMM v3: Readiness Scoring Methodology

**Owner:** CoE · Dorin Solomon · **Status:** Draft v3.0 · **Last updated:** March 2026

---

## 1. Purpose

This document defines **how** to compute Readiness scores (R1 through R4) operationally. It is the companion to [model-spec.md](model-spec.md), which defines **what** each pillar means, and [adoption-scoring.md](adoption-scoring.md), which covers the Adoption axis.

An AI agent reading this document together with `model-spec.md` should have everything it needs to score the Readiness axis for any repository without further human guidance. Every signal has a concrete metric-to-score mapping. Every formula is explicit. Every judgment call is bounded.

**Scope:** Readiness measures whether the codebase is *structurally suitable* for productive AI collaboration — independent of whether any AI tools are currently used.

---

## 2. Readiness Composite Formula

```
Readiness = R1 * 0.30 + R2 * 0.30 + R3 * 0.25 + R4 * 0.15
```

### Weight Rationale

| Pillar | Weight | Why |
|--------|--------|-----|
| R1: Structural Clarity | 0.30 | An AI agent's effectiveness depends first on being able to navigate and understand the codebase. Poor structure defeats every other investment. |
| R2: Semantic Density | 0.30 | Types, documentation, and naming are the primary channels through which an AI agent understands intent. Equal to structure because meaning without organization and organization without meaning are both insufficient. |
| R3: Verification Infrastructure | 0.25 | Without tests, an AI agent cannot verify its own output. Slightly lower than R1/R2 because a well-structured, well-typed codebase with limited tests is still navigable; the reverse is not true. |
| R4: Developer Ergonomics | 0.15 | Linters, formatters, CI, and reproducible environments make AI collaboration smoother but are not fundamental blockers. A repo with perfect ergonomics but poor structure is still hard for AI. |

Each pillar scores 0-100. The composite Readiness score is therefore also 0-100.

---

## 3. Data Collection Process

Readiness scoring inspects codebase structure, file content, and development infrastructure. This requires significantly more data than Adoption scoring (which focuses primarily on AI config files).

### What the Agent Must Fetch

The agent should use the GitHub API tree endpoint (`GET /repos/{owner}/{repo}/git/trees/{branch}?recursive=1`) to retrieve the full file listing in a single call. From there, it selectively fetches content for specific files.

| Data Category | What to Retrieve | Used By |
|---------------|------------------|---------|
| **Source file listing** | Full recursive tree — paths, sizes, types | R1 (organization, granularity, module boundaries) |
| **README.md** | Full content | R2 (README substance) |
| **Config files** | `.editorconfig`, linter configs, formatter configs, `tsconfig.json`, `Cargo.toml`, `*.cabal`, `stack.yaml`, `cabal.project` | R1 (config isolation), R2 (type coverage), R4 (ergonomics) |
| **Build/CI files** | `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, `buildkite/` | R3 (CI test execution), R4 (CI/CD pipeline) |
| **Language-specific files** | `*.cabal`, `Cargo.toml`, `package.json`, `tsconfig.json`, `pyproject.toml` | R1 (module boundaries), R2 (type config), language detection |
| **Test directories and files** | `test/`, `tests/`, `spec/`, `__tests__/`, `*_test.*`, `*.spec.*`, `*.test.*` | R3 (test existence, ratio, categorization) |
| **Documentation directories** | `docs/`, `doc/`, `adr/`, `decisions/`, `rfcs/` | R2 (ADRs/design docs) |
| **Lockfiles** | `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `Cargo.lock`, `cabal.project.freeze`, `flake.lock`, `stack.yaml.lock` | R4 (dependency lockfile), R3 (build reproducibility) |
| **Container/environment files** | `Dockerfile`, `docker-compose.yml`, `devcontainer.json`, `flake.nix`, `shell.nix`, `.envrc` | R3 (build reproducibility), R4 (reproducible environment) |
| **.gitignore** | Full content | R4 (git hygiene) |
| **CHANGELOG** | `CHANGELOG.md`, `HISTORY.md`, `CHANGES.md` | R2 (changelog) |
| **Pre-commit hooks** | `.husky/`, `.pre-commit-config.yaml`, `lefthook.yml` | R4 (pre-commit hooks) |
| **Task runner files** | `Makefile`, `Justfile`, `Taskfile.yml`, `scripts/` directory | R4 (task runner) |
| **Env templates** | `.env.example`, `.env.template`, `.env.sample` | R4 (env template) |

### Efficiency Guidelines

1. **One tree call first.** Fetch the recursive tree, then decide which files to retrieve content for. Do not make hundreds of individual file requests.
2. **Sample, do not exhaustively scan.** For metrics like median file size, sample source files from the tree metadata. For circular dependency analysis, sample the 10 largest source files.
3. **GitHub API language stats.** Use `GET /repos/{owner}/{repo}/languages` for language detection rather than analyzing every file extension manually.
4. **Cache within a scan.** If scoring multiple pillars for the same repo (which you always are), fetch data once and reuse across R1-R4.

---

## 4. R1: Structural Clarity (Weight: 30%)

**What it measures:** Can an AI agent (or a new human developer) understand where things are and how they connect?

### 4.1 Universal Signals

Each signal produces a score from 0 to 100, then is multiplied by its weight.

---

#### Signal 1: File Organization (weight: 0.15)

**Metric:** Depth and consistency of the directory tree.

| Condition | Score |
|-----------|-------|
| 3+ levels of meaningful nesting with clear, consistent hierarchy (e.g., `src/Domain/Ledger/`, `libs/core/src/`) | 100 |
| 3+ levels of nesting but some inconsistency (mixed conventions, orphan directories) | 75 |
| 2 levels of nesting with reasonable grouping | 50 |
| Flat structure with some directories (e.g., `src/` and `test/` but nothing deeper) | 25 |
| All files in root or a single directory | 0 |

**How to measure:** From the recursive tree, compute the maximum and median depth of source files (excluding `node_modules/`, `dist/`, `build/`, `.git/`). Count distinct directory prefixes at each level. Consistency means directories at the same level follow similar naming conventions.

---

#### Signal 2: File Granularity (weight: 0.20)

**Metric:** Median source file size in lines.

| Condition | Score |
|-----------|-------|
| Median < 150 lines | 100 |
| Median 150-300 lines | 75 |
| Median 300-500 lines | 50 |
| Median 500-1000 lines | 25 |
| Median > 1000 lines | 0 |

**Per-file penalty:** Each source file exceeding 1000 lines reduces the score by 2 points, capped at a maximum penalty of -10.

**How to measure:** The GitHub tree API returns file sizes in bytes. Estimate lines as `bytes / 40` for a rough heuristic (language-dependent; Haskell averages ~45 bytes/line, TypeScript ~35). For higher accuracy, sample 10-15 files across size quartiles and compute actual line counts. Use the median, not mean, to avoid skew from generated files.

**Exclusions:** Ignore generated files (`.g.dart`, `.generated.ts`, lockfiles, vendored code). Ignore test fixtures and data files. Focus on authored source files.

---

#### Signal 3: Module Boundaries (weight: 0.20)

**Metric:** Presence of explicit module or package definitions.

| Condition | Score |
|-----------|-------|
| Explicit exports + multi-package structure (monorepo with distinct packages, each with its own manifest) | 100 |
| Explicit exports OR multi-package structure (one but not both) | 75 |
| Some module organization (directories act as logical modules, but no explicit export control) | 50 |
| Minimal module structure (source files grouped loosely, no manifest-level boundaries) | 25 |
| No module boundaries (everything accessible from everywhere, single flat namespace) | 0 |

**How to measure:** Check for multi-package indicators: `cabal.project` with multiple packages, `Cargo.toml` with `[workspace]`, `pnpm-workspace.yaml`, `lerna.json`, `nx.json`. Check for explicit exports: Haskell module export lists, Rust `pub` discipline with `mod.rs`/`lib.rs`, TypeScript barrel files (`index.ts` re-exports), Python `__init__.py` with `__all__`.

---

#### Signal 4: Separation of Concerns (weight: 0.20)

**Metric:** Distinct directories mapping to distinct responsibilities.

| Condition | Score |
|-----------|-------|
| Clear 3+ layer separation (e.g., domain/application/infrastructure, or core/api/persistence, or model/view/controller with clean boundaries) | 100 |
| 2 distinct layers identifiable (e.g., `src/` and `api/` with different responsibilities) | 75 |
| Some separation but mixed concerns (business logic lives alongside HTTP handlers in the same directories) | 50 |
| Minimal separation (a `src/` directory exists but everything is mixed within it) | 25 |
| Everything mixed together (routes, business logic, database queries, utilities all interleaved) | 0 |

**How to measure:** Inspect directory names at the first two levels under `src/` (or equivalent). Look for architectural patterns: `domain/`, `application/`, `infrastructure/`, `ports/`, `adapters/`, `handlers/`, `services/`, `models/`, `views/`, `controllers/`, `api/`, `core/`, `lib/`. The presence of multiple distinct top-level groupings that map to different architectural concerns indicates separation.

---

#### Signal 5: Circular Dependency Risk (weight: 0.10)

**Metric:** Import/dependency graph structure, sampled from the 10 largest source files.

| Condition | Score |
|-----------|-------|
| No cycles detected in the sampled import graph | 100 |
| 1 minor cycle (two modules importing each other, easily refactored) | 75 |
| 2-3 cycles across different parts of the codebase | 50 |
| Multiple cycles (4+), some involving core modules | 25 |
| Severe tangling (core modules are in cycles, deep transitive circular imports) | 0 |

**How to measure:** Select the 10 largest source files by size. For each, retrieve the file and extract import statements. Trace imports 2 levels deep (what do the imported modules import?). Build a directed graph and check for cycles. This is a sample-based heuristic, not an exhaustive analysis.

**Language-specific import patterns:**
- Haskell: `import` and `import qualified` statements
- Rust: `use` statements and `mod` declarations
- TypeScript: `import` and `require` statements
- Python: `import` and `from ... import` statements

---

#### Signal 6: Entry Point Clarity (weight: 0.05)

**Metric:** How easy is it to find where execution starts.

| Condition | Score |
|-----------|-------|
| Clear main/index/app file + documented in README or config (e.g., `main` field in `package.json`, `main-is` in `.cabal`) | 100 |
| Main file identifiable by convention (`Main.hs`, `main.rs`, `index.ts`, `app.py`) | 75 |
| Multiple entry points, all clearly named and organized (CLI + library + server) | 50 |
| Entry point exists but hard to find (buried in directory structure, unconventional name) | 25 |
| No clear entry point (common in poorly organized libraries or legacy codebases) | 0 |

**How to measure:** Search the file tree for conventional entry point names. Check manifest files for entry point declarations (`main-is` in `.cabal`, `main` in `package.json`, `[[bin]]` in `Cargo.toml`). For libraries, check whether there is a clear public API module (`lib.rs`, `Lib.hs`, package `main` field).

---

#### Signal 7: Configuration Isolation (weight: 0.10)

**Metric:** Configuration separated from application logic.

| Condition | Score |
|-----------|-------|
| Dedicated config directory + env template (`.env.example`) + config loading mechanism evident | 100 |
| Config files in dedicated, predictable locations (e.g., `config/`, root-level dotfiles) | 75 |
| Some config files exist but some values are hardcoded in source | 50 |
| Mostly hardcoded with some extraction into environment variables | 25 |
| No config separation (connection strings, API keys, feature flags all inline in source) | 0 |

**How to measure:** Look for `config/` directories, `.env.example` or `.env.template`, dedicated config-loading modules. Check a sample of source files for hardcoded values (string literals that look like URLs, ports, credentials). The presence of environment variable references in source code (`process.env`, `std::env`, `System.Environment`) is a positive signal.

---

### 4.2 R1 Formula

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

R1_language_bonus = sum(applicable_language_signals)  # capped at +15

R1 = min(100, R1_raw + R1_language_bonus)
```

Weights sum to 1.00, so `R1_raw` is on a 0-100 scale. Language bonuses can push the score above what universal signals alone produce, but the final score is capped at 100.

---

### 4.3 R1 Language-Specific Bonuses

Language bonuses reward ecosystem-specific practices that enhance structural clarity beyond what universal signals capture. The total bonus per pillar is **capped at +15**, even if individual signals sum to more.

#### Haskell R1 Bonuses

| Signal | What to Check | Bonus | How to Verify |
|--------|---------------|-------|---------------|
| Module hierarchy | `src/` directory with 3+ levels of module nesting | +5 | Tree depth under `src/`: count directory levels. Modules like `Cardano.Ledger.Core.Era` indicate 4 levels. |
| Explicit exports | >70% of modules have explicit export lists (not bare `module X where`) | +8 | Sample 20 `.hs` files. Check whether the `module` declaration includes a parenthesized export list. Bare `module Foo where` = export-all. `module Foo (bar, baz) where` = explicit exports. |
| Cabal/Stack structure | Well-organized `.cabal` file with `library`, `executable`, and `test-suite` stanzas | +5 | Parse `.cabal` file for stanza headers. All three present = full bonus. Two of three = +3. |
| Internal modules | `Internal` module pattern for implementation hiding | +3 | Search tree for paths containing `/Internal/` or filenames like `Internal.hs`. Presence in multiple packages = bonus. |
| Package boundaries | Multi-package project (`cabal.project` with multiple packages) | +5 | Check for `cabal.project` file. Count `packages:` entries or glob patterns. 2+ packages = bonus. |
| Typeclass discipline | Typeclasses defined in their own modules, orphan instances minimized | +3 | Search for `{-# OPTIONS_GHC -Wno-orphans #-}` or files named `Orphans.hs`. Fewer orphan markers = more disciplined. Typeclasses in dedicated modules (e.g., `Class.hs`, `Types.hs`) = bonus. |

**Maximum possible Haskell R1 bonus: 29 points, capped at +15.**

#### Rust R1 Bonuses

| Signal | What to Check | Bonus | How to Verify |
|--------|---------------|-------|---------------|
| Workspace structure | `Cargo.toml` with `[workspace]` and multiple member crates | +5 | Parse root `Cargo.toml` for `[workspace]` section. Count `members` entries. |
| Crate granularity | Average LOC per crate < 2000 | +3 | Estimate total LOC from tree metadata. Divide by crate count. |
| `pub` visibility discipline | < 40% of functions/structs are `pub` | +5 | Sample 10 `.rs` files. Count `pub fn` and `pub struct` vs total `fn` and `struct`. Ratio < 0.4 = disciplined. |
| Module tree | Clean `mod` declarations, no `#[path = "..."]` hacks | +3 | Search sample files for `#[path`. Absence = clean module tree. |
| Feature flags | `[features]` section in `Cargo.toml` | +3 | Check root and member `Cargo.toml` files for `[features]`. |
| Error type hierarchy | Custom error types with `thiserror` or manual `impl` | +5 | Search for `thiserror` in dependencies or `impl.*Error` / `impl.*Display` patterns in source. |

**Maximum possible Rust R1 bonus: 24 points, capped at +15.**

#### TypeScript R1 Bonuses

| Signal | What to Check | Bonus | How to Verify |
|--------|---------------|-------|---------------|
| Path aliases | `tsconfig.json` has `paths` configured | +5 | Parse `tsconfig.json` for `compilerOptions.paths`. Non-empty = bonus. |
| Barrel files | `index.ts` re-export files per module directory | +3 | Count directories under `src/` that contain an `index.ts`. 3+ = full bonus. 1-2 = +1. |
| Monorepo workspace | `pnpm-workspace.yaml`, `nx.json`, or `turbo.json` present | +5 | Check tree for these files at root level. |
| Shared types package | `packages/types/` or `@org/types` dependency | +5 | Search tree for `packages/types/` directory. Or parse `package.json` dependencies for `@*/types`. |
| Layered architecture | 3+ architectural layers identifiable in directory structure | +8 | Look for directories like `domain/`, `application/`, `infrastructure/`, `presentation/`, `api/`, `services/`, `repositories/`. 3+ distinct architectural layers = full bonus. |

**Maximum possible TypeScript R1 bonus: 26 points, capped at +15.**

---

## 5. R2: Semantic Density (Weight: 30%)

**What it measures:** How much *meaning* is encoded in the codebase beyond the executable logic? Types, documentation, naming, and schemas are the primary channels through which an AI agent understands developer intent.

### 5.1 Universal Signals

---

#### Signal 1: Type Coverage (weight: 0.25)

**Metric:** Proportion of code with type annotations or strong type inference.

| Condition | Score |
|-----------|-------|
| Language is statically typed with full inference (Haskell, Rust) or `strict: true` in TypeScript | 100 |
| Typed language with most code annotated (>80% of functions have explicit types) | 85 |
| Typed language with moderate annotations (50-80%) | 65 |
| Typed language with sparse annotations (<50%) or `strict: false` | 40 |
| Dynamically typed with type hints (Python type hints >50%, JSDoc in JavaScript) | 50 |
| Dynamically typed with sparse type hints (<50%) | 25 |
| Dynamically typed with no type hints at all | 0 |

**How to measure:** This is language-dependent:
- **Haskell/Rust:** Start at 100 (statically typed with inference). Penalize only if explicit signatures are missing where expected (Haskell top-level bindings without signatures).
- **TypeScript:** Check `tsconfig.json` for `strict: true`. If present, start at 100. If `strict: false` or absent, start at 40 and adjust based on how many `any` types appear.
- **Python:** Search for `def` statements and check whether they have `: type` return annotations. Estimate percentage.
- **JavaScript:** Check for JSDoc `@param` and `@returns` annotations. Or presence of `// @ts-check` directives.

---

#### Signal 2: Schema Definitions (weight: 0.15)

**Metric:** Explicit data shape definitions at system boundaries.

| Condition | Score |
|-----------|-------|
| Schema definitions at all major boundaries (API, database, events) using dedicated schema tools | 100 |
| Schema definitions at most boundaries (e.g., OpenAPI for API but no DB schema) | 75 |
| Some schema definitions (e.g., Zod schemas for validation in a few places) | 50 |
| Minimal schemas (only what the framework requires, like database migrations) | 25 |
| No explicit schema definitions anywhere | 0 |

**What counts as a schema definition:** Protobuf (`.proto`), OpenAPI/Swagger (`openapi.yaml`, `swagger.json`), JSON Schema, GraphQL SDL (`.graphql`), Pydantic models, Zod schemas, io-ts codecs, Valibot schemas, database migration files with explicit column types, CDDL specifications, Avro schemas.

**How to measure:** Search the file tree for schema file extensions and directories (`.proto`, `.graphql`, `schemas/`, `openapi/`). Search source files for schema library imports (`zod`, `io-ts`, `pydantic`, `serde`).

---

#### Signal 3: Documentation Ratio (weight: 0.20)

**Metric:** Doc comments per public function/type.

| Condition | Score |
|-----------|-------|
| >70% of public functions/types have doc comments | 100 |
| 50-70% coverage | 75 |
| 40-50% coverage | 60 |
| 20-40% coverage | 40 |
| 10-20% coverage | 20 |
| <10% coverage | 0 |

**How to measure:** Sample 15-20 source files across the codebase. For each, count public declarations and count those preceded by doc comments:
- **Haskell:** `-- |` or `-- ^` Haddock comments before exported functions
- **Rust:** `///` or `//!` doc comments before `pub` items
- **TypeScript:** `/** */` JSDoc comments before exported functions
- **Python:** Triple-quoted docstrings immediately after `def` or `class`

Compute the ratio across all sampled files.

---

#### Signal 4: README Substance (weight: 0.10)

**Metric:** README structural quality, scored by section presence.

Each meaningful section present earns 1 point, mapped to a 0-100 scale:

| Section | What Qualifies | Points |
|---------|---------------|--------|
| Description | Project purpose explained in 2+ sentences (not just the repo name) | 1 |
| Setup / Installation | Steps to build and run from scratch | 1 |
| Usage | How to use the software (examples, CLI commands, API usage) | 1 |
| Architecture | System design, component relationships, directory structure explanation | 1 |
| Contributing | How to contribute, PR process, coding standards | 1 |

| Points | Score |
|--------|-------|
| 5 | 100 |
| 4 | 80 |
| 3 | 60 |
| 2 | 40 |
| 1 | 20 |
| 0 | 0 |

**How to measure:** Fetch `README.md` content. Search for section headings (lines starting with `#` or `##`) that match keywords: "install", "setup", "getting started", "usage", "example", "architecture", "design", "structure", "contributing", "development". Score each section as present only if it contains substantive content (more than a heading and one sentence).

---

#### Signal 5: ADRs / Design Docs (weight: 0.10)

**Metric:** Presence, count, and recency of architectural decision records or design documents.

| Condition | Score |
|-----------|-------|
| 5+ ADRs/design docs, at least one within last 6 months | 100 |
| 3-4 ADRs/design docs with some recency | 75 |
| 1-2 ADRs/design docs | 50 |
| Design docs exist but in an ad hoc format (scattered markdown files) | 25 |
| No design documentation at all | 0 |

**How to measure:** Search the tree for directories: `docs/decisions/`, `docs/adr/`, `adr/`, `decisions/`, `rfcs/`, `docs/rfcs/`. Count files within. Check commit dates on the most recent files for recency. Also check for `ARCHITECTURE.md` at root.

---

#### Signal 6: Naming Quality (weight: 0.10)

**Metric:** Average identifier length and vocabulary richness.

| Condition | Score |
|-----------|-------|
| Average exported identifier length 12-25 characters, domain terms used consistently | 100 |
| Average 8-25 characters, reasonable naming | 75 |
| Average 5-8 characters, somewhat terse but understandable | 50 |
| Average 3-5 characters, heavily abbreviated | 25 |
| Average < 3 characters (single-letter variables dominate) | 0 |

**How to measure:** Sample 10 source files. Extract exported function/type names (language-dependent). Compute average character length. This is a rough heuristic — the agent should also qualitatively assess whether names convey meaning (e.g., `processTransaction` is better than `proc`, regardless of length).

**Language-specific calibration:**
- Haskell tends toward shorter names due to pattern matching and point-free style. Adjust threshold: 6-20 characters = good.
- Rust is similar to Haskell. Adjust: 6-20 characters = good.
- TypeScript/JavaScript tend longer. Standard threshold: 8-25 characters.

---

#### Signal 7: API Documentation (weight: 0.05)

**Metric:** Presence and completeness of API documentation.

| Condition | Score |
|-----------|-------|
| Generated API docs (Haddock, rustdoc, TypeDoc) + OpenAPI/Swagger for HTTP APIs | 100 |
| Generated API docs OR OpenAPI spec (one but not both) | 75 |
| API examples in README or dedicated examples directory | 50 |
| Some API documentation but incomplete or outdated | 25 |
| No API documentation | 0 |

**How to measure:** Check for documentation generation configuration: Haddock flags in `.cabal`, `rustdoc` CI step, `typedoc.json`, `swagger-jsdoc` config. Check for OpenAPI/Swagger files. Check for `examples/` directory.

---

#### Signal 8: CHANGELOG (weight: 0.05)

**Metric:** Presence and quality of a changelog.

| Condition | Score |
|-----------|-------|
| `CHANGELOG.md` present, follows Keep a Changelog or Conventional Changelog format, recent entries | 100 |
| `CHANGELOG.md` present with structured format but not fully up to date | 75 |
| `CHANGELOG.md` or `HISTORY.md` present but unstructured | 50 |
| Release notes only (GitHub Releases, no committed changelog) | 25 |
| No changelog or release notes | 0 |

**How to measure:** Check tree for `CHANGELOG.md`, `CHANGES.md`, `HISTORY.md`. If present, fetch content and check for structured headings (version numbers, dates). Check GitHub Releases via API as a fallback.

---

### 5.2 R2 Formula

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

R2_language_bonus = sum(applicable_language_signals)  # capped at +15

R2 = min(100, R2_raw + R2_language_bonus)
```

---

### 5.3 R2 Language-Specific Bonuses

#### Haskell R2 Bonuses

| Signal | What to Check | Bonus | How to Verify |
|--------|---------------|-------|---------------|
| `-Wall -Werror` in ghc-options | Strict compiler warnings enabled | +8 | Parse `.cabal` file `ghc-options` for `-Wall` and `-Werror`. Both present = full bonus. `-Wall` only = +5. |
| Haddock documentation coverage | Haddock comments on exported symbols | +8 | Sample 15 modules. Check for `-- |` or `-- ^` comments on exported declarations. >70% coverage = full bonus. 40-70% = +4. |
| Type signatures on all top-level bindings | Explicit type annotations | +10 | Sample 15 modules. Check that top-level bindings have type signatures above them. >90% = full bonus. 70-90% = +6. <70% = +0. This is the single most critical Haskell semantic signal. |
| Newtypes for domain concepts | `newtype` usage vs raw primitives | +5 | Search for `newtype` declarations in source files. 5+ meaningful newtypes (not just deriving wrappers) = full bonus. |
| `DerivingStrategies` extension | Explicit deriving strategy annotations | +3 | Search `.cabal` `default-extensions` or file-level `{-# LANGUAGE DerivingStrategies #-}`. |
| Refined types or smart constructors | `refined` library or manual smart constructor pattern | +5 | Search for `Refined` imports or pattern of unexported constructors with exported smart constructor functions (`mk*` pattern). |

**Maximum possible Haskell R2 bonus: 39 points, capped at +15.**

#### Rust R2 Bonuses

| Signal | What to Check | Bonus | How to Verify |
|--------|---------------|-------|---------------|
| `#![deny(missing_docs)]` | Enforced documentation | +10 | Search `lib.rs` or `main.rs` for this attribute. |
| `#![forbid(unsafe_code)]` or scoped `unsafe` | Safety discipline | +5 (forbid) / +3 (minimal scoped) | Search for `forbid(unsafe_code)`. If absent, count `unsafe` blocks — fewer than 5 across codebase = +3. |
| Doc comments (`///`) coverage | Doc comments on `pub` items | +8 | Sample 15 files. Count `pub fn` / `pub struct` with `///` comments above them. >70% = full bonus. |
| `clippy.toml` or `#![warn(clippy::all)]` | Lint discipline | +5 | Check tree for `clippy.toml`. Search source for `warn(clippy`. |
| Type-state pattern usage | State machines encoded in types | +5 | Search for generic types used as state markers (heuristic: multiple structs with same name prefix and different type parameters). |
| `serde` derive with explicit attributes | Structured serialization | +3 | Search for `#[derive(Serialize, Deserialize)]` with `#[serde(rename_all`, `#[serde(deny_unknown_fields)]` or similar attribute customization. |

**Maximum possible Rust R2 bonus: 36 points, capped at +15.**

#### TypeScript R2 Bonuses

| Signal | What to Check | Bonus | How to Verify |
|--------|---------------|-------|---------------|
| `strict: true` in tsconfig | Full strict mode enabled | +10 | Parse `tsconfig.json` for `compilerOptions.strict`. This is the single most critical TypeScript semantic signal. |
| `noUncheckedIndexedAccess` | Extra strictness beyond baseline `strict` | +3 | Check `tsconfig.json` for this compiler option. |
| Zod/io-ts/Valibot schemas | Runtime validation at boundaries | +8 | Search `package.json` dependencies for `zod`, `io-ts`, `valibot`. Search source for import statements. |
| JSDoc on exported functions | Documentation beyond types | +5 | Sample 10 `.ts` files. Check for `/** */` comments on exported functions. >50% coverage = full bonus. |
| Generic type usage | Meaningful use of generics | +3 | Search for generic type definitions (`<T>`, `<T extends`) in type declarations. Present in >10% of type definitions = bonus. |
| `any` count | Explicit `any` usage | Penalty: -2 per 10 occurrences, cap -10 | Search all `.ts` files for `: any`, `as any`, `<any>`. Count total occurrences. This is a penalty, not a bonus. |
| Type-only imports | `import type { }` usage | +2 | Search for `import type` statements. Presence in >30% of imports = bonus. |

**Maximum possible TypeScript R2 bonus: 31 points (minus any penalties), capped at +15.**

---

## 6. R3: Verification Infrastructure (Weight: 25%)

**What it measures:** Can changes be validated automatically? An AI agent that cannot verify its own output is guessing, not engineering.

### HARD GATE

**If zero tests exist in the repository, R3 is hard-capped at 15 regardless of all other signals.** Build reproducibility and CI configuration alone cannot substitute for the ability to verify correctness.

The agent determines "zero tests" as: no files matching test patterns (`test/`, `tests/`, `spec/`, `__tests__/`, `*_test.*`, `*.test.*`, `*.spec.*`, `Test*.hs`, `*Spec.hs`, `*_test.go`) AND no test-suite stanza in build manifests (`.cabal`, `Cargo.toml` `[[test]]`, `package.json` `scripts.test` pointing to a real command).

---

### 6.1 Universal Signals

---

#### Signal 1: Test Existence (GATE — not weighted)

**Metric:** Binary — do tests exist?

| Condition | Effect |
|-----------|--------|
| Tests exist (any test files or test configuration found) | Gate passes; proceed to weighted scoring |
| No tests exist at all | **R3 hard-capped at 15.** All other signals scored normally but final R3 cannot exceed 15. |

**How to measure:** Search tree for test directories and files (patterns listed above). Check build manifests for test stanzas. Check CI workflows for test execution steps.

This signal does not carry a weight in the formula — it is a precondition. If the gate fails, the remaining signals still get scored (for diagnostic purposes and to show what the repo does have), but R3 is capped.

---

#### Signal 2: Test/Source Ratio (weight: 0.25)

**Metric:** Number of test files divided by number of source files.

| Condition | Score |
|-----------|-------|
| Ratio > 0.7 (more than 7 test files per 10 source files) | 100 |
| Ratio 0.4-0.7 | 75 |
| Ratio 0.2-0.4 | 50 |
| Ratio 0.1-0.2 | 25 |
| Ratio < 0.1 | 0 |

**How to measure:** Count files matching test patterns. Count files matching source patterns (language-specific extensions, excluding generated files). Compute the ratio. For monorepos, compute per-package ratios and average them.

**Note:** Some languages co-locate tests with source (Rust `#[cfg(test)] mod tests`). For Rust, count `.rs` files containing `#[cfg(test)]` as having tests, and adjust the ratio calculation accordingly — a file that contains both source and tests counts as 1 source file with tests, not 0 test files.

---

#### Signal 3: Test Categorization (weight: 0.15)

**Metric:** Distinct test categories present (unit, integration, end-to-end, property-based).

| Condition | Score |
|-----------|-------|
| 3+ distinct test categories clearly organized | 100 |
| 2 categories (e.g., unit + integration) | 75 |
| 1 category but well-organized | 50 |
| Tests exist but no categorization (everything in one directory, no naming convention) | 25 |
| No test categorization at all | 0 |

**How to measure:** Look for directory structure: `test/unit/`, `test/integration/`, `test/e2e/`, `tests/property/`. Look for naming conventions: `*.unit.test.ts`, `*.integration.test.ts`. Look for test framework features: property-based testing libraries (`QuickCheck`, `Hedgehog`, `proptest`, `fast-check`), E2E frameworks (`Playwright`, `Cypress`). Each distinct category found = 1 point toward the score.

---

#### Signal 4: Test Framework Configuration (weight: 0.10)

**Metric:** Dedicated configuration file for the test runner.

| Condition | Score |
|-----------|-------|
| Test framework config present with custom settings (timeouts, patterns, reporters) | 100 |
| Test framework config present with minimal customization | 60 |
| Test execution configured only in build manifest (e.g., `scripts.test` in `package.json` with no separate config) | 30 |
| No test framework configuration | 0 |

**How to measure:** Search tree for test config files: `jest.config.*`, `vitest.config.*`, `.mocharc.*`, `pytest.ini`, `pyproject.toml [tool.pytest]`, `conftest.py`, `tasty.hs` test runner config, `.cargo/config.toml` test settings, `cypress.config.*`, `playwright.config.*`.

---

#### Signal 5: Coverage Configuration (weight: 0.10)

**Metric:** Code coverage tool configured.

| Condition | Score |
|-----------|-------|
| Coverage configured with thresholds enforced in CI | 100 |
| Coverage tool configured and runs (but no enforcement) | 60 |
| Coverage tool present in dependencies but not configured | 30 |
| No coverage tooling | 0 |

**How to measure:** Check for coverage configuration: `c8`, `istanbul`/`nyc` config, `vitest --coverage`, `cargo-tarpaulin`, `llvm-cov` in CI, `hpc` configuration, `coverage.py`, `.coveragerc`. Check CI workflows for coverage steps and threshold assertions.

---

#### Signal 6: CI Test Execution (weight: 0.20)

**Metric:** Tests run in CI pipeline on every push or PR.

| Condition | Score |
|-----------|-------|
| Tests run on every PR + push to main, with results reported and blocking merge on failure | 100 |
| Tests run on PR only, blocking merge | 80 |
| Tests run in CI but not blocking (informational) | 50 |
| CI pipeline exists but does not run tests | 20 |
| No CI pipeline at all | 0 |

**How to measure:** Parse `.github/workflows/*.yml` for steps that execute tests (`run: npm test`, `run: cargo test`, `run: cabal test`, `run: pytest`). Check for `if: failure()` or status check requirements in branch protection. Check for `required_status_checks` via GitHub API if accessible.

---

#### Signal 7: Test Fixtures / Factories (weight: 0.10)

**Metric:** Organized test data and helper infrastructure.

| Condition | Score |
|-----------|-------|
| Dedicated fixtures/factories directory with organized test helpers | 100 |
| Test helpers exist (shared setup functions, builder patterns) but not in dedicated directories | 60 |
| Some test data files scattered across test directories | 30 |
| No test fixtures or helpers (each test sets up its own data inline) | 0 |

**How to measure:** Search tree for `fixtures/`, `factories/`, `testdata/`, `__fixtures__/`, `test-helpers/`, `test/support/`. Check test files for shared setup modules or helper imports.

---

#### Signal 8: Build Reproducibility (weight: 0.10)

**Metric:** Lockfile present + deterministic build mechanism.

| Condition | Score |
|-----------|-------|
| Lockfile + Nix flake or equivalent fully deterministic build | 100 |
| Lockfile + Dockerfile or devcontainer | 80 |
| Lockfile committed and up to date | 50 |
| Lockfile present but not committed (in `.gitignore`) | 20 |
| No lockfile | 0 |

**How to measure:** Check for lockfiles (see Section 3 data collection list). Check for `flake.nix`, `shell.nix`, `Dockerfile`, `docker-compose.yml`, `.devcontainer/devcontainer.json`. A committed lockfile is the baseline; a Nix flake is the gold standard for reproducibility.

---

### 6.2 R3 Formula

```
# Score all signals normally first:
R3_raw = (
    test_source_ratio_score      * 0.25 +
    test_categorization_score    * 0.15 +
    test_framework_config_score  * 0.10 +
    coverage_config_score        * 0.10 +
    ci_test_execution_score      * 0.20 +
    test_fixtures_score          * 0.10 +
    build_reproducibility_score  * 0.10
)

R3_language_bonus = sum(applicable_language_signals)  # capped at +15

R3_before_gate = min(100, R3_raw + R3_language_bonus)

# Apply hard gate:
if no_tests_exist:
    R3 = min(15, R3_before_gate)
else:
    R3 = R3_before_gate
```

Note: The weighted signals sum to 1.00 (test existence is a gate, not a weighted signal). Even if the hard gate is active, the agent should still compute and report the full signal breakdown for diagnostic value.

---

### 6.3 R3 Language-Specific Bonuses

#### Haskell R3 Bonuses

| Signal | What to Check | Bonus | How to Verify |
|--------|---------------|-------|---------------|
| `test-suite` stanza in `.cabal` | Test suite formally defined in build manifest | +5 | Parse `.cabal` for `test-suite` section header. **Gate:** without this, Haskell R3 cannot exceed 30 even if test files exist informally. |
| HSpec / Tasty / HUnit | Recognized test framework | +5 | Check `.cabal` `build-depends` for `hspec`, `tasty`, `HUnit`, `tasty-hunit`, `tasty-hspec`. |
| QuickCheck / Hedgehog properties | Property-based testing | +8 | Check `.cabal` `build-depends` for `QuickCheck`, `hedgehog`, `tasty-quickcheck`, `tasty-hedgehog`. This is the highest-value Haskell testing signal — property tests give AI agents strong correctness feedback. |
| `hpc` or coverage config | Coverage tooling | +3 | Check CI workflows for `cabal test --enable-coverage` or `stack test --coverage`. |
| `cabal test` / `stack test` in CI | CI execution of Haskell tests | +3 | Parse workflow files for test commands. |
| Doctest | Executable documentation (`doctest` package) | +5 | Check `build-depends` for `doctest`. Check for `doctest-discover` or `doctest` in `test-suite` stanza `main-is`. |
| Golden tests | `tasty-golden` or similar | +3 | Check `build-depends` for `tasty-golden`. |

**Maximum possible Haskell R3 bonus: 32 points, capped at +15.**

#### Rust R3 Bonuses

| Signal | What to Check | Bonus | How to Verify |
|--------|---------------|-------|---------------|
| `#[cfg(test)] mod tests` | Inline test modules in source files | +5 | Sample 10 `.rs` files. Check for `#[cfg(test)]`. Presence in >50% = full bonus. |
| `tests/` integration test directory | Separate integration tests | +5 | Check tree for `tests/` directory at crate roots. |
| `proptest` or `quickcheck` in dev-dependencies | Property testing | +5 | Parse `Cargo.toml` `[dev-dependencies]` for `proptest`, `quickcheck`. |
| `criterion` or `divan` in dev-dependencies | Benchmark suite | +3 | Parse `Cargo.toml` for `criterion`, `divan`. |
| `cargo-tarpaulin` or `llvm-cov` in CI | Coverage tooling | +3 | Search CI workflow for `tarpaulin`, `llvm-cov`, `cargo llvm-cov`. |
| `cargo clippy` in CI | Lint as verification step | +3 | Search CI workflow for `cargo clippy`. |

**Maximum possible Rust R3 bonus: 24 points, capped at +15.**

#### TypeScript R3 Bonuses

| Signal | What to Check | Bonus | How to Verify |
|--------|---------------|-------|---------------|
| Jest/Vitest/Mocha config | Test framework present and configured | +5 | Check tree for `jest.config.*`, `vitest.config.*`, `.mocharc.*`. **Gate:** without this, TypeScript R3 cannot exceed 30. |
| `*.test.ts` or `*.spec.ts` convention | Consistent test naming | +3 | Count test files by extension pattern. Consistent use of one convention = bonus. |
| `@testing-library/*` | Component testing for UI projects | +3 | Check `package.json` for `@testing-library/react`, `@testing-library/vue`, etc. Only applicable if UI framework detected. |
| Playwright/Cypress config | E2E testing | +5 | Check tree for `playwright.config.*`, `cypress.config.*`, `cypress/`. |
| `package.json` test script | `npm test` works | +3 | Check `package.json` `scripts.test` is not the default `echo "Error: no test specified"`. |
| Coverage tooling | `c8`, `istanbul`, `vitest --coverage` | +3 | Check `package.json` dependencies or vitest config for coverage settings. |

**Maximum possible TypeScript R3 bonus: 22 points, capped at +15.**

---

## 7. R4: Developer Ergonomics (Weight: 15%)

**What it measures:** How smooth is the development loop? Good ergonomics reduce friction for both humans and AI agents — an AI that can lint, format, and run tasks in a standardized way produces more consistent output.

### 7.1 Universal Signals

---

#### Signal 1: Linter Configured (weight: 0.15)

**Metric:** Language-appropriate linter with configuration file.

| Condition | Score |
|-----------|-------|
| Linter configured with custom rules adapted to the project | 100 |
| Linter config present with default or minimal customization | 70 |
| Linter runs in CI but no committed config file | 40 |
| Linter mentioned in docs but not configured | 15 |
| No linter | 0 |

**How to measure:** Search tree for linter configs: `.eslintrc.*`, `eslint.config.*`, `.hlint.yaml`, `hlint.yaml`, `clippy.toml`, `.pylintrc`, `ruff.toml`, `.golangci.yml`. Check if config has project-specific rules (file size > 100 bytes typically indicates customization beyond defaults).

---

#### Signal 2: Formatter Configured (weight: 0.10)

**Metric:** Auto-formatter with configuration.

| Condition | Score |
|-----------|-------|
| Formatter configured and enforced (CI checks formatting) | 100 |
| Formatter config present | 60 |
| Formatter mentioned in contributing docs but no config | 25 |
| No formatter | 0 |

**How to measure:** Search tree for: `.prettierrc*`, `prettier.config.*`, `.rustfmt.toml`, `rustfmt.toml`, `fourmolu.yaml`, `.ormolu`, `.stylish-haskell.yaml`, `pyproject.toml [tool.black]`, `.editorconfig`. Check CI workflows for format-check steps (`prettier --check`, `cargo fmt -- --check`, `fourmolu --mode check`).

---

#### Signal 3: Pre-commit Hooks (weight: 0.10)

**Metric:** Git hooks configured and non-empty.

| Condition | Score |
|-----------|-------|
| Pre-commit hooks run linting, formatting, and/or tests | 100 |
| Pre-commit hooks present with basic checks | 60 |
| Hook framework present but hooks are minimal or empty | 25 |
| No pre-commit hooks | 0 |

**How to measure:** Search tree for `.husky/`, `.pre-commit-config.yaml`, `lefthook.yml`, `.git/hooks/` (not accessible via GitHub API — check for hook configuration files instead). Check that hook config files are non-empty and reference meaningful commands.

---

#### Signal 4: Editor Config (weight: 0.05)

**Metric:** Editor/IDE settings committed to the repository.

| Condition | Score |
|-----------|-------|
| `.editorconfig` + IDE-specific settings (`.vscode/settings.json`, `hie.yaml`, `rust-analyzer` config) | 100 |
| `.editorconfig` present | 60 |
| IDE-specific settings only (no `.editorconfig`) | 40 |
| No editor configuration | 0 |

**How to measure:** Search tree for `.editorconfig`, `.vscode/`, `.idea/`, `hie.yaml`, `.vim/`, `.nvim/`.

---

#### Signal 5: CI/CD Pipeline (weight: 0.20)

**Metric:** Workflow files present, non-trivial, and recently executed.

| Condition | Score |
|-----------|-------|
| CI/CD pipeline with build + test + deploy stages, recently executed | 100 |
| CI pipeline with build + test, recently executed | 80 |
| CI pipeline exists and runs but is minimal (build only) | 50 |
| CI workflow files exist but appear non-functional or stale | 20 |
| No CI/CD pipeline | 0 |

**How to measure:** Count workflow files in `.github/workflows/`. Parse YAML for job steps — look for build, test, and deploy stages. Check GitHub API for recent workflow runs. "Recently executed" means a successful run within the last 30 days.

---

#### Signal 6: Reproducible Environment (weight: 0.15)

**Metric:** Mechanism for reproducing the development environment.

| Condition | Score |
|-----------|-------|
| Nix flake with `devShell` or equivalent fully deterministic environment | 100 |
| Docker/devcontainer with comprehensive setup | 80 |
| Docker or devcontainer with basic setup | 60 |
| Shell script for setup (`setup.sh`, `bootstrap.sh`) | 40 |
| README instructions only | 15 |
| No reproducibility mechanism | 0 |

**How to measure:** Search tree for `flake.nix` (check for `devShells` or `devShell` output), `shell.nix`, `.devcontainer/devcontainer.json`, `Dockerfile`, `docker-compose.yml`, `setup.sh`, `bootstrap.sh`, `.envrc`. Nix flakes get the highest score because they provide fully deterministic, cross-platform development environments.

---

#### Signal 7: Task Runner (weight: 0.10)

**Metric:** Standardized way to run common tasks.

| Condition | Score |
|-----------|-------|
| Task runner with 5+ documented tasks (build, test, lint, format, run) | 100 |
| Task runner with 3-4 tasks | 70 |
| Task runner with 1-2 tasks or basic `Makefile` | 40 |
| `scripts/` directory with ad hoc scripts | 25 |
| No task runner | 0 |

**How to measure:** Search tree for `Makefile`, `Justfile`, `Taskfile.yml`, `package.json` scripts section, `scripts/` directory. If present, count distinct task targets/scripts.

---

#### Signal 8: Env Template (weight: 0.05)

**Metric:** Documented environment variables.

| Condition | Score |
|-----------|-------|
| `.env.example` or `.env.template` with comments explaining each variable | 100 |
| `.env.example` present with variable names (no comments) | 60 |
| Environment variables documented in README only | 30 |
| No env documentation | 0 |

**How to measure:** Search tree for `.env.example`, `.env.template`, `.env.sample`. If present, fetch content and check for comments or documentation.

---

#### Signal 9: Dependency Lockfile (weight: 0.05)

**Metric:** Appropriate lockfile present and committed.

| Condition | Score |
|-----------|-------|
| Lockfile committed and appropriate for the language (e.g., `package-lock.json`, `Cargo.lock`, `cabal.project.freeze`, `flake.lock`) | 100 |
| Lockfile present but appears stale or incomplete | 50 |
| Lockfile in `.gitignore` (deliberately not committed) | 25 |
| No lockfile | 0 |

**How to measure:** Search tree for lockfiles. Check `.gitignore` for lockfile exclusions. For libraries vs applications: note that some ecosystems recommend not committing lockfiles for libraries (e.g., `Cargo.lock` for Rust libraries). The agent should annotate rather than penalize if this is a deliberate choice.

---

#### Signal 10: Git Hygiene (weight: 0.05)

**Metric:** Comprehensive `.gitignore` and no large binaries tracked.

| Condition | Score |
|-----------|-------|
| Comprehensive `.gitignore` covering build artifacts, IDE files, OS files, secrets; no large binaries tracked | 100 |
| Good `.gitignore` with minor gaps | 70 |
| Basic `.gitignore` (language template only) | 40 |
| Minimal `.gitignore` (few entries) | 20 |
| No `.gitignore` | 0 |

**How to measure:** Fetch `.gitignore` content. Count entries. Check for coverage of common categories: build output (`dist/`, `build/`, `target/`), IDE files (`.idea/`, `.vscode/`), OS files (`.DS_Store`, `Thumbs.db`), secrets (`.env`), dependencies (`node_modules/`, `.stack-work/`). Check tree for obviously tracked binaries (`.jar`, `.dll`, `.exe`, large `.png` collections).

---

### 7.2 R4 Formula

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

R4_language_bonus = sum(applicable_language_signals)  # capped at +15

R4 = min(100, R4_raw + R4_language_bonus)
```

---

### 7.3 R4 Language-Specific Bonuses

#### Haskell R4 Bonuses

| Signal | What to Check | Bonus | How to Verify |
|--------|---------------|-------|---------------|
| `ormolu` / `fourmolu` / `stylish-haskell` config | Haskell-specific formatter | +3 | Search tree for `fourmolu.yaml`, `.ormolu`, `.stylish-haskell.yaml`, or check CI for formatter invocation. |
| `hlint.yaml` or `.hlint.yaml` | HLint linter configuration | +5 | Search tree for `hlint.yaml`, `.hlint.yaml`. Check for custom rules (file size > 50 bytes). |
| `stack.yaml` or `cabal.project` | Build tool configuration present | +3 | Search tree for these files. Check for non-trivial content. |
| `hie.yaml` or HLS config | IDE/LSP support | +3 | Search tree for `hie.yaml`, `hie-bios` config, `.hie-bios`. |
| Nix flake for Haskell build | Reproducible Haskell build | +8 | Search for `flake.nix`. Check content for `haskell.nix`, `haskell-flake`, or GHC toolchain provisioning. Haskell builds are notoriously environment-sensitive, making Nix particularly valuable. |
| `ghcid` config or equivalent | Fast feedback loop | +3 | Search tree for `.ghcid`, `ghcid` in `Makefile` or `Justfile` targets. |

**Maximum possible Haskell R4 bonus: 25 points, capped at +15.**

#### Rust R4 Bonuses

| Signal | What to Check | Bonus | How to Verify |
|--------|---------------|-------|---------------|
| `rustfmt.toml` or `.rustfmt.toml` | Formatter configured | +3 | Search tree for these files. |
| `clippy.toml` | Lint customization | +3 | Search tree for `clippy.toml`. |
| `rust-toolchain.toml` | Toolchain version pinned | +5 | Search tree for `rust-toolchain.toml` or `rust-toolchain`. |
| `cargo-make` or `just` | Task runner | +3 | Search tree for `Makefile.toml` (cargo-make) or `Justfile`. |
| `deny.toml` (cargo-deny) | Dependency license and advisory checking | +5 | Search tree for `deny.toml`. Check CI for `cargo deny check`. |

**Maximum possible Rust R4 bonus: 19 points, capped at +15.**

#### TypeScript R4 Bonuses

| Signal | What to Check | Bonus | How to Verify |
|--------|---------------|-------|---------------|
| Prettier config | `.prettierrc*` or `prettier.config.*` | +3 | Search tree for Prettier configuration files. |
| ESLint config | `eslint.config.*` or `.eslintrc.*` | +3 | Search tree for ESLint configuration files. |
| `engines` field in `package.json` | Node version pinned | +2 | Parse `package.json` for `engines.node`. |
| `volta` or `fnm` or `.nvmrc` | Node version management | +3 | Search tree for `.nvmrc`, `.node-version`, `volta` key in `package.json`. |
| `turbo.json` or `nx.json` task caching | Build caching in monorepo | +3 | Search tree for these files. Only applicable if monorepo structure detected. |

**Maximum possible TypeScript R4 bonus: 14 points, capped at +15 (14 in practice).**

---

## 8. Language Detection and Bonus Application

### 8.1 Determining the Primary Language

The agent uses the GitHub API language statistics endpoint (`GET /repos/{owner}/{repo}/languages`) to determine the language breakdown by bytes of code.

**Rules:**

1. **Single-language repo (>80% one language):** Apply that language's bonus set fully.
2. **Multi-language repo (two or more languages each >15%):** Apply language bonuses proportionally by LOC percentage. For example, if a repo is 60% Rust and 35% TypeScript, apply 60% of the Rust bonus and 35% of the TypeScript bonus for each pillar.
3. **No recognized bonus set:** If the primary language does not have a defined bonus set, score using universal signals only. The repo is not penalized — it simply does not get bonus points.

### 8.2 Proportional Bonus Calculation (Multi-Language)

```
effective_bonus = Σ(language_bonus_i * language_percentage_i)
capped_bonus = min(15, effective_bonus)
```

**Example:** A repo that is 60% Rust, 35% TypeScript, 5% Shell:
- Rust R1 bonuses earned: 12 points
- TypeScript R1 bonuses earned: 8 points
- Effective R1 bonus = (12 * 0.60) + (8 * 0.35) = 7.2 + 2.8 = 10.0
- Capped at 15, so R1 bonus = 10.0

### 8.3 Languages with Defined Bonus Sets

The following languages have language-specific bonus signals defined for all four pillars:

| Language | Bonus Sets Available | Notes |
|----------|---------------------|-------|
| **Haskell** | R1, R2, R3, R4 | Strong type system and module system make many bonuses highly impactful |
| **Rust** | R1, R2, R3, R4 | Ownership system and crate structure provide natural structural signals |
| **TypeScript** | R1, R2, R3, R4 | Strict mode and schema libraries are the critical signals |

All other languages (Python, Go, Java, C#, C/C++, Kotlin, Scala, etc.) are scored using universal signals only. As the model evolves, additional language bonus sets may be defined.

### 8.4 Bonus Cap Rationale

The +15 cap per pillar ensures that language-specific practices enhance but do not dominate the score. A repo that excels on universal signals but has no language-specific bonus still reaches 100 on raw scoring. A repo that has every language-specific bonus but poor universal signals cannot score higher than ~65-70 even with the full +15 bonus. Universal signals are the foundation; language bonuses reward ecosystem excellence.

---

## 9. Cross-Pillar Constraints

After computing R1, R2, R3, and R4 individually, apply these constraints before computing the final Readiness composite. These constraints enforce structural integrity — certain combinations of scores are contradictory or dangerous.

### Constraint 1: No Tests, Capped Readiness

**Rule:** If R3 < 20, the final Readiness composite is capped at 50.

**Rationale:** Without tests, an AI agent cannot verify its own work. High structural clarity and semantic density are valuable but insufficient — the AI is guessing, and there is no way to catch mistakes. Capping at 50 ensures the repo cannot reach the "Excellent" or "Good" readiness tiers without verification capability.

**Implementation:**
```
if R3 < 20:
    Readiness = min(50, R1 * 0.30 + R2 * 0.30 + R3 * 0.25 + R4 * 0.15)
```

### Constraint 2: No Types in Typed Language

**Rule:** If the primary language is statically typed (Haskell, Rust, TypeScript with strict mode available, Java, C#, Go, Kotlin, Scala) and type coverage score < 30%, then R2 is capped at 50 before entering the Readiness formula.

**Rationale:** If a language offers a type system and the codebase ignores it, the codebase is actively discarding the most powerful semantic signal available. This is a stronger negative signal than simply being a dynamically typed language.

**Implementation:**
```
if language_is_statically_typed and type_coverage_score < 30:
    R2 = min(50, R2)
```

Note: This applies specifically to languages where types are available but unused (e.g., TypeScript with `strict: false` and pervasive `any`, or a Haskell project with missing type signatures). It does not apply to inherently dynamically typed languages (Python without type hints, JavaScript without JSDoc).

### Constraint 3: AI Tooling Without Readiness (Cross-Axis)

**Rule:** If Readiness < 30 and Adoption composite > 50, flag the repository as "Risky Acceleration."

**Rationale:** This repo is deploying AI tools on a codebase that lacks the structural foundation for AI to be effective. The AI is likely producing low-quality output that is difficult to verify. This is an informational flag, not a score adjustment — it appears in the scan report as a warning.

**Implementation:**
```
if readiness_composite < 30 and adoption_composite > 50:
    add_flag("Risky Acceleration")
    add_recommendation("Invest in codebase readiness (structure, types, tests) before expanding AI adoption")
```

### Application Order

1. Compute R1, R2, R3, R4 individually (with language bonuses and per-pillar caps).
2. Apply Constraint 2 (type coverage cap on R2) if applicable.
3. Compute Readiness composite.
4. Apply Constraint 1 (R3 < 20 caps Readiness at 50).
5. Apply Constraint 3 (flag check, requires both Readiness and Adoption composites).

---

## 10. Worked Example: cardano-ledger (Haskell)

This section walks through the complete Readiness scoring process for [cardano-ledger](https://github.com/IntersectMBO/cardano-ledger), a large Haskell monorepo. The target result is a Readiness score of approximately 90, matching the model spec's characterization of cardano-ledger as a "Stage 0 repo with Readiness 90."

### 10.1 Data Collection

The agent fetches:

1. **Repository tree** via `GET /repos/IntersectMBO/cardano-ledger/git/trees/master?recursive=1` — returns ~3000+ files across multiple packages.
2. **Language stats** via `GET /repos/IntersectMBO/cardano-ledger/languages` — returns Haskell as dominant language (>90%).
3. **Key files to fetch content:**
   - `cabal.project` (multi-package configuration)
   - Several `.cabal` files from sub-packages (`cardano-ledger-core`, `cardano-ledger-shelley`, etc.)
   - `README.md`
   - `flake.nix` (Nix build infrastructure)
   - `.github/workflows/*.yml` (CI configuration)
   - Sample of 15-20 `.hs` source files across packages
   - `.gitignore`
   - `CONTRIBUTING.md` if present

### 10.2 R1: Structural Clarity

#### Universal Signals

**File Organization (weight: 0.15)**
- The tree shows 3+ levels of meaningful nesting: `eras/shelley/impl/src/Cardano/Ledger/Shelley/`, `libs/cardano-ledger-core/src/Cardano/Ledger/Core/`
- Consistent hierarchy across all sub-packages: each has `src/`, `test/`, and a `.cabal` file
- **Score: 100**

**File Granularity (weight: 0.20)**
- Sampling 15 Haskell source files shows median around 180-220 lines
- Haskell files tend to be focused due to the module system
- A few files exceed 500 lines (complex era transition logic), but median is in the 150-300 range
- No per-file penalty (no files >1000 lines in sample)
- **Score: 75**

**Module Boundaries (weight: 0.20)**
- `cabal.project` defines multiple packages: `cardano-ledger-core`, `cardano-ledger-shelley`, `cardano-ledger-alonzo`, etc.
- Each package has explicit module exports in its `.cabal` file
- Both explicit exports AND multi-package structure present
- **Score: 100**

**Separation of Concerns (weight: 0.20)**
- Clear era-based separation: each era is its own package
- Within packages: `src/` for library code, `test/` for tests
- Core abstractions separated from era-specific implementations
- Domain logic (ledger rules) separated from serialization and API layers
- **Score: 100**

**Circular Dependency Risk (weight: 0.10)**
- Multi-package structure naturally prevents most cycles (packages have explicit dependency declarations)
- Sampling the 10 largest files: imports are mostly downward (era packages depend on core, not vice versa)
- Minor internal import cycles possible within packages but not across
- **Score: 75**

**Entry Point Clarity (weight: 0.05)**
- This is a library project — no `main` entry point expected
- Clear public API modules defined in each `.cabal` file's `exposed-modules`
- Easy to identify what each package exports
- **Score: 75**

**Configuration Isolation (weight: 0.10)**
- Nix flake for build configuration
- Cabal config files in predictable locations
- No hardcoded configuration values in source (formal verification domain)
- **Score: 100**

**R1_raw calculation:**
```
R1_raw = (100 * 0.15) + (75 * 0.20) + (100 * 0.20) + (100 * 0.20) +
         (75 * 0.10) + (75 * 0.05) + (100 * 0.10)
       = 15.0 + 15.0 + 20.0 + 20.0 + 7.5 + 3.75 + 10.0
       = 91.25
```

#### Haskell R1 Bonuses

| Signal | Evidence | Bonus |
|--------|----------|-------|
| Module hierarchy | `src/Cardano/Ledger/Core/` = 4 levels deep | +5 |
| Explicit exports | Sampling 20 modules: >80% have explicit export lists | +8 |
| Cabal/Stack structure | `.cabal` files have `library` + `test-suite` stanzas; executables vary by package | +5 |
| Internal modules | `Internal` module pattern used in multiple packages | +3 |
| Package boundaries | `cabal.project` lists 10+ packages | +5 |
| Typeclass discipline | Typeclasses in dedicated modules, minimal orphan instances | +3 |

**R1_language_bonus = 29, capped at 15**

**R1 = min(100, 91.25 + 15) = 100**

Agent judgment adjustment: While the formula yields 100, the agent notes that file granularity is not at the highest tier and some packages have dense modules. The agent records R1 = 95, documenting the 5-point reduction as: "file granularity median is above 150 lines, and a few modules are over-complex for their scope."

**Final R1: 95**

### 10.3 R2: Semantic Density

**Type Coverage (0.25):** Haskell is statically typed with full inference. Most top-level bindings have explicit type signatures. Score: 100.

**Schema Definitions (0.15):** CDDL specifications for ledger serialization formats. Formal specifications translated to Haskell types. Score: 100.

**Documentation Ratio (0.20):** Haddock coverage varies by package. Core packages well-documented. Era implementation packages have sparser documentation. Sampling suggests 40-60% coverage. Score: 65.

**README Substance (0.10):** README covers description, setup (Nix build), and architecture overview. Usage and contributing sections present but brief. 4 of 5 sections present. Score: 80.

**ADRs/Design Docs (0.10):** Formal specifications serve as design documents. `docs/` directory present in some packages. Score: 75.

**Naming Quality (0.10):** Haskell naming is descriptive: `applyTransaction`, `LedgerState`, `TxBody`. Average identifier length 10-18 characters. Score: 100.

**API Documentation (0.05):** Haddock-generated docs. No HTTP API (it is a library). Score: 75.

**CHANGELOG (0.05):** `CHANGELOG.md` present in packages, structured format. Score: 75.

**R2_raw calculation:**
```
R2_raw = (100 * 0.25) + (100 * 0.15) + (65 * 0.20) + (80 * 0.10) +
         (75 * 0.10) + (100 * 0.10) + (75 * 0.05) + (75 * 0.05)
       = 25.0 + 15.0 + 13.0 + 8.0 + 7.5 + 10.0 + 3.75 + 3.75
       = 86.0
```

**Haskell R2 bonuses earned:**
- `-Wall -Werror`: `-Wall` present in most packages, `-Werror` in CI = +8
- Haddock coverage: 40-60% range = +4 (partial)
- Type signatures on top-level bindings: >90% = +10
- Newtypes for domain concepts: extensively used = +5
- `DerivingStrategies`: present in default extensions = +3
- Refined types / smart constructors: used in core types = +5

**R2_language_bonus = 35, capped at 15**

**R2 = min(100, 86.0 + 15) = 100, adjusted to 92**

Agent judgment: documentation ratio is moderate, not all packages are equally well-documented. R2 = 92.

**Final R2: 92**

### 10.4 R3: Verification Infrastructure

**Test Existence (gate):** Test suites present in all packages. Gate passes.

**Test/Source Ratio (0.25):** Extensive test directories across packages. Ratio approximately 0.5-0.6. Score: 75.

**Test Categorization (0.15):** Unit tests, property-based tests (QuickCheck/Hedgehog), golden tests present. 3 categories. Score: 100.

**Test Framework Config (0.10):** Tasty configured as test framework. Custom test runner configuration. Score: 100.

**Coverage Configuration (0.10):** HPC coverage available but not consistently enforced. Score: 30.

**CI Test Execution (0.20):** GitHub Actions run `cabal test` on every PR. Tests block merge. Score: 100.

**Test Fixtures/Factories (0.10):** Golden test data organized in test directories. Test generators for QuickCheck. Score: 60.

**Build Reproducibility (0.10):** Nix flake provides fully deterministic builds. `cabal.project.freeze` for dependency pinning. Score: 100.

**R3_raw calculation:**
```
R3_raw = (75 * 0.25) + (100 * 0.15) + (100 * 0.10) + (30 * 0.10) +
         (100 * 0.20) + (60 * 0.10) + (100 * 0.10)
       = 18.75 + 15.0 + 10.0 + 3.0 + 20.0 + 6.0 + 10.0
       = 82.75
```

**Haskell R3 bonuses earned:**
- `test-suite` stanza: present in all packages = +5
- HSpec/Tasty: Tasty framework = +5
- QuickCheck/Hedgehog: property-based testing = +8
- `hpc` or coverage: partially configured = +1 (partial)
- `cabal test` in CI: yes = +3
- Doctest: not widely used = +0
- Golden tests: `tasty-golden` present = +3

**R3_language_bonus = 25, capped at 15**

**R3 = min(100, 82.75 + 15) = 97.75, adjusted to 88**

Agent judgment: coverage configuration is weak. R3 = 88.

**Final R3: 88**

### 10.5 R4: Developer Ergonomics

**Linter (0.15):** HLint configured. Score: 100.

**Formatter (0.10):** Fourmolu or similar in CI. Score: 100.

**Pre-commit Hooks (0.10):** Not clearly present from tree. Score: 0.

**Editor Config (0.05):** `hie.yaml` for HLS. No `.editorconfig`. Score: 40.

**CI/CD Pipeline (0.20):** Comprehensive GitHub Actions workflows. Build + test + multiple CI jobs. Score: 100.

**Reproducible Environment (0.15):** Nix flake with devShell. Gold standard. Score: 100.

**Task Runner (0.10):** Makefile or Nix commands for common tasks. Score: 70.

**Env Template (0.05):** N/A for a library. Score: 30 (no need, but no documentation of that fact).

**Dependency Lockfile (0.05):** `cabal.project.freeze` and `flake.lock`. Score: 100.

**Git Hygiene (0.05):** Comprehensive `.gitignore`. Score: 100.

**R4_raw calculation:**
```
R4_raw = (100 * 0.15) + (100 * 0.10) + (0 * 0.10) + (40 * 0.05) +
         (100 * 0.20) + (100 * 0.15) + (70 * 0.10) + (30 * 0.05) +
         (100 * 0.05) + (100 * 0.05)
       = 15.0 + 10.0 + 0.0 + 2.0 + 20.0 + 15.0 + 7.0 + 1.5 + 5.0 + 5.0
       = 80.5
```

**Haskell R4 bonuses earned:**
- Fourmolu: yes = +3
- HLint: yes = +5
- `cabal.project`: yes = +3
- `hie.yaml`: yes = +3
- Nix flake for Haskell: yes = +8
- `ghcid` config: not clearly present = +0

**R4_language_bonus = 22, capped at 15**

**R4 = min(100, 80.5 + 15) = 95.5, adjusted to 85**

Agent judgment: missing pre-commit hooks and limited editor configuration bring it down. R4 = 85.

**Final R4: 85**

### 10.6 Cross-Pillar Constraints

1. **No tests cap (R3 < 20)?** R3 = 88. Not triggered.
2. **No types in typed language (type coverage < 30%)?** Type coverage = 100. Not triggered.
3. **Risky Acceleration (Readiness < 30, Adoption > 50)?** Readiness will be well above 30. Not triggered. (Adoption is ~0 for cardano-ledger, but the constraint would not apply regardless.)

No constraints apply.

### 10.7 Final Readiness Composite

```
Readiness = R1 * 0.30 + R2 * 0.30 + R3 * 0.25 + R4 * 0.15
          = 95 * 0.30 + 92 * 0.30 + 88 * 0.25 + 85 * 0.15
          = 28.5 + 27.6 + 22.0 + 12.75
          = 90.85
          ≈ 91
```

**Final Readiness: 91** — consistent with the model spec's characterization of cardano-ledger as having Readiness ~90.

### 10.8 Evidence Summary (as the agent would record it)

```
Repository: IntersectMBO/cardano-ledger
Language: Haskell (>90%)
Readiness: 91

R1 Structural Clarity: 95
  Evidence: multi-package cabal.project (10+ packages), 4-level module hierarchy,
  explicit exports in >80% of modules, clear era-based separation of concerns.
  Deduction: file granularity median ~200 lines (above 150 threshold).

R2 Semantic Density: 92
  Evidence: fully typed (Haskell), CDDL specifications, explicit type signatures
  on >90% of top-level bindings, extensive newtype usage.
  Deduction: Haddock coverage 40-60% (not all packages equally documented).

R3 Verification Infrastructure: 88
  Evidence: property-based testing (QuickCheck/Hedgehog), golden tests,
  CI runs tests on all PRs, Nix flake for reproducible builds.
  Deduction: coverage configuration not enforced, no doctest.

R4 Developer Ergonomics: 85
  Evidence: Nix flake devShell, fourmolu formatting, HLint, comprehensive CI.
  Deduction: no pre-commit hooks, limited editor configuration.

Cross-pillar constraints: none triggered.
Flags: none.
```

---

## 11. Readiness Score Interpretation

The Readiness composite score maps to descriptive labels that communicate the codebase's AI-collaboration potential.

| Score Range | Label | Meaning |
|-------------|-------|---------|
| 80-100 | **Excellent** | Codebase fully supports AI collaboration. Well-structured, well-typed, well-tested, with smooth developer ergonomics. An AI agent can navigate, understand, modify, and verify changes with high confidence. Ideal candidate for AI adoption investment. |
| 60-79 | **Good** | Strong foundation with some areas for improvement. AI agents can work productively but may struggle in specific areas (e.g., sparse documentation, limited test coverage, or inconsistent structure). Targeted improvements will yield significant AI collaboration gains. |
| 45-59 | **Moderate** | Adequate but significant gaps. AI agents can perform basic tasks but effectiveness is limited by structural, semantic, or verification gaps. Investment in readiness improvements before heavy AI adoption is recommended. |
| 30-44 | **Developing** | Major structural work needed before AI collaboration can be productive. The codebase has foundational issues (poor modularity, missing types, few tests) that limit AI effectiveness. Readiness improvements should precede or accompany any AI adoption. |
| 0-29 | **Early** | Fundamental codebase improvements required. AI tools deployed here are working blind — no structure to navigate, no types to understand intent, no tests to verify output. Any AI adoption at this level carries high risk (see: Risky Acceleration flag). |

### Quadrant Placement

The Readiness score determines the vertical axis of the quadrant model (see model-spec.md Section 2.2):

- **Readiness >= 45:** Upper half (Fertile Ground or AI-Native, depending on Adoption)
- **Readiness < 45:** Lower half (Traditional or Risky Acceleration, depending on Adoption)

### Actionable Interpretation

When presenting Readiness scores to teams, emphasize:

1. **Which pillar is the weakest?** That is where improvement effort should focus. A repo with R1=90, R2=85, R3=30, R4=80 should invest in testing, not documentation.
2. **Are any cross-pillar constraints active?** These indicate structural contradictions that should be resolved first.
3. **Is the repo in "Risky Acceleration"?** If so, readiness work must precede further AI adoption.
4. **What is the gap to the next tier?** A repo at Readiness 57 (Moderate) needs targeted work to reach 60 (Good). Show which signals would have the highest impact.

---

## Appendix A: Signal Weight Summary

### R1: Structural Clarity

| Signal | Weight |
|--------|--------|
| File organization | 0.15 |
| File granularity | 0.20 |
| Module boundaries | 0.20 |
| Separation of concerns | 0.20 |
| Circular dependency risk | 0.10 |
| Entry point clarity | 0.05 |
| Configuration isolation | 0.10 |
| **Total** | **1.00** |

### R2: Semantic Density

| Signal | Weight |
|--------|--------|
| Type coverage | 0.25 |
| Schema definitions | 0.15 |
| Documentation ratio | 0.20 |
| README substance | 0.10 |
| ADRs / design docs | 0.10 |
| Naming quality | 0.10 |
| API documentation | 0.05 |
| CHANGELOG | 0.05 |
| **Total** | **1.00** |

### R3: Verification Infrastructure

| Signal | Weight |
|--------|--------|
| Test existence | Gate (not weighted) |
| Test/source ratio | 0.25 |
| Test categorization | 0.15 |
| Test framework config | 0.10 |
| Coverage configuration | 0.10 |
| CI test execution | 0.20 |
| Test fixtures / factories | 0.10 |
| Build reproducibility | 0.10 |
| **Total** | **1.00** |

### R4: Developer Ergonomics

| Signal | Weight |
|--------|--------|
| Linter configured | 0.15 |
| Formatter configured | 0.10 |
| Pre-commit hooks | 0.10 |
| Editor config | 0.05 |
| CI/CD pipeline | 0.20 |
| Reproducible environment | 0.15 |
| Task runner | 0.10 |
| Env template | 0.05 |
| Dependency lockfile | 0.05 |
| Git hygiene | 0.05 |
| **Total** | **1.00** |

---

## Appendix B: Agent Judgment Guidelines

This scoring methodology combines formula-based computation with bounded agent judgment. The following guidelines ensure reproducibility.

### When Agent Judgment Applies

1. **Signal scoring within tiers.** The metric-to-score tables define tiers (e.g., 0, 25, 50, 75, 100). The agent may interpolate within tiers when evidence is borderline. For example, a repo with median file size of exactly 150 lines could score 75 or 100 — the agent decides based on overall distribution shape.

2. **Final pillar adjustment.** After computing the formula-based score, the agent may adjust by up to +/-5 points based on holistic assessment. This adjustment must be documented with specific reasoning (as shown in the worked example).

3. **Language bonus partial credit.** Some language bonuses are binary (present/absent). Others allow partial credit (e.g., "Haddock coverage >70% = +8, 40-70% = +4"). The agent assigns partial credit based on the evidence.

### When Agent Judgment Does NOT Apply

1. **Weights.** Signal weights are fixed. The agent cannot reassign weights.
2. **Caps.** The +15 language bonus cap and the 100-point pillar cap are absolute.
3. **Hard gates.** The R3 test existence gate and the cross-pillar constraints are non-negotiable.
4. **Formula.** The Readiness composite formula (R1 * 0.30 + R2 * 0.30 + R3 * 0.25 + R4 * 0.15) is fixed.

### Reproducibility Standard

Two agents scoring the same repository should produce Readiness scores within 5 points of each other. If they diverge by more than 5 points, the evidence recording is insufficient — the scoring should be reviewed.

---

## Appendix C: Quick Reference — Minimum Data for Each Pillar

For agents optimizing API calls, this table shows the minimum data needed per pillar.

| Pillar | Minimum Data Required |
|--------|----------------------|
| R1 | Repository tree (recursive), sample of 10-15 source file contents, build manifests (`.cabal`, `Cargo.toml`, `package.json`) |
| R2 | Sample of 15-20 source file contents, `README.md`, `tsconfig.json`/build config for type settings, `CHANGELOG.md`, tree search for `docs/`/`adr/` directories |
| R3 | Repository tree (for test file counting), CI workflow files, build manifests (test stanzas), sample of test files for categorization |
| R4 | Repository tree (for config file detection), `.gitignore`, CI workflow files, `package.json` (scripts section) |
| All | GitHub API language stats, repository tree (one call covers all pillars) |
