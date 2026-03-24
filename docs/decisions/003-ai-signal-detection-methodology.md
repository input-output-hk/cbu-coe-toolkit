# ADR-003: Multi-Layer AI Signal Detection Methodology

**Date:** 2026-03-20
**Status:** Accepted
**Confidence:** High

## Context

During the first LACE v4 assessment, single-pass detection missed 3 significant AI signals:

1. **Cursor attribution in PR body** — not in commit metadata, only in PR description text.
2. **Copilot Coding Agent PR** — closed (not merged), absent from the recent-merged sample.
3. **Submodule AI infrastructure** — `.claude/` in a submodule, invisible from parent repo's tree API.

These represent the 3 main ways AI signals hide: in PR text (not structured metadata), in non-merged PRs (outside the sample window), and in linked repositories (submodules).

## Decision drivers

- False negatives undermine trust in scores — repos with real AI activity shouldn't score 0
- Organic AI adoption doesn't follow institutional patterns (individual developer tools, experimental agent PRs)
- Must stay within 50 API calls/repo budget

## Considered alternatives

| Option | Pros | Cons |
|---|---|---|
| **5-layer detection** | Catches all known signal types, within budget | Slightly more complex, heuristic PR body matching |
| Tree + commits only | Simple, low API cost | Misses 3 categories of real signals |
| Full repository mining | Maximum coverage | Exceeds API budget, slow |

## Decision

Adopt a 5-layer detection methodology:

| Layer | What | API cost |
|---|---|---|
| **1. Tree** | AI config files (CLAUDE.md, .mcp.json, .cursor/rules) | 0 (uses existing tree) |
| **2. Commits** | `Co-authored-by` patterns in recent 50 commits | 1 call |
| **3. PR author** | Bot-authored PRs via Search API (copilot-swe-agent, coderabbit) | 1–3 calls |
| **4. PR body** | AI tool signatures in PR description text | 0 (reuses PR data) |
| **5. Submodules** | Follow `.gitmodules` → check referenced repo trees | 1–2 per submodule |

Total: ~30–42 calls, within the 50-call budget.

## Consequences

- **Positive:** Catches organic AI adoption. Richer annotations with specific PR evidence. Reduces false negatives.
- **Negative:** Slightly more API calls (~5–7 more per repo).
- **Risks:** PR body matching is heuristic — could false-positive on "cursor position" or "copilot program". Mitigated with specific patterns (`Made with [Cursor]`). Submodule repos may be inaccessible — always annotate when detection is incomplete.
- **Operational:** Token must have `repo` scope for orgs with private repos. Verify before scanning.
