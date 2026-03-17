# 📐 CBU: AI Augmentation Scoring Methodology

> **⚠️ DEPRECATED:** This is AAMM v1 scoring. Superseded by v3. See [`models/ai-augmentation-maturity-v3/adoption-scoring.md`](../ai-augmentation-maturity-v3/adoption-scoring.md) and [`readiness-scoring.md`](../ai-augmentation-maturity-v3/readiness-scoring.md).

**Owner:** CoE · Dorin Solomon · **Status:** Draft v3.4 · **Last updated:** March 2026

This document defines how observable GitHub signals translate into stage scores, and how the automated measurement process works. For what each stage and dimension means, see the [📶 Maturity Model](./model.md). For the list of tracked repositories, see `models/config.yaml`.

Scoring is performed **per repository**. Each repo receives one score (0–4) per dimension, a confidence level per dimension, and an overall stage. Organisation-level maturity is derived from the distribution of repo scores.

---

## General Scoring Rules

1. **Each dimension scores 0–4.** The score represents the highest stage fully achieved.
2. **Stages are cumulative.** A repo cannot score Stage 2 without satisfying Stage 1. If Stage 2 signals appear without Stage 1 foundation (e.g., AI-authored PRs but no AI config), score as 0 and note the anomaly.
3. **Non-AI tooling does not advance the AI augmentation score.** Dependabot, hlint, Nix flakes, `-Werror` — these are strong engineering practices noted as *infrastructure readiness*. They facilitate future stage transitions but are not AI augmentation signals.
4. **Scores are tool-agnostic.** GitHub Copilot, Claude Code, Cursor, Gemini, or any other AI tool count equally. The model measures capability, not vendor adoption.

### Overall Stage Calculation

| Pattern | Overall Stage | Example |
|---------|--------------|---------|
| All dimensions at 0 | **0** | All zeros |
| 1 dimension at N, rest lower | **0→N** (transitioning) | CQ:1, rest 0 |
| 2+ dimensions at N | **N** (gaps noted) | CQ:1, Sec:1, rest 0 → **1** |
| Some dimensions advancing beyond N | **N→N+1** | CQ:2, Sec:1, Test:1, Del:1, rest 0 → **1→2** |

---

## How Automated Measurement Works

The monthly scan is executed by a Claude Code agent (or a human following the same steps). This section defines exactly what the agent checks and how it makes scoring decisions.

### Authentication

The agent authenticates with GitHub using the `$GITHUB_TOKEN` environment variable, which should already be set. **If the token is not available or authentication fails, stop and ask the human operator** — do not proceed without it. Never print, log, display, or save the token value.

### What to Retrieve from GitHub

For each tracked repository, the agent collects the following information. Use the GitHub API (REST or GraphQL) in whatever way is most effective — specific endpoints may change over time, so the requirement is defined by **what data is needed**, not how to fetch it.

| What to Get | Why | Where to Store |
|---|---|---|
| **List of files in repo root and `.github/` directory** | Detect AI config files, security policies, workflow definitions | Used during scoring, not stored separately |
| **Full text content of each AI config file found** | Assess quality (meaningful context vs stub) for Stage 1 scoring | Summarised in evidence field of results JSON |
| **All workflow YAML files** (`.github/workflows/*.yml`) | Detect AI quality gates, security gates, release automation, monitoring steps | Referenced by filename in evidence |
| **Pull requests** (merged, since last snapshot): author, title, body, review status, reviewers | Detect AI-authored PRs, unreviewed merges, AI review comments, PR template compliance | PR counts and numbers in evidence |
| **PR reviews** for recently merged PRs | Detect whether PRs were reviewed before merge (Minimum Viability check) | Summarised in minimum viability risks |
| **Recent commits** on default branch (since last snapshot) | Detect AI co-author attributions in commit messages | Count and patterns in evidence |
| **Issues** (recent, open, and recently closed) | Detect AI-generated issues, delivery workflow signals, stale/blocked items | Issue numbers in evidence |
| **GitHub Projects linked to the repo** | Detect delivery tracking, project board structure, status automation | Presence/absence noted in evidence |
| **Branch protection rules** for default branch | Detect PR review requirements, merge restrictions | Summarised in minimum viability risks |
| **Dependabot / Renovate configuration** | Detect dependency scanning status | Noted in infrastructure readiness |
| **Language-specific files** (see Language-Specific Infrastructure Signals below) | Detect infrastructure readiness signals per language ecosystem | Listed in infrastructure_readiness field |

