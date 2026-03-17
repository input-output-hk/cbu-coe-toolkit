# 📶 CBU: AI Augmentation Maturity Model

> **⚠️ DEPRECATED:** This is AAMM v1. Superseded by v3. See [`models/ai-augmentation-maturity-v3/model-spec.md`](../ai-augmentation-maturity-v3/model-spec.md) for the current model.

**Owner:** CoE · Dorin Solomon · **Status:** Draft v3.1 · **Last updated:** March 2026

This model defines five stages of AI adoption at the **repository and organisational level** — distinct from individual developer usage. A team can have engineers using AI tools daily (grassroots) while sitting at Stage 0 here (institutional). Grassroots usage is valuable. This model tracks when that value becomes durable, shared, and compounding.

**This model is educational, not evaluative.** Stages describe what good looks like so teams know what to focus on next. They are not performance scores, not targets with deadlines, and not grounds for comparison between teams working in different contexts.

**Related pages:**
- [📐 Scoring Methodology](./scoring.md) — how signals translate into stage scores
- Tracked repositories — see `models/config.yaml`

---

## The Five Stages

Stages are assessed **per repository**. A single repo receives one score per dimension, and an overall stage derived from those scores. Organisation-level maturity is then derived from the distribution of repo scores — how many repos sit at each stage, which dimensions lead, and where the biggest gaps are. This means a team can be at Stage 2 on one repo and Stage 0 on another, and that's expected — the model tracks each codebase independently because different repos have different complexity, tooling, and readiness.

| Stage | Name | What It Means |
|-------|------|---------------|
| **0** | **Invisible** | AI tools may be used locally by individual developers. The repository has no institutional awareness that AI exists. When a developer closes their session, no trace remains. |
| **1** | **Configured** | The repository gives AI tools project context — architecture, conventions, module boundaries, testing standards, operational topology, delivery workflow. AI tools understand *what this project is and how it works* before a developer types a prompt. Every developer benefits from this context, not just the one who wrote it. |
| **2** | **Active in Workflow** | AI participates in the team's shared workflow — reviewing code, opening PRs, suggesting tests, flagging risks, assisting with planning and incident response. AI contributions are visible in the project's history: auditable, reviewable, improvable by the team. |
| **3** | **Integrated in Pipeline** | AI runs automatically — triggered by events, not by a person. Quality gates, security scanning, test generation, release preparation, and anomaly detection happen on every push or on schedule without anyone asking. |
| **4** | **Standardised & Learning** | Org-wide decisions have been made. Every new repo starts configured. AI adoption is the default. Engineers define policy; AI executes within guardrails. Critically, AI effectiveness improves over time — accumulated team feedback, refined context, and historical patterns make AI contributions progressively better. Humans review AI decisions, not individual actions. |

---

## SDLC Dimensions

Each stage maps to six engineering dimensions. A repo can be at different stages per dimension — that's expected, especially at Stages 1–3. The matrix below describes **what the capability looks like**, not how to measure it (see [Scoring Methodology](./scoring.md) for that).

### Code Quality

What "quality" means in an AI-augmented context: AI doesn't just review syntax — it understands the project deeply enough to improve code structure, flag performance concerns, ensure documentation stays current, catch duplication, enforce PR standards, propose bug fixes, and learn from the team's feedback to get better over time.

| Stage | What It Looks Like |
|-------|--------------------|
| **0** | Code review is entirely human. No AI awareness in the repo. |
| **1** | AI tools have project context: coding conventions, architecture overview, module boundaries, preferred patterns, performance expectations, documentation standards. An AI assistant opening this repo for the first time understands the project before the developer types anything. |
| **2** | AI participates visibly in the development workflow. This includes any combination of: reviewing PRs for style, complexity, performance, and duplication; suggesting documentation improvements; flagging missing or outdated docs; opening fix or refactoring PRs; enforcing PR template compliance; co-authoring commits. AI contributions are visible in project history. |
| **3** | AI quality checks run in the pipeline on every push. Quality gates can block merges. AI-generated refactoring suggestions surface automatically. Documentation gaps are detected and flagged in CI. Flaky tests are diagnosed without human investigation. AI-generated bug fix PRs are opened from issue analysis. |
| **4** | All coding standards are enforced by AI across the org. Refactoring PRs are raised on schedule. Documentation is generated and maintained automatically. AI effectiveness improves based on accumulated team feedback — accepted and rejected suggestions refine the AI's understanding of what this team considers quality. |

