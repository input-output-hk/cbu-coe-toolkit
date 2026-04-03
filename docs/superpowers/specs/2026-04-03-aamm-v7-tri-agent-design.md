# AAMM v7 — Tri-Agent Architecture Design

> **Status:** APPROVED — Grok: APPROVED; Gemini: CONDITIONAL APPROVAL (fixes applied); Gemini quota exhausted 2026-04-03, re-verify when quota resets
> **Date:** 2026-04-03
> **Author:** Dorin Solomon (CoE lead) + Claude (AI agent)
> **Supersedes:** `2026-04-02-dual-agent-consensus-design.md` (v6.1)
> **ADR:** ADR-020 (to be written)

---

## 1. Problem

AAMM v6.1 introduced dual-agent consensus (Claude + Gemini) to eliminate single-model bias. Two remaining issues:

1. **Pre-selection bias:** Claude collects all repo data via GitHub API, then injects it into Gemini's prompt. Gemini reasons over Claude's selection — if Claude misses an indicator, Gemini never sees it. Independence is in reasoning, not in discovery.
2. **Two agents share blind spots:** Claude and Gemini have different training but both are optimized for corrrectness and code quality. A third agent with a fundamentally different perspective (operational survivability, scale, value for personas) catches what both miss.

---

## 2. Design Principles

1. **Zero pre-selection bias** — No agent decides what another agent sees. Every agent independently decides what to investigate.
2. **Tri-agent tiered consensus** — Claude + Gemini + Grok. All three ≥9/10 = HIGH confidence (approved). Two of three ≥9 + third ≥7 = MEDIUM confidence (approved, mandatory CoE review flagged). Anything else = `consensus: false`.
3. **Adversarial-collaborative** — Every agent challenges constructively. Score changes require new evidence. No default concession. No manufactured disagreement.
4. **Auditability by design** — File-based protocol. We know exactly what each agent requested, received, and concluded.
5. **Token efficiency without quality loss** — Claude subagents for isolated analysis phases; structured JSON consensus exchange.
6. **Learning scans optimize for recall** — Union model (not intersection). Missing a pattern is worse than including a weak one. CoE filters.
7. **Future-proof** — A fourth agent enters by following the same protocol. No orchestration changes needed.

---

## 3. Agents

| Agent | Model | Invocation | Perspective |
|---|---|---|---|
| **Claude** | Claude Sonnet/Opus (Claude Code) | Native — orchestrator + subagent scorer | Pattern matching, evidence, KB alignment |
| **Gemini** | Gemini 2.5 Pro | `gemini --yolo -m gemini-2.5-pro` from repo root | Skeptical, methodical, citation-heavy |
| **Grok** | Grok 4 (`grok-4-0709`) | `bash scripts/grok-invoke.sh` (xAI API, `$XAI_API_KEY`) | Survivability, scale, value for personas, absence signals |

**Cost:** Claude Max (zero) + Gemini Google One AI Pro (zero) + xAI API (`$XAI_API_KEY`, low cost per scan).

**Health checks (parallel, mandatory before any scan):**
```bash
# Gemini CLI
gemini -p "Reply: AAMM_READY" --yolo -m gemini-2.5-pro -o text 2>/dev/null | grep -q "AAMM_READY"

# Grok API
bash scripts/grok-invoke.sh grok-4-0709 "Reply with exactly: AAMM_READY" 2>/dev/null | grep -q "AAMM_READY"
```
If either fails → **STOP. Announce to operator. Ask how to proceed. No single-agent or dual-agent fallback.**

---

## 4. Request/Serve Protocol

The core architectural innovation. Replaces GitHub API pre-collection with local clone + agent-driven file discovery.

### Phase 0 — Setup