### Where to Store Results

- **Machine-readable snapshots:** `scans/ai-augmentation/results/YYYY-MM.json` in the `cbu-coe-toolkit` repo. One file per monthly snapshot. Never overwrite previous snapshots.
- **Human-readable output:** Published to the Notion display pages (see `notion/page-registry.yaml` for page IDs). Notion is the presentation layer — GitHub is the source of truth.
- **Evidence:** Each dimension score includes a short evidence string citing specific file names, PR numbers, or workflow references. Never generic descriptions — always verifiable.

### Scoring Decision Process per Dimension

For each dimension, the agent follows this exact sequence. Every decision is recorded with the evidence that triggered it.

#### Code Quality — Scoring Process

```
1. CHECK: Does the repo contain any AI config file?
   Accepted files:
   - CLAUDE.md or claude.md in repo root
   - AGENTS.md in repo root
   - GEMINI.md in repo root
   - .github/copilot-instructions.md
   - .github/copilot-setup-steps.yml
   - .cursor/rules
   - .claude/settings.json
   - ai_run.sh in repo root
   - agent_docs/ directory in repo root
   This list should be updated as new AI tools emerge.
   → If none found: Score 0. Record "No AI config files."

2. ASSESS QUALITY: Fetch the content of each config file found.
   Check for meaningful project context:
   - Does it describe architecture, module boundaries, coding conventions?
   - Does it reference project-specific patterns, not just generic instructions?
   - Is it approximately 50+ lines of substantive content?
   → If file exists but fails quality check: Score 0.
     Record "Config present but insufficient — [reason]."
   → If passes: Stage 1 achieved. Record file name and quality assessment.

3. CHECK STAGE 2: Search for AI activity in the shared workflow.
   - Pull requests authored by AI bots:
     copilot[bot], github-copilot[bot]
     (update this list as new AI tools emerge that author PRs)
   - Commits containing AI co-author strings:
     "Co-authored-by: copilot", "Co-authored-by: Claude", "AI-generated"
   - PR review comments from AI bots
   - AI-generated PR summaries in PR descriptions
   - AI-opened fix, refactoring, or documentation PRs
   Count AI PRs since last snapshot date.
   → If no AI workflow activity: Stay at Stage 1.
   → If activity found: Stage 2 achieved. Record PR numbers, bot names, counts.

4. CHECK STAGE 3: Inspect workflow YAML files for AI quality gates.
   - Do any workflows reference AI tools (copilot, anthropic, openai,
     coderabbit, codeguru, or equivalent) that block or gate merges?
   - Are there AI-generated bug fix PRs opened from automated issue analysis?
   - Are there AI documentation generation steps in CI?
   → If no pipeline integration: Stay at Stage 2.
   → If found: Stage 3 achieved. Record workflow file names and relevant steps.

5. CHECK STAGE 4: Assess org-wide standardisation and learning signals.
   - Does the AI config follow a consistent template across multiple repos?
   - Is AI quality enforcement documented in CONTRIBUTING.md?
   - Is there evidence that AI config has been refined over time (commit history)?
   → If found: Stage 4 achieved. Record evidence.
```

#### Security — Scoring Process

