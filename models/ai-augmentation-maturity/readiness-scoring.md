# AAMM: Readiness Scoring Methodology

> Operational specification for computing Readiness scores. Every signal has a metric-to-score mapping. Every formula is explicit. This file + code in scripts is the source of truth for scoring.
> **Depends on:** `README.md` (model context)
> **Read by:** agents (before scoring), CoE (when updating scoring rules)
> **Implemented in:** `scripts/aamm/score-readiness.sh`, `scripts/aamm/review-scores.sh`
> **Sync rule:** Changes here MUST be reflected in the implementing scripts and vice versa.

**Owner:** CoE · Dorin Solomon · **Last updated:** March 2026

---

## 1. Purpose

This document defines **how** to compute Readiness scores (Navigate, Understand, Verify) operationally. It is the companion to [README.md](README.md), which defines **what** each pillar means.

An AI agent reading this document together with `README.md` should have everything it needs to score the Readiness axis for any repository without further human guidance. Every signal has a concrete metric-to-score mapping. Every formula is explicit.

**No discretionary adjustments.** The formula output is the score.

**No language bonuses.** Universal signals are language-aware where needed (e.g., Type Safety scores differently for statically-typed vs dynamically-typed languages). There is no separate bonus system.

---

## 2. Readiness Composite Formula

```
Readiness_raw = Navigate * 0.35 + Understand * 0.35 + Verify * 0.30

# Cross-pillar constraints
if Verify < 20:
    Readiness_raw = min(50, Readiness_raw)
if type_coverage_score < 50:
    Readiness_raw = min(70, Readiness_raw)

# Penalties
Readiness = max(0, Readiness_raw - sum(applicable_penalties))
```

### Penalties

| Penalty | Condition | Impact |
|---|---|---|
| PRs without review | >30% of 10 most recent merged PRs have 0 reviews | -10 |
| No vulnerability monitoring | See graduated scale below | -10 or -5 |
| No branch protection | No required reviews on default branch | -5 |

**Vulnerability monitoring — graduated scale:**

| Situation | Impact | How to detect |
|---|---|---|
| No scanning AND no strategy | **-10** | No `dependabot.yml`/`renovate.json`, no lockfile pinning strategy, no security scanning in CI |
| Partial scanning (wrong ecosystem) | **-5** | `dependabot.yml` exists but doesn't list primary language ecosystem (e.g., covers `github-actions` but not `npm` for a TypeScript repo) |
| Ecosystem lacks tooling, team manages deps | **0** (risk flag only) | No automated CVE scanning available for primary language, but team uses active dependency management: `index-state` pinning (Haskell), curated package sets, lockfile + manual audit cycle. Applies to: Haskell/Cabal (no Dependabot support), Nix (flake.lock), and other ecosystems where Dependabot/Renovate don't operate. No penalty — teams cannot adopt tooling that doesn't exist. Flagged as risk for visibility. |
| Scanning active for primary ecosystem | **0** | `dependabot.yml` with entry matching primary language, OR `renovate.json`, OR security scanning tool in CI (CodeQL, Trivy, Snyk, cargo-deny, npm audit, etc.) |

**Principle:** Penalties are for things teams CAN fix but haven't. If no mature scanning tool exists for the ecosystem, the team is not negligent — the gap is flagged as a risk, not penalized. The graduated scale distinguishes between: negligence (tooling exists, not configured → -10 or -5), and ecosystem gaps (no tooling exists → 0 + risk flag).

---

## 3. Data Collection

### One tree call first

Fetch the recursive tree (`GET /repos/{owner}/{repo}/git/trees/{branch}?recursive=1`), then selectively fetch content for specific files.

### Deterministic sampling strategy

When sampling source files for content reads:
1. Select the 10 largest source files by byte size from the tree (excluding generated/vendored)
2. Select the 5 most recently modified source files (by commit date)
3. Remove duplicates → sample of 10-15 files

Same tree = same sample = same score.

### Exclusions

Ignore these paths in all tree analysis: `node_modules/`, `dist/`, `build/`, `.git/`, `.yarn/`, `.stack-work/`, `target/`, `vendor/`, `generated/`, `gen/`, `autogen/`.

