# KB Proposals — Learning Scan: input-output-hk/lace-platform
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: TypeScript | Agent: Claude Opus 4.6

---

## Seed Pattern Validation

### ts_contract_generation — VALIDATED

**Evidence:**
- Massive monorepo: 339 tsconfigs, 114 package.json files — extensive multi-package workspace
- Seed KB already references this repo: "30+ contract packages observed"
- `.claude/docs/PRINCIPLES.md`, `.claude/docs/ui-development.md`, `.claude/docs/development.md` — team has documented architectural patterns for AI consumption
- Active development with conventional commits (`style:`, `fix:`, `feat:` prefixes observed in recent commits)

**Confidence:** HIGH (seed already validated against this repo)

### ts_component_test_gen — VALIDATED

**Evidence:**
- `.claude/commands/test/analyze-mobile-integration.md` (11.5KB) and `.claude/commands/test/create-mobile-integration.md` (19.3KB) — dedicated AI commands for test creation
- These Claude commands are specifically designed for analyzing and generating integration tests
- 339 tsconfigs implies extensive component surface area

**Confidence:** HIGH (team has already built AI-powered test generation commands)

### ts_doc_generation — VALIDATED

**Evidence:**
- `.claude/docs/` directory with substantive documentation: `PRINCIPLES.md` (2.8KB), `ui-development.md` (4.3KB), `development.md` (939B), `cli-development.md` (1KB)
- These docs serve dual purpose: human reference and AI context
- Complex workspace with 114 packages — documentation debt is structurally inevitable at this scale

**Confidence:** MEDIUM (docs infrastructure exists for AI context but automated doc generation not confirmed)

### ts_pr_descriptions — VALIDATED

**Evidence:**
- Conventional commit messages confirmed in recent history: `style: improve UX...`, `fix: remove non-functional staking info icons...`
- `.claude/commands/git-commit.md` — AI-assisted commit workflow
- `.claude/gha-code-review-request.md` (1.3KB), `.claude/gha-implementation-request.md` — GitHub Actions integration with AI for code review and implementation
- Squash merge configured with commit messages

**Confidence:** HIGH (AI-assisted PR workflow actively in use)

### ts_debug_state — VALIDATED

**Evidence:**
- Crypto wallet with multi-chain support (Cardano + Midnight per topics)
- Mobile + extension + web targets (mobile integration test commands confirm multi-platform)
- `.claude/agents/` directory with 6 specialized research agents: `codebase-locator.md`, `confluence-page-researcher.md`, `figma-design-researcher.md`, `general-researcher.md`, `git-commit-researcher.md`, `jira-ticket-researcher.md`, `web-fetch-researcher.md`
- State flows across mobile native bridge, web views, and backend services

**Confidence:** HIGH (multi-platform wallet with complex state is the canonical use case)

---

## Cross-Cutting Patterns

### cc_claude_md_context — VALIDATED (exemplar)

**Evidence:**
- Comprehensive `.claude/` directory structure:
  - `agents/` — 6 specialized research agents
  - `commands/` — custom slash commands including `git-commit.md`, `plan.md`, `prompt-engineer.md`, `research.md`, test commands
  - `docs/` — architectural principles, development guides
  - `settings.json` — Claude Code configuration
  - `gha-code-review-request.md`, `gha-implementation-request.md` — CI/AI integration
- 1 AI-attributed commit confirms active usage
- This is the most mature AI configuration observed across all scanned repos

**This repo should be the `seen_in` exemplar for cc_claude_md_context in the KB.**

### cc_aiignore_boundaries — CONFIRMED APPLICABLE

- Crypto wallet handling private keys, transaction signing, seed phrases
- Multi-chain (Cardano + Midnight) with different security models
- No `.aiignore` found despite extensive `.claude/` configuration
- Risk: AI agents have access to all code paths including security-critical wallet operations

---

## New Pattern Proposals

### AI agent specialization via .claude/agents/

```yaml
id: ts_claude_agent_specialization
type: opportunity
ecosystem: cross-cutting
status: proposed
discovered: 2026-03-30

applies_when:
  - Large monorepo with distinct domain areas
  - Team actively using Claude Code
  - Research tasks span multiple external systems (Jira, Confluence, Figma)

value: HIGH
value_context: "Specialized agents reduce hallucination by constraining context; lace-platform has 6 agents each focused on one domain"
evidence_to_look_for:
  - .claude/agents/ directory with multiple .md files
  - Each agent scoped to a specific research domain
seen_in:
  - repo: input-output-hk/lace-platform
    outcome: "6 specialized agents for codebase, Confluence, Figma, general, git, Jira, and web research"
```

### AI-integrated CI via GitHub Actions

```yaml
id: ts_gha_ai_integration
type: opportunity
ecosystem: cross-cutting
status: proposed
discovered: 2026-03-30

applies_when:
  - CI/CD via GitHub Actions
  - AI tools configured for the repo
  - Code review or implementation tasks triggerable from CI

value: MEDIUM
value_context: "CI-triggered AI review catches issues before human review; reduces review cycle time"
evidence_to_look_for:
  - .claude/gha-*.md files defining AI behavior in CI context
  - GitHub Actions workflows that invoke AI tools
seen_in:
  - repo: input-output-hk/lace-platform
    outcome: "gha-code-review-request.md and gha-implementation-request.md define AI behavior for CI-triggered tasks"
```

---

## Summary

| Pattern | Status | Confidence |
|---------|--------|------------|
| ts_contract_generation | VALIDATED | HIGH |
| ts_component_test_gen | VALIDATED | HIGH |
| ts_doc_generation | VALIDATED | MEDIUM |
| ts_pr_descriptions | VALIDATED | HIGH |
| ts_debug_state | VALIDATED | HIGH |
| cc_claude_md_context | VALIDATED (exemplar) | HIGH |
| cc_aiignore_boundaries | APPLICABLE — opportunity | HIGH |

**Key finding:** lace-platform is the most AI-mature repo in the scanned portfolio. The `.claude/` directory structure (agents, commands, docs, settings, GHA integration) represents a best practice that should be documented as the reference implementation for cc_claude_md_context. The gap is `.aiignore` for security-critical wallet code paths.