```
1. Clone target repo locally (single clone, shared read-only):

   Scoring scan:
   git clone --depth=100 https://$GITHUB_TOKEN@github.com/$OWNER/$REPO \
     /tmp/aamm-v7-$OWNER-$REPO/clone/

   Learning scan (full history needed for temporal signals):
   git clone --shallow-since="12 months ago" \
     https://$GITHUB_TOKEN@github.com/$OWNER/$REPO \
     /tmp/aamm-v7-$OWNER-$REPO/clone/

   LFS handling (if .gitattributes present):
   cd /tmp/aamm-v7-$OWNER-$REPO/clone/ && git lfs install && git lfs pull 2>/dev/null || true

   Private repo access check (BEFORE clone attempt):
   HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
     -H "Authorization: Bearer $GITHUB_TOKEN" \
     https://api.github.com/repos/$OWNER/$REPO)
   if [ "$HTTP_CODE" != "200" ]; then
     echo "FATAL: Cannot access $OWNER/$REPO (HTTP $HTTP_CODE). Check GITHUB_TOKEN scope."
     # STOP — no clone attempted, no partial state left on disk
   fi

   LFS handling (if .gitattributes present in tree):
   cd /tmp/aamm-v7-$OWNER-$REPO/clone/ && git lfs install && git lfs pull 2>/dev/null || true

2. Detect repo type for SDLC pruning (orchestrator — from manifest metadata):

   Repo type is derived from language + topics + file patterns at repo root:

   | Type          | Detection signals                                              |
   |---------------|----------------------------------------------------------------|
   | library       | no web framework deps, no server entrypoint, published pkg     |
   | web-app       | framework deps (React/Next/Express/etc), server entrypoint     |
   | cli-tool      | binary entrypoint, no HTTP server, no frontend                 |
   | infrastructure| Terraform/Nix/Helm/Dockerfile at root, no src/                 |
   | mixed         | signals from 2+ types, or orchestrator cannot determine        |

   Saved to manifest.json as `repo_type: library|web-app|cli-tool|infrastructure|mixed`.
   Agents receive repo_type and may override it with justification in their file request output.

   SDLC sections active per repo type:
   | Section                    | library | web-app | cli-tool | infrastructure |
   |----------------------------|---------|---------|----------|----------------|
   | AI Context & Config        | ✓       | ✓       | ✓        | ✓              |
   | Planning & Documentation   | ✓       | ✓       | ✓        | ✓              |
   | Development                | ✓       | ✓       | ✓        | ✓              |
   | Code Review & PR Mgmt      | ✓       | ✓       | ✓        | ✓              |
   | Testing                    | ✓       | ✓       | ✓        | partial        |
   | Security                   | ✓       | ✓       | ✓        | ✓              |
   | Performance                | ✓       | ✓       | partial  | partial        |
   | Delivery (CI/CD)           | ✓       | ✓       | ✓        | ✓              |
   | Dependency & Release       | ✓       | ✓       | ✓        | partial        |
   | Operations & Monitoring    | partial | ✓       | partial  | ✓              |
   | Developer Experience       | ✓       | ✓       | ✓        | partial        |
   | AI Governance & Ethics     | ✓       | ✓       | ✓        | ✓              |

   `partial` = check for presence, log absence, do not penalize for gaps.
   `mixed` = full framework, no pruning.
   Agents log skipped sections as "not applicable — {repo_type}" rather than absence signals.

3. Monorepo detection and subproject targeting:

   Orchestrator detects monorepo if: multiple package manifests at depth >1
   (e.g., packages/*/package.json, crates/*/Cargo.toml, libs/*/cabal.project).

   Monorepo detection — deny-listed directories excluded FIRST:
   Deny-list: vendor/, deps/, third_party/, extern/, node_modules/, .git/, _build/, dist/
   Only manifests outside deny-listed paths count toward monorepo detection.
   Cross-check: deny-listed path with low git churn (< 5 commits in 90 days) = vendored, skip.

   If monorepo detected (after deny-list filtering):
   a) Orchestrator lists subprojects in manifest.json:
      subprojects: [{name, root_dir, language, manifest_file, last_commit_date, commit_count_90d}]
   b) Operator specifies target subproject via scan argument:
      /scan-aamm-v7 owner/repo --subproject=packages/wallet
   c) If no subproject specified: orchestrator selects the highest-churn subproject
      (most commits in last 90 days, excluding deny-listed dirs) and announces selection
      to operator before proceeding. Fallback if churn is misleading (e.g., docs/ is highest):
      orchestrator picks the subproject containing the primary language entrypoint.
   d) Scan targets the subproject root only. SDLC framework applies to that subproject.
   e) report.md header includes: "Scan scope: {subproject} (monorepo — other subprojects excluded)"

   Monorepo detection is itself auditable: manifest.json lists all detected subprojects,
   deny-listed paths, and the detection criteria used.

4. Generate neutral manifest (orchestrator — zero interpretation):
   - File tree: path + size + extension for every file (full repo or subproject scope)
   - Git stats: commit count per directory (last 100 commits)
   - Commit heatmap: files changed most frequently (raw counts, no ranking)
   - Metadata: language, topics, last commit date, open PR count, contributor count
   - repo_type: detected type (see step 2)
   - subprojects: list if monorepo (see step 3), empty otherwise
   → Saved to /tmp/aamm-v7-$OWNER-$REPO/manifest.json

   RULE: Manifest contains structure and stats only. No file contents. No signals.
         The manifest is a map, not a selection.
   NOTE: Commit heatmap lists raw per-file counts — no "top 20" filter. Agents
         compute their own priorities from raw data.
```

### Phase 1 — File Requests (independent, no agent sees another's requests)

```
All three agents receive simultaneously:
  - manifest.json
  - KB files: ecosystems/$ECOSYSTEM.md + cross-cutting.md + anti-patterns.md
  - scoring-model.md (operational manual)
  - Task: "Based on this manifest and KB, list the files you want to examine."

Each agent produces a file request list:
  file-request-claude.json   ← Claude subagent (isolated context)
  file-request-gemini.json   ← Gemini via --yolo
  file-request-grok.json     ← Grok via xAI API

Grok file serving — batched due to API context limits (128k tokens):
  Orchestrator serves Grok's requested files in batches of 50 files max.
  Grok processes batch 1, returns partial findings + "need more files: [list]".
  Orchestrator serves next batch. Grok integrates and produces final output.
  Max 5 batches per phase. If Grok needs more: log "context limit reached",
  include what was analyzed. Orchestrator adds a top-level WARNING banner in
  both report.md and detailed-log.md:
    ⚠ WARNING: Grok analysis incomplete — context limit reached after batch N.
    Files analyzed: {list}. Files not analyzed: {list}. This scan is PARTIAL.
  The warning is prominent and cannot be missed. A partial scan is still
  official but must be re-run before acting on Grok's findings in production.

Orchestrator serves each request from /clone/ — unfiltered, no judgment.
Audit log: exact file list requested by each agent → saved to /tmp/aamm-v7-.../audit/

RULE: No agent sees another's file request list.
RULE: Orchestrator never adds or removes files from a request.
```

### Why this eliminates pre-selection bias

In v6.1, Claude read "README.md, all .github/workflows/*.yml, CLAUDE.md, CONTRIBUTING.md..." — a fixed list. Gemini received exactly this selection. If the signal was in `docs/adr/0042-ai-policy.md`, neither agent found it.

In v7: Gemini might request `docs/adr/*.md` because it spotted ADR files in the manifest. Grok might request `.github/CODEOWNERS` because ownership patterns indicate AI governance maturity. Claude might request `benchmarks/` because performance infrastructure signals AI readiness. Each agent discovers independently.

