# AAMM — Sample Report: input-output-hk/lace

**Model version:** 1.0 · **Scan date:** 2026-03-25 · **Scanned by:** CoE (Dorin Solomon)

---

## Risks

| Severity | Risk | Detail |
|----------|------|--------|
| 🟡 Medium | NO BRANCH PROTECTION | See evidence log |
| 🟡 Medium | Active without foundation | AI activity signals found but Configured gate not met (no substantive AI config) |

---

## Summary

| Axis | Score | Detail |
|------|-------|--------|
| **AI Readiness** | **51.11 / 100** | Navigate: 90.01, Understand: 34.75, Verify: 41.50. Penalties: -5. |
| **AI Adoption** | **0 / 100** | Code: None, Testing: None, Security: None, Delivery: None, Governance: None |
| **Quadrant** | **Fertile Ground** | High readiness, low adoption. |

```
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │ ★ FERTILE   │  AI-NATIVE  │
              │   GROUND    │             │
AI Readiness  │ (lace)  │              │
    ↑         │             │              │
              ├─────────────┼─────────────┤
              │             │  RISKY      │
         Low  │ TRADITIONAL │ ACCELERATION │
              └─────────────┴─────────────┘
```

---

## Domain Profile: Blockchain

**Detected via:** repo topics

**AI Value Framing:** AI as adversarial reviewer/challenger/auditor on critical code; quality driver on docs/tests/PRs; code generator only on boilerplate/serialization

### Supplementary Signals

| Signal | Status | Detail |
|--------|--------|--------|
| Formal spec presence | ✗ | Not detected |
| Conformance testing | ✗ | Not detected |
| Generator discipline | ✗ | cover/classify=0, custom Arbitrary=0, adversarial=0 |
| Concurrency testing (io-sim) | ✗ | io-sim=0 |
| Benchmark regression | ✗ | files=0, dirs=0, CI regression=0 |
| Strict evaluation discipline | ✗ | StrictData/BangPatterns=0 |
| .aiignore on critical paths | ✗ | 0 |

### Domain Risk Flags

| Severity | Risk | Detail |
|----------|------|--------|
| 🟡 Medium | No benchmark regression detection | Performance-sensitive blockchain code without benchmarks |

---

## AI Readiness: 51.11 / 100

### Pillar 1: Navigate — 90.01 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **100** | 0.12 | max_depth=14, directories=759 |
| N2 | file_granularity | **92** | 0.13 | median_lines=33, large_files=4, per_file_penalty=-8 |
| N3 | module_boundaries | **75** | 0.15 | workspace_files=0, package_manifests=9 |
| N4 | separation_of_concerns | **100** | 0.12 | top_level_dirs=6 (heuristic — override recommended) |
| N5 | code_consistency | **100** | 0.13 | linter=1, formatter=1, ci_enforced=1, configs=16 |
| N6 | cicd_pipeline | **100** | 0.15 | workflows=9, has_build=1, has_deploy=1, days_since_push=0 |
| N7 | reproducible_env | **100** | 0.12 | flake=1, flake_lock=1, docker=0, lockfile=3 |
| N8 | repo_foundations | **35** | 0.08 | codeowners=0, gitignore_cats=5(35), security_md=0 |

---

