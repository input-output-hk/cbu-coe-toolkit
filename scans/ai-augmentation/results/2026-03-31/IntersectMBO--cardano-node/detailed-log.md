# AAMM v6 Detailed Log: IntersectMBO/cardano-node
> Scan date: 2026-03-31 | Agent: claude-opus-4-6

## Data Collection

API calls without auth (public repo). All succeeded.
- Metadata: master branch, 123109KB, 3177 stars, active (last push 2026-03-31)
- Tree: 1527 files, not truncated
- Commits: 100 fetched
- PRs: 30 fetched

## AI Attribution: ZERO

No Co-authored-by trailers mentioning AI tools in last 100 commits.
No AI bot PR authors.
No AI config files (.claude/, .cursorrules, .mcp.json, AGENTS.md, copilot-instructions.md, .aiignore).

Human co-authored-by trailers found: Marcin Wójtowicz (2), Pablo Lamela (1), Javier Sagredo (1), Fraser Murray (1), Federico Mastellone (1).

## Critical Finding: trace-dispatcher phantom

Churn analysis from commit diffs showed `trace-dispatcher/` as high-churn (#2 and #3 directories). However, `trace-dispatcher/` does NOT exist in the current repo tree (verified against tree.json). This likely means:
- The package was moved to a separate repo or renamed
- Commit diffs reference files from merge commits that included external changes
- The churn data is misleading for this directory

Stage A adversarial review correctly caught this and rejected two opportunities that relied on trace-dispatcher evidence.

## Adversarial Stage A

Dispatched as separate agent. Duration: ~317 seconds.

**Result: 3/7 approved, 4 rejected.**

Rejections:
1. opp-node-trace-tests — FABRICATED: trace-dispatcher/ does not exist in tree
2. opp-node-haddock — HALF-FABRICATED: referenced non-existent trace-dispatcher
3. opp-node-onboarding — VAGUE: ignores existing external wiki, doesn't establish bottleneck
4. opp-node-pr-descriptions — MISDIAGNOSED: PR template exists, issue is compliance not content

## Adversarial Stage B

Dispatched as separate agent. Duration: ~125 seconds.

**Result: 3/3 approved, 0 rejected.**

All recommendations passed Groundedness, Measurability, Actionability, Relevance tests.
ROI order validated. Type validation passed. No consistency issues.

## Anomalies

1. **trace-dispatcher phantom** — primary anomaly. Churn analysis unreliable for directories not in current tree. Future scans should cross-reference churn directories against tree.json before using as evidence.
2. **Zero AI adoption** — unusual for a 3177-star, actively maintained Haskell repo. This is an observation, not a judgment.
