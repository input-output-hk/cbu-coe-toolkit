# AAMM: Adoption Scoring Methodology

**Owner:** CoE · Dorin Solomon · **Last updated:** March 2026

---

## 1. Purpose

This document defines how an AI agent scores adoption across **5 SDLC dimensions** — decision trees, stage determination, and output format. It is the operational companion to [model-spec.md](./model-spec.md).

**No discretionary adjustments.** Stage assignment follows the decision tree. If conditions are met, the stage is assigned.

---

## 2. General Rules

1. **5 dimensions scored:** Code, Testing, Security, Delivery, Governance.
2. **4 stages:** None (0), Configured (1), Active (2), Integrated (3).
3. **Stages are cumulative.** Active requires Configured. If Active signals appear without Configured foundation, score as None and annotate: "Active signals emerging without Configured foundation."
4. **Configured requires two conditions:** (A) practice active + (B) AI config covers this dimension.
5. **Tool-agnostic.** Any AI tool counts equally.

### Stage-to-Score Mapping

| Stage | Label | Score |
|---|---|---|
| 0 | None | 0 |
| 1 | Configured | 33 |
| 2 | Active | 66 |
| 3 | Integrated | 100 |

### Adoption Composite

```
Adoption = Code * 0.25 + Testing * 0.25 + Security * 0.20
         + Delivery * 0.15 + Governance * 0.15
```

When a dimension is n/a, redistribute its weight proportionally across remaining dimensions.

---

## 3. Data Collection

### API budget: ≤ 20 calls for Adoption

| Call | Count | Layer | Purpose |
|---|---|---|---|
| AI config file contents | 3-5 | L1 | Quality check, content categories |
| Recent PRs (30) | 1-2 | L2, L4 | Bot authors, review comments, AI co-authorship, body text signatures |
| Recent commits (50) | 1 | L2 | Co-authored-by patterns |
| Workflow YAML files | 2-3 | — | AI pipeline integration |
| Issues (recent) | 1 | — | Delivery tracking |
| AI config commit history | 1-2 | — | Staleness check |
| PR author search (bots) | 1-3 | L3 | Copilot agent, CodeRabbit, bot-authored PRs |
| Submodule tree traversal | 0-4 | L5 | AI config in submodules (if .gitmodules exists) |
| **Total** | **~12-20** | | |

Note: Some data (tree, PRs, workflows) is shared with Readiness collection. Total budget for both axes: ≤ 50 calls/repo.

### Accepted AI Config Files

| File / Directory | Tool |
|---|---|
| `CLAUDE.md` / `claude.md` | Claude Code |
| `AGENTS.md` | Multi-agent orchestration |
| `GEMINI.md` | Gemini |
| `.github/copilot-instructions.md` | GitHub Copilot |
| `.github/copilot-setup-steps.yml` | GitHub Copilot |
| `.cursor/rules` / `.cursorrules` | Cursor |
| `.claude/settings.json` | Claude Code |
| `.claude/commands/` | Claude Code custom commands |
| `.mcp.json` / `mcp.json` | MCP servers |
| `.coderabbit.yaml` | CodeRabbit |
| `.aiignore` / `.cursorignore` | AI file exclusion |
| `.aider*` | Aider |
| `.windsurfrules` | Windsurf |
| `.continue/` | Continue.dev |
| `.sourcegraph/cody` | Sourcegraph Cody |
| `.codex/` | OpenAI Codex |

**Governance-only files:** `.mcp.json`, `.aiignore`, `.cursorignore` satisfy Governance Condition A (AI tool presence) but do NOT satisfy Condition B for any dimension. They contain tool configuration, not project context.

### AI Config Quality — Content-Category Checklist

An AI config file satisfies Condition B when it contains substantive content in **≥ 3 of 8 categories:**

| # | Category | Examples of substantive content |
|---|---|---|
| 1 | **Architecture** | Module boundaries, dependency relationships, key abstractions, package structure |
| 2 | **Conventions** | Naming patterns, formatting rules, style preferences, preferred approaches, anti-patterns |
| 3 | **Testing** | Test frameworks, coverage expectations, test types, test conventions, how to run tests |
| 4 | **Security** | Security-critical modules, trust boundaries, sensitive data flows, secret handling, where AI should NOT generate code |
| 5 | **Delivery** | Versioning scheme, changelog format, release process, estimation approach, branching strategy |
| 6 | **Operations** | Deployment topology, monitoring setup, runbook locations, environment configuration |
| 7 | **Build system** | How to build, which toolchain versions, package manager specifics, environment setup, CI/CD conventions |
| 8 | **Formal specification** | Which modules implement which spec rules, verification strategy, invariants that must hold, spec-to-code mapping |

