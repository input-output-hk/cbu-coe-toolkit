# Learnings

Operational insights discovered during work on this repo. Newest first. Contributors propose entries; the repo owner reviews before committing.

---

### 2026-03-31 — Session 12: First v6 scoring scans, Gemini reviewer, synthesize, scoring-model hardening

- **Multi-model review catches different things than single-model.** Gemini 2.5 Pro reviewing scoring-model.md found issues Claude missed: undefined ROI formula, risk assessment requiring data the agent can't collect, ambiguous churn definition. After 7 rounds, scoring-model improved significantly. Multi-model review is worth the setup cost.

- **Don't blindly comply with reviewer findings.** Gemini round 5 said "count unique commits not files" for churn. Round 8 said "unique commits ignores volume" — exact opposite. Oscillation, not improvement. Evaluate each finding: real bug → fix. Design tradeoff → contest with reasoning. Previous round contradicted → stop changing.

- **Gemini CLI gets MODEL_CAPACITY_EXHAUSTED independent of user fault.** Google's cloudcode-pa.googleapis.com returns "No capacity available" during high traffic. Not per-user rate limiting — server-side capacity. Fix: health check (45s timeout) before real invocations + Gemini API ($GEMINI_API_KEY) as Level 2 fallback. Two separate capacity pools.

- **Subagent permission pattern: main collects, subagent analyzes.** Background subagents cannot get Bash permissions interactively. Solution: main session does all API calls, writes data to /tmp, dispatches subagents that only read local files + write output. Works reliably for parallel scans.

- **Portfolio review must be CoE+Leadership only, not team-facing.** Gemini's end-user review flagged that cross-repo comparisons turn consultations into competitive scorecards. Reframed synthesize output as internal portfolio-review.md with systemic patterns, not team rankings.

- **Stage A adversarial caught fabricated evidence.** cardano-node scan: primary agent cited trace-dispatcher/ as high-churn. Stage A verified against tree.json — directory doesn't exist. 2 opportunities rejected. Churn from commit diffs ≠ current file tree.

### 2026-03-30 — Session 11: AAMM v6 spec, scoring-model, KB seed, first learning scans

- **Adversarial review on your own spec surfaces design flaws before implementation.** 3 rounds of aggressive review on spec.md found: overengineered human gates (2 gates with 3 rounds each for 1 person operating 29 repos), Team Capability component that judged teams while claiming not to, Governance component that measured mechanisms not outcomes (violating ADR-011), missing failure modes, undefined adversarial context. Fixing at spec level cost hours; fixing at implementation level would cost days.

- **Subagents in background cannot get interactive bash permissions.** When launching Agent tool with `run_in_background: true`, the subagent can't prompt the user for tool approval. First batch of 5 learning scan agents all failed — they needed bash for API calls but couldn't get approval. Fix: collect all data in main context first (one batch script, 30 seconds for 28 repos), then launch subagents that only read /tmp and write output files. Pattern: **main context collects, subagents analyze.**

- **GitHub Contents API: use raw accept header, not base64 decode.** `Accept: application/vnd.github.raw+json` returns file contents directly. Base64 decode via `jq -r '.content' | base64 -d` produces garbled output on some systems. Always use the raw header.

- **One batch script > 5 parallel agents for data collection.** A single bash script collecting metadata + tree + commits for 28 repos finished in 30 seconds. 5 parallel agents each trying to do the same work failed entirely due to permission issues. For deterministic, well-defined operations (API calls with known endpoints), batch scripts beat agent parallelism.

- **KB seed format validated on first real scan.** The `applies_when` + `evidence_to_look_for` + `readiness_criteria` structure from spec.md worked in practice on cardano-ledger. All 5 seed patterns matched with real evidence. 4 new patterns proposed from observations the seeds didn't cover (Agda conformance, Imp tests, constrained generators, era transition docs). The format is practical, not just theoretical.

- **Learning scan before scoring scan is genuinely necessary.** cardano-ledger learning scan found that 4 of 9 Haskell KB patterns only exist because of this repo's specific architecture (STS framework, constrained-generators, Agda formal spec, Imp tests). Without the learning scan, the KB would lack the most valuable patterns for the portfolio's primary ecosystem.

- **Read-only rule must be stated 3 times.** AAMM's read-only constraint on target repos was not in the original spec, scoring-model, or skill. Added after explicit reminder. For non-negotiable rules: state in spec (design intent), scoring-model (agent instruction), and skill (operational guard). If it's only in one place, it will be missed.