### API budget: ≤ 35 calls for Readiness

| Call | Count | Purpose |
|---|---|---|
| Recursive tree | 1 | All file paths and sizes |
| Languages | 1 | Language detection |
| Config files | 3-5 | tsconfig, package.json, .cabal, Cargo.toml, etc. |
| CI workflow files | 2-4 | CI/CD, test execution |
| README.md | 1 | README substance |
| .gitignore | 1 | Repo foundations |
| Linter/formatter configs | 1-2 | Code consistency |
| Source file samples | 10-15 | Doc coverage, type analysis |
| Recent merged PRs | 1 | Penalty: PR review check |
| Branch protection | 1 | Penalty: branch protection check |
| **Total** | **~25-35** | |

---

## 4. Navigate (Weight: 0.35)

**Poate AI-ul lucra eficient aici?**

### N1: File Organization (weight: 0.12)

**Metric:** Depth and consistency of directory tree.

| Condition | Score |
|-----------|-------|
| 3+ levels of meaningful nesting with clear, consistent hierarchy | 100 |
| 3+ levels but some inconsistency (mixed conventions, orphan directories) | 75 |
| 2 levels of nesting with reasonable grouping | 50 |
| Flat structure with some directories (src/ and test/ but nothing deeper) | 25 |
| All files in root or single directory | 0 |

**How to measure:** From the recursive tree, compute max and median depth of source files (after exclusions). Count distinct directory prefixes at each level. A directory level is "meaningful" if it contains 2+ items.

---

### N2: File Granularity (weight: 0.13)

**Metric:** Median source file size in estimated lines.

| Condition | Score |
|-----------|-------|
| Median < 150 lines | 100 |
| Median 150-300 | 75 |
| Median 300-500 | 50 |
| Median 500-1000 | 25 |
| Median > 1000 | 0 |

**Per-file penalty:** Each source file > 1000 lines reduces score by 2, capped at -10.

**Bytes-to-lines estimation:** Use the sampled files (Section 3) to compute an actual bytes-per-line ratio for the repo. Apply that ratio to the full tree. If sampling is not possible, use defaults: Haskell 50 bytes/line, Rust 55, TypeScript 35, Python 35, Go 40, Java 50.

**Exclusions:** Ignore generated files, test fixtures, data files, lockfiles, vendored code.

---

### N3: Module Boundaries (weight: 0.15)

**Metric:** Explicit module/package definitions.

| Condition | Score |
|-----------|-------|
| Multi-package structure with explicit exports (monorepo with distinct packages, each with manifest) | 100 |
| Multi-package structure OR explicit exports (one but not both) | 75 |
| Some module organization (directories as logical modules, no explicit export control) | 50 |
| Minimal structure (source files grouped loosely, no manifest-level boundaries) | 25 |
| No module boundaries (single flat namespace) | 0 |

**How to measure:** Check for multi-package indicators: `cabal.project` with multiple packages, `Cargo.toml` with `[workspace]`, `pnpm-workspace.yaml`, Yarn workspaces in `package.json`, `nx.json`, `turbo.json`. Check for barrel files (`index.ts`), explicit Haskell module exports, Rust `pub` API in `lib.rs`.

---

### N4: Separation of Concerns (weight: 0.12)

**Metric:** Distinct directories mapping to distinct responsibilities.

| Condition | Score |
|-----------|-------|
| 3+ distinct layers identifiable (e.g., domain/application/infrastructure, core/api/persistence) | 100 |
| 2 distinct layers | 75 |
| Some separation but mixed concerns | 50 |
| Minimal separation (src/ exists but everything mixed) | 25 |
| Everything mixed together | 0 |

**How to measure:** Inspect directory names at the first two levels under `src/` (or equivalent). Accept unconventional names that clearly map to distinct responsibilities — the signal is architectural separation, not naming convention compliance.

---

### N5: Code Consistency (weight: 0.13)

**Metric:** Linter and/or formatter configured.

