# AAMM v6 Detailed Log: IntersectMBO/cardano-ledger
> Scan date: 2026-03-31 | Agent: claude-opus-4-6

---

## 1. Data Collection

### API Calls

| Endpoint | Response | Notes |
|----------|----------|-------|
| `GET /repos/IntersectMBO/cardano-ledger` | 200 | default_branch=master, size=150094KB, stars=285, forks=175, not archived |
| `GET /repos/.../git/trees/master?recursive=1` | 200 | 2328 files, truncated=false |
| `GET /repos/.../commits?sha=master&per_page=100` | 200 | 100 commits returned |
| `GET /repos/.../pulls?state=closed&sort=updated&direction=desc&per_page=30` | 200 | 30 PRs returned |
| `GET /repos/.../pulls/{N}/reviews` (×5) | 200 | PR #5670: 6 reviews, #5635: 16 reviews, #5609: 1, #5671: 2, #5675: 15 |

Note: Initial API calls with GITHUB_TOKEN failed (401 Bad credentials). All calls succeeded without auth (public repo).

### Local Clone

Repo cloned to `/home/devuser/repos/cardano-ledger/` during this session. Used for:
- `git log` analysis (churn, AI attribution, commit frequency)
- File content verification (Haddock coverage, module structure, Arbitrary.hs contents)
- Structure exploration (Rules modules, Imp tests, conformance, CDDL)

### Key Files Read

**Present:**
- `README.md` — comprehensive, covers all eras with spec links, repository structure
- `CONTRIBUTING.md` — trunk-based development, release process, CHaP publishing, formatting scripts
- `CODEOWNERS` — present
- `.github/PULL_REQUEST_TEMPLATE.md` — checklist: commits, tests, CHANGELOG, versions, formatting, CDDL, hie.yaml
- `.github/workflows/haskell.yml` — builds GHC 9.6.7/9.8.4/9.10.3/9.12.2/9.14.1, fourmolu enforced
- `.github/workflows/bench.yml` — benchmarks on master push, uses nix
- `.github/workflows/gh-pages.yml` — Haddock deployment
- `.github/workflows/push-specs.yml` — spec publishing
- `cabal.project` — 28 packages, CHaP repo, constrained-generators pinned, formal-ledger-specifications pinned
- `docs/NewEra.md` — detailed era transition guide
- `flake.nix` — present (13552 bytes)
- `.claude/skills/update-changelogs/SKILL.md` — Claude Code skill added via PR #5670

**Absent (confirmed):**
- CLAUDE.md, AGENTS.md, .cursorrules, .mcp.json, copilot-instructions.md, .aiignore, ARCHITECTURE.md, .hlint.yaml

### Derived Data

**High-churn modules (top 10 from last 100 commits):**
1. eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules — 19 changes
2. eras/dijkstra/impl — 13
3. eras/conway/impl/src/Cardano/Ledger/Conway/Rules — 13
4. eras/shelley/impl/src/Cardano/Ledger/Shelley/Rules — 12
5. eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra — 12
6. eras/alonzo/impl/src/Cardano/Ledger/Alonzo/Plutus — 12
7. eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra — 10
8. libs/cardano-ledger-core/src/Cardano/Ledger — 9
9. libs/cardano-ledger-core — 9
10. eras/conway/impl/test/Test/Cardano/Ledger/Conway/Binary — 9

**AI Attribution:**
- 2 commits with "Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
  - `b566f359` (2026-03-16, Joosep Jääger): "Add custom generator for plutus scripts to avoid set collisions"
    - Files: alonzo/HuddleSpec.hs, babbage/HuddleSpec.hs, conway/HuddleSpec.hs, conway/CddlSpec.hs, shelley/HuddleSpec.hs, core/HuddleSpec.hs
  - `d20b44d3` (2026-03-16, Joosep Jääger): "Enable Dijkstra CDDL tests and add plutusScriptGen to plutus_v4_script"
    - Files: dijkstra/HuddleSpec.hs, dijkstra/CddlSpec.hs
- 1 dependabot[bot] PR (bumping requests package)
- No other AI bot PRs detected

**AI Bot Activity:**
- dependabot[bot]: 1 PR (Python dependency bump in doc/)
- No copilot[bot], coderabbit-ai[bot], or other AI review bots

**Commit Frequency (March 2026):** Active daily, 2-11 commits/day, last commit 2026-03-30

**PR Data:**
- Most PRs have substantial descriptions (1200-9400 chars)
- Active review culture: 1-16 reviews per sampled PR
- PR template well-used with checklist items

