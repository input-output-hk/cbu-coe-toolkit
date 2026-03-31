# AAMM Report: IntersectMBO/cardano-node
> Scan date: 2026-03-31 | Ecosystem: haskell | Schema: v6.0

## Executive Summary

**Top opportunities** (ROI-ordered):
1. Create .aiignore to protect protocol and consensus integration paths — HIGH value, Low effort
2. Create substantive CLAUDE.md for 15-package integration architecture — HIGH value, Low effort
3. Extend mainnet config validation tests via AI-generated permutations — MEDIUM value, Medium effort

**Top recommendations** (ROI-ordered):
1. Create .aiignore for Protocol/, Handlers/, genesis configs, Tracing/Era/ — start_now
2. Write CLAUDE.md covering architecture, builds, dependencies, contribution standards — start_now
3. Extend Test/Cardano/Config/Mainnet.hs with config permutation test cases — start_now

**Risk flags:**
- No risky acceleration (no AI adoption detected)
- Ad-hoc AI usage: NOT triggered (no AI activity at all)

**Quadrant:** High potential, low activity — no AI adoption detected, strong infrastructure for it

---

## Opportunity Map

### #1: opp-node-aiignore
**Create .aiignore to protect protocol implementation paths and consensus integration code**

| Field | Value |
|-------|-------|
| Value | HIGH — node is the consensus integration point; protocol misconfiguration has network-wide impact |
| Effort | Low — file creation with team lead review |
| KB Pattern | cc_aiignore_boundaries |
| Adversarial | ✅ Approved — all paths verified in tree |

**Evidence:** .aiignore absent. Protocol paths: `cardano-node/src/Cardano/Node/Protocol/` (Byron.hs, Cardano.hs, Alonzo.hs, Conway.hs, Shelley.hs, Dijkstra.hs, Checkpoints.hs, Types.hs). Handlers: `Handlers/Shutdown.hs`, `Handlers/TopLevel.hs`. Genesis: `configuration/cardano/mainnet-*.json`.

---

### #2: opp-node-claude-md
**Create a substantive CLAUDE.md covering node integration architecture, nix build system, and security-critical protocol paths**

| Field | Value |
|-------|-------|
| Value | HIGH — 15 packages, complex integration of external ledger/consensus/networking layers |
| Effort | Low — one-time investment, information sources exist |
| KB Pattern | cc_claude_md_context |
| Adversarial | ✅ Approved — trace-dispatcher references removed (does not exist in repo) |

**Evidence:** CLAUDE.md absent. README.md has architecture mermaid diagram. 15 cabal packages. Zero AI config files. Integration architecture documented in README but not in AI-facing format.

---

### #3: opp-node-config-validation
**Use AI to generate test cases for mainnet configuration validation**

| Field | Value |
|-------|-------|
| Value | MEDIUM — config errors affect all node operators |
| Effort | Medium — extends existing test infrastructure |
| KB Pattern | null (novel) |
| Adversarial | ✅ Approved — CI workflow, config files, and test file all verified |

**Evidence:** `configuration/cardano/` has 20 files including mainnet genesis. `check-mainnet-config.yml` CI workflow exists. `Test/Cardano/Config/Mainnet.hs` exists as extension point. `badConfig.yaml`/`goodConfig.yaml` pattern in test data.

---

### Rejected Opportunities (Stage A)

| Opportunity | Rejection Reason |
|-------------|-----------------|
| Expand trace-dispatcher test coverage | **Fabricated evidence** — `trace-dispatcher/` does not exist in repo tree |
| Generate Haddock for undocumented modules | **Half-fabricated** — references non-existent trace-dispatcher |
| Generate onboarding documentation | **Vague scope** — ignores existing external wiki |
| AI-assisted PR descriptions | **Misdiagnosed problem** — template exists, issue is compliance not content |

---

## Risk Surface

| Path | Detection Difficulty | Blast Radius | AI Exposure | Notes |
|------|---------------------|--------------|-------------|-------|
| `cardano-node/src/Cardano/Node/Protocol/` | MEDIUM | HIGH | None | Consensus integration. 8 .hs files. Network-wide impact. |
| `cardano-node/src/Cardano/Node/Handlers/` | MEDIUM | HIGH | None | Shutdown/TopLevel — operational safety. |
| `configuration/cardano/mainnet-*.json` | LOW | HIGH | None | Mainnet genesis/config. CI validates. |
| `cardano-node/src/Cardano/Node/Tracing/` | MEDIUM | MEDIUM | None | High churn. Era-specific tracing. |