**If Gemini and Grok both independently request the same file and find the same signal → that signal is strong.**

---

## 5. Token Efficiency — Claude Subagent Architecture

Claude is both orchestrator and scorer. Without isolation, the orchestrator context accumulates everything: KB content, all requested files, all agent outputs, all consensus rounds. This degrades quality as context grows.

Solution: Claude subagents for analysis-heavy phases.

```
Main Claude (orchestrator — lean context)
  │  Sees only: manifest, JSON outputs from agents, consensus state
  │
  ├── dispatches → Claude Subagent: File Request
  │     Input: manifest + KB + scoring-model
  │     Output: file-request-claude.json
  │     Context released after
  │
  ├── dispatches → Claude Subagent: Independent Analysis
  │     Input: requested files + KB + scoring-model
  │     Output: opportunity-map-claude.json
  │     Context released after
  │
  ├── invokes → Gemini (independent analysis)
  ├── invokes → Grok (independent analysis)
  │
  ├── conducts consensus loop (on JSON only — no raw file content in orchestrator)
  │
  └── dispatches → Claude Subagent: Report Generation
        Input: assessment.json (frozen)
        Output: report.md + detailed-log.md
        Context released after
```

**Orchestrator state on disk, not in context** — after each phase, state is written to disk. Orchestrator loads only the current round's data, not the full scan history. This prevents context bloat across long consensus loops.

```
/tmp/aamm-v7-$OWNER-$REPO/
  consensus-state.json     ← current phase + round index, what's approved/pending
  phase-1/round-N-*.json   ← per-round snapshots (loaded on demand, not kept in context)
```

**Structured JSON consensus exchange** — consensus rounds use strict JSON, not prose:

```json
{
  "item_id": "opp-3",
  "agent": "grok",
  "score": 7,
  "evidence": ["src/Main.hs:142 — no AI tool attribution in last 47 commits"],
  "challenge": "Adoption claimed Partial but zero evidence in commit history",
  "required_for_9": "Show at least one AI-attributed commit in past 6 months"
}
```

Prose arguments ~800 tokens. Structured JSON ~120 tokens. ~70% reduction per consensus exchange.

---

## 6. Scan Flow — Scoring Mode

```
/scan-aamm-v7 owner/repo

PHASE 0: Setup
  ├── Health check: Gemini + Grok (parallel)
  ├── Clone repo → /tmp/aamm-v7-$OWNER-$REPO/clone/
  └── Generate manifest.json (neutral)

PHASE 1: Independent Analysis
  ├── All agents receive manifest + KB + scoring-model simultaneously
  ├── File requests (independent, parallel where possible)
  ├── Orchestrator serves files (unfiltered)
  └── Each agent produces opportunity map independently
      (Claude via subagent, Gemini via CLI, Grok via API)

PHASE 2: Consensus — Opportunity Map
  ├── Step A: Intersection-first
  │     Items where all 3 agree → auto-approved (consensus_round: 0)
  │     Items where 2/3 agree → enter loop (still need all 3)
  │     Items unique to 1 agent → enter loop
  ├── Step B: Consensus loop (max 5 rounds, JSON structured)
  │     All 3 ≥9/10 → approved
  │     After round 5 → consensus: false, all positions preserved
  └── Step C: Component Assessment (adoption/readiness/risk)
        Same pattern: independent → intersection → loop

PHASE 3: Consensus — Recommendations
  ├── All 3 generate recommendations independently from approved map
  ├── Intersection-first → Consensus loop (max 5 rounds)
  └── ROI ordering consensus (all 3 rank, debate divergences)

PHASE 4: Report Generation (Claude subagent, fresh context)
  ├── Reads assessment.json (frozen after Phase 3)
  ├── Reads previous scan for delta (if exists)
  └── Writes: report.md, assessment.json, detailed-log.md

PHASE 5: Save + KB Proposals
  └── scans/ai-augmentation/results/YYYY-MM-DD/$OWNER--$REPO/
```

---

## 7. Scan Flow — Learning Mode

Learning scans have a fundamentally different objective: **maximize recall**. Missing a KB pattern costs more than including a weak one. CoE filters; agents discover.

```
/scan-aamm-v7 owner/repo --mode=learning

PHASE 0: Same (health checks + clone + manifest)

PHASE 1: Independent Deep Scan
  ├── No file quota — agents request everything they consider relevant
  ├── Each agent scans all SDLC layers (see Section 8)
  ├── Each agent explicitly logs absence signals:
  │     "Expected AI config file — not found. This IS a signal."
  └── Each agent produces findings-{agent}.json independently

PHASE 2: Union with Evidence Filter (NOT consensus)
  ├── Union: all findings from all 3 agents combined
  ├── For each finding in union:
  │     → Confidence tier by agent count AND evidence type:
  │
  │       found_by 3 agents, each with evidence       → HIGH  (enters KB proposals)
  │       found_by 2 agents, each with evidence       → MEDIUM (enters KB proposals)
  │       found_by 1 agent (Claude or Gemini)
  │         with file:line or commit SHA              → LOW (enters KB proposals, CoE scrutiny)
  │       found_by 1 agent (Grok only)
  │         with evidence                             → LOW-GROK (enters KB proposals,
  │                                                      flag: "adversarial signal — verify
  │                                                      independently before merge")
  │       Any agent with absence signal evidence      → LOW-ABSENCE (enters KB proposals,
  │         (no file:line, but quantified absence:       flag: "absence signal — no direct
  │          "zero AI config in repo with 200 contribs"  file citation, verify pattern")
  │       No agent provides any evidence              → dropped, logged with reason
  │
  └── Rationale for LOW-ABSENCE tier:
        Absence signals are explicitly defined as a core Grok capability (GROK.md) and
        a mandatory SDLC layer (Section 8, Layer 4). "Zero AI config files in a 200-person
        repo" is a real signal with no possible file:line citation. Dropping it because
        it lacks a file path would silently eliminate an entire category of KB value.
        LOW-ABSENCE requires the agent to quantify the absence (count, timeframe, context)
        rather than just assert it. CoE evaluates before merge.

PHASE 3: Hallucination Filter (not consensus — counter-evidence only)
  ├── Each agent reviews proposals found by others
  ├── ONLY valid response: "I found counter-evidence that disproves this: {file:line}"
  ├── If no counter-evidence → proposal stands, regardless of agent agreement
  ├── No scoring, no disagreement logging, no "I would have found this differently"
  └── Rationale: agents challenge absence signals they didn't personally discover because
      they didn't request those files — that is a discovery gap, not a hallucination.
      Only concrete counter-evidence (proof the signal is false) can drop a proposal.

OUTPUT: kb-proposals.json only (no report.md, no assessment.json)
  CoE reviews → merges approved entries into knowledge-base/
```

