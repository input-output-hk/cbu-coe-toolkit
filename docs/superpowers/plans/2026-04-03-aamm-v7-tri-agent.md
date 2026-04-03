# AAMM v7 — Tri-Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Read first:** `docs/superpowers/specs/2026-04-03-aamm-v7-tri-agent-design.md` — spec is APPROVED (Grok: APPROVED, Gemini: CONDITIONAL APPROVAL, fixes applied).
>
> **Read second:** This file. Do not start implementing until you have read both.

**Goal:** Replace AAMM v6.1 dual-agent (Claude + Gemini) with tri-agent (Claude + Gemini + Grok), local clone + request/serve protocol, tiered consensus, dynamic SDLC pruning, and learning scan union model.

**Architecture:** Claude orchestrates via isolated subagents. Gemini accesses the local clone via `--yolo`. Grok accesses the local clone via batched file serving through xAI API. All three agents independently decide what files to examine from a neutral manifest before any analysis begins.

**Tech Stack:** Bash (orchestration), Claude Code Agent tool (subagents), Gemini CLI (`gemini --yolo -m gemini-2.5-pro`), xAI API (`scripts/grok-invoke.sh`, `$XAI_API_KEY`), JSON (consensus exchange), Markdown (reports), YAML (config).

---

## File Map

### New files to create

| File | Responsibility |
|---|---|
| `.claude/skills/scan-aamm-v7/SKILL.md` | Main scan skill — replaces scan-aamm-v6 |
| `.claude/skills/scan-aamm-v7/prompts/gemini-file-request.md` | P1 Gemini: manifest → file list |
| `.claude/skills/scan-aamm-v7/prompts/gemini-phase1-analysis.md` | P2 Gemini: files → opportunity map |
| `.claude/skills/scan-aamm-v7/prompts/gemini-consensus-round.md` | P3 Gemini: score findings, challenge/accept |
| `.claude/skills/scan-aamm-v7/prompts/gemini-component-assessment.md` | P4 Gemini: adoption/readiness/risk per opportunity |
| `.claude/skills/scan-aamm-v7/prompts/gemini-phase2-recommendations.md` | P5 Gemini: opportunity map → recommendations |
| `.claude/skills/scan-aamm-v7/prompts/grok-file-request.md` | P1 Grok: manifest → file list (batched) |
| `.claude/skills/scan-aamm-v7/prompts/grok-phase1-analysis.md` | P2 Grok: files → opportunity map (adversarial lens) |
| `.claude/skills/scan-aamm-v7/prompts/grok-consensus-round.md` | P3 Grok: score findings, survivability/scale lens |
| `.claude/skills/scan-aamm-v7/prompts/grok-component-assessment.md` | P4 Grok: risk surface emphasis |
| `.claude/skills/scan-aamm-v7/prompts/grok-phase2-recommendations.md` | P5 Grok: recommendations with persona framing |
| `.claude/skills/select-reference-repos/SKILL.md` | Tri-agent consensus on external KB reference repos |
| `schema/assessment-v7.schema.json` | JSON schema for assessment output (tri-agent fields) |
| `docs/decisions/020-aamm-v7-tri-agent.md` | ADR-020 |

### Files to modify

| File | Change |
|---|---|
| `GROK.md` | Add "Role in AAMM v7 Scans" section |
| `CLAUDE.md` | Update scan flow diagram, v7 references, dual-agent → tri-agent |
| `models/config.yaml` | Add `reference_repos:` section |
| `models/ai-augmentation-maturity/scoring-model.md` | Rewrite for v7 (tri-agent, local clone, manifest-driven) |
| `models/ai-augmentation-maturity/changelog.md` | Add v7 entry |

### Files that do NOT change

`scripts/grok-invoke.sh`, `GEMINI.md` (scan participant role already in place), all KB files, existing scan results, `models/ai-augmentation-maturity/spec.md` (updated separately as human-readable spec).

---

## Phase 1 — Infrastructure & Scaffolding

### Task 1: ADR-020

**Files:**
- Create: `docs/decisions/020-aamm-v7-tri-agent.md`

- [ ] **Step 1: Write ADR-020**

```markdown
# ADR-020 — AAMM v7 Tri-Agent Architecture

**Date:** 2026-04-03
**Status:** Accepted
**Supersedes:** ADR-019 (single-agent), ADR-018 (v5 architecture)

## Context

AAMM v6.1 introduced dual-agent consensus (Claude + Gemini) to eliminate single-model bias. Two issues remained:
1. Pre-selection bias: Claude collected all repo data before Gemini saw it.
2. Two agents share structural blind spots around operational survivability and scale.

## Decision

Replace dual-agent with tri-agent architecture:
- **Claude** (orchestrator + scorer): pattern matching, KB alignment
- **Gemini** (independent scorer): skeptical, methodical, citation-heavy
- **Grok** (independent scorer): survivability, scale, value for personas, absence signals

Replace GitHub API pre-collection with local clone + request/serve protocol:
each agent independently decides what files to examine from a neutral manifest.

Use tiered consensus: all 3 ≥9 → HIGH; 2 of 3 ≥9 + third ≥7 → MEDIUM (CoE review required);
otherwise → consensus:false.

Use union model for learning scans (maximize recall, CoE filters).

## Consequences

- Eliminates pre-selection bias: every agent independently decides what to read
- Eliminates two-agent blind spots: Grok's adversarial perspective catches what Claude+Gemini miss
- Increases scan complexity: 3 agents, batched serving for Grok, PARTIAL handling
- Future-proof: fourth agent enters by following same protocol, no orchestration changes
- Cost: Claude Max (zero) + Gemini Google One AI Pro (zero) + xAI API (low cost per scan)

## Rejected alternatives

- Gemini-only third pass: same blind spots, no structural diversity
- All-or-nothing ≥9: too strict, Grok's adversarial nature would produce 40-60% consensus:false
```

- [ ] **Step 2: Commit**

```bash
cd /home/devuser/repos/cbu-coe/cbu-coe-toolkit
git checkout -b feat/aamm-v7-tri-agent
git add docs/decisions/020-aamm-v7-tri-agent.md
git commit -m "docs: add ADR-020 for AAMM v7 tri-agent architecture"
```

---

### Task 2: Update GROK.md with scan participant role

**Files:**
- Modify: `GROK.md`

- [ ] **Step 1: Read current GROK.md**

Open `GROK.md` and locate the end of the file.

- [ ] **Step 2: Append scan participant section**

Add after the existing `## Invocation` section:

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

### What stays the same from design challenger role

- Break it first — find how the design fails before confirming it works
- Concrete scenarios — every challenge is "when repo X has Y and agent does Z, then W"
- Quantify — "this is slow" → "this requires N calls × M seconds = N×M total"
- Respect what works — if a finding is solid, approve it
```

- [ ] **Step 3: Verify grok-invoke.sh health check still works**

```bash
source ~/.zshrc 2>/dev/null
cd /home/devuser/repos/cbu-coe/cbu-coe-toolkit
bash scripts/grok-invoke.sh grok-4-0709 "Reply with exactly: AAMM_READY" 2>/dev/null | grep -q "AAMM_READY" && echo "PASS" || echo "FAIL"
```

Expected: `PASS`

- [ ] **Step 4: Commit**

```bash
git add GROK.md
git commit -m "docs: add AAMM v7 scan participant role to GROK.md"
```

---

### Task 3: Update CLAUDE.md with v7 scan flow

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update scan flow section**

In `CLAUDE.md`, find the `## Scan flow` section and replace it with:

```markdown
## Scan flow (v7 — tri-agent consensus)

```
/scan-aamm-v7 owner/repo
  → Health-check Gemini CLI + Grok API (parallel)  # STOP if either unavailable
  → Access check via GitHub API                     # STOP if 403
  → Clone repo locally → /tmp/aamm-v7-$OWNER-$REPO/clone/
  → Detect repo type (library/web-app/cli-tool/infrastructure/mixed)
  → Detect monorepo subprojects (deny-list: vendor/, deps/, third_party/)
  → Generate neutral manifest (structure + stats, no content, no signals)

  → Phase 1: File Requests (independent, parallel)
    → Claude subagent: requests files based on manifest + KB
    → Gemini: requests files based on manifest + KB (--yolo, can browse beyond list)
    → Grok: requests files based on manifest + KB (batched, max 50/batch)
    → Orchestrator serves all requests unfiltered from /clone/

  → Phase 2: Independent Analysis
    → Claude subagent: produces opportunity-map-claude.json
    → Gemini: produces opportunity-map-gemini.json
    → Grok: produces opportunity-map-grok.json
    → No agent sees another's output

  → Phase 3: Consensus — Opportunity Map
    → Intersection-first (items all 3 found → auto-approved)
    → Consensus loop max 5 rounds (JSON structured, ~120 tokens/exchange)
    → Tiered outcome: HIGH (all ≥9) | MEDIUM (2/3 ≥9 + third ≥7, CoE flag) | consensus:false
    → MEDIUM cap: 10 items per scan; overflow downgraded to LOW
    → Component Assessment (adoption/readiness/risk): same pattern

  → Phase 4: Consensus — Recommendations
    → All 3 generate independently → intersection-first → loop
    → ROI ordering consensus

  → Phase 5: Report Generation (Claude subagent, fresh context)
    → Reads assessment.json (frozen) + previous scan for delta
    → Writes: report.md, assessment.json, detailed-log.md

  → Phase 6: Save to scans/ai-augmentation/results/YYYY-MM-DD/$OWNER--$REPO/
```

Mid-scan failure: Gemini or Grok unavailable after 5 retries → continue PARTIAL with ⚠ WARNING in report.
```

- [ ] **Step 2: Update design principles line about dual-agent**

Find: `**Dual-agent consensus is mandatory — Claude + Gemini at every phase`
Replace with: `**Tri-agent consensus — Claude + Gemini + Grok at every phase (ADR-020 + spec 2026-04-03).**`

- [ ] **Step 3: Update Rule 12**

Find: `**Dual-agent consensus is mandatory (ADR-012 + ADR-019 + spec 2026-04-02).**`
Replace with: `**Tri-agent consensus is mandatory (ADR-020 + spec 2026-04-03).** Claude + Gemini + Grok participate in every scoring scan. Health check failure at start → STOP. Mid-scan failure after 5 retries → PARTIAL with WARNING.`

