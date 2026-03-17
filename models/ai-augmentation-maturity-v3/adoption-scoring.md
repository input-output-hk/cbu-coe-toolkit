# AAMM v3: Adoption Scoring Methodology

**Owner:** CoE · Dorin Solomon · **Status:** Draft v1.0 · **Last updated:** March 2026

This document defines how an AI agent scores adoption across **7 SDLC dimensions** — step-by-step decision trees, data collection requirements, sub-level determination, and output format. It is the operational companion to [model-spec.md](./model-spec.md), which defines stage semantics and the two-axis architecture. For the other axis (AI Readiness scoring), see `readiness-scoring.md`.

Scoring is performed **per repository**. Each repo receives a stage (0-4) and sub-level (Low/Mid/High) per dimension, a confidence level per dimension, a learning signal annotation, and an Adoption composite score. Organisation-level results are derived from the distribution of repo scores.

---

## 1. General Scoring Rules

1. **Each dimension scores Stage 0-4.** The stage represents the highest stage fully achieved.
2. **Each stage carries a sub-level (Low / Mid / High)** indicating within-stage progress. Stage 0 also carries a blank sub-level when neither condition is met at all.
3. **Stages are cumulative.** A repo cannot score Stage 2 without satisfying Stage 1. If Stage 2 signals appear without Stage 1 foundation (e.g., AI-authored PRs but no AI config), score as Stage 0 and annotate: "Stage 2 signals emerging without Stage 1 foundation."
4. **Stage 1 requires a two-condition gate on every dimension.** Both (A) the relevant engineering practice must be active and (B) AI config must cover that dimension. Meeting only one condition keeps the dimension at Stage 0 with an appropriate sub-level (see Section 2 for the decision tree).
5. **Non-AI tooling does not advance the AI adoption score.** Dependabot, hlint, Nix flakes, `-Werror` — these are strong engineering practices that satisfy Condition A. They facilitate stage transitions but are not AI signals by themselves.
6. **Scores are tool-agnostic.** GitHub Copilot, Claude Code, Cursor, Gemini, or any other AI tool count equally. The model measures capability, not vendor adoption.
7. **7 dimensions** are scored: Code Quality, Security, Testing, Release, Ops & Monitoring, AI-Assisted Delivery, and AI Practices & Governance.
8. **When a dimension is n/a** (e.g., Ops/Monitoring for a library repo), its weight is redistributed proportionally. Remaining weights are divided by (1 - excluded_weight) to maintain a sum of 1.0.

### Stage-to-Score Mapping

Sub-levels map to a 0-100 scale for composite calculation:

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0     | 0   | 7   | 13   |
| 1     | 20  | 27  | 33   |
| 2     | 40  | 47  | 53   |
| 3     | 60  | 67  | 73   |
| 4     | 80  | 90  | 100  |

Stage 0 with blank sub-level (neither condition met, no signals) maps to **0**.

### Adoption Composite Calculation

```
Adoption composite = weighted average of mapped scores across 7 dimensions
```

**Dimension weights:**

| Dimension | Code | Weight |
|-----------|------|--------|
| Code Quality | CQ | 0.18 |
| Security | Sec | 0.15 |
| Testing | Test | 0.18 |
| Release | Rel | 0.12 |
| Ops & Monitoring | Ops | 0.10 |
| AI-Assisted Delivery | Del | 0.12 |
| AI Practices & Governance | AIP | 0.15 |

**Formula:**

```
Adoption = CQ_score * 0.18 + Sec_score * 0.15 + Test_score * 0.18
         + Rel_score * 0.12 + Ops_score * 0.10 + Del_score * 0.12
         + AIP_score * 0.15
```

**When a dimension is excluded** (n/a), divide remaining weights by (1 - excluded_weight). Example: Ops excluded (weight 0.10), CQ weight becomes 0.18 / 0.90 = 0.200.

### Overall Stage Calculation

| Pattern | Overall Stage | Example |
|---------|--------------|---------|
| All dimensions at 0 | **0** | All zeros |
| 1 dimension at N, rest lower | **0->N** (transitioning) | CQ:1, rest 0 |
| 2+ dimensions at N | **N** (gaps noted) | CQ:1, Sec:1, rest 0 -> **1** |
| Some dimensions advancing beyond N | **N->N+1** | CQ:2, Sec:1, Test:1, Del:1, rest 0 -> **1->2** |

---

## 2. Two-Condition Gate (Stage 1 Decision Logic)

Every dimension follows the same Stage 1 gate logic. The two conditions are:

- **(A) Relevant engineering practice is active** — the non-AI infrastructure exists and runs
- **(B) AI config covers that dimension** — AI tools have project context for this area

The decision tree for each dimension begins:

```
1. CHECK STAGE 0:
   Is Condition A met? Is Condition B met?

   -> Neither A nor B:
      Stage 0 (blank). Record "No signals."

   -> Only A met (practice active, no AI config):
      Stage 0 - Mid. Record "Practice active, no AI config."

   -> Only B met (AI config present, practice not active):
      Stage 0 - Mid. Record "AI config present, practice not active."

   -> Both partially met (emerging signals on both):
      Stage 0 - High. Record specifics of what is partially met.

   -> Both A and B fully met:
      Proceed to Stage 1 assessment.

2. CHECK STAGE 1 (requires BOTH conditions):
   a. Condition A: {dimension-specific checks - see per-dimension sections}
   b. Condition B: {dimension-specific AI config content checks}

   -> If BOTH met: Stage 1. Determine sub-level (Low/Mid/High).
   -> If only one met: Stay at Stage 0 with appropriate sub-level.

3. CHECK STAGE 2: {dimension-specific signals}
4. CHECK STAGE 3: {dimension-specific signals}
5. CHECK STAGE 4: {dimension-specific signals}
```

The per-dimension sections (Sections 4-10) provide the specific Condition A and Condition B checks and the Stage 2-4 signal definitions.

---

## 3. Data Collection -- What to Retrieve from GitHub

### Authentication

The agent authenticates with GitHub using the `$GITHUB_TOKEN` environment variable, which should already be set. **If the token is not available or authentication fails, stop and ask the human operator** — do not proceed without it. Never print, log, display, or save the token value.

### Data Requirements

For each tracked repository, the agent collects the following information. Use the GitHub API (REST or GraphQL) in whatever way is most effective — specific endpoints may change over time, so the requirement is defined by **what data is needed**, not how to fetch it.

| What to Get | Why | Where to Store |
|---|---|---|
| **List of files in repo root, `.github/`, `.claude/`, `.cursor/`, `.sourcegraph/`, `.continue/`, `.codex/`** | Detect AI config files, security policies, workflow definitions, governance files | Used during scoring, not stored separately |
| **Full text content of each AI config file found** | Assess quality (meaningful context vs stub) for Stage 1 scoring | Summarised in evidence field of results JSON |
| **All workflow YAML files** (`.github/workflows/*.yml`) | Detect CI/CD, security gates, AI quality gates, release automation, monitoring steps, test execution | Referenced by filename in evidence |
| **Pull requests** (merged, since last snapshot): author, title, body, review status, reviewers | Detect AI-authored PRs, unreviewed merges, AI review comments, PR template compliance | PR counts and numbers in evidence |
| **PR reviews** for recently merged PRs | Detect whether PRs were reviewed before merge (Minimum Viability check); detect AI bot review comments | Summarised in minimum viability risks |
| **Recent commits** on default branch (since last snapshot) | Detect AI co-author attributions in commit messages (Co-authored-by patterns) | Count and patterns in evidence |
| **Issues** (recent, open, and recently closed) | Detect AI-generated issues, delivery workflow signals, stale/blocked items | Issue numbers in evidence |
| **GitHub Projects linked to the repo** | Detect delivery tracking, project board structure, status automation | Presence/absence noted in evidence |
| **Branch protection rules** for default branch | Detect PR review requirements, merge restrictions | Summarised in minimum viability risks |
| **Dependabot / Renovate configuration** | Detect dependency scanning status | Noted in infrastructure readiness |
| **Language-specific files** (see Language-Specific Infrastructure Signals in model-spec.md) | Detect infrastructure readiness signals per language ecosystem | Listed in infrastructure_readiness field |
| **`.aiignore` / `.cursorignore` file** | Detect sensitive path exclusion from AI tools (AI Practices dimension) | Noted in evidence |
| **`AGENTS.md`** | Detect agent orchestration patterns, specialized roles (AI Practices Stage 2+) | Content summarised in evidence |
| **`.claude/commands/` directory** | Detect custom AI commands (AI Practices Stage 2+) | File list noted in evidence |
| **MCP config files** (`.mcp.json`, `mcp.json`) | Detect MCP server configurations, tool integrations | Content summarised in evidence |
| **Commit history on AI config files** | Assess learning signals: frequency, substance, and recency of updates since initial creation | Commit dates and diff summaries in evidence |
| **`CONTRIBUTING.md`** | Detect documented human-AI review gates, AI governance expectations | Content summarised in evidence |
| **`SECURITY.md`** | Minimum viability threshold check | Presence noted |

