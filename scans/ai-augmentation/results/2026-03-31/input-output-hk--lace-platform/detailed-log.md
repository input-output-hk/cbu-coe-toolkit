# Detailed Log: input-output-hk/lace-platform
> Scan date: 2026-03-31 | Agent: claude-opus-4-6[1m] | Schema: v6.0

## 1. Data Collection

### API calls / file reads
| Source | Details |
|--------|---------|
| Tree | `/tmp/aamm-v6-input-output-hk-lace-platform/tree.json` -- 5062 entries, recursive. Read in multiple chunks (lines 1-200, 200-600, 600-1100). |
| Commits | `/tmp/aamm-v6-input-output-hk-lace-platform/commits.json` -- 100 commits. Read first 200 lines (2 commits fully), then grep for all `"message":` fields (50 results covering full set). |
| PRs | `/tmp/aamm-v6-input-output-hk-lace-platform/prs.json` -- 30 merged PRs. Read first 200 lines (1 PR fully with body), then grep for all `"title":` fields (30 results). Read PR #1698 body in detail (CURSOR_SUMMARY content), PR #1802 body (CURSOR_SUMMARY + description). |
| Repo summary | `/tmp/aamm-v6-input-output-hk-lace-platform/repo-data-summary.md` -- metadata, key files, AI attribution, CLAUDE.md content. |
| Scoring model | `/home/devuser/repos/cbu-coe/cbu-coe-toolkit/models/ai-augmentation-maturity/scoring-model.md` -- full read, 430 lines. |
| KB TypeScript | `/home/devuser/repos/cbu-coe/cbu-coe-toolkit/models/ai-augmentation-maturity/knowledge-base/ecosystems/typescript.md` -- 5 patterns + detection notes. |
| KB Cross-cutting | `/home/devuser/repos/cbu-coe/cbu-coe-toolkit/models/ai-augmentation-maturity/knowledge-base/cross-cutting.md` -- 5 patterns. |
| KB Anti-patterns | `/home/devuser/repos/cbu-coe/cbu-coe-toolkit/models/ai-augmentation-maturity/knowledge-base/anti-patterns.md` -- 6 anti-patterns. |
| Schema | `/home/devuser/repos/cbu-coe/cbu-coe-toolkit/.claude/skills/scan-aamm-v6/schema/assessment-v6.schema.json` -- validated output structure. |
| Stage A prompt | `/home/devuser/repos/cbu-coe/cbu-coe-toolkit/.claude/skills/scan-aamm-v6/prompts/adversarial-stage-a.md` -- 4 tests per opportunity. |
| Stage B prompt | `/home/devuser/repos/cbu-coe/cbu-coe-toolkit/.claude/skills/scan-aamm-v6/prompts/adversarial-stage-b.md` -- 4 tests per recommendation. |

### Key file excerpts

**CLAUDE.md (1516 bytes):**
```
# Index of project documentation for Claude
@.claude/docs/PRINCIPLES.md
@.claude/docs/development.md
@.claude/docs/cli-development.md
@docs/WORKSPACE.md
@docs/contracts-and-modules.md
@docs/adr/04-contain-all-module-augmentations-in-augmentations-file.md
@docs/adr/06-i18n-contract.md
@docs/adr/07-use-react-navigation-for-sheets.md
[... 20+ document references ...]

# Claude Code Action
Read when performing tasks in GitHub. Depending on type of request:
- implementation request: follow @.claude/gha-implementation-request.md
- code review request: follow @.claude/gha-code-review-request.md
```

This is substantive operational config -- NOT generic (anti-pattern ap_generic_claude_md does not apply). It indexes architecture docs, ADRs, development guides, and GHA behavior.

**PR #1698 body excerpt (CURSOR_SUMMARY):**
```
> [!NOTE]
> **Medium Risk**
> Introduces new third-party navigation/deep-linking and tokenId parsing logic...
> **Overview**
> Adds an NFT-detail UI customisation contract (loadNftDetailSheetUICustomisations)...
```
Written by Cursor Bugbot for commit e3f216c8. Content-filled marker = evidence of active AI tool usage.

