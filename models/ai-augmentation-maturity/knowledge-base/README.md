# AAMM v6 Knowledge Base

The KB holds opportunity patterns and readiness criteria that drive AAMM v6 assessments.

## Two Roles

### Role 1 — Opportunity Patterns
AI use-case patterns per ecosystem. Each pattern describes where AI can add value, under what conditions, and what evidence to look for. The scanner agent matches these against repo data to generate the Opportunity Map.

### Role 2 — Readiness Criteria
Per use-case type, validated criteria for assessing whether a repo is set up to make that opportunity effective. These are the ONLY criteria the agent uses for readiness assessment — no ad-hoc criteria.

## Entry Format

Each pattern is a YAML block in a markdown file:

```yaml
id: unique_snake_case_id
type: opportunity                       # opportunity | readiness | anti-pattern
ecosystem: haskell | typescript | rust | python | cross-cutting
status: seed | proposed | validated | deprecated
discovered: YYYY-MM-DD
updated: YYYY-MM-DD

# Role 1 fields (opportunity patterns)
applies_when:
  - condition 1
  - condition 2
value: HIGH | MEDIUM | LOW
value_context: "why this value level for this type of repo"
effort: High | Medium | Low
evidence_to_look_for:
  - specific file patterns or signals
seen_in:
  - repo: owner/name
    outcome: "what happened"
learning_entry: |
  Concrete instructions for a team to get started.

# Role 2 fields (readiness criteria)
readiness_criteria:
  - criterion: "what to check"
    type: Objective | Semi-objective
    check: "how to check it from repo data"
```

## Lifecycle

1. **Seed** (CoE manual): Initial patterns written by CoE before first learning scan. Status: `seed`.
2. **Learning scan proposals**: Agent proposes new patterns → `proposed` in `kb-proposals.md`.
3. **CoE review**: CoE validates proposals → `proposed` → `validated`.
4. **Enrichment**: Each scoring scan may propose updates to existing patterns (new `seen_in`, refined `applies_when`).
5. **Quarterly consolidation**: CoE reviews all patterns. Dedup, validate, deprecate stale patterns.

## File Conventions

- `ecosystems/{language}.md` — per-ecosystem opportunity patterns + readiness criteria
- `cross-cutting.md` — patterns that apply to all ecosystems
- `anti-patterns.md` — things that don't work (detection traps, false signals)

## Seed vs Validated

`seed` patterns are written by CoE from domain knowledge, before any scan validates them. They provide the initial vocabulary for learning scans. After a learning scan confirms a seed pattern with evidence, CoE promotes it to `validated`.

Learning scans without seed patterns have no anchor — they produce noise. The seed is small (5-10 per ecosystem) but critical.