- [ ] **Step 4: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md scan flow diagram and rules for v7 tri-agent"
```

---

### Task 4: assessment-v7 JSON schema

**Files:**
- Create: `schema/assessment-v7.schema.json`

- [ ] **Step 1: Create schema directory if needed**

```bash
mkdir -p schema
```

- [ ] **Step 2: Write schema**

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "AAMM v7 Assessment",
  "type": "object",
  "required": ["scan_metadata", "opportunity_map", "recommendations"],
  "properties": {
    "scan_metadata": {
      "type": "object",
      "required": ["repo", "date", "agents", "consensus_model", "scan_mode"],
      "properties": {
        "repo": { "type": "string" },
        "subproject": { "type": ["string", "null"] },
        "date": { "type": "string", "format": "date" },
        "agents": {
          "type": "array",
          "items": { "enum": ["claude", "gemini", "grok"] }
        },
        "consensus_model": { "enum": ["tri-agent-v1", "partial-gemini", "partial-grok"] },
        "scan_mode": { "enum": ["scoring", "learning"] },
        "local_clone": { "type": "boolean" },
        "repo_type": { "enum": ["library", "web-app", "cli-tool", "infrastructure", "mixed"] },
        "partial": { "type": "boolean", "default": false },
        "partial_reason": { "type": ["string", "null"] },
        "phase_1_rounds": { "type": "integer" },
        "phase_2_rounds": { "type": "integer" },
        "medium_overflow_count": { "type": "integer", "default": 0 }
      }
    },
    "opportunity_map": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "title", "value", "effort", "roi_rank", "evidence", "consensus"],
        "properties": {
          "id": { "type": "string" },
          "title": { "type": "string" },
          "value": { "enum": ["HIGH", "MEDIUM", "LOW"] },
          "effort": { "enum": ["High", "Medium", "Low"] },
          "roi_rank": { "type": "integer" },
          "evidence": { "type": "string" },
          "kb_pattern": { "type": ["string", "null"] },
          "found_by": {
            "type": "array",
            "items": { "enum": ["claude", "gemini", "grok"] }
          },
          "consensus": { "type": "boolean" },
          "confidence": { "enum": ["HIGH", "MEDIUM", "LOW"] },
          "coe_review_required": { "type": "boolean", "default": false },
          "consensus_round": { "type": "integer" },
          "claude_score": { "type": ["number", "null"] },
          "gemini_score": { "type": ["number", "null"] },
          "grok_score": { "type": ["number", "null"] },
          "debate_summary": { "type": ["string", "null"] },
          "disagreement": {
            "type": ["object", "null"],
            "properties": {
              "claude_final_argument": { "type": "string" },
              "gemini_final_argument": { "type": "string" },
              "grok_final_argument": { "type": "string" },
              "unresolved_objection": { "type": "string" }
            }
          },
          "file_requests": {
            "type": "object",
            "properties": {
              "claude": { "type": "array", "items": { "type": "string" } },
              "gemini": { "type": "array", "items": { "type": "string" } },
              "grok": { "type": "array", "items": { "type": "string" } }
            }
          },
          "adoption_state": {
            "type": ["object", "null"],
            "properties": {
              "state": { "enum": ["Active", "Partial", "Absent"] },
              "evidence": { "type": "string" }
            }
          },
          "readiness": { "type": ["object", "null"] },
          "risk_surface": { "type": ["array", "null"] }
        }
      }
    },
    "recommendations": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "opportunity_id", "type", "consensus"],
        "properties": {
          "id": { "type": "string" },
          "opportunity_id": { "type": "string" },
          "type": { "enum": ["start_now", "foundation_first", "fix_the_foundation"] },
          "title": { "type": "string" },
          "rationale": { "type": "string" },
          "roi_rank": { "type": "integer" },
          "consensus": { "type": "boolean" },
          "confidence": { "enum": ["HIGH", "MEDIUM", "LOW"] },
          "coe_review_required": { "type": "boolean", "default": false },
          "found_by": { "type": "array", "items": { "enum": ["claude", "gemini", "grok"] } },
          "claude_score": { "type": ["number", "null"] },
          "gemini_score": { "type": ["number", "null"] },
          "grok_score": { "type": ["number", "null"] },
          "debate_summary": { "type": ["string", "null"] }
        }
      }
    }
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add schema/assessment-v7.schema.json
git commit -m "feat: add assessment-v7 JSON schema with tri-agent consensus fields"
```

---

### Task 5: Update models/config.yaml

**Files:**
- Modify: `models/config.yaml`

- [ ] **Step 1: Add reference_repos section**

At the end of `models/config.yaml`, add:

```yaml

# ============================================================
# Reference Repos — External benchmarks for KB enrichment
# scope: learning ONLY — never scored, never reported to teams
# Selected by tri-agent consensus (all 3 agents ≥9/10)
# ============================================================
reference_repos: []
# Populated by /select-reference-repos skill after tri-agent consensus
# Format per entry:
#   - repo: owner/repo-name
#     language: haskell|rust|typescript|python
#     scope: learning
#     rationale: "one-line reason"
#     selected_by: tri-agent-consensus
#     selected_date: YYYY-MM-DD
```

- [ ] **Step 2: Commit**

```bash
git add models/config.yaml
git commit -m "feat: add reference_repos section to config.yaml for v7 KB enrichment"
```

---

## Phase 2 — Prompt Files

### Task 6: Gemini prompt files

**Files:**
- Create: `.claude/skills/scan-aamm-v7/prompts/gemini-file-request.md`
- Create: `.claude/skills/scan-aamm-v7/prompts/gemini-phase1-analysis.md`
- Create: `.claude/skills/scan-aamm-v7/prompts/gemini-consensus-round.md`
- Create: `.claude/skills/scan-aamm-v7/prompts/gemini-component-assessment.md`
- Create: `.claude/skills/scan-aamm-v7/prompts/gemini-phase2-recommendations.md`

- [ ] **Step 1: Create prompts directory**

```bash
mkdir -p .claude/skills/scan-aamm-v7/prompts
```

- [ ] **Step 2: Write gemini-file-request.md**

```markdown
# AAMM v7 — Gemini File Request

You are an independent AI analyst. You will assess `{OWNER}/{REPO}` for AI adoption opportunities.
You have access to the repository at `{CLONE_PATH}` — you can read any file using your tools.

This is Phase 1 of 2. In this phase: decide which files to examine. Do NOT start your analysis yet.

Below is the repository manifest (structure and stats only — no file contents).
Below is the Knowledge Base for the `{ECOSYSTEM}` ecosystem.
Repo type: `{REPO_TYPE}` — active SDLC sections: `{ACTIVE_SDLC_SECTIONS}`

Based on the manifest and KB patterns, list the files you want to examine before producing your analysis.
Be thorough — your goal is to find signals others might miss.
You may also read additional files directly using your tools during analysis (Phase 2).

Output a JSON array of file paths and nothing else:
`["path/to/file1", "path/to/file2", ...]`

[MANIFEST]
{MANIFEST_JSON}

[KB — {ECOSYSTEM}]
{KB_ECOSYSTEM_CONTENT}

[KB — Cross-Cutting]
{KB_CROSSCUTTING_CONTENT}

[KB — Anti-Patterns]
{KB_ANTIPATTERNS_CONTENT}
```

- [ ] **Step 3: Write gemini-phase1-analysis.md**

```markdown
# AAMM v7 — Gemini Independent Analysis

You are an independent AI analyst assessing `{OWNER}/{REPO}` (ecosystem: `{ECOSYSTEM}`) for AI adoption opportunities.
You have equal standing with the other analysts — your findings carry the same weight.

Repo type: `{REPO_TYPE}`. Active SDLC sections: `{ACTIVE_SDLC_SECTIONS}`.
Subproject scope (if monorepo): `{SUBPROJECT_OR_NONE}`.

## Your Task

Produce an opportunity map for this repository. Component assessment (adoption, readiness, risk) happens later.

## Files You Requested

The following files have been served from the local clone:

{SERVED_FILE_CONTENTS}

You may also read additional files directly using your tools.

## Instructions

### 1. Match KB Patterns

For each KB pattern below, check its `applies_when` conditions against the files you have read.
If match: locate specific evidence, assess value/effort for this repo.

{KB_ECOSYSTEM_CONTENT}

{KB_CROSSCUTTING_CONTENT}

Also look for AI adoption signals not covered by KB patterns (flag as `kb_pattern: null`).

### 2. Check SDLC Coverage

For each active SDLC section (`{ACTIVE_SDLC_SECTIONS}`):
- Look for AI adoption signals (presence AND absence)
- Log absence signals explicitly: "Expected X — not found. This IS a signal."

### 3. Self-Check

For each opportunity: "Would this appear identically on any other `{ECOSYSTEM}` repo?" If yes → make it repo-specific or drop it.

### 4. Output Format

```json
{
  "opportunities": [
    {
      "id": "string — KB pattern ID or descriptive slug",
      "title": "string — specific action for THIS repo",
      "value": "HIGH|MEDIUM|LOW",
      "effort": "High|Medium|Low",
      "roi_rank": 1,
      "evidence": "string — file:line, commit SHA, or config entry from THIS repo",
      "kb_pattern": "string|null",
      "absence_signal": false
    }
  ]
}
```

## Rules

- **Do not accept any prior analysis.** Form your own conclusions from the evidence.
- **Read-only.** Do not create, modify, or delete any files in the repository.
- **Evidence required.** Every finding must cite specific file:line, commit SHA, or config line.
- **Output JSON only.**
```

- [ ] **Step 4: Write gemini-consensus-round.md**