**Key distinction:** Scoring consensus = all must agree. Learning filter = at least one must prove. A finding seen only by Grok with concrete evidence enters KB proposals.

---

## 8. SDLC Coverage Framework

Learning scans (and scoring scans) use this framework to ensure no SDLC stage is skipped. Agents treat this as a checklist — they must explicitly address each area or log why it's not applicable.

### AI Context & Configuration
```
- CLAUDE.md, .claude/settings.json, .claude/commands/
- GEMINI.md, .gemini/settings.json
- GROK.md
- AGENTS.md (multi-agent standard)
- .cursorrules, .cursor/rules/
- .windsurfrules (Windsurf/Codeium)
- .github/copilot-instructions.md
- .aider.conf.yml, CONVENTIONS.md
- .continue/config.json
- .devin/ (Cognition AI)
- .mcp.json ← strong signal: agentic tool use, not just completion
- .aiignore
- .tabnine/, .codeium/, .amazon-q/, .sourcegraph/
```

### Planning & Documentation
```
- ADRs: frequency, AI attribution, quality of reasoning
- Architecture docs: AI-assistable structure, context density
- README quality: does it orient an AI agent effectively?
- Onboarding docs: AI tooling mentioned? Setup friction for AI tools?
- Internal wikis / knowledge bases: AI-assisted authoring signals
- Specs and design docs: evidence of AI-assisted design
```

### Development
```
- AI attribution in commits: Co-authored-by AI tools
- Code comment density and quality (AI context-friendliness)
- Scaffolding patterns: AI-generated boilerplate signals
- Refactoring evidence: large AI-assisted refactors in history
- API design quality: OpenAPI specs, AI-generated docs
- AI-assisted debugging signals in issue/PR descriptions
```

### Code Review & PR Management
```
- PR templates: AI guidance, context prompts
- AI reviewer bots: coderabbit[bot], copilot[bot], sourcery[bot], sweep[bot], deepsource[bot]
- PR description quality: evidence of AI-generated or AI-assisted descriptions
- Issue templates: structured enough for AI-assisted triage
- Label taxonomy: AI-compatible classification
- Review turnaround: evidence of AI-accelerated review
```

### Testing
```
- Test coverage and structure: AI-assistable test patterns
- Property-based testing: AI-friendly fuzz/property testing signals
- AI-assisted test generation: signals in test file history
- Test documentation: quality of test intent documentation
```

### Security
```
- AI-assisted security scanning in CI (CodeQL, Snyk, AI-powered SAST)
- Dependency review automation
- Security policy: AI tooling explicitly addressed?
- Vulnerability response time in issue history
```

### Performance
```
- Benchmarking infrastructure: AI-assistable performance analysis
- AI-assisted profiling signals
- Performance regression CI: automated detection
- Perf documentation quality
```

### Delivery (CI/CD)
```
- AI steps in workflow files (.github/workflows/)
- Deployment automation maturity
- Release notes automation (release-please, git-cliff, AI-generated changelogs)
- Semantic versioning automation
```

### Dependency & Release Management
```
- Dependabot / Renovate configuration: AI-assisted grouping and scheduling
- License compliance automation
- Vulnerability response patterns in PR/issue history
```

### Operations & Monitoring
```
- Runbooks: AI-assistable format, completeness
- Observability signals: dashboards, alerting configs
- Postmortem culture: evidence of structured incident review
- AI-assisted incident response signals
```

### Developer Experience
```
- AI pair programming signals (mob session references in docs/PRs)
- Technical debt tracking with AI prioritization
- Accessibility testing: AI-assisted signals
- Localization/i18n: AI-assisted signals
```

### AI Governance & Ethics
```
- AI usage policy document (ai-policy.md, AI_GUIDELINES.md, or equivalent)
- Data privacy guidelines for AI prompts (what not to send to AI tools)
- Policy for reviewing AI-generated code in security-sensitive areas
- Audit trail requirements for AI-assisted decisions
- Team training or onboarding docs mentioning responsible AI use
- CODEOWNERS or review requirements for AI-generated changes
```
Note: governance signals are often in Confluence/Notion rather than the repo.
Agents should note "not found in repo — may exist in external docs" rather than
treating absence as confirmed absence.

### Detectability Note

Some SDLC signals are qualitative and may have low detection rates:
- "AI-assisted incident response signals" — rarely logged explicitly in repos
- "AI pair programming signals" — inferred from docs/PRs, not directly observable
- "AI-assisted debugging signals" — interpretive, not concrete

