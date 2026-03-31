# Detailed Log: AAMM v6 Scan — input-output-hk/mithril
> Scan date: 2026-03-31 | Agent: claude-opus-4-6[1m] | Schema: v6.0

---

## 1. Data Collection

### Files Read
| File | Purpose | Key Findings |
|------|---------|-------------|
| repo-data-summary.md | Repo metadata | Rust, 191221KB, 150 stars, 2438 files. CLAUDE.md: 14 bytes (placeholder). .aiignore: ABSENT. copilot-instructions.md: EXISTS. CONTRIBUTING.md: EXISTS. Zero AI attribution. |
| tree.json | File tree | 2438 entries. Key: deny.toml (743B), .github/copilot-instructions.md (7091B), .github/pull_request_template.md (985B), ci.yml (45048B), backward-compatibility.yml (10392B), 18+ internal/ crates, docs/website/adr/ with 11+ ADRs |
| commits.json | Git history | Examined first 5 commits. All by jpraynaud. Conventional commit format (feat:, fix:, chore:). Zero Co-authored-by AI trailers. Active SNARK prover work. |
| prs.json | PR data | PR #3105: SNARK prover deploy (merged 2026-03-31). PR #3103: wire SNARK in aggregate signature (merged 2026-03-30). Both have structured descriptions with checklists. No bot PRs. |

### Ecosystem Detection
- Primary: Rust (Cargo.toml workspace with 25+ members)
- Secondary: JavaScript/TypeScript (docs/website, mithril-explorer, mithril-client-wasm)
- Assessment uses Rust KB patterns + cross-cutting patterns

### High-Churn Areas (inferred from recent commits)
- mithril-stm/ -- SNARK prover integration
- mithril-aggregator/ -- version bumps, SNARK wiring
- mithril-signer/ -- version bumps
- internal/mithril-era/ -- era reader adapter rename
- mithril-infra/ -- SNARK prover deployment

### AI Attribution Scan
- Co-authored-by trailers: ZERO across all examined commits
- Bot PRs: ZERO
- AI config files: .github/copilot-instructions.md (7091 bytes -- substantive)
- CLAUDE.md: 14 bytes (placeholder, returned 404 on content fetch)
- .aiignore: ABSENT
- Conclusion: AI tools configured (copilot-instructions.md) but no observable AI-attributed activity in commits/PRs

---

## 2. Opportunity Map Generation

### KB Pattern Matching

