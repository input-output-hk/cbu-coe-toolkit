# AAMM Report: input-output-hk/mithril
> Scan date: 2026-03-31 | Ecosystem: rust | Schema: v6.0

## Executive Summary

**Top opportunities** (ROI-ordered):
1. AI-assisted review of unsafe blocks in mithril-stm cryptographic multi-signature implementation -- HIGH value, Low effort
2. Create .aiignore trust boundaries for mithril-stm and SNARK prover paths -- HIGH value, Low effort
3. AI-assisted debugging of async concurrency in mithril-aggregator and mithril-signer -- HIGH value, Low effort
4. Write substantive CLAUDE.md covering 25+ crate workspace architecture -- HIGH value, Medium effort
5. Audit cargo-deny configuration for advisory scanning completeness -- MEDIUM value, Low effort

**Top recommendations** (ROI-ordered):
1. Create .aiignore listing mithril-stm/ and mithril-signer/ as AI-excluded zones -- start_now
2. Run AI-assisted unsafe code audit on mithril-stm focusing on SNARK-related unsafe blocks -- start_now
3. Write CLAUDE.md covering workspace architecture, STM protocol, and security-critical paths -- start_now
4. AI-audit deny.toml to confirm advisory scanning runs -- start_now

**Risk flags:**
- No Risky Acceleration flags (no Active + Undiscovered combinations)
- Ad-hoc AI usage flag: NOT triggered (zero AI-attributed commits; copilot-instructions.md shows intentionality)

**Quadrant:** High Potential, Low Activity -- Untapped

ROI ordering is a heuristic based on estimated value and effort -- treat as suggested priority, not certainty.

---

## Opportunity Map

### #1: AI-assisted review of unsafe blocks in mithril-stm (ROI rank 1)
- **ID:** opp-mithril-rs_unsafe_audit
- **Value:** HIGH -- unsafe blocks in cryptographic STM code require expert review; AI can flag missing safety invariant documentation
- **Effort:** Low -- reading and reviewing existing code
- **KB pattern:** rs_unsafe_audit
- **Evidence:** mithril-stm/ is the core STM crypto library. Active SNARK prover work: PR #3105 (deploy SNARK prover, merged 2026-03-31), PR #3103 (wire SNARK proof in aggregate signature, merged 2026-03-30). Commit 994a4b9 references "SNARK AVK" in protocol message creation.
- **Seen in:** (none previously)

### #2: Create .aiignore trust boundaries (ROI rank 2)
- **ID:** opp-mithril-cc_aiignore_boundaries
- **Value:** HIGH -- explicit trust boundaries prevent AI from modifying security-critical crypto code without review
- **Effort:** Low -- one-time file creation
- **KB pattern:** cc_aiignore_boundaries
- **Evidence:** .aiignore ABSENT. .github/copilot-instructions.md EXISTS (7091 bytes) confirming AI tools configured. Security-critical paths: mithril-stm/ (crypto primitives), mithril-signer/ (signing operations).
- **Seen in:** (none previously)

### #3: AI-assisted async concurrency debugging (ROI rank 3)
- **ID:** opp-mithril-rs_debug_async
- **Value:** HIGH -- async Rust bugs are notoriously hard to debug; AI can trace task interactions
- **Effort:** Low -- debugging assistance during development
- **KB pattern:** rs_debug_async
- **Evidence:** mithril-aggregator/ and mithril-signer/ are network services. Version bumps in commit a33d505 confirm active development. Async runtime inferred from network service architecture (MEDIUM confidence).
- **Seen in:** (none previously)

### #4: Write substantive CLAUDE.md (ROI rank 4)
- **ID:** opp-mithril-cc_claude_md_context
- **Value:** HIGH -- one-time investment with compounding returns for every AI interaction
- **Effort:** Medium -- 25+ crate workspace requires thorough coverage (adjusted from Low by Stage A adversarial review)
- **KB pattern:** cc_claude_md_context
- **Evidence:** CLAUDE.md is 14 bytes (placeholder/404). Cargo workspace has 25+ members. copilot-instructions.md exists (7091 bytes) showing AI tool investment. Complex domain: stake-based threshold multi-signatures with SNARK proofs.
- **Seen in:** input-output-hk/lace-platform (comprehensive CLAUDE.md, measurably better AI interactions)

