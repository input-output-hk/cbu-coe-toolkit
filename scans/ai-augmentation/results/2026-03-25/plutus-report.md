# AAMM — Sample Report: IntersectMBO/plutus

**Model version:** 1.0 · **Scan date:** 2026-03-25 · **Scanned by:** CoE (Dorin Solomon)

---

## Risks

| Severity | Risk | Detail |
|----------|------|--------|
| 🟡 Medium | NO BRANCH PROTECTION | See evidence log |

---

## Summary

| Axis | Score | Detail |
|------|-------|--------|
| **AI Readiness** | **67.39 / 100** | Navigate: 95.50, Understand: 50.50, Verify: 71.00. Penalties: -5. |
| **AI Adoption** | **52.80 / 100** | Code: Active, Testing: Active, Security: None, Delivery: Active, Governance: Active |
| **Quadrant** | **AI-Native** | High readiness, high adoption. |

```
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │  FERTILE    │ ★ AI-NATIVE │
              │   GROUND    │             │
AI Readiness  │              │              │
    ↑         │             │              │
              ├─────────────┼─────────────┤
              │             │  RISKY      │
         Low  │ TRADITIONAL │ ACCELERATION │
              └─────────────┴─────────────┘
```

---

## Domain Profile: Blockchain

**Detected via:** repo topics, .agda files (18)

**AI Value Framing:** AI as adversarial reviewer/challenger/auditor on critical code; quality driver on docs/tests/PRs; code generator only on boilerplate/serialization

### Supplementary Signals

| Signal | Status | Detail |
|--------|--------|--------|
| Formal spec presence | ✓ | 18 .agda files, 0 formal-spec dirs, 0 .cddl files |
| Conformance testing | ✓ | 1140 conformance dirs, oracle=1 |
| Generator discipline | ✓ | cover/classify=1, custom Arbitrary=1, adversarial=0 |
| Concurrency testing (io-sim) | ✗ | io-sim=0 |
| Benchmark regression | ✓ | files=728, dirs=157, CI regression=0 |
| Strict evaluation discipline | ✓ | StrictData/BangPatterns=1 |
| .aiignore on critical paths | ✓ | 1 |

### Domain Risk Flags

| Severity | Risk | Detail |
|----------|------|--------|
| 🟡 Medium | Benchmarks without CI regression detection | Benchmarks exist but no CI-based regression alerting detected |

---

## AI Readiness: 67.39 / 100

### Pillar 1: Navigate — 95.50 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **100** | 0.12 | max_depth=10, directories=2231 |
| N2 | file_granularity | **90** | 0.13 | median_lines=94, large_files=68, per_file_penalty=-10 |
| N3 | module_boundaries | **100** | 0.15 | workspace_files=1, package_manifests=13 |
| N4 | separation_of_concerns | **100** | 0.12 | top_level_dirs=13 (heuristic — override recommended) |
| N5 | code_consistency | **100** | 0.13 | linter=1, formatter=1, ci_enforced=1, configs=4 |
| N6 | cicd_pipeline | **100** | 0.15 | workflows=16, has_build=1, has_deploy=1, days_since_push=0 |
| N7 | reproducible_env | **100** | 0.12 | flake=1, flake_lock=1, docker=0, lockfile=3 |
| N8 | repo_foundations | **60** | 0.08 | codeowners=0, gitignore_cats=5(35), security_md=1 |

---