```
1. CHECK STAGE 1 (two conditions required):
   a. Is automated dependency/security scanning active?
      Check for: .github/dependabot.yml, renovate.json,
      workflow YAML containing: codeql, trivy, snyk, semgrep,
      cargo-deny, cargo audit, cabal audit
   b. Is an AI config file present? (any file from the Code Quality check)
   → If both (a) AND (b): Stage 1 achieved.
   → If only scanning but no AI config: Score 0.
     Record "Security scanning active (infrastructure readiness) but no AI config."
   → If only AI config but no scanning: Score 0.
     Record "AI config present but no automated security scanning."

2. CHECK STAGE 2: Is AI surfacing vulnerabilities in PRs?
   - PR comments from Copilot Autofix or AI security bots
   - AI-powered SAST comments on PRs
   → If found: Stage 2. Record PR numbers and bot names.

3. CHECK STAGE 3: Is AI security integrated in the pipeline?
   - Workflow YAML contains AI security steps that block merges
   - Auto-remediation PRs opened by AI for known CVEs
   - Evidence of modern AI-powered SAST (beyond basic Dependabot):
     Claude security analysis, CodeQL with AI, or equivalent
   - Workflow steps that scan production code on schedule (not just PR-triggered)
   → If found: Stage 3. Record workflow references.

4. CHECK STAGE 4: Is there continuous threat modelling?
   - AI-generated security issues or threat assessments in repo
   - Architectural risk assessments in ADRs or issues
   - Supply chain verification step in every build workflow
   → If found: Stage 4. Record evidence.
```

#### Testing — Scoring Process

```
1. CHECK STAGE 1: Does AI config document testing standards?
   Fetch AI config content and check for:
   - Test frameworks, patterns, or conventions mentioned
   - Coverage expectations documented
   - Test types listed (unit, integration, property-based, E2E)
   → If found: Stage 1. Record what's documented.

2. CHECK STAGE 2: Is AI active in test review?
   - AI PR comments mentioning coverage, untested paths, or test suggestions
   - AI reviewing coverage at PR or project level
   - AI flagging missing test types
   → If found: Stage 2. Record PR numbers.

3. CHECK STAGE 3: Are AI-generated tests in CI?
   - Test files with AI authorship attribution committed to repo
   - Coverage thresholds enforced in workflow YAML
   - AI-proposed test framework improvements (PRs or issues)
   - Mutation testing configured
   → If found: Stage 3. Record evidence.

4. CHECK STAGE 4: Is test generation automated from specs?
   - Test suites generated from types or formal specs
   - Mutation testing automated and gating merges
   - AI-opened PRs closing coverage gaps
   → If found: Stage 4. Record evidence.
```

#### Release — Scoring Process

```
1. CHECK STAGE 1: Does AI config document release workflow?
   - Versioning conventions, changelog format, release process mentioned
   → If found: Stage 1.

2. CHECK STAGE 2: Is AI assisting with release prep?
   - AI-generated draft changelogs visible in PRs or release issues
   - AI PR summaries used for release notes
   - AI breaking-change detection in PR comments
   → If found: Stage 2. Record evidence.

3. CHECK STAGE 3: Is AI automating release artifacts?
   - Workflow YAML contains AI-generated changelog or version bump steps
   - Regression gating workflow before merge to main
   - Breaking change detection automated in pipeline
   → If found: Stage 3. Record workflow references.

4. CHECK STAGE 4: Is release fully AI-automated?
   - Fully automated release pipeline in workflow YAML
   - AI handling versioning, changelogs, and rollback within policy
   - Humans approve release outcomes, not individual steps
   → If found: Stage 4. Record evidence.
```

#### Ops & Monitoring — Scoring Process

```
1. CHECK STAGE 1: Does AI config document operational context?
   - Deployment topology, runbook locations, alert patterns, escalation paths
   → If found: Stage 1.

2. CHECK STAGE 2: Is AI assisting with incidents?
   - AI-generated triage comments on issues
   - AI log summaries or root-cause suggestions in project history
   → If found: Stage 2. Record issue numbers.

3. CHECK STAGE 3: Is AI integrated in monitoring?
   - AI anomaly detection in workflow or monitoring config
   - AI-calibrated alerting thresholds
   → If found: Stage 3. Record evidence.

4. CHECK STAGE 4: Are AI ops autonomous within policy?
   - Autonomous runbook execution evidence
   - AI-drafted post-mortems in issues or docs
   → If found: Stage 4. Record evidence.
```