```markdown
# AAMM v7 — Gemini Consensus Round

You are an independent AI analyst reviewing findings from another analyst for `{OWNER}/{REPO}`.
You have equal standing — you are not subordinate, and your assessment carries the same weight.
Round: {ROUND} of 5 maximum.

## Findings to Score

{FINDINGS_JSON}

## Previous Discussion

{PREVIOUS_ROUNDS_OR_NONE}

## Instructions

For each finding:

1. **Verify evidence.** Check cited file paths and commit SHAs in the repository using your tools.
2. **Score 1–10:**
   - 9–10: Strong evidence, specific to this repo, clearly actionable
   - 7–8: Reasonable but evidence gaps or specificity concerns
   - 5–6: Partially valid but generic or weakly evidenced
   - 1–4: Wrong, unsupported, or not applicable
3. **Challenge if score < 9.** Provide:
   - `objection`: what is wrong or weak, with evidence (file:line or commit SHA)
   - `resolution`: what specific evidence would change your mind
4. **Explain re-scoring.** If round > 1: what new evidence changed your score, or why it didn't change.

## Rules

- You are not obligated to agree. If your evidence supports your position, maintain it.
- Evidence wins over argument. File:line and commit SHAs outweigh assertions.
- No generic objections. "Too generic" is not valid. "Claims X but file Y:Z shows opposite" is.

## Output Format

```json
{
  "scores": [
    {
      "id": "string",
      "score": 8,
      "argument": "string — why this score, citing evidence",
      "challenge": {
        "objection": "string — what is wrong, with evidence",
        "resolution": "string — what specifically would change your mind"
      }
    }
  ]
}
```

Include `challenge` only when score < 9. Output JSON only.
```

- [ ] **Step 5: Write gemini-component-assessment.md**

Base this on the existing v6 prompt (`.claude/skills/scan-aamm-v6/prompts/gemini-component-assessment.md`) with these additions:

```markdown
# AAMM v7 — Gemini Component Assessment

You are an independent AI analyst assessing the approved opportunity map for `{OWNER}/{REPO}`.
You have equal standing with the other analysts.

Repo type: `{REPO_TYPE}`. Active SDLC sections: `{ACTIVE_SDLC_SECTIONS}`.

## Approved Opportunities

{APPROVED_OPPORTUNITIES_JSON}

## KB Readiness Criteria

{KB_READINESS_CRITERIA}

## Instructions

For each approved opportunity, independently assess:

### 1. Adoption State
- **Active** — production usage, established workflows, committed tooling
- **Partial** — experimentation, partial implementation, ad-hoc usage
- **Absent** — no evidence of AI adoption for this opportunity

Cite specific evidence (file:line, commit SHA, config line).

### 2. Readiness

Use ONLY the KB readiness criteria above. For each criterion:
- Is it met? (YES/NO)
- Confidence: HIGH (concrete evidence) | MEDIUM (pattern/heuristic) | LOW (inference/absence)
- Evidence

Readiness level = highest level where ALL criteria meet thresholds.

### 3. Risk Surface

- What could go wrong if AI is adopted here without preparation?
- What existing risks does AI adoption amplify?
- Detection difficulty, blast radius, AI exposure for each risk

## Output Format

```json
{
  "assessments": [
    {
      "opportunity_id": "string",
      "adoption_state": { "state": "Active|Partial|Absent", "evidence": "string" },
      "readiness": {
        "level": "Undiscovered|Exploring|Practiced|Not Assessable",
        "criteria_results": [
          { "criterion": "string", "result": "YES|NO", "confidence": "HIGH|MEDIUM|LOW", "evidence": "string" }
        ],
        "risky_acceleration_flag": false
      },
      "risk_surface": [
        {
          "path": "string",
          "detection_difficulty": "HIGH|MEDIUM|LOW",
          "blast_radius": "HIGH|MEDIUM|LOW",
          "ai_exposure": "confirmed|potential|none",
          "evidence": "string"
        }
      ]
    }
  ]
}
```

Output JSON only.
```

- [ ] **Step 6: Write gemini-phase2-recommendations.md**

Base on v6 `gemini-phase-2-recommendations.md` with v7 updates:

```markdown
# AAMM v7 — Gemini Recommendations

You are an independent AI analyst generating recommendations for `{OWNER}/{REPO}`.
You have equal standing with the other analysts.
Do NOT accept any prior recommendations. Generate your own from the evidence below.

## Approved Opportunity Map + Component Assessment

{APPROVED_MAP_WITH_ASSESSMENT_JSON}

## Instructions

Generate recommendations ordered by ROI. For each:

1. Derive from: opportunity × readiness gap × adoption state
2. Type: `start_now` (readiness met, adopt), `foundation_first` (readiness gap, build it), `fix_the_foundation` (active but risky)
3. Self-check: "Is this recommendation specific to this repo's context? Does it include risk of inaction?"

## Output Format

```json
{
  "recommendations": [
    {
      "id": "string",
      "opportunity_id": "string",
      "type": "start_now|foundation_first|fix_the_foundation",
      "title": "string — specific action",
      "rationale": "string — why now, for this repo",
      "risk_of_inaction": "string — what happens if not done",
      "roi_rank": 1,
      "evidence": "string"
    }
  ]
}
```

Output JSON only.
```

- [ ] **Step 7: Commit**

```bash
git add .claude/skills/scan-aamm-v7/prompts/gemini-*.md
git commit -m "feat: add Gemini prompt files for AAMM v7 (P1-P5)"
```

---

### Task 7: Grok prompt files

**Files:**
- Create: `.claude/skills/scan-aamm-v7/prompts/grok-file-request.md`
- Create: `.claude/skills/scan-aamm-v7/prompts/grok-phase1-analysis.md`
- Create: `.claude/skills/scan-aamm-v7/prompts/grok-consensus-round.md`
- Create: `.claude/skills/scan-aamm-v7/prompts/grok-component-assessment.md`
- Create: `.claude/skills/scan-aamm-v7/prompts/grok-phase2-recommendations.md`

- [ ] **Step 1: Write grok-file-request.md**

```markdown
# AAMM v7 — Grok File Request

You are a design challenger analyzing `{OWNER}/{REPO}` for AI adoption opportunities.

Your lens: ask "will this survive reality?" — operational survivability at scale,
value for specific personas (tech leads, repo owners, CoE, CBU leadership), and
absence signals (what should be here but isn't, and why does that gap matter?).

Repo type: `{REPO_TYPE}`. Active SDLC sections: `{ACTIVE_SDLC_SECTIONS}`.

Based on the manifest and KB patterns below, decide which files you want to examine.
Let your lens guide your selection — do not constrain yourself to any particular file type.
Ask: what evidence would prove (or disprove) genuine AI adoption in a repo like this?
What would a skeptic look for?

This is batch {BATCH_NUMBER} of up to 5. You will receive more files if needed.

Output: JSON array of file paths (max 50 files):
`["path/to/file1", "path/to/file2", ...]`

[MANIFEST]
{MANIFEST_JSON}

[KB — {ECOSYSTEM}]
{KB_ECOSYSTEM_CONTENT}

[KB — Cross-Cutting]
{KB_CROSSCUTTING_CONTENT}

[KB — Anti-Patterns]
{KB_ANTIPATTERNS_CONTENT}
```

- [ ] **Step 2: Write grok-phase1-analysis.md**

```markdown
# AAMM v7 — Grok Independent Analysis

You are a design challenger assessing `{OWNER}/{REPO}` (ecosystem: `{ECOSYSTEM}`) for AI adoption opportunities.
You have equal standing with the other analysts — your findings carry the same weight.

Repo type: `{REPO_TYPE}`. Active SDLC sections: `{ACTIVE_SDLC_SECTIONS}`.
Subproject scope (if monorepo): `{SUBPROJECT_OR_NONE}`.
{PARTIAL_COVERAGE_NOTE}

## Your Task

Produce an opportunity map from your design challenger perspective. Component assessment happens later.

## Files Served (Batch {BATCH_NUMBER})

{SERVED_FILE_CONTENTS}

## Prior Batch Findings (if batch > 1)

{PRIOR_BATCH_FINDINGS_OR_NONE}

## Instructions

### 1. Match KB Patterns

For each KB pattern, check `applies_when` conditions. If match: locate specific evidence.

{KB_ECOSYSTEM_CONTENT}

{KB_CROSSCUTTING_CONTENT}

### 2. Absence Signals (your primary contribution)

For each active SDLC section, explicitly answer: "What should be here but isn't?"
Quantify absences: "zero AI config files in a repo with {N} contributors over {M} months" is a signal.

### 3. Survivability Check

For each opportunity: will this work at 3 AM unattended? What breaks at scale?

### 4. Self-Check

For each opportunity: "Would this appear identically on any other {ECOSYSTEM} repo?" If yes → make it specific.

### 5. Output Format

```json
{
  "opportunities": [
    {
      "id": "string",
      "title": "string — specific to THIS repo",
      "value": "HIGH|MEDIUM|LOW",
      "effort": "High|Medium|Low",
      "roi_rank": 1,
      "evidence": "string — file:line, commit SHA, or quantified absence",
      "kb_pattern": "string|null",
      "absence_signal": true,
      "survivability_concern": "string|null — what breaks at scale, or null if solid"
    }
  ],
  "need_more_files": ["path/to/file"]
}
```

Include `need_more_files` if you need additional files (triggers next batch). Leave empty if done.

Do NOT accept any prior analysis. Form your own conclusions. Output JSON only.
```

- [ ] **Step 3: Write grok-consensus-round.md**

```markdown
# AAMM v7 — Grok Consensus Round

You are challenging findings from another analyst for `{OWNER}/{REPO}`.
You have equal standing — your assessment is not subordinate to others.
Round: {ROUND} of 5 maximum.

## Findings to Score

{FINDINGS_JSON}

## Previous Discussion

{PREVIOUS_ROUNDS_OR_NONE}

## Instructions

For each finding, score 1–10 from your design challenger lens:

- **9–10**: Finding is solid AND will survive operational reality at scale
- **7–8**: Finding is correct but you have a scale/survivability/value concern — state it with evidence
- **5–6**: Finding is partially valid but has a material gap you can quantify
- **1–4**: Finding is wrong, unsupported, or will fail in production

**Valid evidence types:**
- `file:line` or commit SHA (direct file evidence)
- `projection: <quantified scenario>` with supporting repo stats (e.g., "500 files × 1k tokens = 500k tokens, exceeds 128k limit")
- Quantified absence: "zero Co-authored-by in last 200 commits across 3 years"

**Rules:**
- Score the finding on its own merits first. If solid but your lens reveals a gap → score 8+ with a challenge note.
- "This will fail" requires a specific scenario, not a general concern.
- If evidence is clear and the finding is genuinely solid → approve it (9+). No manufactured disagreement.

## Output Format

```json
{
  "scores": [
    {
      "id": "string",
      "score": 8,
      "argument": "string — why this score",
      "challenge": {
        "objection": "string — specific scenario or evidence",
        "resolution": "string — what would resolve this"
      }
    }
  ]
}
```

Include `challenge` only when score < 9. Output JSON only.
```

