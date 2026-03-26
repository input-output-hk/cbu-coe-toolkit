# AAMM — Sample Report: input-output-hk/mithril

**Model version:** 1.0 · **Scan date:** 2026-03-26 · **Scanned by:** CoE (Dorin Solomon)

---

## Risks

| Severity | Risk | Detail |
|----------|------|--------|
| 🟡 Medium | NO BRANCH PROTECTION | See evidence log |

---

## Summary

| Axis | Score | Detail |
|------|-------|--------|
| **AI Readiness** | **71.63 / 100** | Navigate: 94.3, Understand: 92.5, Verify: 37.5. Penalties: -5. |
| **AI Adoption** | **21.45 / 100** | Code: Configured, Testing: Configured, Security: None, Delivery: Configured, Governance: None |
| **Quadrant** | **Fertile Ground** | High readiness, low adoption. |

```
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │ ★ FERTILE   │  AI-NATIVE  │
              │   GROUND    │             │
AI Readiness  │ (mithril)  │              │
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
| Benchmark regression | ✓ | files=24, dirs=7, CI regression=0 |
| Strict evaluation discipline | ✗ | StrictData/BangPatterns=0 |
| .aiignore on critical paths | ✗ | 0 |

### Domain Risk Flags

| Severity | Risk | Detail |
|----------|------|--------|
| 🟡 Medium | No concurrency testing framework | Network/distributed code but no io-sim/dejafu detected |
| 🟡 Medium | Benchmarks without CI regression detection | Benchmarks exist but no CI-based regression alerting detected |

---

## AI Readiness: 71.63 / 100

### Pillar 1: Navigate — 94.3 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **100** | 0.12 | max_depth=9, directories=509 |
| N2 | file_granularity | **90** | 0.13 | median_lines=65, large_files=8, per_file_penalty=-10 |
| N3 | module_boundaries | **100** | 0.15 | workspace_files=35, package_manifests=34 |
| N4 | separation_of_concerns | **100** | 0.12 | top_level_dirs=17 (heuristic — override recommended) |
| N5 | code_consistency | **100** | 0.13 | linter=1 (Clippy, enforced in CI — step fails on warnings), formatter=1 (cargo fmt --check, enforced in CI), ci_enforced=1 (CORRECTED: script missed cargo clippy/fmt detection), configs=2 |
| N6 | cicd_pipeline | **100** | 0.15 | workflows=20, has_build=1, has_deploy=1, days_since_push=0 |
| N7 | reproducible_env | **100** | 0.12 | flake=1, flake_lock=1, docker=0, lockfile=7 |
| N8 | repo_foundations | **45** | 0.08 | codeowners=0, gitignore_cats=3(20), security_md=1 |

---

### Pillar 2: Understand — 92.5 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **100** | 0.3 | Rust → automatic 100 (statically typed with full inference) |
| U2 | doc_coverage | **100** | 0.25 | Agent sampled 5 .rs files: 41/45 pub items documented (91%) → score 100 |
| U3 | readme_substance | **100** | 0.15 | readme_lines=146, desc=1, setup=1, usage=1, arch=1, contrib=1 (CORRECTED: emoji-prefixed headings missed by regex — e.g. :rocket: Getting started) |
| U4 | architecture_docs | **100** | 0.15 | adrs=11, architecture_md=2 |
| U5 | schema_definitions | **50** | 0.15 | schema_files=1 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 37.5 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (141 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **25** | 0.3 | ratio=.160 (141 test / 880 source) |
| V2 | test_categorization | **75** | 0.2 | detected_categories=2 [integration/e2e,golden] (heuristic — override recommended) |
| V3 | ci_test_execution | **50** | 0.3 | ci_test=1, ci_blocking=0 |
| V4 | coverage_config | **0** | 0.2 | coverage_tool=0, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 94.3 × 0.35 + 92.5 × 0.35 + 37.5 × 0.30
              = 76.63

Constraints: none applied

Penalties: -5
Readiness = 71.63
```

### Penalties

