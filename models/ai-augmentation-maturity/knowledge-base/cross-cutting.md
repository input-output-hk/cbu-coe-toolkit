# Cross-Cutting Patterns — All Ecosystems

## AI-assisted PR descriptions

```yaml
id: cc_pr_descriptions
type: opportunity
ecosystem: cross-cutting
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Active PR workflow (>5 PRs merged per month)
  - PR descriptions are inconsistent or thin
  - PR template exists but often not filled properly

value: MEDIUM
value_context: "Consistent PR descriptions improve review quality and historical traceability; AI can generate structured descriptions from diffs in seconds"
effort: Low
evidence_to_look_for:
  - PR template exists (.github/PULL_REQUEST_TEMPLATE.md)
  - Recent PRs with thin or no descriptions
  - High PR volume (>5/month)
seen_in: []

learning_entry: |
  Set up AI to draft PR descriptions from the diff before submitting.
  Template: What changed (bullet points), Why (link to issue), How to test,
  Breaking changes. Edit the draft — don't submit blindly.
  Tools: Claude Code generates these natively; GitHub Copilot has PR description feature.

readiness_criteria:
  - criterion: "PR template exists"
    type: Objective
    check: ".github/PULL_REQUEST_TEMPLATE.md exists"
  - criterion: "CI runs on PRs"
    type: Objective
    check: "CI workflow triggered on pull_request events"
```

## CLAUDE.md with substantive project context

```yaml
id: cc_claude_md_context
type: opportunity
ecosystem: cross-cutting
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Repo uses or plans to use AI tools (Claude, Copilot, Cursor)
  - No CLAUDE.md exists, or CLAUDE.md is generic/empty
  - Complex project with domain knowledge AI needs to work effectively

value: HIGH
value_context: "A substantive CLAUDE.md makes every AI interaction more effective — it's a one-time investment with compounding returns"
effort: Low
evidence_to_look_for:
  - CLAUDE.md absent
  - CLAUDE.md exists but <100 words or no project-specific content
  - CLAUDE.md missing coverage of: architecture, testing strategy, security-critical paths, build commands, coding conventions
seen_in:
  - repo: input-output-hk/lace-platform
    outcome: "comprehensive CLAUDE.md covering architecture, conventions, testing — measurably better AI interactions"

learning_entry: |
  Write a CLAUDE.md covering 6 categories:
  1. Architecture / module boundaries
  2. Coding conventions (naming, patterns, forbidden patterns)
  3. Testing strategy (what to test, how, which frameworks)
  4. Security-critical paths (what NOT to touch without review)
  5. Build and development commands
  6. Delivery workflow (branching, PR process, release)
  Start with one paragraph per category. Iterate as AI interactions reveal gaps.

readiness_criteria:
  - criterion: "AI tool in use or planned"
    type: Objective
    check: "Any AI config file exists, or AI-attributed commits present, or AI tool in dependencies"
```

## Trust boundary documentation (.aiignore)

```yaml
id: cc_aiignore_boundaries
type: opportunity
ecosystem: cross-cutting
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - High-assurance repo with security-critical code paths
  - AI tools in use without explicit trust boundaries
  - Crypto, consensus, financial, or authentication modules present

value: HIGH
value_context: "Explicit trust boundaries prevent AI from modifying security-critical code without human review — essential for high-assurance repos"
effort: Low
evidence_to_look_for:
  - .aiignore absent
  - Security-sensitive directories (crypto/, signing/, consensus/, auth/, keys/)
  - AI-attributed commits present but no .aiignore
seen_in: []

learning_entry: |
  Create .aiignore listing security-critical paths:
  - Cryptographic implementations
  - Consensus/protocol logic
  - Key management and signing
  - Financial state transitions
  - Authentication and authorization
  One path per line, same syntax as .gitignore.
  Review with security lead — they know which paths are critical.

readiness_criteria:
  - criterion: "Security-critical paths identifiable in file tree"
    type: Objective
    check: "Directories named crypto/, consensus/, auth/, signing/, or similar exist"
  - criterion: "AI tools in active use"
    type: Objective
    check: "AI-attributed commits or AI config files present"
```

## AI-assisted commit message quality

```yaml
id: cc_commit_messages
type: opportunity
ecosystem: cross-cutting
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Commit messages are inconsistent or uninformative
  - Conventional commits not adopted
  - High commit volume

value: LOW
value_context: "Better commit messages improve git bisect, changelog generation, and code archaeology — but low direct ROI compared to other opportunities"
effort: Low
evidence_to_look_for:
  - Commits with single-word messages ("fix", "update", "wip")
  - No conventional commit pattern (feat:, fix:, chore:)
  - High commit count (>50/month)
seen_in: []

learning_entry: |
  Configure AI to suggest commit messages from staged changes.
  Format: conventional commits (feat/fix/chore: concise description).
  Edit the suggestion — it captures the "what" well but often misses the "why."

readiness_criteria:
  - criterion: "Commit workflow exists (not direct pushes to main)"
    type: Objective
    check: "Branch protection enabled or PR-based workflow observed"
```

## Onboarding documentation generation

```yaml
id: cc_onboarding_docs
type: opportunity
ecosystem: cross-cutting
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Complex project with steep learning curve
  - CONTRIBUTING.md absent or thin
  - README focuses on usage, not development setup

value: MEDIUM
value_context: "Onboarding docs reduce time-to-contribution; AI can draft setup guides, architecture overviews, and contribution guides from existing code"
effort: Medium
evidence_to_look_for:
  - CONTRIBUTING.md absent or <50 words
  - README.md lacks development setup section
  - Complex build system (nix, multi-step setup)
  - New contributor PRs show common mistakes (indicates missing documentation)
seen_in: []

learning_entry: |
  Give Claude the repo structure + build config + CI workflow.
  Ask: "Draft a CONTRIBUTING.md covering: prerequisites, setup, build, test, PR process."
  Then: "Draft a development setup section for the README."
  Have a recent new contributor review the draft — they know what was confusing.

readiness_criteria:
  - criterion: "README exists with substantive content"
    type: Semi-objective
    check: "README.md >100 words of actual content"
  - criterion: "Build process is documented or scriptable"
    type: Semi-objective
    check: "Makefile, justfile, or build instructions in README/CONTRIBUTING"
```