### Accepted AI Config Files (Complete List)

The following files are recognized as AI configuration files. This list corresponds to model-spec.md Section 7 and should be updated as new AI tools emerge.

| File / Directory | Tool / Purpose |
|---|---|
| `CLAUDE.md` or `claude.md` | Anthropic Claude Code project context |
| `AGENTS.md` | Multi-agent orchestration and specialized roles |
| `GEMINI.md` | Google Gemini project context |
| `.github/copilot-instructions.md` | GitHub Copilot project context |
| `.github/copilot-setup-steps.yml` | GitHub Copilot setup automation |
| `.cursor/rules` | Cursor editor rules |
| `.cursorrules` | Cursor editor rules (legacy location) |
| `.claude/settings.json` | Claude Code tool and permission settings |
| `.claude/commands/` | Claude Code custom slash commands |
| `ai_run.sh` | Generic AI execution script |
| `agent_docs/` | Generic AI agent documentation directory |
| `.mcp.json` or `mcp.json` | Model Context Protocol server configuration |
| `.aider*` | Aider configuration files |
| `.coderabbit.yaml` | CodeRabbit AI reviewer configuration |
| `.windsurfrules` | Windsurf editor rules |
| `.continue/` | Continue.dev configuration directory |
| `.sourcegraph/cody` | Sourcegraph Cody configuration |
| `.codex/` | OpenAI Codex configuration directory |
| `.aiignore` | AI tool file exclusion (sensitive paths) |
| `.cursorignore` | Cursor file exclusion (sensitive paths) |

**Note:** `.aiignore` and `.cursorignore` are exclusion files, not project context files. They contribute to AI Practices scoring (governance) but do not satisfy Condition B for other dimensions. Condition B requires substantive project context (architecture, conventions, standards).

### AI Config Quality Threshold

"File exists" is necessary but not sufficient. An AI config file counts toward Stage 1 Condition B only if it contains **meaningful project context.**

**Counts:**
- Architecture overview, module boundaries, dependency relationships
- Coding conventions, naming patterns, preferred approaches
- Testing standards, build commands, CI expectations
- Security-critical areas, trust boundaries
- Delivery workflow, estimation approach, issue structure
- Operational context, deployment topology
- Approximately 50+ lines of substantive content (guideline, not hard cutoff)

**Does not count:**
- Empty or stub files ("TODO: add instructions")
- Generic boilerplate copied without project-specific adaptation
- Files containing only tool configuration with no project context (e.g., `.mcp.json` with only server URLs)

If a file fails the quality check, score the dimension as Stage 0 with annotation: "Config present but insufficient -- [specific reason]."

### Bot Names for AI Activity Detection

When checking for AI-authored PRs, commits, and reviews (Stage 2+):

| Bot Identifier | Platform |
|---|---|
| `copilot[bot]` | GitHub Copilot |
| `github-copilot[bot]` | GitHub Copilot |

This list should be updated as new AI tools emerge that author PRs. Also check for:
- PR authors with `[bot]` suffix that reference AI tools
- Commit messages containing `Co-authored-by:` with AI tool names (copilot, Claude, Cursor, Gemini, AI-generated, etc.)
- PR review comments from bot accounts associated with AI tools (e.g., CodeRabbit, CodeGuru)

### Where to Store Results

- **Machine-readable snapshots:** `scans/ai-augmentation/results/YYYY-MM.json` in the `cbu-coe-toolkit` repo. One file per monthly snapshot. Never overwrite previous snapshots.
- **Human-readable output:** Published to the Notion display pages (see `notion/page-registry.yaml` for page IDs). Notion is the presentation layer — GitHub is the source of truth.
- **Evidence:** Each dimension score includes a short evidence string citing specific file names, PR numbers, or workflow references. Never generic descriptions — always verifiable.

---

## 4. Code Quality -- Scoring Process

**Condition A (practice active):** Linter/formatter or code review process active in the repository.
**Condition B (AI config):** AI config covers coding conventions, architecture overview, module boundaries, preferred patterns, documentation standards.

```
1. CHECK STAGE 0:
   Is Condition A met? Is Condition B met?

   a. Condition A check:
      - Linter config present? (e.g., .hlint.yaml, clippy.toml, .eslintrc.*,
        eslint.config.js, .pylintrc, ruff.toml)
      - Formatter config present? (e.g., .ormolu, fourmolu.yaml, rustfmt.toml,
        .prettierrc, prettier.config.js, pyproject.toml with [tool.black])
      - Code review process visible? (PR review requirements in branch protection,
        CODEOWNERS file, or documented review process)
      - Any of the above running in CI? (check workflow YAML)

   b. Condition B check:
      - Any accepted AI config file present? (see Section 3 complete list)
      - Does the config contain coding conventions, architecture, module boundaries?
      - Quality threshold met? (50+ lines of substantive content, project-specific)

   -> Neither A nor B:
      Stage 0 (blank). Record "No signals."

   -> Only A (linter/formatter/review active, no AI config):
      Stage 0 - Mid. Record "Linter/formatter active ({tool names}), no AI config."

   -> Only B (AI config present, no linter/formatter/review):
      Stage 0 - Mid. Record "AI config present ({file}), no linter/formatter/review."

   -> Both partially met:
      Stage 0 - High. Record specifics.

2. CHECK STAGE 1 (requires BOTH conditions):
   a. Condition A: At least one of the following is true:
      - Linter runs in CI (workflow YAML references linting step)
      - Formatter enforced (check step or pre-commit hook)
      - Code review process active (branch protection requires reviews,
        or CODEOWNERS file routes reviews, or recent PRs show review activity)
   b. Condition B: AI config file passes quality threshold AND contains:
      - Coding conventions (naming, formatting, style preferences)
      - Architecture overview (module structure, key abstractions)
      - Module boundaries (what goes where, separation of concerns)
   -> If BOTH met: Stage 1. Determine sub-level.
   -> If only one: Stay at Stage 0 with appropriate sub-level.

3. CHECK STAGE 2: AI participates visibly in the development workflow.
   Look for ANY of:
   - Pull requests authored by AI bots:
     copilot[bot], github-copilot[bot]
     (update this list as new AI tools emerge)
   - Commits containing AI co-author strings:
     "Co-authored-by: copilot", "Co-authored-by: Claude",
     "Co-authored-by: Cursor", "AI-generated"
   - PR review comments from AI bots (CodeRabbit, Copilot, etc.)
   - AI-generated PR summaries in PR descriptions
   - AI-opened fix, refactoring, or documentation PRs
   Count AI PRs and co-authored commits since last snapshot date.
   -> If no AI workflow activity: Stay at Stage 1.
   -> If activity found: Stage 2 achieved. Record PR numbers, bot names, counts.

4. CHECK STAGE 3: AI quality checks run in pipeline.
   Look for:
   - Workflow YAML files that reference AI tools (copilot, anthropic, openai,
     coderabbit, codeguru, or equivalent) that block or gate merges
   - AI-generated bug fix PRs opened from automated issue analysis
   - AI documentation generation steps in CI
   - AI-generated refactoring suggestions surfaced automatically
   - Flaky test diagnosis without human investigation
   -> If no pipeline integration: Stay at Stage 2.
   -> If found: Stage 3. Record workflow file names and relevant steps.

5. CHECK STAGE 4: Org-wide standardisation and learning signals.
   Look for:
   - AI config follows a consistent template across multiple repos in the org
   - AI quality enforcement documented in CONTRIBUTING.md
   - AI coding standards documented at org level
   - Evidence that AI config has been refined based on feedback (commit history
     showing iterations, accepted/rejected suggestions documented)
   - Refactoring PRs raised on schedule by AI
   - Documentation maintained automatically
   -> If found: Stage 4. Record evidence.
```

**Sub-level criteria:**

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0 | Neither condition met | One condition substantially met (linter active OR AI config present) | One fully met + other emerging (e.g., linter active + partial AI config) |
| 1 | Both conditions minimally met: basic config + linter present but not in CI | Solid config covering conventions and architecture + linter running in CI | Comprehensive config including patterns, anti-patterns, examples + emerging AI PR activity |
| 2 | Occasional AI activity (1-2 co-authored commits or bot PRs) | Regular AI activity (multiple AI PRs, reviews, co-authored commits) | Heavy AI workflow integration + emerging pipeline signals |
| 3 | Single AI quality gate in pipeline | Multiple AI quality checks, automated refactoring PRs | Comprehensive pipeline coverage + emerging org-wide patterns |
| 4 | Org-wide template adopted + basic learning evidence | Active refinement visible + multi-repo consistency | Self-improving: config evolves from team feedback, measurable improvement |

