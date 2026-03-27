# AAMM v5 Assessment Report: IntersectMBO/cardano-ledger

**Date:** 2026-03-27
**Ecosystem:** Haskell
**Agent:** claude-opus-4-6[1m]
**Schema:** v5.0 | Criteria: v5.0.0

---

## 1. SUMMARY

| Dimension | Result |
|-----------|--------|
| **Repo** | IntersectMBO/cardano-ledger |
| **Description** | Formal specifications, executable models, and implementations of the Cardano Ledger |
| **Readiness** | **HIGH** (5/5 pillars at Practiced) |
| **Adoption** | **MEDIUM** (1/5 zones at Exploring, 4/5 Undiscovered) |
| **Quadrant** | **Growing** |

**What this means:** cardano-ledger is exceptionally well-structured for AI augmentation but has barely begun adopting AI tools. The infrastructure is ready -- strong types, modular architecture, comprehensive tests, clear workflows. The opportunity cost of not providing AI context (CLAUDE.md, .aiignore) is high because contributors are already using Claude (2 co-authored commits detected) without project-specific guidance.

---

## 2. TOP RECOMMENDATIONS (ROI-ordered)

### #1: Add .aiignore for security-critical paths
- **Effort:** Low (days) | **Impact:** HIGH
- **What:** Create .aiignore listing crypto modules, formal spec implementations, consensus-critical code (rewards, delegation, monetary policy), and key derivation paths.
- **Why:** Financial ledger with zero AI trust boundaries. Even minimal AI adoption today creates risk that grows as adoption increases.
- **Source:** KB: `.aiignore on critical paths`
- **Measurable:** `.aiignore` exists with >=5 critical path entries

### #2: Add CLAUDE.md with ledger-specific context
- **Effort:** Low (days) | **Impact:** HIGH
- **What:** Create CLAUDE.md covering multi-era architecture, CDDL requirements, formal spec alignment, QuickCheck patterns, build commands, and security-critical paths.
- **Why:** 2 Claude co-authored commits exist -- contributors use AI without project context. Domain-aware AI assistance requires domain context.
- **Source:** KB: `CLAUDE.md content-category coverage`
- **Measurable:** CLAUDE.md exists with >=6 sections

