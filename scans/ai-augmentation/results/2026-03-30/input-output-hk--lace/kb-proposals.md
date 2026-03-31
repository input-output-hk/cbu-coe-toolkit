# KB Proposals — Learning Scan: input-output-hk/lace
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: TypeScript | Agent: Claude Opus 4.6

---

## Seed Pattern Validation

### ts_contract_generation — NOT APPLICABLE

Lace is a browser extension monorepo (Yarn workspaces, 20 tsconfigs, 11 package.json) but the actual multi-package contract architecture has migrated to lace-platform. The lace repo retains the extension shell (`src/popup-bundle.js`, `src/sw-bundle.js`, `assets/popup.html`) and CI/release workflows. No evidence of typed contract packages or Zod/io-ts schemas in the remaining tree.

### ts_component_test_gen — VALIDATED

**Evidence:**
- CI workflow `.github/workflows/ci.yml` (15.7KB) includes unit test action `.github/actions/test/unit/action.yml`
- E2E test workflow `.github/workflows/e2e-tests-linux-split.yml` (10.7KB)
- Test infrastructure exists: unit and E2E actions configured
- 20 tsconfigs across packages suggests multiple component packages

**Gaps observed:**
- Cannot determine component-to-test ratio from tree alone, but CI test infrastructure is established
- SonarCloud configured (`sonar-project.properties`) for coverage tracking

**Confidence:** MEDIUM (CI confirms test infra, but component coverage unknown without deeper sampling)

### ts_doc_generation — NOT APPLICABLE

No evidence of TypeDoc, JSDoc tooling, or doc generation in dependencies. The repo has `ARCHITECTURE.md` for human documentation but no automated doc generation pipeline.

### ts_pr_descriptions — VALIDATED

**Evidence:**
- PR template exists: `.github/pull_request_template.md` (509 bytes)
- Husky commit-msg hook: `.husky/commit-msg` (conventional commits enforcement)
- Active PR workflow with CI on PRs (ci.yml, e2e-tests)
- Labeler configured: `.github/labeler.yml`

**Confidence:** HIGH

### ts_debug_state — VALIDATED

**Evidence:**
- Lace is a crypto wallet with complex state (wallet state, transaction state, DApp connector state)
- Multiple packages managing state across extension popup, service worker, and DApp contexts
- `.mcp.json` (547 bytes) suggests MCP integration — indicates complex tooling context

**Gaps observed:**
- Cannot confirm specific state management library from tree alone
- State flows across browser extension contexts (popup, background, content scripts) add complexity beyond typical React state

**Confidence:** MEDIUM (wallet domain implies complex state, but specific library not confirmed)

---

## Cross-Cutting Patterns

### cc_claude_md_context — CONFIRMED ABSENT

No CLAUDE.md found. However, `.mcp.json` exists (MCP server config), indicating some AI tooling awareness. 0 AI-attributed commits. This is a gap: a wallet extension with complex domain knowledge (Cardano, DApp connector, multi-chain) would benefit substantially from a CLAUDE.md.

### cc_aiignore_boundaries — CONFIRMED APPLICABLE

Security-critical code paths exist in a crypto wallet:
- Transaction signing, key management (handled by lace-platform SDK, but extension still handles message passing)
- DApp connector (cross-origin security boundary)
- No `.aiignore` exists despite `.mcp.json` indicating AI tool usage intent

---

## New Pattern Proposals

None. The lace repo is primarily an extension shell; the substantive TypeScript patterns apply more strongly to lace-platform.

---

## Summary

| Pattern | Status | Confidence |
|---------|--------|------------|
| ts_contract_generation | NOT APPLICABLE | - |
| ts_component_test_gen | VALIDATED | MEDIUM |
| ts_doc_generation | NOT APPLICABLE | - |
| ts_pr_descriptions | VALIDATED | HIGH |
| ts_debug_state | VALIDATED | MEDIUM |
| cc_claude_md_context | ABSENT — opportunity | HIGH |
| cc_aiignore_boundaries | APPLICABLE — opportunity | HIGH |
