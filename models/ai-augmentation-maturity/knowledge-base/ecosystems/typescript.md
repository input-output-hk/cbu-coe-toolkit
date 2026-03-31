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
```

---

## Detection Notes (from v5 scans)

- **NX/pnpm workspaces:** Detect via `pnpm-workspace.yaml` or `nx.json`. Commands like `npx nx affected --target=lint` don't contain tool names directly.
- **ESLint + Prettier:** Standard TS tooling. Detection: `.eslintrc.*`, `.prettierrc.*`, or config in package.json.
- **Strict mode:** `tsconfig.json` → `compilerOptions.strict === true`. This is a readiness prerequisite for most TS opportunities.