### #3: Add Haskell-specific vulnerability scanning to CI
- **Effort:** Low (days) | **Impact:** HIGH
- **What:** Add `cabal audit` step to CI for Haskell dependency scanning. Dependabot is already active for Python deps in doc/ (confirmed via merged dependabot[bot] PR #5677, 2026-03-24), but no Haskell-specific CVE scanning detected.
- **Why:** No CVE scanning detected. Nix flake.lock provides hash pinning but not vulnerability awareness. Financial system dependency risk.
- **Measurable:** dependabot.yml or cabal audit in CI

### #4: Add hpc coverage reporting
- **Effort:** Medium (weeks) | **Impact:** MEDIUM
- **What:** Enable Haskell Program Coverage in CI. Start with visibility, then add threshold.
- **Measurable:** `--enable-coverage` in CI + report artifact

### #5: Improve Haddock documentation to >50%
- **Effort:** Medium (weeks) | **Impact:** MEDIUM
- **What:** Add doc comments to exported functions/types in libs/ packages. Target 55%.
- **Source:** KB: `Haddock documentation coverage`
- **Measurable:** Haddock report >=50% on public API modules

---

## 3. RISK FLAGS

| Risk | Severity | Detail |
|------|----------|--------|
| **Missing trust boundaries** | HIGH | High-assurance financial ledger with no .aiignore or AI security config. Crypto, consensus, and monetary policy code has no AI access restrictions. |
| **No Haskell vulnerability scanning** | MEDIUM | Dependabot active for Python deps in doc/, but no Haskell-specific CVE scanning (cabal audit). Nix hash pinning does not detect known vulnerabilities. |

**Not flagged:**
- Unreviewed PRs: 29 recently merged PRs with CI checks and CODEOWNERS -- review patterns appear healthy
- Stale CI: CI is active (nightly schedule, recent PRs)

---

## 4. SKILL TREE

### Readiness (HIGH -- 5/5 pillars at Practiced)

```
Structure    [=====] 5/5  Practiced   HIGH confidence
Clarity      [==== ] 4/5  Practiced   HIGH confidence
Purpose      [==== ] 4/5  Practiced   MEDIUM confidence
Workflow     [==== ] 4/5  Practiced   HIGH confidence
Safety Net   [==== ] 4/5  Practiced   HIGH confidence
```

**Cross-pillar note:** All 5 pillars scoring Practiced is uncommon. Structure scores are typically high for mature repos (linter, formatter, CI are standard). Purpose at 4/5 is above industry average -- 9 ADRs and structured PR templates are notable. The only gaps are Haddock coverage (Clarity), product context (Purpose), trust boundaries (Workflow), and coverage tooling (Safety Net).

### Adoption (LOW -- 1 zone Exploring, 4 Undiscovered)

```
Code                    [=   ] 1/3  Exploring      HIGH confidence
Testing                 [    ] 0/3  Undiscovered   HIGH confidence
Security                [    ] 0/3  Undiscovered   HIGH confidence
Product & Delivery      [    ] 0/3  Undiscovered   HIGH confidence
Governance & Architecture [  ] 0/3  Undiscovered   HIGH confidence
```

**Note:** HIGH confidence on Undiscovered means "I am confident there is no detectable AI activity" -- not "I am confident they don't use AI." Industry attribution limitations apply: contributors may use AI tools without co-authored-by tags.

---

## 5. FINDINGS

### Structure Findings
- **28 cabal packages** organized by ledger era (Byron, Shelley, Allegra, Mary, Alonzo, Babbage, Conway) plus shared libraries. Each era has its own impl/ and testlib/ packages. KB pattern `cabal multi-package as module boundary signal` validated.
- **Nix-based reproducibility** via flake.nix + flake.lock provides hermetic builds stronger than lockfile-only approaches. The entire toolchain (GHC, hlint, fourmolu, system deps) is pinned.
- **Multi-GHC matrix** (9.6 through 9.14) provides forward-compatibility testing -- unusually thorough.
- **Nix-wrapped tooling detection:** hlint and fourmolu run via `nix develop --command`, not as standalone CI steps. KB pattern `Nix-wrapped CI hides tools from direct grep` applied -- scanner checks flake.nix patterns, not workflow YAML tool names.

### Clarity Findings
- **Haddock coverage at 45.8%** -- 4.2 points below the 50% threshold. KB tracks this. Coverage may be higher on public API surfaces vs. implementation modules, but aggregate measurement does not distinguish.
- **CDDL schemas** per era (.cddl files) serve as machine-readable interface contracts defining binary wire format. CddlSpec.hs verifies conformance -- this is a strong clarity signal specific to protocol repos.
- **Haskell type system** partially compensates for doc comment gaps: type signatures on exported functions are more precise contracts than doc comments in most languages.

### Purpose Findings
- **9 ADRs** (docs/adr/001-009) indicate systematic architectural decision recording. Above industry average.
- **P3 (product context) gap:** No product requirements docs. The formal mathematical specifications ARE the product definition for a ledger implementation. This is an inherent tension with the P3 criterion for formal-spec repos. **Flagged for CoE lead: consider domain-specific P3 interpretation for protocol repos.**
- **PR template** includes domain-specific checks (CDDL conformance, changelog) beyond generic DoD.

### Workflow Findings
- **Trunk-based development** documented in CONTRIBUTING.md -- PRs merge directly to master.
- **CODEOWNERS** separates ledger maintainers from Nix/DevX team -- good ownership boundaries.
- **3 issue templates** including a dedicated release-packages template indicating formalized release process.
- **W5 (trust boundaries) is the critical gap.** High-assurance financial system with no AI guardrails documented.

### Safety Net Findings
- **Property-based testing** via QuickCheck is a standout strength. testlib/ directories with Arbitrary instances per era enable state-space exploration. KB pattern `QuickCheck property tests for state machine correctness` validated.
- **CDDL conformance tests** (CddlSpec.hs) verify binary serialization -- domain-specific verification.
- **No coverage tooling** (SN5) is the gap. hpc (Haskell Program Coverage) would provide visibility. Note: property-based testing provides correctness assurance that line coverage tools may underrepresent.

### Adoption Findings
- **2 Claude Opus co-authored commits** out of 100 recent commits (2%) = individual experimentation, not systematic adoption.
- **No AI config** means contributors using AI tools get generic assistance without era architecture, CDDL requirements, or formal spec alignment context.
- **All non-Code adoption zones are Undiscovered** with HIGH confidence. This is expected -- AI adoption typically starts with Code and expands outward.

---

## 6. CROSS-REPO INSIGHTS

### Applicable KB Patterns
| Pattern | Source | Applicability |
|---------|--------|--------------|
| Nix-wrapped CI hides tools from direct grep | KB: ecosystems/haskell.md | Applied to S4 (hlint detection) |
| QuickCheck property tests for state machine correctness | KB: ecosystems/haskell.md | Validated -- testlib/ Arbitrary instances |
| Haddock documentation coverage | KB: ecosystems/haskell.md | C2 gap -- 45.8% coverage |
| cabal multi-package as module boundary signal | KB: ecosystems/haskell.md | S1 -- 28 packages |
| HLint + fourmolu as standard tooling | KB: ecosystems/haskell.md | S4/S5 -- both present |
| CLAUDE.md content-category coverage | KB: cross-cutting.md | Recommendation #2 |
| .aiignore on critical paths | KB: cross-cutting.md | Recommendation #1, risk flag |
| Undocumented workflow = AI cannot follow it | KB: cross-cutting.md | W5 gap |

### KB Nominations (new patterns from this scan)
1. **CDDL conformance testing as safety net pattern:** CddlSpec.hs verifying binary serialization against .cddl schema files. Domain-specific testing pattern for protocol repos.
2. **Formal spec repos and P3 criterion:** When the product context IS the formal specification. P3 may need domain-specific interpretation.
3. **Multi-GHC matrix testing:** Forward-compatibility testing across compiler versions as a build robustness pattern.

---

## 7. EVOLUTION

**First assessment.** No previous scan exists for comparison.

Baseline established: High readiness (5 Practiced pillars), Low adoption (1 Exploring zone). Fertile Ground quadrant.

**Next scan expectations:**
- If recommendations #1 and #2 are implemented: W5 could flip to YES (Workflow stays Practiced), Code zone could reach Practiced (AC1 met).
- If no changes: expect same assessment. The 2 Claude co-authored commits may grow or shrink organically.

---

## 8. EVIDENCE LOG

### Files Referenced (from collected data)
| File | Used For | Finding |
|------|----------|---------|
| README.md | C3, P1, P5 | ~500 words, era descriptions, repo structure section |
| CONTRIBUTING.md | W1 | ~300 words, trunk-based dev, roles, releasing, GHC transition |
| CODEOWNERS | W4 | @cardano-ledger-maintainers + @core-tech-devx |
| cabal.project | S1 | 28+ packages across eras/ and libs/ |
| fourmolu.yaml | S5 | Formatter config present |
| flake.lock | S2 | Nix lockfile for reproducible builds |
| .github/PULL_REQUEST_TEMPLATE.md | W2, P4 | Structured checklist with CDDL conformance |
| .github/ISSUE_TEMPLATE/ | W3 | 3 templates (config, feature, release) |
| .github/workflows/haskell.yml | S3, SN3, SN4 | Multi-GHC matrix, cabal build+test, PR+master+nightly triggers |
| docs/adr/ (001-009) | P2 | 9 ADRs present |
| eras/*/impl/test/ | SN1 | Test directories per era |
| testlib/ directories | SN2 | QuickCheck Arbitrary instances |
| *.cddl files | C4 | Schema definitions per era |

### Files NOT Found (negative evidence)
| File | Criterion | Impact |
|------|-----------|--------|
| CLAUDE.md | AC1 | No AI config |
| .aiignore | W5, AS1 | No trust boundaries |
| .hlint.yaml | S4 | Hlint inferred via Nix (KB pattern) |
| ARCHITECTURE.md | P1 | README section used instead |
| Coverage config (hpc/codecov) | SN5 | No coverage tooling |
| dependabot.yml / security scanning | Risk flag | No vuln scanning |
| PRD/FRD/requirements docs | P3 | No product context docs |

### Rubric Reasoning Summary
- **Structure 5/5:** All infrastructure in place. S4 (hlint) relies on KB-validated Nix pattern.
- **Clarity 4/5:** C2 (Haddock) at 45.8% misses 50% threshold by 4.2 points.
- **Purpose 4/5:** P3 (product context) absent. Formal specs exist but are not product context per criterion definition.
- **Workflow 4/5:** W5 (trust boundaries) absent. Critical gap for high-assurance repo.
- **Safety Net 4/5:** SN5 (coverage tooling) absent. Strong test suite without visibility metrics.
- **Code 1/3:** AC2 only -- 2 Claude co-authored commits. Individual experimentation.
- **Testing through Governance 0/3:** No detectable AI activity in any zone.

### Confidence Assessment
| Pillar/Zone | Confidence | Rationale |
|-------------|-----------|-----------|
| Structure | HIGH | All criteria verified via file existence (objective) |
| Clarity | HIGH | C2 based on KB-validated measurement; C1 auto-pass |
| Purpose | MEDIUM | P1 (README architecture section) is semi-objective judgment; P3 interpretation debatable for formal-spec repos |
| Workflow | HIGH | All criteria verified via file existence (objective) |
| Safety Net | HIGH | SN4 capped at MEDIUM per rubric (branch protection unverifiable) but pillar overall HIGH |
| Code | HIGH | Objective detection: file search + commit grep |
| Testing-Governance | HIGH | Confident absence of detectable artifacts |

### Adversarial Review Results
All 7 recommendations approved. No rejections. Key adversarial challenges:
- Rec #3 (hpc): Challenged on whether property-based testing renders line coverage less useful. Approved with caveat that team should interpret hpc results carefully.
- Rec #5 (Haddock): Challenged on effort estimate. Confirmed medium -- requires domain knowledge for meaningful doc comments.
- Rec #7 (product context): Challenged on P3 criterion fit for formal-spec repos. Approved with flag for CoE lead.