---

## 2. KB Pattern Matching

### Matched Patterns (11 total, 8 approved by Stage A)

| KB Pattern | Match | Evidence | Approved |
|------------|-------|----------|----------|
| hs_imp_test_generation | YES | 23 Dijkstra Rules, 4 Imp tests, Conway 13 as template | ✅ |
| cc_claude_md_context | YES | CLAUDE.md absent, AI in use, complex project | ✅ |
| cc_aiignore_boundaries | YES | .aiignore absent, critical paths, AI active | ✅ |
| hs_haddock_generation | YES | Sub-1% doc density, Haddock infra deployed | ✅ |
| hs_agda_conformance | YES | Formal spec pinned, Conway conformance exists, no Dijkstra | ✅ |
| hs_constrained_generators | YES | Library pinned, AI precedent, Sub* modules | ✅ |
| hs_era_transition_docs | YES | NewEra.md exists, Dijkstra active | ✅ |
| hs_cddl_conformance | YES | 8 CDDL files, AI commits in area, 6 xdescribe gaps | ✅ |
| hs_quickcheck_corner_cases | YES | Matched but rejected as duplicate of constrained-gen | ❌ |
| hs_debug_state_transitions | YES | Matched but rejected as generic activity description | ❌ |
| hs_cross_era_review | YES | Matched but rejected as generic AI review suggestion | ❌ |

### Unmatched Patterns
| KB Pattern | Why Not Matched |
|------------|----------------|
| cc_pr_descriptions | PRs already have substantial descriptions (1200-9400 chars), active review culture |
| cc_commit_messages | Commit messages are informative, low direct ROI |
| cc_onboarding_docs | CONTRIBUTING.md exists, README comprehensive, lower priority vs domain-specific opportunities |

### Novel Opportunities (not in KB)
None identified. The KB patterns covered all significant repo-specific opportunities.

---

## 3. Adversarial Stage A — Full Dialogue

### Invocation
Dispatched as separate Agent subagent with:
- Stage A adversarial prompt (from prompts/adversarial-stage-a.md)
- Opportunity map (11 opportunities as JSON)
- Repo data summary + access to local clone for verification

### Results
- **Duration:** ~155 seconds
- **Outcome:** 8 approved, 3 rejected

### Rejections (full reasoning)

**opp-ledger-corner-cases** — Failed: Specificity, Feasibility
> Near-identical to opp-ledger-constrained-gen. Both target constrained generators for Dijkstra Sub* modules, cite the same AI commits (b566f359, d20b44d3) and same Conway testlib as reference. "Discover untested corner cases focusing on cross-field invariant gaps" is vague enough to apply to any property-testing codebase. No specific invariant gaps named.

**opp-ledger-debug-sts** — Failed: Specificity, Feasibility
> "Use AI for state transition debugging" could be copy-pasted onto ANY STS-based Haskell project. Names no specific bugs, debugging scenarios, or known spec divergence. Evidence lists structural facts but identifies no concrete debugging target. A team would ask: "Debug what, exactly?"

**opp-ledger-cross-era-review** — Failed: Specificity, Feasibility
> Generic AI code review suggestion. PR template already has CDDL checklist. No analysis of what AI review would catch that 5+ human reviewers and CI do not. No specific past regression cited as motivation.

### Verification Notes from Stage A
- All file paths and directory structures confirmed against local clone
- Genesis.hs actually has 0 doc comments (not 1 as initially claimed) — density worse than stated
- PR #5670 merge commit fff2cdd21 confirmed
- constrained-generators and formal-ledger-specifications both pinned in cabal.project confirmed

---

## 4. Component Assessment Reasoning

### Adoption State

| Opportunity | State | Reasoning |
|-------------|-------|-----------|
| opp-ledger-imp-dijkstra | Absent | Searched: `git log -100` for AI attribution in testlib/Imp/ files — none found. No AI config references test generation. |
| opp-ledger-claude-md | Absent | File doesn't exist — opportunity is to create it. |
| opp-ledger-aiignore | Absent | File doesn't exist — opportunity is to create it. |
| opp-ledger-haddock | Absent | No AI-attributed commits touch documentation. No AI config references doc generation. |
| opp-ledger-agda-conformance | Absent | No AI-attributed commits in libs/cardano-ledger-conformance/. |
| opp-ledger-constrained-gen | Partial | 2 commits (b566f359, d20b44d3) used Claude for generator work (plutusScriptGen). Related but not systematic constrained-generator usage. |
| opp-ledger-era-transition-docs | Absent | No AI-attributed commits in docs/ or Translation.hs modules. |
| opp-ledger-cddl-conformance | Partial | Same 2 commits fixed CDDL test generation — AI used in this exact area but not systematically. |