### #5: Audit cargo-deny configuration (ROI rank 5)
- **ID:** opp-mithril-rs_cargo_deny_audit
- **Value:** MEDIUM -- misconfigured cargo-deny gives false confidence in security scanning
- **Effort:** Low -- review one config file
- **KB pattern:** rs_cargo_deny_audit
- **Evidence:** deny.toml EXISTS at repo root (743 bytes). KB pattern seen_in includes this repo: "cargo deny check licenses found but cargo deny check advisories was the actual security check."
- **Seen in:** input-output-hk/mithril (prior KB observation)

### #6: AI-generated rustdoc for internal crates (ROI rank 6)
- **ID:** opp-mithril-rs_rustdoc_generation
- **Value:** MEDIUM -- documentation improves crate usability across workspace
- **Effort:** Low -- AI drafts docs from type signatures
- **KB pattern:** rs_rustdoc_generation
- **Evidence:** internal/ directory contains 18+ crates (mithril-era, mithril-persistence, mithril-metric, mithril-dmq, etc.). Commit 4ac1a10 renames era reader adapter, confirming active development.
- **Seen in:** (none previously)

### #7: AI-generated property tests for trait implementations (ROI rank 7)
- **ID:** opp-mithril-rs_trait_test_gen
- **Value:** MEDIUM -- trait correctness across types is critical for protocol security
- **Effort:** Medium -- requires understanding trait contracts
- **KB pattern:** rs_trait_test_gen
- **Evidence:** mithril-common is shared by most workspace crates (high fan-in). mithril-stm implements cryptographic trait contracts. Cannot confirm proptest/quickcheck presence (MEDIUM confidence).
- **Seen in:** (none previously)

### Rejected: AI-assisted PR descriptions
- **Reason:** PRs #3105 and #3103 already have structured descriptions with content sections, pre-submit checklists, and issue references. PR template exists at .github/pull_request_template.md (985 bytes). The team is already doing this well.

---

## Risk Surface

| Path | Detection Difficulty | Blast Radius | AI Exposure | Key Evidence |
|------|---------------------|--------------|-------------|-------------|
| mithril-stm/ | MEDIUM | HIGH | Potential | Core crypto library. Imported by aggregator, signer, common. Active SNARK prover work. copilot-instructions.md exists but no AI commits. |
| mithril-signer/ | MEDIUM | HIGH | Potential | Signing service handling keys and protocol signatures. copilot-instructions.md exists but no AI commits. |
| mithril-aggregator/ | MEDIUM | HIGH | Potential | Aggregator combining signatures into certificates. API-facing. copilot-instructions.md exists but no AI commits. |
| mithril-common/ | MEDIUM | HIGH | Potential | Shared library across entire workspace. Changes propagate everywhere. copilot-instructions.md exists but no AI commits. |

**AI Exposure classification: Potential for all paths.** copilot-instructions.md (7091 bytes) exists, confirming AI tools are configured for the repo, but zero AI-attributed commits were found in any path. This is a preventive note, not an active risk.

**Opportunity-risk intersections (MEDIUM confidence -- inferred):**
- opp-mithril-rs_unsafe_audit intersects with mithril-stm/ (direct target)
- opp-mithril-cc_aiignore_boundaries intersects with mithril-stm/, mithril-signer/ (trust boundaries for these paths)
- opp-mithril-rs_debug_async intersects with mithril-aggregator/, mithril-signer/ (async services)
- opp-mithril-rs_trait_test_gen intersects with mithril-stm/, mithril-common/ (trait implementations)

---

## Recommendations

### #1: Create .aiignore for crypto paths (ROI: 27 = HIGH x Low x Absent)
- **ID:** rec-mithril-aiignore
- **Type:** start_now -- "Everything is in place. The gap is activation, not preparation."
- **Effort:** Low | **Impact:** HIGH
- **Linked opportunity:** opp-mithril-cc_aiignore_boundaries
- **Measurable outcome:** .aiignore exists at repo root containing at minimum: mithril-stm/, mithril-signer/ paths.
- **Recommended learning:** Create .aiignore listing security-critical paths. Same syntax as .gitignore. Review with the mithril-stm maintainer. copilot-instructions.md already exists -- .aiignore complements it with explicit exclusion boundaries.