No AI exposure detected on any path. All risk surface entries are preventive.

---

## Recommendations

### ✅ #1: rec-node-aiignore — Start now
> Create .aiignore listing Protocol/ handlers, genesis configs, and era-specific tracing paths

| Field | Value |
|-------|-------|
| Effort | Low |
| Impact | HIGH |
| Done when | `.aiignore` exists listing ≥4 paths: Protocol/, Handlers/, mainnet-*, Tracing/Era/ |
| Learning | Review with node team lead. Start with Protocol/ (highest blast radius). |

---

### ✅ #2: rec-node-claude-md — Start now
> Write CLAUDE.md covering 15-package integration architecture, nix build commands, external dependency boundaries

| Field | Value |
|-------|-------|
| Effort | Low |
| Impact | HIGH |
| Done when | `CLAUDE.md` exists with ≥200 words covering 6 sections |
| Learning | Use README.md mermaid diagram. Document what's IN repo vs external deps. Tracing = `Tracing/` + `cardano-tracer/`, NOT `trace-dispatcher`. |

---

### ✅ #3: rec-node-config-tests — Start now
> Extend mainnet config validation tests with AI-generated permutation test cases

| Field | Value |
|-------|-------|
| Effort | Medium |
| Impact | MEDIUM |
| Done when | `Test/Cardano/Config/Mainnet.hs` has ≥5 new test cases (invalid hash, missing fields, type mismatches) |
| Learning | Give Claude Mainnet.hs + config files. Reference badConfig/goodConfig pattern. Focus mainnet first. |

---

## Adoption State

| Opportunity | State | Evidence |
|-------------|-------|----------|
| .aiignore | **Absent** | No AI config, no AI commits, no AI tools |
| CLAUDE.md | **Absent** | File does not exist |
| Config validation | **Absent** | No AI-attributed commits in test files |

> Zero AI adoption detected across the entire repository. No Co-authored-by trailers, no AI bot PRs, no AI config files. This does not confirm absence of AI use — attribution is not universally enforced.

---

## Readiness per Use Case

| Opportunity | Level | Criteria | Notes |
|-------------|-------|----------|-------|
| .aiignore | 🟢 Practiced | 1/2 — paths identifiable (YES), AI tools active (NO) | Proactive: paths exist and are classifiable even without current AI use |
| CLAUDE.md | 🟢 Practiced | 0/1 — AI tool in use (NO) | Preemptive: repo complexity warrants CLAUDE.md before AI adoption |
| Config validation | 🟢 Practiced | 3/3 — configs exist, tests exist, CI validates | Full infrastructure in place |

---

## Evolution

**This is the first v6 assessment for IntersectMBO/cardano-node.** No previous scan data available for delta computation.

---

## Evidence Log

### API Calls
- `GET /repos/IntersectMBO/cardano-node` — metadata
- `GET /repos/.../git/trees/master?recursive=1` — 1527 files
- `GET /repos/.../commits?sha=master&per_page=100` — 100 commits
- `GET /repos/.../pulls?state=closed&sort=updated&direction=desc&per_page=30` — 30 PRs
- `GET raw.githubusercontent.com/.../README.md` — read content
- `GET raw.githubusercontent.com/.../cabal.project` — package list
- `GET raw.githubusercontent.com/.../CONTRIBUTING.md` — contribution guidelines
- `GET raw.githubusercontent.com/.../haskell.yml` — CI config
- `GET raw.githubusercontent.com/.../PULL_REQUEST_TEMPLATE.md` — PR template
- `GET raw.githubusercontent.com/.../Run.hs` — Haddock coverage sample

### Key Files Confirmed Absent
- CLAUDE.md, AGENTS.md, .cursorrules, .mcp.json, .aiignore, ARCHITECTURE.md, copilot-instructions.md, .claude/

### Adversarial Outcomes
- **Stage A:** 3/7 approved, 4 rejected (1 fabricated evidence, 1 half-fabricated, 1 vague scope, 1 misdiagnosed problem)
- **Stage B:** 3/3 approved, 0 rejected. ROI order correct. Types valid.
- **Key correction:** Stage A caught that `trace-dispatcher/` does not exist in the repo tree — churn data from commit diffs referenced files in a package that may have been moved or is external. All trace-dispatcher references removed from approved opportunities.

### Confidence Summary
- Opportunity evidence: HIGH (all paths verified by adversarial agent against tree.json)
- Adoption states: HIGH (objective — zero AI signals confirmed)
- Risk surface: HIGH (paths verified, no AI exposure)