Categories 7-8 are especially relevant for Haskell/blockchain repos where build complexity (Nix + Cabal) and formal spec compliance are critical for AI effectiveness.

**How to check:** The agent reads the AI config file content and marks each category as present (1) or absent (0). A category is "present" if the file contains at least 2 sentences or a structured list addressing that topic. Score = count of categories present. If count ≥ 3, Condition B is satisfied. The gate remains at ≥ 3 of 8 (not 3 of 6) — the additional categories increase opportunity, not the bar.

This is deterministic: presence check, not quality judgment.

**AI value framing in config:** The most effective AI configs guide AI toward its highest-value roles: adversarial review on critical code, quality improvement on docs/tests/PRs, and code generation on boilerplate. A Security category that tells AI "review this module for timing attacks" is more valuable than one that tells AI "generate code for this module."

### AI Signal Detection — 5 Layers (ADR-003)

A single detection pass misses significant AI signals. The scan must use all 5 layers:

**Layer 1: Repository Tree** (existing — 0 extra calls)
- Scan tree for all Accepted AI Config Files listed above.

**Layer 2: Commit Metadata** (existing — 0 extra calls)
- Scan recent 50 commits for `Co-authored-by` patterns (see below).

**Layer 3: PR Author Search** (new — 1-3 calls)
- Use GitHub Search API to find bot-authored PRs **regardless of merge status**:
  - `author:app/copilot-swe-agent` — Copilot Coding Agent
  - `author:app/coderabbit-ai` — CodeRabbit
  - `author:Copilot` — Copilot (user-account alias)
- **Why:** Agent PRs may be closed/abandoned but still prove AI experimentation.

**Layer 4: PR Body Text Search** (new — 0 extra calls, reuses PR list)
- Scan recent 30 PR **descriptions** for AI tool signatures:
  - `Made with [Cursor]` / `Made with Cursor` — Cursor IDE attribution
  - `Copilot coding agent` / `copilot-swe-agent` boilerplate
  - `Generated by Claude` / `Claude Code` mentions
  - `@copilot` mentions in PR comments (separate search: 1 call)
- **Why:** AI attribution increasingly appears in PR body text, not commit metadata. PR #2172 on LACE was "Made with Cursor" — detectable only from body text.

**Layer 5: Submodule Traversal** (new — 1-4 calls)
- Parse `.gitmodules` to identify submodules.
- For each submodule: fetch the referenced repo's tree at the **pinned SHA**.
- Check submodule trees for AI config files.
- **Annotate** when submodule repos are inaccessible (private, token scope insufficient).
- **Why:** LACE's v2 submodule contains `.claude/` directory invisible from parent tree.

### Bot Names for AI Activity Detection

| Bot Identifier | Platform | Detection Layer |
|---|---|---|
| `copilot-swe-agent[bot]` | Copilot Coding Agent | L3 (PR author) |
| `Copilot` (user account) | Copilot Coding Agent | L3 (PR author) |
| `copilot[bot]` / `github-copilot[bot]` | GitHub Copilot | L2 (commits), L3 (PR author) |
| `coderabbit-ai[bot]` | CodeRabbit | L3 (PR author), L4 (review comments) |

### PR Body Signatures for AI Activity Detection

| Pattern | Tool | Detection Layer |
|---|---|---|
| `Made with [Cursor]` / `Made with Cursor` | Cursor IDE | L4 (PR body) |
| `Copilot coding agent` / `@copilot` | Copilot Coding Agent | L4 (PR body/comments) |
| `Generated by Claude` / `Claude Code` | Claude | L4 (PR body) |
| `Co-Authored-By:.*Claude` (in body, not commit) | Claude Code | L4 (PR body) |

**Co-author patterns** (case-insensitive in commit messages — Layer 2):
- `Co-authored-by: copilot`
- `Co-authored-by: Claude`
- `Co-authored-by: Cursor`
- `Co-authored-by: Gemini`
- `AI-generated`

These lists should be reviewed quarterly and updated as new AI tools emerge.

---

## 4. Code — Decision Tree

**What it measures:** AI assisting in writing, reviewing, and refactoring code.

**Condition A (practice active):** Linter or formatter active, OR code review process visible (branch protection + CODEOWNERS).

