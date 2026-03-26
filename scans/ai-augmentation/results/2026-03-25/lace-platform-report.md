# AAMM — Sample Report: input-output-hk/lace-platform

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
| **AI Readiness** | **57.66 / 100** | Navigate: 88.70, Understand: 44.50, Verify: 53.50. Penalties: -5. |
| **AI Adoption** | **80.00 / 100** | Code: Integrated, Testing: Integrated, Security: None, Delivery: Integrated, Governance: Integrated |
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
| .aiignore on critical paths | ✓ | 1 |

### Domain Risk Flags

| Severity | Risk | Detail |
|----------|------|--------|
| 🟡 Medium | No benchmark regression detection | Performance-sensitive blockchain code without benchmarks |

---

## AI Readiness: 57.66 / 100

### Pillar 1: Navigate — 88.70 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **100** | 0.12 | max_depth=11, directories=1121 |
| N2 | file_granularity | **90** | 0.13 | median_lines=40, large_files=11, per_file_penalty=-10 |
| N3 | module_boundaries | **100** | 0.15 | workspace_files=1, package_manifests=108 |
| N4 | separation_of_concerns | **100** | 0.12 | top_level_dirs=13 (heuristic — override recommended) |
| N5 | code_consistency | **100** | 0.13 | linter=1, formatter=1, ci_enforced=1, configs=114 |
| N6 | cicd_pipeline | **100** | 0.15 | workflows=17, has_build=1, has_deploy=1, days_since_push=0 |
| N7 | reproducible_env | **60** | 0.12 | flake=0, flake_lock=0, docker=0, lockfile=1 |
| N8 | repo_foundations | **35** | 0.08 | codeowners=0, gitignore_cats=5(35), security_md=0 |

---