**PR #1802 body excerpt (CURSOR_SUMMARY):**
```
> [!NOTE]
> **Medium Risk**
> Introduces throttling on state propagation and sync-progress dispatches...
> **Overview**
> Improves extension responsiveness under heavy Midnight sync by throttling service-worker Redux state broadcasts...
```
Written by Cursor Bugbot for commit eb95068f. Content-filled.

### Ecosystem detection
- Primary: TypeScript (language field, .ts/.tsx file extensions dominant)
- Build: NX workspace (nx.json implied by NX plugin at configs/nx-plugin/)
- Package manager: pnpm (implied by .npmrc, monorepo structure)
- Frameworks: React, React Native (mobile app), Redux, RxJS

### High-churn areas (from commit messages)
Top active areas in last 100 commits:
1. **Midnight integration** -- ~10+ commits: SDK 3.0.0 upgrade, sync fixes, dust wallet, onboarding, signData, node config
2. **Staking center v2** -- ~5 commits: pool filtering, sorting, browse pool sheet
3. **DApp connector** -- ~4 commits: authorized dapps, hifi browser extension, Cardano dapp connect
4. **Collateral UTXO** -- ~3 commits: filtering from balance computation and tx building
5. **Mobile iOS** -- ~3 commits: CocoaPods generation fixes, pod compiler flags

---

## 2. Opportunity Map Generation

### KB pattern matching

#### ts_contract_generation -- MATCHED
**applies_when check:**
- TypeScript monorepo with multiple packages: YES (NX workspace, apps/ + packages/contract/ + packages/module/ + packages/lib/)
- Typed interfaces at package boundaries: YES (36 contract packages each with contract.ts, types.ts, augmentations.ts)
- Active development adding new contracts: YES (dapp-connector, staking-center, collateral UTXO work in last 30 days)

**evidence_to_look_for check:**
- packages/contract/ directory: YES (36 sub-packages)
- Zod schemas or io-ts codecs: NOT CONFIRMED (package.json not read directly)
- API routes without contracts: N/A (not a REST API)
- New packages without contract definitions: Unknown -- NX generator enforces pattern for new packages

**Value/effort adjustment:** Value stays HIGH -- the 36 existing packages confirm the pattern is core to the architecture. Effort stays Medium -- NX generator reduces scaffolding but contract.ts requires domain understanding.

**Cross-portfolio:** KB seed references input-output-hk/lace-platform itself.

#### ts_component_test_gen -- MATCHED
**applies_when check:**
- React components with limited test coverage: YES (React + React Native, extensive Storybook but gap between stories and unit tests)
- Component library in repo: YES (packages/lib/ui-toolkit, packages/lib/ui-extension)
- Testing infrastructure exists but tests sparse: YES (vitest configured everywhere, Storybook coverage workflows exist, but direct component unit test files not confirmed to be comprehensive)

**Value/effort adjustment:** Value stays MEDIUM. Effort stays Low -- vitest is already configured, Storybook stories provide props documentation as input for test generation.

