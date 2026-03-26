# AAMM — Sample Report: input-output-hk/ouroboros-leios

**Model version:** 1.0 · **Scan date:** 2026-03-25 · **Scanned by:** CoE (Dorin Solomon)

---

## Risks

| Severity | Risk | Detail |
|----------|------|--------|
| 🟡 Medium | NO BRANCH PROTECTION | See evidence log |
| 🔴 High | AI without governance | Active/Integrated AI usage but Governance = None |

---

## Summary

| Axis | Score | Detail |
|------|-------|--------|
| **AI Readiness** | **52.65 / 100** | Navigate: 94.30, Understand: 31.00, Verify: 46.00. Penalties: -5. |
| **AI Adoption** | **42.90 / 100** | Code: Active, Testing: Active, Security: None, Delivery: Active, Governance: None |
| **Quadrant** | **Fertile Ground** | High readiness, low adoption. |

```
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │ ★ FERTILE   │  AI-NATIVE  │
              │   GROUND    │             │
AI Readiness  │ (ouroboros-leios)  │              │
    ↑         │             │              │
              ├─────────────┼─────────────┤
              │             │  RISKY      │
         Low  │ TRADITIONAL │ ACCELERATION │
              └─────────────┴─────────────┘
```

---

## Domain Profile: Blockchain

**Detected via:** repo topics, description, .agda files (5), formal-spec dirs

**AI Value Framing:** AI as adversarial reviewer/challenger/auditor on critical code; quality driver on docs/tests/PRs; code generator only on boilerplate/serialization

### Supplementary Signals

| Signal | Status | Detail |
|--------|--------|--------|
| Formal spec presence | ✓ | 5 .agda files, 1 formal-spec dirs, 0 .cddl files |
| Conformance testing | ✓ | 3 conformance dirs, oracle=0 |
| Generator discipline | ✗ | cover/classify=0, custom Arbitrary=0, adversarial=0 |
| Concurrency testing (io-sim) | ✓ | io-sim=1 |
| Benchmark regression | ✓ | files=67, dirs=13, CI regression=1 |
| Strict evaluation discipline | ✗ | StrictData/BangPatterns=0 |
| .aiignore on critical paths | ✗ | 0 |

---

## AI Readiness: 52.65 / 100

### Pillar 1: Navigate — 94.30 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **100** | 0.12 | max_depth=7, directories=2056 |
| N2 | file_granularity | **90** | 0.13 | median_lines=14, large_files=8, per_file_penalty=-10 |
| N3 | module_boundaries | **100** | 0.15 | workspace_files=8, package_manifests=12 |
| N4 | separation_of_concerns | **100** | 0.12 | top_level_dirs=22 (heuristic — override recommended) |
| N5 | code_consistency | **100** | 0.13 | linter=1, formatter=1, ci_enforced=1, configs=5 |
| N6 | cicd_pipeline | **100** | 0.15 | workflows=12, has_build=1, has_deploy=1, days_since_push=0 |
| N7 | reproducible_env | **100** | 0.12 | flake=1, flake_lock=1, docker=1, lockfile=9 |
| N8 | repo_foundations | **45** | 0.08 | codeowners=0, gitignore_cats=3(20), security_md=1 |

---