---

## 5. Security -- Scoring Process

**Condition A (practice active):** Automated dependency/security scanning active in CI.
**Condition B (AI config):** AI config identifies security-critical modules, trust boundaries, and sensitive data flows.

```
1. CHECK STAGE 0:
   Is Condition A met? Is Condition B met?

   a. Condition A check:
      - Dependabot config: .github/dependabot.yml
      - Renovate config: renovate.json, renovate.json5, .renovaterc
      - Workflow YAML containing any of:
        codeql, trivy, snyk, semgrep, cargo-deny, cargo-audit, cargo audit,
        cabal-audit, cabal audit, npm audit, yarn audit, pip-audit,
        safety check, bandit, gosec
      - Security-focused CI step: workflow YAML with security-related
        job names or step names

   b. Condition B check:
      - AI config file present AND contains security-specific content:
        security-critical modules identified, trust boundaries documented,
        sensitive data flows described, authentication/authorization
        patterns noted, secret handling conventions

   -> Neither A nor B:
      Stage 0 (blank). Record "No signals."

   -> Only A (scanning active, no AI config for security):
      Stage 0 - Mid.
      Record "Security scanning active ({tool names}) but no AI config
      covering security context."

   -> Only B (AI config covers security, no automated scanning):
      Stage 0 - Mid.
      Record "AI config covers security context but no automated scanning."

   -> Both partially met:
      Stage 0 - High. Record specifics.

2. CHECK STAGE 1 (requires BOTH conditions):
   a. Condition A: At least one automated scanning tool active:
      - .github/dependabot.yml exists with package-ecosystem entries
      - renovate.json or equivalent configured
      - Workflow YAML contains security scanning step that runs on PRs or schedule
      - Language-specific: cargo-deny in CI (Rust), cabal-audit in CI (Haskell),
        npm audit in CI (TypeScript/JavaScript)
   b. Condition B: AI config file passes quality threshold AND contains:
      - Security-critical modules or components identified
      - Trust boundaries described (what talks to what, what is public-facing)
      - Sensitive data flows documented (secrets, PII, keys, credentials)
   -> If BOTH met: Stage 1. Determine sub-level.
   -> If only one: Stay at Stage 0 with appropriate sub-level.

3. CHECK STAGE 2: AI surfaces vulnerabilities during code review.
   Look for:
   - PR comments from Copilot Autofix or AI security bots
   - AI-powered SAST comments on PRs
   - AI-flagged CVEs in dependency update PRs
   - AI security suggestions in PR review comments
   - AI identifying risky patterns (SQL injection, XSS, deserialization, etc.)
   -> If found: Stage 2. Record PR numbers and bot names.

4. CHECK STAGE 3: AI security integrated in pipeline.
   Look for:
   - Workflow YAML contains AI security steps that block merges
     (required status checks referencing AI security tools)
   - Auto-remediation PRs opened by AI for known CVEs
   - AI-powered SAST running on every push (beyond basic Dependabot):
     Claude security analysis, CodeQL with AI, Snyk AI, or equivalent
   - Scheduled security scanning workflows (not just PR-triggered)
   - Continuous scanning against production code
   -> If found: Stage 3. Record workflow references.

5. CHECK STAGE 4: Continuous AI threat modelling.
   Look for:
   - AI-generated security issues or threat assessments in repo
   - Architectural risk assessments in ADRs or issues
   - Supply chain verification step in every build workflow
     (signature verification, provenance checks, SBOM generation)
   - CVE remediation automated within policy
   - AI threat modelling evidence (threat model documents, STRIDE analysis)
   -> If found: Stage 4. Record evidence.
```

**Sub-level criteria:**

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0 | Neither condition met | One condition substantially met (scanning active OR AI config covers security) | One fully met + other emerging |
| 1 | Basic scanning (Dependabot only) + minimal security in AI config | Active scanning with multiple tools + security context in AI config | Comprehensive scanning + detailed trust boundaries + emerging AI security reviews |
| 2 | Occasional AI security comments on PRs | Regular AI security reviews + CVE flagging | AI security reviews standard practice + emerging pipeline signals |
| 3 | Single AI security gate in pipeline | AI blocking merges + auto-remediation PRs | Comprehensive AI security pipeline + emerging threat modelling |
| 4 | Supply chain verification on builds | Active threat modelling + automated CVE remediation | Continuous AI threat assessment + self-improving security posture |

---

## 6. Testing -- Scoring Process

**Condition A (practice active):** Test suite runs in CI (check workflow YAML for test execution step).
**Condition B (AI config):** AI config documents test standards, frameworks, coverage expectations, and test types.

```
1. CHECK STAGE 0:
   Is Condition A met? Is Condition B met?

   a. Condition A check:
      - Workflow YAML contains test execution step:
        "cabal test", "stack test", "cargo test", "npm test", "yarn test",
        "pytest", "jest", "vitest", "go test", "mix test", "dotnet test",
        or equivalent
      - Test files/directories exist (test/, tests/, __tests__/, spec/,
        *_test.go, *_spec.rb, *.test.ts, *.spec.ts, Test.hs, Spec.hs)

   b. Condition B check:
      - AI config file present AND contains testing-specific content:
        test frameworks named, coverage expectations stated, test types
        listed (unit, integration, property-based, E2E), test conventions
        documented (naming, structure, fixtures)

   -> Neither A nor B:
      Stage 0 (blank). Record "No signals."

   -> Only A (tests run in CI, no AI config for testing):
      Stage 0 - Mid.
      Record "Test suite runs in CI ({framework}), no AI config covering testing."

   -> Only B (AI config covers testing, no CI test execution):
      Stage 0 - Mid.
      Record "AI config covers testing standards, no test execution in CI."

   -> Both partially met:
      Stage 0 - High. Record specifics.

2. CHECK STAGE 1 (requires BOTH conditions):
   a. Condition A: Test suite executes in CI pipeline:
      - Workflow YAML contains explicit test step that runs on push or PR
      - Test files exist in the repository (not just config, actual test code)
   b. Condition B: AI config file passes quality threshold AND contains:
      - Test frameworks identified (e.g., HSpec, Tasty, jest, pytest, cargo test)
      - Coverage expectations stated (e.g., "maintain 80% line coverage")
      - Test types documented (what types of tests the project uses)
      - Test conventions (naming patterns, fixture organization, assertion style)
   -> If BOTH met: Stage 1. Determine sub-level.
   -> If only one: Stay at Stage 0 with appropriate sub-level.

3. CHECK STAGE 2: AI active in test review.
   Look for:
   - AI PR comments mentioning coverage, untested paths, or test suggestions
   - AI reviewing coverage at PR or project level
   - AI flagging missing test types (e.g., "no integration tests for this endpoint")
   - AI identifying untested code paths during review
   - AI suggesting edge cases or test scenarios in PR comments
   -> If found: Stage 2. Record PR numbers and specific comments.

4. CHECK STAGE 3: AI-generated tests in CI.
   Look for:
   - Test files with AI authorship attribution committed to the repo
     (co-authored commits, bot-authored PRs adding tests)
   - Coverage thresholds enforced per module in workflow YAML
   - AI-proposed test framework improvements (PRs or issues)
   - Mutation testing configured (e.g., stryker, mutmut, cargo-mutants)
   - AI closing coverage gaps through committed test PRs
   -> If found: Stage 3. Record evidence.

5. CHECK STAGE 4: Test generation automated from specs.
   Look for:
   - Test suites generated from types, specs, or formal properties
   - Mutation testing automated and gating merges
   - AI-opened PRs closing coverage gaps autonomously
   - Test debt surfaces as scheduled PRs
   - Property-based test generation from type signatures
   -> If found: Stage 4. Record evidence.
```

**Sub-level criteria:**

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0 | Neither condition met | One condition substantially met (tests in CI OR AI config covers testing) | One fully met + other emerging |
| 1 | Tests run in CI + minimal testing in AI config | Tests in CI + AI config covers frameworks, coverage, and test types | Comprehensive test documentation + multiple test categories + emerging AI test suggestions |
| 2 | Occasional AI test suggestions in PRs | Regular AI coverage analysis + edge case suggestions | AI test review standard practice + emerging committed AI tests |
| 3 | Some AI-generated tests committed | Coverage enforced per module + mutation testing configured | Comprehensive AI test generation + mutation testing active |
| 4 | Tests generated from specs + mutation gated | Autonomous coverage gap closure + test debt tracked | Self-improving: test generation improves from feedback |