### Security

AI-augmented security means continuous, context-aware protection — not just scanning for known CVEs, but understanding the project's architecture well enough to identify threats, enforce supply chain integrity, and respond to vulnerabilities faster than manual processes allow.

| Stage | What It Looks Like |
|-------|--------------------|
| **0** | Security relies on manual audits or traditional (non-AI) scanning. |
| **1** | Automated dependency and security scanning is active, and AI tools have project context that identifies security-critical modules, trust boundaries, and sensitive data flows. The combination of scanning and context creates readiness for AI-assisted security. |
| **2** | AI surfaces vulnerabilities during code review — flagging CVEs in dependencies, identifying risky patterns in PRs, providing fix suggestions with context. |
| **3** | AI security analysis runs in the pipeline and can block merges on new vulnerabilities. Auto-remediation PRs are opened for known CVEs. AI-powered SAST (using modern tools like Claude security analysis, CodeQL with AI, or equivalent) scans every push. Continuous security scanning runs against production code, not just new PRs. |
| **4** | The project's architecture is continuously audited for threats — AI threat modelling runs against the codebase and its dependencies, not just individual changes. CVE remediation is automated within policy. Supply chain integrity is verified on every build. State-of-the-art AI security tools are integrated and maintained. |

### Testing

AI-augmented testing goes beyond generating test cases — it means AI understands the project's testing strategy deeply enough to evaluate coverage at both the PR and project level, identify missing test types (unit, integration, property-based, E2E), propose test framework improvements, and maintain test quality over time. The goal is not more tests — it's the right tests, maintained efficiently, catching the failures that matter.

| Stage | What It Looks Like |
|-------|--------------------|
| **0** | All tests are authored manually. No AI involvement in testing. |
| **1** | Test standards, frameworks, coverage expectations, testing patterns, and test types (unit, integration, property-based, E2E) are documented in AI configuration — ready for AI agents to use when generating or suggesting tests. |
| **2** | AI identifies untested code paths during review. AI suggests test cases, edge cases, or missing assertions in PR comments. AI reviews PRs for test coverage at both PR level (are the right tests included?) and project level (does this change affect areas with weak coverage?). AI flags missing test types for the change. |
| **3** | AI-generated tests are committed to the repo and maintained alongside source code. Coverage is enforced per module in CI. Test framework improvements (helpers, fixtures, generators) are proposed by AI. Mutation testing or equivalent identifies dead assertions. |
| **4** | Test suites are generated from types, specs, and formal properties. Mutation testing is automated and gated. AI closes coverage gaps autonomously. AI identifies and proposes missing test types across the project. Test debt surfaces as scheduled PRs. |

### Release

Releasing software involves repetitive, error-prone work that directly affects users and stakeholders: assembling changelogs, determining version numbers, identifying breaking changes, and gating releases on regression results. AI-augmented release means this work is progressively automated — from AI-drafted changelogs that a human reviews, to fully automated pipelines where humans approve outcomes rather than performing each step. The result is faster, more reliable releases with fewer surprises.

| Stage | What It Looks Like |
|-------|--------------------|
| **0** | Changelogs, version bumps, and release notes are manual. |
| **1** | The release process, versioning conventions, and changelog format are documented in AI configuration — so AI tools understand the project's release workflow. |
| **2** | AI assists with release preparation — generating draft changelogs from merged PRs, summarising changes for release notes, flagging breaking changes during review. Humans still drive the release. |
| **3** | AI generates changelogs, version bumps, and release notes automatically. Regression gating runs before merge to main. Breaking changes are detected and flagged without human investigation. |
| **4** | Fully automated release pipeline: AI handles versioning, changelogs, regression gating, and rollback decisions within defined policy. Humans approve outcomes, not individual steps. |