- [ ] **Step 4: Write grok-component-assessment.md**

```markdown
# AAMM v7 — Grok Component Assessment

You are a design challenger assessing the approved opportunity map for `{OWNER}/{REPO}`.
Your focus: risk surface and operational failure modes. Equal standing with other analysts.

## Approved Opportunities

{APPROVED_OPPORTUNITIES_JSON}

## KB Readiness Criteria

{KB_READINESS_CRITERIA}

## Instructions

For each opportunity, assess independently:

### 1. Adoption State (Active / Partial / Absent)
Cite specific evidence. If absence: quantify it ("zero AI steps in 47 CI runs over 6 months").

### 2. Readiness
Use KB criteria. For each: met? Confidence? Evidence?
Flag "Risky Acceleration" if: Active adoption + readiness gaps.

### 3. Risk Surface (your primary contribution)

For each risk:
- **Scenario**: "When X happens, Y fails because Z"
- **Scale**: at what point does this become a problem? (1 repo? 10? 100?)
- **Blast radius**: what breaks if this fails?
- **Detection difficulty**: how quickly would the team know?
- **AI exposure**: confirmed | potential | none

## Output Format

```json
{
  "assessments": [
    {
      "opportunity_id": "string",
      "adoption_state": { "state": "Active|Partial|Absent", "evidence": "string" },
      "readiness": {
        "level": "Undiscovered|Exploring|Practiced|Not Assessable",
        "criteria_results": [
          { "criterion": "string", "result": "YES|NO", "confidence": "HIGH|MEDIUM|LOW", "evidence": "string" }
        ],
        "risky_acceleration_flag": false
      },
      "risk_surface": [
        {
          "path": "string — specific failure scenario",
          "scale_threshold": "string — at what scale does this break",
          "detection_difficulty": "HIGH|MEDIUM|LOW",
          "blast_radius": "HIGH|MEDIUM|LOW",
          "ai_exposure": "confirmed|potential|none",
          "evidence": "string"
        }
      ]
    }
  ]
}
```

Output JSON only.
```

- [ ] **Step 5: Write grok-phase2-recommendations.md**

```markdown
# AAMM v7 — Grok Recommendations

You are a design challenger generating recommendations for `{OWNER}/{REPO}`.
Do NOT accept any prior recommendations. Generate your own from the evidence below.

## Approved Opportunity Map + Component Assessment

{APPROVED_MAP_WITH_ASSESSMENT_JSON}

## Instructions

Generate recommendations ordered by ROI. For each, answer:

1. **Who benefits?** tech lead | repo owner | CoE | CBU leadership (be specific)
2. **Will this survive reality?** What operational concern applies at scale?
3. **What's the risk of inaction?** Quantify if possible.
4. **Type:** `start_now` | `foundation_first` | `fix_the_foundation`

## Output Format

```json
{
  "recommendations": [
    {
      "id": "string",
      "opportunity_id": "string",
      "type": "start_now|foundation_first|fix_the_foundation",
      "title": "string",
      "rationale": "string",
      "primary_persona": "tech-lead|repo-owner|coe|leadership",
      "risk_of_inaction": "string",
      "survivability_note": "string|null",
      "roi_rank": 1,
      "evidence": "string"
    }
  ]
}
```

Output JSON only.
```

- [ ] **Step 6: Commit**

```bash
git add .claude/skills/scan-aamm-v7/prompts/grok-*.md
git commit -m "feat: add Grok prompt files for AAMM v7 (P1-P5)"
```

---

## Phase 3 — Main SKILL.md

### Task 8: scan-aamm-v7 SKILL.md — Phase 0 (setup + health checks)

**Files:**
- Create: `.claude/skills/scan-aamm-v7/SKILL.md` (initial — Phase 0 only)

- [ ] **Step 1: Write SKILL.md Phase 0**

```markdown
---
name: scan-aamm-v7
description: Run AAMM v7 scan — tri-agent (Claude + Gemini + Grok) consensus. Each agent independently requests files from a local clone, analyzes independently, then reaches tiered consensus. Produces ROI-ordered opportunities and recommendations.
---

# AAMM v7 Scan

## Input

Target repo specified as:
- **Single repo:** `owner/repo` directly
- **From config:** "scan all" or "scan next" → read `models/config.yaml`

Optional flags:
- `--mode=learning` — learning scan (union model, kb-proposals output only)
- `--subproject=path/to/subproject` — target specific subproject in monorepos

Set variables:
```
OWNER=<org name>
REPO=<repo name>
ECOSYSTEM=<language, lowercased: haskell|typescript|rust|python|lean|nix|shell>
SCAN_TYPE=<scoring (default) | learning>
SUBPROJECT=<subproject path | null>
SCAN_DIR=/tmp/aamm-v7-$OWNER-$REPO
```

## Phase 0 — Setup

### Step 0.1: Health Checks (parallel)

```bash
source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null

# Gemini health check
GEMINI_OK=$(gemini -p "Reply with exactly: AAMM_READY" --yolo -m gemini-2.5-pro -o text \
  2>/dev/null | grep -c "AAMM_READY")

# Grok health check
GROK_OK=$(bash scripts/grok-invoke.sh grok-4-0709 "Reply with exactly: AAMM_READY" \
  2>/dev/null | grep -c "AAMM_READY")

if [ "$GEMINI_OK" != "1" ]; then
  echo "FATAL: Gemini health check failed. Cannot start scan."
  echo "Verify: gemini CLI installed, authenticated, not rate-limited."
  # STOP — do not continue
fi

if [ "$GROK_OK" != "1" ]; then
  echo "FATAL: Grok health check failed. Cannot start scan."
  echo "Verify: XAI_API_KEY set, api.x.ai reachable."
  # STOP — do not continue
fi

echo "Health checks passed: Gemini ✓ Grok ✓"
```

### Step 0.2: GitHub Access Check

```bash
source ~/.zshrc 2>/dev/null || true
if [ -z "$GITHUB_TOKEN" ]; then
  echo "FATAL: GITHUB_TOKEN not set."
  # STOP
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO")

if [ "$HTTP_CODE" != "200" ]; then
  echo "FATAL: Cannot access $OWNER/$REPO (HTTP $HTTP_CODE). Check GITHUB_TOKEN scope."
  # STOP — no clone attempted
fi
```

### Step 0.3: Clone Repository

```bash
mkdir -p "$SCAN_DIR"

if [ "$SCAN_TYPE" = "learning" ]; then
  git clone --shallow-since="12 months ago" \
    "https://$GITHUB_TOKEN@github.com/$OWNER/$REPO" \
    "$SCAN_DIR/clone/"
  if [ $? -ne 0 ]; then
    echo "FATAL: Clone failed for $OWNER/$REPO. Check GITHUB_TOKEN scope and network."
    # STOP
  fi
  # B6 fix: if shallow clone produced fewer than 500 commits, go deeper for KB signal coverage
  COMMIT_COUNT=$(git -C "$SCAN_DIR/clone" rev-list --count HEAD 2>/dev/null || echo 0)
  if [ "$COMMIT_COUNT" -lt 500 ]; then
    echo "[clone] Only $COMMIT_COUNT commits — re-cloning with 24-month window for better signal coverage"
    rm -rf "$SCAN_DIR/clone"
    git clone --shallow-since="24 months ago" \
      "https://$GITHUB_TOKEN@github.com/$OWNER/$REPO" \
      "$SCAN_DIR/clone/"
    if [ $? -ne 0 ]; then
      echo "FATAL: Deep clone failed for $OWNER/$REPO."
      # STOP
    fi
  fi
else
  git clone --depth=100 \
    "https://$GITHUB_TOKEN@github.com/$OWNER/$REPO" \
    "$SCAN_DIR/clone/"
  if [ $? -ne 0 ]; then
    echo "FATAL: Clone failed for $OWNER/$REPO. Check GITHUB_TOKEN scope and network."
    # STOP
  fi
fi

# LFS handling
if [ -f "$SCAN_DIR/clone/.gitattributes" ]; then
  cd "$SCAN_DIR/clone" && git lfs install && git lfs pull 2>/dev/null || true
  cd -
fi
```

### Step 0.4: Detect Repo Type

```bash
CLONE="$SCAN_DIR/clone"

# B2 fix: bash-first detection — apply rules in order, write result to file
REPO_TYPE="mixed"  # default

# Rule 1: infrastructure
if find "$CLONE" -maxdepth 1 \( -name "*.tf" -o -name "flake.nix" -o -name "default.nix" -o -name "Chart.yaml" \) | grep -q . ; then
  REPO_TYPE="infrastructure"
# Rule 2: web-app (check package.json for server deps)
elif [ -f "$CLONE/package.json" ] && python3 -c "
import json,sys
pkg=json.load(open(sys.argv[1]))
deps={**pkg.get('dependencies',{}),**pkg.get('devDependencies',{})}
webkw=['react','next','vue','express','fastify','koa','hapi','nuxt']
sys.exit(0 if any(k in deps for k in webkw) else 1)
" "$CLONE/package.json" 2>/dev/null; then
  REPO_TYPE="web-app"
# Rule 3: cli-tool
elif [ -f "$CLONE/Cargo.toml" ] && grep -q '^\[\[bin\]\]' "$CLONE/Cargo.toml" 2>/dev/null; then
  REPO_TYPE="cli-tool"
elif [ -f "$CLONE/package.json" ] && python3 -c "
import json,sys; pkg=json.load(open(sys.argv[1])); sys.exit(0 if 'bin' in pkg else 1)
" "$CLONE/package.json" 2>/dev/null; then
  REPO_TYPE="cli-tool"
elif find "$CLONE" -maxdepth 2 -name "*.cabal" | xargs grep -l "^executable" 2>/dev/null | grep -q .; then
  REPO_TYPE="cli-tool"
# Rule 4: library
elif [ -f "$CLONE/Cargo.toml" ] && grep -q '^\[lib\]' "$CLONE/Cargo.toml" 2>/dev/null; then
  REPO_TYPE="library"