---

## 7. Release -- Scoring Process

**Condition A (practice active):** Automated build or release workflow exists in CI.
**Condition B (AI config):** AI config documents versioning conventions, changelog format, and release process.

```
1. CHECK STAGE 0:
   Is Condition A met? Is Condition B met?

   a. Condition A check:
      - Workflow YAML contains build or release job:
        "release", "deploy", "publish", "build", "package"
      - Automated release tooling configured:
        semantic-release, release-please, changesets, goreleaser,
        cargo-release, cabal upload
      - Release workflow triggered on tags, releases, or scheduled

   b. Condition B check:
      - AI config file present AND contains release-specific content:
        versioning conventions (semver, calver, etc.), changelog format
        (Keep a Changelog, Conventional Commits), release process documented

   -> Neither A nor B:
      Stage 0 (blank). Record "No signals."

   -> Only A (release workflow exists, no AI config for release):
      Stage 0 - Mid.
      Record "Release workflow exists ({workflow name}), no AI config covering
      release process."

   -> Only B (AI config covers release, no automated workflow):
      Stage 0 - Mid.
      Record "AI config covers release process, no automated release workflow."

   -> Both partially met:
      Stage 0 - High. Record specifics.

2. CHECK STAGE 1 (requires BOTH conditions):
   a. Condition A: At least one automated build or release workflow:
      - Workflow YAML contains build job that runs on push, PR, or schedule
      - OR release workflow triggered on tags/releases
      - Note: manual shell scripts (e.g., release.sh) do NOT satisfy Condition A
        — automation must be in CI
   b. Condition B: AI config file passes quality threshold AND contains:
      - Versioning conventions (semver, calver, or custom scheme)
      - Changelog format expectations
      - Release process overview (who approves, what triggers, what gates)
   -> If BOTH met: Stage 1. Determine sub-level.
   -> If only one: Stay at Stage 0 with appropriate sub-level.

3. CHECK STAGE 2: AI assisting with release prep.
   Look for:
   - AI-generated draft changelogs visible in PRs or release issues
   - AI PR summaries used for release notes
   - AI breaking-change detection in PR comments
   - AI summarizing changes between versions
   - AI flagging breaking changes during review
   -> If found: Stage 2. Record evidence.

4. CHECK STAGE 3: AI automating release artifacts.
   Look for:
   - Workflow YAML contains AI-generated changelog or version bump steps
   - Regression gating workflow before merge to main
   - Breaking change detection automated in pipeline
   - AI auto-generating release notes from commit/PR history
   -> If found: Stage 3. Record workflow references.

5. CHECK STAGE 4: Fully AI-automated release pipeline.
   Look for:
   - Fully automated release pipeline in workflow YAML
   - AI handling versioning, changelogs, and rollback decisions within policy
   - Humans approve release outcomes, not individual steps
   - Release cadence maintained automatically
   -> If found: Stage 4. Record evidence.
```

**Sub-level criteria:**

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0 | Neither condition met | One condition substantially met (release workflow OR AI config covers release) | One fully met + other emerging |
| 1 | Basic CI build + minimal release info in AI config | Release workflow + AI config covers versioning and changelog format | Comprehensive release documentation + automated pipelines + emerging AI changelogs |
| 2 | Occasional AI changelog drafts or PR summaries | Regular AI release assistance + breaking change detection | AI release prep standard practice + emerging pipeline signals |
| 3 | AI changelog generation in pipeline | Regression gating + automated breaking change detection | Comprehensive release automation + emerging full pipeline control |
| 4 | Automated pipeline + basic AI release decisions | AI manages versioning and rollback within policy | Self-improving: release process improves from outcome data |

---

## 8. Ops & Monitoring -- Scoring Process

**Condition A (practice active):** Monitoring/alerting infrastructure exists (dashboards, alerting rules, runbooks, OR documented external monitoring).
**Condition B (AI config):** AI config documents deployment topology, runbook locations, alert patterns, and escalation paths.

**Special handling:** Library repos (repos that are not services and have no production deployment) receive Stage 0 with annotation "(n/a -- library)". The Ops weight (0.10) is redistributed proportionally to remaining dimensions.

To determine if a repo is a library:
- Package manifest indicates library (e.g., Cargo.toml with `[lib]` only, `.cabal` with library stanza only)
- No deployment workflow, no Dockerfile/container config, no infrastructure code
- README describes usage as a dependency, not a running service
- If ambiguous, assess as a service (benefit of the doubt)

```
0. PRE-CHECK: Is this a library repo?
   If yes: Stage 0 with annotation "(n/a -- library, not a service)."
   Weight redistributed. Skip remaining checks.

1. CHECK STAGE 0:
   Is Condition A met? Is Condition B met?

   a. Condition A check:
      - Monitoring/alerting config present:
        dashboard definitions, alerting rules, Grafana/Datadog/PagerDuty config
      - Runbooks or incident response docs:
        runbooks/ directory, INCIDENT.md, on-call documentation
      - Deployment manifests indicating a running service:
        Dockerfile, docker-compose, k8s manifests, terraform, pulumi,
        serverless config, AWS/GCP/Azure deployment config
      - Documented external monitoring (referenced in AI config or README)

   b. Condition B check:
      - AI config file present AND contains ops-specific content:
        deployment topology (what runs where), runbook locations,
        alert patterns, escalation paths, on-call procedures

   -> Neither A nor B:
      Stage 0 (blank). Record "No signals."

   -> Only A (monitoring exists, no AI config for ops):
      Stage 0 - Mid.
      Record "Monitoring infrastructure present, no AI config covering ops context."

   -> Only B (AI config covers ops, no monitoring infrastructure):
      Stage 0 - Mid.
      Record "AI config covers ops context, no monitoring infrastructure found."

   -> Both partially met:
      Stage 0 - High. Record specifics.

2. CHECK STAGE 1 (requires BOTH conditions):
   a. Condition A: Monitoring/alerting infrastructure confirmed:
      - Alerting rules or dashboard definitions in repo or referenced config
      - OR deployment manifest with health check endpoints
      - OR documented external monitoring system
   b. Condition B: AI config file passes quality threshold AND contains:
      - Deployment topology (services, infrastructure, dependencies)
      - Runbook locations (where to find incident procedures)
      - Alert patterns (what alerts exist, what they mean)
      - Escalation paths (who to contact, in what order)
   -> If BOTH met: Stage 1. Determine sub-level.
   -> If only one: Stay at Stage 0 with appropriate sub-level.

3. CHECK STAGE 2: AI assists during incidents.
   Look for:
   - AI-generated triage comments on issues (log summaries, correlation)
   - AI root-cause suggestions in project history or issue comments
   - AI-generated deployment risk assessments on infrastructure PRs
   - AI log summaries or anomaly descriptions
   - AI correlating recent deploys with observed issues
   -> If found: Stage 2. Record issue numbers and specific comments.

4. CHECK STAGE 3: AI integrated in monitoring.
   Look for:
   - AI anomaly detection configured (workflow or monitoring config)
   - Alerting thresholds calibrated by AI baselines
   - AI-assisted incident triage reducing mean time to diagnosis
   - Scheduled AI monitoring reviews
   -> If found: Stage 3. Record evidence.

5. CHECK STAGE 4: AI ops autonomous within policy.
   Look for:
   - Autonomous runbook execution evidence (self-healing workflows)
   - AI-drafted post-mortems in issues or docs
   - Engineers review AI decisions, not individual alerts
   - AI proposes architectural mitigations based on incident patterns
   -> If found: Stage 4. Record evidence.
```

**Sub-level criteria:**

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0 | Neither condition met (or n/a library) | One condition substantially met (monitoring exists OR AI config covers ops) | One fully met + other emerging |
| 1 | Basic monitoring + minimal ops in AI config | Monitoring with alerting + AI config covers topology and escalation | Comprehensive monitoring + detailed AI config + emerging AI incident assistance |
| 2 | Occasional AI triage comments | Regular AI incident assistance + deployment risk assessments | AI incident support standard practice + emerging anomaly detection |
| 3 | Basic AI anomaly detection | AI-calibrated alerting + AI incident triage active | Comprehensive AI monitoring + emerging self-healing |
| 4 | Self-healing for known patterns | AI post-mortems + autonomous runbook execution | Self-improving: monitoring adapts from incident data automatically |

---

## 9. AI-Assisted Delivery -- Scoring Process

