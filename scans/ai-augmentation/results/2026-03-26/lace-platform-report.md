# AAMM — Sample Report: input-output-hk/lace-platform

**Model version:** 1.0 · **Scan date:** 2026-03-26 · **Scanned by:** CoE (Dorin Solomon)

---

## Risks

| Severity | Risk | Detail |
|----------|------|--------|
| 🟡 Medium | NO VULNERABILITY MONITORING | See evidence log |
| 🟡 Medium | NO BRANCH PROTECTION | See evidence log |

---

## Summary

| Axis | Score | Detail |
|------|-------|--------|
| **AI Readiness** | **60.97 / 100** | Navigate: 89.30, Understand: 62.50, Verify: 59.50. Penalties: -10. |
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

## AI Readiness: 60.97 / 100

### Pillar 1: Navigate — 89.30 / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| N1 | file_organization | **100** | 0.12 | max_depth=11, directories=1123 |
| N2 | file_granularity | **90** | 0.13 | median_lines=40, large_files=11, per_file_penalty=-10 |
| N3 | module_boundaries | **100** | 0.15 | workspace_files=1, package_manifests=108 |
| N4 | separation_of_concerns | **100** | 0.12 | top_level_dirs=13 (heuristic — override recommended) |
| N5 | code_consistency | **80** | 0.13 | linter=1, formatter=1, ci_linter=0, ci_formatter=0, configs=114 |
| N6 | cicd_pipeline | **100** | 0.15 | workflows=18, has_build=1, has_deploy=1, days_since_push=0 |
| N7 | reproducible_env | **60** | 0.12 | flake=0, flake_lock=0, docker=0, lockfile=1 |
| N8 | repo_foundations | **75** | 0.08 | codeowners=1, gitignore_cats=5(35), security_md=0 |

---

### Pillar 2: Understand — 62.50 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **100** | 0.30 | TypeScript strict: true (via tsconfig.base.json — NX pattern) |
| U2 | doc_coverage | **25** | 0.25 | Not sampled — requires agent file content analysis. Override recommended. |
| U3 | readme_substance | **100** | 0.15 | readme_lines=562, desc=1, setup=1, usage=1, arch=1, contrib=1 |
| U4 | architecture_docs | **75** | 0.15 | adrs=25, architecture_md=0 |
| U5 | schema_definitions | **0** | 0.15 | schema_files=0 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 59.50 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (389 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **25** | 0.30 | ratio=.171 (389 test / 2264 source) |
| V2 | test_categorization | **50** | 0.20 | detected_categories=1 [integration/e2e] (heuristic — override recommended) |
| V3 | ci_test_execution | **100** | 0.30 | ci_test=1, ci_blocking=1, ci_on_main=1 |
| V4 | coverage_config | **60** | 0.20 | coverage_tool=1, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 89.30 × 0.35 + 62.50 × 0.35 + 59.50 × 0.30
              = 70.97

Constraints: none applied

Penalties: -10
Readiness = 60.97
```

### Penalties

| Penalty | Applied? | Impact | Evidence |
|---------|----------|--------|----------|
| prs without review | NO | -0 | N/A |
| no vulnerability monitoring | **YES** | -5 | N/A |
| no branch protection | **YES** | -5 | N/A |

---

## AI Adoption: 52.80 / 100

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
| **Code** | Active | 66 | ✓ linter=1, codeowners=1 | ✓ AI config .claude/commands/test/create-mobile-integration.md: 7/8 categories, includes Architecture + Conventions | Active AI usage detected |
| **Testing** | Active | 66 | ✓ test execution found in CI workflows | ✓ AI config .claude/commands/test/create-mobile-integration.md: 7/8 categories, includes Testing | Active AI usage detected |
| **Security** | None | 0 | ✗ dependabot exists but doesn't cover TypeScript | ✓ AI config .claude/commands/test/create-mobile-integration.md: 7/8 categories, includes Security | AI config present, practice not active |
| **Delivery** | Active | 66 | ✓ build_workflow=true, issues=true (open=52) | ✓ AI config .claude/commands/test/create-mobile-integration.md: 7/8 categories, includes Delivery | Active AI usage detected |
| **Governance** | Active | 66 | ✓ 26 AI config files in tree, 0 in submodules | ✓ usage expectations documented + .aiignore present | Active AI usage detected |

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | `input-output-hk/lace-platform` |
| Description | The fast and easy way to explore Web3 |
| Default branch | `main` |
| Private | true |
| Primary language | TypeScript (89.4%) |
| Languages | TypeScript: 89.4%,Objective-C: 7.9%,JavaScript: 2.1%,Shell: 0.3%,Gherkin: 0.1% |
| Size | 133191 KB |
| Open issues | 52 |
| Stars | 4 |
| License | Unknown |
| Created | 2024-04-11T14:07:57Z |
| Last push | 2026-03-26T11:33:44Z |
| Tree entries | 5087 |
| Source files | 2264 |
| Test files | 389 |
| Directories | 1123 |
| Max depth | 11 |

### Score Summary

```
Navigate   = 89.30  (weight 0.35)
Understand = 62.50  (weight 0.35)
Verify     = 59.50  (weight 0.30)

Readiness_raw = 70.97
Penalties: -10
Readiness = 60.97

Adoption composite = 52.80
  Code: Active (66), Testing: Active (66), Security: None (0), Delivery: Active (66), Governance: Active (66)

Quadrant: AI-Native
```

---

## Principal Engineer Review

**Corrections applied:** 0 · **Notes raised:** 1

### Review Notes

| Signal | Severity | Note | Action |
|--------|----------|------|--------|
| U2 | warning | U2 was not sampled (doc-coverage.json missing). Re-run collect-readiness.sh. | rescan_recommended |

---

## Recommendations

### Improve AI Understanding (Understand: 62.50/100)

- **Documentation coverage (U2=25):** Add TSDoc/JSDoc (`/** */`) to exported functions and types. This is the single highest-impact improvement for AI comprehension.

### Strengthen Verification (Verify: 59.50/100)

- **Test/source ratio (V1=25):** Ratio is .171 — add unit tests for modules with zero test coverage. Focus on the most-changed files first for maximum AI verification value.
- **Test categorization (V2=50):** Expand test types beyond what's currently detected. Add unit tests (if only integration/e2e exist) or property-based tests (e.g., fast-check for TypeScript, QuickCheck for Haskell) for richer AI verification.
- **Coverage threshold (V4=60):** Coverage tool detected but no enforcement threshold. Add a minimum coverage gate to CI to prevent regression.