### Pillar 2: Understand — 31.00 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **40** | 0.30 | Jupyter Notebook — requires manual type safety assessment |
| U2 | doc_coverage | **25** | 0.25 | Not sampled — requires agent file content analysis. Override recommended. |
| U3 | readme_substance | **60** | 0.15 | readme_lines=251, desc=1, setup=1, usage=1, arch=0, contrib=0 |
| U4 | architecture_docs | **25** | 0.15 | adrs=0, architecture_md=0 |
| U5 | schema_definitions | **0** | 0.15 | schema_files=0 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 46.00 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (16 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **0** | 0.30 | ratio=.025 (16 test / 620 source) |
| V2 | test_categorization | **50** | 0.20 | detected_categories=1 [golden] (heuristic — override recommended) |
| V3 | ci_test_execution | **80** | 0.30 | ci_test=1, ci_blocking=1 |
| V4 | coverage_config | **60** | 0.20 | coverage_tool=1, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 94.30 × 0.35 + 31.00 × 0.35 + 46.00 × 0.30
              = 57.65

Constraints: none applied

Penalties: -5
Readiness = 52.65
```

### Penalties

| Penalty | Applied? | Impact | Evidence |
|---------|----------|--------|----------|
| prs without review | NO | -0 | N/A |
| no vulnerability monitoring | NO | -0 | N/A |
| no branch protection | **YES** | -5 | N/A |

---

## AI Adoption: 42.90 / 100

### Detection Layer Results

| Layer | Method | Result |
|-------|--------|--------|
| **L1_tree** | L1 | 2 found — sim-rs/CLAUDE.md,ui/CLAUDE.md |
| **L2_commits** | L2 | 1 found —  |
| **L3_pr_author** | L3 | N/A —  |
| **L4_pr_body** | L4 | 2 found —  |
| **L5_submodules** | L5 | None —  |

### Per-Dimension Scoring

| Dimension | Stage | Score | Condition A | Condition B | Annotation |
|-----------|-------|-------|-------------|-------------|------------|
| **Code** | Active | 66 | ✓ linter=1, codeowners=0 | ✓ AI config sim-rs/CLAUDE.md: 7/8 categories, includes Architecture + Conventions | Active AI usage detected |
| **Testing** | Active | 66 | ✓ test execution found in CI workflows | ✓ AI config sim-rs/CLAUDE.md: 7/8 categories, includes Testing | Active AI usage detected |
| **Security** | None | 0 | ✗ no security scanning detected | ✗ no AI config with Security category | Emerging AI usage |
| **Delivery** | Active | 66 | ✓ build_workflow=true, issues=true (open=60) | ✓ AI config sim-rs/CLAUDE.md: 7/8 categories, includes Delivery | Active AI usage detected |
| **Governance** | None | 0 | ✓ 2 AI config files in tree, 0 in submodules | ✗ usage expectations found but no .aiignore | Practice active, no AI config |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `input-output-hk/ouroboros-leios` |
| Description | Documentation and tools relating to the design and prototyping of Ouroboros Leios |
| Default branch | `main` |
| Private | false |
| Primary language | Jupyter Notebook (96.9%) |
| Languages | Jupyter Notebook: 96.9%,Shell: 0.8%,Haskell: 0.8%,Rust: 0.6%,TypeScript: 0.3% |
| Size | 769676 KB |
| Open issues | 60 |
| Stars | 41 |
| License | Unknown |
| Created | 2022-11-17T11:47:35Z |
| Last push | 2026-03-25T13:06:25Z |
| Tree entries | 12122 |
| Source files | 620 |
| Test files | 16 |
| Directories | 2056 |
| Max depth | 7 |

### Score Summary

```
Navigate   = 94.30  (weight 0.35)
Understand = 31.00  (weight 0.35)
Verify     = 46.00  (weight 0.30)

Readiness_raw = 57.65
Penalties: -5
Readiness = 52.65

Adoption composite = 42.90
  Code: Active (66), Testing: Active (66), Security: None (0), Delivery: Active (66), Governance: None (0)

Quadrant: Fertile Ground
```

---

## Principal Engineer Review

**Corrections applied:** 0 · **Notes raised:** 2

### Review Notes

| Signal | Severity | Note | Action |
|--------|----------|------|--------|
| U2 | info | Default score (25) — requires agent file content analysis. | override_recommended |
| nav_und_gap | warning | Navigate (94.30) >> Understand (31.00). Well-structured codebase but AI can't understand intent. Typically means docs/comments gap. High-impact improvement area. | operator_attention |

**⚠ 1 signal(s) use default scores and need agent override.** Scores marked `override_recommended` above are heuristic defaults — the scanning agent should sample actual file content and apply evidence-based overrides for accurate results. Until overridden, the affected pillar scores may be understated.

---

## Recommendations


### Blockchain-Specific AI Value

Frame AI as **adversarial reviewer**, not code generator, on critical paths:

| AI Role | Where to Apply | Example |
|---------|---------------|---------|
| **Threat modeler** | Core logic, validation | "What if input is malformed? What if amounts overflow?" |
| **Completeness auditor** | Test coverage | "Spec defines N rules, tests cover M — identify gaps" |
| **Security reviewer** | Auth, crypto, key mgmt | "Review all security-critical paths for common vulnerabilities" |
| **Performance challenger** | Hot paths | "Identify O(n²) patterns, unnecessary allocations, missing caching" |
| **API/interface reviewer** | Module boundaries | "Review error types, input validation, contract consistency" |
| **Documentation driver** | API docs, README, ADRs | "Generate docs for all exported public interfaces" |

**Add `.aiignore`** excluding consensus/crypto paths — signals mature AI governance and prevents AI from generating code in critical modules.

### Improve AI Understanding (Understand: 31.00/100)

- **Documentation coverage (U2=25):** Add doc comments to exported functions and types. This is the single highest-impact improvement for AI comprehension.
- **Architecture docs (U4=25):** Add `ARCHITECTURE.md` or ADRs. Even a single file explaining module relationships and key design decisions significantly improves AI's ability to make contextually correct suggestions.

### Strengthen Verification (Verify: 46.00/100)

- **Test/source ratio (V1=0):** Ratio is .025 — add unit tests for modules with zero test coverage. Focus on the most-changed files first for maximum AI verification value.
- **Test categorization (V2=50):** Expand test types beyond what's currently detected. Add unit tests (if only integration/e2e exist) or property-based tests (e.g., fast-check for TypeScript, QuickCheck for Haskell) for richer AI verification.
- **Coverage threshold (V4=60):** Coverage tool detected but no enforcement threshold. Add a minimum coverage gate to CI to prevent regression.

