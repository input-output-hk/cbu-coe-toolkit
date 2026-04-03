# TypeScript Ecosystem — Opportunity Patterns + Readiness Criteria

## AI-assisted type-safe API contract generation

```yaml
id: ts_contract_generation
type: opportunity
ecosystem: typescript
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - TypeScript monorepo with multiple packages
  - Typed interfaces defined at package boundaries (contract packages, shared types)
  - Active development adding new API endpoints or inter-package contracts

value: HIGH
value_context: "Contract packages ensure type safety across module boundaries; AI can draft contracts from implementation + usage patterns"
effort: Medium
evidence_to_look_for:
  - packages/contract/ or packages/*/types/ directories
  - Zod schemas, io-ts codecs, or similar runtime validation
  - API routes without corresponding typed contracts
  - New packages added without contract definitions
seen_in:
  - repo: input-output-hk/lace-platform
    outcome: "30+ contract packages observed — pattern well-established but new modules sometimes miss contracts"

learning_entry: |
  When adding a new API endpoint or inter-package dependency:
  1. Give Claude the implementation module + the consuming module
  2. Ask it to draft a typed contract (interface + Zod schema for runtime validation)
  3. Review: does the contract capture all edge cases? Are optional fields correct?
  Key: AI sees both sides of the contract (producer + consumer) simultaneously.

readiness_criteria:
  - criterion: "TypeScript strict mode enabled"
    type: Objective
    check: "tsconfig.json has 'strict': true in compilerOptions"
  - criterion: "Contract or shared-types pattern established"
    type: Objective
    check: "Directories named contract/, types/, or shared/ exist with .ts interface files"
  - criterion: "Runtime validation library in use"
    type: Objective
    check: "Zod, io-ts, or similar in package.json dependencies"
  - criterion: "CI type-checks across packages"
    type: Objective
    check: "CI runs tsc --noEmit or equivalent across the workspace"

kb_version: "6.2"

adoption_signals:
  active:
    - description: "AI-attributed commits creating or updating contract files"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching packages/*/contract/ or packages/*/types/"
      threshold: "count >= 3 in last 90 days"
    - description: "claude.yml or Cursor config references contract generation workflow"
      method: file_search
      pattern: ".github/workflows/claude.yml or .cursor/ config referencing contract or type generation"
      threshold: "exists: true"
    - description: "NX generator combined with AI workflow for contracts"
      method: file_search
      pattern: "tools/generators/ or workspace-generators/ with contract/type scaffolding + CLAUDE.md or .mcp.json referencing contracts"
      threshold: "exists: true"
      verification_hint: "Must have both generator and AI config — generator alone is not AI adoption"
  partial:
    - description: "CLAUDE.md and .claude/ directory exist but no AI contract commits"
      method: file_search
      pattern: "CLAUDE.md or .claude/ directory exists"
      threshold: "exists: true"
      verification_hint: "Check commit_scan for contract-path AI commits — if none, Partial only"
    - description: "1-2 AI commits touching contract paths"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching packages/*/contract/ or packages/*/types/"
      threshold: "count >= 1 AND count < 3 in last 90 days"
  absent:
    - description: "No AI config files in repo"
      method: file_search
      pattern: "CLAUDE.md, .cursorrules, .mcp.json, copilot-instructions.md, AGENTS.md"
      threshold: "none exist"
    - description: "No AI attribution in commits"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini|AI)"
      threshold: "count == 0 in last 180 days"
  anti_patterns:
    - description: "AI config exists but contract packages have no Zod or runtime validation"
      method: content_analysis
      pattern: "AI config present but contract directories contain only bare interfaces — no Zod, io-ts, or runtime validation"
      actual_state: "Partial at best — AI may generate contracts but without runtime safety"
  confidence_threshold: 60

readiness_levels:
  undiscovered:
    description: "No contract infrastructure or strict mode"
    criteria:
      - description: "Fewer than 3 contract or shared-type packages"
        method: file_search
        pattern: "packages/*/contract/ or packages/*/types/ directories"
        threshold: "count < 3"
      - description: "TypeScript strict mode not enabled"
        method: file_search
        pattern: "tsconfig.json with strict: true in compilerOptions"
        threshold: "exists: false"
    quantitative: "<3 contract packages, no strict mode"
  exploring:
    description: "Contract pattern exists but incomplete"
    requires: [undiscovered]
    criteria:
      - description: "3-10 contract or type packages exist"
        method: file_search
        pattern: "packages/*/contract/ or packages/*/types/ directories"
        threshold: "count >= 3 AND count <= 10"
      - description: "Strict mode enabled"
        method: file_search
        pattern: "tsconfig.json with strict: true"
        threshold: "exists: true"
      - description: "No runtime validation (Zod/io-ts) in contracts"
        method: file_search
        pattern: "zod or io-ts imports in contract package files"
        threshold: "count == 0"
    quantitative: "3-10 contract packages, strict mode, no Zod/io-ts"
  practiced:
    description: "Comprehensive contract infrastructure ready for AI augmentation"
    requires: [exploring]
    criteria:
      - description: "10+ contract or type packages"
        method: file_search
        pattern: "packages/*/contract/ or packages/*/types/ directories"
        threshold: "count >= 10"
      - description: "Strict mode enabled across workspace"
        method: file_search
        pattern: "tsconfig.json with strict: true"
        threshold: "exists: true"
      - description: "Zod or io-ts used for runtime validation in contracts"
        method: file_search
        pattern: "zod or io-ts in contract package dependencies"
        threshold: "exists: true"
      - description: "CI type-checks across workspace boundaries"
        method: file_search
        pattern: "CI workflow running tsc --noEmit or nx affected:typecheck"
        threshold: "exists: true"
    quantitative: "10+ contract packages, strict + Zod/io-ts + CI cross-workspace type check"
    temporal_check: "Last 3 new modules added have corresponding contract packages"
  confidence_threshold: 60
```

