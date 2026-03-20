# AAMM: Readiness Scoring Methodology

**Owner:** CoE · Dorin Solomon · **Last updated:** March 2026

---

## 1. Purpose

This document defines **how** to compute Readiness scores (Navigate, Understand, Verify) operationally. It is the companion to [model-spec.md](model-spec.md), which defines **what** each pillar means.

An AI agent reading this document together with `model-spec.md` should have everything it needs to score the Readiness axis for any repository without further human guidance. Every signal has a concrete metric-to-score mapping. Every formula is explicit.

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
| Ecosystem lacks tooling, team manages deps | **-5** | No automated CVE scanning available for primary language, but team uses active dependency management: `index-state` pinning (Haskell), curated package sets, lockfile + manual audit cycle. Applies to: Haskell/Cabal (no Dependabot support), Nix (flake.lock), and other ecosystems where Dependabot/Renovate don't operate. |
| Scanning active for primary ecosystem | **0** | `dependabot.yml` with entry matching primary language, OR `renovate.json`, OR security scanning tool in CI (CodeQL, Trivy, Snyk, cargo-deny, npm audit, etc.) |

**Rationale:** The original -10 binary penalty treated "Haskell repo where Dependabot doesn't support Hackage" identically to "TypeScript repo with 1,100 npm deps and no scanning." The graduated scale distinguishes between ecosystems where the tooling doesn't exist (reduced penalty) and ecosystems where it does but the team hasn't configured it (full penalty).

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

**How to measure:** Search tree for linter config files (e.g., `.eslintrc.*`, `eslint.config.*`, `biome.json`, `.hlint.yaml`, `clippy.toml`, `.pylintrc`, `ruff.toml`, or equivalent) and formatter config files (e.g., `.prettierrc*`, `biome.json`, `.rustfmt.toml`, `fourmolu.yaml`, or equivalent). Tool choice is free. Check CI workflows for lint/format steps.

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

**How to measure:** Check primary language. For TypeScript: parse `tsconfig.json` for `strict`, `strictNullChecks`, `noImplicitAny` flags. For Haskell/Rust: start at 100. For Python: estimate type hint coverage from sampled files (presence of `: type` annotations on function parameters).

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

**How to measure:** Use the deterministic sample (Section 3). For each file, use regex to count:
- **TypeScript:** `export` declarations and `/** */` JSDoc blocks preceding them
- **Haskell:** exported functions (from module export list) and `-- |` / `-- ^` / `{- |` Haddock comments (line and block styles)
- **Rust:** `pub fn` / `pub struct` declarations and `///` doc comments
- **Python:** `def` / `class` declarations and triple-quoted docstrings

Compute ratio across all sampled files. This is a regex heuristic, not AST parsing.

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

**How to measure:** Fetch README.md. Search for section headings matching keywords. Score a section as present only if it has substantive content beyond a heading.

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

**How to measure:** Search `package.json` / `Cargo.toml` / `.cabal` dependencies for schema libraries: `zod`, `io-ts`, `valibot`, `serde`, `aeson`, `pydantic`. Search tree for schema files: `.proto`, `.graphql`, `openapi.yaml`, `swagger.json`. Count and assess coverage.

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

---

### V2: Test Categorization (weight: 0.20)

**Metric:** Distinct test categories present.

| Condition | Score |
|-----------|-------|
| 3+ distinct categories clearly organized | 100 |
| 2 categories (e.g., unit + e2e) | 75 |
| 1 category but well-organized | 50 |
| Tests exist but no categorization | 25 |

**How to measure:** Look for directory structure and framework detection. Categories: unit tests, integration tests, E2E tests (Playwright, Cypress, WebdriverIO, Puppeteer, Selenium, or equivalent), property-based tests (QuickCheck, Hedgehog, fast-check, proptest, or equivalent). Any framework counts — tool names are examples, not exhaustive.

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

**How to measure:** Parse `.github/workflows/*.yml` for test execution steps. Check for required status checks. This is the ONLY signal that scores test-in-CI — Navigate's CI/CD signal (N6) excludes test execution.

---

### V4: Coverage Configuration (weight: 0.20)

**Metric:** Coverage tool configured.

| Condition | Score |
|-----------|-------|
| Coverage configured with thresholds enforced in CI | 100 |
| Coverage tool configured and runs (no enforcement) | 60 |
| Coverage tool in dependencies but not configured | 30 |
| No coverage tooling | 0 |

**How to measure:** Check for coverage config (e.g., `c8`, `istanbul`/`nyc`, `vitest --coverage`, `cargo-tarpaulin`, `hpc`, `pytest-cov`, or equivalent). Check CI for coverage steps and threshold assertions. Any coverage tool counts.

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

**Rules:**
1. **Single-language repo (>80% one language):** Score all signals using that language's conventions for thresholds (e.g., Type Safety starts at 100 for Haskell, checks `strict: true` for TypeScript).
2. **Multi-language repo (two or more languages each >15%):** Score using the primary language's conventions. Note secondary languages in evidence.
3. **No recognized language conventions:** Score using generic thresholds. The repo is not penalized.

---

## 8. Worked Examples

### 8.1 LACE (TypeScript monorepo) — Readiness: 68.6

*(Scored during model validation. Full report generated via `scripts/aamm/scan-repo.sh`.)*

**Navigate: 97.0** — Excellent monorepo structure (Yarn workspaces, 8 packages), Nix flake devShell, ESLint+Prettier with custom rules enforced in CI, comprehensive CI/CD (9 workflows). Only gap: no SECURITY.md (N8: 75).

**Understand: 57.5** — TypeScript with `strictNullChecks`+`noImplicitAny` (U1: 85). JSDoc ~30-50% of exports (U2: 50). Good README + ARCHITECTURE.md but no ADRs (U4: 50). No runtime schemas at boundaries (U5: 0).

**Verify: 65.0** — Test ratio 0.371 (V1: 50). Three test categories: Jest/Vitest unit + WebdriverIO E2E + Cucumber BDD (V2: 100). CI runs tests on every PR (V3: 80). SonarCloud configured but no coverage thresholds (V4: 30).

**Penalty: -5** — Dependabot covers `github-actions` only, not npm (partial scanning — wrong ecosystem). Crypto wallet with 1,100+ transitive npm deps unmonitored.

*[TODO: Score cardano-ledger (Haskell) to validate language-awareness — Type Safety should start at 100]*