| Penalty | Applied? | Impact | Evidence |
|---------|----------|--------|----------|
| prs without review | NO | 0 | N/A |
| no vulnerability monitoring | NO | 0 | N/A |
| no branch protection | **YES** | -5 | N/A |

---

## AI Adoption: 21.45 / 100

### Detection Layer Results

| Layer | Method | Result |
|-------|--------|--------|
| **L1_tree** | L1 | 1 found — .github/copilot-instructions.md |
| **L2_commits** | L2 | None —  |
| **L3_pr_author** | L3 | N/A —  |
| **L4_pr_body** | L4 | None —  |
| **L5_submodules** | L5 | None —  |

### Per-Dimension Scoring

| Dimension | Stage | Score | Condition A | Condition B | Annotation |
|-----------|-------|-------|-------------|-------------|------------|
| **Code** | Configured | 33 | ✓ linter=1, codeowners=0 | ✓ AI config .github/copilot-instructions.md: 8/8 categories, includes Architecture + Conventions | Configured but no active AI signals in last 30 PRs/50 commits |
| **Testing** | Configured | 33 | ✓ test execution found in CI workflows | ✓ AI config .github/copilot-instructions.md: 8/8 categories, includes Testing | Configured but no active AI signals in last 30 PRs/50 commits |
| **Security** | None | 0 | ✗ no security scanning detected | ✓ AI config .github/copilot-instructions.md: 8/8 categories, includes Security | AI config present, practice not active |
| **Delivery** | Configured | 33 | ✓ build_workflow=true, issues=true (open=128) | ✓ AI config .github/copilot-instructions.md: 8/8 categories, includes Delivery | Configured but no active AI signals in last 30 PRs/50 commits |
| **Governance** | None | 0 | ✓ 1 AI config files in tree, 0 in submodules | ✗ usage expectations found but no .aiignore | Practice active, no AI config |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `input-output-hk/mithril` |
| Description | Stake-based threshold multi-signatures protocol |
| Default branch | `main` |
| Private | false |
| Primary language | Rust (94.1%) |
| Languages | Rust: 94.1%,JavaScript: 2.7%,Shell: 1.7%,HCL: 1%,Makefile: 0.3% |
| Size | 190439 KB |
| Open issues | 129 |
| Stars | 149 |
| License | Apache-2.0 |
| Created | 2021-09-07T05:33:14Z |
| Last push | 2026-03-26T08:55:40Z |
| Tree entries | 2425 |
| Source files | 880 |
| Test files | 141 |
| Directories | 509 |
| Max depth | 9 |

### Score Summary

```
Navigate   = 94.3  (weight 0.35)
Understand = 92.5  (weight 0.35)
Verify     = 37.5  (weight 0.30)

Readiness_raw = 76.63
Penalties: -5
Readiness = 71.63

Adoption composite = 21.45
  Code: Configured (33), Testing: Configured (33), Security: None (0), Delivery: Configured (33), Governance: None (0)

Quadrant: Fertile Ground
```

---

## Principal Engineer Review

**Corrections applied:** 0 · **Notes raised:** 2

### Review Notes

| Signal | Severity | Note | Action |
|--------|----------|------|--------|
| U2 | info | Default score (25) — Agent should sample .rs files for /// doc comments. | override_recommended |
| domain_io_sim | warning | Network/consensus repo without io-sim detected. Verify manually — io-sim may be a transitive dependency not visible in tree. | verify_manually |

**⚠ 1 signal(s) use default scores and need agent override.** Scores marked `override_recommended` above are heuristic defaults — the scanning agent should sample actual file content and apply evidence-based overrides for accurate results. Until overridden, the affected pillar scores may be understated.

---

## Recommendations

### Strengthen Verification (Verify: 37.5/100)

- **Test/source ratio (V1=25):** Ratio is .160 — add unit tests for modules with zero test coverage. Focus on the most-changed files first for maximum AI verification value.
- **Coverage config (V4=0):** Add coverage tool + threshold to CI.