### Pillar 2: Understand — 50.50 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **100** | 0.30 | Haskell → automatic 100 (statically typed with full inference) |
| U2 | doc_coverage | **25** | 0.25 | Not sampled — requires agent file content analysis. Override recommended. |
| U3 | readme_substance | **20** | 0.15 | readme_lines=73, desc=1, setup=0, usage=0, arch=0, contrib=0 |
| U4 | architecture_docs | **75** | 0.15 | adrs=5, architecture_md=0 |
| U5 | schema_definitions | **0** | 0.15 | schema_files=0 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 71.00 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (261 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **50** | 0.30 | ratio=.240 (261 test / 1087 source) |
| V2 | test_categorization | **100** | 0.20 | detected_categories=3 [unit,property,golden] (heuristic — override recommended) |
| V3 | ci_test_execution | **80** | 0.30 | ci_test=1, ci_blocking=1 |
| V4 | coverage_config | **60** | 0.20 | coverage_tool=1, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 95.50 × 0.35 + 50.50 × 0.35 + 71.00 × 0.30
              = 72.39

Constraints: none applied

Penalties: -5
Readiness = 67.39
```

### Penalties

| Penalty | Applied? | Impact | Evidence |
|---------|----------|--------|----------|
| prs without review | NO | -0 | N/A |
| no vulnerability monitoring | NO | -0 | N/A |
| no branch protection | **YES** | -5 | N/A |

---

## AI Adoption: 52.80 / 100

### Detection Layer Results

| Layer | Method | Result |
|-------|--------|--------|
| **L1_tree** | L1 | 2 found — .cursorignore,.github/copilot-instructions.md |
| **L2_commits** | L2 | 5 found —  |
| **L3_pr_author** | L3 | N/A —  |
| **L4_pr_body** | L4 | None —  |
| **L5_submodules** | L5 | None —  |

### Per-Dimension Scoring

| Dimension | Stage | Score | Condition A | Condition B | Annotation |
|-----------|-------|-------|-------------|-------------|------------|
| **Code** | Active | 66 | ✓ linter=1, codeowners=0 | ✓ AI config .github/copilot-instructions.md: 7/8 categories, includes Architecture + Conventions | Active AI usage detected |
| **Testing** | Active | 66 | ✓ test execution found in CI workflows | ✓ AI config .github/copilot-instructions.md: 7/8 categories, includes Testing | Active AI usage detected |
| **Security** | None | 0 | ✗ dependabot exists but doesn't cover Haskell | ✗ no AI config with Security category | Emerging AI usage |
| **Delivery** | Active | 66 | ✓ build_workflow=true, issues=true (open=233) | ✓ AI config .github/copilot-instructions.md: 7/8 categories, includes Delivery | Active AI usage detected |
| **Governance** | Active | 66 | ✓ 2 AI config files in tree, 0 in submodules | ✓ usage expectations documented + .aiignore present | Active AI usage detected |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `IntersectMBO/plutus` |
| Description | The Plutus language implementation and tools |
| Default branch | `master` |
| Private | false |
| Primary language | Haskell (83.6%) |
| Languages | Haskell: 83.6%,Untyped Plutus Core: 15.7%,R: 0.2%,Go Template: 0.1%,Shell: 0.1% |
| Size | 281572 KB |
| Open issues | 233 |
| Stars | 1636 |
| License | Apache-2.0 |
| Created | 2016-11-15T22:38:43Z |
| Last push | 2026-03-25T10:47:09Z |
| Tree entries | 10918 |
| Source files | 1087 |
| Test files | 261 |
| Directories | 2231 |
| Max depth | 10 |

### Score Summary

```
Navigate   = 95.50  (weight 0.35)
Understand = 50.50  (weight 0.35)
Verify     = 71.00  (weight 0.30)

Readiness_raw = 72.39
Penalties: -5
Readiness = 67.39

Adoption composite = 52.80
  Code: Active (66), Testing: Active (66), Security: None (0), Delivery: Active (66), Governance: Active (66)

Quadrant: AI-Native
```

---

## Principal Engineer Review

**Corrections applied:** 0 · **Notes raised:** 2

### Review Notes

| Signal | Severity | Note | Action |
|--------|----------|------|--------|
| U2 | info | Default score (25) — Haskell repos typically have Haddock docs. Agent should sample 10 largest + 5 most recent .hs files for {- | -} / -- | doc comments. | override_recommended |
| nav_und_gap | warning | Navigate (95.50) >> Understand (50.50). Well-structured codebase but AI can't understand intent. Typically means docs/comments gap. High-impact improvement area. | operator_attention |

**⚠ 1 signal(s) use default scores and need agent override.** Scores marked `override_recommended` above are heuristic defaults — the scanning agent should sample actual file content and apply evidence-based overrides for accurate results. Until overridden, the affected pillar scores may be understated.

---

## Recommendations


### Blockchain-Specific AI Value

Frame AI as **adversarial reviewer**, not code generator, on critical paths:

| AI Role | Where to Apply | Example |
|---------|---------------|---------|
| **Threat modeler** | Ledger rules, tx validation | "What if amount overflows? What if block has 0 txs?" |
| **Completeness auditor** | Conformance tests | "Spec defines 14 UTXO rules, tests cover 11 — missing rules 7, 12, 14" |
| **Generator quality reviewer** | Property tests | "genBlock never produces >100 txs, cover shows 0% on txCount>50" |
| **Performance challenger** | Hot paths | "This fold on Map.union is O(n×m) per block — benchmark?" |
| **API/interface reviewer** | Cross-component boundaries | "Error type for applyTx doesn't distinguish recoverable from fatal" |
| **Documentation driver** | Haddock, README, ADRs | "Generate docs for all exported types in this era module" |

### Improve AI Understanding (Understand: 50.50/100)

- **Documentation coverage (U2=25):** Add Haddock comments (`{- | -}` / `-- |`) to exported functions and types. This is the single highest-impact improvement for AI comprehension.
- **README substance (U3=20):** Add Architecture and Usage sections to README. AI agents read README first — a good README multiplies AI effectiveness across all tasks.