### Pillar 2: Understand — 34.75 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **40** | 0.30 | TypeScript, tsconfig exists but not fetched — override recommended |
| U2 | doc_coverage | **25** | 0.25 | Not sampled — requires agent file content analysis. Override recommended. |
| U3 | readme_substance | **60** | 0.15 | readme_lines=75, desc=1, setup=1, usage=0, arch=1, contrib=0 |
| U4 | architecture_docs | **50** | 0.15 | adrs=0, architecture_md=1 |
| U5 | schema_definitions | **0** | 0.15 | schema_files=0 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 41.50 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (232 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **25** | 0.30 | ratio=.107 (232 test / 2168 source) |
| V2 | test_categorization | **50** | 0.20 | detected_categories=1 [unit] (heuristic — override recommended) |
| V3 | ci_test_execution | **80** | 0.30 | ci_test=1, ci_blocking=1 |
| V4 | coverage_config | **0** | 0.20 | coverage_tool=0, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 90.01 × 0.35 + 34.75 × 0.35 + 41.50 × 0.30
              = 56.11

Constraints: none applied

Penalties: -5
Readiness = 51.11
```

### Penalties

| Penalty | Applied? | Impact | Evidence |
|---------|----------|--------|----------|
| prs without review | NO | -0 | N/A |
| no vulnerability monitoring | NO | -0 | N/A |
| no branch protection | **YES** | -5 | N/A |

---

## AI Adoption: 0 / 100

### Detection Layer Results

| Layer | Method | Result |
|-------|--------|--------|
| **L1_tree** | L1 | 1 found — .mcp.json |
| **L2_commits** | L2 | None —  |
| **L3_pr_author** | L3 | N/A —  |
| **L4_pr_body** | L4 | 3 found —  |
| **L5_submodules** | L5 | 26 found —  |

### Per-Dimension Scoring

| Dimension | Stage | Score | Condition A | Condition B | Annotation |
|-----------|-------|-------|-------------|-------------|------------|
| **Code** | None | 0 | ✓ linter=1, codeowners=0 | ✗ no AI config with Architecture + Conventions | Practice active, no AI config |
| **Testing** | None | 0 | ✓ test execution found in CI workflows | ✗ no AI config with Testing category | Practice active, no AI config |
| **Security** | None | 0 | ✗ dependabot exists but doesn't cover TypeScript | ✗ no AI config with Security category | Emerging AI usage |
| **Delivery** | None | 0 | ✓ build_workflow=true, issues=true (open=39) | ✗ no AI config with Delivery category | Practice active, no AI config |
| **Governance** | None | 0 | ✓ 1 AI config files in tree, 26 in submodules | ✗ no usage expectations or .aiignore | Practice active, no AI config |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `input-output-hk/lace` |
| Description | The Lace Wallet. |
| Default branch | `main` |
| Private | false |
| Primary language | TypeScript (85.9%) |
| Languages | TypeScript: 85.9%,Gherkin: 7.6%,SCSS: 5.1%,JavaScript: 1%,Makefile: 0.1% |
| Size | 95589 KB |
| Open issues | 39 |
| Stars | 44 |
| License | Apache-2.0 |
| Created | 2023-05-26T13:53:13Z |
| Last push | 2026-03-25T13:13:25Z |
| Tree entries | 4427 |
| Source files | 2168 |
| Test files | 232 |
| Directories | 759 |
| Max depth | 14 |

### Score Summary

```
Navigate   = 90.01  (weight 0.35)
Understand = 34.75  (weight 0.35)
Verify     = 41.50  (weight 0.30)

Readiness_raw = 56.11
Penalties: -5
Readiness = 51.11

Adoption composite = 0
  Code: None (0), Testing: None (0), Security: None (0), Delivery: None (0), Governance: None (0)

Quadrant: Fertile Ground
```

---

## Principal Engineer Review

**Corrections applied:** 0 · **Notes raised:** 2

### Review Notes

| Signal | Severity | Note | Action |
|--------|----------|------|--------|
| U2 | info | Default score (25) — Agent should sample .ts files for JSDoc/TSDoc comments. | override_recommended |
| nav_und_gap | warning | Navigate (90.01) >> Understand (34.75). Well-structured codebase but AI can't understand intent. Typically means docs/comments gap. High-impact improvement area. | operator_attention |

**⚠ 1 signal(s) use default scores and need agent override.** Scores marked `override_recommended` above are heuristic defaults — the scanning agent should sample actual file content and apply evidence-based overrides for accurate results. Until overridden, the affected pillar scores may be understated.

---

## Recommendations

### Start AI Adoption

**Zero AI adoption detected.** Quick wins to establish AI presence:

1. **Add `CLAUDE.md`** (or equivalent AI config) with:
   - Architecture: module boundaries, key abstractions, state management approach
   - Conventions: naming, formatting (prettier config), preferred patterns
   - Testing: framework (jest/vitest), coverage expectations, E2E setup
   - Security: auth flows, sensitive data handling, trust boundaries

2. **Enable AI-assisted PR review** — lowest risk, highest immediate value. AI reviews documentation, test coverage gaps, and style consistency.


### Blockchain-Specific AI Value

Frame AI as **adversarial reviewer**, not code generator, on critical paths:

| AI Role | Where to Apply | Example |
|---------|---------------|---------|
| **Threat modeler** | Wallet logic, tx construction | "What if BigInt amount overflows? What if CBOR deserialization gets malformed input?" |
| **Completeness auditor** | Integration tests | "API defines 8 endpoints, tests cover 5 — missing: /stake, /withdraw, /delegate" |
| **Security reviewer** | Key management, signing | "Private key buffer not zeroed after use. Mnemonic stored in plaintext localStorage." |
| **Performance challenger** | UI rendering, API calls | "This useEffect triggers on every render — debounce or memoize the balance fetch" |
| **API/interface reviewer** | Cross-module contracts | "Error type for submitTx is string — use discriminated union for recoverable vs fatal" |
| **Documentation driver** | TSDoc, README, ADRs | "Generate TSDoc for all exported types in the SDK package" |

**Add `.aiignore`** excluding consensus/crypto paths — signals mature AI governance and prevents AI from generating code in critical modules.

### Improve AI Understanding (Understand: 34.75/100)

- **Documentation coverage (U2=25):** Add TSDoc/JSDoc (`/** */`) to exported functions and types. This is the single highest-impact improvement for AI comprehension.

### Strengthen Verification (Verify: 41.50/100)

- **Test/source ratio (V1=25):** Ratio is .107 — add unit tests for modules with zero test coverage. Focus on the most-changed files first for maximum AI verification value.
- **Test categorization (V2=50):** Expand test types beyond what's currently detected. Add unit tests (if only integration/e2e exist) or property-based tests (e.g., fast-check for TypeScript, QuickCheck for Haskell) for richer AI verification.
- **Coverage config (V4=0):** Add coverage tool + threshold to CI.

