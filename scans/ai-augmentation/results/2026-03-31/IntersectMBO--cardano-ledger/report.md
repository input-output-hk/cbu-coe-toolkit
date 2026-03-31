# AAMM Report: IntersectMBO/cardano-ledger
> Scan date: 2026-03-31 | Ecosystem: haskell | Schema: v6.0

## Executive Summary

**Top opportunities** (ROI-ordered):
1. Generate Imp test suites for 19 untested Dijkstra STS rules — HIGH value, Low effort
2. Create substantive CLAUDE.md for 28-package ledger architecture — HIGH value, Low effort
3. Create .aiignore to protect consensus/crypto/STS paths — HIGH value, Low effort
4. Generate Haddock docs for undocumented Conway/Dijkstra modules — HIGH value, Low effort
5. Extend Agda conformance testing to Dijkstra era — HIGH value, Medium effort

**Top recommendations** (ROI-ordered):
1. Generate Dijkstra Imp tests starting with SubGov/SubUtxo — start_now
2. Write CLAUDE.md covering architecture, STS, builds, security paths — start_now
3. Create .aiignore for TPraos rules, STS rules, CDDL definitions — start_now
4. Extend conformance testing to Dijkstra via AI-identified divergence points — start_now
5. Audit Dijkstra completeness against NewEra.md checklist — start_now

**Risk flags:**
- No risky acceleration detected (no Active + Undiscovered combinations)
- Ad-hoc AI usage flag: NOT triggered (.claude/skills/ constitutes intentionality signal)

**Quadrant:** High potential, low activity — prime candidate for guided AI adoption

---

## Opportunity Map

### #1: opp-ledger-imp-dijkstra
**Generate Imp test suites for the 19 untested Dijkstra STS rules using Conway Imp patterns as templates**

| Field | Value |
|-------|-------|
| Value | HIGH — Dijkstra is the active development era with 23 Rules modules but only 4 Imp test files |
| Effort | Low — Conway's 13 Imp specs serve as direct templates |
| KB Pattern | hs_imp_test_generation |
| Adversarial | ✅ Approved (Stage A) |

**Evidence:** 23 Rules modules in `eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Rules/` (Bbody, Utxo, SubGov, SubUtxo, Pool, Ledgers, Gov, SubLedger, SubDeleg, SubUtxow, Utxow, SubCert, SubCerts, Certs, Deleg, SubGovCert, SubPool, Mempool, SubLedgers, Utxos, GovCert, Ledger, Cert). Only 4 Imp test files: UtxowSpec.hs, CertSpec.hs, UtxoSpec.hs, LedgerSpec.hs. Conway has 13 covering CertsSpec, EnactSpec, GovSpec, UtxosSpec, UtxowSpec, HardForkSpec, BbodySpec, EpochSpec, DelegSpec, GovCertSpec, RatifySpec, UtxoSpec, LedgerSpec. Dijkstra Rules is #1 churn area (19 changes in last 100 commits).

---

### #2: opp-ledger-claude-md
**Create a substantive CLAUDE.md covering ledger architecture, era boundaries, STS framework, security-critical paths, and build commands**

| Field | Value |
|-------|-------|
| Value | HIGH — 28 packages, 9 eras, nix builds; every AI interaction starts without domain context |
| Effort | Low — one-time investment with compounding returns |
| KB Pattern | cc_claude_md_context |
| Adversarial | ✅ Approved (Stage A) |

**Evidence:** CLAUDE.md absent. 2 AI-attributed commits (b566f359, d20b44d3, 2026-03-16). PR #5670 adds Claude Code skill (`.claude/skills/update-changelogs/`). 28 cabal packages across 9 eras. Complex nix-based build system.

---

### #3: opp-ledger-aiignore
**Create .aiignore to protect consensus rules, cryptographic paths, and era transition logic from unreviewed AI modifications**

| Field | Value |
|-------|-------|
| Value | HIGH — financial ledger with consensus-critical and serialization-critical paths |
| Effort | Low — file creation with security-lead review |
| KB Pattern | cc_aiignore_boundaries |
| Adversarial | ✅ Approved (Stage A) |

**Evidence:** .aiignore absent. Security-critical paths: `libs/cardano-protocol-tpraos/src/Cardano/Protocol/TPraos/Rules/` (OCert, Overlay, Prtcl, Tickn, Updn), `eras/*/impl/src/Cardano/Ledger/*/Rules/` (STS rules all eras), `libs/cardano-ledger-core/`. AI commits already touch CDDL/test files across eras.

---

### #4: opp-ledger-haddock
**Generate Haddock documentation for undocumented exported modules in Conway and Dijkstra eras**