## Test generation for UI components

```yaml
id: ts_component_test_gen
type: opportunity
ecosystem: typescript
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - React/Vue/Svelte components with limited test coverage
  - Component library or design system in repo
  - Testing infrastructure exists (Jest, Vitest, Testing Library) but test files sparse

value: MEDIUM
value_context: "Component tests are repetitive to write; AI can generate comprehensive test suites from component props and render logic"
effort: Low
evidence_to_look_for:
  - components/ or src/ui/ directories with .tsx files
  - Few or no corresponding .test.tsx or .spec.tsx files
  - Test config present (jest.config, vitest.config) but low test count
  - Storybook stories exist (stories are props documentation — useful for test generation)
seen_in: []

learning_entry: |
  Pick one component with no tests. Give Claude:
  1. The component source (.tsx)
  2. Its props/types
  3. One example of an existing test in the repo (for style reference)
  Ask it to generate: render tests, prop variation tests, interaction tests.
  Review: are the assertions testing behavior (not implementation details)?

readiness_criteria:
  - criterion: "Test runner configured"
    type: Objective
    check: "jest.config.* or vitest.config.* exists"
  - criterion: "Testing Library available"
    type: Objective
    check: "@testing-library/react or equivalent in devDependencies"
  - criterion: "At least one component test exists as reference"
    type: Objective
    check: "Any .test.tsx or .spec.tsx file exists in the component directory tree"

kb_version: "6.2"

adoption_signals:
  active:
    - description: "AI-generated test files in component directories"
      method: file_search
      pattern: "*.test.tsx or *.spec.tsx files with Co-authored-by AI attribution in git log"
      threshold: "count >= 3 in last 90 days"
    - description: "AI commits touching test paths"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching **/*.test.tsx or **/*.spec.tsx"
      threshold: "count >= 3 in last 90 days"
    - description: "AI PR reviews or bot PRs adding component tests"
      method: pr_analysis
      pattern: "PRs with AI co-authorship adding .test.tsx or .spec.tsx files"
      threshold: "count >= 2 in last 90 days"
  partial:
    - description: "1-2 AI commits touching test files"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching **/*.test.tsx or **/*.spec.tsx"
      threshold: "count >= 1 AND count < 3 in last 90 days"
    - description: "AI config exists but no test-generation evidence"
      method: file_search
      pattern: "CLAUDE.md or .cursorrules or .mcp.json exists"
      threshold: "exists: true"
      verification_hint: "File exists but no AI-attributed test commits — Partial infrastructure"
  absent:
    - description: "No AI config files"
      method: file_search
      pattern: "CLAUDE.md, .cursorrules, .mcp.json, copilot-instructions.md, AGENTS.md"
      threshold: "none exist"
    - description: "No AI attribution in any commits"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini|AI)"
      threshold: "count == 0 in last 180 days"
  anti_patterns:
    - description: "AI-generated tests assert implementation details not behavior"
      method: content_analysis
      pattern: "Test files with assertions on internal state, DOM structure, or snapshot-only tests without behavioral assertions"
      actual_state: "Partial at best — tests exist but provide fragile coverage"
    - description: "AI test config present but test runner broken or disabled"
      method: file_search
      pattern: "jest.config or vitest.config exists but CI does not run tests"
      actual_state: "Absent — infrastructure exists on paper only"
  confidence_threshold: 60

readiness_levels:
  undiscovered:
    description: "No test runner or testing library configured"
    criteria:
      - description: "No test runner config"
        method: file_search
        pattern: "jest.config.* or vitest.config.* files"
        threshold: "count == 0"
      - description: "No testing library in dependencies"
        method: file_search
        pattern: "@testing-library/react or @testing-library/vue in package.json"
        threshold: "exists: false"
  exploring:
    description: "Test infrastructure exists but coverage is low"
    requires: [undiscovered]
    criteria:
      - description: "Test runner configured"
        method: file_search
        pattern: "jest.config.* or vitest.config.* exists"
        threshold: "exists: true"
      - description: "Testing library available"
        method: file_search
        pattern: "@testing-library/react or equivalent in devDependencies"
        threshold: "exists: true"
      - description: "Less than 10% of components have test files"
        method: file_search
        pattern: "*.test.tsx or *.spec.tsx files vs *.tsx component files"
        threshold: "ratio < 0.10"
    quantitative: "Runner + library configured, <10% component test coverage"
  practiced:
    description: "Comprehensive testing infrastructure ready for AI augmentation"
    requires: [exploring]
    criteria:
      - description: "More than 30% of components have test files"
        method: file_search
        pattern: "*.test.tsx or *.spec.tsx files vs *.tsx component files"
        threshold: "ratio >= 0.30"
      - description: "Storybook stories exist as component reference"
        method: file_search
        pattern: "*.stories.tsx or *.stories.ts files in component directories"
        threshold: "count >= 5"
      - description: "CI runs component tests"
        method: file_search
        pattern: "CI workflow running jest or vitest on pull_request"
        threshold: "exists: true"
    quantitative: ">30% component test coverage, Storybook stories as reference, CI test gate"
    temporal_check: "Last 3 new components added have corresponding test files"
  confidence_threshold: 60
```