| Condition | Score |
|-----------|-------|
| Both linter and formatter configured with custom rules + enforced in CI | 100 |
| Both configured with custom rules | 80 |
| One of linter/formatter configured with custom rules | 60 |
| Linter or formatter present with default config | 40 |
| Mentioned in docs but not configured | 15 |
| Neither present | 0 |

**How to measure:** Search tree for linter config files (e.g., `.eslintrc.*`, `eslint.config.*`, `biome.json`, `.hlint.yaml`, `clippy.toml`, `.pylintrc`, `ruff.toml`, `.stan.toml`, or equivalent) and formatter config files (e.g., `.prettierrc*`, `biome.json`, `.rustfmt.toml`, `fourmolu.yaml`, or equivalent). **Also check `flake.nix`** for tool definitions — Nix projects often declare linters/formatters as derivations rather than standalone config files (e.g., `hlint = "3.8"` in a Nix devShell). Tool choice is free.

**CI enforcement — per-tool:** Check CI workflows for lint/format steps. Score "enforced in CI" (100) only when **both** linter and formatter are CI-enforced. If only one is CI-enforced, score as "both configured" (80). Check for specific tool names in workflows, not generic keywords like `lint` or `format` which match too broadly. **npm/NX monorepo patterns:** `npm run lint`, `npm run check:lint`, `npx nx affected --target=lint` count as linter CI enforcement when the underlying tool (ESLint, Biome) is configured. Similarly, `npm run check:format` counts as formatter CI enforcement. These are npm script wrappers for the actual tool. **Nix-based CI:** `nix flake check` counts as CI enforcement for both tools if the flake includes both checks. `nix develop` alone does not — it provides tools but doesn't enforce their use.

**"Custom rules" means:** For **linters**: config file with project-specific rules beyond defaults (disabled checks, custom patterns, severity overrides). For **formatters**: any config file with project-specific settings (indentation, line length, comma style, etc.) — a formatter config file IS custom rules because its presence means the team chose specific formatting standards. An empty or absent config file = defaults.

---

### N6: CI/CD Pipeline (weight: 0.15)

**Metric:** Build and deploy workflows present and active.

| Condition | Score |
|-----------|-------|
| CI/CD with build + deploy stages, recently executed (last 30 days) | 100 |
| CI with build stage, recently executed | 75 |
| CI workflow exists and runs but minimal (single step) | 50 |
| Workflow files exist but appear stale or non-functional | 20 |
| No CI/CD pipeline | 0 |

**How to measure:** Count workflow files in `.github/workflows/`. Parse YAML for build and deploy steps. **Exclude test execution steps** — those are scored in Verify (V3).

**Note:** This signal scores the pipeline as build/deploy infrastructure only.

---

### N7: Reproducible Environment (weight: 0.12)

**Metric:** Mechanism for reproducing the development environment + dependency lockfile.

| Condition | Score |
|-----------|-------|
| Nix flake with devShell + lockfile committed | 100 |
| Docker/devcontainer + lockfile committed | 80 |
| Lockfile committed + setup script or detailed README instructions | 60 |
| Lockfile committed only | 40 |
| Lockfile in .gitignore or no lockfile | 10 |
| No reproducibility mechanism at all | 0 |

**How to measure:** Search tree for `flake.nix`, `shell.nix`, `Dockerfile`, `docker-compose.yml`, `.devcontainer/devcontainer.json`, lockfiles (`yarn.lock`, `package-lock.json`, `Cargo.lock`, `flake.lock`, `cabal.project.freeze`).

**Note for libraries:** Libraries that deliberately exclude lockfiles per ecosystem convention (e.g., Rust libraries) score based on whether version constraints are defined in the manifest. If constraints are present and lockfile is deliberately excluded, score as if lockfile is committed.

---

### N8: Repo Foundations (weight: 0.08)

**Metric:** Presence of foundational repository files.

| File | Points |
|------|--------|
| `CODEOWNERS` | 40 |
| Comprehensive `.gitignore` (covers build artifacts, IDE files, OS files, secrets) | 35 |
| `SECURITY.md` (vulnerability disclosure path) | 25 |