### 2026-03-27 — Session 10: AAMM v5 complete redesign — single AI agent replaces bash pipeline

- **Working backwards from the problem is more productive than forward-iterating on signals.** 9 sessions of pipeline refinement produced precise numbers but superficial recommendations. Starting with "what problem does AAMM solve?" and working backwards produced a fundamentally better model in one session: awareness gap, where to start, feedback loop, guardrails.

- **Rubric + depth resolves the reproducibility vs quality trade-off.** v4 was reproducible but shallow (bash grep). Pure AI is deep but non-reproducible. Rubric (structured YES/NO criteria) + depth (qualitative findings with file citations) gives both: rubric anchors the level reproducibly, depth adds insight bash couldn't provide. Key rule: depth does NOT change the level — it adds findings only.

- **3 rounds of adversarial review on the spec found 59 issues total (31→16→12).** Each round caught structural problems the previous missed. Round 1 found the ADR-017 contradiction and missing level criteria. Round 2 found the 3-criteria scale mismatch and false determinism claims. Round 3 found CLAUDE.md sync and data access gaps. Adversarial review at the spec level is as valuable as at the scan level.

- **First v5 scan validated the model: adversarial review caught a quadrant miscalculation.** cardano-ledger scored HIGH readiness, MEDIUM adoption (Growing quadrant). The scanner incorrectly classified adoption as LOW — adversarial review caught this by re-checking the derivation rules. Also caught: dependabot activity the scanner missed, PR data fetched from 2018 instead of recent.

- **KB pre-seeding from previous sessions is essential for first-scan credibility.** An empty KB produces generic recommendations. Pre-seeding with 22 validated patterns from 9 sessions (5 Haskell, 4 TypeScript, 4 Rust, 3 Python, 3 cross-cutting, 3 anti-patterns) meant the first v5 scan already had ecosystem-specific context.

- **Single agent > dual architecture when the rubric provides structure.** ADR-017's dual architecture (pipeline + agent) was the right instinct (use each for its strength) but wrong implementation (two systems to maintain). The rubric embedded in the agent prompt achieves the same goal with one system. ADR-018 supersedes.

- **Subagents can't write files — plan for this in skill design.** Claude Code subagents spawned via Agent tool don't have Write/Bash permissions. Data collection and file creation must happen in the main conversation or be pre-created before dispatching subagents.

- **PR API default sort order returns oldest first.** `GET /repos/{owner}/{repo}/pulls?state=closed&sort=updated` returns ascending by default. Must add `&direction=desc` for recent PRs. This caused the scanner to analyze 2018 PRs instead of 2026.

### 2026-03-27 — Session 9: Signal audit, architecture rethink, AAMM purpose clarified

- **The score is not the goal.** AAMM purpose is visibility ("where are we?") + action ("what do we do with highest ROI?"). 9 sessions optimizing score precision (boundary logic, sampling strategies, weight redistribution) produced precise numbers but superficial recommendations. The real value is in helping teams improve, not in calculating 73.4 vs 75.1. ADR-017.

- **Two mechanisms for two goals.** Deterministic pipeline (grep, jq, formulas) is good for reproducible scores — leadership tracking, month-over-month comparison. AI agent is good for deep findings and specific recommendations — reading actual code, understanding context, producing "your CLAUDE.md doesn't mention the NX contract→module structure." Use each for what it's good at. Don't use AI for scoring (non-reproducible) or grep for recommendations (superficial).

- **Be honest the first time, not after being challenged.** U3 was rubber-stamped as "solid, wouldn't change" then eliminated 5 minutes later when questioned. The data was there all along (80% repos at 60-100, zero substance checking). Lesson: apply the same skepticism to your own first assessment that you'd apply in adversarial review.

- **Adoption is holistic SDLC, not just "has AI config."** AI can add value in: code generation, code review, PR quality (titles, descriptions, impact), testing (generation, coverage), security (review, CVE fixes), product (feature definition, user stories, acceptance criteria), delivery (release notes, changelogs, estimation), architecture (challenge, consistency, spec compliance), governance (multi-tool, attribution, boundaries). Current v4 detects <20% of these. v5 should cover the full SDLC surface.