## Documentation generation for complex hooks and utilities

```yaml
id: ts_doc_generation
type: opportunity
ecosystem: typescript
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Custom hooks or utility modules with complex logic
  - JSDoc coverage below 50% on exported functions
  - Functions with complex generic signatures

value: MEDIUM
value_context: "TypeScript type signatures carry information but complex generics still need explanation; AI can draft accurate JSDoc from signatures + usage"
effort: Low
evidence_to_look_for:
  - hooks/ or utils/ directories
  - Exported functions without JSDoc comments (/** */ blocks)
  - Complex generic signatures (multiple type parameters, conditional types)
seen_in: []

learning_entry: |
  Pick a complex utility or hook. Give Claude the source + 2-3 call sites.
  Ask it to draft JSDoc with: description, @param for each parameter,
  @returns, @example with a real usage from the codebase.
  Review for accuracy — AI handles generic descriptions well but may
  oversimplify constraints.

readiness_criteria:
  - criterion: "TypeDoc or JSDoc tooling available"
    type: Objective
    check: "typedoc in devDependencies, or JSDoc comments present in at least some files"
  - criterion: "Exported functions are typed (no 'any' escape hatches)"
    type: Semi-objective
    check: "Sample 5 exported functions — fewer than 20% use 'any' or 'unknown' as return type"

kb_version: "6.2"

adoption_signals:
  active:
    - description: "AI-attributed commits adding JSDoc comments"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits adding or modifying JSDoc (/** */) blocks"
      threshold: "count >= 3 in last 90 days"
    - description: "AI commits modifying TypeDoc configuration"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching typedoc.json or typedoc.config.*"
      threshold: "count >= 1 in last 90 days"
    - description: "AI PRs adding documentation to exported functions"
      method: pr_analysis
      pattern: "PRs with AI co-authorship adding JSDoc blocks to hooks/ or utils/ files"
      threshold: "count >= 2 in last 90 days"
  partial:
    - description: "AI config references doc generation but few doc commits"
      method: file_search
      pattern: "CLAUDE.md or .cursorrules mentioning JSDoc, TypeDoc, or documentation generation"
      threshold: "exists: true"
      verification_hint: "Config mentions docs but check commit_scan for actual AI doc commits"
    - description: "1-2 AI commits adding JSDoc"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits adding JSDoc blocks"
      threshold: "count >= 1 AND count < 3 in last 90 days"
  absent:
    - description: "No AI config files"
      method: file_search
      pattern: "CLAUDE.md, .cursorrules, .mcp.json, copilot-instructions.md, AGENTS.md"
      threshold: "none exist"
    - description: "No AI attribution in commits"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini|AI)"
      threshold: "count == 0 in last 180 days"
  anti_patterns:
    - description: "AI-generated JSDoc is generic or copy-paste of function name"
      method: content_analysis
      pattern: "JSDoc comments that merely restate the function name or have placeholder descriptions"
      actual_state: "Partial at best — docs exist but add no value beyond what the type signature provides"
  confidence_threshold: 60

readiness_levels:
  undiscovered:
    description: "No documentation tooling or JSDoc present"
    criteria:
      - description: "No TypeDoc in dependencies"
        method: file_search
        pattern: "typedoc in devDependencies in any package.json"
        threshold: "exists: false"
      - description: "No JSDoc comments on exported functions"
        method: content_analysis
        pattern: "/** */ blocks preceding export function or export const declarations"
        threshold: "count == 0 in sampled files"
        sampling: "sample 10 files from hooks/ or utils/"
  exploring:
    description: "Doc tooling configured but low coverage"
    requires: [undiscovered]
    criteria:
      - description: "TypeDoc or JSDoc tooling available"
        method: file_search
        pattern: "typedoc in devDependencies or typedoc.json exists"
        threshold: "exists: true"
      - description: "JSDoc coverage below 20% on exports"
        method: content_analysis
        pattern: "Exported functions with preceding JSDoc vs total exports"
        threshold: "ratio < 0.20"
        sampling: "sample 10 files from hooks/ or utils/"
      - description: "Exported functions use proper types (not any)"
        method: content_analysis
        pattern: "export function or export const declarations using any as return type"
        threshold: "ratio < 0.20 in sampled files"
    quantitative: "TypeDoc configured, <20% JSDoc coverage, typed exports"
  practiced:
    description: "Comprehensive documentation ready for AI augmentation"
    requires: [exploring]
    criteria:
      - description: "JSDoc coverage above 50% on exported functions"
        method: content_analysis
        pattern: "Exported functions with preceding JSDoc vs total exports"
        threshold: "ratio >= 0.50"
        sampling: "sample 10 files from hooks/ or utils/"
      - description: "TypeDoc generates output in CI or build"
        method: file_search
        pattern: "typedoc command in CI workflow or build scripts"
        threshold: "exists: true"
      - description: "JSDoc includes @example tags with real usage"
        method: content_analysis
        pattern: "@example tags in JSDoc blocks"
        threshold: "found in >= 30% of JSDoc blocks in sampled files"
        sampling: "sample 10 documented files"
    quantitative: ">50% JSDoc coverage on exports, TypeDoc in CI, @example tags"
    temporal_check: "Last 3 new exported functions have JSDoc with @param and @returns"
  confidence_threshold: 60
```

