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
| **AI Readiness** | **68.51 / 100** | Navigate: 94.30, Understand: 70.75, Verify: 52.50. Penalties: -5. |
| **AI Adoption** | **28.05 / 100** | Code: Configured, Testing: Configured, Security: Configured, Delivery: Configured, Governance: None |
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

## Domain Profile: High-assurance

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

## AI Readiness: 68.51 / 100

### Pillar 1: Navigate — 94.30 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **100** | 0.12 | max_depth=9, directories=509 |
| N2 | file_granularity | **90** | 0.13 | median_lines=65, large_files=8, per_file_penalty=-10 |
| N3 | module_boundaries | **100** | 0.15 | workspace_files=35, package_manifests=34 |
| N4 | separation_of_concerns | **100** | 0.12 | top_level_dirs=17 (heuristic — override recommended) |
| N5 | code_consistency | **100** | 0.13 | linter=1, formatter=1, ci_linter=1, ci_formatter=1, configs=3 |
| N6 | cicd_pipeline | **100** | 0.15 | workflows=20, has_build=1, has_deploy=1, days_since_push=0 |
| N7 | reproducible_env | **100** | 0.12 | flake=1, flake_lock=1, docker=0, lockfile=7 |
| N8 | repo_foundations | **45** | 0.08 | codeowners=0, gitignore_cats=3(20), security_md=1 |

---

### Pillar 2: Understand — 70.75 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **100** | 0.30 | Rust → automatic 100 (statically typed with full inference) |
| U2 | doc_coverage | **25** | 0.25 | Sampled 1 files but no public items detected — default 25 |
| U3 | readme_substance | **80** | 0.15 | readme_lines=146, desc=1, setup=1, usage=0, arch=1, contrib=1 |
| U4 | architecture_docs | **100** | 0.15 | adrs=11, architecture_md=2 |
| U5 | schema_definitions | **50** | 0.15 | schema_files=1 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 52.50 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (141 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **25** | 0.30 | ratio=.160 (141 test / 881 source) |
| V2 | test_categorization | **75** | 0.20 | detected_categories=2 [integration/e2e,golden] (heuristic — override recommended) |
| V3 | ci_test_execution | **100** | 0.30 | ci_test=1, ci_blocking=1, ci_on_main=1 |
| V4 | coverage_config | **0** | 0.20 | coverage_tool=0, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 94.30 × 0.35 + 70.75 × 0.35 + 52.50 × 0.30
              = 73.51

Constraints: none applied

Penalties: -5
Readiness = 68.51
```

### Penalties

| Penalty | Applied? | Impact | Evidence |
|---------|----------|--------|----------|
| prs without review | NO | -0 | N/A |
| no vulnerability monitoring | NO | -0 | N/A |
| no branch protection | **YES** | -5 | N/A |

---

## AI Adoption: 28.05 / 100

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
| **Security** | Configured | 33 | ✓ security scanning in CI | ✓ AI config .github/copilot-instructions.md: 8/8 categories, includes Security | Configured but no active AI signals in last 30 PRs/50 commits |
| **Delivery** | Configured | 33 | ✓ build_workflow=true, issues=true (open=126) | ✓ AI config .github/copilot-instructions.md: 8/8 categories, includes Delivery | Configured but no active AI signals in last 30 PRs/50 commits |
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
| Size | 190325 KB |
| Open issues | 126 |
| Stars | 149 |
| License | Apache-2.0 |
| Created | 2021-09-07T05:33:14Z |
| Last push | 2026-03-26T11:31:53Z |
| Tree entries | 2425 |
| Source files | 881 |
| Test files | 141 |
| Directories | 509 |
| Max depth | 9 |

### Score Summary

```
Navigate   = 94.30  (weight 0.35)
Understand = 70.75  (weight 0.35)
Verify     = 52.50  (weight 0.30)

Readiness_raw = 73.51
Penalties: -5
Readiness = 68.51

Adoption composite = 28.05
  Code: Configured (33), Testing: Configured (33), Security: Configured (33), Delivery: Configured (33), Governance: None (0)

Quadrant: Fertile Ground
```

---

## Principal Engineer Review

**Corrections applied:** 0 · **Notes raised:** 1

### Review Notes

| Signal | Severity | Note | Action |
|--------|----------|------|--------|
| domain_io_sim | warning | Network/consensus repo without io-sim detected. Verify manually — io-sim may be a transitive dependency not visible in tree. | verify_manually |

---

## Recommendations


### High-Assurance AI Value

Frame AI as **adversarial reviewer**, not code generator, on critical paths:

| AI Role | Where to Apply | Example |
|---------|---------------|---------|
| **Threat modeler** | Core logic, serialization | "What if deserialized tx has length 0? What if fee overflows u64?" |
| **Completeness auditor** | Conformance tests | "Spec defines 14 rules, tests cover 11 — missing rules 7, 12, 14" |
| **Unsafe reviewer** | FFI, crypto boundaries | "This unsafe block assumes aligned input — add alignment check" |
| **Performance challenger** | Hot paths | "This allocation in the inner loop creates GC pressure — use arena allocator" |
| **API/interface reviewer** | Crate boundaries | "Error type for submit_tx doesn't distinguish NetworkError from ValidationError" |
| **Documentation driver** | rustdoc, README, ADRs | "Generate rustdoc for all pub types in this crate" |

**Add `.aiignore`** excluding consensus/crypto paths — signals mature AI governance and prevents AI from generating code in critical modules.

### Strengthen Verification (Verify: 52.50/100)

- **Test/source ratio (V1=25):** Ratio is .160 — add unit tests for modules with zero test coverage. Focus on the most-changed files first for maximum AI verification value.
- **Coverage config (V4=0):** Add coverage tool + threshold to CI.