Agents must log confidence (HIGH/MEDIUM/LOW) per signal. Low-detectability signals
contribute to KB as LOW confidence proposals only. The SDLC framework is comprehensive
by design — partial coverage is expected and correct.

### Absence Signals (Layer 4 — mandatory)

For every SDLC stage, agents must explicitly answer: **"What should be here but isn't?"**

```
Examples:
- TypeScript repo with 200+ contributors, zero AI config file → significant absence
- Active CI pipeline with no AI-assisted steps → absence signal
- Large codebase, zero Co-authored-by AI in 12 months → adoption absence
- Security scanning present, zero AI-powered SAST → maturity gap
```

Absence signals are as valuable as presence signals for KB enrichment.

---

## 9. Consensus Protocol

### Consensus Thresholds

Items are approved according to the tiered model below. There is no single "all-or-nothing" rule — the tiers reflect confidence level, not a binary gate.

### Debate Rules

1. **Independence first** — No agent sees another's analysis before producing its own.
2. **Evidence-only** — Every score <9 cites: file:line, commit SHA, KB pattern ID, or concrete repo artifact. Abstract objections are invalid.
3. **No default concession** — Score changes require new evidence. An agent that raises its score must state what convinced it.
4. **No manufactured disagreement** — If evidence is clear, approve. Grok does not challenge for the sake of challenging.
5. **Symmetry** — All three agents have equal standing. Orchestration role confers no authority.
6. **5 rounds maximum** — After round 5, item status is final.

### Tiered Consensus Outcomes

```
All 3 ≥9/10                         → approved, confidence: HIGH
2 of 3 ≥9 + third ≥7               → approved, confidence: MEDIUM, coe_review_required: true
Any agent <7, or third agent 7-8
  after 5 rounds                    → consensus: false, confidence: LOW

consensus_round: 0                  → all 3 found it independently → strongest HIGH
consensus_round: 1-2                → agreement after minor clarification → HIGH or MEDIUM
consensus_round: 3-5                → substantive debate resolved → MEDIUM (debate_summary required)
consensus: false                    → persistent disagreement → LOW, all positions preserved
```

**Why tiered:** Grok will legitimately score 7-8 on findings where Claude and Gemini score 10 — surfacing a real scale or survivability concern. A MEDIUM finding with a CoE review flag is more useful than a dropped finding.

**MEDIUM cap per scan: 10 items.** If the consensus loop produces more than 10 MEDIUM items:
- Top 10 by ROI rank → MEDIUM, included in report with full debate trail
- Remaining → downgraded to LOW, included with a one-line summary of Grok's concern
- A `medium_overflow_summary` section is added to report.md listing all downgraded items

Rationale: 29 repos × unlimited MEDIUM = unmanageable CoE queue. The cap forces prioritization at scan time rather than drowning the reviewer.

---

## 10. Reference Repos — External KB Enrichment

### Purpose

Internal CBU repos provide patterns from one organization's practices. External reference repos provide industry benchmarks — what AI readiness looks like at the frontier.

### Selection — Tri-Agent Consensus Task

Reference repo selection is itself a tri-agent consensus task (the first application of the v7 mechanism):

```
/select-reference-repos

Each agent independently researches per ecosystem:
  haskell | rust | typescript | python

Evaluation criteria (each agent applies independently):
  - AI tooling config present (AGENTS.md, CLAUDE.md, .cursorrules, .mcp.json, etc.)
  - AI attribution in recent commit history
  - CI/CD with AI-assisted steps
  - Complexity comparable to CBU internal repos
  - Active maintenance (commits in last 6 months)
  - Recognized for engineering practices (not just popularity)
  - SDLC coverage: AI adoption signals across planning, dev, review, delivery

Each agent proposes 3-5 repos per ecosystem with rationale.
Consensus: same tiered protocol as scoring scans (see Section 9). Reference repo selection uses HIGH tier only (all 3 ≥9/10) — MEDIUM approval is not sufficient for adding a benchmark repo to config.yaml.
Output: approved list committed to models/config.yaml under reference_repos section.
```

### config.yaml — Separate Section

```yaml
repos:
  # Internal CBU repos — scoring scope
  - repo: input-output-hk/lace-platform
    language: typescript
    project: lace
    scope: scoring

reference_repos:
  # External — learning scope only, never scored, never reported to teams
  - repo: <to be determined by tri-agent consensus>
    language: haskell
    scope: learning
    rationale: "..."
    selected_by: tri-agent-consensus
    selected_date: YYYY-MM-DD
```

`scope: learning` is a hard constraint: these repos never appear in scoring scans, never in reports to teams, never in portfolio dashboards. Learning only.

### Learning Scan Cadence

- **Initial:** Run learning scans on all approved reference repos before the first v7 scoring scan.
- **Scheduled:** Re-run every 6 months via tri-agent consensus to keep benchmarks current.
- **Triggered:** Re-run when ≥50 new KB entries have been added (corpus has shifted enough to warrant re-calibration), or when scoring scan disagreement signals reveal a systematic KB gap.
- **On addition:** Any new reference repo triggers a learning scan before its patterns enter KB.

---

## 11. Infrastructure Changes

### New / Modified Files

