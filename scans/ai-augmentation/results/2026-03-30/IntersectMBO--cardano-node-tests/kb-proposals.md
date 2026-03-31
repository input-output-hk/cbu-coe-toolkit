# KB Proposals — Learning Scan: IntersectMBO/cardano-node-tests
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: Python | Agent: Claude Opus 4.6

---

## Seed Pattern Validation

### py_test_generation — VALIDATED

**Evidence:**
- This IS a test repo: "System and end-to-end (E2E) tests for cardano-node"
- pytest infrastructure confirmed: 6 conftest.py files (extensive fixture infrastructure)
- `pyproject.toml` at root
- Multiple CI workflows for test execution: `nightly.yaml`, `nightly_cli.yaml`, `nightly_dbsync.yaml`, `nightly_pv11.yaml`, `nightly_upgrade.yaml`, `regression.yaml`, `regression-dbsync.yaml`, `upgrade.yaml`
- Regression test reusable workflow: `regression_reusable.yaml`, `upgrade_reusable.yaml`
- Test execution scripts: `.github/run_tests.sh` (6.3KB), `.github/regression.sh` (7.6KB)
- `Makefile` (1.7KB) — build/test commands
- Pre-commit hooks: `.pre-commit-config.yaml`

**Gaps observed:**
- The repo itself is tests — the question is whether AI can generate MORE tests for new cardano-node features
- `agent_docs/new_tests.md` (1.1KB) — the team has already documented how AI agents should create new tests
- `.github/reqs_coverage.sh`, `.github/cli_coverage.sh` — coverage tracking scripts

**Confidence:** HIGH (test-focused repo with mature infrastructure and explicit AI agent documentation for test creation)

### py_type_annotations — VALIDATED

**Evidence:**
- Python project with `pyproject.toml`
- `.pre-commit-config.yaml` — code quality tooling configured
- `code_checks.yaml` CI workflow — likely includes type checking or linting
- Mature project (created 2020, 59 stars, 29 forks)

**Gaps observed:**
- Cannot confirm mypy configuration from tree alone
- `ruff` or similar modern tooling status unknown

**Confidence:** MEDIUM (pre-commit and code checks suggest typing awareness, but mypy not confirmed)

### py_docstring_generation — VALIDATED

**Evidence:**
- `agent_docs/` directory with 5 documentation files for AI agents:
  - `commits.md` (207B) — commit conventions
  - `fixtures_caching.md` (1.8KB) — fixture patterns
  - `new_tests.md` (1.1KB) — how to write new tests
  - `resource_management.md` (3.7KB) — resource handling patterns
  - `running_tests.md` (437B) — test execution guide
  - `subtests.md` (2.6KB) — subtest patterns
- These agent_docs serve as both human and AI documentation — but source code docstrings may be sparse

**Confidence:** MEDIUM (documentation culture exists via agent_docs, but inline docstring coverage unknown)

### py_hypothesis_testing — VALIDATED

**Evidence:**
- E2E test suite for cardano-node — tests exercise complex protocol behavior
- 6 conftest.py files — rich fixture infrastructure capable of supporting property-based tests
- Nightly test suites run full regression — infrastructure can handle hypothesis-style tests
- Protocol version testing (`nightly_pv11.yaml`), upgrade testing (`upgrade.yaml`, `nightly_upgrade.yaml`) — complex input domains

**Gaps observed:**
- Cannot confirm hypothesis in dependencies from tree alone
- The test domain (cardano-node E2E) may be better suited to scenario-based testing than property-based
- `ai_run.sh` (1.2KB) — script for AI-driven test runs, suggesting the team is already exploring AI-assisted testing

**Confidence:** MEDIUM (infrastructure supports it, but E2E testing may not be the ideal hypothesis application)

---

## Cross-Cutting Patterns

### cc_claude_md_context — VALIDATED (minimal)

