# KB Proposals — Learning Scan: HarmonicLabs/pebble-lsp
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: TypeScript | Agent: Claude Opus 4.6

---

## Seed Pattern Validation

### ts_contract_generation — NOT APPLICABLE

LSP (Language Server Protocol) extension with client/server architecture (5 tsconfigs, 3 package.json — typical for VSCode extension with client + server + root). No typed API contract packages in the monorepo sense. The "contract" between client and server is the LSP protocol itself.

### ts_component_test_gen — NOT APPLICABLE

VSCode extension repo. No evidence of test files or test configuration in the tree. The `.vscode/launch.json` and `.vscode/tasks.json` are for extension debugging, not testing. No jest.config, vitest.config, or test directories found. This is a gap, but without any test infrastructure, the pattern precondition ("test runner configured") is not met.

### ts_doc_generation — VALIDATED

**Evidence:**
- `README.md` (3.9KB) — user-facing documentation exists
- `CONTRIBUTING.md` (4.3KB) — contributor documentation exists
- `CODE_OF_CONDUCT.md` (3.4KB) — community standards
- LSP servers have complex APIs (completions, diagnostics, hover, etc.) that benefit from inline documentation
- `.vscodeignore` (463 bytes) indicates packaged extension

**Gaps observed:**
- No evidence of TypeDoc or JSDoc tooling
- LSP handler functions likely need documentation for contributors

**Confidence:** LOW (documentation exists at repo level but inline code doc status unknown)

### ts_pr_descriptions — NOT APPLICABLE

No PR template. No CI workflows. 0 open issues, 0 forks. Appears to be early-stage or single-developer project.

### ts_debug_state — NOT APPLICABLE

LSP extensions manage minimal state (document state is owned by the editor). No complex state management patterns.

---

## Cross-Cutting Patterns

### cc_claude_md_context — CONFIRMED ABSENT

No CLAUDE.md. 0 AI commits. No AI config files. LSP development is a niche domain where CLAUDE.md could help (LSP protocol nuances, Pebble language specifics), but no AI adoption signals.

### cc_aiignore_boundaries — NOT APPLICABLE

No security-critical code. Language tooling, not financial/crypto logic.

---

## New Pattern Proposals

None.

---

## Summary

| Pattern | Status | Confidence |
|---------|--------|------------|
| ts_contract_generation | NOT APPLICABLE | - |
| ts_component_test_gen | NOT APPLICABLE | - |
| ts_doc_generation | VALIDATED | LOW |
| ts_pr_descriptions | NOT APPLICABLE | - |
| ts_debug_state | NOT APPLICABLE | - |
| cc_claude_md_context | ABSENT — low priority | LOW |
| cc_aiignore_boundaries | NOT APPLICABLE | - |

**Key finding:** Early-stage LSP extension with no CI, no tests, and no AI adoption. The repo has good community documentation (CONTRIBUTING.md, CODE_OF_CONDUCT.md) but lacks development infrastructure. Most TS patterns are not applicable due to missing preconditions (no test runner, no CI, no multi-package contracts).
