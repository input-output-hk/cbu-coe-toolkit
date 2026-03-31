# KB Proposals — Learning Scan: input-output-hk/CardanoBlaster
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: Lean | Agent: Claude Opus 4.6

## Cross-Cutting Patterns

### cc_claude_md_context
**Status: NOT PRESENT**
No `CLAUDE.md`. Private repo (147 files, 0 stars). Early-stage automated formal verification tool for Cardano smart contracts.

### cc_aiignore_boundaries
**Status: NOT PRESENT**
No `.aiignore`. Private repo with formal verification proofs. As this matures, `.aiignore` boundaries around proof artifacts would be prudent.

### cc_pr_descriptions
**Status: MINIMAL**
No PR template. No open issues. Commits pushed directly to main (e.g., "Fix the pair issue" on 2026-03-02, unsigned). Single CI workflow: `.github/workflows/lean_action_ci.yml` (200 bytes -- minimal). No structured PR workflow observed.

### cc_onboarding_docs
**Status: MINIMAL**
`README.md` present. No `CONTRIBUTING.md`, no `CODEOWNERS`, no issue templates. Has `.gitattributes`. Created 2026-02-22 -- very new repo.

## New Pattern Proposals

### Proposed: lean_cardano_smart_contract_verification
CardanoBlaster applies Lean4 formal verification to Cardano smart contracts (Examples/HelloWorld with Properties.lean). This pattern of property-based verification of blockchain smart contracts is a novel AI-augmentation surface: AI could generate property specifications or assist with proof obligations.

## Summary
| Pattern | Status |
|---|---|
| cc_claude_md_context | Not present |
| cc_aiignore_boundaries | Not present |
| cc_pr_descriptions | Minimal (no PR template, direct pushes) |
| cc_onboarding_docs | Minimal (README only, new repo) |