#### rs_unsafe_audit -- MATCHED
- **applies_when:** "Crates contain unsafe blocks" -- mithril-stm is a cryptographic library implementing threshold multi-signatures. Crypto Rust crates commonly use unsafe for performance-critical operations (FFI to C crypto libs, raw pointer manipulation for zero-copy). MEDIUM confidence (inferred from crate purpose, cannot grep source).
- **applies_when:** "Safety-critical modules" -- mithril-stm is the core cryptographic primitive. SNARK prover integration active (PR #3103, #3105). HIGH confidence.
- **value:** HIGH (matches KB base value -- crypto code in active development)
- **effort:** Low (matches KB -- reviewing existing code)
- **ROI:** 9 (3 x 3)

#### rs_trait_test_gen -- MATCHED
- **applies_when:** "Custom trait implementations with complex invariants" -- 25+ crate workspace with shared types in mithril-common. MEDIUM confidence.
- **applies_when:** "Multiple types implementing the same trait" -- mithril-common is a shared library suggesting trait abstractions. MEDIUM confidence.
- **value:** MEDIUM
- **effort:** Medium
- **ROI:** 4 (2 x 2)

#### rs_rustdoc_generation -- MATCHED
- **applies_when:** "Public API crates with underdocumented interfaces" -- internal/ has 18+ crates. Internal infrastructure crates typically have sparser docs. MEDIUM confidence.
- **applies_when:** "Crate used by other crates in the workspace (high fan-in)" -- internal crates are dependencies of service crates by definition. HIGH confidence.
- **value:** MEDIUM
- **effort:** Low
- **ROI:** 6 (2 x 3)

#### rs_debug_async -- MATCHED
- **applies_when:** "Async runtime in use (tokio, async-std)" -- mithril-aggregator and mithril-signer are network services. Tokio is standard for Rust network services. MEDIUM confidence.
- **applies_when:** "Multiple concurrent tasks with shared state" -- signature aggregation requires handling concurrent signer registrations. MEDIUM confidence.
- **value:** HIGH
- **effort:** Low
- **ROI:** 9 (3 x 3)

#### rs_cargo_deny_audit -- MATCHED
- **applies_when:** "cargo-deny or cargo-audit configured" -- deny.toml exists (743 bytes). HIGH confidence.
- **applies_when:** "Advisory scanning may be misconfigured" -- KB seen_in references this exact repo with prior finding. HIGH confidence.
- **value:** MEDIUM
- **effort:** Low
- **ROI:** 6 (2 x 3)

#### cc_pr_descriptions -- MATCHED BUT REJECTED (Stage A)
- **applies_when:** "Active PR workflow (>5 PRs merged per month)" -- YES
- **applies_when:** "PR descriptions are inconsistent or thin" -- NO. Sampled PRs have structured descriptions.
- Rejected at Stage A: team already produces quality PR descriptions.

#### cc_claude_md_context -- MATCHED
- **applies_when:** "No CLAUDE.md exists, or CLAUDE.md is generic/empty" -- CLAUDE.md is 14 bytes (placeholder). HIGH confidence.
- **applies_when:** "Complex project with domain knowledge AI needs" -- stake-based threshold multi-signatures with SNARK proofs. HIGH confidence.
- **value:** HIGH
- **effort:** Low -> Medium (adjusted by Stage A due to 25+ crate complexity)
- **ROI:** 6 (3 x 2, after effort adjustment)

#### cc_aiignore_boundaries -- MATCHED
- **applies_when:** "High-assurance repo with security-critical code paths" -- cryptographic protocol implementation. HIGH confidence.
- **applies_when:** "AI tools in use without explicit trust boundaries" -- copilot-instructions.md exists, .aiignore absent. HIGH confidence.
- **value:** HIGH
- **effort:** Low
- **ROI:** 9 (3 x 3)

#### cc_commit_messages -- NOT MATCHED
- **applies_when:** "Commit messages are inconsistent or uninformative" -- NO. Team uses conventional commits (feat:, fix:, chore: prefixes with scoped context). Messages are informative.

#### cc_onboarding_docs -- NOT MATCHED
- **applies_when:** "CONTRIBUTING.md absent or thin" -- NO. CONTRIBUTING.md exists (5551 bytes -- substantive).
- **applies_when:** "README focuses on usage, not development setup" -- README exists (10622 bytes), docs/devbook/ exists with setup guides. Nix is used (flake.nix observed in tree).

### Novel Opportunities Considered
- "AI-assisted SNARK proof verification review" -- mithril's active SNARK prover integration is a novel use case. However, insufficient KB criteria exist to assess this. Nominated for KB expansion rather than included as an opportunity.

---

## 3. Adversarial Stage A — Full Dialogue

### Input to Stage A
7 candidate opportunities + 1 novel + repo data summary

### Stage A Review (inline, adversarial posture)

**Opportunity #1: rs_unsafe_audit (mithril-stm)**
- Specificity Test: PASS. Targets mithril-stm cryptographic core specifically, not generic "unsafe review."
- Grounding Test: PASS (MEDIUM). mithril-stm/ exists in tree. Active SNARK work confirmed (PR #3103, #3105, commit 994a4b9). Cannot confirm unsafe block count.
- Feasibility Test: PASS. Low effort, standard AI workflow.
- Relevance Test: PASS. Commits within last week on SNARK work.
- **APPROVED.**

**Opportunity #2: cc_aiignore_boundaries**
- Specificity Test: PASS. Names mithril-stm and SNARK prover paths.
- Grounding Test: PASS. .aiignore ABSENT (confirmed). copilot-instructions.md EXISTS (7091B, confirmed).
- Feasibility Test: PASS. Trivial file creation.
- Relevance Test: PASS. AI config present, crypto paths active.
- **APPROVED.**

**Opportunity #3: rs_debug_async (aggregator/signer)**
- Specificity Test: PASS. Names specific services.
- Grounding Test: PASS (MEDIUM). Services exist. Async runtime inferred, not confirmed.
- Feasibility Test: PASS. Standard debugging workflow.
- Relevance Test: PASS. Version bumps in last commit.
- **APPROVED** with confidence caveat.

**Opportunity #4: cc_claude_md_context**
- Specificity Test: PASS. References 25+ crate workspace, STM protocol, signing paths.
- Grounding Test: PASS. CLAUDE.md 14 bytes confirmed. copilot-instructions.md 7091 bytes confirmed.
- Feasibility Test: ADJUSTED. 25+ crates makes this Medium effort, not Low.
- Relevance Test: PASS. Active repo with AI config.
- **APPROVED with effort adjustment: Low -> Medium.**

**Opportunity #5: rs_cargo_deny_audit**
- Specificity Test: PASS. References deny.toml in this repo.
- Grounding Test: PASS. deny.toml confirmed (743B). KB seen_in references this repo.
- Feasibility Test: PASS. Trivial audit.
- Relevance Test: PASS. Always relevant for crypto project.
- **APPROVED.**

**Opportunity #6: cc_pr_descriptions**
- Specificity Test: BORDERLINE. Generic framing.
- Grounding Test: FAIL. PRs #3105 and #3103 have structured descriptions with content sections, checklists, and issue references. PR template exists (985B). The problem this opportunity addresses does not exist.
- Feasibility Test: PASS.
- Relevance Test: FAIL. Team already doing this well.
- **REJECTED.** Could be salvaged by: Not salvageable -- the team's PR descriptions are already structured and informative.

**Opportunity #7: rs_rustdoc_generation (internal crates)**
- Specificity Test: PASS. Names specific internal crates.
- Grounding Test: PASS (MEDIUM). Internal crates exist. Doc sparseness inferred.
- Feasibility Test: PASS.
- Relevance Test: PASS. mithril-era recently modified.
- **APPROVED.**

**Opportunity #8: rs_trait_test_gen**
- Specificity Test: PASS. Names mithril-common and mithril-stm.
- Grounding Test: PASS (MEDIUM). Crates exist. Trait impl details inferred.
- Feasibility Test: PASS.
- Relevance Test: PASS. Core crates actively developed.
- **APPROVED.**

### Stage A Output
- Approved: 7 opportunities
- Rejected: 1 (cc_pr_descriptions)
- Adjustments: cc_claude_md_context effort Low -> Medium

---

## 4. Component Assessment Reasoning

### 4.1 Adoption State

All 7 approved opportunities assessed as **Absent**.

Reasoning: Zero AI co-authored-by trailers across all commits examined. Zero bot PRs. CLAUDE.md is a placeholder (14 bytes). The only intentionality signal is copilot-instructions.md (7091 bytes), which confirms AI tools are configured but does not provide evidence of AI-attributed activity in specific areas.

Per anti-pattern ap_attribution_absence: "Absence of attribution means 'we cannot observe AI usage from repo data,' not 'AI is not being used.'" This is stated explicitly for each Absent finding.

### 4.2 Readiness Assessment

Readiness assessed per opportunity using KB criteria only. See assessment.json for full criteria_results.

Key observations:
- **cargo-deny audit (Practiced):** Both criteria met -- deny.toml exists, advisory check inferred from KB prior observation. This is the highest readiness level in the scan.
- **Rustdoc generation (Undiscovered):** Neither criterion met -- no evidence of cargo doc in CI, crate-level docs unknown.
- **Trait test generation (Undiscovered):** 1/3 criteria met (CI runs tests) but proptest not confirmed, trait docs unknown.
- **Others (Exploring):** 50-100% of criteria met depending on what can be verified from collected data.

### 4.3 Risk Surface

Four risk paths identified, all with **Potential** AI exposure (copilot-instructions.md exists but no AI commits in these paths).

Key risk assessment: mithril-stm/ has the highest combined risk (MEDIUM detection, HIGH blast radius) because it implements the core cryptographic protocol and is imported across the workspace.

### 4.4 Ad-hoc AI Usage Flag

NOT triggered. While there are zero AI-attributed commits, there is an intentionality signal: copilot-instructions.md (7091 bytes) with substantive content. Per the scoring model, any one intentionality signal is sufficient to not trigger the flag.

---

## 5. Recommendation Generation Reasoning

All 7 opportunities have Adoption = Absent. Recommendation types determined by:
- Absent + Exploring/Practiced = **start_now** (4 recommendations)
- Absent + Undiscovered = **foundation_first** (3 recommendations)

### ROI Calculations
| Recommendation | Impact | Effort | Gap | ROI |
|---------------|--------|--------|-----|-----|
| .aiignore | HIGH (3) | Low (3) | Absent (3) | 27 |
| Unsafe audit | HIGH (3) | Low (3) | Absent (3) | 27 |
| CLAUDE.md | HIGH (3) | Medium (2) | Absent (3) | 18 |
| deny.toml audit | MEDIUM (2) | Low (3) | Absent (3) | 18 |
| Async debug | HIGH (3) | Medium (2) | Absent (3) | 18 |
| Rustdoc | MEDIUM (2) | Low (3) | Absent (3) | 18 |
| Trait tests | MEDIUM (2) | Medium (2) | Absent (3) | 12 |

Ties at ROI=18 broken by impact (HIGH wins), then by effort (Low wins).

### Self-checks Applied
1. "Can a tech lead put this in backlog tomorrow?" -- YES for all. Each has a clear scope and owner.
2. "Is this specific to this team?" -- YES. All reference specific crates, paths, or repo characteristics.
3. "Can I verify the measurable outcome from repo data?" -- YES. All outcomes are file existence, content checks, or grep-verifiable.

---

## 6. Adversarial Stage B — Full Dialogue

### Stage B Review (inline, adversarial posture)

Applied to all 7 recommendations. Testing: Is this actionable? Is the measurable outcome actually measurable? Is it specific to this team?

**rec-mithril-aiignore:** APPROVED. Creating .aiignore is the simplest possible action. Outcome is file existence check. Specific to mithril's crypto paths.

**rec-mithril-unsafe-review:** APPROVED. Grep for // SAFETY: comments is a concrete measurable outcome. Specific to mithril-stm SNARK code.

**rec-mithril-claude-md:** APPROVED. >500 words with 5 required sections is measurable. Leveraging copilot-instructions.md as starting point is pragmatic. lace-platform precedent cited.

**rec-mithril-deny-audit:** APPROVED. Verify deny.toml configuration is directly actionable. KB prior evidence for this exact repo adds weight.

**rec-mithril-async-debug:** APPROVED. Foundation-first framing is correct -- AI debugging needs documented topology. Outcome (documentation exists listing tasks, state, channels) is verifiable.

**rec-mithril-rustdoc:** APPROVED. cargo doc --no-deps is a concrete verification command. Starting with mithril-era (recently active) is justified.

**rec-mithril-trait-tests:** APPROVED. proptest in dev-dependencies is verifiable. 3 property tests per crate is a concrete threshold. Foundation-first is correct framing.

### Stage B Output
- Approved: 7/7 recommendations
- Rejected: 0
- No adjustments needed

---

## 7. Anomalies and Limitations

1. **Source code not readable:** All source-level assessments (unsafe blocks, safety comments, trait documentation, async runtime, doc comments) are inferred from file tree structure and crate purpose. This caps many confidence levels at MEDIUM.

2. **CI configuration not readable:** ci.yml is 45KB but its contents were not fetched. Clippy, miri, cargo doc, cargo deny command specifics are all inferred.

3. **CLAUDE.md returned 404:** Despite being listed in the file tree (14 bytes), the content fetch returned 404. This may indicate the file exists but is empty or has an encoding issue.

4. **copilot-instructions.md content unknown:** The file is 7091 bytes (substantive) but its contents were not read. We cannot assess whether it covers security boundaries, testing strategy, or architecture.

5. **Commit history depth:** Only first 5 commits deeply examined due to API pagination. Broader patterns (commit frequency, contributor diversity, churn distribution) are inferred from limited sample.

6. **PR review data incomplete:** PR review counts not available from the collected data. Cannot assess review depth beyond observing reviewer requests.