**Condition B (AI config):** AI config passes content-category checklist (≥3 categories) AND includes Architecture + Conventions.

```
1. CHECK NONE vs CONFIGURED:
   Is Condition A met?  → Check: linter config exists, OR formatter config exists,
                           OR branch protection requires reviews, OR CODEOWNERS exists
   Is Condition B met?  → Check: AI config file with ≥3 content categories,
                           including Architecture and Conventions

   → Neither A nor B met:          None.
   → Only A met:                   None. Annotate: "Practice active, no AI config."
   → Only B met:                   None. Annotate: "AI config present, practice not active."
   → Both A and B met:             → Configured.

2. CHECK ACTIVE:
   Look for ANY of (in the last 30 merged PRs or last 50 commits):
   - PRs authored by AI bots (copilot[bot], github-copilot[bot])
   - Commits with AI co-author patterns
   - PR review comments from AI bots (coderabbit-ai[bot])
   - AI-generated PR summaries or descriptions

   → If found:                     → Active. Record evidence (PR numbers, bot names, counts).
   → If not found:                 Stay at Configured.

3. CHECK INTEGRATED:
   Look for:
   - Workflow YAML referencing AI tools that gate merges (required status checks)
   - AI quality checks as automated pipeline steps
   - Automated AI-generated refactoring or fix PRs

   → If found:                     → Integrated. Record workflow references.
   → If not found:                 Stay at Active.
```

---

## 5. Testing — Decision Tree

**What it measures:** AI generating tests and verifying correctness.

**Condition A (practice active):** Test suite runs in CI (evidence in workflow YAML).

**Condition B (AI config):** AI config passes content-category checklist (≥3 categories) AND includes Testing.

```
1. CHECK NONE vs CONFIGURED:
   → Same gate logic as Code dimension, with Testing-specific conditions.

2. CHECK ACTIVE:
   Look for:
   - AI-generated test PRs or test additions in AI-authored commits
   - AI test suggestions in PR review comments
   - Test files with AI co-authorship attribution

   → If found: Active.
   → If not: Configured.

3. CHECK INTEGRATED:
   Look for:
   - AI test generation step in CI pipeline
   - Coverage enforcement with AI-augmented analysis
   - Automated test maintenance PRs from AI

   → If found: Integrated.
   → If not: Active.
```

---

## 6. Security — Decision Tree

**What it measures:** AI protecting the codebase and supply chain.

**Condition A (practice active):** Automated dependency or security scanning in CI for the **primary language ecosystem**. Dependabot scanning only `github-actions` does NOT satisfy this for a TypeScript or Haskell repo.