```
cbu-coe-toolkit/
├── GROK.md                              ← updated: scan participant role added
├── scripts/grok-invoke.sh               ← exists: health check pattern confirmed
├── models/config.yaml                   ← reference_repos section added
├── models/ai-augmentation-maturity/
│   ├── scoring-model.md                 ← rewritten for v7
│   ├── spec.md                          ← rewritten for v7
│   └── changelog.md                     ← v7 entry
├── .claude/skills/
│   ├── scan-aamm-v7/
│   │   ├── SKILL.md                     ← new, replaces scan-aamm-v6
│   │   └── prompts/
│   │       ├── gemini-file-request.md
│   │       ├── gemini-phase1-analysis.md
│   │       ├── gemini-consensus-round.md
│   │       ├── gemini-component-assessment.md
│   │       ├── gemini-phase2-recommendations.md
│   │       ├── grok-file-request.md
│   │       ├── grok-phase1-analysis.md
│   │       ├── grok-consensus-round.md
│   │       ├── grok-component-assessment.md
│   │       └── grok-phase2-recommendations.md
│   └── select-reference-repos/
│       └── SKILL.md                     ← new
├── schema/
│   └── assessment-v7.schema.json        ← new (tri-agent consensus fields)
├── CLAUDE.md                            ← updated: scan flow diagram, v7 references
└── docs/decisions/
    └── 020-aamm-v7-tri-agent.md         ← new ADR
```

### GROK.md Addition

```markdown
## Role in AAMM v7 Scans

When invoked as a scan participant (prompts state this explicitly), Grok is an
independent scorer with equal standing to Claude and Gemini.

Protocol: receive manifest → request files → analyze independently → participate
in consensus rounds.

Grok's scan perspective emphasizes:
- Risk surface and operational failure modes for each opportunity
- Scale implications: does this work for 1 repo or 100?
- Value clarity per persona: tech leads, repo owners, CoE, CBU leadership
- Absence signals: what should be present in a mature AI-ready repo but isn't?
- Reality check: will this recommendation survive a 3 AM production incident?
```

### assessment.json — New Fields

```json
{
  "scan_metadata": {
    "agents": ["claude", "gemini", "grok"],
    "consensus_model": "tri-agent-v1",
    "scan_mode": "scoring",
    "local_clone": true,
    "phase_1_rounds": 2,
    "phase_2_rounds": 1
  },
  "opportunity_map": [
    {
      "id": "opp-1",
      "consensus": true,
      "found_by": ["claude", "gemini", "grok"],
      "consensus_round": 0,
      "claude_score": 10,
      "gemini_score": 9,
      "grok_score": 9,
      "debate_summary": "null (intersection — auto-approved)",
      "file_requests": {
        "claude": ["src/Main.hs", ".github/workflows/ci.yml"],
        "gemini": ["src/Main.hs", "CLAUDE.md", ".github/workflows/"],
        "grok": [".github/workflows/ci.yml", "docs/architecture.md", "CONTRIBUTING.md"]
      }
    },
    {
      "id": "opp-4",
      "consensus": false,
      "found_by": ["grok"],
      "consensus_round": 5,
      "claude_score": 7,
      "gemini_score": 8,
      "grok_score": 10,
      "disagreement": {
        "claude_final_argument": "...",
        "gemini_final_argument": "...",
        "grok_final_argument": "...",
        "unresolved_objection": "..."
      }
    }
  ]
}
```

---

## 12. Failure Handling

| Failure | Detection | Action |
|---|---|---|
| Gemini unavailable at start | Health check fails | **STOP.** Announce. Ask operator. No fallback. |
| Grok unavailable at start | Health check fails | **STOP.** Announce. Ask operator. No fallback. |
| Gemini rate-limited mid-scan | 429/timeout | Wait 120s, retry ×5. If still failing → **continue without Gemini** (PARTIAL). Write ⚠ WARNING in report.md + detailed-log.md: "Gemini unavailable after 5 retries during Phase {N}, Round {M}. Scan continued with Claude + Grok only. Re-run recommended." |
| Grok rate-limited mid-scan | 429/timeout | Wait 120s, retry ×5. If still failing → **continue without Grok** (PARTIAL). Write ⚠ WARNING in report.md + detailed-log.md: "Grok unavailable after 5 retries during Phase {N}, Round {M}. Scan continued with Claude + Gemini only. Re-run recommended." |
| Any agent output unparseable | JSON parse fails | Retry once with format reminder. If still fails → **STOP.** Show raw output. Ask operator. |
| Clone fails | git clone non-zero exit | STOP. Check GITHUB_TOKEN scope for private repos. |
| Disk full during clone | No space left | STOP. Report. Operator clears /tmp/aamm-v7-*/. |
| Context pressure (Claude) | Subagent approaching limits | Prioritize: Opportunity Map > Recommendations > Risk Surface. Flag partial assessment. |
| 0 approved opportunities | Consensus loop → empty | Valid outcome. Report: data summary + all rejection logs. Flag for CoE. |
| All items consensus: false | 5 rounds, no agreement | Valid outcome. All disagreement signals preserved. Report flags for CoE review. |

---

## 13. Invariants

Non-negotiable constraints. Any implementation that violates these is wrong.

1. **Tri-agent is the standard.** Health check failure at scan start (either Gemini or Grok) → scan does not begin. Mid-scan rate-limit failure (either Gemini or Grok) after 5 retries → scan continues with remaining 2 agents, flagged PARTIAL with ⚠ WARNING. Both agents treated symmetrically. No other fallbacks.
2. **Independence before debate.** No agent sees another's analysis or file requests before completing its own.
3. **Zero pre-selection.** Orchestrator serves file requests unfiltered. Never adds or removes files from an agent's request.
4. **Evidence-only arguments.** Scores without concrete evidence citations are ignored in consensus.
5. **No default concession.** Score changes require new evidence, stated explicitly.
6. **Tiered consensus thresholds.** All 3 ≥9/10 → HIGH. Two of 3 ≥9 + third ≥7 → MEDIUM, coe_review_required. Any agent <7 after 5 rounds → consensus: false. See Section 9 for full tiered model.
7. **5 rounds maximum.** Prevents loops. Unresolved items are data, not failures.
8. **Full audit trail.** File requests per agent + every consensus round saved in detailed-log.md.
9. **Learning = union, not intersection.** Every evidence-backed finding enters KB proposals regardless of agent agreement.
10. **Read-only on target repos.** Neither clone writes to the scanned repo. AAMM never creates PRs, issues, commits, or comments on scanned repos.
11. **Report is official at completion.** No human gate between scan finish and report publication.
12. **Reference repos are learning-only.** Never appear in scoring scans, never in reports to teams.