- **Indicators with confidence > scores with precision.** ✅/⚠/❌ with confidence (HIGH/MEDIUM/LOW) is more honest and useful than 73.4/100. Teams understand "Type Safety: ✅ Strong (HIGH confidence)" better than "U1=100, weight=0.30, contribution=30.00." Confidence levels also make detection limitations transparent — MEDIUM confidence on a sampled signal is honest; a precise number on the same data is false precision.

### 2026-03-27 — Session 9: Signal-by-signal readiness audit, N4 removed, N8 expanded, U2 redesigned

- **Signals that don't discriminate should be removed, not improved.** N4 (Separation of Concerns) scored 100 for all 29 repos. Attempts to make it smarter (pattern matching, layer detection) would add complexity without adding value. Removed (ADR-013), weight redistributed to N3 and N5 which DO discriminate.

- **Repo foundations are more than 3 files.** N8 covered only CODEOWNERS + .gitignore + SECURITY.md. Expanded to 7 signals (ADR-014) including LICENSE, CONTRIBUTING.md, issue templates, PR templates — all directly relevant to AI creating issues/PRs.

- **Sample quality > sample size for U2.** The "10 largest files" sampling strategy biased toward storybook stories and data files in TypeScript monorepos. Fix: breadth-first (10 files across modules) + middle-percentile by size (5 files), excluding non-production paths. Also added minimum sample gate (≥5 public items) to prevent extrapolating from insufficient data.

- **Branch protection penalty was dead code.** API returned 404 for 97% of repos (GitHub Rulesets). The outcome (unreviewed code) was already caught by "PRs without review" penalty. Removed (ADR-015). Design principle: measure outcomes, not mechanisms.

- **docs/ is NOT architecture documentation.** Data from 30 repos: ouroboros-consensus docs/ (292 files) contains agda-spec, formal-spec, haddocks, tech-reports, website — zero architecture. Same pattern across portfolio. U4 was inflated by counting websites and generated docs as "architecture." Redesigned: README arch section (40pts, 25/30 repos have it) + ARCHITECTURE.md (30pts) + ADRs≥3 (30pts). No docs/ fallback.

- **Go and Python coverage patterns were missing.** U2 scorer had no Go counting patterns and Python counted private functions as public. Fixed: Go `func [A-Z]` + `// [A-Z]`, Python excludes `def _private`.

### 2026-03-26 — Session 8: Architecture audit, mechanism-vs-outcome, adversarial review enforcement

- **Measure outcomes, not mechanisms.** N7 scored Nix=100, Docker=80, lockfile+README=60 — measuring tool adoption, not reproducibility. A TypeScript repo with `.nvmrc` + `package-lock.json` is equally reproducible but scored 40 points lower. Fix (ADR-011): score what's pinned (runtime+deps=80, deps only=50), not which tool does the pinning. This principle applies to ALL signals — when reviewing any signal, ask "does this score the outcome or the tool?"

- **One boolean for 5 dimensions is architecture-level broken.** `HAS_AI_ACTIVITY` (one global flag) promoted ALL adoption dimensions to Active from a single PR mentioning "Claude Code." The spec defines per-dimension Active criteria but the implementation ignored them. 1 PR → Security Active + Delivery Active + Testing Active = indefensible. Quick patches (scoping L6 to Code) were immediately defeated by L4's global flag. Lesson: when you find a per-dimension problem, check if the architecture supports per-dimension answers at all.

- **Don't patch broken architecture — stop, audit, redesign.** Session applied L6 scoping (correct), but L4's global flag overrode it. Each patch exposed a new issue. The right response was to stop, audit the full adoption scoring design, document findings, and plan the fix. Dorin: "this is a big risk to aamm credibility and we need not only to fix this in the right way but to review the whole AI Adoption."

- **3 of 5 adoption dimensions have Active criteria that can't be detected from GitHub API.** Testing Active needs PR diff analysis (which files did the AI commit change?). Security Active needs review comment classification (was this a security flag or a style comment?). Delivery Active needs issue author + changelog analysis. None of these are within the 50-call API budget. A model should not define criteria it cannot measure — either expand the API budget or reduce the dimensions to what's detectable.

- **Adversarial review is the highest-value quality gate — enforce by default (ADR-012).** 3 reviewer agents across 3 repos found 18 issues, ~30% score drift, and 1 architecture flaw. The automated `review-scores.sh` caught 0 of these. The pattern works: main agent scans → reviewer agent reads output + spec + raw data → challenges every signal. This should be the default posture for ALL AAMM work, not just scans.