### Pillar 2: Understand — 44.50 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **40** | 0.30 | TypeScript, tsconfig exists but not fetched — override recommended |
| U2 | doc_coverage | **25** | 0.25 | Not sampled — requires agent file content analysis. Override recommended. |
| U3 | readme_substance | **100** | 0.15 | readme_lines=562, desc=1, setup=1, usage=1, arch=1, contrib=1 |
| U4 | architecture_docs | **75** | 0.15 | adrs=25, architecture_md=0 |
| U5 | schema_definitions | **0** | 0.15 | schema_files=0 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 53.50 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (383 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **25** | 0.30 | ratio=.170 (383 test / 2251 source) |
| V2 | test_categorization | **50** | 0.20 | detected_categories=1 [integration/e2e] (heuristic — override recommended) |
| V3 | ci_test_execution | **80** | 0.30 | ci_test=1, ci_blocking=1 |
| V4 | coverage_config | **60** | 0.20 | coverage_tool=1, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 88.70 × 0.35 + 44.50 × 0.35 + 53.50 × 0.30
              = 62.66

Constraints: none applied

Penalties: -5
Readiness = 57.66
```

### Penalties

| Penalty | Applied? | Impact | Evidence |
|---------|----------|--------|----------|
| prs without review | NO | -0 | N/A |
| no vulnerability monitoring | NO | -0 | N/A |
| no branch protection | **YES** | -5 | N/A |

---

## AI Adoption: 80.00 / 100

### Detection Layer Results

| Layer | Method | Result |
|-------|--------|--------|
| **L1_tree** | L1 | 26 found — .claude/agents/codebase-locator.md,.claude/agents/confluence-page-researcher.md,.claude/agents/figma-design-researcher.md,.claude/agents/general-researcher.md,.claude/agents/git-commit-researcher.md,.claude/agents/jira-ticket-researcher.md,.claude/agents/web-fetch-researcher.md,.claude/commands/git-commit.md,.claude/commands/plan.md,.claude/commands/prompt-engineer.md,.claude/commands/research.md,.claude/commands/test/analyze-mobile-integration.md,.claude/commands/test/create-mobile-integration.md,.claude/docs/PRINCIPLES.md,.claude/docs/cli-development.md,.claude/docs/development.md,.claude/docs/ui-development.md,.claude/gha-code-review-request.md,.claude/gha-implementation-request.md,.claude/settings.json,.claude/skills/git-commit/SKILL.md,.claude/skills/nx/SKILL.md,.claude/skills/troubleshoot/SKILL.md,.cursorignore,.mcp.json,CLAUDE.md |
| **L2_commits** | L2 | 1 found —  |
| **L3_pr_author** | L3 | N/A —  |
| **L4_pr_body** | L4 | 8 found —  |
| **L5_submodules** | L5 | None —  |

### Per-Dimension Scoring

| Dimension | Stage | Score | Condition A | Condition B | Annotation |
|-----------|-------|-------|-------------|-------------|------------|
| **Code** | Integrated | 100 | ✓ linter=1, codeowners=0 | ✓ AI config .claude/commands/test/create-mobile-integration.md: 7/8 categories, includes Architecture + Conventions | AI integrated in CI pipeline |
| **Testing** | Integrated | 100 | ✓ test execution found in CI workflows | ✓ AI config .claude/commands/test/create-mobile-integration.md: 7/8 categories, includes Testing | AI integrated in CI pipeline |
| **Security** | None | 0 | ✗ dependabot exists but doesn't cover TypeScript | ✓ AI config .claude/commands/test/create-mobile-integration.md: 7/8 categories, includes Security | AI config present, practice not active |
| **Delivery** | Integrated | 100 | ✓ build_workflow=true, issues=true (open=48) | ✓ AI config .claude/commands/test/create-mobile-integration.md: 7/8 categories, includes Delivery | AI integrated in CI pipeline |
| **Governance** | Integrated | 100 | ✓ 26 AI config files in tree, 0 in submodules | ✓ usage expectations documented + .aiignore present | AI integrated in CI pipeline |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `input-output-hk/lace-platform` |
| Description | The fast and easy way to explore Web3 |
| Default branch | `main` |
| Private | true |
| Primary language | TypeScript (89.3%) |
| Languages | TypeScript: 89.3%,Objective-C: 8%,JavaScript: 2.1%,Shell: 0.3%,Gherkin: 0.1% |
| Size | 132739 KB |
| Open issues | 48 |
| Stars | 4 |
| License | Unknown |
| Created | 2024-04-11T14:07:57Z |
| Last push | 2026-03-25T13:19:50Z |
| Tree entries | 5064 |
| Source files | 2251 |
| Test files | 383 |
| Directories | 1121 |
| Max depth | 11 |

### Score Summary

```
Navigate   = 88.70  (weight 0.35)
Understand = 44.50  (weight 0.35)
Verify     = 53.50  (weight 0.30)

Readiness_raw = 62.66
Penalties: -5
Readiness = 57.66

Adoption composite = 80.00
  Code: Integrated (100), Testing: Integrated (100), Security: None (0), Delivery: Integrated (100), Governance: Integrated (100)

Quadrant: AI-Native
```

---

## Principal Engineer Review

**Corrections applied:** 0 · **Notes raised:** 2

### Review Notes

| Signal | Severity | Note | Action |
|--------|----------|------|--------|
| U2 | info | Default score (25) — Agent should sample .ts files for JSDoc/TSDoc comments. | override_recommended |
| nav_und_gap | warning | Navigate (88.70) >> Understand (44.50). Well-structured codebase but AI can't understand intent. Typically means docs/comments gap. High-impact improvement area. | operator_attention |

**⚠ 1 signal(s) use default scores and need agent override.** Scores marked `override_recommended` above are heuristic defaults — the scanning agent should sample actual file content and apply evidence-based overrides for accurate results. Until overridden, the affected pillar scores may be understated.

---

## Recommendations


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

### Improve AI Understanding (Understand: 44.50/100)

- **Documentation coverage (U2=25):** Add TSDoc/JSDoc (`/** */`) to exported functions and types. This is the single highest-impact improvement for AI comprehension.

### Strengthen Verification (Verify: 53.50/100)

- **Test/source ratio (V1=25):** Ratio is .170 — add unit tests for modules with zero test coverage. Focus on the most-changed files first for maximum AI verification value.
- **Test categorization (V2=50):** Expand test types beyond what's currently detected. Add unit tests (if only integration/e2e exist) or property-based tests (e.g., fast-check for TypeScript, QuickCheck for Haskell) for richer AI verification.
- **Coverage threshold (V4=60):** Coverage tool detected but no enforcement threshold. Add a minimum coverage gate to CI to prevent regression.