| Field | Value |
|-------|-------|
| Value | HIGH — sub-1% doc comment density in sampled era modules |
| Effort | Low — Haddock infra already deployed via gh-pages.yml |
| KB Pattern | hs_haddock_generation |
| Adversarial | ✅ Approved (Stage A) |

**Evidence:** Sampled Conway files: PParams.hs (7/1343 lines), Genesis.hs (0/111), BlockBody.hs (0/16), Translation.hs (0/190), TxOut.hs (0/81). Haddock deployed via `gh-pages.yml`. Complex type signatures (era-indexed GADTs, type families).

---

### #5: opp-ledger-agda-conformance
**Use AI to identify divergence points between Agda formal spec and Dijkstra Haskell implementation for conformance test expansion**

| Field | Value |
|-------|-------|
| Value | HIGH — formal spec conformance is the gold standard for correctness in financial ledger systems |
| Effort | Medium — requires understanding ExecSpecRule bridge |
| KB Pattern | hs_agda_conformance |
| Adversarial | ✅ Approved (Stage A) |

**Evidence:** `formal-ledger-specifications` pinned in `cabal.project` (tag 6158038b). `libs/cardano-ledger-conformance/` with Conway conformance (14+ ExecSpecRule modules). No Dijkstra-specific conformance test files.

---

### #6: opp-ledger-constrained-gen
**Use AI to write constrained generators for new Dijkstra data types, using existing Conway generators as reference**

| Field | Value |
|-------|-------|
| Value | HIGH — constrained-generators produces test data with inter-field constraints |
| Effort | Medium — requires understanding invariant constraints |
| KB Pattern | hs_constrained_generators |
| Adversarial | ✅ Approved (Stage A) |

**Evidence:** `constrained-generators` pinned in `cabal.project`. AI precedent: commits b566f359 and d20b44d3 (Claude co-authored) added plutusScriptGen. Dijkstra Sub* modules (10 Sub* rule files).

---

### #7: opp-ledger-era-transition-docs
**Use AI to generate Dijkstra era transition documentation from Conway-to-Dijkstra diff and NewEra.md guide**

| Field | Value |
|-------|-------|
| Value | MEDIUM — Dijkstra is actively being developed; transition completeness matters |
| Effort | Low — guide exists, diff is mechanical |
| KB Pattern | hs_era_transition_docs |
| Adversarial | ✅ Approved (Stage A) |

**Evidence:** `docs/NewEra.md` with detailed checklist. `eras/dijkstra/impl/src/Cardano/Ledger/Dijkstra/Translation.hs` exists. Dijkstra is highest-churn era.

---

### #8: opp-ledger-cddl-conformance
**Use AI to identify untested CDDL schema variants in Dijkstra era CddlSpec**

| Field | Value |
|-------|-------|
| Value | MEDIUM — 6 xdescribe'd test groups in Dijkstra CddlSpec |
| Effort | Medium — requires understanding CDDL spec + HuddleSpec generator |
| KB Pattern | hs_cddl_conformance |
| Adversarial | ✅ Approved (Stage A) |

**Evidence:** 8 CDDL files (one per era). AI commits b566f359/d20b44d3 fixed CDDL test generation. 6 xdescribe'd test groups remain disabled in Dijkstra CddlSpec.hs.

---

### Rejected Opportunities (Stage A)