**Condition A (practice active):** Issue tracking active (GitHub Issues/Projects enabled, OR external tool documented in AI config).
**Condition B (AI config):** AI config documents delivery workflow, estimation approach, Definition of Done, sprint cadence.

**Note (Gap 5 fix):** Stage 1 accepts documented external tools. If a team uses Linear, Jira, or another tool and documents this in their AI config, Condition A is satisfied. Stage 2+ signals are measured only through GitHub-visible signals; if delivery tracking is partially external, add annotation "delivery tracking partially external."

```
0. PRE-CHECK: Does the repo use GitHub Issues or Projects, or document
   external delivery tools in AI config?
   - Check if repo has issues enabled (GitHub API)
   - Check if repo is linked to any GitHub Project (GraphQL projectsV2)
   - Check if AI config mentions external tools (Linear, Jira, etc.)
   -> If none of the above: Score 0 (blank).
      Record "Delivery tracking not in GitHub and no external tool documented."

1. CHECK STAGE 0:
   Is Condition A met? Is Condition B met?

   a. Condition A check:
      - GitHub Issues enabled with recent activity (issues created/closed
        within lookback window)
      - GitHub Projects linked to the repo
      - OR external delivery tool documented in AI config

   b. Condition B check:
      - AI config file present AND contains delivery-specific content:
        issue templates, labelling conventions, estimation approach,
        definition of done, sprint cadence, board structure

   -> Neither A nor B:
      Stage 0 (blank). Record "No signals."

   -> Only A (issue tracking active, no AI config for delivery):
      Stage 0 - Mid.
      Record "Issue tracking active ({platform}), no AI config covering
      delivery workflow."

   -> Only B (AI config covers delivery, no issue tracking):
      Stage 0 - Mid.
      Record "AI config covers delivery workflow, no issue tracking active."

   -> Both partially met:
      Stage 0 - High. Record specifics.

2. CHECK STAGE 1 (requires BOTH conditions):
   a. Condition A: Issue tracking confirmed active:
      - GitHub Issues with recent activity (issues opened/closed in lookback window)
      - OR GitHub Projects with cards/items
      - OR external tool documented in AI config with specific details
        (project URL, workflow description)
   b. Condition B: AI config file passes quality threshold AND contains:
      - Delivery workflow (how work flows from idea to done)
      - Issue templates or labelling conventions
      - Estimation approach (how effort is estimated)
      - Definition of done (what "done" means for this project)
   -> If BOTH met: Stage 1. Determine sub-level.
   -> If only one: Stay at Stage 0 with appropriate sub-level.

3. CHECK STAGE 2: AI active in delivery tasks.
   Look for:
   - Issues authored or refined by AI bots
   - AI-generated issues from bug reports or feature requests
   - AI comments suggesting work decomposition on issues
   - AI-generated status summaries on project boards
   - AI flagging blocked or stale items
   - AI creating well-structured issues from bug reports
   -> If found: Stage 2. Record issue numbers.

4. CHECK STAGE 3: Delivery automation running.
   Look for:
   - Scheduled workflows generating status reports
   - Automated stale/overdue issue detection (bot-labelled)
   - Estimation accuracy tracked in issues or project metadata
   - Scope change detection in milestones
   - AI-driven sprint/iteration reporting
   -> If found: Stage 3. Record evidence.

5. CHECK STAGE 4: AI managing delivery workflow.
   Look for:
   - AI-assisted decomposition and estimation as default workflow
   - AI-maintained delivery dashboards
   - AI-generated retrospective insights
   - Evidence of estimation model improvement over time
   - AI managing work prioritization within policy
   -> If found: Stage 4. Record evidence.
```

**Sub-level criteria:**

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0 | Neither condition met | One condition substantially met (issue tracking OR AI config covers delivery) | One fully met + other emerging |
| 1 | Issue tracking + minimal delivery in AI config | Active issue tracking + AI config covers workflow, estimation, and DoD | Comprehensive delivery documentation + issue templates + emerging AI issue activity |
| 2 | Occasional AI-generated issues or comments | Regular AI delivery assistance + decomposition suggestions | AI delivery support standard practice + emerging automation |
| 3 | Basic stale issue detection | Automated status reports + estimation tracking | Comprehensive delivery automation + emerging AI management |
| 4 | AI decomposition default + dashboards maintained | Retrospective insights generated + estimation models active | Self-improving: delivery workflow optimized from outcome data |

---

## 10. AI Practices & Governance -- Scoring Process

**Condition A (practice active):** At least one AI tool actively configured (config file present with substantive content).
**Condition B (AI config):** AI usage expectations documented, `.aiignore` or `.cursorignore` for sensitive paths.

This is the cross-cutting dimension. It measures the maturity of AI tooling practices themselves, not any specific SDLC concern.

```
1. CHECK STAGE 0:
   Is Condition A met? Is Condition B met?

   a. Condition A check:
      - Any accepted AI config file present from the complete list (Section 3)?
      - Does the file contain substantive content (quality threshold)?

   b. Condition B check:
      - AI usage expectations documented:
        Which AI tools to use, when to use them, attribution expectations,
        review requirements for AI output
      - .aiignore or .cursorignore present (sensitive path exclusion)

   -> Neither A nor B:
      Stage 0 (blank). Record "No signals. No AI tooling configured."

   -> Only A (AI tool configured, no usage expectations):
      Stage 0 - Mid.
      Record "AI tool configured ({file}), no usage expectations documented."

   -> Only B (usage expectations documented, no active AI tool):
      Stage 0 - Mid.
      Record "AI usage expectations exist, no AI tool actively configured."

   -> Both partially met:
      Stage 0 - High. Record specifics.

2. CHECK STAGE 1 (requires BOTH conditions):
   a. Condition A: At least one AI tool actively configured:
      - Config file present with substantive content (not stub)
      - File is meaningful for the project (describes how AI should work here)
   b. Condition B: AI usage expectations documented:
      - Which tools the team uses and for what purpose
      - Attribution expectations (how to credit AI contributions)
      - .aiignore or .cursorignore present for sensitive paths
      OR usage expectations are embedded in the AI config file itself
   -> If BOTH met: Stage 1. Determine sub-level.
   -> If only one: Stay at Stage 0 with appropriate sub-level.
   -> NOTE: Single AI tool caps sub-level at Mid (cross-pillar constraint).

3. CHECK STAGE 2: Multi-tool config and orchestration patterns.
   Look for:
   - Multi-tool configuration: 2+ distinct AI tools configured
     (e.g., CLAUDE.md + .github/copilot-instructions.md)
   - Agent orchestration patterns:
     AGENTS.md with specialized agent roles
     .claude/commands/ directory with custom commands
     MCP server configurations (.mcp.json, mcp.json)
   - AI attribution in commits:
     Co-authored-by patterns in commit messages
   - Human-AI review gates documented in CONTRIBUTING.md
   Count distinct AI tools configured. Check for orchestration files.
   -> If found: Stage 2. Record tool count, orchestration files, attribution patterns.

4. CHECK STAGE 3: AI governance in CI.
   Look for:
   - AI governance policy enforced in CI
     (workflow steps that validate AI config, check attribution, etc.)
   - Agent workflows automated (skills triggered on events)
   - AI output quality tracked (merge rates of AI PRs, review cycle data)
   - Version pinning on AI tools and models
   - Cross-dimension AI standards documented and maintained
   -> If found: Stage 3. Record evidence.

5. CHECK STAGE 4: Org-wide AI governance.
   Look for:
   - Org-wide AI governance framework
   - Cross-repo agent orchestration
   - Self-improving AI configuration with documented feedback loops
     (config changes correlated with usage outcomes)
   - New repos inherit AI standards automatically (template evidence)
   - AI effectiveness compounds — measurable improvement quarter over quarter
   -> If found: Stage 4. Record evidence.
```

**Sub-level criteria:**

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0 | Neither condition met, no AI tooling | One condition substantially met (AI tool configured OR usage expectations documented) | One fully met + other emerging |
| 1 | Single AI tool with basic config (cap: Mid for single tool) | Single tool with comprehensive config + .aiignore | Multiple tools partially configured + emerging orchestration patterns |
| 2 | 2 AI tools configured + basic orchestration | Multi-tool config + AGENTS.md or custom commands + attribution in commits | Comprehensive multi-tool setup + MCP configs + governance in CONTRIBUTING.md |
| 3 | Basic AI governance in CI | Quality tracking + version pinning + cross-dimension standards | Comprehensive governance + automated agent workflows |
| 4 | Org-wide framework adopted | Cross-repo orchestration + documented feedback loops | Self-improving: AI configuration evolves from outcome data, compounding effectiveness |

