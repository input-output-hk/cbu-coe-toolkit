# AAMM Knowledge Base

Accumulated knowledge of the CoE — patterns, anti-patterns, and best practices
from IOG portfolio scans and external exemplary repos.

## Format

Each ecosystem file contains multiple patterns. Each pattern is a level-2 heading
with structured metadata in a fenced block:

    ## Pattern Title

    ```yaml
    source: iog-scan | external | ecosystem-standard
    repos: [cardano-ledger, ouroboros-consensus]
    category: structure | clarity | purpose | workflow | safety-net | adoption | governance | adoption-detection
    status: validated | proposed | needs-revalidation | deprecated
    discovered: 2026-03-27
    updated: 2026-03-27
    ```

    Description of the pattern with evidence.

    **Recommendation template:** "..."
    **Applicability:** Which repos/ecosystems this applies to.

## Lifecycle

1. Scanner agent proposes new patterns after each scan → `proposed`
2. CoE lead reviews → `proposed` → `validated`
3. Scanner re-validates on subsequent scans → stays `validated` or → `needs-revalidation`
4. External patterns expire after 6 months → `needs-revalidation`
5. CoE quarterly review cleans up → `deprecated` or re-validated

## Consolidation (quarterly)

KB files grow with each scan. Quarterly, CoE lead runs consolidation:

1. **Dedup:** Merge patterns that describe the same thing with different wording
2. **Validate:** Re-check `validated` patterns against current repo state
3. **Expire:** Mark `needs-revalidation` for patterns whose source repos changed
4. **Prune:** Move `deprecated` patterns to a `kb/archive/` directory
5. **Split:** If an ecosystem file exceeds 200 patterns, split by category
   (e.g., `haskell-testing.md`, `haskell-structure.md`)

## File Conventions

- `kb/ecosystems/{language}.md` — per-ecosystem patterns
- `kb/cross-cutting.md` — patterns that apply to all ecosystems
- `kb/anti-patterns.md` — things that don't work
- `kb/external/{repo-name}.md` — patterns from external exemplary repos
- `kb/archive/` — deprecated patterns (for history)
