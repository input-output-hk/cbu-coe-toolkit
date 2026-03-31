# KB Proposals — Learning Scan: input-output-hk/CHA-react-FE-template
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: TypeScript | Agent: Claude Opus 4.6

---

## Seed Pattern Validation

### ts_contract_generation — NOT APPLICABLE

Single-package template repo (`starter_app/`) with 1 tsconfig.json and 1 package.json. No multi-package workspace, no contract packages, no typed API boundaries. Template repo derived from `plutus-high-assurance-template`.

### ts_component_test_gen — NOT APPLICABLE

Template contains `starter_app/src/App.test.tsx` (boilerplate CRA test) and `starter_app/src/setupTests.ts`. This is scaffolding, not a codebase with real components needing test generation. `is_template: true` — this repo exists to bootstrap new projects, not to develop actively.

### ts_doc_generation — NOT APPLICABLE

Small template repo. No complex hooks, utilities, or generic signatures requiring documentation. Last pushed 2025-12-09 — low activity.

### ts_pr_descriptions — NOT APPLICABLE

PR template exists (`.github/pull_request_template.md`, 916 bytes) and issue templates are well-structured (epic, story, idea, free-form). However, this is a template repo with minimal active development (2 open issues, 0 forks, last push 3+ months ago). The PR template is part of the template itself, not evidence of active PR workflow.

### ts_debug_state — NOT APPLICABLE

Boilerplate React app (`starter_app/src/App.tsx`). No state management beyond React defaults.

---

## Cross-Cutting Patterns

### cc_claude_md_context — NOT APPLICABLE

No CLAUDE.md. Template repo with no AI config. 0 AI-attributed commits. Low value target: templates benefit more from good documentation than AI context files.

### cc_aiignore_boundaries — NOT APPLICABLE

No security-critical code. Template scaffolding only. CI is limited to `sync_template.yml` (syncing from parent template).

---

## New Pattern Proposals

None.

---

## Summary

| Pattern | Status |
|---------|--------|
| ts_contract_generation | NOT APPLICABLE |
| ts_component_test_gen | NOT APPLICABLE |
| ts_doc_generation | NOT APPLICABLE |
| ts_pr_descriptions | NOT APPLICABLE |
| ts_debug_state | NOT APPLICABLE |
| cc_claude_md_context | NOT APPLICABLE |
| cc_aiignore_boundaries | NOT APPLICABLE |

**Key finding:** This is a dormant template repo (is_template=true, last pushed 2025-12-09, 0 forks). No AI augmentation patterns are applicable. The well-structured issue templates (`.github/ISSUE_TEMPLATE/`) are the most notable feature but are part of the template output, not AI opportunities.