---

## 11. Learning Signal Assessment Process

Learning signals annotate each dimension, enriching the sub-level assessment. They measure whether AI configuration is static, evolving, or self-improving.

### What to Inspect

For each AI config file associated with a dimension:

1. **Commit history on AI config files:**
   - Fetch the commit log for the specific file (e.g., `CLAUDE.md`, `.github/copilot-instructions.md`)
   - Record: creation date, total commit count, most recent commit date, date range of changes

2. **Content evolution:**
   - Compare the first committed version with the current version (diff size)
   - Check for evidence of refinement (not just typo fixes — substantive changes to conventions, patterns, or architecture sections)

3. **Custom commands/skills:**
   - If `.claude/commands/` or equivalent exists, check commit history
   - Are commands being added or refined over time?

4. **Feedback patterns:**
   - Does the config contain feedback-derived content? ("When X doesn't work, do Y", "Prefer A over B because of past issues")
   - Are there documented anti-patterns that suggest learning from experience?

5. **Cross-repo patterns:**
   - Does the config reference or inherit from other repos?
   - Is there evidence of a shared template being adapted locally?

### Classification Thresholds

| Classification | Criteria | Evidence |
|---|---|---|
| **static** | AI config written once, no meaningful updates since creation | 0-1 commits after initial creation, OR no commits in 90+ days, OR only trivial changes (whitespace, typos) |
| **evolving** | AI config updated based on usage with meaningful refinement | 2+ substantive commits after creation within the lookback period, OR meaningful updates correlating with usage patterns (e.g., config updated after period of AI PR activity) |
| **self-improving** | Automated feedback loops driving config evolution | Automated commits updating config, cross-repo propagation evidence, config changes triggered by CI outcomes, documented feedback loop mechanisms |

### Impact on Sub-Levels

| Learning Signal | Impact |
|---|---|
| **static** | Dimension cannot be rated High within its current stage. If evidence otherwise suggests High, cap at Mid. |
| **evolving** | No adjustment. Normal sub-level assignment. |
| **self-improving** | Sub-level boost: Low -> Mid, Mid -> High. If already High, no change (already at maximum). |

### Decision Tree

```
1. Fetch commit history for AI config file(s) relevant to this dimension.

2. Count substantive commits after initial creation:
   -> 0 commits after creation, OR no commits in 90+ days:
      Learning = "static"
   -> 1 commit after creation within 90 days:
      Inspect diff. If trivial (whitespace, typo): Learning = "static"
      If substantive (new sections, refined conventions): Learning = "evolving"
   -> 2+ substantive commits within lookback period:
      Learning = "evolving"
   -> Automated commits detected, OR cross-repo propagation, OR
      documented feedback loop mechanism:
      Learning = "self-improving"

3. Record the learning classification and evidence (commit dates, diff summary).
```

---

## 12. Sub-Level Determination Guidelines

This section provides the consolidated lookup matrix that agents use during scoring. For each dimension at each stage, the criteria define what distinguishes Low, Mid, and High.

### Code Quality

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0 | No signals at all | Linter/formatter active (Cond A met) OR AI config present (Cond B met) | Linter active + partial AI config covering some conventions |
| 1 | Basic config (short, generic) + linter present but not enforced in CI | Config covers conventions + architecture + linter running in CI | Comprehensive config including patterns, anti-patterns, examples + emerging AI PRs |
| 2 | 1-2 co-authored commits or single bot PR | Multiple AI PRs + AI review comments + co-authored commits | Heavy AI workflow integration: regular AI PRs, reviews, and refactoring suggestions |
| 3 | Single AI quality gate in CI | Multiple AI quality checks + automated refactoring PRs | AI quality gates comprehensive + documentation gaps detected in CI |
| 4 | Org template adopted, basic refinement | Active refinement across repos + CONTRIBUTING.md documents AI standards | Self-improving: config evolves from team feedback, measurable quality improvement |

### Security

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0 | No signals at all | Scanning active (Dependabot/Renovate) OR AI config covers security | Scanning active + partial security context in AI config |
| 1 | Dependabot only + minimal security in AI config | Multiple scanning tools + security trust boundaries documented | Comprehensive scanning + detailed data flows + emerging AI security reviews |
| 2 | Occasional AI security comments on PRs | Regular AI security flagging + CVE notifications | AI security review standard practice + auto-fix suggestions emerging |
| 3 | Single AI security gate blocking merges | AI SAST + auto-remediation PRs for CVEs | Comprehensive pipeline security + scheduled scanning + emerging threat modelling |
| 4 | Supply chain verification on builds | Active AI threat modelling + automated CVE remediation | Continuous threat assessment + self-improving security posture |

### Testing

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0 | No signals at all | Tests run in CI (Cond A met) OR AI config covers testing (Cond B met) | Tests in CI + partial testing context in AI config |
| 1 | Tests in CI + minimal testing info in AI config | Tests in CI + AI config covers frameworks, coverage targets, test types | Comprehensive test docs + multiple test categories + emerging AI test suggestions |
| 2 | Occasional AI test suggestions in PR comments | Regular AI coverage analysis + edge case identification | AI test review standard + committed AI-suggested test improvements |
| 3 | Some AI-generated tests committed to repo | Coverage enforced per module + mutation testing configured | Comprehensive AI test generation + mutation testing active + test debt tracked |
| 4 | Tests generated from types/specs | Autonomous coverage gap closure + mutation testing gated | Self-improving: test generation adapts from codebase changes |

### Release

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0 | No signals at all | Release workflow exists (Cond A met) OR AI config covers release (Cond B met) | Release workflow + partial release context in AI config |
| 1 | Basic CI build + minimal release info in AI config | Release workflow with tags/versioning + AI config covers versioning and changelog | Comprehensive release docs + automated pipeline + emerging AI changelogs |
| 2 | Occasional AI changelog drafts | Regular AI release assistance + breaking change flagging | AI release prep standard practice + emerging pipeline integration |
| 3 | AI changelog generation in pipeline | Regression gating + breaking change detection automated | Comprehensive release automation + emerging full pipeline |
| 4 | Automated pipeline + basic AI decisions | AI versioning and rollback within policy | Self-improving: release process optimized from outcome data |

### Ops & Monitoring

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0 | No signals (or n/a library) | Monitoring exists (Cond A met) OR AI config covers ops (Cond B met) | Monitoring + partial ops context in AI config |
| 1 | Basic monitoring + minimal ops in AI config | Monitoring with alerting + AI config covers topology and escalation | Comprehensive monitoring + detailed AI ops config + emerging AI triage |
| 2 | Occasional AI triage comments on incidents | Regular AI incident assistance + deployment risk assessments | AI incident support standard + root cause analysis emerging |
| 3 | Basic AI anomaly detection active | AI-calibrated alerting + incident triage active | Comprehensive AI monitoring + emerging self-healing patterns |
| 4 | Self-healing for known failure patterns | AI post-mortems + autonomous runbook execution | Self-improving: monitoring adapts from incident data automatically |

### AI-Assisted Delivery

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0 | No signals at all | Issue tracking active (Cond A met) OR AI config covers delivery (Cond B met) | Issue tracking + partial delivery context in AI config |
| 1 | Issue tracking + minimal delivery in AI config | Active issues + AI config covers workflow, estimation, DoD | Comprehensive delivery docs + templates + emerging AI issues |
| 2 | Occasional AI-generated issues or comments | Regular AI delivery suggestions + decomposition assistance | AI delivery support standard + emerging automation |
| 3 | Basic stale issue detection automated | Status reports + estimation tracking active | Comprehensive delivery automation + emerging AI management |
| 4 | AI decomposition default + dashboards | Retrospective insights + estimation models improving | Self-improving: delivery workflow optimized from retrospective data |

### AI Practices & Governance

| Stage | Low | Mid | High |
|-------|-----|-----|------|
| 0 | No AI tooling at all | AI tool configured (Cond A met) OR usage expectations documented (Cond B met) | AI tool configured + partial usage expectations |
| 1 | Single tool, basic config (capped at Mid) | Single tool, comprehensive config + .aiignore (max for single tool) | Multiple tools partially configured + emerging orchestration |
| 2 | 2 tools configured + basic orchestration | Multi-tool + AGENTS.md or custom commands + attribution | Comprehensive multi-tool + MCP + governance in CONTRIBUTING.md |
| 3 | Basic governance in CI | Quality tracking + version pinning + standards documented | Comprehensive governance + automated agent workflows |
| 4 | Org-wide framework adopted | Cross-repo orchestration + feedback loops documented | Self-improving: AI configuration evolves from outcome data |

---