- **`| head -N` in bash pipelines causes SIGPIPE on large repos.** 7 instances of `sort | head | cut` killed the scan for repos with 2000+ source files. `head` closes the pipe after N lines → `sort` gets SIGPIPE (exit 141) → `set -euo pipefail` kills the script. Fix: `| awk 'NR<=N'` reads all input, prints N lines, keeps pipe open. This is not a Haskell/Rust/TS issue — it's a bash anti-pattern that scales with repo size.

- **Empty PR template placeholders are not AI signals.** `<!-- CURSOR_SUMMARY --><!-- /CURSOR_SUMMARY -->` in PR body matched L4 pattern → 6 false positives on lace-platform → inflated adoption from 33 to 52.80. Template markers without content are infrastructure artifacts, not evidence of AI activity. Fix: removed `CURSOR_SUMMARY` from L4 patterns (real Cursor usage detected by `Made with.*Cursor`).

- **Dependabot.yml existence ≠ Dependabot.yml content.** The tree scan found `.github/dependabot.yml` but the collector never fetched its content. The scorer checked ecosystem coverage in a file that didn't exist → `covers_primary=0` → false -5 penalty on repos with active npm scanning. Fix: 1 API call to fetch and parse the file.

- **Language-specific signals on wrong languages produce noise, not insight.** io-sim (Haskell concurrency framework) checked on Rust repos → false "no concurrency testing" risk flag. StrictData/BangPatterns (GHC extensions) checked on TypeScript → meaningless zeros in domain profile. Gate ecosystem-specific signals on `PRIMARY_LANG`.

- **Readiness is publishable; Adoption Active is not.** After 8 sessions: 15 of 17 readiness signals are reliable, scores are reproducible, penalties are ecosystem-aware. Adoption Configured is reliable. Adoption Active/Integrated has a fundamental architecture flaw (global boolean) and 3 of 5 dimensions have undetectable Active criteria. Publish readiness with adoption Configured. Hold Active/Integrated until fixed.

### 2026-03-26 — Exhaustive detection, U2 sampling, markdown escaping

- **Never conclude "tool absent" from one detection method.** cardano-ledger and cardano-base both use HLint, but it's defined in `flake.nix` (not `.hlint.yaml`). The scanner only checked tree file names → false negative → N5=60 instead of 100. Lesson: when a signal comes back negative, exhaust all plausible locations before scoring 0.
- **Nix projects define tooling in `flake.nix`, not config files.** HLint, fourmolu, ormolu, clippy, rustfmt — any of these can be declared as Nix derivations rather than standalone config files. `flake.nix` is a first-class detection surface for linters and formatters, equivalent to `package.json` for JS tools.
- **The review step should validate absences, not just presences.** review-scores.sh was designed to catch false positives/negatives, but its N5 check used the same limited source (`lint-format-configs.txt`) as the scorer. A review step adds value only when it checks independently — e.g., directly grepping `flake.nix` for tool names when the config-file list comes up empty.
- **Pattern: detect → score → review should use progressively wider search.** Collection looks for known file patterns. Scoring uses what collection found. Review should ask "what did we miss?" and check alternative locations (flake.nix, Makefile, CI scripts, package manifests). Each layer should be wider than the last, not a repetition.
- **U2 default score of 25 was a 25-point understatement for cardano-ledger.** Actual Haddock coverage is 45.8% (score 50). Default scores for agent-sampled signals must be flagged prominently and resolved before reports are finalized. A "not sampled" signal with a low default quietly drags an entire pillar down.
- **Markdown pipe `|` in evidence strings breaks report tables.** Haddock syntax `-- |` and `{- |` contain literal pipe characters which act as column separators in markdown tables. Any string injected into a markdown table must have `|` escaped as `\|`. Fix: `md_escape_pipes()` helper applied to all evidence fields in generate-report.sh.
- **Sampling strategy for U2: breadth > depth.** Initial approach of "10 largest files" biased toward old monolithic modules. Adding "1 file per package" catches the variation: core libs (87% coverage) vs new era modules (5%). The aggregate ratio reflects the real state better than any single file.
- **U3 README regex `## *` misses H1 headings.** cardano-ledger uses `#` (H1) for all sections. The regex `## *(architecture|...)` requires H2 minimum. Fix: `#{1,6} *` matches any heading level. This is a common pattern — many repos use H1 for top-level sections in README. Two sections (Repository structure, Contributing) were invisible, costing 40 points.
- **V4 coverage regex matched non-coverage strings.** `--min` (threshold check) matched `--minimize-conflict-set` in cabal build. The generic word `coverage` is too common in CI files. Fix: require specific tool names (codecov, hpc, tarpaulin) not generic words, and require threshold patterns to include coverage context (`coverage.*threshold`, not just `--min`). cardano-ledger V4 was 100 (false positive) → actually 0 (no coverage tooling).
- **N5 CI enforcement needs per-tool granularity.** A single `CI_LINT=1` flag can't distinguish "formatter in CI" from "linter in CI." When fourmolu runs in CI but hlint doesn't, the single-flag approach scores 100 (both CI-enforced) when it should score 80 (both present, only one CI-enforced). Fix: separate CI_LINTER and CI_FORMATTER flags.
- **Exhaustive rescan found errors in both directions.** Original score 80.07 had both false negatives (N5, U2, U3 understated) and a false positive (V4 overstated). Net effect: corrections nearly cancel out (79.27). The lesson is not that the score barely changed — it's that the *composition* was wrong. A team reading "V4=100, coverage enforced" would think they have coverage. They don't.

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
- **High-assurance domain detection catches TypeScript wallet repos.** lace-platform has "cardano" in GitHub topics, so `IS_HIGH_ASSURANCE=1`. Non-Haskell high-assurance repos are a valid category.