#### AI-Assisted Delivery — Scoring Process

```
0. PRE-CHECK: Does the repo use GitHub Issues or Projects?
   - Check if repo has issues enabled
   - Check if repo is linked to any GitHub Project (GraphQL projectsV2)
   → If neither: Score 0. Record "Delivery tracking not in GitHub."

1. CHECK STAGE 1: Does AI config document delivery workflow?
   - Issue templates, board structure, labelling conventions
   - Estimation approach, definition of done, sprint cadence
   → If found: Stage 1.

2. CHECK STAGE 2: Is AI active in delivery tasks?
   - Issues authored or refined by AI bots
   - AI-generated issues from bug reports or feature requests
   - AI comments suggesting work decomposition on issues
   - AI-generated status summaries on project boards
   - AI flagging blocked or stale items
   → If found: Stage 2. Record issue numbers.

3. CHECK STAGE 3: Is delivery automation running?
   - Scheduled workflows generating status reports
   - Automated stale/overdue issue detection (bot-labelled)
   - Estimation accuracy tracked in issues or project metadata
   - Scope change detection in milestones
   → If found: Stage 3. Record evidence.

4. CHECK STAGE 4: Is AI managing delivery workflow?
   - AI-assisted decomposition and estimation as default
   - AI-maintained delivery dashboards
   - AI-generated retrospective insights
   - Evidence of estimation model improvement over time
   → If found: Stage 4. Record evidence.
```

### Scoring Output Format

For each repo, the agent produces:

```json
{
  "repo": "org/repo-name",
  "snapshot_date": "2026-04-01",
  "dimensions": {
    "code_quality":       { "stage": 1, "confidence": "high", "evidence": "..." },
    "security":           { "stage": 1, "confidence": "high", "evidence": "..." },
    "testing":            { "stage": 0, "confidence": "high", "evidence": "..." },
    "release":            { "stage": 0, "confidence": "high", "evidence": "..." },
    "ops_monitoring":     { "stage": 0, "confidence": "high", "evidence": "..." },
    "delivery":           { "stage": 0, "confidence": "high", "evidence": "..." }
  },
  "overall_stage": "0→1",
  "infrastructure_readiness": ["hlint", "fourmolu", "Nix flakes", "Dependabot"],
  "minimum_viability_risks": ["No SECURITY.md"],
  "anomalies": [],
  "delta_from_previous": "New — first assessment"
}
```

---

## Anti-Gaming Provisions

### AI Config Quality Threshold (Stage 1)

"File exists" is necessary but not sufficient. An AI config file counts toward Stage 1 only if it contains **meaningful project context.**

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
- Files containing only tool configuration with no project context

If a file fails the quality check, score the dimension as 0 with annotation: "Config present but insufficient — [specific reason]."

### Present vs Active

For Stage 1+, we distinguish:
- **Present:** The artifact exists (file committed, bot installed)
- **Active:** The artifact is being used (recent edits, bot activity, pipeline runs referencing AI)

Scores are based on "present" (benefit of the doubt), but "active" status is tracked. A dimension at "Stage 1, Low confidence" for three consecutive months signals the config exists but isn't being used — the data tells the story.

### Cumulative Stage Enforcement

Stage 2 signals without Stage 1 foundation: score as **0** with annotation "Stage 2 signals emerging without Stage 1 config." Track as a priority gap — this is demand signal, not a failure.

### Stage 4 Learning Evidence

Stage 4 requires not just standardisation but evidence of improvement over time. The agent checks:
- Has the AI config file been meaningfully updated since initial creation? (commit history)
- Are there patterns of AI suggestion refinement? (e.g., config edits following periods of AI PR activity)
- Is the org-wide template versioned and evolving?

If standardisation signals are present but no learning evidence exists, score as Stage 3 with annotation "Standardised but no learning signals detected."

---

## Confidence Levels