### Ops & Monitoring

Production systems fail in ways that are hard to predict and time-consuming to diagnose. AI-augmented operations means AI understands the project's deployment topology, alert patterns, and incident history well enough to accelerate diagnosis, correlate signals across systems, and — at maturity — execute predefined remediation within policy. The shift is from engineers reacting to alerts and manually assembling context, to engineers defining operational policy and reviewing AI-driven responses.

| Stage | What It Looks Like |
|-------|--------------------|
| **0** | Monitoring is manual dashboards, reactive alerting, and human-driven incident response. |
| **1** | Operational context is documented in AI configuration — deployment topology, runbook locations, alert patterns, escalation paths. AI tools understand how this project runs in production, not just how it's built. |
| **2** | AI assists during incidents — summarising logs, correlating alerts, suggesting root causes from historical patterns. AI-generated context appears in incident channels or issue comments. Humans still drive resolution. |
| **3** | AI anomaly detection is active in staging or production. Alerting thresholds are calibrated by AI baselines. AI-assisted incident triage reduces mean time to diagnosis. |
| **4** | Self-healing runbooks execute autonomously within defined policy. AI drafts post-mortems and proposes architectural mitigations. Engineers review AI decisions, not individual alerts. |

### AI-Assisted Delivery

How well AI helps the team plan, decompose, estimate, and track work — making delivery more predictable and visible. This is where AI augmentation connects most directly to business value: predictable commitments, early risk detection, and reduced overhead in status management.

| Stage | What It Looks Like |
|-------|--------------------|
| **0** | Work planning, decomposition, and estimation are entirely manual. GitHub Projects may or may not be in use. No AI involvement in delivery workflow. |
| **1** | Delivery workflow context is documented in AI configuration — issue templates, project board structure, labelling conventions, estimation approach, definition of done, sprint/iteration cadence. AI tools understand how this team plans and tracks work. |
| **2** | AI assists with delivery tasks visible in GitHub: refining issue descriptions, suggesting work decomposition (epics → stories → tasks), proposing estimates based on historical patterns, generating status summaries from project boards, flagging blocked or stale items, creating well-structured issues from bug reports or feature requests. |
| **3** | AI-driven delivery automation runs on schedule or on trigger: status reports generated automatically from project board state, overdue items flagged without human scanning, estimation accuracy tracked and surfaced, scope changes detected and communicated, dependency risks identified across issues. |
| **4** | AI manages delivery workflow within defined policy: work items are decomposed and estimated with AI assistance as default, delivery health is AI-maintained, retrospective insights are generated from delivery data, estimation models improve based on actual vs predicted cycle times. Teams focus on decisions, not status accounting. |

---

## Why This Matters

Each stage transition changes **who benefits** from AI adoption.

**Stage 0 → 1** moves value from one developer's session to every developer's session. The context you encode once gets loaded automatically for every prompt, every developer, every day. This is the highest-leverage single action a team can take.

**Stage 1 → 2** makes AI participation visible in the team's shared record of work. AI contributions become auditable, reviewable, and improvable — not invisible and unaccountable.

**Stage 2 → 3** removes the human trigger. Quality, security, testing, release preparation, delivery tracking, and operational monitoring improve on every push or on schedule, not just when someone remembers to ask.

**Stage 3 → 4** means two things: institutional knowledge survives team changes and tool updates (encoded in policy, not people), and AI effectiveness compounds — it gets better because of accumulated feedback, not just because the underlying model improves.

**Progress is rarely uniform across dimensions.** A team might reach Stage 3 on Security while sitting at Stage 1 on Delivery. That is expected and useful to name — it lets teams identify which dimension is blocking the most value and sequence investment accordingly.
