# KB Proposals — Learning Scan: input-output-hk/sc-fvt
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: Lean | Agent: Claude Opus 4.6

## Cross-Cutting Patterns

### cc_claude_md_context
**Status: NOT PRESENT**
No `CLAUDE.md` found. Private repo (formal verification tooling, 266 files). AI agent context would help given the specialized Lean4 codebase and formal verification domain. 2 AI-attributed commits indicate early AI adoption.

### cc_aiignore_boundaries
**Status: NOT PRESENT**
No `.aiignore` found. As a private repo doing formal verification of smart contracts, security boundaries for AI agents would be prudent -- proofs and verification artifacts may have integrity requirements.

### cc_pr_descriptions
**Status: ACTIVE**
Active PR workflow with 237 open issues and structured issue management. PR template present at `.github/pull_request_template.md` (916 bytes). Multiple issue templates (idea, epic, story, PI objective, free-form). CI workflow at `.github/workflows/ci-linux.yaml`. Recent PR #275 merged 2025-11-24. Also has `project-adder.yaml` workflow for GitHub Projects integration.

### cc_onboarding_docs
**Status: PRESENT**
`CONTRIBUTING.md` found in tree. Comprehensive issue template system with structured templates for ideas, epics, stories, and PI objectives -- indicates mature project management practices.

## New Pattern Proposals

### Proposed: lean_formal_verification_context
Lean4 repos doing formal verification have unique AI assistance patterns: proof automation, tactic suggestions, and CEK machine modeling (latest PR: "macrolessCEK"). AI tools could assist with proof search but must not compromise proof validity. This is a domain-specific pattern worth tracking.

### Proposed: cc_project_management_maturity
This repo has unusually structured issue templates (idea -> epic -> story -> PI objective), a project-adder workflow, and discussions enabled. This level of project management tooling in GitHub could be a cross-cutting signal for team maturity.

## Summary
| Pattern | Status |
|---|---|
| cc_claude_md_context | Not present |
| cc_aiignore_boundaries | Not present |
| cc_pr_descriptions | Active (PR template, structured issue templates, CI) |
| cc_onboarding_docs | Present (CONTRIBUTING.md, issue templates) |