elif find "$CLONE" -maxdepth 2 -name "*.cabal" | xargs grep -l "^library" 2>/dev/null | grep -q .; then
  REPO_TYPE="library"
elif [ -f "$CLONE/package.json" ] && ! python3 -c "
import json,sys; pkg=json.load(open(sys.argv[1])); sys.exit(0 if 'bin' in pkg else 1)
" "$CLONE/package.json" 2>/dev/null; then
  REPO_TYPE="library"
fi

echo "$REPO_TYPE" > "$SCAN_DIR/repo_type.txt"
echo "Detected repo_type: $REPO_TYPE"
```

Write repo_type to `$SCAN_DIR/repo_type.txt`.

### Step 0.5: Detect Monorepo

```bash
CLONE="$SCAN_DIR/clone"
DENY_LIST="vendor deps third_party extern node_modules .git _build dist"

# Find package manifests at depth > 1, outside deny-listed dirs
# package.json, Cargo.toml, *.cabal, pyproject.toml at depth 2-4
MANIFESTS=$(find "$CLONE" -mindepth 2 -maxdepth 4 \
  \( -name "package.json" -o -name "Cargo.toml" -o -name "*.cabal" -o -name "pyproject.toml" \) \
  | grep -vE "/(vendor|deps|third_party|extern|node_modules|\.git|_build|dist)/" \
  | head -20)

MANIFEST_COUNT=$(echo "$MANIFESTS" | grep -c . 2>/dev/null || echo 0)
```

If MANIFEST_COUNT >= 2: monorepo detected. Build subprojects list:
- For each manifest: extract name, root_dir, language, last_commit_date
- Cross-check churn: `git log --since="90 days ago" -- "$subdir" | wc -l`
- Exclude subprojects with < 5 commits in 90 days (vendored/stale)
- Write `$SCAN_DIR/subprojects.json`

If `--subproject` flag provided: use that subproject.
If monorepo but no `--subproject`: select highest-churn non-deny-listed subproject.
Announce selection to operator before proceeding.

### Step 0.6: Generate Manifest

Claude (orchestrator) generates manifest.json from the clone:

```json
{
  "repo": "owner/repo",
  "scan_date": "YYYY-MM-DD",
  "repo_type": "library|web-app|cli-tool|infrastructure|mixed",
  "subproject": "path/or/null",
  "language": "haskell",
  "topics": ["cardano", "blockchain"],
  "last_commit_date": "YYYY-MM-DD",
  "contributor_count": 42,
  "open_pr_count": 7,
  "file_tree": [
    {"path": "src/Main.hs", "size_bytes": 4200, "ext": ".hs"}
  ],
  "git_stats": {
    "commit_count_per_dir": {"src/": 87, "test/": 34},
    "file_commit_counts": {"src/Main.hs": 23, "src/Lib.hs": 45}
  },
  "subprojects": [],
  "deny_listed_paths": ["vendor/", "node_modules/"]
}
```

RULE: No file contents. No signals. Raw structure and stats only.
Save to `$SCAN_DIR/manifest.json`.

Determine active SDLC sections from repo_type (see spec Section 4 pruning table).
Save to `$SCAN_DIR/active_sdlc_sections.json`.

Save state: `$SCAN_DIR/consensus-state.json`:
```json
{"phase": 0, "status": "setup_complete", "scan_type": "scoring", "partial": false, "partial_reason": null}
```
```

- [ ] **Step 2: Verify structure**

```bash
ls .claude/skills/scan-aamm-v7/
```

Expected: `SKILL.md  prompts/`

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/scan-aamm-v7/SKILL.md
git commit -m "feat: add scan-aamm-v7 SKILL.md Phase 0 (setup, health checks, manifest)"
```

---

### Task 9: SKILL.md — Phase 1 (file requests + serving)

**Files:**
- Modify: `.claude/skills/scan-aamm-v7/SKILL.md` (append Phase 1)

- [ ] **Step 1: Append Phase 1 to SKILL.md**

```markdown
## Phase 1 — Independent File Requests

### Step 1.1: Dispatch file requests (independent — no agent sees another's request)

**Claude Subagent — File Request:**
Dispatch a Claude subagent with:
- Input: manifest.json + KB ecosystem file + cross-cutting.md + anti-patterns.md + scoring-model.md + active_sdlc_sections.json
- Task: "Based on this manifest and KB, list the files you want to examine."
- Output: `$SCAN_DIR/phase-1/file-request-claude.json` (JSON array of paths)
- Context released after output

**Gemini — File Request:**
```bash
# B1 fix: fully assemble prompt — inject all dynamic content before invocation
mkdir -p "$SCAN_DIR/phase-1"

MANIFEST_JSON=$(cat "$SCAN_DIR/manifest.json")
KB_ECOSYSTEM=$(cat "models/ai-augmentation-maturity/knowledge-base/ecosystems/$ECOSYSTEM.md" 2>/dev/null || echo "No ecosystem KB found for $ECOSYSTEM")
KB_CROSSCUTTING=$(cat "models/ai-augmentation-maturity/knowledge-base/cross-cutting.md")
KB_ANTIPATTERNS=$(cat "models/ai-augmentation-maturity/knowledge-base/anti-patterns.md")
REPO_TYPE_VAL=$(cat "$SCAN_DIR/repo_type.txt")
ACTIVE_SDLC=$(cat "$SCAN_DIR/active_sdlc_sections.json")

python3 - <<PYEOF > "$SCAN_DIR/phase-1/gemini-file-request-prompt.md"
import sys

with open('.claude/skills/scan-aamm-v7/prompts/gemini-file-request.md') as f:
    prompt = f.read()

replacements = {
    '{OWNER}': '$OWNER',
    '{REPO}': '$REPO',
    '{CLONE_PATH}': '$SCAN_DIR/clone',
    '{ECOSYSTEM}': '$ECOSYSTEM',
    '{REPO_TYPE}': '$REPO_TYPE_VAL',
    '{ACTIVE_SDLC_SECTIONS}': '$ACTIVE_SDLC',
    '{MANIFEST_JSON}': '''$MANIFEST_JSON''',
    '{KB_ECOSYSTEM_CONTENT}': '''$KB_ECOSYSTEM''',
    '{KB_CROSSCUTTING_CONTENT}': '''$KB_CROSSCUTTING''',
    '{KB_ANTIPATTERNS_CONTENT}': '''$KB_ANTIPATTERNS''',
}
for k, v in replacements.items():
    prompt = prompt.replace(k, v)
print(prompt)
PYEOF

cd "$SCAN_DIR/clone"
gemini -p "$(cat $SCAN_DIR/phase-1/gemini-file-request-prompt.md)" \
  --yolo -m gemini-2.5-pro -o text \
  2>"$SCAN_DIR/phase-1/gemini-file-request-stderr.txt" \
  | tee "$SCAN_DIR/phase-1/gemini-file-request-raw.md"
cd -
```
Parse JSON array from output → `$SCAN_DIR/phase-1/file-request-gemini.json`:
```bash
python3 -c "
import sys, json, re
raw = open('$SCAN_DIR/phase-1/gemini-file-request-raw.md').read()
# Extract JSON array — find first [ ... ] block
m = re.search(r'\[.*?\]', raw, re.DOTALL)
if not m:
    print('ERROR: No JSON array in Gemini file request output', file=sys.stderr)
    sys.exit(1)
paths = json.loads(m.group(0))
json.dump(paths, open('$SCAN_DIR/phase-1/file-request-gemini.json','w'), indent=2)
print(f'Gemini requested {len(paths)} files')
"
```

**Grok — File Request (batch 1):**
```bash
# B1 fix: fully assemble Grok prompt before invocation
python3 - <<PYEOF > "$SCAN_DIR/phase-1/grok-file-request-prompt.md"
import sys

with open('.claude/skills/scan-aamm-v7/prompts/grok-file-request.md') as f:
    prompt = f.read()

replacements = {
    '{OWNER}': '$OWNER',
    '{REPO}': '$REPO',
    '{REPO_TYPE}': '$REPO_TYPE_VAL',
    '{ACTIVE_SDLC_SECTIONS}': '$ACTIVE_SDLC',
    '{BATCH_NUMBER}': '1',
    '{MANIFEST_JSON}': '''$MANIFEST_JSON''',
    '{KB_ECOSYSTEM_CONTENT}': '''$KB_ECOSYSTEM''',
    '{KB_CROSSCUTTING_CONTENT}': '''$KB_CROSSCUTTING''',
    '{KB_ANTIPATTERNS_CONTENT}': '''$KB_ANTIPATTERNS''',
}
for k, v in replacements.items():
    prompt = prompt.replace(k, v)
print(prompt)
PYEOF

source ~/.zshrc 2>/dev/null
bash scripts/grok-invoke.sh grok-4-0709 "$(cat $SCAN_DIR/phase-1/grok-file-request-prompt.md)" \
  > "$SCAN_DIR/phase-1/grok-file-request-raw.md" \
  2>"$SCAN_DIR/phase-1/grok-file-request-stderr.txt"
```
Parse JSON array → `$SCAN_DIR/phase-1/file-request-grok-batch-1.json`:
```bash
python3 -c "
import sys, json, re
raw = open('$SCAN_DIR/phase-1/grok-file-request-raw.md').read()
m = re.search(r'\[.*?\]', raw, re.DOTALL)
if not m:
    print('ERROR: No JSON array in Grok file request output', file=sys.stderr)
    sys.exit(1)
paths = json.loads(m.group(0))
json.dump(paths, open('$SCAN_DIR/phase-1/file-request-grok-batch-1.json','w'), indent=2)
print(f'Grok requested {len(paths)} files (batch 1)')
"
```

RULE: Claude, Gemini, Grok file request outputs are NOT shown to each other.

### Step 1.2: Serve files from clone

Orchestrator reads each agent's file request list and serves files from `$SCAN_DIR/clone/`:

```bash
# For each agent, for each requested path:
# Read file from clone, build served-files-{agent}.json
# If path does not exist: include {"path": "...", "error": "not found"}
# Never modify, filter, or add files
```