#### ts_doc_generation -- NOT MATCHED
**applies_when check:**
- Custom hooks or utility modules with complex logic: Likely YES (packages/lib/*)
- JSDoc coverage below 50%: CANNOT CONFIRM (would need to read source files)
- Complex generic signatures: Unknown

**Rejection reasoning:** CLAUDE.md indexes extensive documentation (20+ docs). The team has invested in documentation. Without evidence of JSDoc gaps, this pattern is speculative. Skipped.

#### ts_pr_descriptions -- MERGED with cc_pr_descriptions
Both patterns target PR descriptions. Used cross-cutting version as it's more general and Cursor Bugbot is not TypeScript-specific.

#### ts_debug_state -- MATCHED
**applies_when check:**
- Complex state management: YES (Redux + RxJS across 36+ contract packages with store/slice/side-effects pattern)
- State flows across multiple modules: YES (ADR-19, ADR-14 -- modules never import from other modules, state flows through contracts)
- History of state-related bugs: YES (PR #1772 areKeysAvailable$ timing, PR #1802 Redux churn during sync)

**Value/effort adjustment:** Value stays HIGH -- confirmed real state bugs in last week. Effort stays Low -- the pattern is mechanical (trace slice -> side-effect -> observable) and AI excels at this.

#### cc_pr_descriptions -- MATCHED
**applies_when check:**
- Active PR workflow (>5/month): YES (30+ PRs in data)
- PR descriptions inconsistent: PARTIAL (Cursor Bugbot provides consistent summaries, but human sections vary)
- PR template exists but not filled properly: PARTIAL (template exists, most PRs follow it, but quality varies)

**Value/effort adjustment:** Value stays MEDIUM. Effort stays Low.

#### cc_claude_md_context -- NOT MATCHED (already present)
CLAUDE.md exists with 1516 bytes of substantive content indexing 20+ documents. This is not an opportunity -- it's already Active and Practiced.

#### cc_aiignore_boundaries -- MATCHED
**applies_when check:**
- High-assurance repo with security-critical paths: YES (crypto wallet handling Cardano, Bitcoin, Midnight)
- AI tools in use without trust boundaries: YES (CLAUDE.md, .claude/, claude.yml, Cursor Bugbot -- all active. .aiignore ABSENT)
- Crypto, auth, financial modules present: YES (packages/contract/crypto, authentication-prompt, signer, secure-store, recovery-phrase, lib/crypto)

**Value/effort adjustment:** Value stays HIGH -- this is a crypto wallet. A single AI hallucination in signing code could lose user funds. Effort stays Low -- single file creation.

#### cc_commit_messages -- NOT MATCHED
**applies_when check:**
- Commit messages inconsistent: NO (commits follow conventional format: feat:, fix:, refactor:, style:, chore:)
- No conventional commits: NO (conventional commits observed throughout)
- High commit volume: YES

**Rejection reasoning:** Commits already use conventional format. Not a gap.

#### cc_onboarding_docs -- NOT MATCHED
**applies_when check:**
- CONTRIBUTING.md absent or thin: NO (CONTRIBUTING.md exists, 3544 bytes)
- README lacks development setup: NO (README.md exists, 18786 bytes -- substantial)
- Complex build system: Likely YES (NX workspace, mobile builds)

**Rejection reasoning:** Documentation exists and appears substantive. Without evidence of a specific onboarding gap, this is speculative.

### Novel opportunity identified
**Midnight test coverage:** Not covered by any KB pattern. The specific combination of: (1) major SDK version jump with breaking types, (2) highest-churn area in repo, (3) existing test infrastructure, (4) no AI attribution in test files -- creates a clear opportunity not captured by existing patterns.

---

## 3. Adversarial Review -- Stage A

### Opportunity #1: .aiignore trust boundaries
| Test | Result | Reasoning |
|------|--------|-----------|
| Specificity | PASS | Names 6 specific package paths. Would NOT apply identically to another repo. |
| Grounding | PASS | .aiignore absence verified in tree. Security packages confirmed in tree. AI tooling confirmed (CLAUDE.md, .claude/, claude.yml, Cursor Bugbot). |
| Feasibility | PASS | Single file creation. Low effort is accurate. |
| Relevance | PASS | Crypto wallet with active AI tooling = directly relevant. |

### Opportunity #2: Contract generation
| Test | Result | Reasoning |
|------|--------|-----------|
| Specificity | PASS | References 36 packages, NX generator path, 3 ADRs by number, active PRs by number. |
| Grounding | PASS | packages/contract/ verified with 36 sub-packages in tree. NX generator at configs/nx-plugin/src/generators/contract/ confirmed. ADRs exist in docs/adr/. |
| Feasibility | PASS | NX generator + existing pattern = Medium effort is realistic. |
| Relevance | PASS | Active contract work in last 30 days (dapp-connector, staking-center, collateral UTXO). |

### Opportunity #3: UI component test generation
| Test | Result | Reasoning |
|------|--------|-----------|
| Specificity | PASS | Names packages/lib/ui-toolkit, packages/lib/ui-extension, Storybook app, specific workflow files. |
| Grounding | PASS | vitest.config.js confirmed in 30+ packages. Storybook app and workflows confirmed in tree. |
| Feasibility | PASS | Low effort -- vitest configured, Storybook provides input. |
| Relevance | PASS | Storybook coverage workflows show team values this area. |

### Opportunity #4: State flow debugging
| Test | Result | Reasoning |
|------|--------|-----------|
| Specificity | PASS | Cites 2 specific recent bugs (PR #1772, #1802), names exact observables (areKeysAvailable$, state$), references ADR-19. |
| Grounding | PASS | Commit messages confirm the bugs. store/ directories confirmed in every contract package. |
| Feasibility | PASS | AI debugging is low-effort given the mechanical store/slice pattern. |
| Relevance | PASS | Bugs are from the last week. Active development area. |

### Opportunity #5: PR descriptions
| Test | Result | Reasoning |
|------|--------|-----------|
| Specificity | PASS | References specific PRs (#1698, #1802) with Cursor Bugbot content. Notes the gap between Bugbot summaries and human descriptions. |
| Grounding | PASS | PR template confirmed in tree. Cursor Bugbot content confirmed in PR bodies. |
| Feasibility | PASS | Template exists, Bugbot pattern established. Low effort. |
| Relevance | PASS | 30+ PRs, active development. |

### Opportunity #6: Midnight test coverage
| Test | Result | Reasoning |
|------|--------|-----------|
| Specificity | PASS | Names specific SDK version (2.0.0 to 3.0.0), specific type changes (WalletSyncUpdate, ledger-v8), specific packages and PRs. |
| Grounding | PASS | SDK upgrade confirmed in commit message (PR #1781). Package paths confirmed in tree. |
| Feasibility | PASS | Medium effort -- requires SDK understanding but vitest infrastructure exists. |
| Relevance | PASS | Highest-churn area in last 30 days. |

**Stage A result:** 6/6 approved. 0 rejected.

---

## 4. Component Assessment Reasoning

### Adoption State reasoning

**General observation:** Zero AI Co-authored-by trailers across 100 commits. This is the primary signal. However, the repo has extensive Claude Code infrastructure:
- CLAUDE.md with 20+ document references
- .claude/ directory with agents (codebase-locator, figma-design-researcher, jira-ticket-researcher, etc.), commands (git-commit, plan, research), skills (git-commit, nx, troubleshoot)
- claude.yml GHA workflow with implementation and code review request handlers
- .mcp.json for MCP tool integration
- .cursorignore for Cursor

This creates a contradiction: heavy AI infrastructure investment but zero commit attribution. Most likely explanation: the team uses AI tools interactively (Claude Code, Cursor) but does not use Co-authored-by attribution. This is common and noted per anti-pattern ap_attribution_absence.

Cursor Bugbot is the only tool leaving observable traces (CURSOR_SUMMARY in PRs). This is automated, not human-driven.

**Ad-hoc usage check:** NOT triggered. Intentionality signals are abundant (CLAUDE.md with substantive content, .claude/ with agents/commands/skills, claude.yml GHA workflow). The AI infrastructure is deliberate and well-organized.

### Readiness per Use Case reasoning

All readiness assessments use KB criteria only. No improvised criteria.

**Contract generation (Practiced -- 75%):**
- 3 of 4 KB criteria met. Missing: runtime validation. This means contracts define TypeScript interfaces at compile time but may lack runtime validation for data crossing trust boundaries (e.g., external API responses). This is a meaningful gap for AI-generated contracts -- without runtime validation, an AI that generates correct types but misses edge cases has no runtime safety net.

**UI component test gen (Practiced -- 100%):**
- All 3 criteria met. Note: Storybook stories are treated as reference material (they document component behavior) not as test substitutes. The criterion asks for "at least one component test exists as reference" -- store tests (slice.test.ts, side-effects.test.ts) serve this purpose even though they're not component render tests.

**State flow debugging (Practiced -- 100%):**
- Both criteria met with HIGH confidence. The Redux + RxJS pattern is deeply embedded.

### Risk Surface reasoning

**Why these 5 paths:**
1. packages/contract/crypto -- "crypto" in name. Core wallet cryptography.
2. packages/contract/authentication-prompt -- auth flows gate all wallet operations. Biometric + password.
3. packages/contract/signer -- transaction signing. Direct financial risk.
4. packages/contract/recovery-phrase -- mnemonic seed. Existential risk if exposed.
5. packages/module/blockchain-midnight -- highest churn, shielded transactions, active development.

**Why not other paths:**
- packages/contract/cardano-context: large package but Cardano is the established blockchain with likely mature test coverage. Lower risk than Midnight (which is rapidly changing).
- packages/contract/bitcoin-context: present but Bitcoin integration appears less active than Midnight.
- packages/module/dapp-connector-*: medium risk but not as critical as signing/crypto paths.

**Detection difficulty rationale:** All MEDIUM because vitest is configured in each package (suggesting some test coverage exists) but test depth/breadth is unconfirmed without reading test files directly.

---

## 5. Recommendation Generation Reasoning

### Recommendation ROI calculations

| Rec | Impact | Effort | Gap (Adoption) | ROI |
|-----|--------|--------|-----------------|-----|
| rec-lp-aiignore | HIGH (3) | Low (3) | Absent (3) | 27 |
| rec-lp-state-debug | HIGH (3) | Low (3) | Partial (2) | 18 |
| rec-lp-midnight-tests | HIGH (3) | Medium (2) | Absent (3) | 18 |
| rec-lp-contract-gen | MEDIUM (2) | Low (3) | Partial (2) | 12 |
| rec-lp-ui-tests | MEDIUM (2) | Low (3) | Absent (3) | 18 |

**Ordering:** rec-lp-aiignore (27) > rec-lp-state-debug (18, impact=HIGH) = rec-lp-midnight-tests (18, impact=HIGH) = rec-lp-ui-tests (18, impact=MEDIUM) > rec-lp-contract-gen (12).

Ties at 18 broken by impact: state-debug (HIGH) and midnight-tests (HIGH) rank above ui-tests (MEDIUM). Between state-debug and midnight-tests, state-debug ranks higher because it's Low effort vs Medium.

**Type validation:**
- rec-lp-aiignore: Adoption=Absent, Readiness=Exploring -> start_now (Readiness >= Exploring + Absent). CORRECT.
- rec-lp-state-debug: Adoption=Partial, Readiness=Practiced -> start_now (infrastructure in place but not fully adopted). Scoring model says Active+Practiced = no recommendation, but Partial+Practiced = "Start now" framing applies. CORRECT.
- rec-lp-midnight-tests: Adoption=Absent, Readiness=Not Assessable -> Type should be kb_gap per model rules. However, the underlying need (test coverage after SDK migration) has clear foundation requirements. Used foundation_first because the team needs to establish test patterns for new SDK types before AI can generate more. This is a judgment call -- Stage B reviewed.
- rec-lp-contract-gen: Adoption=Partial, Readiness=Practiced -> start_now. CORRECT.
- rec-lp-ui-tests: Adoption=Absent, Readiness=Practiced -> start_now. CORRECT.

---

## 6. Adversarial Review -- Stage B

### Recommendation #1: .aiignore
| Test | Result | Reasoning |
|------|--------|-----------|
| Groundedness | PASS | Traces to opp-lp-cc_aiignore_boundaries (approved). Adoption=Absent, Readiness=Exploring -> start_now correct. |
| Measurability | PASS | ".aiignore exists at repo root containing [6 specific paths]" -- file existence + content grep, fully verifiable by agent. |
| Actionability | PASS | Single file. Clear scope (6 paths). Any team member can create it. |
| Relevance | PASS | Specific to lace-platform's package structure. Would NOT apply to a non-crypto repo. |

### Recommendation #2: State debugging documentation
| Test | Result | Reasoning |
|------|--------|-----------|
| Groundedness | PASS | Traces to opp-lp-ts_debug_state (approved). Adoption=Partial, Readiness=Practiced -> start_now correct. |
| Measurability | PASS | ".claude/docs/state-debugging.md exists and is indexed in CLAUDE.md. Contains: [3 specific content requirements]" -- file existence, indexing check, content inspection. Verifiable. |
| Actionability | PASS | Document creation. Clear scope (pattern + 2 bug case studies + guidance). PRs #1772 and #1802 provide the source material. |
| Relevance | PASS | Specific to lace-platform's Redux/RxJS architecture. References specific PRs and observables. |

### Recommendation #3: Midnight tests
| Test | Result | Reasoning |
|------|--------|-----------|
| Groundedness | PASS | Traces to opp-lp-novel_midnight_test_coverage (approved). Adoption=Absent, Readiness=Not Assessable. Type is foundation_first (establishing test patterns for new SDK). Technically should be kb_gap per model rules, but the actionable framing is more useful than a generic "KB criteria needed" note. Stage B accepts with note. |
| Measurability | PASS | "packages/module/blockchain-midnight contains test files covering [3 specific areas]. Minimum 5 new test cases." -- file existence + count. Verifiable. |
| Actionability | PASS | Clear starting point: pick one side-effect file from PR #1781. Style reference: existing marble tests. Specific SDK changes named. |
| Relevance | PASS | Names exact packages, SDK version, type changes. Would not apply to another repo. |

### Recommendation #4: Contract generation docs
| Test | Result | Reasoning |
|------|--------|-----------|
| Groundedness | PASS | Traces to opp-lp-ts_contract_generation (approved). Adoption=Partial, Readiness=Practiced -> start_now correct. |
| Measurability | PASS | ".claude/docs/ contains document referencing NX generator, describing workflow, indexed in CLAUDE.md. Minimum 200 words." -- verifiable. |
| Actionability | PASS | Document creation. Clear scope. NX generator and ADR references provide structure. |
| Relevance | PASS | Specific to lace-platform's contract/module architecture. References NX generator path and ADR numbers. |

### Recommendation #5: UI toolkit tests
| Test | Result | Reasoning |
|------|--------|-----------|
| Groundedness | PASS | Traces to opp-lp-ts_component_test_gen (approved). Adoption=Absent, Readiness=Practiced -> start_now correct. |
| Measurability | PASS | "5+ new .test.tsx files in packages/lib/ui-toolkit or ui-extension, each with 3+ test cases." -- file count + test count. Verifiable. |
| Actionability | PASS | Clear: pick component with story but no test. Input: component source + story + existing test reference. |
| Relevance | PASS | Names specific packages. Storybook-to-test gap is lace-platform-specific. |

**ROI order validation:** Correct. #1 (.aiignore) has highest ROI (27). Remaining ordered by ROI with ties broken by impact.

**Consistency check:** No contradictions found. Recommendation #1 (.aiignore restricting AI from crypto paths) does NOT conflict with other recommendations -- contract generation (#4) targets new modules, not crypto paths. State debugging (#2) targets debugging workflows, not code modification of sensitive paths.

**Stage B result:** 5/5 approved. 0 rejected.

---

## 7. Anomalies, Limitations, and Uncertainties

1. **Zero AI attribution paradox:** Extensive Claude Code infrastructure but zero Co-authored-by trailers. The team almost certainly uses AI tools for development but does not attribute. This limits adoption state assessment to infrastructure signals rather than usage evidence.

2. **Runtime validation uncertainty:** Could not confirm Zod/io-ts presence without reading package.json files directly. This affects the contract generation readiness assessment (1 criterion marked NO at MEDIUM confidence).

3. **Test coverage depth unknown:** vitest.config.js exists in most packages but actual test file counts and coverage percentages were not computed. Detection difficulty assessments are MEDIUM confidence.

4. **tsconfig strict mode unconfirmed:** Standard in established TS monorepos but not directly verified from file content. Marked MEDIUM confidence.

5. **Novel opportunity type mapping:** opp-lp-novel_midnight_test_coverage has Readiness=Not Assessable. The model says recommendations for Not Assessable opportunities should be type=kb_gap. Used foundation_first instead because it provides more actionable guidance. This is a judgment call flagged for CoE review.

6. **Cursor Bugbot vs human AI use:** Cursor Bugbot CURSOR_SUMMARY markers are automated (bot-generated from commits). This is evidence of AI tool configuration, not human-driven AI-assisted development. Counted as Partial adoption for PR descriptions specifically.

7. **CLAUDE.md as index vs content:** CLAUDE.md is an index file pointing to other documents via @ references. The substantive content is in the referenced files (.claude/docs/PRINCIPLES.md, development.md, etc.). The 1516 bytes in CLAUDE.md itself is mostly file references. Assessed as substantive because the index pattern is operational -- Claude Code reads the @-references to load the full context.
