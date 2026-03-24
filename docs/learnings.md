# Learnings

Operational insights discovered during work on this repo. Newest first. Contributors propose entries; the repo owner reviews before committing.

---

### 2026-03-21 — Nix CI detection, learning signals design

- **Nix-wrapped CI is invisible to direct tool grep.** Haskell repos run hlint/fourmolu via `nix develop --command`. CI enforcement checks must match `nix develop|nix build|nix flake check` patterns, not just direct tool names.
- **Per-dimension learning signals are false precision.** AI config files serve all SDLC dimensions simultaneously. Per-repo annotation is more honest than per-dimension attribution.
- **90-day window for "evolving" config.** 180 days answers "is this dead?" but learning asks "is this being refined?" — higher bar, shorter window.
- **Commit count ≥2 beats content-diff analysis.** A single typo fix shouldn't flip learning state. Two commits in the window filters noise without line-count complexity.
- **"Self-improving" state needs scan history.** Detecting causal correlation between outcomes and config changes requires comparing scans. Deferred to v2.

### 2026-03-21 — Script robustness, D1 validation

- **`pipefail` + `grep` on empty input kills scripts silently.** `grep -v '^$'` exits 1 when nothing matches, and `set -euo pipefail` aborts with no error message. Fix: append `|| true`.
- **Heredoc `<< EOF` expands `\(` to `(`.** jq `\(.key)` inside unquoted heredocs loses the backslash. Fix: use `\\(.key)` or compute values before the heredoc.
- **jq `-s` pipe context loss.** `|` changes context, making earlier array indices inaccessible. Fix: capture with named variables (`.[0] as $a`).
- **`awk` average can produce decimals.** Bash `$((...))` only handles integers. Fix: use `printf "%d"` in awk.
- **Blockchain domain detection catches TypeScript wallet repos.** lace-platform has "cardano" in GitHub topics, so `IS_BLOCKCHAIN=1`. Non-Haskell blockchain repos are a valid category.

### 2026-03-20 — AAMM pipeline v2, blockchain domain, recommendations

- **Sampling strategy matters as much as scoring logic.** Initial scan sampled longest-named test files — all were conformance modules, not generators. Result: false negative on generator discipline. Fix: prioritize `Gen*.hs`, `Generators.hs`, `*Arbitrary*` files.
- **Transitive dependencies are invisible to tree API.** io-sim is a Hackage dep, invisible in tree and cabal.project. Only `.cabal` file `build-depends` catches it.
- **Graduated penalty order matters.** Active dep management check came after dependabot partial check in if/elif chain. Repos with both hit the wrong branch. Fix: reorder so active strategy takes priority.
- **`bc` outputs ".828" not "0.828".** GNU bc omits leading zero. Fix: `sed 's/^\./0./'`.
- **`grep -c` returns exit 1 on zero matches.** Combined with `|| echo 0`, captures "0\n0". Fix: use `|| true` and handle empty separately.
- **Principal engineer review catches what scripts can't.** The review step identified 6 false negatives/positives — language-specific patterns, transitive deps, sampling bias.
- **Reports without recommendations produce no action.** Scores alone don't drive change. Specific next steps ("Add CLAUDE.md with these categories") are essential.
- **Specs drift from decisions within hours.** model-spec.md showed 6 categories while adoption-scoring.md showed 8. Every scoring decision must update all affected spec files in the same session.

### 2026-03-20 — LACE sample report, hidden AI signals

- **PR body text is a critical AI detection surface.** "Made with Cursor" in PR body, not in commit metadata. Scan must regex-search PR bodies for AI tool signatures.
- **Search for bot-authored PRs explicitly.** Copilot Agent PR was closed (not merged), invisible in recent-merged sample. Use GitHub Search API regardless of merge status.
- **Submodule AI config is invisible from parent repo.** `.claude/` in a submodule requires following the submodule SHA. See ADR-003 for full detection methodology.
- **Token scope must include `repo` for private repos.** `public_repo` scope returns 404 silently. Verify before scanning orgs with private repos.
- **Multi-tool detection requires multiple strategies.** No single method finds all AI tools. MCP is in tree, Cursor is in PR bodies, Copilot Agent is a PR author, Claude is in a private submodule.
- **"Active without Configured" is the most actionable insight.** Teams with organic AI adoption need the lightest push to unlock institutional value.

### 2026-03-17 — AAMM v3 design

- **Two-condition gates for Stage 1.** Config-only Stage 1 allowed gaming. Requiring practice active + AI config is more honest.
- **Sub-levels beat continuous scores for adoption.** 0–100 continuous scoring required 35+ formulas and confused stakeholders. Low/Mid/High gives enough granularity.
- **The quadrant is the communication tool.** "Fertile Ground — Readiness 90, Adoption 5" communicates more than any stage table. Quadrant is what leadership remembers; stages are what teams act on.
- **Next Steps as flywheel.** Always 3 steps, ordered by impact/effort, showing projected advancement. Turns measurement into action.

### 2026-03-13 — Initial setup

- **Repo scaffolded per project brief v1.1.** Both repos follow the same structure.
- **Three-layer knowledge capture adopted.** Decisions, learnings, session handoff. See ADR-001.
- **Notion page registry pre-populated** from project brief page IDs.