## AI-assisted PR description and changelog generation

```yaml
id: ts_pr_descriptions
type: opportunity
ecosystem: typescript
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Active PR workflow (>5 PRs merged per month)
  - PR descriptions are inconsistent or thin
  - Changelog maintained manually or not at all

value: MEDIUM
value_context: "Consistent PR descriptions improve review quality and onboarding; AI can generate structured descriptions from diffs"
effort: Low
evidence_to_look_for:
  - PR template exists but descriptions vary in quality
  - CHANGELOG.md exists but updates are sporadic
  - High PR volume in last 30 days
seen_in: []

learning_entry: |
  Set up Claude Code or Copilot to draft PR descriptions from the diff.
  Template: What changed (bullet points), Why (link to issue/ticket),
  How to test (specific steps), Breaking changes (if any).
  Review and edit before submitting — the draft saves time, not replaces judgment.

readiness_criteria:
  - criterion: "PR template exists"
    type: Objective
    check: ".github/PULL_REQUEST_TEMPLATE.md exists"
  - criterion: "CI runs on PRs"
    type: Objective
    check: "CI workflow triggered on pull_request events"

kb_version: "6.2"

adoption_signals:
  active:
    - description: "Cursor CURSOR_SUMMARY sections with substantive content in PRs"
      method: pr_analysis
      pattern: "PR bodies containing CURSOR_SUMMARY with >50 words of non-boilerplate content"
      threshold: "count >= 5 in last 90 days"
    - description: "claude.yml GHA workflow running PR review"
      method: file_search
      pattern: ".github/workflows/claude.yml triggered on pull_request or pull_request_target"
      threshold: "exists: true"
    - description: "AI-generated PR descriptions in recent PRs"
      method: pr_analysis
      pattern: "PRs with structured descriptions containing AI attribution or bot labels"
      threshold: "count >= 5 in last 90 days"
  partial:
    - description: "PR template exists but AI descriptions inconsistent"
      method: file_search
      pattern: ".github/PULL_REQUEST_TEMPLATE.md exists"
      threshold: "exists: true"
      verification_hint: "Template exists but check PR analysis for actual AI-generated content"
    - description: "Some CURSOR_SUMMARY sections but sparse content"
      method: pr_analysis
      pattern: "PR bodies containing CURSOR_SUMMARY with <50 words"
      threshold: "count >= 1"
  absent:
    - description: "No PR template"
      method: file_search
      pattern: ".github/PULL_REQUEST_TEMPLATE.md"
      threshold: "exists: false"
    - description: "No AI attribution in PR descriptions"
      method: pr_analysis
      pattern: "PRs with CURSOR_SUMMARY, AI co-authorship, or bot labels"
      threshold: "count == 0 in last 90 days"
  anti_patterns:
    - description: "Empty CURSOR_SUMMARY sections in PRs"
      method: pr_analysis
      pattern: "PR bodies containing CURSOR_SUMMARY with empty or <10 word content"
      actual_state: "Absent — tool is configured but not producing value"
    - description: "claude.yml PR review workflow exists but disabled"
      method: file_search
      pattern: ".github/workflows/claude.yml with workflow disabled or commented out"
      actual_state: "Partial at best — was Active, now degraded"
  confidence_threshold: 60

readiness_levels:
  undiscovered:
    description: "No PR review infrastructure"
    criteria:
      - description: "No PR template"
        method: file_search
        pattern: ".github/PULL_REQUEST_TEMPLATE.md"
        threshold: "exists: false"
      - description: "No CI on pull requests"
        method: file_search
        pattern: "CI workflows triggered on pull_request events"
        threshold: "count == 0"
  exploring:
    description: "PR infrastructure exists but limited AI integration"
    requires: [undiscovered]
    criteria:
      - description: "PR template exists"
        method: file_search
        pattern: ".github/PULL_REQUEST_TEMPLATE.md"
        threshold: "exists: true"
      - description: "CI runs on PRs"
        method: file_search
        pattern: "CI workflow triggered on pull_request events"
        threshold: "exists: true"
      - description: "Moderate PR volume"
        method: pr_analysis
        pattern: "Merged PRs in last 30 days"
        threshold: "count >= 5"
    quantitative: "PR template + CI on PRs + 5+ merged PRs/month"
  practiced:
    description: "Active AI-assisted PR workflow"
    requires: [exploring]
    criteria:
      - description: "High PR volume with structured descriptions"
        method: pr_analysis
        pattern: "Merged PRs in last 30 days"
        threshold: "count >= 15"
      - description: "AI PR review workflow active"
        method: file_search
        pattern: ".github/workflows/claude.yml triggered on pull_request"
        threshold: "exists: true"
      - description: "CURSOR_SUMMARY or AI descriptions in majority of PRs"
        method: pr_analysis
        pattern: "PRs with CURSOR_SUMMARY or AI attribution vs total PRs"
        threshold: "ratio >= 0.50 in last 30 days"
    quantitative: "15+ PRs/month, AI review workflow, >50% PRs with AI descriptions"
    temporal_check: "Last 5 merged PRs have structured AI-generated descriptions"
  confidence_threshold: 60
```

