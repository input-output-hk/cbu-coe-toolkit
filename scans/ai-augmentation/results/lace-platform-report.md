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
| **AI Readiness** | **60.84 / 100** | Navigate: 91.9, Understand: 44.5, Verify: 77.0. Penalties: -10. |
| **AI Adoption** | **52.8 / 100** | Code: Active, Testing: Active, Security: None, Delivery: Active, Governance: Active |
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

## AI Readiness: 60.84 / 100

### Pillar 1: Navigate — 91.9 / 100 (weight: 0.35)

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
| N8 | repo_foundations | **75** | 0.08 | codeowners=1, gitignore_cats=5(35), security_md=0 (CORRECTED: CODEOWNERS in .github/ — script only searches root; API confirms .github/CODEOWNERS exists; score=40+35=75) |

---

### Pillar 2: Understand — 44.5 / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| U1 | type_safety | **40** | 0.3 | TypeScript, tsconfig exists but not fetched — override recommended |
| U2 | doc_coverage | **25** | 0.25 | Not sampled — requires agent file content analysis. Override recommended. |
| U3 | readme_substance | **100** | 0.15 | readme_lines=562, desc=1, setup=1, usage=1, arch=1, contrib=1 |
| U4 | architecture_docs | **75** | 0.15 | adrs=25, architecture_md=0 |
| U5 | schema_definitions | **0** | 0.15 | schema_files=0 (heuristic — override recommended for dep-based schemas like zod/io-ts) |

---

### Pillar 3: Verify — 77.0 / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** PASS (383 test files)

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
| V1 | test_source_ratio | **50** | 0.3 | ratio=.170 (383 test / 2251 source) → CORRECTED: apps/lace-extension-e2e/src/ files (assertions, page objects, steps, ~120 files) are test infrastructure counted as source; corrected ratio ~0.24 → score 50 |
| V2 | test_categorization | **100** | 0.2 | detected_categories=2 [unit,.test.ts,integration/e2e] (CORRECTED: 383 .test.ts files in packages/contract/*/test/ are unit tests; script only detected integration/e2e category) |
| V3 | ci_test_execution | **100** | 0.3 | ci_test=1, ci_blocking=1 (CORRECTED: ci.yml triggers on pull_request + push:branches:main — satisfies both PR and main requirement) |
| V4 | coverage_config | **60** | 0.2 | coverage_tool=1, threshold=0 |

---

### Cross-Pillar Constraints

```
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = 91.9 × 0.35 + 44.5 × 0.35 + 77.0 × 0.30
              = 70.84

Constraints: none applied

Penalties: -10
Readiness = 60.84
```

### Penalties

| Penalty | Applied? | Impact | Evidence |
|---------|----------|--------|----------|
| prs without review | NO | 0 | N/A |
| no vulnerability monitoring | **YES** | -5 | N/A |
| no branch protection | **YES** | -5 | N/A |

---

## AI Adoption: 52.8 / 100

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
| **Code** | Active | 66 | ✓ linter=1, codeowners=0 | ✓ AI config .claude/commands/test/create-mobile-integration.md: 7/8 categories, includes Architecture + Conventions | AI active in workflow but claude.yml has read-only permissions — not a required status check, does not gate merges; Integrated requires merge-blocking AI |
| **Testing** | Active | 66 | ✓ test execution found in CI workflows | ✓ AI config .claude/commands/test/create-mobile-integration.md: 7/8 categories, includes Testing | AI active in CI review but does not gate merges — same as Code dimension |
| **Security** | None | 0 | ✗ dependabot exists but doesn't cover TypeScript | ✓ AI config .claude/commands/test/create-mobile-integration.md: 7/8 categories, includes Security | AI config present, practice not active |
| **Delivery** | Active | 66 | ✓ build_workflow=true, issues=true (open=48) | ✓ AI config .claude/commands/test/create-mobile-integration.md: 7/8 categories, includes Delivery | Active evidence: Cursor-attributed CI workflow PRs; no automated AI changelog/release pipeline found — Integrated not confirmed |
| **Governance** | Active | 66 | ✓ 26 AI config files in tree, 0 in submodules | ✓ usage expectations documented + .aiignore present | Active: 26 AI files, 7 agents, 5 MCP servers, config evolution PR; Integrated requires cross-repo consistency or AI governance in branch protection — neither confirmed |

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
| Languages | TypeScript: 89.4%,Objective-C: 7.9%,JavaScript: 2.1%,Shell: 0.3%,Gherkin: 0.1% |
| Size | 133188 KB |
| Open issues | 52 |
| Stars | 4 |
| License | Unknown |
| Created | 2024-04-11T14:07:57Z |
| Last push | 2026-03-26T09:51:23Z |
| Tree entries | 5087 |
| Source files | 2251 |
| Test files | 383 |
| Directories | 1121 |
| Max depth | 11 |

### Score Summary

```
Navigate   = 91.9  (weight 0.35)
Understand = 44.5  (weight 0.35)
Verify     = 77.0  (weight 0.30)

Readiness_raw = 70.84
Penalties: -10
Readiness = 60.84

Adoption composite = 52.8
  Code: Active (66), Testing: Active (66), Security: None (0), Delivery: Active (66), Governance: Active (66)

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

### Improve AI Understanding (Understand: 44.5/100)

- **Documentation coverage (U2=25):** Add TSDoc/JSDoc (`/** */`) to exported functions and types. This is the single highest-impact improvement for AI comprehension.