---

## 14. What Does NOT Change from v6.1

- KB format, content, and pattern structure
- Report sections and ordering (new fields added, none removed)
- Scan-from-zero rule (no previous results read before Phase 3 is frozen)
- ROI ordering logic and formula
- Pre-commit Gemini hook on models/ (reviewer role, separate from scan participant role)
- CoE review gate for KB merges
- Publishing to Notion requires human approval
- AAMM is a consultation, not a score

---

## 15. Prompt Design

Prompts are part of the design, not the implementation. They define exactly what each agent receives, which directly determines independence quality. Wrong prompts = biased independence, even with the right protocol.

### Design Principles for All Prompts

1. **No Claude framing** — Prompts for Gemini and Grok never position Claude as "primary" or "first analyst". Both are "independent analysts with equal standing."
2. **No prior conclusions injected** — Analysis prompts never include another agent's findings. Scoring prompts include the findings to score but not the reasoning chain behind them.
3. **Role clarity** — Each prompt states exactly what the agent is doing in this phase and what it is NOT doing (e.g., "produce opportunity map only — no component assessment yet").
4. **Evidence mandate** — All prompts state explicitly: every claim must cite file:line, commit SHA, or config line. No abstract claims.
5. **Independence instruction** — All analysis prompts include: "Do not accept any prior analysis. Form your own conclusions from the evidence."
6. **Persona consistency** — Gemini prompts align with GEMINI.md (skeptical, methodical, citation-heavy). Grok prompts align with GROK.md (survivability, scale, absence signals, value for personas).

---

### Prompt Inventory

#### P1 — File Request (all agents)

**Purpose:** Agent receives manifest + KB, produces list of files it wants to examine.
**Receives:** manifest.json, KB ecosystem file, cross-cutting.md, anti-patterns.md, scoring-model.md
**Must NOT receive:** Any file contents, any other agent's file request

**Gemini variant:**
```
You are an independent AI analyst. You will assess [{OWNER}/{REPO}] for AI adoption opportunities.
You have access to the repository at [{CLONE_PATH}] — you can read any file using your tools.

Below is the repository manifest (structure and stats only — no file contents).
Below is the Knowledge Base for [{ECOSYSTEM}] ecosystem.

Based on the manifest and KB patterns, list the files you want to examine before producing
your analysis. Be thorough — the goal is to find signals others might miss.

Output a JSON array of file paths: ["path/to/file1", "path/to/file2", ...]

[MANIFEST]
{MANIFEST_JSON}

[KB — {ECOSYSTEM}]
{KB_ECOSYSTEM_CONTENT}

[KB — Cross-Cutting]
{KB_CROSSCUTTING_CONTENT}

[KB — Anti-Patterns]
{KB_ANTIPATTERNS_CONTENT}
```

Note: Gemini uses --yolo so it can also directly browse the clone beyond what it lists here. The file request list is the structured starting point; Gemini may read additional files during analysis.

**Grok variant:**
```
You are a design challenger analyzing [{OWNER}/{REPO}] for AI adoption opportunities.

Your lens: ask "will this survive reality?" — operational survivability at scale,
value for specific personas (tech leads, repo owners, CoE, CBU leadership), and
absence signals (what should be here but isn't, and why does that gap matter?).

Based on the manifest and KB patterns below, decide which files you want to examine.
Let your lens guide your selection — do not constrain yourself to any particular file
type. Ask: what evidence would prove (or disprove) genuine AI adoption in a repo like
this? What would a skeptic look for?

Output: JSON array of file paths (max 50 per batch — you will be served more if needed).

[MANIFEST]
{MANIFEST_JSON}

[KB — {ECOSYSTEM}]
{KB_ECOSYSTEM_CONTENT}

[KB — Cross-Cutting]
{KB_CROSSCUTTING_CONTENT}

[KB — Anti-Patterns]
{KB_ANTIPATTERNS_CONTENT}
```

---

#### P2 — Independent Analysis (all agents)

**Purpose:** Agent analyzes its requested files and produces an opportunity map.
**Receives:** Contents of its requested files + KB + scoring-model
**Must NOT receive:** Any other agent's analysis, any other agent's file requests

**Gemini variant:** Adapted from v6 `gemini-phase-1-analysis.md`. Key changes for v7:
- Remove "Collect Data" section (data collection was the file request phase)
- Add: "You have read the files you requested. Now analyze them."
- Add SDLC coverage framework reference: "Check signals across all SDLC layers, not just code."
- Keep: KB pattern matching, self-check, JSON output format

**Grok variant (new):**
```
You are analyzing [{OWNER}/{REPO}] as a design challenger.

You have read the files you requested. Your task: identify AI adoption opportunities
from the perspective of operational reality.

For each opportunity you identify:
- Will this survive 3 AM unattended? What breaks at scale?
- Which persona benefits most (tech lead, repo owner, CoE, CBU leadership)?
- What is the absence signal? (What SHOULD be here but isn't — and why does that matter?)
- What is the risk if adopted without the right foundation?

Produce an opportunity map with the same JSON format as other agents.
Every finding must cite specific evidence (file:line, commit SHA, config entry).
Do not accept any prior analysis. Form your own conclusions from the evidence.

[FILES YOU REQUESTED]
{REQUESTED_FILE_CONTENTS}

[KB — {ECOSYSTEM}]
{KB_ECOSYSTEM_CONTENT}

[OUTPUT FORMAT]
{JSON_SCHEMA}
```