### #2: Run unsafe code audit on mithril-stm (ROI: 27 = HIGH x Low x Absent)
- **ID:** rec-mithril-unsafe-review
- **Type:** start_now
- **Effort:** Low | **Impact:** HIGH
- **Linked opportunity:** opp-mithril-rs_unsafe_audit
- **Measurable outcome:** Each unsafe block in mithril-stm/src/ has a // SAFETY: comment documenting its invariants. Verifiable by grep.
- **Recommended learning:** For each unsafe block: give AI the block + context. Ask: "What safety invariants must hold?" and "Is there a safe alternative?" The SNARK prover integration (PR #3103) is a good starting point as it is fresh code.

### #3: Write CLAUDE.md (ROI: 18 = HIGH x Medium x Absent)
- **ID:** rec-mithril-claude-md
- **Type:** start_now
- **Effort:** Medium | **Impact:** HIGH
- **Linked opportunity:** opp-mithril-cc_claude_md_context
- **Measurable outcome:** CLAUDE.md at repo root with >500 words covering workspace crate map, security-critical paths, build commands, testing strategy, coding conventions.
- **Recommended learning:** Leverage copilot-instructions.md (7091 bytes) as starting point. Cover 6 categories per KB guidance. lace-platform found this measurably improved AI interactions.

### #4: Audit deny.toml (ROI: 18 = MEDIUM x Low x Absent)
- **ID:** rec-mithril-deny-audit
- **Type:** start_now
- **Effort:** Low | **Impact:** MEDIUM
- **Linked opportunity:** opp-mithril-rs_cargo_deny_audit
- **Measurable outcome:** deny.toml confirmed to include advisories check. CI confirmed to run cargo deny check advisories.
- **Recommended learning:** Review deny.toml with AI: Is check advisories running? Are allow-listed advisories stale? KB notes this repo previously had a license-vs-advisory gap.

### #5: Document async task topology (ROI: 18 = HIGH x Medium x Absent)
- **ID:** rec-mithril-async-debug
- **Type:** foundation_first -- "Before debugging concurrency with AI, document the task topology."
- **Effort:** Medium | **Impact:** HIGH
- **Linked opportunity:** opp-mithril-rs_debug_async
- **Measurable outcome:** Documentation listing spawned tasks, shared state, and channels in mithril-aggregator and mithril-signer.
- **Recommended learning:** Document task topology before using AI for async debugging. Give Claude task spawning code + shared state. Ask about lock acquisition order and cancellation safety.

### #6: AI-draft rustdoc for internal crates (ROI: 18 = MEDIUM x Low x Absent)
- **ID:** rec-mithril-rustdoc
- **Type:** foundation_first
- **Effort:** Low | **Impact:** MEDIUM
- **Linked opportunity:** opp-mithril-rs_rustdoc_generation
- **Measurable outcome:** lib.rs in mithril-era, mithril-persistence, mithril-dmq each have //! module-level doc comments >50 words. cargo doc --no-deps passes without warnings.
- **Recommended learning:** Start with mithril-era (recently active). Give Claude public API + call sites from dependent crates. Draft doc comments with description, arguments, returns, errors, examples.

### #7: AI-generate property tests for traits (ROI: 12 = MEDIUM x Medium x Absent)
- **ID:** rec-mithril-trait-tests
- **Type:** foundation_first -- "Before generating property tests, add proptest to dev-dependencies."
- **Effort:** Medium | **Impact:** MEDIUM
- **Linked opportunity:** opp-mithril-rs_trait_test_gen
- **Measurable outcome:** proptest in dev-dependencies for mithril-stm and mithril-common. At least 3 property tests per crate.
- **Recommended learning:** Start with serialization round-trip properties (most mechanical). Pick a trait in mithril-common with multiple impls. Ask AI for invariants and proptest strategies.

---

## Adoption State

| Opportunity | State | Evidence |
|-------------|-------|---------|
| Unsafe code audit (mithril-stm) | Absent | Zero AI co-authored-by trailers. No AI-attributed commits touching mithril-stm/. |
| .aiignore trust boundaries | Absent | .aiignore does not exist. copilot-instructions.md covers coding guidance, not trust boundaries. |
| Async debugging (aggregator/signer) | Absent | Zero AI-attributed commits touching these services. |
| CLAUDE.md context | Absent | CLAUDE.md is 14 bytes (placeholder). Per anti-pattern ap_generic_claude_md: empty = absent. |
| cargo-deny audit | Absent | deny.toml exists but no AI-assisted auditing observed. |
| Rustdoc generation | Absent | Zero AI-attributed commits touching documentation. |
| Trait test generation | Absent | Zero AI-attributed commits touching test files. |

**Note on all Absent states:** No observable AI attribution found. This does not confirm absence of AI use -- attribution is not universally enforced. The presence of copilot-instructions.md (7091 bytes) suggests AI tools are in use or planned, but individual commits do not carry attribution.

---

## Readiness per Use Case

| Opportunity | Level | Criteria Met | Confidence |
|-------------|-------|-------------|------------|
| Unsafe code audit | Exploring (1/3 met) | Clippy likely in CI (MEDIUM), No Miri evidence (MEDIUM), Safety comments unknown (LOW) | MEDIUM |
| .aiignore boundaries | Exploring (2/2 met) | Crypto paths identifiable (HIGH), AI tools in use (HIGH) | HIGH |
| Async debugging | Exploring (2/2 met) | Async runtime inferred (MEDIUM), Structured logging confirmed via ADR-002 (MEDIUM) | MEDIUM |
| CLAUDE.md context | Exploring (1/1 met) | AI tool in use -- copilot-instructions.md (HIGH) | HIGH |
| cargo-deny audit | Practiced (2/2 met) | deny.toml exists (HIGH), Advisory check inferred from KB (MEDIUM) | MEDIUM |
| Rustdoc generation | Undiscovered (0/2 met) | No rustdoc in CI (MEDIUM), Crate docs unknown (LOW) | MEDIUM |
| Trait test generation | Undiscovered (1/3 met) | proptest unconfirmed (MEDIUM), Trait docs unknown (LOW), CI runs tests (MEDIUM) | MEDIUM |

---

## Evolution

First assessment. No previous scan results to compare against.

---

## Evidence Log

### Data Sources Read
- `/tmp/aamm-v6-input-output-hk-mithril/repo-data-summary.md` -- repo metadata, key files, AI attribution summary
- `/tmp/aamm-v6-input-output-hk-mithril/tree.json` -- 2438 files, full tree structure. Key findings: deny.toml, .github/copilot-instructions.md, .github/pull_request_template.md, ci.yml (45KB), mithril-stm/, internal/, docs/website/adr/
- `/tmp/aamm-v6-input-output-hk-mithril/commits.json` -- Recent commits examined. Key: 45f79ef (merge PR #3105, SNARK prover deploy), a33d505 (crate version upgrades), 994a4b9 (SNARK AVK fix), f640298 (CI fix for future_snark)
- `/tmp/aamm-v6-input-output-hk-mithril/prs.json` -- PRs #3105 (SNARK prover dev deploy), #3103 (wire SNARK in aggregate signature). Both have structured descriptions.

### KB Patterns Matched
| Pattern | Matched | Reasoning |
|---------|---------|-----------|
| rs_unsafe_audit | YES | Crypto crate (mithril-stm), active SNARK work |
| rs_trait_test_gen | YES | Multiple crates implementing shared traits |
| rs_rustdoc_generation | YES | 18+ internal crates with inferred sparse docs |
| rs_debug_async | YES | Network services (aggregator, signer) |
| rs_cargo_deny_audit | YES | deny.toml exists, KB seen_in references this repo |
| cc_pr_descriptions | NO | Team already produces good PR descriptions |
| cc_claude_md_context | YES | CLAUDE.md is placeholder, complex domain |
| cc_aiignore_boundaries | YES | Crypto paths present, AI config exists, no .aiignore |
| cc_commit_messages | NO | Team uses conventional commits (feat:, fix:, chore:) |
| cc_onboarding_docs | NO | CONTRIBUTING.md exists (5551 bytes), devbook docs exist, runbook docs exist |

### Adversarial Reviews
- **Stage A:** Inline review. 7 approved, 1 rejected (cc_pr_descriptions -- team already has structured PR descriptions). Effort on cc_claude_md_context adjusted from Low to Medium due to 25+ crate complexity.
- **Stage B:** Inline review. All 7 recommendations approved. Each has specific measurable outcome verifiable from repo data at next scan.

### Confidence Summary
- HIGH confidence: File existence checks (.aiignore absent, CLAUDE.md placeholder, deny.toml present, copilot-instructions.md present, PR template present)
- MEDIUM confidence: CI configuration inferences (clippy in CI, cargo deny command, async runtime presence), churn-based relevance, documentation sparseness
- LOW confidence: Source code content assessments (safety comments, trait documentation, unsafe block count)

### Limitations
- Cannot read source file contents -- all source-level assessments are inferred from file tree structure, commit messages, and crate purpose
- Cannot read CI workflow YAML contents -- CI configuration assessments are inferred from file sizes and names
- Cannot confirm proptest/quickcheck presence without reading Cargo.toml dev-dependencies
- Async runtime (tokio) presence inferred from service architecture, not confirmed