Score = sum of points for files present. Max 100.

**How to measure:** Check tree for file existence. For `.gitignore`, fetch content and count categories covered: build output, IDE files, OS files, secrets/env, dependencies. 4+ categories = comprehensive (35 points). 2-3 categories = basic (20 points). 0-1 = minimal (10 points).

---

### Navigate Formula

```
Navigate = sum(signal_score_i * signal_weight_i)
# Weights: N1=0.12, N2=0.13, N3=0.15, N4=0.12, N5=0.13, N6=0.15, N7=0.12, N8=0.08
# Sum = 1.00
```

---

## 5. Understand (Weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

### U1: Type Safety (weight: 0.30)

**Metric:** Type annotations and enforcement.

| Condition | Score |
|-----------|-------|
| Statically typed with full inference (Haskell, Rust, OCaml) | 100 |
| TypeScript with `strict: true` | 100 |
| TypeScript with `strictNullChecks` + `noImplicitAny` (most critical strict flags) | 85 |
| TypeScript with partial strict flags (only one of the above) | 65 |
| Typed language but `strict: false` or minimal config | 40 |
| Dynamically typed with type hints >50% (Python type hints, JSDoc) | 50 |
| Dynamically typed with sparse type hints | 25 |
| Dynamically typed, no type hints | 0 |

**How to measure:** Check primary language. For TypeScript: parse `tsconfig.json` for `strict`, `strictNullChecks`, `noImplicitAny` flags. For monorepos using NX or Turborepo, also check `tsconfig.base.json` at the root when `tsconfig.json` is absent. For Haskell/Rust: start at 100. For Python: estimate type hint coverage from sampled files (presence of `: type` annotations on function parameters).

**Mixed-language caveat:** If >15% of source files are in a weakly-typed or untyped language (C, Assembly, JavaScript) — e.g., via FFI bindings — cap U1 at 85. The type-safe primary language cannot protect the untyped boundary code. This applies regardless of primary language.

---

### U2: Documentation Coverage (weight: 0.25)

**Metric:** Doc comments per public function/type, estimated from sample.

| Condition | Score |
|-----------|-------|
| >70% of sampled public functions/types have doc comments | 100 |
| 50-70% | 75 |
| 30-50% | 50 |
| 10-30% | 25 |
| <10% | 0 |

**How to measure:** The collection step samples 5 representative source files (excluding tests, generated code, files under 500 bytes). Scorer counts documented public items vs total public items per language: Rust (`///` doc comments vs `pub fn/struct/enum/trait`), TypeScript (`/**` blocks vs `export` declarations), Haskell (`-- |` Haddock vs top-level type signatures), Python (docstrings vs `def`/`class`). Sampled files are saved as `sampled_u2_*` in the data directory. Override is still supported but no longer required for standard languages.

**Partial failures:** If some files fail to fetch, compute ratio from successful files only. Note failure count in evidence.

---

### U3: README Substance (weight: 0.15)

**Metric:** README structural quality scored by section presence.

| Section | What qualifies | Points |
|---------|---------------|--------|
| Description | Purpose explained in 2+ sentences | 20 |
| Setup / Installation | Steps to build and run | 20 |
| Usage | How to use (examples, commands) | 20 |
| Architecture | System design, component relationships | 20 |
| Contributing | How to contribute, PR process | 20 |

Score = sum of points for sections present. Max 100.

**How to measure:** Fetch README.md. Search for section headings at **any heading level** (`#` through `######`) matching keywords. Many repos use `#` (H1) for top-level sections, not `##` (H2). Match keywords: Setup/Install/Build/Building/Testing (setup), Usage/Examples/How-to (usage), Architecture/Design/Structure/Overview (arch), Contributing/Development (contrib). Score a section as present only if it has substantive content beyond a heading. Heading detection allows up to 20 characters before the keyword to accommodate emoji or icon prefixes (e.g., `## :rocket: Getting started`).

---

### U4: Architecture Documentation (weight: 0.15)

**Metric:** Presence, count, and recency of architectural documentation.