---

#### P3 — Consensus Scoring (all agents)

**Purpose:** Agent scores another agent's findings. May approve, challenge, or counter-argue.
**Receives:** Findings to score (JSON) + previous rounds (if round > 1) + clone access
**Must NOT receive:** Scoring agent's own previous scores (to avoid anchoring)

**Shared structure (Gemini + Grok use same schema, different framing):**

Gemini framing: "You are reviewing findings from another independent analyst. Score each 1-10 based on evidence quality, specificity to this repo, and actionability."

Grok framing: "You are challenging findings from another analyst. Score each 1-10 based on operational survivability, scale viability, and value for the intended personas. A 9+ means you believe this finding will hold up in production reality."

**Both use identical JSON output schema:**
```json
{
  "scores": [
    {
      "id": "string",
      "score": 8,
      "argument": "string — why this score, citing evidence",
      "challenge": {
        "objection": "string — what is wrong, with evidence (file:line or commit SHA)",
        "resolution": "string — what would change your mind specifically"
      }
    }
  ]
}
```
`challenge` included only when score < 9.

---

#### P4 — Component Assessment (all agents)

**Purpose:** Agent independently assesses adoption state, readiness, and risk per approved opportunity.
**Receives:** Approved opportunity map (IDs + titles only, no scores) + KB readiness criteria + clone access
**Must NOT receive:** Other agent's component assessment

Gemini: adapted from v6 `gemini-component-assessment.md` — unchanged in structure, add SDLC coverage note.

Grok variant (new): emphasis on risk surface and operational failure modes.
```
For each approved opportunity, assess:
1. Adoption State (Active/Partial/Absent) — with evidence
2. Readiness — using KB criteria provided. For each criterion: met or not, with evidence.
3. Risk Surface — your primary contribution:
   - What fails at scale for this adoption path?
   - What is the blast radius if this goes wrong in production?
   - What detection difficulty does each risk carry?
   - Is this a "Risky Acceleration" scenario (Active + gaps)?
```

---

#### P5 — Recommendations (all agents)

**Purpose:** Agent generates recommendations from approved opportunity map + component assessment.
**Receives:** Approved opportunity map + component consensus + KB + scoring-model Section 4
**Must NOT receive:** Other agents' recommendations

Gemini: adapted from v6 `gemini-phase-2-recommendations.md`.

Grok variant (new): explicit persona framing.
```
Generate recommendations for [{OWNER}/{REPO}] based on the approved opportunity map.

For each recommendation, state explicitly:
- Who benefits: tech lead / repo owner / CoE / CBU leadership
- What fails if this is not done (risk of inaction)
- What operational reality check applies (will this work at scale?)
- ROI rank: is the effort genuinely justified for THIS team's context?
```

---

#### P6 — Intersection Assessment (all agents)

**Purpose:** Agent independently assesses whether proposed intersection matches are genuinely equivalent.
**Receives:** Proposed matches (both agents' findings side by side) — no scores

Structure: "For each proposed match, assess independently: are these findings equivalent, partially overlapping, or distinct? Cite specific evidence. Do not default to agreement."

Options per match: `equivalent` | `partial_overlap` | `distinct`
Evidence required for all three — not just for disagreement.

This prompt is identical structure for Gemini and Grok.

---

### What Prompts Must Never Include

- Another agent's reasoning chain or internal thought process
- Claude's confidence assessments
- Any framing that implies one agent has already "decided" the correct answer
- Instructions to "agree with" or "validate" another agent's finding
- The word "confirm" when the intent is "analyze" (confirmation bias risk)

---

## 16. Sign-Off Round — Complete Flow Review

This is the final review round. All previously open questions are now resolved in v3:

| Issue | Resolution |
|---|---|
| Clone depth (H2 R1) | `--depth=100` scoring, `--shallow-since=12mo` learning |
| Grok context overflow (H1 R1) | Batched serving, 50 files/batch, max 5, WARNING on overflow |
| All-or-nothing strictness (M1 R1) | Tiered: HIGH (all ≥9), MEDIUM (2/3 ≥9 + third ≥7), consensus:false |
| AI Governance missing (M2 R1) | Added to SDLC Section 8 |
| Qualitative signals (M3 R1) | Detectability note added |
| Reference repo staleness (L1 R1) | 6-month scheduled cadence + trigger thresholds |
| P6 confirmation bias (H1 R2) | "Confirm or contest" → "Assess: equivalent/partial_overlap/distinct" |
| Absence signals dropped (H2 R2) | LOW-ABSENCE tier in learning filter |
| Grok P1 prescriptive (M1 R2) | Perspective-based framing, not file-type lists |
| Monorepo unhandled (M2 R2) | Phase 0 subproject detection + per-subproject targeting |
| Partial coverage flag subtle (M3 R2) | Prominent ⚠ WARNING banner in report.md |
| Private repo 403 (Grok R1) | API access check before clone |
| Dynamic SDLC pruning (Grok R1) | repo_type detection + per-type active sections table |
| Manifest pre-selection bias (Grok R2) | Raw commit counts, no "top 20" filter |

**Agents are asked to review the complete spec (all sections) and provide one of:**
- `APPROVED` — flow is correct, complete, implementable
- `CONDITIONAL APPROVAL` — approved pending specific stated fix (must be minor)
- `REJECTED` — material issue remains, must be addressed before implementation

No new major findings expected. If a new HIGH finding surfaces, address and re-review.