### 2026-03-20 — AAMM pipeline v2, high-assurance domain, recommendations

- **Sampling strategy matters as much as scoring logic.** Initial scan sampled longest-named test files — all were conformance modules, not generators. Result: false negative on generator discipline. Fix: prioritize `Gen*.hs`, `Generators.hs`, `*Arbitrary*` files.
- **Transitive dependencies are invisible to tree API.** io-sim is a Hackage dep, invisible in tree and cabal.project. Only `.cabal` file `build-depends` catches it.
- **Graduated penalty order matters.** Active dep management check came after dependabot partial check in if/elif chain. Repos with both hit the wrong branch. Fix: reorder so active strategy takes priority.
- **`bc` outputs ".828" not "0.828".** GNU bc omits leading zero. Fix: `sed 's/^\./0./'`.
- **`grep -c` returns exit 1 on zero matches.** Combined with `|| echo 0`, captures "0\n0". Fix: use `|| true` and handle empty separately.
- **Principal engineer review catches what scripts can't.** The review step identified 6 false negatives/positives — language-specific patterns, transitive deps, sampling bias.
- **Reports without recommendations produce no action.** Scores alone don't drive change. Specific next steps ("Add CLAUDE.md with these categories") are essential.
- **Specs drift from decisions within hours.** README.md showed 6 categories while adoption-scoring.md showed 8. Every scoring decision must update all affected spec files in the same session.

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

### 2026-03-26 — Adversarial review round 2: pipeline fixes + peer review

- **`grep -c` + `set -euo pipefail` = silent script death.** `grep -c` returns exit 1 when count is 0 (no matches) BUT still outputs "0" to stdout. Combined with `|| echo 0`, the result is `0\n0` (grep's "0" + echo's "0"). With `pipefail`, this breaks arithmetic. Fix: use `|| true` and `${var:-0}` default. This was the root cause of mithril's scoring script silently failing.

- **Adversarial review agents are the highest-value quality gate.** Dispatching 3 reviewer agents (one per repo) that challenge every signal from CoE + team perspectives found 9 pipeline bugs producing 11-15 point score errors per repo. `review-scores.sh` (the automated review step) caught 0 of these. The pattern: main agent scans, reviewer agent reads output + scoring spec + raw data, challenges each score.

- **Peer review before implementation caught 3 blocking issues.** `.test.ts` as unconditional "unit test" is wrong (E2E .test.ts exists), `node_modules/` tree scan is dead code (excluded by collection), and spec sync was missing. Cost of fixing after implementation would have been higher.

- **API 429 errors saved as source files corrupt scoring.** When GitHub rate-limits during collection, the error page ("429: Too Many Requests") gets saved as `sampled_u2_0_filename.rs`. The scoring script then tries to `grep -c` for Rust patterns on HTTP error text. Fix: `head -1 | grep -qE '^[0-9]{3}: '` guard at the start of file processing loops.