**Condition B (AI config):** AI config identifies **any 1 of 3**: security-critical modules, trust boundaries, or sensitive data flows. (Relaxed from v3's all-3 requirement — most real-world configs only cover one aspect.)

```
1. CHECK NONE vs CONFIGURED:
   Condition A: .github/dependabot.yml with entry for primary language ecosystem,
                OR renovate.json, OR workflow YAML with security scanning
                (codeql, trivy, snyk, semgrep, cargo-deny, npm audit, etc.)
   Condition B: AI config with ≥3 content categories AND Security category present.

   → Gate logic same as other dimensions.

2. CHECK ACTIVE:
   Look for:
   - AI security review comments on PRs (Copilot Autofix, CodeRabbit security flags)
   - AI-flagged CVEs in dependency update PRs
   - AI-powered SAST comments

   → If found: Active.

3. CHECK INTEGRATED:
   Look for:
   - AI security steps in workflow YAML that block merges
   - Auto-remediation PRs for known CVEs
   - Scheduled AI security scanning workflows

   → If found: Integrated.
```

---

## 7. Delivery — Decision Tree

**What it measures:** AI improving planning, releases, and predictability.

This dimension merges v3's "Release" and "AI-Assisted Delivery" because they represent the same flow: planning → building → shipping.

**Condition A (practice active):** Automated build/release workflow exists AND issue tracking active (GitHub Issues/Projects, or external tool documented in AI config like Jira/Linear).

**Condition B (AI config):** AI config passes content-category checklist (≥3 categories) AND includes Delivery.

```
1. CHECK NONE vs CONFIGURED:
   → Gate logic same as other dimensions.
   → Note: teams using Jira/Linear satisfy Condition A if documented in AI config.

2. CHECK ACTIVE:
   Look for:
   - AI-generated release notes or changelogs
   - AI PR summaries or descriptions
   - AI-generated issues or task decomposition
   - AI-assisted estimation evidence

   → If found: Active.

3. CHECK INTEGRATED:
   Look for:
   - Automated AI-driven release workflows
   - AI deployment verification steps
   - AI-powered changelog generation in CI

   → If found: Integrated.
```

**Known limitation:** Stage 2+ requires GitHub-visible signals. Teams using AI extensively for delivery in external tools (Jira, Linear) will not show these signals on GitHub. For such teams, Delivery is effectively capped at Configured.

---

## 8. Governance — Decision Tree

**What it measures:** AI tooling maturity, attribution, review gates. Cross-cutting.

**Condition A (practice active):** At least one AI tool actively configured. Any file from the Accepted AI Config Files list counts, INCLUDING `.mcp.json` and `.aiignore`.

**Condition B (AI config):** AI usage expectations documented (which tools, when to use, attribution expectations) + `.aiignore` or equivalent for sensitive paths.

```
1. CHECK NONE vs CONFIGURED:
   Condition A: Any accepted AI config file present in tree.
   Condition B: At least one AI config file with documented usage expectations
                (not just tool config) AND .aiignore or .cursorignore present.

   → Gate logic same as other dimensions.

2. CHECK ACTIVE:
   Look for:
   - Multi-tool configuration (2+ AI tools configured)
   - Agent orchestration patterns: AGENTS.md, .claude/commands/, custom MCP servers
   - AI attribution in commits (Co-authored-by patterns)
   - Human-AI review gates documented in CONTRIBUTING.md

   → If found: Active.

3. CHECK INTEGRATED:
   Look for:
   - Cross-repo config consistency (AI config follows similar structure across org repos)
   - Automated config updates (config evolves based on feedback — commit history)
   - AI governance requirements in branch protection or PR templates

   → If found: Integrated.
```

---

## 9. Annotations

When scoring produces notable observations, record them in the evidence log:

| Annotation | When |
|---|---|
| "Active signals without Configured foundation" | Active signals detected but Configured gate not met |
| "Practice active, no AI config" | Condition A met, Condition B not met |
| "AI config present, practice not active" | Condition B met, Condition A not met |
| "Delivery tracking external" | External delivery tool (Jira/Linear) documented |
| "AI config stale" | >180 days unchanged |
| "Emerging AI usage" | .mcp.json or individual AI tool signals without institutional config |
| "Dependabot partial" | Dependabot scans github-actions only, not primary language ecosystem |

---

## 10. Risk Flags (Adoption)

| Risk | Condition | Severity |
|---|---|---|
| AI without governance | Active or Integrated on any dimension but Governance = None | 🔴 High |
| Risky Acceleration | Adoption composite ≥ 45 but Readiness < 45 | 🔴 High |
| AI config stale | AI config unchanged >180 days | 🟡 Medium |
| Active without foundation | Active-level signals but Configured gate not met | 🟡 Medium |

---

## 11. Worked Example

### 11.1 LACE (TypeScript monorepo) — Adoption: 0

*(Scored during model validation. Full report generated via `scripts/aamm/scan-repo.sh`.)*

All 5 dimensions scored **None**. Strong engineering practices (Condition A met for 4/5 dimensions) but no AI project context (Condition B not met for any).

| Dimension | Stage | Condition A | Condition B | Annotation |
|-----------|-------|-------------|-------------|------------|
| Code | None | ✓ ESLint + Prettier + CODEOWNERS | ✗ .mcp.json has zero project context | Practice active, no AI config |
| Testing | None | ✓ Jest + Vitest in CI | ✗ No AI config with Testing | Practice active, no AI config |
| Security | None | ✗ Dependabot github-actions only | ✗ No AI config with Security | Dependabot partial |
| Delivery | None | ✓ Release workflows + JIRA | ✗ No AI config with Delivery | Practice active, no AI config. Delivery tracking external (JIRA) |
| Governance | None | ✓ .mcp.json (3 MCP servers) | ✗ No usage expectations, no .aiignore | Emerging AI usage |

**Key observation:** `.mcp.json` with 3 MCP servers (sequential-thinking, context7, interactive) indicates individual developer AI exploration. The gap is institutional — no project-specific context for AI tools, no governance documentation, no `.aiignore`.

**Content-category check:** `.mcp.json` contains only server definitions. Categories present: 0/6. Does not satisfy Condition B for any dimension.

Adoption composite: `0 × 0.25 + 0 × 0.25 + 0 × 0.20 + 0 × 0.15 + 0 × 0.15 = 0`