Audit log: `$SCAN_DIR/audit/file-requests.json`:
```json
{
  "claude": ["src/Main.hs", ".github/workflows/ci.yml"],
  "gemini": ["src/Main.hs", "CLAUDE.md", ".github/workflows/"],
  "grok_batch_1": [".github/workflows/ci.yml", "docs/architecture.md"]
}
```

### Step 1.3: Handle Grok batching

After receiving Grok's initial analysis (Phase 2), check for `need_more_files` field.
If present and non-empty, AND batch count < 5:
- Serve next batch of up to 50 files
- Invoke Grok again with batch N + prior batch findings
- Repeat until `need_more_files` is empty or batch 5 reached

If batch 5 exhausted and Grok still needs files:
- Set `$SCAN_DIR/grok-partial.txt` with list of unserved files
- Report will include ⚠ WARNING banner
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/scan-aamm-v7/SKILL.md
git commit -m "feat: add SKILL.md Phase 1 (independent file requests + serving)"
```

---

### Task 10: SKILL.md — Phase 2 (independent analysis)

**Files:**
- Modify: `.claude/skills/scan-aamm-v7/SKILL.md` (append Phase 2)

- [ ] **Step 1: Append Phase 2**

```markdown
## Phase 2 — Independent Analysis

Each agent receives its served files and produces an opportunity map independently.
No agent sees another's output at this stage.

### Step 2.1: Claude Subagent Analysis

Dispatch Claude subagent with:
- Input: served-files-claude.json + KB + scoring-model.md + active_sdlc_sections.json
- Task: Follow scoring-model.md Section 2 to produce opportunity map
- Output: `$SCAN_DIR/phase-1/opportunity-map-claude.json`
- Context released after output

### Step 2.2: Gemini Analysis

Build prompt from `prompts/gemini-phase1-analysis.md`:
- Inject served file contents
- Inject KB content
- Inject repo_type + active_sdlc_sections

```bash
cd "$SCAN_DIR/clone"
gemini -p "$(cat $SCAN_DIR/phase-1/gemini-analysis-prompt.md)" \
  --yolo -m gemini-2.5-pro -o text \
  2>"$SCAN_DIR/phase-1/gemini-analysis-stderr.txt" \
  | tee "$SCAN_DIR/phase-1/gemini-analysis-raw.md"
cd -
```

Handle Gemini unavailability mid-scan:
```
If gemini call fails with 429/timeout:
  → Wait 120s, retry ×5
  → If still failing after 5 retries:
      Set $SCAN_DIR/gemini-partial.txt = "Phase 2 — analysis"
      Update consensus-state.json: {"partial": true, "partial_reason": "Gemini unavailable after 5 retries in Phase 2"}
      Continue with Claude + Grok only
```

Parse + validate JSON from output → `$SCAN_DIR/phase-1/opportunity-map-gemini.json`:
```bash
# B3 fix: validate JSON — retry with format-correction prompt if parse fails
python3 -c "
import json, sys
raw = open('$SCAN_DIR/phase-1/gemini-analysis-raw.md').read()
# Strip markdown code fences if present
import re
m = re.search(r'\{.*\}', raw, re.DOTALL)
if not m:
    sys.exit(1)
data = json.loads(m.group(0))
json.dump(data, open('$SCAN_DIR/phase-1/opportunity-map-gemini.json','w'), indent=2)
" 2>/dev/null || {
  echo "[gemini] Phase 2 output is not valid JSON — retrying with format reminder"
  FORMAT_REMINDER="Your previous response was not valid JSON. Reply with ONLY a JSON object matching: {\"opportunities\": [...]}. No prose, no markdown fences."
  cd "$SCAN_DIR/clone"
  gemini -p "$FORMAT_REMINDER" \
    --yolo -m gemini-2.5-pro -o text \
    2>>"$SCAN_DIR/phase-1/gemini-analysis-stderr.txt" \
    | tee "$SCAN_DIR/phase-1/gemini-analysis-retry-raw.md"
  cd -
  python3 -c "
import json, sys, re
raw = open('$SCAN_DIR/phase-1/gemini-analysis-retry-raw.md').read()
m = re.search(r'\{.*\}', raw, re.DOTALL)
if not m:
    print('ERROR: Gemini analysis still not valid JSON after retry — triggering PARTIAL', file=sys.stderr)
    open('$SCAN_DIR/gemini-partial.txt','w').write('Phase 2 — analysis: JSON parse failed after retry')
    sys.exit(0)  # continue with PARTIAL, not STOP
data = json.loads(m.group(0))
json.dump(data, open('$SCAN_DIR/phase-1/opportunity-map-gemini.json','w'), indent=2)
" 2>&1
}

### Step 2.3: Grok Analysis (batched)

Build prompt from `prompts/grok-phase1-analysis.md` with batch 1 files:

```bash
source ~/.zshrc 2>/dev/null
bash scripts/grok-invoke.sh grok-4-0709 \
  "$(cat $SCAN_DIR/phase-1/grok-analysis-prompt-batch-1.md)" \
  > "$SCAN_DIR/phase-1/grok-analysis-batch-1-raw.md" \
  2>"$SCAN_DIR/phase-1/grok-analysis-batch-1-stderr.txt"
```

Handle Grok unavailability mid-scan (same as Gemini above — symmetric).

Check `need_more_files` in Grok's output. If non-empty and batch < 5:
- Build next batch prompt with prior batch findings injected
- Invoke Grok again
- Merge findings across batches into `$SCAN_DIR/phase-1/opportunity-map-grok.json`

If batch 5 exhausted: set `$SCAN_DIR/grok-partial.txt`, update consensus-state.json.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/scan-aamm-v7/SKILL.md
git commit -m "feat: add SKILL.md Phase 2 (independent analysis + PARTIAL handling)"
```

---

### Task 11: SKILL.md — Phase 3 (consensus: opportunity map)

**Files:**
- Modify: `.claude/skills/scan-aamm-v7/SKILL.md` (append Phase 3)

- [ ] **Step 1: Append Phase 3**

```markdown
## Phase 3 — Consensus: Opportunity Map

### Step 3.1: Intersection-first merge

Orchestrator compares all three opportunity maps:

```
Match criteria:
  - Same kb_pattern (non-null) → proposed intersection match
  - Same target module/dir + same use-case type (for kb_pattern: null) → proposed match

For each proposed match: build confirmation prompt showing both agents' findings.
Ask all 3 agents: "Assess as equivalent / partial_overlap / distinct — evidence required."

Items where all 3 say 'equivalent' → auto-approved, consensus_round: 0
Items where 2+ say 'partial_overlap' or agents disagree → enter consensus loop
Items unique to 1 agent → enter consensus loop
```

Save:
- `$SCAN_DIR/phase-1/intersection.json` (auto-approved)
- `$SCAN_DIR/phase-1/unique-claude.json`
- `$SCAN_DIR/phase-1/unique-gemini.json`
- `$SCAN_DIR/phase-1/unique-grok.json`

### Step 3.2: Consensus loop (max 5 rounds)

For each round N, for each pending item:

**Claude scores pending items** — B4 fix: dispatch Claude subagent with assembled prompt:

Build `$SCAN_DIR/phase-1/claude-prompt-round-$N.md`:
- Template: `prompts/gemini-consensus-round.md` (same structure, adapted for Claude)
- Inject: `{FINDINGS_JSON}` = pending items JSON, `{ROUND}` = N, `{PREVIOUS_ROUNDS_OR_NONE}` = prior round summaries

Dispatch Claude subagent with this prompt.
Output: `$SCAN_DIR/phase-1/claude-round-$N-raw.md`

Parse + validate JSON → `$SCAN_DIR/phase-1/round-$N-claude-scores.json`:
```bash
python3 -c "
import json, sys, re
raw = open('$SCAN_DIR/phase-1/claude-round-$N-raw.md').read()
m = re.search(r'\{.*\}', raw, re.DOTALL)
if not m: sys.exit(1)
data = json.loads(m.group(0))
json.dump(data, open('$SCAN_DIR/phase-1/round-$N-claude-scores.json','w'), indent=2)
" || echo "WARNING: Claude round $N output unparseable — using empty scores"
```

**Gemini scores pending items** via `prompts/gemini-consensus-round.md`:
```bash
cd "$SCAN_DIR/clone"
gemini -p "$(cat $SCAN_DIR/phase-1/prompt-round-$N.md)" \
  --yolo -m gemini-2.5-pro -o text \
  2>"$SCAN_DIR/phase-1/gemini-round-$N-stderr.txt" \
  | tee "$SCAN_DIR/phase-1/gemini-round-$N-raw.md"
cd -
```

**Grok scores pending items** via `prompts/grok-consensus-round.md`:
```bash
source ~/.zshrc 2>/dev/null
bash scripts/grok-invoke.sh grok-4-0709 \
  "$(cat $SCAN_DIR/phase-1/grok-prompt-round-$N.md)" \
  > "$SCAN_DIR/phase-1/grok-round-$N-raw.md" \
  2>"$SCAN_DIR/phase-1/grok-round-$N-stderr.txt"
```

**Check consensus thresholds:**
```
All 3 ≥9/10                     → approved, confidence: HIGH
2 of 3 ≥9 + third ≥7           → approved, confidence: MEDIUM, coe_review_required: true
Any agent <7, or no progress    → stays in loop
After round 5 with no consensus → consensus: false, all positions preserved
```

Save per-round: `$SCAN_DIR/phase-1/round-$N-scores.json`

**MEDIUM cap:** After loop completes, if MEDIUM count > 10:
- Sort MEDIUM items by ROI (value/effort)
- Top 10 → remain MEDIUM
- Remaining → downgrade to LOW with one-line Grok concern
- Log to `$SCAN_DIR/phase-1/medium-overflow.json`

### Step 3.3: Component Assessment

For each approved opportunity (HIGH + MEDIUM), independently assess:
- Adoption State (Active/Partial/Absent)
- Readiness per KB criteria
- Risk Surface

Each agent uses its component assessment prompt:
- Claude subagent: via Agent tool with `prompts/...`
- Gemini: via `prompts/gemini-component-assessment.md`
- Grok: via `prompts/grok-component-assessment.md`

Same consensus loop (max 5 rounds, same thresholds).

Save final: `$SCAN_DIR/phase-1/consensus.json` (all approved + consensus:false items)
Update consensus-state.json: `{"phase": 1, "status": "complete"}`
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/scan-aamm-v7/SKILL.md
git commit -m "feat: add SKILL.md Phase 3 (consensus loop, tiered thresholds, MEDIUM cap)"
```