**Evidence:**
- `CLAUDE.md` exists but is only 36 bytes — effectively a placeholder (likely just `# CLAUDE.md` or a redirect)
- `AGENTS.md` (2KB) — more substantive agent instructions
- `agent_docs/` directory with 5 files totaling ~10KB — rich AI context documentation
- `ai_run.sh` (1.2KB) — AI-integrated test execution script

The team has invested significantly in AI agent documentation (`AGENTS.md` + `agent_docs/` + `ai_run.sh`) but the CLAUDE.md itself is minimal. The substantive content lives in `AGENTS.md` and `agent_docs/`. This is an interesting pattern: the team has built comprehensive AI documentation but distributed across multiple files rather than consolidating in CLAUDE.md.

### cc_aiignore_boundaries — NOT APPLICABLE

This is a test repo, not production code. No cryptographic, signing, or consensus-critical code paths. Tests may exercise security-sensitive cardano-node features, but the test code itself is not security-critical.

---

## New Pattern Proposals

### Distributed AI agent documentation (agent_docs/ pattern)

```yaml
id: py_agent_docs_pattern
type: opportunity
ecosystem: cross-cutting
status: proposed
discovered: 2026-03-30

applies_when:
  - Team uses AI agents for code generation (especially test generation)
  - Repo has domain-specific conventions that AI needs to follow
  - Multiple distinct areas of concern (fixtures, resources, subtests, etc.)

value: HIGH
value_context: "Dedicated agent_docs/ directory with per-topic files gives AI agents targeted context without overloading a single CLAUDE.md"
evidence_to_look_for:
  - agent_docs/ or similar directory with .md files
  - AGENTS.md at repo root
  - AI execution scripts (ai_run.sh)
  - Topics: test patterns, resource management, fixture caching
seen_in:
  - repo: IntersectMBO/cardano-node-tests
    outcome: "AGENTS.md + agent_docs/ with 5 topic files + ai_run.sh. 0 AI commits despite infrastructure — suggests the tooling is being set up for adoption."
```

### AI-assisted E2E test generation for blockchain nodes

```yaml
id: py_e2e_node_testing
type: opportunity
ecosystem: python
status: proposed
discovered: 2026-03-30

applies_when:
  - E2E test suite for a blockchain node or protocol implementation
  - Tests involve cluster management, transaction submission, governance actions
  - New protocol features require new test scenarios regularly

value: HIGH
value_context: "Blockchain node E2E tests are repetitive to write but critical for protocol correctness; AI can generate test scenarios from protocol specifications"
evidence_to_look_for:
  - conftest.py with cluster fixtures
  - Test files organized by protocol feature (governance, staking, delegation)
  - agent_docs/ with test writing conventions
  - Node upgrade test workflows
seen_in:
  - repo: IntersectMBO/cardano-node-tests
    outcome: "6 conftest.py files, nightly/regression/upgrade test workflows, agent_docs/new_tests.md with explicit instructions for AI test generation"
```

---

## Summary

| Pattern | Status | Confidence |
|---------|--------|------------|
| py_test_generation | VALIDATED | HIGH |
| py_type_annotations | VALIDATED | MEDIUM |
| py_docstring_generation | VALIDATED | MEDIUM |
| py_hypothesis_testing | VALIDATED | MEDIUM |
| cc_claude_md_context | VALIDATED (minimal CLAUDE.md, rich agent_docs/) | HIGH |
| cc_aiignore_boundaries | NOT APPLICABLE | - |

**Key finding:** cardano-node-tests has the most intentional AI agent infrastructure of any scanned repo: `AGENTS.md` + `agent_docs/` (5 topic files) + `ai_run.sh` + `CLAUDE.md` (placeholder). Despite this infrastructure, there are 0 AI-attributed commits — the tooling appears to be in setup/adoption phase. The `agent_docs/` pattern (distributed per-topic AI documentation) is a novel approach worth capturing in the KB as an alternative to monolithic CLAUDE.md. The team has explicitly documented how AI should write tests (`agent_docs/new_tests.md`), manage fixtures (`agent_docs/fixtures_caching.md`), and handle resources (`agent_docs/resource_management.md`).