| Condition | Score |
|-----------|-------|
| 5+ ADRs/design docs + ARCHITECTURE.md, at least one recent (6 months) | 100 |
| 3-4 ADRs/design docs or ARCHITECTURE.md with substantive content | 75 |
| 1-2 ADRs or ARCHITECTURE.md present | 50 |
| Some docs exist but scattered/informal | 25 |
| No architectural documentation | 0 |

**How to measure:** Search tree for `ARCHITECTURE.md`, `docs/decisions/`, `docs/adr/`, `adr/`, `decisions/`, `rfcs/`. Count files.

---

### U5: Schema Definitions (weight: 0.15)

**Metric:** Explicit data shape definitions at system boundaries.

| Condition | Score |
|-----------|-------|
| Schema definitions at all major boundaries (API + data) | 100 |
| Schema definitions at most boundaries | 75 |
| Some schema definitions (e.g., Zod in a few places) | 50 |
| Minimal schemas (only framework-required, e.g., DB migrations) | 25 |
| No explicit schema definitions | 0 |

**How to measure:** Search tree for schema files: `.proto`, `.graphql`, `.cddl`, `openapi.yaml`, `swagger.json`. Search manifest dependencies for **schema/validation** libraries: `zod`, `io-ts`, `valibot`, `yup`, `joi` (TypeScript), `pydantic` (Python), `servant` + `servant-openapi3` (Haskell API schemas), `proto-lens` (Haskell protobuf). Count and assess coverage.

**Contract-first architecture:** TypeScript monorepos using `packages/contract/` or `contracts/` directories with typed interface boundaries represent a de facto schema pattern. When no literal schema files exist but 5+ contract packages define typed boundaries, score as "some schema definitions" (50). This is a conservative heuristic — override recommended for deeper assessment.

**Note:** Serialization libraries (`aeson`, `serde`, `JSON.parse`) are NOT schema libraries. They encode/decode data but don't validate structure at boundaries. Only count libraries that enforce data shape contracts (validation, type-checked API definitions, or formal schema languages).

---

### Understand Formula

```
Understand = sum(signal_score_i * signal_weight_i)
# Weights: U1=0.30, U2=0.25, U3=0.15, U4=0.15, U5=0.15
# Sum = 1.00
```

---

## 6. Verify (Weight: 0.30)

**Poate AI-ul verifica ce produce?**

### Hard Gate

If zero tests exist → Verify capped at 15. The agent determines "zero tests" as: no files matching test patterns (`test/`, `tests/`, `__tests__/`, `*_test.*`, `*.test.*`, `*.spec.*`) AND no test stanza in build manifests AND no `scripts.test` in `package.json` pointing to a real command (not `echo "Error: no test specified"`).

---

### V1: Test/Source Ratio (weight: 0.30)

**Metric:** Test files ÷ source files.

| Condition | Score |
|-----------|-------|
| Ratio > 0.7 | 100 |
| Ratio 0.4-0.7 | 75 |
| Ratio 0.2-0.4 | 50 |
| Ratio 0.1-0.2 | 25 |
| Ratio < 0.1 | 0 |

**How to measure:** Count files matching test patterns. Count source files (language-specific extensions, excluding generated). Compute ratio.

**Language notes:**
- **Rust:** Conventional pattern is inline `#[cfg(test)]` modules inside source files — these are invisible to a file-count ratio. A Rust repo with ratio 0.1–0.2 may have substantial inline test coverage. Manual override is recommended when sampled source files contain `#[cfg(test)]` blocks.
- **TypeScript/JavaScript monorepos:** E2E test infrastructure directories (e.g., `*-e2e/src/` containing page objects, assertions, step definitions) are test support code, not source. If such directories appear in the source count, reclassify them as test files and override V1 accordingly.

---

### V2: Test Categorization (weight: 0.20)

**Metric:** Distinct test categories present.

| Condition | Score |
|-----------|-------|
| 3+ distinct categories clearly organized | 100 |
| 2 categories (e.g., unit + e2e) | 75 |
| 1 category but well-organized | 50 |
| Tests exist but no categorization | 25 |