- **npm/NX monorepo CI patterns are invisible to tool-name grep.** `npm run check:format` and `npx nx affected --target=lint` don't contain tool names (eslint, prettier). CI enforcement detection must recognize npm script wrappers as valid indicators when the underlying tool config exists.

- **Contract-first architecture is a de facto schema pattern.** lace-platform has 30+ `packages/contract/` packages defining typed TypeScript interfaces at module boundaries — functionally equivalent to schema definitions. The spec's literal file search (.proto, .graphql) missed this entirely. Conservative score: 50 (not 75), per peer review.

- **Branch protection API 404 ≠ absent.** All 3 repos had 0 unreviewed PRs out of 200+ checked, strongly implying protection exists but the API returns 404 (org-level rulesets or insufficient token scope). Penalizing 100%-review-rate repos for "no branch protection" is logically inconsistent. Fix: check PR review rate as counter-evidence, same as the 403 handler.

### 2026-03-26 — Adversarial scan review: 3 repos, 18 issues, 10 corrections

**Context:** Full adversarial re-scan of mithril (Rust), cardano-node (Haskell), lace-platform (TypeScript) — reviewer at each signal asking "ce ai putut rata, ce n-ai verificat, se poate altfel?"

- **Adversarial review per-signal catches ~30% score drift.** 18 issues found across 3 repos. Score corrections: mithril +4.2, cardano-node +7.6, lace-platform +3.1 Readiness; lace-platform Adoption -27.2 (Integrated → Active for 4 dimensions). Running a sceptic at each signal step is worth the time on first-scan of any new repo.

- **`head -4` workflow cap was the most widespread bug.** Alphabetical fetch of only 4 workflows means any CI workflow starting with a letter after the first 4 misses detection. cardano-node: `check-hlint.yml` and `stylish-haskell.yml` never fetched (5th, 17th alphabetically). mithril: `ci.yml` never fetched (5th). Fixed to `head -20`.

- **U2 always returning 25 is the biggest systematic bias.** U2 weight = 0.25 in Understand (0.35) = ~8.75% of total readiness. Every repo was getting the same default score. Autonomous 5-file sampling now runs at collect time. For Rust: manual sample of mithril showed 91% doc coverage → 100, not 25.

- **Adoption Integrated was awarded too generously.** Pattern: `grep -qiE '(claude|copilot|coderabbit)'` in any workflow → `HAS_AI_IN_CI=true` → Integrated. lace-platform's `claude.yml` has read-only permissions — it reviews PRs but doesn't block merges. Fix: Integrated now requires accessible branch protection (non-404 API). Active is still a strong signal; claiming Integrated without confirmation is dishonest.

- **CODEOWNERS in `.github/` is the GitHub-recommended location for repos with many root files.** Only root was checked. lace-platform had `.github/CODEOWNERS` → codeowners=0 (false negative). GitHub accepts root, `.github/`, or `docs/`. Fixed in collect step.

- **`cargo-deny check licenses` ≠ CVE scanning.** Two completely different security postures. mithril runs `cargo deny check licenses` but not `check advisories`. The script previously credited `cargo-deny` presence as `HAS_CI_SECURITY=1` regardless of subcommand. Fixed: only `check advisories` or bare `check` counts for CVE scanning.

- **Rust inline tests (`#[cfg(test)]`) are invisible to file-count ratio.** 53% of sampled mithril source files had inline test modules; 169+ `#[test]` functions not counted. V1=25 (file ratio 0.16) misrepresents a repo with healthy test coverage. Model blindspot — documented in spec, override recommended.

- **U3 emoji-prefixed headings silently fail.** Regex `#{1,6} *(keyword)` requires keyword immediately after `##`. Modern repos use `## :rocket: Getting started` or `## 🛠️ Build`. mithril had all 5 README sections but only 1 was matched → score 20 instead of 100. Fixed with `.{0,20}` lookahead.

- **Branch protection 404 is ambiguous for IOG repos.** Could mean: (a) no protection, (b) org-level GitHub Ruleset (not visible via repo API), (c) insufficient token scope. All sampled PRs across all 3 repos had ≥1 review — 0 unreviewed out of 200+ checked. -5 penalty may be incorrect for repos using org-level rulesets.

- **Two root fixes eliminate most issues.** Fix the workflow cap → resolves N5/N6 detection for 80%+ of repos. Add U2 autonomous sampling → eliminates the largest systematic score bias. Everything else is incremental.
