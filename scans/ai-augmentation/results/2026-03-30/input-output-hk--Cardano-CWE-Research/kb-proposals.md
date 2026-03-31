# KB Proposals — Learning Scan: input-output-hk/Cardano-CWE-Research
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: unknown (Markdown/research) | Agent: Claude Opus 4.6

## Cross-Cutting Patterns

### cc_claude_md_context
**Status: NOT PRESENT**
No `CLAUDE.md`. Research repository (33 files) for the Plu-stan analyzer -- primarily Markdown documentation of CWE rules and audit findings.

### cc_aiignore_boundaries
**Status: NOT PRESENT**
No `.aiignore`. Content is research documentation (audit reports, CWE rules). No security-sensitive code, but audit findings in `audits/` (Aiken.md at 128 KB, Plinth.md, Plutarch.md) contain vulnerability research that should be handled carefully.

### cc_pr_descriptions
**Status: MINIMAL**
2 PRs total (latest: #2 "Plinth rules", merged 2026-02-02). No PR template, no CI workflows, no issue templates. Low activity.

### cc_onboarding_docs
**Status: MINIMAL**
`README.md` present (742 bytes). `LICENSE` present (Apache-2.0). No `CONTRIBUTING.md`, no `CODEOWNERS`.

## New Pattern Proposals

### Proposed: cc_security_research_sensitivity
This repo contains detailed vulnerability research (CWE rules for Cardano smart contract languages) and audit reports totaling 190+ KB. AI agents working with security-vulnerability documentation need sensitivity boundaries -- `.aiignore` or equivalent -- to prevent accidental exposure of exploit details in AI-generated outputs.

## Summary
| Pattern | Status |
|---|---|
| cc_claude_md_context | Not present |
| cc_aiignore_boundaries | Not present (recommended for audit content) |
| cc_pr_descriptions | Minimal (2 PRs, no template) |
| cc_onboarding_docs | Minimal (README only) |