**How to measure:** Look for directory structure, framework detection, dedicated CI jobs, and filename patterns.

**Unit test detection heuristics:**
- **Path keywords:** `unit/`, `__tests__/`, `Unit` in test file paths
- **Filename patterns:** `.test.ts`, `.test.tsx`, `.spec.ts`, `.spec.js` files — count as unit tests ONLY when NOT in E2E/integration directories (e.g., exclude files matching `e2e/`, `integration/`, `playwright/`, `cypress/`, `storybook/`)
- **Rust inline tests:** `#[cfg(test)]` modules in sampled source files indicate unit tests (invisible to file-count ratio)
- **CI workflow frameworks:** Jest, Vitest, cargo test/nextest, pytest, HUnit/Tasty in workflow files suggest unit test execution

**E2E/visual regression detection from CI workflows:** Playwright, Cypress, WebdriverIO, BrowserStack patterns in workflow YAML indicate E2E testing. Chromatic, Percy, BackstopJS patterns indicate visual regression testing.

**Recognized test categories** (a category is distinct if it tests a fundamentally different property):

| Category | What it tests | Examples |
|----------|--------------|---------|
| Unit | Individual function correctness | Jest, Vitest, HUnit, Tasty, pytest, JUnit |
| Integration | Component interaction, API contracts | Storybook + Playwright, database tests, Imp framework |
| E2E | Full user flow across system boundary | Playwright, Cypress, WebdriverIO, Selenium, BrowserStack |
| Property-based | Invariants hold across random inputs | QuickCheck, Hedgehog, fast-check, proptest |
| Golden/snapshot | Output stability against known-good reference | Jest snapshots, golden file comparison |
| Conformance | Implementation matches external spec | Formal spec compliance tests (e.g., vs Agda spec) |
| Visual regression | UI renders consistently | Chromatic, Percy, BackstopJS |

BDD frameworks (Cucumber, hspec) count as integration or unit depending on scope — they are a style, not a distinct category. A repo needs evidence of **distinct test strategies**, not just multiple framework names.

**High-assurance domain profile — V2 sub-signals** (supplementary, reported alongside V2 score):

| Sub-signal | How to detect | What it indicates |
|-----------|--------------|-------------------|
| Generator discipline | `cover`/`classify`/`tabulate`/`checkCoverage`/`forAllShrink`/`forAllBlind`/`withMaxSuccess`/`forAllShow` in test files | Generators produce diverse, verified input distributions |
| Custom generators | Explicit `Arbitrary` instances with `shrink` definitions | Generators are hand-crafted for domain correctness, not generic |
| Conformance oracle | Test references to Agda/formal spec, `conformance/` directories | Tests verify against external specification, not just internal consistency |
| Adversarial testing | Generator names containing `Adversarial`, `Malicious`, `Invalid`, `Corrupt` | Tests actively probe failure modes, not just happy paths |

These sub-signals distinguish between "property tests exist" (V2 category count) and "property tests are effective" (generator quality). Both are detectable from GitHub API via file content sampling.

---

### V3: CI Test Execution (weight: 0.30)

**Metric:** Tests run in CI and block merge.

| Condition | Score |
|-----------|-------|
| Tests on every PR + push to main, blocking merge on failure | 100 |
| Tests on PR only, blocking merge | 80 |
| Tests in CI but not blocking (informational) | 50 |
| CI exists but does not run tests | 20 |
| No CI at all | 0 |

**How to measure:** Parse `.github/workflows/*.yml` for test execution steps. Check for required status checks. Detect PR-trigger by checking for `pull_request` in workflow `on:` block. Detect main-push trigger by additionally checking for `push:` with `branches: main` or `branches: master` in the same workflow. Score 100 only when both triggers are present in a workflow that also runs tests. This is the ONLY signal that scores test-in-CI — Navigate's CI/CD signal (N6) excludes test execution.

---

### V4: Coverage Configuration (weight: 0.20)

**Metric:** Coverage tool configured.

| Condition | Score |
|-----------|-------|
| Coverage configured with thresholds enforced in CI | 100 |
| Coverage tool configured and runs (no enforcement) | 60 |
| Coverage tool in dependencies but not configured | 30 |
| No coverage tooling | 0 |

