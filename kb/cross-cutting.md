# Cross-Cutting Patterns

## CLAUDE.md content-category coverage

```yaml
source: iog-scan
repos: [lace-platform, cardano-ledger]
category: governance
status: validated
discovered: 2026-03-20
updated: 2026-03-27
```

Effective CLAUDE.md covers: architecture/module boundaries, coding conventions,
testing standards, security-critical areas, build commands, delivery workflow.
Generic CLAUDE.md without project context = minimal AI value.

**Recommendation template:**
"Your CLAUDE.md covers [N]/6 categories. Add: [missing]. Effort: Low. Impact: HIGH."

**Applicability:** All repos with AI config.

## .aiignore on critical paths

```yaml
source: iog-scan
repos: []
category: workflow
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

High-assurance repos must define trust boundaries via .aiignore listing
critical paths (crypto/, signing/, formal-spec/, key-management/).

**Recommendation template:**
"Add .aiignore listing [critical paths]. Effort: Low. Impact: HIGH."

**Applicability:** High-assurance repos.

## Undocumented workflow = AI cannot follow it

```yaml
source: iog-scan
repos: []
category: workflow
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

If PR process, branching strategy, and trust boundaries are not documented
(CONTRIBUTING.md, PR templates, CODEOWNERS), AI cannot respect them.

**Applicability:** All repos.