## 13. Minimum Viability Thresholds

These 7 thresholds flag engineering risks **regardless of AI adoption**. They are checked in EVERY assessment and reported as `minimum_viability_risks` if unmet.

### 1. CI/CD

- **Threshold:** At least one automated build/test workflow.
- **How to check:** `.github/workflows/` contains at least one `.yml` file with build or test steps.
- **API call:** List directory contents of `.github/workflows/`. Fetch each YAML file and verify it contains actionable steps (not just a stub).
- **Risk if unmet:** No automated quality gate — every merge is manual trust. Cannot progress beyond Stage 1 on dimensions requiring pipeline (Stage 3+).

### 2. Dependency Scanning

- **Threshold:** Dependabot, Renovate, or language-specific equivalent active.
- **How to check:** `.github/dependabot.yml` exists with package-ecosystem entries, OR `renovate.json`/`.renovaterc` exists, OR workflow YAML references scanning tools (`cargo-deny`, `cargo audit`, `cabal audit`, `npm audit`, etc.).
- **API call:** Check file existence, then fetch content to verify configuration.
- **Risk if unmet:** Unmonitored supply chain — CVEs go undetected.

### 3. Security Policy

- **Threshold:** `SECURITY.md` or equivalent disclosure process.
- **How to check:** `SECURITY.md` exists in repo root or `.github/SECURITY.md`.
- **API call:** Check file existence at both paths.
- **Risk if unmet:** No clear path for vulnerability reporting.

### 4. Test Automation

- **Threshold:** At least one test suite runs in CI.
- **How to check:** Workflow YAML contains test execution step (e.g., `cabal test`, `cargo test`, `npm test`, `pytest`, `jest`, `vitest`, `go test`).
- **API call:** Fetch all workflow YAML files, search for test execution commands.
- **Risk if unmet:** No automated regression detection.

### 5. Branch Protection

- **Threshold:** Main/master branch requires PR review before merge.
- **How to check:** Branch protection API returns `required_pull_request_reviews` enabled for the default branch.
- **API call:** `GET /repos/{owner}/{repo}/branches/{branch}/protection` — check `required_pull_request_reviews` object exists and `required_approving_review_count >= 1`.
- **Risk if unmet:** Direct pushes bypass all quality checks.

### 6. PR Review Enforcement

- **Threshold:** No PRs merged without at least one review.
- **How to check:** Sample the 10 most recently merged PRs. For each, check `review_count > 0` or `approved_review_count >= 1`.
- **API call:** List merged PRs, then fetch reviews for each. Flag if any merged PR has zero reviews.
- **Risk if unmet:** Code reaches main without human review — high risk.

### 7. Issue Tracking

- **Threshold:** GitHub Issues or Projects active for the repo.
- **How to check:** Repo has issues enabled (GitHub API `has_issues` field) and/or is linked to a GitHub Project.
- **API call:** `GET /repos/{owner}/{repo}` for `has_issues`, GraphQL `projectsV2` query for Projects.
- **Risk if unmet:** Work is invisible to stakeholders.

---

## 14. Adoption-Side Cross-Pillar Constraints

These guardrails are enforced during scoring to prevent misleading results. They come from model-spec.md Section 6.

### Single AI Tool Cap

**Rule:** If AI Practices & Governance Stage 1 is achieved through a single AI tool only, the AI Practices sub-level is capped at Mid.

**How to check:** During AI Practices scoring, count distinct AI tools configured. If exactly 1, apply the cap regardless of other signals.

**Rationale:** One config file does not indicate team-wide AI commitment. Multi-tool adoption is a stronger signal.

### Stale AI Configs Penalty

**Rule:** AI config files unchanged in more than 6 months — the dimension associated with that config cannot be rated above Low sub-level.

**How to check:** For each AI config file, fetch the most recent commit date. If the most recent commit is older than 180 days from the snapshot date, apply the penalty to all dimensions that rely on that file for Condition B.

**Rationale:** Outdated AI instructions actively mislead AI tools. A config that described the project a year ago may no longer reflect current architecture, conventions, or boundaries.

**Application:**
1. Check the last commit date on each AI config file.
2. If any config file has not been updated in >180 days, flag it.
3. For each dimension where that file satisfies Condition B, cap the sub-level at Low.
4. Record the annotation: "Stale AI config ({filename}, last updated {date}) -- sub-level capped at Low."

### Cumulative Enforcement

**Rule:** Stage 2 signals without Stage 1 foundation: score as Stage 0 with annotation.

**How to check:** If Stage 2+ signals are detected but Stage 1 conditions are not both met, score Stage 0 and add annotation: "Stage 2 signals emerging without Stage 1 foundation."

**Rationale:** This is demand signal, not failure. Record the signals and recommend completing Stage 1 first.

---

## 15. Edge Cases

### Haskell & Nix Repos

Nix flakes, Hydra CI, hlint, fourmolu, `-Werror`, `cabal audit`, `cabal check` are noted as **infrastructure readiness** signals. They satisfy Condition A for relevant adoption dimensions (hlint satisfies Code Quality Condition A; cabal audit satisfies Security Condition A) but do not by themselves advance the AI adoption score. When AI config is added, existing infrastructure makes transitions to Stage 1 immediate for those dimensions.

### AI PRs Without AI Config

Score all affected dimensions as **Stage 0** with annotation: "Stage 2 signals emerging without Stage 1 config." The activity is demand signal — adding project context (AI config) would improve AI work already happening. Record the PR numbers and bot names for evidence.

### Inaccessible Repos

If the `$GITHUB_TOKEN` does not grant access to a repository, score all dimensions as **N/A**. Exclude the repo from all aggregate calculations. Record: "Repository inaccessible -- excluded from assessment."

### Repos With No CI/CD

Score Testing, Release, and Ops as Stage 0 (Condition A not met). Cannot progress beyond Stage 1 on any dimension that requires pipeline integration for Stage 3+. Flag as a Minimum Viability risk. Note: Code Quality and AI-Assisted Delivery can still achieve Stage 1 without CI/CD if their specific conditions are met.

### Repos Not Using GitHub Issues/Projects

Score AI-Assisted Delivery based on what is documented:
- If external tool (Linear, Jira, etc.) is documented in AI config: Condition A can be satisfied. Proceed with Stage 1 assessment.
- If no delivery tool is documented: Stage 0 with annotation "Delivery tracking not in GitHub and no external tool documented."
- Stage 2+ is measured only through GitHub-visible signals. If tracking is partially external, annotate: "Delivery tracking partially external."

### Multi-Language Repos