| Opportunity | Rejection Reason |
|-------------|-----------------|
| Corner case discovery in generators | Near-duplicate of constrained-gen (#6). No specific invariant gaps named. |
| State transition debugging | Activity description, not opportunity. "Debug what?" |
| Cross-era PR review | Generic AI review suggestion. PR template already has CDDL checklist. |

---

## Risk Surface

| Path | Detection Difficulty | Blast Radius | AI Exposure | Notes |
|------|---------------------|--------------|-------------|-------|
| `libs/cardano-protocol-tpraos/Rules/` | LOW | HIGH | None | Consensus rules. Heavy testing. No AI commits. |
| `eras/*/Rules/` | MEDIUM | HIGH | None | STS rules — financial state transitions. Property + Imp tests. No AI commits in rule implementations. |
| `libs/cardano-ledger-core/` | MEDIUM | HIGH | None | Core types. High fan-in. No AI commits. |
| `eras/*/cddl/ + HuddleSpec + CddlSpec` | LOW | MEDIUM | **Confirmed** | AI commits b566f359/d20b44d3 modified HuddleSpec across 5 eras. Tests verify conformance. |
| `libs/cardano-ledger-conformance/` | LOW | MEDIUM | None | Conformance bridge. Conway complete. No AI commits. |

**Opportunity-risk intersections** (MEDIUM confidence — inferred):
- opp-ledger-imp-dijkstra → touches `eras/dijkstra/Rules/` (HIGH blast radius). Imp tests are read-only on rules — low risk from test generation itself.
- opp-ledger-aiignore → directly addresses risk surface. Protective measure.
- opp-ledger-agda-conformance → touches `libs/cardano-ledger-conformance/` (MEDIUM blast radius). Conformance tests verify, not modify.

---

## Recommendations

### ✅ Approved (5 of 8)

**#1: rec-ledger-imp-dijkstra** — Start now
> Generate Imp test suites for 19 untested Dijkstra STS rules, starting with SubGov and SubUtxo

| Field | Value |
|-------|-------|
| Effort | Low |
| Impact | HIGH |
| Opportunity | opp-ledger-imp-dijkstra |
| Done when | `eras/dijkstra/impl/testlib/Test/Cardano/Ledger/Dijkstra/Imp/` contains ≥8 *Spec.hs files covering SubGovSpec, SubUtxoSpec, GovSpec, GovCertSpec, CertsSpec, BbodySpec, UtxosSpec, EpochSpec |
| Learning | Pick SubGovSpec first. Give Claude Conway GovSpec.hs as template + Dijkstra SubGov.hs. Ask: "Generate an Imp test suite following Conway patterns." Verify preconditions and postconditions. |

---

**#2: rec-ledger-claude-md** — Start now
> Write CLAUDE.md covering 28-package architecture, era boundaries, STS framework, nix build commands, and security-critical paths

| Field | Value |
|-------|-------|
| Effort | Low |
| Impact | HIGH |
| Opportunity | opp-ledger-claude-md |
| Done when | `CLAUDE.md` exists at repo root with ≥200 words covering 6 sections: multi-era architecture, STS framework, build commands, security-critical paths, testing strategy, coding conventions |
| Learning | Use `.claude/skills/update-changelogs/SKILL.md` as Claude Code integration reference. Start with one paragraph per category. Reference `docs/NewEra.md` for architecture, `CONTRIBUTING.md` for workflow. |

---

**#3: rec-ledger-aiignore** — Start now
> Create .aiignore listing consensus rules (TPraos), core STS rules per era, and serialization-critical CDDL definitions

| Field | Value |
|-------|-------|
| Effort | Low |
| Impact | HIGH |
| Opportunity | opp-ledger-aiignore |
| Done when | `.aiignore` exists listing ≥5 paths: TPraos Rules, era STS Rules, Core, CDDL data, small-steps |
| Learning | Review with security lead. Start with TPraos + STS rules. Mark as review-required, not blocked. |

---

**#4: rec-ledger-agda-conformance** — Start now
> Extend conformance testing to Dijkstra era by using AI to identify spec-implementation divergence in Sub* rules

| Field | Value |
|-------|-------|
| Effort | Medium |
| Impact | HIGH |
| Opportunity | opp-ledger-agda-conformance |
| Done when | `libs/cardano-ledger-conformance/test/Test/Cardano/Ledger/Conformance/` contains `Dijkstra/` with ≥1 conformance module |
| Learning | Study Conway conformance as reference. Give Claude Conway conformance module + Dijkstra rule + Agda spec extract. Ask: "Where does Dijkstra diverge from the formal spec?" |

---

**#5: rec-ledger-era-transition-docs** — Start now
> Use AI to audit Dijkstra era completeness against NewEra.md checklist

| Field | Value |
|-------|-------|
| Effort | Low |
| Impact | MEDIUM |
| Opportunity | opp-ledger-era-transition-docs |
| Done when | `docs/` contains Dijkstra transition status or `docs/NewEra.md` updated with Dijkstra completion checklist |
| Learning | Give Claude `docs/NewEra.md` + Dijkstra file listing + Conway file listing. Ask: "What's missing in Dijkstra?" Review against team roadmap. |

---

### ❌ Rejected (3 of 8)

| Recommendation | Rejection Reason |
|----------------|-----------------|
| Haddock generation | Stage B: Measurable outcome too weak — some modules already pass threshold. Fix: target modules with 0 current comments. |
| Constrained generators | Stage B: Dijkstra Arbitrary.hs already has instances for all 10 Sub* types. Outcome factually incorrect. Type mismatch (start_now invalid for Partial adoption). |
| CDDL expansion | Stage B: Real gap is 6 xdescribe'd groups, not missing branches. Outcome ambiguous. Type mismatch. |

---

## Adoption State

| Opportunity | State | Evidence |
|-------------|-------|----------|
| Imp test generation | **Absent** | No AI-attributed commits in Imp test files |
| CLAUDE.md | **Absent** | File does not exist |
| .aiignore | **Absent** | File does not exist |
| Haddock docs | **Absent** | No AI-attributed docs work |
| Agda conformance | **Absent** | No AI in conformance tests |
| Constrained generators | **Partial** | 2 Claude commits (b566f359, d20b44d3) on related generator work |
| Era transition docs | **Absent** | No AI in docs/transition |
| CDDL conformance | **Partial** | Same 2 commits fixed CDDL test generation |

> Note: Absent means no observable AI attribution — it does not confirm absence of AI use. Attribution is not universally enforced.

---

## Readiness per Use Case

| Opportunity | Level | Criteria Met | Notes |
|-------------|-------|-------------|-------|
| Imp test generation | 🟢 Practiced | 3/3 (100%) | Imp framework exists, Rules modules present, CI builds |
| CLAUDE.md | 🟢 Practiced | 1/1 (100%) | AI tools in active use |
| .aiignore | 🟢 Practiced | 2/2 (100%) | Security paths identifiable, AI tools active |
| Haddock docs | 🟢 Practiced | 3/3 (100%) | Tooling configured, explicit exports, style references exist |
| Agda conformance | 🟢 Practiced | 3/3 (100%) | Formal spec pinned, bridge exists, CI runs conformance |
| Constrained generators | 🟢 Practiced | 3/3 (100%) | Library available, reference generators exist, invariants documented |
| Era transition docs | 🟢 Practiced | 2/2 (100%) | Guide exists, previous transitions as reference |
| CDDL conformance | 🟢 Practiced | 3/3 (100%) | CDDL files exist, conformance tests exist, serialization modules identifiable |

All opportunities at Practiced readiness level. No Risky Acceleration flags (no Active + Undiscovered combinations).

---

## Evolution

**This is the first v6 assessment for IntersectMBO/cardano-ledger.**

### v5 Historical Context (not computed as delta)

A v5 assessment was completed on 2026-03-28 (agent: claude-sonnet-4-6):
- **v5 Readiness:** HIGH (5/5 pillars at Practiced)
- **v5 Adoption:** MEDIUM (2/5 zones at Exploring)
- **v5 Quadrant:** Growing

v6 shifts from pillar-based readiness to per-use-case readiness with KB-driven criteria. The v5 "HIGH readiness" assessment measured general engineering quality; v6 assesses readiness per specific AI opportunity. Both assessments agree on the fundamental finding: the repo is well-structured for AI adoption but adoption is minimal.

A v6 learning scan was completed on 2026-03-30, producing KB proposals that informed this scoring scan's opportunity matching.

---

## Evidence Log

### API Calls
- `GET /repos/IntersectMBO/cardano-ledger` — metadata (size, stars, branch, archived status)
- `GET /repos/IntersectMBO/cardano-ledger/git/trees/master?recursive=1` — 2328 files
- `GET /repos/IntersectMBO/cardano-ledger/commits?sha=master&per_page=100` — 100 commits
- `GET /repos/IntersectMBO/cardano-ledger/pulls?state=closed&sort=updated&direction=desc&per_page=30` — 30 PRs
- `GET /repos/IntersectMBO/cardano-ledger/pulls/{N}/reviews` — 5 PRs sampled

### Key Files Read
- README.md, CONTRIBUTING.md, CODEOWNERS, .github/PULL_REQUEST_TEMPLATE.md
- .github/workflows/haskell.yml, bench.yml
- cabal.project (first 80 lines — packages, source-repository-packages)
- docs/NewEra.md (first 30 lines)
- flake.nix (existence confirmed)

### Files Confirmed Absent
- CLAUDE.md, AGENTS.md, .cursorrules, .mcp.json, .aiignore, ARCHITECTURE.md, copilot-instructions.md

### Git History Analysis
- High-churn: Dijkstra Rules (#1, 19 changes), Dijkstra impl (#2, 13), Conway Rules (#3, 13)
- AI attribution: 2 commits with "Co-Authored-By: Claude Opus 4.6" (b566f359, d20b44d3)
- Commit frequency: active daily, ~4-6 commits/day average
- Last commit: 2026-03-30

### Adversarial Outcomes
- **Stage A:** 8/11 opportunities approved. 3 rejected (corner-cases=duplicate, debug-sts=generic, cross-era-review=generic)
- **Stage B:** 5/8 recommendations approved. 3 rejected (haddock=measurability, constrained-gen=factually incorrect, cddl-expand=ambiguous)
- Stage A corrected Haddock density (Genesis.hs: 0 comments, not 1 as initially claimed)
- Stage B discovered Dijkstra Arbitrary.hs already has Sub* instances (314 lines, 10+ types)

### Confidence Summary
- Opportunity evidence: HIGH (all file paths and commit SHAs verified by adversarial agents)
- Adoption states: HIGH (objective — attribution presence/absence confirmed)
- Readiness criteria: HIGH for Objective checks, MEDIUM for Semi-objective (explicit exports, style reference assessment)
- Risk surface AI exposure: HIGH for confirmed paths, MEDIUM for inferred opportunity intersections
