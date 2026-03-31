# KB Proposals — Learning Scan: HarmonicLabs/pluts-emulator
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: TypeScript | Agent: Claude Opus 4.6

---

## Seed Pattern Validation

### ts_contract_generation — NOT APPLICABLE

Single-package repo (1 tsconfig, 1 package.json). No multi-package workspace, no contract boundaries. Source is a focused emulator library: `src/Emulator.ts` (42KB — the core), `src/queue.ts`, `src/types/`, `src/utils/`.

### ts_component_test_gen — VALIDATED

**Evidence:**
- Jest configured: `jest.config.cjs` (7.2KB — substantial configuration), `babel.config.cjs`
- Test files exist: `tests/emulator.test.ts` (14KB), `tests/experiments.test.ts` (2.7KB), `tests/helper.test.ts` (1KB), `tests/queue.test.ts` (2.6KB)
- 4 test files covering the 4 main source modules — good existing coverage pattern
- No CI workflow — tests are local-only

**Gaps observed:**
- `src/Emulator.ts` is 42KB — a single large file that likely has complex logic needing more granular tests
- `src/experiment.ts` (2KB) exists alongside `tests/experiments.test.ts` — active experimentation area
- No CI means no automated test enforcement

**Confidence:** MEDIUM (test infra exists but no CI to enforce)

### ts_doc_generation — VALIDATED

**Evidence:**
- `README.md` (7KB) — substantive documentation exists
- `CHANGELOG.md` (3.2KB) — maintained changelog
- `TODO.md` (25KB) — extensive roadmap/backlog document
- Core `src/Emulator.ts` at 42KB is a complex module that would benefit from JSDoc

**Confidence:** MEDIUM (large core module likely lacks inline documentation)

### ts_pr_descriptions — NOT APPLICABLE

No PR template. No CI workflows. Low PR volume (6 open issues, 1 fork, last push 2026-01-08). Likely single-developer repo.

### ts_debug_state — NOT APPLICABLE

Emulator is a library, not a stateful application. It emulates Cardano ledger state transitions, but this is domain-specific logic, not UI state management.

---

## Cross-Cutting Patterns

### cc_claude_md_context — CONFIRMED ABSENT

No CLAUDE.md. 0 AI commits. Small focused library — a CLAUDE.md would help given the 42KB core file with complex Cardano ledger emulation logic, but the team shows no AI adoption signals.

### cc_aiignore_boundaries — NOT APPLICABLE

No security-critical paths. Emulator is a testing tool, not a production signing/key management component. No AI usage to boundary-protect against.

---

## New Pattern Proposals

None.

---

## Summary

| Pattern | Status | Confidence |
|---------|--------|------------|
| ts_contract_generation | NOT APPLICABLE | - |
| ts_component_test_gen | VALIDATED | MEDIUM |
| ts_doc_generation | VALIDATED | MEDIUM |
| ts_pr_descriptions | NOT APPLICABLE | - |
| ts_debug_state | NOT APPLICABLE | - |
| cc_claude_md_context | ABSENT — low priority | MEDIUM |
| cc_aiignore_boundaries | NOT APPLICABLE | - |

**Key finding:** Small, focused emulator library with good test coverage patterns but no CI and no AI adoption. The 42KB `Emulator.ts` and 25KB `TODO.md` suggest a complex, actively designed module where AI-assisted documentation and test expansion could add value, but the team shows no AI readiness signals.