| Confidence | Meaning | When to Use |
|------------|---------|-------------|
| **High** | Clear, unambiguous evidence | Observable signals match the stage definition directly |
| **Medium** | Partial signals or interpretation needed | Some signals present but not all, or signals in adjacent categories |
| **Low** | Inferred or file-only evidence | Config file present but no evidence of active use |

---

## Edge Cases

### Haskell & Nix Repos
Nix flakes, Hydra CI, hlint, fourmolu, `-Werror` are noted as **infrastructure readiness** but don't advance the AI score. When AI config is added, existing infrastructure makes certain transitions easier (e.g., supply chain already locked for Security Stage 1).

### AI PRs Without AI Config
Score Code Quality as **0** with annotation "Stage 2 signals emerging without Stage 1 config." The activity is demand signal — adding project context would improve AI work already happening.

### Inaccessible Repos
Score all dimensions as **N/A** (— in columns). Exclude from all aggregate calculations.

### Repos With No CI/CD
Score Release and Ops as 0. Cannot progress beyond Stage 2 on other dimensions (Stage 3 requires pipeline integration).

### Repos Not Using GitHub Projects or Issues
Score AI-Assisted Delivery as 0 with annotation "Delivery tracking not in GitHub." This is informational — the team may use other tools.

### Multi-Language Repos
Score using the primary language's tooling signals. Note secondary language readiness in annotations.

---

## Minimum Viability Thresholds

These flag delivery and security risks **regardless of AI adoption**. If unmet, highlighted as a risk item in every assessment. These are not AI maturity scores — they are engineering hygiene baselines.

| Area | Minimum Threshold | How Agent Checks | Risk if Unmet |
|------|-------------------|------------------|---------------|
| **CI/CD** | At least one automated build/test workflow | `.github/workflows/` contains at least one `.yml` file | No automated quality gate — every merge is manual trust |
| **Dependency scanning** | Dependabot, Renovate, `cargo-deny`, `cabal audit`, or equivalent | `.github/dependabot.yml` or `renovate.json` exists, or workflow YAML references scanning tools | Unmonitored supply chain — CVEs go undetected |
| **Security policy** | `SECURITY.md` or equivalent disclosure process | `SECURITY.md` exists in repo root | No clear path for vulnerability reporting |
| **Test automation** | At least one test suite runs in CI | Workflow YAML contains test execution step | No automated regression detection |
| **Branch protection** | Main/master requires PR review | Branch protection API returns `required_pull_request_reviews` enabled | Direct pushes bypass all quality checks |
| **PR review enforcement** | No PRs merged without at least one review | Sample recent merged PRs via API, check review count > 0 | Code reaches main without human review — high risk |
| **Issue tracking** | GitHub Issues or Projects active for the repo | Repo has issues enabled and/or linked to a GitHub Project | Work is invisible to stakeholders |

---

## Measurement Cadence

- **Monthly snapshots** on or near the first working day of each month
- **Repo list** from `models/config.yaml` at snapshot time
- **Lookback window:** AI activity signals (PRs, commits, issues) are checked since the previous snapshot date. Config files and workflow YAML are checked as of the current snapshot.
- **Historical snapshots are immutable** — correct errors in the next snapshot and note the correction
- **Model and scoring are versioned** — changes tracked in `changelog.md`

---

## Language-Specific Infrastructure Signals

These signals are noted as **infrastructure readiness** — they don't advance the AI score but provide important context for recommendations.

### Haskell
`hlint`, `weeder`, `fourmolu`, `-Werror`, `cabal audit`, `cabal check`, `hydra-coding-standards`, `hydraJobs`, `hie.yaml`

### Rust
`cargo audit`, `cargo deny`, `clippy`, `cargo fmt`, `deny.toml`, `rust-toolchain.toml`

### TypeScript
`npm audit` / `yarn audit`, `eslint`, `eslint-plugin-security`, `prettier`, `tsconfig.json`

### Python
`ruff`, `mypy` / `pyright`, `pytest`, `hypothesis`, `.pre-commit-config.yaml`, `pyproject.toml`, `uv.lock`

### Lean
`lakefile.lean`, `lake-manifest.json`, `lean-toolchain`
