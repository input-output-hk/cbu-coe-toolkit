# AAMM Report: input-output-hk/lace-platform
> Scan date: 2026-03-31 | Ecosystem: typescript | Schema: v6.0

## Executive Summary

**Top opportunities** (ROI-ordered):
1. Create .aiignore trust boundaries for crypto/signer/auth packages -- HIGH value, Low effort
2. AI-assisted typed contract generation using established contract/ pattern + NX generator -- HIGH value, Medium effort
3. Generate unit tests for UI toolkit components with Storybook stories but no test files -- MEDIUM value, Low effort
4. AI-assisted debugging of cross-package Redux store/side-effects/slice state flows -- HIGH value, Low effort
5. Standardize AI-assisted PR descriptions extending Cursor Bugbot pattern -- MEDIUM value, Low effort
6. AI test generation for Midnight blockchain modules after SDK 3.0.0 migration -- HIGH value, Medium effort

ROI ordering is a heuristic based on estimated value and effort -- treat as suggested priority, not certainty.

**Top recommendations** (ROI-ordered):
1. Create .aiignore listing crypto, signer, recovery-phrase, secure-store, authentication-prompt packages -- start_now
2. Add .claude/docs/state-debugging.md with store/slice/side-effects pattern and resolved state bug examples -- start_now
3. Generate unit tests for blockchain-midnight side-effects covering SDK 3.0.0 migration surface -- foundation_first
4. Document AI-assisted contract creation workflow in .claude/docs/ -- start_now
5. Generate vitest unit tests for 5 UI toolkit components lacking direct test files -- start_now

**Risk flags:**
- No Risky Acceleration flags detected
- Ad-hoc AI usage flag: NOT triggered -- intentionality signals are strong (CLAUDE.md with substantive content, .claude/ directory with agents/commands/skills, claude.yml GHA workflow, .mcp.json)

**Quadrant:** High Potential, Medium Activity -- AI infrastructure is mature but zero observable AI attribution in commit history.

---

## Opportunity Map

### #1: Create .aiignore trust boundaries (ROI: 9)
| Field | Value |
|-------|-------|
| **ID** | opp-lp-cc_aiignore_boundaries |
| **Value** | HIGH -- crypto wallet with 6 security-sensitive packages exposed to AI tooling without boundaries |
| **Effort** | Low -- single file creation |
| **KB Pattern** | cc_aiignore_boundaries |
| **Evidence** | .aiignore ABSENT. Security-sensitive packages: `packages/contract/crypto`, `packages/contract/authentication-prompt` (biometric + password authenticators), `packages/contract/signer`, `packages/contract/secure-store`, `packages/contract/recovery-phrase`, `packages/lib/crypto`. AI tooling active: CLAUDE.md, .claude/ agents/commands/skills, claude.yml GHA, Cursor Bugbot in PRs, .mcp.json. |
| **Seen in** | -- |