## Debugging complex state management

```yaml
id: ts_debug_state
type: opportunity
ecosystem: typescript
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Complex state management (Redux, Zustand, MobX, or custom state machines)
  - State flows across multiple modules or packages
  - History of state-related bugs (race conditions, stale state, incorrect selectors)

value: HIGH
value_context: "State management bugs are hard to trace across module boundaries; AI can follow state flow through selectors, reducers, and effects"
effort: Low
evidence_to_look_for:
  - store/, state/, or reducers/ directories
  - State management library in dependencies
  - Bug-fix commits mentioning "state", "race condition", "stale"
seen_in: []

learning_entry: |
  When debugging a state issue:
  1. Give Claude the state definition + the relevant selectors/reducers/effects
  2. Describe the symptom ("component shows stale data after X action")
  3. Ask it to trace the state update path and identify where the flow breaks
  AI traces mechanical state flows accurately — validate the root cause, then fix.

readiness_criteria:
  - criterion: "State management is centralized (not scattered useState)"
    type: Semi-objective
    check: "State management library in dependencies OR dedicated store/ directory"
  - criterion: "State types are defined"
    type: Objective
    check: "TypeScript interfaces or types for state shape exist"

kb_version: "6.2"

adoption_signals:
  active:
    - description: "AI-attributed commits referencing debugging or state fixes"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits with messages matching (debug|fix.*state|race condition|stale)"
      threshold: "count >= 2 in last 90 days"
    - description: "AI troubleshooting skill configured"
      method: file_search
      pattern: ".claude/skills/troubleshoot* or .claude/skills/debug* files"
      threshold: "exists: true"
    - description: "AI debug fix PRs merged"
      method: pr_analysis
      pattern: "PRs with AI co-authorship and title/body matching (debug|fix.*state|race condition|stale|selector)"
      threshold: "count >= 2 in last 90 days"
  partial:
    - description: "AI config exists but no debug-specific commits"
      method: file_search
      pattern: "CLAUDE.md or .cursorrules exists"
      threshold: "exists: true"
      verification_hint: "Config exists but check commit_scan for debug-path AI commits"
    - description: "1 AI commit fixing state issue"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits with messages matching (debug|fix.*state|race condition|stale)"
      threshold: "count == 1 in last 90 days"
  absent:
    - description: "No AI config files"
      method: file_search
      pattern: "CLAUDE.md, .cursorrules, .mcp.json, copilot-instructions.md, AGENTS.md"
      threshold: "none exist"
    - description: "No AI attribution in commits"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini|AI)"
      threshold: "count == 0 in last 180 days"
  anti_patterns:
    - description: "AI debugging commits that suppress errors rather than fix root cause"
      method: content_analysis
      pattern: "AI-attributed commits adding try/catch, error suppression, or // eslint-disable without fixing state flow"
      actual_state: "Absent — AI is masking bugs, not resolving them"
  confidence_threshold: 60

readiness_levels:
  undiscovered:
    description: "No centralized state management"
    criteria:
      - description: "No state management library in dependencies"
        method: file_search
        pattern: "redux, zustand, mobx, @ngrx/store, or xstate in package.json dependencies"
        threshold: "exists: false"
      - description: "No dedicated store or state directory"
        method: file_search
        pattern: "store/ or state/ or reducers/ directories"
        threshold: "count == 0"
  exploring:
    description: "State management exists but weakly typed"
    requires: [undiscovered]
    criteria:
      - description: "State management library in dependencies"
        method: file_search
        pattern: "redux, zustand, mobx, @ngrx/store, or xstate in package.json"
        threshold: "exists: true"
      - description: "Basic state types defined"
        method: file_search
        pattern: "TypeScript interface or type for state shape in store/ or state/ directories"
        threshold: "exists: true"
      - description: "No typed selectors or effect documentation"
        method: content_analysis
        pattern: "Typed selector functions or RxJS effect documentation in store/ files"
        threshold: "count == 0 in sampled files"
        sampling: "sample 5 store files"
    quantitative: "State lib + basic types, no typed selectors"
  practiced:
    description: "Well-structured state management ready for AI debugging"
    requires: [exploring]
    criteria:
      - description: "Dedicated store directory with organized modules"
        method: file_search
        pattern: "store/ directory with multiple subdirectories or module files"
        threshold: "count >= 3 module files or subdirectories"
      - description: "Typed selectors defined"
        method: content_analysis
        pattern: "Typed selector functions with explicit return types in store/ files"
        threshold: "found in >= 50% of sampled store files"
        sampling: "sample 5 store files"
      - description: "RxJS effects or async state flows documented"
        method: content_analysis
        pattern: "JSDoc or inline comments on effect/thunk/saga definitions"
        threshold: "found in >= 30% of effect files"
        sampling: "sample 5 effect files"
      - description: "State-related CI checks pass"
        method: file_search
        pattern: "CI workflow running type checks covering store/ directory"
        threshold: "exists: true"
    quantitative: "Store dir with 3+ modules, typed selectors in 50%+, documented effects, CI coverage"
    temporal_check: "Last 3 state-related bug fixes resolved via typed selectors, not workarounds"
  confidence_threshold: 60
```

---

## Detection Notes (from v5 scans)

- **NX/pnpm workspaces:** Detect via `pnpm-workspace.yaml` or `nx.json`. Commands like `npx nx affected --target=lint` don't contain tool names directly.
- **ESLint + Prettier:** Standard TS tooling. Detection: `.eslintrc.*`, `.prettierrc.*`, or config in package.json.
- **Strict mode:** `tsconfig.json` → `compilerOptions.strict === true`. This is a readiness prerequisite for most TS opportunities.