---

### Task 12: SKILL.md — Phase 4+5 (recommendations + report)

**Files:**
- Modify: `.claude/skills/scan-aamm-v7/SKILL.md` (append Phases 4-6)

- [ ] **Step 1: Append Phases 4-6**

```markdown
## Phase 4 — Consensus: Recommendations

### Step 4.1: Independent recommendation generation

**Claude subagent:** generate recommendations from approved map + component assessment.
**Gemini:** via `prompts/gemini-phase2-recommendations.md`.
**Grok:** via `prompts/grok-phase2-recommendations.md`.

RULE: No agent receives another's recommendations before producing its own.

### Step 4.2: Intersection-first + consensus loop

Same mechanism as Phase 3. Match criteria: same `opportunity_id` + same `type`.

### Step 4.3: ROI ordering consensus

All 3 independently propose ROI ranking. Where all agree → final. Where rankings diverge → consensus loop (max 5 rounds). Each agent argues with ROI evidence (impact × 1/effort × adoption gap).

Save: `$SCAN_DIR/phase-2/consensus.json`
Update consensus-state.json: `{"phase": 2, "status": "complete"}`

**Freeze assessment.json** at this point. File is immutable after freezing.

## Phase 5 — Report Generation

Dispatch Claude subagent (fresh context, reads assessment.json only):

**Input:** `$SCAN_DIR/phase-2/consensus.json` (frozen) + previous scan if exists.

**Delta computation (if previous scan exists):**
```bash
PREV=$(ls -d scans/ai-augmentation/results/*/$OWNER--$REPO 2>/dev/null | sort -r | head -1)
```
Compare: opportunity IDs (new/discontinued/persisted), readiness changes, recommendation status.

**Write report.md** following scoring-model.md Section 6:
1. Executive Summary — includes:
   ```
   **Agents:** Claude + Gemini + Grok (tri-agent-v1)
   **Consensus:** {N} HIGH, {M} MEDIUM (CoE review required), {K} unresolved
   ```
   If PARTIAL: add ⚠ WARNING banner prominently before summary.
2. Opportunity Map (ROI ordered)
3. Risk Surface
4. Recommendations
5. Adoption State
6. Readiness per Use Case
7. Evolution (if previous scan)
8. Evidence Log
9. MEDIUM Overflow Summary (if any)

**Write detailed-log.md** with full audit trail:
- File requests per agent (from audit/file-requests.json)
- All consensus rounds (from phase-1/ and phase-2/ round files)
- Grok batch log
- Any PARTIAL events

**Write assessment.json** following `schema/assessment-v7.schema.json`.

## Phase 6 — Save + KB Proposals

```bash
DATE=$(date +%Y-%m-%d)
RESULT_DIR="scans/ai-augmentation/results/$DATE/$OWNER--$REPO"
mkdir -p "$RESULT_DIR"
cp "$SCAN_DIR/phase-2/report.md" "$RESULT_DIR/report.md"
cp "$SCAN_DIR/phase-2/assessment.json" "$RESULT_DIR/assessment.json"
cp "$SCAN_DIR/phase-2/detailed-log.md" "$RESULT_DIR/detailed-log.md"
```

If new KB patterns discovered during scan:
- Write proposed entries to `scans/ai-augmentation/results/$DATE/kb-updates.md`
- CoE reviews before merging to `knowledge-base/`

## Failure Handling Reference

| Failure | Detection | Action |
|---|---|---|
| Gemini/Grok unavailable at start | Health check fails | STOP. Announce. Ask operator. |
| Gemini rate-limited mid-scan | 429/timeout ×5 | Continue without Gemini, flag PARTIAL |
| Grok rate-limited mid-scan | 429/timeout ×5 | Continue without Grok, flag PARTIAL |
| Agent output unparseable | JSON parse fails | Retry once with format reminder. If fails → STOP. |
| Clone fails | git non-zero | STOP. Check token scope. |
| Grok context limit | 5 batches exhausted | Continue with what was analyzed, flag PARTIAL |
| 0 approved items | Consensus → empty | Valid outcome. Report data + rejection log. |

## Important

- **AAMM is read-only on target repos** — never create PRs, commits, issues on scanned repos
- **Never print $GITHUB_TOKEN or $XAI_API_KEY**
- **Tri-agent is standard** — health check failure at start = STOP; mid-scan failure = PARTIAL
- **No confirmations during scans** — run fully autonomously end-to-end
- **Scan-from-zero** — never read previous results before Phase 5 is frozen
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/scan-aamm-v7/SKILL.md
git commit -m "feat: add SKILL.md Phases 4-6 (recommendations, report, save)"
```

---

## Phase 4 — Learning Scan + Reference Repos

### Task 13: Learning scan flow in SKILL.md

**Files:**
- Modify: `.claude/skills/scan-aamm-v7/SKILL.md` (append learning scan section)

- [ ] **Step 1: Append learning scan flow**

```markdown
## Learning Scan Flow (`--mode=learning`)

Phase 0: identical to scoring scan (health checks + clone + manifest).
Phase 1: identical to scoring scan (file requests + serving).
         No file quota — agents request everything they consider relevant.

### Learning Phase 2 — Independent Deep Scan

Each agent receives its files and scans all active SDLC sections:
- Match KB patterns
- Log ALL absence signals explicitly with quantification
- Look for patterns not in KB (novel patterns)
- Log confidence (HIGH/MEDIUM/LOW) per signal

Claude subagent → `$SCAN_DIR/learning/findings-claude.json`
Gemini → `$SCAN_DIR/learning/findings-gemini.json`
Grok → `$SCAN_DIR/learning/findings-grok.json`

### Learning Phase 3 — Union with Evidence Filter

Orchestrator builds union of all findings:

```
For each finding in union:
  found_by 3 agents + each with evidence  → HIGH
  found_by 2 agents + each with evidence  → MEDIUM
  found_by 1 agent (Claude/Gemini) + file:line or commit SHA → LOW
  found_by 1 agent (Grok) + evidence      → LOW-GROK
  Any agent + absence signal (quantified) → LOW-ABSENCE
  No evidence from any agent              → dropped, logged
```

### Learning Phase 4 — Hallucination Filter

Each agent reviews proposals found by others.
**ONLY valid response:** "I found counter-evidence that disproves this: {file:line}"
**No scoring. No disagreement logging.**
If no counter-evidence → proposal stands.

### Learning Output

Write `$SCAN_DIR/learning/kb-proposals.json`:
```json
{
  "proposals": [
    {
      "pattern_type": "opportunity|readiness_criterion|anti_pattern",
      "confidence": "HIGH|MEDIUM|LOW|LOW-GROK|LOW-ABSENCE",
      "found_by": ["grok"],
      "description": "string",
      "evidence": "string — file:line, commit SHA, or quantified absence",
      "ecosystem": "haskell",
      "proposed_addition_to": "knowledge-base/ecosystems/haskell.md"
    }
  ]
}
```

Save to `scans/ai-augmentation/results/$DATE/$OWNER--$REPO/kb-proposals.json`
CoE reviews all proposals before merging to knowledge-base/.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/scan-aamm-v7/SKILL.md
git commit -m "feat: add learning scan flow to SKILL.md (union model, hallucination filter)"
```

---

### Task 14: select-reference-repos skill

**Files:**
- Create: `.claude/skills/select-reference-repos/SKILL.md`

- [ ] **Step 1: Write skill**

```markdown
---
name: select-reference-repos
description: Tri-agent consensus selection of external reference repos for AAMM KB enrichment. Each agent independently researches best-practice repos per ecosystem, then reaches consensus (all 3 ≥9/10 HIGH tier only).
---

# Select Reference Repos

## Purpose

Populate `models/config.yaml reference_repos` section with external repos that represent
AI readiness best practices per ecosystem. These become the benchmark for KB enrichment.

## Ecosystems to cover

haskell | rust | typescript | python

## Phase 0: Health Checks

Same as scan-aamm-v7 (Gemini + Grok health checks mandatory).

## Phase 1: Independent Research

Each agent independently researches 3-5 repos per ecosystem.

**Evaluation criteria (apply independently):**
- AI tooling config present (AGENTS.md, CLAUDE.md, .cursorrules, .mcp.json, etc.)
- AI attribution in recent commit history (Co-authored-by AI tools)
- CI/CD with AI-assisted steps
- Complexity comparable to CBU internal repos (not toy projects)
- Active maintenance (commits in last 6 months)
- Recognized for engineering practices (not just popularity)
- SDLC coverage: AI adoption signals across planning, dev, review, delivery

**Claude subagent** → `$SCAN_DIR/reference-repos-claude.json`
**Gemini** → research via web + GitHub API → `$SCAN_DIR/reference-repos-gemini.json`
**Grok** → research → `$SCAN_DIR/reference-repos-grok.json`

Each output:
```json
{"proposals": [{"repo": "owner/name", "ecosystem": "typescript", "rationale": "...", "signals": [...]}]}
```

## Phase 2: Intersection + Consensus

Same mechanism as scoring scan. HIGH tier only (all 3 ≥9/10).
MEDIUM is not sufficient for reference repo selection.

## Phase 3: Output

Approved repos written to `models/config.yaml` under `reference_repos:`.
Require operator approval before committing to main.
```

- [ ] **Step 2: Commit**

```bash
git add .claude/skills/select-reference-repos/SKILL.md
git commit -m "feat: add select-reference-repos skill for tri-agent KB enrichment"
```

---

## Phase 5 — scoring-model.md Rewrite

### Task 15: Update scoring-model.md for v7

**Files:**
- Modify: `models/ai-augmentation-maturity/scoring-model.md`

- [ ] **Step 1: Update header and references**

Replace the opening block of `scoring-model.md`:

```markdown
# AAMM v7 — Scoring Model

> **This file is the operational manual for the AAMM v7 scanner agent.**
> Read this file at scan time. Follow it step by step. Do not improvise.
>
> For design rationale: see [spec.md](spec.md).
> For KB patterns and criteria: see [knowledge-base/](knowledge-base/).
> For scan skill: see [scan-aamm-v7 skill](../../.claude/skills/scan-aamm-v7/SKILL.md).
>
> **Tri-agent consensus:** Scoring scans use three independent agents (Claude + Gemini + Grok).
> Each agent independently requests files from a local clone, analyzes independently,
> then reaches tiered consensus through evidence-based debate.
> See scan skill for orchestration details.
```

- [ ] **Step 2: Update Section 1 (Data Collection)**

Replace "Collect all of the following before any assessment begins" section.
Remove: all GitHub API curl commands, hardcoded file lists.
Replace with:

```markdown
## 1. Data Collection

You are a Claude subagent. The orchestrator has already:
- Cloned the repo to `$SCAN_DIR/clone/`
- Generated `manifest.json` (structure + stats, no content)
- Served your requested files to `served-files-claude.json`

Your task: analyze the served files against KB patterns.
If you need a file not in your served set: request it from the manifest and ask the orchestrator.

Repo type: `{REPO_TYPE}`. Active SDLC sections: `{ACTIVE_SDLC_SECTIONS}`.
```

- [ ] **Step 3: Update Section 2 (Opportunity Map)**

Add self-check rule:
```markdown
Self-check per opportunity: "Would this appear identically on any other {ECOSYSTEM} repo with similar characteristics?" If yes → make it specific to this repo's actual evidence, or drop it.
```

- [ ] **Step 4: Update consensus references**

Replace all references to "dual-agent" or "adversarial subagent" with tri-agent language.
Update output schema references to `assessment-v7.schema.json`.

- [ ] **Step 5: Commit**

```bash
git add models/ai-augmentation-maturity/scoring-model.md
git commit -m "feat: update scoring-model.md for v7 tri-agent (local clone, manifest-driven)"
```

---

### Task 16: Update changelog.md

**Files:**
- Modify: `models/ai-augmentation-maturity/changelog.md`

- [ ] **Step 1: Prepend v7 entry**

```markdown
## v7.0 — 2026-04-03

**Tri-agent consensus with local clone + request/serve protocol**

- Replace dual-agent (Claude + Gemini) with tri-agent (Claude + Gemini + Grok)
- Replace GitHub API pre-collection with local clone + agent-driven file discovery
- Each agent independently decides what files to examine from a neutral manifest
- Tiered consensus: HIGH (all 3 ≥9/10), MEDIUM (2/3 ≥9 + third ≥7), consensus:false
- MEDIUM cap: 10 items per scan, overflow → LOW with one-line summary
- Learning scan union model (vs intersection): maximize recall, CoE filters
- Dynamic SDLC pruning by repo_type (library/web-app/cli-tool/infrastructure)
- Monorepo detection with deny-list + subproject targeting
- Symmetric PARTIAL handling: either agent unavailable after 5 retries → continue PARTIAL

**Supersedes:** v6.1 (dual-agent consensus, 2026-04-02)
**ADR:** ADR-020
**Spec:** docs/superpowers/specs/2026-04-03-aamm-v7-tri-agent-design.md
```

- [ ] **Step 2: Commit**

```bash
git add models/ai-augmentation-maturity/changelog.md
git commit -m "docs: add v7 changelog entry for tri-agent architecture"
```

---

## Phase 6 — Final Squash + Verification

### Task 17: Smoke test Phase 0

**Test:** Run Phase 0 of the new skill on a single known repo.

- [ ] **Step 1: Run health checks**

```bash
source ~/.zshrc 2>/dev/null
cd /home/devuser/repos/cbu-coe/cbu-coe-toolkit

GEMINI_OK=$(gemini -p "Reply with exactly: AAMM_READY" --yolo -m gemini-2.5-pro -o text \
  2>/dev/null | grep -c "AAMM_READY")
GROK_OK=$(bash scripts/grok-invoke.sh grok-4-0709 "Reply with exactly: AAMM_READY" \
  2>/dev/null | grep -c "AAMM_READY")

echo "Gemini: $GEMINI_OK (expected 1)"
echo "Grok:   $GROK_OK (expected 1)"
```

Expected: both `1`

- [ ] **Step 2: Test GitHub access check**

```bash
source ~/.zshrc 2>/dev/null
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/cardano-scaling/hydra")
echo "HTTP: $HTTP_CODE (expected 200)"
```

Expected: `200`

- [ ] **Step 3: Test clone on small repo**

```bash
OWNER=cardano-scaling
REPO=hydra
SCAN_DIR=/tmp/aamm-v7-$OWNER-$REPO
rm -rf "$SCAN_DIR"
mkdir -p "$SCAN_DIR"

git clone --depth=100 \
  "https://$GITHUB_TOKEN@github.com/$OWNER/$REPO" \
  "$SCAN_DIR/clone/" 2>&1 | tail -5
CLONE_EXIT=$?
# B5 fix: check exit code immediately, before ls
if [ $CLONE_EXIT -ne 0 ]; then
  echo "FAIL: Clone exited with $CLONE_EXIT — check token scope and repo access"
  exit 1
fi

ls "$SCAN_DIR/clone/" | head -10
echo "Clone exit: $CLONE_EXIT (expected 0)"
```

Expected: exit 0, files visible

- [ ] **Step 4: Test grok-invoke.sh retry behavior**

```bash
source ~/.zshrc 2>/dev/null
bash scripts/grok-invoke.sh grok-4-0709 "Reply: HEALTH_OK" 2>/dev/null
echo "Exit: $?"
```

Expected: output contains `HEALTH_OK`, exit 0

- [ ] **Step 5: Verify SKILL.md is parseable**

```bash
wc -l .claude/skills/scan-aamm-v7/SKILL.md
head -5 .claude/skills/scan-aamm-v7/SKILL.md
```

Expected: frontmatter present, no truncation

### Task 18: Squash and final commit

- [ ] **Step 1: Check all files are in place**

```bash
ls .claude/skills/scan-aamm-v7/SKILL.md
ls .claude/skills/scan-aamm-v7/prompts/
ls .claude/skills/select-reference-repos/SKILL.md
ls schema/assessment-v7.schema.json
ls docs/decisions/020-aamm-v7-tri-agent.md
grep -c "reference_repos" models/config.yaml
```

All expected to return without error.

- [ ] **Step 2: Review diff before squash**

```bash
git log --oneline feat/aamm-v7-tri-agent
git diff main..feat/aamm-v7-tri-agent --stat
```

Review: no secrets in diff, no unintended files.

- [ ] **Step 3: Squash into single clean commit**

```bash
git rebase -i $(git merge-base main feat/aamm-v7-tri-agent)
# In editor: change all 'pick' to 'squash' except the first
# Write final commit message:
```

Final commit message:
```
feat: AAMM v7 tri-agent architecture

Replaces dual-agent (Claude+Gemini) v6.1 with tri-agent (Claude+Gemini+Grok).

Key changes:
- Local clone + request/serve protocol: each agent independently decides
  what files to examine from a neutral manifest (zero pre-selection bias)
- Tiered consensus: HIGH (all 3 ≥9), MEDIUM (2/3 ≥9+third ≥7), consensus:false
- MEDIUM cap: 10 items/scan, overflow downgraded to LOW with summary
- Dynamic SDLC pruning by repo_type (library/web-app/cli-tool/infrastructure)
- Monorepo detection with deny-list + subproject targeting
- Learning scan union model: maximize recall, CoE filters
- Symmetric PARTIAL handling: either agent unavailable → continue with warning
- Claude subagent isolation: orchestrator stays lean, context released per phase
- Structured JSON consensus: ~70% token reduction vs prose

New files: scan-aamm-v7 skill + 10 prompts, select-reference-repos skill,
assessment-v7 schema, ADR-020.
Modified: GROK.md, CLAUDE.md, config.yaml, scoring-model.md, changelog.md.

Spec: docs/superpowers/specs/2026-04-03-aamm-v7-tri-agent-design.md
ADR: docs/decisions/020-aamm-v7-tri-agent.md
```

- [ ] **Step 4: Open PR**

```bash
git push -u origin feat/aamm-v7-tri-agent
gh pr create \
  --title "feat: AAMM v7 tri-agent (Claude+Gemini+Grok, local clone, tiered consensus)" \
  --body "Implements spec from docs/superpowers/specs/2026-04-03-aamm-v7-tri-agent-design.md. Spec approved: Grok APPROVED, Gemini CONDITIONAL APPROVAL (fixes applied). ADR-020."
```

---

## Appendix: Consensus State Machine

```
consensus-state.json tracks:
{
  "phase": 0-5,
  "status": "setup_complete|phase1_complete|phase2_complete|report_complete",
  "scan_type": "scoring|learning",
  "partial": false,
  "partial_reason": null | "Gemini unavailable after 5 retries in Phase N" | "Grok context limit",
  "agents_active": ["claude", "gemini", "grok"]
}

If partial=true → report.md and detailed-log.md both contain ⚠ WARNING banner.
```

## Appendix: Directory Structure

```
/tmp/aamm-v7-$OWNER-$REPO/
  clone/                        ← git clone, read-only for all agents
  manifest.json                 ← neutral manifest
  repo_type.txt                 ← library|web-app|cli-tool|infrastructure|mixed
  subprojects.json              ← monorepo subproject list (empty if not monorepo)
  active_sdlc_sections.json     ← sections active for this repo_type
  consensus-state.json          ← current phase + partial status
  audit/
    file-requests.json          ← what each agent requested
  phase-1/
    file-request-claude.json
    file-request-gemini.json
    file-request-grok-batch-N.json
    served-files-claude.json
    served-files-gemini.json
    served-files-grok-batch-N.json
    opportunity-map-claude.json
    opportunity-map-gemini.json
    opportunity-map-grok.json
    intersection.json
    unique-claude.json / unique-gemini.json / unique-grok.json
    round-N-{claude,gemini,grok}-scores.json
    consensus.json              ← frozen after Step 3
    component-consensus.json    ← frozen after Step 3
  phase-2/
    recommendations-{claude,gemini,grok}.json
    intersection.json
    round-N-*.json
    consensus.json              ← frozen after Step 4
    roi-consensus.json
    report.md / assessment.json / detailed-log.md
  learning/                     ← only if --mode=learning
    findings-{claude,gemini,grok}.json
    kb-proposals.json
```