### #2: AI-assisted typed contract generation (ROI: 6)
| Field | Value |
|-------|-------|
| **ID** | opp-lp-ts_contract_generation |
| **Value** | HIGH -- 36 contract packages with established pattern; new modules actively being added |
| **Effort** | Medium -- requires understanding contract/module architecture and ADR conventions |
| **KB Pattern** | ts_contract_generation |
| **Evidence** | 36 packages under `packages/contract/`. NX generator at `configs/nx-plugin/src/generators/contract/`. ADR-09 (naming), ADR-10 (type discriminator), ADR-14 (module isolation). Active: dapp-connector (PR #1695), staking-center v2 (#1745), collateral UTXO (#1783). |
| **Seen in** | input-output-hk/lace-platform (self-reference from KB seed) |

### #3: UI component test generation (ROI: 6)
| Field | Value |
|-------|-------|
| **ID** | opp-lp-ts_component_test_gen |
| **Value** | MEDIUM -- Storybook stories document components but unit test coverage is uneven |
| **Effort** | Low -- vitest configured in every package, Storybook provides props documentation |
| **KB Pattern** | ts_component_test_gen |
| **Evidence** | Storybook: `apps/lace-mobile-storybook` with integration stories, coverage workflows (storybook-mobile-coverage-nightly.yml, storybook-extension-perf-nightly.yml). vitest.config.js in 30+ packages. `packages/lib/ui-toolkit`, `packages/lib/ui-extension` contain reusable components. |
| **Seen in** | -- |

### #4: AI-assisted state flow debugging (ROI: 3 -- HIGH value, Low effort, but tied at #4 due to Active/Partial adoption reducing gap)
| Field | Value |
|-------|-------|
| **ID** | opp-lp-ts_debug_state |
| **Value** | HIGH -- Redux + RxJS state flows across 36+ contract packages; confirmed recent state bugs |
| **Effort** | Low -- AI can trace state mechanically given the slice/side-effects/observable pattern |
| **KB Pattern** | ts_debug_state |
| **Evidence** | Every contract package has `store/` with `slice.ts`, `side-effects.ts`, `init.ts`. ADR-19 (observables), `docs/rxjs-guidelines.md`, `docs/redux-persistence.md`. Recent bugs: PR #1772 (areKeysAvailable$ timing -- dust wallet stale balances), PR #1802 (Redux state$ throttling -- UI freeze during Midnight sync). |
| **Seen in** | -- |

### #5: Standardize AI-assisted PR descriptions (ROI: 6)
| Field | Value |
|-------|-------|
| **ID** | opp-lp-cc_pr_descriptions |
| **Value** | MEDIUM -- high PR volume, Cursor Bugbot already active but human descriptions vary |
| **Effort** | Low -- template exists, Bugbot pattern established |
| **KB Pattern** | cc_pr_descriptions |
| **Evidence** | `.github/pull_request_template.md` (787 bytes). Cursor Bugbot CURSOR_SUMMARY active with content (PR #1698, #1802). 30+ merged PRs. Human descriptions vary: PR #1802 detailed but testing unchecked, PR #1698 comprehensive with screenshots. |
| **Seen in** | -- |

### #6: Midnight integration test generation (ROI: 6)
| Field | Value |
|-------|-------|
| **ID** | opp-lp-novel_midnight_test_coverage |
| **Value** | HIGH -- highest-churn area, major SDK version jump creates test coverage gaps |
| **Effort** | Medium -- requires understanding Midnight SDK types and RxJS marble testing patterns |
| **KB Pattern** | null (novel -- KB expansion candidate) |
| **Evidence** | 10+ of last 30 commits touch Midnight code. SDK 2.0.0->3.0.0 (PR #1781): ledger-v7->v8, new estimateTransactionFee, WalletSyncUpdate type changes. Bug fixes: PR #1772 (dust wallet), PR #1802 (sync throttling), PR #1756 (onboarding). Packages: `packages/module/blockchain-midnight`, `packages/module/dapp-connector-midnight`, `packages/contract/midnight-context`. |
| **Seen in** | -- |

---

## Risk Surface

| Path | Detection | Blast Radius | AI Exposure | Evidence |
|------|-----------|-------------|-------------|----------|
| `packages/contract/crypto` | MEDIUM | HIGH | Potential | Crypto operations underpinning all wallet signing. vitest.config.js present. No AI commits. CLAUDE.md + .claude/ exist = potential exposure. |
| `packages/contract/authentication-prompt` | MEDIUM | HIGH | Potential | Biometric + password auth. Side-effects handle secret access/verification. Recent adjacent commit: PR #1772 AuthenticationCancelledError. No AI attribution. |
| `packages/contract/signer` | MEDIUM | HIGH | Potential | Transaction signing. Incorrect logic = fund loss. vitest configured. No AI commits. |
| `packages/contract/recovery-phrase` | MEDIUM | HIGH | Potential | Mnemonic seed management. Exposure = total fund loss. vitest configured. No AI commits. |
| `packages/module/blockchain-midnight` | MEDIUM | MEDIUM | Potential | Highest-churn area. SDK 3.0.0 migration. Handles shielded transactions. RxJS marble tests exist. No AI attribution. |

**Opportunity-risk intersections (MEDIUM confidence -- inferred):**
- opp-lp-cc_aiignore_boundaries intersects with all HIGH blast radius paths (crypto, auth, signer, recovery-phrase)
- opp-lp-ts_debug_state intersects with authentication-prompt (auth state flows) and blockchain-midnight (sync state)
- opp-lp-novel_midnight_test_coverage intersects with blockchain-midnight

---

## Recommendations

### #1: Create .aiignore for security-critical packages
| Field | Value |
|-------|-------|
| **ID** | rec-lp-aiignore |
| **Type** | start_now |
| **Effort** | Low |
| **Impact** | HIGH |
| **Opportunity** | opp-lp-cc_aiignore_boundaries |
| **Measurable outcome** | `.aiignore` exists at repo root containing: `packages/contract/crypto/**`, `packages/contract/signer/**`, `packages/contract/recovery-phrase/**`, `packages/contract/secure-store/**`, `packages/contract/authentication-prompt/**`, `packages/lib/crypto/**` |
| **Learning** | Create .aiignore with one path per line (.gitignore syntax). The six packages handle key material, signing, authentication, and seed phrases. Review with security lead for completeness. |

### #2: Document state debugging patterns for AI assistance
| Field | Value |
|-------|-------|
| **ID** | rec-lp-state-debug |
| **Type** | start_now |
| **Effort** | Low |
| **Impact** | HIGH |
| **Opportunity** | opp-lp-ts_debug_state |
| **Measurable outcome** | `.claude/docs/state-debugging.md` exists and is indexed in CLAUDE.md. Contains: store/slice/side-effects architecture pattern, 2+ resolved state bug examples with root cause analysis, AI debugging guidance. |
| **Learning** | Document PR #1772 (areKeysAvailable$ timing) and PR #1802 (state$ throttling) as case studies. For each: symptom, state flow path (slice -> side-effect -> observable), root cause, fix. This creates reusable context for AI-assisted debugging. |

### #3: Generate Midnight SDK 3.0.0 migration tests
| Field | Value |
|-------|-------|
| **ID** | rec-lp-midnight-tests |
| **Type** | foundation_first |
| **Effort** | Medium |
| **Impact** | HIGH |
| **Opportunity** | opp-lp-novel_midnight_test_coverage |
| **Measurable outcome** | `packages/module/blockchain-midnight` contains test files covering: WalletSyncUpdate handling, estimateTransactionFee, deferred-sync-service lifecycle. Minimum 5 new test cases. |
| **Learning** | Pick one side-effect file changed in SDK 3.0.0 upgrade (PR #1781). Give Claude the source + SDK type changes + existing RxJS marble test as style reference. Review: are marble timings realistic? Do assertions cover error paths (AuthenticationCancelledError pattern from PR #1772 is a good model)? |

### #4: Document AI-assisted contract creation workflow
| Field | Value |
|-------|-------|
| **ID** | rec-lp-contract-gen |
| **Type** | start_now |
| **Effort** | Low |
| **Impact** | MEDIUM |
| **Opportunity** | opp-lp-ts_contract_generation |
| **Measurable outcome** | `.claude/docs/` contains a document referencing the NX generator, describing AI-assisted contract.ts + types.ts drafting, indexed in CLAUDE.md. Minimum 200 words. |
| **Learning** | After running NX generator, give Claude: generated scaffold + similar existing contract (e.g., dapp-connector/src/contract.ts) + consuming module. Review: ADR-09 naming, ADR-10 discriminator, augmentations.ts pattern. |

### #5: Generate unit tests for UI toolkit components
| Field | Value |
|-------|-------|
| **ID** | rec-lp-ui-tests |
| **Type** | start_now |
| **Effort** | Low |
| **Impact** | MEDIUM |
| **Opportunity** | opp-lp-ts_component_test_gen |
| **Measurable outcome** | 5+ new .test.tsx or .test.ts files in `packages/lib/ui-toolkit` or `packages/lib/ui-extension`, each with 3+ test cases. |
| **Learning** | Pick a component with a Storybook story but no test file. Give Claude: component source + props/types + story + existing test as style reference. Request render tests and prop variation tests. Review for behavior (not implementation) assertions. |

---

## Adoption State

| Opportunity | State | Key Evidence |
|-------------|-------|-------------|
| .aiignore trust boundaries | **Absent** | No .aiignore exists. No trust boundary documentation. |
| Contract generation | **Partial** | Claude infrastructure deployed (CLAUDE.md, .claude/, claude.yml, .mcp.json). Cursor Bugbot active. Zero AI co-author attribution in commits. Infrastructure supports but no evidence of AI-assisted contract generation. |
| UI component test gen | **Absent** | No AI-attributed test commits. No AI in test pipeline. |
| State flow debugging | **Partial** | .claude/skills/troubleshoot/SKILL.md exists. Claude GHA handles implementation requests. No AI-attributed debugging commits. |
| PR descriptions | **Partial** | Cursor Bugbot active (CURSOR_SUMMARY with content in PRs #1698, #1802). But human-written sections unassisted. |
| Midnight test coverage | **Absent** | No AI attribution in Midnight test files. SDK migration authored manually. |

Note: Zero AI Co-authored-by trailers in last 100 commits. This does not confirm absence of AI use -- attribution is not universally enforced. The extensive Claude Code infrastructure (.claude/ with agents, commands, skills, GHA integration) strongly suggests AI is in use for development workflows, but commit-level attribution is not practiced.

---

## Readiness per Use Case

| Opportunity | Level | Criteria Met | Notes |
|-------------|-------|-------------|-------|
| .aiignore trust boundaries | Exploring (2/2 criteria met but only 2 criteria total -- 100%) | Security paths identifiable: YES (HIGH). AI tools active: YES (HIGH). | All criteria met. However, with only 2 criteria this is a shallow assessment. |
| Contract generation | Practiced (3/4 = 75%) | Strict mode: YES (MEDIUM). Contract pattern: YES (HIGH). Runtime validation: NO (MEDIUM). CI type-checks: YES (MEDIUM). | Runtime validation (Zod/io-ts) not confirmed -- this is the gap. |
| UI component test gen | Practiced (3/3 = 100%) | Test runner: YES (HIGH). Testing Library: YES (MEDIUM). Reference test exists: YES (HIGH). | All criteria met. |
| State flow debugging | Practiced (2/2 = 100%) | Centralized state: YES (HIGH). State types defined: YES (HIGH). | All criteria met. |
| PR descriptions | Practiced (2/2 = 100%) | PR template: YES (HIGH). CI on PRs: YES (HIGH). | All criteria met. |
| Midnight test coverage | Not Assessable | -- | No KB criteria for this use-case type. Novel opportunity. |

---

## Evolution

First assessment. No previous scan data available for delta computation.

---

## Evidence Log

### Data sources
- **File tree:** GitHub API git/trees (5062 files, recursive)
- **Commits:** Last 100 commits on main branch (2026-03-31 back to ~2026-03-14)
- **PRs:** Last 30 merged PRs
- **Key files read:** CLAUDE.md content (1516 bytes, index of 20+ docs), PR template confirmed from PR bodies

### AI attribution analysis
- Co-authored-by trailers: 2 found -- both human (Lukasz Jagiela, Dmytro Iakymenko)
- AI bot PRs: 0
- AI CI actions: claude.yml workflow present
- AI config files: CLAUDE.md, .claude/ (agents, commands, skills, settings.json, GHA request handlers), .mcp.json, .cursorignore

### KB patterns matched
| Pattern | Match | Reasoning |
|---------|-------|-----------|
| ts_contract_generation | YES | 36 contract packages, NX generator, active new module development |
| ts_component_test_gen | YES | Storybook with coverage workflows, vitest configured, ui-toolkit and ui-extension packages |
| ts_doc_generation | NO | CLAUDE.md indexes extensive documentation. Not a primary gap. |
| ts_pr_descriptions | MERGED with cc_pr_descriptions | Used cross-cutting version -- more appropriate since Cursor Bugbot is tool-agnostic |
| ts_debug_state | YES | Redux + RxJS architecture, confirmed state bugs in last week |
| cc_pr_descriptions | YES | High PR volume, Bugbot active, human descriptions vary |
| cc_claude_md_context | NO (already present) | CLAUDE.md exists with substantive content (1516 bytes, indexes 20+ docs). Adoption is Active. |
| cc_aiignore_boundaries | YES | Security-sensitive packages, AI tools active, no .aiignore |
| cc_commit_messages | NO | Commits follow conventional format (feat:, fix:, refactor:, style:). Not a gap. |
| cc_onboarding_docs | NO | CONTRIBUTING.md exists, README.md exists (18786 bytes). Documentation is substantive. |

### Anti-patterns checked
| Anti-pattern | Triggered | Notes |
|--------------|----------|-------|
| ap_empty_pr_placeholders | Monitored | Cursor Bugbot CURSOR_SUMMARY markers checked -- they contain substantive content (risk assessment, overview), not empty. Counted as Partial adoption evidence. |
| ap_generic_claude_md | Checked | CLAUDE.md is NOT generic -- it indexes 20+ specific documents (PRINCIPLES.md, development.md, ADRs, testing-strategy.md). Substantive operational config. |
| ap_docs_not_architecture | N/A | ARCHITECTURE.md absent but not penalized -- documentation distributed across ADRs and .claude/docs/. |
| ap_attribution_absence | Applied | Zero AI co-author trailers. Statement included in all Absent adoption assessments. |
| ap_readiness_not_ai_readiness | Applied | Readiness assessed per use case from KB criteria, not from general engineering quality. |

### Adversarial review outcomes
- **Stage A (Opportunity Map):** 6 opportunities submitted, 6 approved. No rejections. All passed specificity (repo-specific titles and evidence), grounding (file paths and commit SHAs verified), feasibility (effort estimates aligned with existing infrastructure), and relevance (all target active development areas from last 30 days).
- **Stage B (Recommendations):** 5 recommendations submitted, 5 approved. No rejections. All passed groundedness (linked to approved opportunities with correct type mappings), measurability (file existence/count checks), actionability (clear scope and starting points), and relevance (specific to lace-platform architecture).

### Confidence summary
| Finding | Confidence | Basis |
|---------|-----------|-------|
| .aiignore absence | HIGH | Objective: file not in tree |
| Contract package count (36) | HIGH | Objective: tree traversal |
| AI attribution absence | HIGH | Objective: grep of commit messages |
| Claude infrastructure presence | HIGH | Objective: file existence confirmed |
| Cursor Bugbot activity | HIGH | Objective: PR body content confirmed |
| State bug evidence | HIGH | Objective: commit messages cite specific bugs |
| Midnight as highest-churn area | HIGH | Objective: commit count in last 30 days |
| Test coverage gaps | MEDIUM | Semi-objective: vitest configured but test file counts not exhaustively verified |
| Runtime validation absence | MEDIUM | Semi-objective: not confirmed from package.json contents directly |
| Effort estimates | LOW | Subjective: all effort estimates carry LOW confidence ceiling |
| Value estimates | LOW | Subjective: all value estimates carry LOW confidence ceiling |