### Readiness Assessment

All opportunities assessed as **Practiced** (≥75% KB criteria met). Full criteria evaluation in assessment.json.

Key observations:
- This repo is exceptionally well-structured for AI augmentation
- Every KB readiness criterion is met across all 8 opportunities
- The gap is adoption, not readiness — consistent with v5 finding

### Risk Surface

Identified 5 risk-relevant paths. Only one has confirmed AI exposure (CDDL spec/test files — MEDIUM blast radius, LOW detection difficulty). No AI commits touch HIGH blast radius paths (consensus rules, STS rules, core ledger state).

### Ad-hoc AI Usage Flag

**NOT triggered.** Rationale:
- AI-attributed commits present in CDDL files across multiple eras
- BUT `.claude/skills/update-changelogs/SKILL.md` constitutes "equivalent AI config with substantive content" — an intentionality signal per scoring-model.md Section 3.4
- This is a recent addition (PR #5670) indicating emerging formalization of AI tool usage

---

## 5. Recommendation Generation Reasoning

All 8 recommendations generated as `start_now` type based on:
- 6 opportunities: Adoption=Absent + Readiness=Practiced → start_now (correct per matrix)
- 2 opportunities: Adoption=Partial + Readiness=Practiced → start_now (borderline — Partial is not Absent)

The 2 borderline cases were caught by Stage B adversarial review (type mismatch for Adoption=Partial).

---

## 6. Adversarial Stage B — Full Dialogue

### Invocation
Dispatched as separate Agent subagent with:
- Stage B adversarial prompt (from prompts/adversarial-stage-b.md)
- 8 recommendations as JSON
- Assessment context (adoption, readiness, risk surface)
- Repo data + local clone access

### Results
- **Duration:** ~139 seconds
- **Outcome:** 5 approved, 3 rejected

### Rejections (full reasoning)

**rec-ledger-haddock** — Failed: Measurability
> Core.hs already has 18 Haddock comments, exceeding proposed "3 per module" threshold. Outcome measures state not delta — unverifiable as proof of work done. Fix: target modules with 0 current comments.

**rec-ledger-constrained-gen** — Failed: Measurability, Groundedness
> Dijkstra Arbitrary.hs (314 lines) already contains Arbitrary instances for all 10 Sub* pred-failure types. "Sub* data types that did not have generators before" is factually wrong. Type mismatch: start_now invalid for Adoption=Partial.

**rec-ledger-cddl-expand** — Failed: Measurability
> CddlSpec.hs already has ~40 test invocations. Real gap is 6 xdescribe'd test groups, not missing schema branches. "5 additional test cases" is ambiguous. Type mismatch: start_now invalid for Adoption=Partial.

### ROI Order Correction from Stage B
Stage B recommended: #1 (Imp tests), #2 (CLAUDE.md), #5 (conformance), #3 (.aiignore), #4 (haddock).
Reasoning: .aiignore is defensive with near-zero AI modification risk currently; conformance testing provides immediate value in highest-churn era.

### Consistency Notes
.aiignore lists `*.cddl` as protected, but CDDL test recommendations involve adjacent files. Not contradictory (tests vs definitions) but should be noted in CLAUDE.md as "review-required, not blocked."

---

## 7. Anomalies and Limitations

1. **GITHUB_TOKEN invalid:** Initial API calls failed with 401. All calls succeeded without auth since repo is public. Rate limiting risk without auth — no rate limit issues encountered during this scan.

2. **Haddock density underreported then corrected:** Initial assessment claimed Genesis.hs had 1 doc comment; Stage A verified 0. Density is even worse than initially stated.

3. **Arbitrary.hs coverage not initially verified:** Primary agent assumed Sub* types lacked generators; Stage B discovered they already exist (314 lines, 10+ types). This highlights the value of adversarial review catching factual errors.

4. **v5 to v6 transition:** Previous scan (2026-03-28) was v5 with different assessment framework. No delta computed per scoring-model rules. The v5 "HIGH readiness" finding aligns with v6's "all Practiced" — both frameworks agree the repo is well-structured.

5. **Single-day AI attribution:** Both Claude co-authored commits are from 2026-03-16 by the same author (Joosep Jääger), suggesting a single focused AI-assisted session rather than systematic adoption.