Adoption dimensions are language-agnostic (same stages regardless of language). Score using signals from all languages present. Note the primary and secondary languages in the evidence. If different languages have different infrastructure maturity (e.g., Rust packages have extensive testing but TypeScript packages don't), note the discrepancy in annotations.

### Library Repos

Ops & Monitoring receives Stage 0 with annotation "(n/a -- library, not a service)." The Ops weight (0.10) is redistributed proportionally to remaining dimensions. All other dimensions are scored normally. This is informational, not a gap.

### Monorepos

Assess as a single repository. If sub-packages have significantly different AI adoption levels (e.g., one package has AI config while others don't), note the variance in annotations. Score based on the overall repository signals, not individual packages.

### Non-GitHub Delivery

If the team uses external delivery tools (Jira, Linear, Shortcut) and documents this in their AI config, Stage 1 on Delivery is achievable. Stage 2+ requires GitHub-visible signals. If the team's delivery workflow is entirely external and undocumented, Delivery stays at Stage 0.

### AI Config Across Multiple Files

A repo may have multiple AI config files (e.g., `CLAUDE.md` + `.github/copilot-instructions.md` + `.coderabbit.yaml`). For Condition B assessment, consider the **union** of content across all files. A dimension's Condition B is met if any combination of AI config files collectively covers the required topics. For AI Practices & Governance, multi-file configuration is a positive signal for Stage 2.

---

## 16. Confidence Levels

Each dimension receives a confidence level alongside its stage and sub-level.

| Confidence | Meaning | When to Use |
|------------|---------|-------------|
| **High** | Clear, unambiguous evidence | Observable signals match the stage definition directly. Both conditions clearly met or clearly not met. File contents are clear. Bot activity is unambiguous. |
| **Medium** | Partial signals or interpretation needed | Some signals present but not all. Signals in adjacent categories. Config quality is borderline. External tools referenced but not verified. |
| **Low** | Inferred or file-only evidence | Config file present but no evidence of active use. Signals are ambiguous. Assessment relies heavily on inference rather than direct observation. |

**Guidelines for confidence assignment:**

- Stage 0 with no signals: **High** confidence (clearly nothing there)
- Stage 0 with one condition met: **High** confidence (clear which condition is met and which is not)
- Stage 1 with clear conditions: **High** confidence
- Stage 1 with borderline quality check: **Medium** confidence (note: "Config quality borderline")
- Stage 2 with clear bot activity: **High** confidence
- Stage 2 with only co-authored commits (no bot PRs): **Medium** confidence
- Stage 3+ with clear pipeline evidence: **High** confidence
- Any stage where external tools are referenced but not verified: **Medium** confidence
- Any stage relying on inference: **Low** confidence

---

## 17. Measurement Cadence

- **Monthly snapshots** on or near the first working day of each month.
- **Repo list** from `models/config.yaml` at snapshot time.
- **Lookback window:** AI activity signals (PRs, commits, issues) are checked since the previous snapshot date. Config files and workflow YAML are checked as of the current snapshot.
- **Historical snapshots are immutable** — correct errors in the next snapshot and note the correction. Never overwrite `scans/ai-augmentation/results/YYYY-MM.json`.
- **Model and scoring are versioned** — changes tracked in `changelog.md`.
- **First v3 assessment:** If this is the first assessment under v3, all repos get `delta_from_previous: "New -- first v3 assessment"` regardless of whether v1 assessments exist.

---

## 18. Scoring Output Format

### Per-Dimension JSON Structure

Each dimension in the output includes the mapped score:

```json
{
  "stage": 1,
  "sub_level": "mid",
  "mapped_score": 27,
  "learning": "static",
  "confidence": "high",
  "evidence": "CLAUDE.md (4KB, covers architecture + conventions + test standards). Linter: clippy in CI (ci.yml:42). Learning: static (CLAUDE.md created 2025-11-15, no updates since)."
}
```

**Field definitions:**

| Field | Type | Description |
|---|---|---|
| `stage` | integer (0-4) | Highest stage fully achieved |
| `sub_level` | string ("low"/"mid"/"high") or null | Within-stage progress. Null only for Stage 0 with blank sub-level. |
| `mapped_score` | integer (0-100) | Numeric score from the Stage-to-Score Mapping table |
| `learning` | string or null | "static", "evolving", or "self-improving". Null if Stage 0 with no AI config. |
| `confidence` | string | "high", "medium", or "low" |
| `evidence` | string | Specific, verifiable evidence: file names, PR numbers, workflow references. Never generic. |

### Full Per-Repo JSON

```json
{
  "repo": "org/repo-name",
  "snapshot_date": "2026-04-01",
  "model_version": "v3.0",
  "languages": [
    { "language": "Rust", "percentage": 100 }
  ],
  "readiness": {
    "composite": 86,
    "pillars": {
      "structural_clarity":     { "score": 88, "evidence": "..." },
      "semantic_density":       { "score": 88, "evidence": "..." },
      "verification_infra":     { "score": 84, "evidence": "..." },
      "developer_ergonomics":   { "score": 81, "evidence": "..." }
    }
  },
  "adoption": {
    "composite": 18,
    "dimensions": {
      "code_quality":       { "stage": 1, "sub_level": "mid",  "mapped_score": 27, "learning": "static", "confidence": "high", "evidence": "..." },
      "security":           { "stage": 0, "sub_level": "mid",  "mapped_score": 7,  "learning": null,     "confidence": "medium", "evidence": "..." },
      "testing":            { "stage": 1, "sub_level": "low",  "mapped_score": 20, "learning": "static", "confidence": "high", "evidence": "..." },
      "release":            { "stage": 1, "sub_level": "low",  "mapped_score": 20, "learning": "static", "confidence": "high", "evidence": "..." },
      "ops_monitoring":     { "stage": 0, "sub_level": "low",  "mapped_score": 0,  "learning": null,     "confidence": "high", "evidence": "..." },
      "delivery":           { "stage": 1, "sub_level": "low",  "mapped_score": 20, "learning": "static", "confidence": "medium", "evidence": "..." },
      "ai_practices":       { "stage": 1, "sub_level": "low",  "mapped_score": 20, "learning": "static", "confidence": "high", "evidence": "..." }
    }
  },
  "quadrant": "Fertile Ground",
  "quadrant_sub_level": "High",
  "next_steps": [
    {
      "priority": 1,
      "action": "Confirm cargo-deny/cargo-audit runs in CI + add security trust boundaries to AI config",
      "effort": "low",
      "impact": [
        { "dimension": "security", "from_stage": 0, "from_sub": "mid", "to_stage": 1, "to_sub": "low" }
      ],
      "adoption_change": { "from": 18, "to": 20 }
    }
  ],
  "flags": [],
  "minimum_viability_risks": [],
  "anomalies": [],
  "infrastructure_readiness": ["cargo-deny", "clippy", "rustfmt", "deny.toml"],
  "delta_from_previous": "New -- first v3 assessment"
}
```

### Adoption Composite Worked Example: mithril

This example matches the mithril assessment from model-spec.md Section 15.

**Dimension scores:**

| Dimension | Stage | Sub-level | Mapped Score | Weight |
|-----------|-------|-----------|-------------|--------|
| Code Quality | 1 | Mid | 27 | 0.18 |
| Security | 0 | Mid | 7 | 0.15 |
| Testing | 1 | Low | 20 | 0.18 |
| Release | 1 | Low | 20 | 0.12 |
| Ops & Monitoring | 0 | Low | 0 | 0.10 |
| AI-Assisted Delivery | 1 | Low | 20 | 0.12 |
| AI Practices | 1 | Low | 20 | 0.15 |

**Calculation:**

```
Adoption = 0.18 * 27  +  0.15 * 7   +  0.18 * 20  +  0.12 * 20
         + 0.10 * 0   +  0.12 * 20  +  0.15 * 20

         = 4.86  +  1.05  +  3.60  +  2.40
         + 0.00  +  2.40  +  3.00

         = 17.31

Rounded: 18 (values are rounded to the nearest integer for display)
```

**After recommended Step 1 (Security Stage 0 Mid -> Stage 1 Low):**

```
Change: Security mapped_score 7 -> 20
Delta: 0.15 * (20 - 7) = 0.15 * 13 = 1.95
New composite: 17.31 + 1.95 = 19.26 -> 20 (rounded)
```

**After recommended Step 2 (Code Quality Stage 1 Mid -> Stage 2 Low):**

```
Change: Code Quality mapped_score 27 -> 40
Delta: 0.18 * (40 - 27) = 0.18 * 13 = 2.34
New composite: 19.26 + 2.34 = 21.60 -> 22 (rounded)
```

**After recommended Step 3 (AI Practices Stage 1 Low -> Stage 1 Mid):**

```
Change: AI Practices mapped_score 20 -> 27
Delta: 0.15 * (27 - 20) = 0.15 * 7 = 1.05
New composite: 21.60 + 1.05 = 22.65 -> 23 (rounded)
```

### Weight Redistribution Example: Library Repo (Ops Excluded)

When Ops & Monitoring is n/a, its weight (0.10) is redistributed:

```
Remaining weight sum = 1.00 - 0.10 = 0.90

Adjusted weights:
  Code Quality:       0.18 / 0.90 = 0.200
  Security:           0.15 / 0.90 = 0.167
  Testing:            0.18 / 0.90 = 0.200
  Release:            0.12 / 0.90 = 0.133
  Delivery:           0.12 / 0.90 = 0.133
  AI Practices:       0.15 / 0.90 = 0.167
                                     ─────
  Sum:                               1.000
```

---

## Anti-Gaming Provisions

### AI Config Quality Threshold (Stage 1)

Detailed in Section 3 under "AI Config Quality Threshold." The key principle: "File exists" is necessary but not sufficient. An AI config file counts toward Stage 1 only if it contains meaningful project context.

### Present vs Active

For Stage 1+, the agent distinguishes:
- **Present:** The artifact exists (file committed, bot installed)
- **Active:** The artifact is being used (recent edits, bot activity, pipeline runs referencing AI)

Sub-levels incorporate this distinction: a "present but not active" config gets Low sub-level. Active usage signals push toward Mid and High. A dimension at "Stage 1, Low confidence" for three consecutive months signals the config exists but is not being used — the data tells the story.

### Cumulative Stage Enforcement

Detailed in Section 14. Stage 2 signals without Stage 1 foundation: score as **Stage 0** with annotation. Track as a priority gap — this is demand signal, not a failure.

### Stage 4 Learning Evidence

Stage 4 requires not just standardisation but evidence of improvement over time. If standardisation signals are present but no learning evidence exists, score as Stage 3 with annotation: "Standardised but no learning signals detected." See Section 11 for the learning signal assessment process.