**How to measure:** Check for coverage config (e.g., `c8`, `istanbul`/`nyc`, `vitest --coverage`, `cargo-tarpaulin`, `hpc`, `pytest-cov`, SonarCloud, Codecov, or equivalent). Check CI for coverage steps and threshold assertions. Any coverage tool counts.

**Detection precision:** Match specific coverage tool names, not generic words. The word `coverage` alone is too common in CI files (appears in unrelated contexts like "code coverage" comments, variable names, etc.). The pattern `--min` matches non-coverage flags like `--minimize-conflict-set`. Threshold detection must require coverage context: `coverage.*threshold`, `--check-coverage`, `--cov-fail-under`, `fail-under` — not standalone `--min` or `threshold`.

**Haskell note:** `hpc` (Haskell Program Coverage) ships with GHC but is difficult to configure for multi-package `cabal.project` setups (no native cross-suite merging, limited CI integration). Score 30 ("in dependencies but not configured") if `hpc` or `cabal test --enable-coverage` appears in docs or scripts but doesn't run in CI. Score 0 only if coverage is completely absent from docs, scripts, and CI. This reflects that hpc availability ≠ hpc usability for large projects.

---

### Verify Formula

```
Verify_raw = sum(signal_score_i * signal_weight_i)
# Weights: V1=0.30, V2=0.20, V3=0.30, V4=0.20
# Sum = 1.00

if no_tests_exist:
    Verify = min(15, Verify_raw)
else:
    Verify = Verify_raw
```

---

## 7. Language Detection

The agent uses the GitHub API language statistics endpoint (`GET /repos/{owner}/{repo}/languages`).

**Infrastructure languages** (Nix, Shell, Makefile, Dockerfile, CMake) should be excluded from the language percentage calculation before applying these rules. They are build tooling, not application code. Only application/library languages count.

**Rules:**
1. **Single-language repo (>60% one language after excluding infrastructure):** Score all signals using that language's conventions (e.g., Type Safety starts at 100 for Haskell, checks `strict: true` for TypeScript).
2. **Multi-language repo (two or more application languages each >15%):** Score using the primary language's conventions. Note secondary languages in evidence.
3. **No recognized language conventions:** Score using generic thresholds. The repo is not penalized.

**Example:** A repo with 75% Haskell, 12% Nix, 8% Shell, 5% C → exclude Nix + Shell → 75% Haskell, 5% C → single-language (Haskell). A repo with 50% TypeScript, 30% Haskell, 20% Nix → exclude Nix → 50% TS, 30% Haskell → multi-language, primary = TypeScript.

---

## 8. Worked Examples

### 8.1 LACE (TypeScript monorepo) — Readiness: 68.6

*(Scored during model validation. Full report generated via `scripts/aamm/scan-repo.sh`.)*

**Navigate: 97.0** — Excellent monorepo structure (Yarn workspaces, 8 packages), Nix flake devShell, ESLint+Prettier with custom rules enforced in CI, comprehensive CI/CD (9 workflows). Only gap: no SECURITY.md (N8: 75).

**Understand: 57.5** — TypeScript with `strictNullChecks`+`noImplicitAny` (U1: 85). JSDoc ~30-50% of exports (U2: 50). README with 4/5 sections (U3: 80). ARCHITECTURE.md but no ADRs (U4: 50). No runtime schemas at boundaries (U5: 0).

**Verify: 65.0** — Test ratio 0.371 (V1: 50). Three test categories: unit (Jest/Vitest), E2E (WebdriverIO), integration/BDD (Cucumber) (V2: 100). CI runs tests on every PR (V3: 80). SonarCloud configured but no coverage thresholds (V4: 30).

**Penalty: -5** — Dependabot covers `github-actions` only, not npm (partial scanning — wrong ecosystem). Crypto wallet with 1,100+ transitive npm deps unmonitored.

*[TODO: Score cardano-ledger (Haskell) to validate language-awareness — Type Safety should start at 100]*
