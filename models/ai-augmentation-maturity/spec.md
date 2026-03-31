# AAMM v6 — Specification

> **Status:** Draft — adversarial review pending
> **Date:** 2026-03-30 (revised from 2026-03-28 draft)
> **Author:** Dorin Solomon (CoE lead) + Claude (AI agent)
> **ADR:** ADR-019 (supersedes ADR-018, which supersedes ADR-017)
> **Context:** v5 answered the wrong question — it measured general engineering maturity and called it AI readiness. v6 is built around a use-case spectrum: different AI applications carry different risk/value profiles, and a high-assurance repo can have appropriate AI adoption across much of the SDLC.

---

## 1. What AAMM Is

**AAMM is an AI-powered consultation per repo.** It tells teams where AI can add the most value for their specific codebase, where they currently are on that journey, and what to do next with the highest ROI.

AAMM produces **leveled indicators** (not numeric scores) and **actionable recommendations grounded in evidence**. The quality of findings and recommendations is the primary measure of AAMM's value — everything else serves that.

### Four Problems AAMM Solves

| # | Problem | How AAMM Solves It |
|---|---------|-------------------|
| 1 | **Awareness gap** — teams don't know what AI can do across the full SDLC; most think only about code generation | Agent derives specific high-value AI opportunities from the repo itself and cites evidence; KB includes outcomes from other repos |
| 2 | **Where to start** — teams don't know what to do first for their specific context | Opportunities ranked by ROI (value × effort); top recommendations with "done when X" outcomes — #1 is the highest-ROI action |
| 3 | **No feedback loop** — learnings stay with individual teams, no cross-pollination | KB entries include `seen_in` attribution: which repo used this pattern and what the outcome was; patterns flow actively, not just as abstractions |
| 4 | **Risk without guardrails** — AI on high-assurance code without boundaries is dangerous | Risk Surface maps AI exposure to concrete code paths; severity calibrated to what AI has actually touched, not theoretical maximum |

### Audiences

| Who | What they see | Time investment |
|-----|-------------|-----------------|
| **Team / tech lead** | Executive summary: opportunities + top recommendations + risk flags (first 15 lines of report) | 5 minutes |
| **CoE lead** | Full report + portfolio view across repos | 15 minutes |
| **Leadership / stakeholders** | Quadrant position + delta vs previous scan + trajectory (portfolio-summary.md) | 2 minutes |

### What AAMM Does NOT Do

- Does not measure code quality (that's CMM)
- Does not measure business impact (that's Engineering Vitals)
- Does not judge teams — informs and recommends
- Does not produce numeric scores — produces leveled indicators with evidence and confidence
- Does not assess team competence — recommends learning opportunities
- Does not treat all AI adoption as code generation risk — recognises the use-case spectrum
- Does not write to scanned repositories — **AAMM is strictly read-only**. No PRs, commits, issues, comments, or any other writes to target repos. All output is written to `cbu-coe-toolkit` only.

### The Use-Case Spectrum

AI adoption is not binary (AI present / absent) and is not synonymous with code generation. Risk and value vary by use case:

| Use case | Risk | Value in high-assurance repos |
|----------|------|-------------------------------|
| Documentation (inline, README, ADRs) | Very low | High — domain docs are expensive and AI can draft them accurately |
| PR descriptions, commit messages | Very low | High — saves time, improves consistency |
| Debugging complex scenarios | Low | Very high — expert-level reasoning on state and call traces |
| Thread / concurrency analysis | Low | Very high — hard problems where AI augments human review |
| Corner case / edge case discovery | Low | Very high — directly accelerates property-based testing |
| Code review / understanding unfamiliar code | Low | High — accelerates onboarding and cross-module work |
| Test generation (non-critical modules) | Medium | Medium |
| Code generation (non-critical paths) | Medium | Medium |
| Code generation (security / consensus / financial) | High | Requires explicit guardrails and mandatory human review |
| Architecture decisions | Medium | Requires human confirmation — AI assists, does not decide |

A well-functioning high-assurance repo should have active AI use in the low-risk rows regardless of the risk profile of its core domain. AAMM surfaces this spectrum explicitly.

---

## 2. Scan Types

AAMM has two distinct scan types. They share the same agent and KB but serve different purposes.

### Learning Scan

**Purpose:** Populate the Knowledge Base from well-understood repos before scoring scans begin.

**When to use:**
- Before the first scoring scan on a new ecosystem
- On reference repos (external, high-quality repos similar to the portfolio in complexity and domain)
- On portfolio repos when a new pattern type is being investigated

**Output:** A single file `kb-proposals.md` saved to `scans/ai-augmentation/results/YYYY-MM-DD/OWNER--REPO/kb-proposals.md`. Format is identical to KB entry format (YAML blocks in markdown) so CoE can merge directly into knowledge-base/ without transformation. Each proposal includes `evidence_from_scan` — the specific files/commits that triggered the proposal.

Distinct from scoring scan output (`kb-updates.md`). Naming makes scan type clear from filename alone.

CoE reviews and merges approved proposals before they become canonical KB entries.

**Reference repos per ecosystem (starting set):**

| Ecosystem | Internal | External reference |
|-----------|----------|-------------------|
| Haskell | cardano-ledger, cardano-node, plutus | Well-structured Haskell projects with similar property-based testing and formal spec patterns |
| TypeScript | lace, lace-platform | High-assurance TS projects with strict typing and strong test coverage |
| Rust | mithril, hydra | Rust projects with high safety requirements and strong test profiles |

**Cold-start rule:** If an ecosystem has no KB coverage at scan time, the agent uses cross-cutting patterns only and marks the scan explicitly: "Limited KB coverage for this ecosystem — learning scan recommended before scoring." No improvisation.

### Scoring Scan

**Purpose:** Full assessment producing actionable report for a team.

**Requires:** KB populated for the target ecosystem (via learning scans or accumulated scoring scans).

**Output:** report.md + assessment.json + detailed-log.md + KB update proposals.

**Fully autonomous.** No mid-scan gates, no confirmations, no iterative loops. The agent produces the complete report end-to-end. CoE reviews the output post-scan.

All subsequent sections describe the scoring scan unless noted otherwise.

---

## 3. Architecture

### Components

```
┌─────────────────────────────────────────────────────────────────┐
│                          AAMM v6                                │
│                                                                 │
│  ┌──────────┐   reads    ┌─────────────────────────────────┐   │
│  │Knowledge │◀──────────▶│  AI Agent                       │   │
│  │Base      │  +updates  │                                 │   │
│  └──────────┘            │  1. Data Collection             │   │
│                          │  2. Opportunity Map             │   │
│                          └──────────────┬──────────────────┘   │
│                                         │                       │
│                          ┌──────────────▼──────────────────┐   │
│                          │  Adversarial Agent (Stage A)    │   │
│                          │  filters platitudes from map    │   │
│                          └──────────────┬──────────────────┘   │
│                                         │                       │
│                          ┌──────────────▼──────────────────┐   │
│                          │  AI Agent (continued)           │   │
│                          │  3. Adoption State              │   │
│                          │  4. Readiness (KB criteria)     │   │
│                          │  5. Risk Surface                │   │
│                          │  6. Recommendations             │   │
│                          └──────────────┬──────────────────┘   │
│                                         │                       │
│                          ┌──────────────▼──────────────────┐   │
│                          │  Adversarial Agent (Stage B)    │   │
│                          │  challenges recommendations     │   │
│                          └──────────────┬──────────────────┘   │
│                                         │                       │
│                          ┌──────────────▼──────────────────┐   │
│                          │  Report (3 files) ✓ OFFICIAL    │   │
│                          │  publishable immediately        │   │
│                          └─────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Why Two Adversarial Agents, Not One

Stage A (Opportunity Map) and Stage B (Recommendations) have different failure modes. A single adversarial review at the end cannot correct a flawed opportunity map — all downstream work built on bad foundations is already complete. Two reviews at different stages catch different classes of problems when correction is still cheap.

Both are agent invocations — zero human cost, zero delay.

### Report Is Official at Completion

The scan produces a complete, official report. It is publishable and shareable immediately — no approval gate required.

**CoE can challenge post-publication:**
- Challenge specific findings, recommendations, or risk assessments with evidence and rationale
- Challenges are recorded in `assessment.json` as CoE annotations (not edits to the original assessment)
- A successful challenge triggers a rescan or manual correction in the next cycle — it does not retroactively invalidate the published report
- Mastered nominations: only CoE can nominate a repo for Mastered level. The agent flags candidates; CoE confirms or rejects.

**KB proposals:** CoE reviews `kb-updates.md` and merges approved patterns into knowledge-base/. This is KB curation, not report validation.

### Execution Model

AAMM scans can run:
- **Claude Max (zero marginal cost):** Interactive via Claude Code CLI or VS Code. Operator triggers manually.
- **API (token cost):** Automated, batch, or scheduled. Same agent, same quality.

Quality of findings and recommendations is the priority regardless of execution mode.

---

## 4. The Five Assessment Components

### Component 1: Opportunity Map

**Question:** Where would AI add the most value in this specific repo, given its domain, tech stack, test profile, and change history?

**Data used:**
- File tree and contents (documentation density, test types, schema presence, module structure)
- Git history: high-churn modules, recent additions, areas of active development, revert patterns
- CI configuration: what's automated, what's slow, what's manual
- Commit patterns: where problems are introduced
- KB patterns per ecosystem

**Opportunity ID generation:**
- KB-derived opportunities: `hash(repo_slug + kb_pattern_id)` — stable as long as KB pattern ID is stable
- ID follows the opportunity regardless of modifications to title or content
- Delta tracking at next scan: IDs absent from current map = "discontinued"; new IDs without precedent = "new"

**Output:** Specific opportunities (minimum 3, no artificial upper bound — Stage A reduces), **ordered by ROI descending** (value × 1/effort). Each containing:
```
id:          stable hash (see generation rules above)
title:       specific action, not generic category
value:       HIGH / MEDIUM / LOW (for this repo type)
effort:      High / Medium / Low (to get started)
roi_rank:    position in ROI-ordered list (1 = highest ROI)
evidence:    specific repo artifacts (file paths, commit SHAs, CI lines)
kb_pattern:  KB entry that grounds this opportunity
seen_in:     [repo, outcome] — cross-portfolio reference if available
```

**No artificial count target.** A small repo may have 3 real opportunities. A mono-repo may have 12. The agent produces what the evidence supports; Stage A filters what doesn't hold up. Forcing a minimum count produces platitudes; forcing a maximum suppresses real findings.

**Failure mode explicitly avoided:** Generic opportunities — "AI for documentation" without citing which modules are underdocumented and why that matters for this repo. The adversarial agent at Stage A filters these.

### Component 1A (Process): Adversarial Review — Stage A

A separate agent invocation with an aggressive prompt. Reviews each opportunity against four criteria.

**What "fresh context" means:** The adversarial agent receives the opportunity map **plus the repo data** (file tree, key file contents, git history summary, CI config) — the same data the primary agent used. What it does NOT receive is the primary agent's reasoning, internal notes, or draft iterations. It can independently verify every claim in the opportunity map against repo evidence. Without repo data, the grounding and relevance tests are impossible.

**Four criteria:**

1. **Specificity test:** Would this opportunity appear identically on any repo in the same ecosystem? The adversarial agent compares the opportunity's evidence against the repo's specific structure — if the evidence is generic (e.g., "has a src/ directory"), it's a platitude. If the evidence names specific modules, files, or patterns unique to this repo, it passes.
2. **Grounding test:** Does the opportunity cite specific repo artifacts (files, commits, patterns)? The adversarial agent spot-checks 2-3 citations by reading the cited files. If citations are wrong or misleading → rejected.
3. **Feasibility test:** Is this actionable with reasonable effort by a team without prior AI experience in this area? If no → downgraded or rejected.
4. **Relevance test:** Is this opportunity relevant to this repo's domain and current priorities (inferred from churn/recency in the git history)? If no → rejected.

**Output** — two mandatory documents:
1. **Approved opportunity map** — basis for all downstream assessment
2. **Rejection summary** — 3-5 lines per rejected opportunity: what + why. CoE sees what was filtered during post-publication review.

Full rejection details archived in detailed-log.

### Component 2: Adoption State

**Question:** Which validated opportunities are currently in use?

Per approved opportunity: **Active** / **Partial** / **Absent**

- **Active:** Regular AI-attributed commits in this area, or AI config explicitly references this use case
- **Partial:** Some evidence (occasional commits, one-off usage) but not systematic
- **Absent:** No positive evidence

The agent does not infer absence as negative — absence means no observable signal, not "not happening." Team communication channels (Slack, wiki) are not observable.

**The gap signal:** Absent on a validated high-value opportunity is the primary input for recommendations. It surfaces what's possible but not happening.

### Component 3: Readiness per Use Case

**Question:** Is the repo set up to make each validated opportunity effective?

Criteria come exclusively from the **Knowledge Base** — not generated ad-hoc per scan. This ensures comparability across scans and repos, and eliminates the circularity problem (agent evaluating against its own criteria).

**Strict two-phase reading — scan-from-zero preserved:**
- **Phase 1 (assessment):** Agent reads KB + current repo data only. No previous scan results. Assessment is completed and frozen.
- **Phase 2 (delta computation):** After Phase 1 is frozen, agent reads the previous `assessment.json` and computes delta mechanically: opportunity IDs compared, readiness levels compared, adoption states compared, recommendation statuses compared. Delta populates the Evolution section only — it does not alter any Phase 1 output.

This eliminates anchoring bias: previous results cannot influence the current assessment because they are not in context during Phase 1.

**Levels:**

| Level | Meaning |
|-------|---------|
| ⬜ Undiscovered | Repo lacks basic prerequisites for this use case |
| 🟡 Exploring | Prerequisites exist but setup is incomplete or inconsistent |
| 🟢 Practiced | Repo is well-configured for this use case; team could start today |
| 💎 Mastered | Exemplary setup; practices documented and transferable; **requires explicit CoE nomination** (see below) |

**Why Mastered requires CoE nomination:** Undiscovered/Exploring/Practiced are assessable from repo evidence alone — they answer "what exists in the repo." Mastered answers a different question: "are these practices transferable to other teams?" Transferability requires context the agent cannot observe: has another team successfully adopted this repo's patterns? Did the documentation actually help someone outside the original team? Has CoE validated the practices against portfolio-wide standards? These are organisational signals, not repo signals. The agent flags Mastered candidates (repos where all KB criteria are met and practices are well-documented); CoE confirms or rejects based on cross-team evidence.

**Missing KB criteria:** If the KB has no readiness criteria for an opportunity's use-case type, readiness is marked **Not Assessable** with reason: "No KB criteria for this use-case type." This does not block the opportunity from appearing in the report — Adoption State and Recommendations still apply. The readiness gap for that opportunity defaults to "unknown" (not "low"), and recommendations frame it as: "Readiness cannot be assessed — KB criteria needed before readiness evaluation." The opportunity is excluded from Quadrant computation (it contributes neither to AI Potential nor AI Activity counts).

**Active + Undiscovered — Risky Acceleration flag:** If any opportunity is simultaneously Active and Undiscovered readiness, this generates an automatic per-opportunity risk flag: "AI in use without foundational readiness." This flag appears in the executive summary regardless of overall quadrant position.

### Component 4: Risk Surface

**Question:** Where would AI errors be hardest to detect and most damaging?

Risk is mapped to concrete code paths, not the repo as a whole. Severity is calibrated to **current AI exposure** — what AI has actually touched — not theoretical maximum.

**Two dimensions per risk path:**

| Dimension | HIGH | MEDIUM | LOW |
|-----------|------|--------|-----|
| **Detection difficulty** | Weak test coverage, subtle invariants, cross-component dependencies | Tests cover happy paths; edge cases implicit | Heavy property tests, formal verification, CDDL conformance |
| **Blast radius** | Consensus, cryptography, financial state, cross-era serialization | API contracts, data migration, auth flows | Presentation, documentation, non-critical utilities |

**Calibration rule:**
- AI commits touching test files only → flag test paths, not the codebase
- No AI commits but AI config present → preventive note, not active risk flag
- AI commits touching critical paths without mandatory review → HIGH severity

**Intersection with Opportunity Map:** When a validated opportunity would, if adopted, touch a high-risk code path, the report surfaces this explicitly with a "proceed with guardrails" framing. AAMM does not make the go/no-go decision — the team does.

**Confidence on intersection:** The mapping from use cases (abstract) to code paths (concrete) is inferential — e.g., "corner case discovery in QuickCheck" doesn't map mechanically to specific files; the agent infers which modules would be affected. All opportunity-risk intersections carry **MEDIUM confidence ceiling** (semi-objective at best). The report must state this explicitly: "This opportunity intersects with high-risk paths [list] — confidence: MEDIUM (inferred, not confirmed)." Teams treat this as a flag to investigate, not a confirmed risk.

### Component 5: Recommendations

**Question:** What should the team do next, and what do they need to know to do it?

**Ordered by ROI descending:** value × (1/effort) × adoption gap size. The first recommendation is the highest-ROI action the team can take. If the team reads nothing else, they read #1.

**Three recommendation types derived from component combinations:**

| Opportunity state | Recommendation type | Example framing |
|---|---|---|
| High value + High readiness + Absent | Start now | "Everything is in place for X. The gap is activation, not preparation." |
| High value + Low readiness + Absent | Foundation first | "Before adopting X, set up Y — it's the prerequisite that makes X reliable" |
| High value + Low readiness + Active | Fix the foundation | "You're already using X but the setup doesn't support it safely. Fix Y first." |

**Each recommendation contains:**
- Title (specific action)
- Effort: Low / Medium / High
- Impact: HIGH / MEDIUM / LOW
- Linked opportunity ID
- Measurable outcome: "done when X is true" — must be verifiable from repo data at next scan
- Recommended learning: what the team needs to know to execute (from KB). This is the educational output of AAMM — "we know where AI could help; here's what to do Monday morning."

**Learning entry example:**
> "Corner case discovery in QuickCheck: take one existing Arbitrary instance, ask Claude to identify invariants it's not covering, review output against the formal spec before committing. See KB: haskell/quickcheck-patterns.md — prompting strategy section."

### Component 5A (Process): Adversarial Review — Stage B

Separate agent, fresh context. Challenges each recommendation against four criteria:

1. **Groundedness test:** Does the recommendation trace to specific assessment evidence (not agent opinion)?
2. **Measurability test:** Can "done when X" be verified from repo data at the next quarterly scan?
3. **Actionability test:** Can a tech lead put this in the team backlog tomorrow morning with a clear owner and scope?
4. **Relevance test:** Is this specific to this team's context, or is it a generic best practice that would appear on any report?

Rejected recommendations are documented with reasons. If all recommendations are rejected, this is flagged in the report — it indicates either the opportunity map was weak or the recommendation generation needs tuning.

### Risk Flag: Ad-hoc AI Usage

Not a scored component — a flag surfaced when the pattern is detected.

**Trigger:** AI-attributed commits exist across multiple areas but no intentionality signals are present (no CLAUDE.md, no .aiignore, no AI policy in CONTRIBUTING.md, no consistent attribution pattern).

**What the flag says:** "AI is in active use but there's no evidence it's deliberate or governed. This increases the chance of inconsistent practices and untracked risk."

**What the flag does NOT say:** It does not judge the team or require specific mechanisms. A team can govern AI usage through practices that aren't visible in the repo — the flag notes the absence of observable signals, not the absence of governance.

The flag appears in the executive summary when triggered. Trajectory (improving/stable/regressing) is computed in the Evolution section by comparing against the previous scan.

---

## 5. Confidence Model

Every assessment includes a confidence level:

| Evidence type | Examples | Confidence ceiling |
|---------------|---------|-------------------|
| **Objective** | File exists, config parsed, count verified, attribution confirmed in commit | HIGH |
| **Semi-objective** | Content matches expected structure, pattern detected, churn inferred from git log | MEDIUM |
| **Subjective** | Quality judgment, effort estimate | LOW |

The agent cannot self-assign HIGH confidence on subjective evaluations. Non-negotiable.

**Grounding rule:** Every finding must cite file path + content excerpt (or API response excerpt for commit/PR data). The adversarial agent at Stage B spot-checks 3-5 claims by re-reading cited sources. Ungrounded findings are automatically LOW confidence.

---

## 6. Output Format

### report.md (team-facing)

Structured for progressive reading. Sections in order:

```
1.  Executive Summary        ← first 15 lines; everything a tech lead needs
                               Opportunities (3 bullets) + Top recs (3 bullets)
                               + Risk flags (Risky Acceleration, Ad-hoc usage)
2.  Opportunity Map          ← what AI could do here, with evidence
3.  Risk Surface             ← before recommendations; context for action
4.  Top Recommendations      ← actionable, with recommended learning
5.  Adoption State           ← per opportunity: active / partial / absent
6.  Readiness per Use Case   ← per opportunity: level + key criteria
7.  Evolution                ← delta vs previous scan
8.  Evidence Log             ← citations, confidence levels, adversarial outcomes
```

**Risk Surface precedes Recommendations (sections 3 and 4).** Teams must understand the risk context before acting on recommendations.

### assessment.json (structured data)

Schema version: 6.0. Minimum fields:

```json
{
  "schema_version": "6.0",
  "scan_type": "scoring | learning",
  "scan_date": "YYYY-MM-DD",
  "repo": { "owner": "", "name": "", "ecosystem": "", "project": "" },
  "opportunity_map": [
    {
      "id": "",
      "title": "",
      "value": "HIGH|MEDIUM|LOW",
      "effort": "High|Medium|Low",
      "evidence": "",
      "kb_pattern": "",
      "seen_in": [{ "repo": "", "outcome": "" }],
      "adversarial_status": "approved|rejected"
    }
  ],
  "adoption_state": [
    { "opportunity_id": "", "state": "Active|Partial|Absent", "evidence": "" }
  ],
  "readiness": [
    {
      "opportunity_id": "",
      "level": "Undiscovered|Exploring|Practiced|Mastered|Not Assessable",
      "criteria_results": [
        { "criterion": "", "result": "YES|NO", "confidence": "HIGH|MEDIUM|LOW", "evidence": "" }
      ],
      "risky_acceleration_flag": false
    }
  ],
  "risk_surface": [
    {
      "path": "",
      "detection_difficulty": "HIGH|MEDIUM|LOW",
      "blast_radius": "HIGH|MEDIUM|LOW",
      "ai_exposure": "confirmed|potential|none",
      "evidence": ""
    }
  ],
  "recommendations": [
    {
      "id": "",
      "title": "",
      "type": "start_now|foundation_first|fix_the_foundation|kb_gap",
      "effort": "Low|Medium|High",
      "impact": "HIGH|MEDIUM|LOW",
      "opportunity_id": "",
      "measurable_outcome": "",
      "recommended_learning": "",
      "kb_ref": "",
      "adversarial_status": "approved|rejected",
      "adversarial_reason": "",
      "team_response": {
        "status": "accepted|rejected|deferred|no_response",
        "rationale": "",
        "recorded_by": "coe",
        "recorded_date": "YYYY-MM-DD"
      }
    }
  ],
  "flags": {
    "risky_acceleration": [],
    "adhoc_usage": false
  },
  "quadrant": {
    "ai_potential": "HIGH|MEDIUM|LOW",
    "ai_activity": "HIGH|MEDIUM|LOW",
    "position": ""
  },
  "kb_nominations": [],
  "mastered_nominations": [],
  "previous_scan_date": "YYYY-MM-DD | null"
}
```

### detailed-log.md (audit trail)

Everything: API calls made, files read with excerpts, reasoning per component, adversarial dialogues (Stage A + Stage B), rejected opportunities with reasons, rejected recommendations with reasons.

---

## 7. Quadrant (Portfolio / Leadership View)

### Per-repo quadrant

**AI Potential** — how many validated opportunities have Readiness ≥ Practiced?
- HIGH: ≥3 opportunities at Practiced+
- MEDIUM: 1-2 at Practiced+
- LOW: 0 at Practiced+

**AI Activity** — how many validated opportunities show Active or Partial adoption **and** Readiness ≥ Exploring?
*(Active + Undiscovered does not count toward AI Activity — it counts as a Risky Acceleration flag)*
- HIGH: ≥3 opportunities Active/Partial with Readiness ≥ Exploring
- MEDIUM: 1-2 Active/Partial with Readiness ≥ Exploring
- LOW: 0

**Grid:**

Labels are descriptive, not judgmental. They describe the state, not the team's merit.

| | Low Activity | Medium Activity | High Activity |
|---|---|---|---|
| **High Potential** | Ready, not yet active | Partially active | Broadly active |
| **Medium Potential** | Some foundations | Selectively active | Active, gaps in foundations |
| **Low Potential** | Early stage | Active without foundations ⚠ | Active without foundations ⚠ |

Cells marked ⚠ trigger the Risky Acceleration flag in the executive summary — high activity with low foundational readiness is a risk pattern, not a judgment.

### Portfolio view (CoE + Leadership)

Generated quarterly by a **portfolio scan** — a separate skill (`/portfolio-scan`) triggered manually by CoE lead.

**Operator:** CoE lead.
**Trigger:** Manual, end of quarter, after planned scoring scans are complete or after a defined cutoff date.
**Incomplete data:** Repos without a current-quarter scan use the most recent available scan, marked explicitly as `"last_scanned": "YYYY-QN"`. Repos are never excluded — data freshness is transparent.

**Output path:** `scans/ai-augmentation/portfolio/YYYY-QN/`

`portfolio-summary.md` structure (2-minute leadership read):
```
## Portfolio: AI Augmentation — Q[N] [Year]

Repos assessed this quarter: N / Total: M (last-scan dates for remainder)
Quadrant distribution: [table]
Delta vs Q[N-1]: [movers up / movers down]
⚠ Flags requiring attention: [Risky Acceleration flags, Ad-hoc usage flags]
Repos needing CoE attention: [list with reason]
Top patterns emerging across portfolio: [2-3 bullets]
```

`portfolio.json` aggregates all repo quadrant positions and recommendation statuses for dashboard/reporting tool integration.

---

## 8. Scan Flow (Scoring Scan)

```
Step 1   Data Collection
         File tree, git history (full), CI config, commits (last 100 or last 90 days, whichever yields more),
         PRs (last 30), key file contents, churn patterns per module
         Public repos: no auth required
         Private repos: GITHUB_TOKEN with read scope

Step 2   Opportunity Map Generation
         Agent reads KB (ecosystem opportunity patterns + use-case catalog)
         + repo data from Step 1
         Produces opportunities (min 3, no artificial cap) ROI-ordered,
         with full output structure (id, title,
         value, effort, evidence, kb_pattern, seen_in)

Step 3   Adversarial Review — Stage A
         Separate agent. Aggressive prompt. Four criteria:
         specificity / grounding / feasibility / relevance
         Output (mandatory):
           (1) Approved opportunity map
           (2) Rejection summary — 3-5 lines per rejected opp: what + why
         Full details archived in detailed-log

Step 4   Component Assessment
         For each approved opportunity:
           Adoption State (Active / Partial / Absent)
           Readiness per Use Case (KB criteria → level)
           Flag: Active + Undiscovered → Risky Acceleration
         Across all opportunities:
           Risk Surface (path mapping, detection difficulty, blast radius,
                         AI exposure calibration; intersect with opportunity map)
           Flag: Active across multiple areas + no intentionality signals
                 → Ad-hoc AI Usage

Step 5   Recommendation Generation
         Recommendations (ROI-ordered) derived from:
         opportunity × readiness gap × adoption state
         Each: title, type, effort, impact, opportunity_id,
               measurable_outcome, recommended_learning (from KB)

Step 6   Adversarial Review — Stage B
         Separate agent. Four criteria:
         groundedness / measurability / actionability / relevance
         Output: approved / rejected per recommendation with reasons
         If all rejected: flagged in report for CoE attention

Step 7   Report Generation
         Phase 1 (assessment frozen): agent writes assessment.json with
           all component outputs. This file is immutable after this step.
         Phase 2 (delta computation): agent reads previous assessment.json,
           computes delta mechanically (IDs, levels, statuses). Adds
           Evolution section to report.md. Does NOT modify assessment.json.
         report.md (section order: Summary → Opportunity Map → Risk Surface
                    → Recommendations → Adoption → Readiness → Evolution
                    → Evidence Log)
         assessment.json (schema v6.0)
         detailed-log.md (full audit trail)
         Saved to: scans/ai-augmentation/results/YYYY-MM-DD/OWNER--REPO/

Step 8   KB Update Proposals
         New opportunity patterns or readiness criteria discovered →
         proposed entries (status: proposed) →
         scans/ai-augmentation/results/YYYY-MM-DD/kb-updates.md
         CoE reviews before merging to knowledge-base/
```

**Fully autonomous end-to-end.** No mid-scan gates, no confirmations, no human interaction during scan execution.

**Post-scan:** Report is official and publishable at completion. CoE can challenge findings post-publication with evidence (see Section 3: "Report Is Official at Completion"). KB proposals reviewed and merged separately.

**Scan cadence:** Quarterly for all repos in `models/config.yaml`. Ad-hoc scans on request (new repo, major release, significant change in AI tooling).

**Recommendation follow-up:** At each quarterly scan, the agent checks recommendation IDs from the previous scan against current repo state. For each recommendation with a measurable outcome: verified / unverified / not applicable. Delta appears in Evolution section.

**Recording team responses:** After sharing, teams communicate decisions via existing channels (PR comment, email, Slack to CoE). CoE records the team's response in `assessment.json` under `recommendations[].team_response` — status (accepted / rejected / deferred / no_response) + rationale + date. Teams do not modify JSON files directly.

---

## 9. Knowledge Base

The KB has two roles in v6:

### Role 1 — Opportunity Patterns per Ecosystem

Per ecosystem, the KB holds a catalog of AI use cases:

```yaml
id: quickcheck_corner_case_discovery
ecosystem: haskell
applies_when:
  - QuickCheck or Hedgehog used for property-based testing
  - Arbitrary instances exist per domain type
  - High-churn modules with complex invariants
value: HIGH for property-test-heavy repos
effort: Medium
evidence_to_look_for:
  - testlib/*/Arbitrary.hs files
  - Absence of shrinking implementations
  - New modules added without corresponding generators
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "identified gap in dijkstra era generators (2026-03-28)"
learning_entry: |
  Start with one Arbitrary instance. Ask Claude to identify invariants
  not covered. Validate output against formal spec before committing.
  See quickcheck-prompting-patterns.md for prompting strategy.
```

### Role 2 — Readiness Criteria per Use Case

Per use case type, the KB holds validated assessment criteria (CoE-approved, not ad-hoc):

```yaml
use_case: quickcheck_corner_case_discovery
readiness_criteria:
  - criterion: "Arbitrary instances exist per domain type"
    type: Objective
    check: "testlib/ directories contain Arbitrary.hs files per module"
  - criterion: "Shrinking implemented in generators"
    type: Objective
    check: "Arbitrary instances use shrink or via Generics"
  - criterion: "Invariants documented in test modules"
    type: Semi-objective
    check: "test modules contain comments explaining what properties are tested"
  - criterion: "CI runs property tests"
    type: Objective
    check: "CI workflow invokes cabal test or equivalent covering testlib/"
```

### KB Bootstrapping — Phase 0 (Mandatory, Before Any Scoring Scan)

KB bootstrapping is the **first thing AAMM v6 does**. No scoring scans run until the KB has real patterns for the target ecosystem.

**Step 1 — Seed KB (CoE manual):**
CoE writes 5-10 initial use-case patterns per ecosystem based on domain knowledge. These are not comprehensive — they give the learning scan agent a vocabulary of what to look for. Without a seed, learning scans have no anchor and produce noise.

**Step 2 — Learning scans on monitored repos (29 repos in config.yaml):**
Agent scans each repo in learning mode. Produces `kb-proposals.md` with patterns observed, grounded in repo evidence. CoE reviews and merges approved proposals.

**Step 3 — Learning scans on similar external repos:**
Repos selected for similarity: same language, comparable complexity, high-assurance domain. These provide patterns the portfolio repos may not exhibit yet but should aspire to.

**Step 4 — KB review and consolidation:**
CoE reviews all merged patterns. Removes duplicates, resolves conflicts, promotes `proposed` → `validated`. Result: KB populated with real, evidence-grounded patterns per ecosystem.

**Only then do scoring scans begin.**

**KB entry attribution:** Every pattern includes `seen_in` — the repo where it was first observed and validated. This enables active cross-pollination: when an opportunity map references a pattern, the report cites the real-world example, not just the abstraction.

---

## 10. Edge Cases and Failure Modes

### Stage A rejects all opportunities

The adversarial agent filters every opportunity from the map. This means the primary agent produced nothing repo-specific.

**What happens:** The scan terminates early. Report contains only: Data Collection summary + Stage A rejection summary + a single finding: "No repo-specific AI opportunities identified. This may indicate: (a) the KB lacks patterns relevant to this repo's ecosystem/domain, (b) the repo's structure makes AI opportunities hard to derive from artifacts alone, or (c) the repo genuinely has no high-value AI opportunities at this time." No Adoption State, no Readiness, no Recommendations, no Quadrant position. The report is still official — "no findings" is a valid finding.

**Follow-up:** CoE reviews the rejection summary. If rejections seem wrong, CoE challenges post-publication. If rejections seem right, the repo may need a learning scan first, or may simply not be a priority for AI adoption.

### KB has no patterns for the target ecosystem

Covered by the cold-start rule (Section 2): agent uses cross-cutting patterns only, marks the scan explicitly, recommends learning scan. For scoring scans: the scan still runs but Readiness for ecosystem-specific opportunities is marked "Not Assessable." Only cross-cutting opportunities get full assessment.

### Repo has zero AI-attributed commits

Adoption State = all Absent. Risk Surface = no active AI exposure (preventive notes only if AI config exists). Ad-hoc flag = not triggered (no activity to be ad-hoc about).

**The report is still valuable:** Opportunity Map + Readiness show what's possible and how ready the repo is. Recommendations are all "Start now" or "Foundation first" type. This is the awareness gap use case — the primary reason AAMM exists.

### Repo is archived or unmaintained

If the repo has no commits in the last 6 months and no open PRs, the agent flags this in the executive summary: "Repo appears unmaintained — recommendations may not be actionable without active development." The scan still completes (historical record), but recommendations are framed as conditional: "If development resumes, prioritize X."

### Stage B rejects all recommendations

Already covered in spec (Component 5A): flagged in the report for CoE attention. Additionally: the report still contains Opportunity Map, Adoption State, Readiness, and Risk Surface — these are valuable without recommendations. The finding "no actionable recommendations survived adversarial review" is itself informative.

### Adversarial agents are too aggressive or too lenient

This is a tuning problem, not a spec problem. But the spec should acknowledge it: adversarial prompt calibration is an operational concern. If Stage A consistently rejects >80% of opportunities across multiple scans, or consistently approves >95%, the adversarial prompt needs adjustment. The detailed-log includes rejection/approval rates per scan. CoE monitors these rates across scans and recalibrates prompts when patterns indicate systematic over- or under-filtering.

### CoE never reviews post-publication

The report is official regardless. KB proposals accumulate unmerged — the KB stagnates, future scans get less specific. Mastered nominations are never confirmed — no repo reaches Mastered. Team responses are never recorded — Evolution section has no team feedback data.

**Degradation is gradual, not catastrophic.** The system works without CoE review; it works better with it. The spec does not pretend CoE review is optional — it's important. But the system doesn't break without it.

---



- Single AI agent (not dual architecture) — ADR-018 principle holds
- Fully autonomous scan execution — no mid-scan gates or confirmations
- Adversarial review as mandatory gate — ADR-012, now applied twice (Stage A + Stage B)
- Scan-from-zero rule — KB reused, prior results not consulted before assessment
- Confidence model (HIGH/MEDIUM/LOW with evidence type ceilings)
- Grounding rule (every finding cites file path + content excerpt)
- Leveled indicators (not numeric scores)
- Quadrant concept (now: AI Potential × AI Activity)
- Per-repository assessment (org-level is derived, never independently assessed)
- Knowledge Base for cross-repo learning
- Three output files (report.md + assessment.json + detailed-log.md)
- ADR process for design decisions

## 11. What We Eliminate from v5

- 25-criterion rubric measuring general engineering maturity as the primary scoring mechanism
- 5 generic readiness pillars (Structure, Clarity, Purpose, Workflow, Safety Net) as quadrant determinants
  *(These become an optional context section in the report — informative, not scored)*
- Binary AI presence/absence as risk calibration
- Single adversarial review at the end (two reviews at different stages)
- Fixed rubric criteria independent of use cases (criteria now live in KB per use case type)

## 12. What v6 Adds

- Use-case spectrum as the foundation (not generic engineering maturity)
- Opportunity Map as the core assessment driver
- Readiness assessed per use case (from KB criteria), not globally
- Risk Surface mapped to concrete code paths with AI exposure calibration
- Two-stage adversarial review (opportunity map + recommendations)
- Recommended learning per opportunity (educational output)
- Scan-from-zero with mechanical delta computation (Phase 1 / Phase 2 separation)
- Ad-hoc AI Usage flag (replaces scored governance component)
- Learning scans as a distinct scan type for KB bootstrapping

---

## 13. Version Compatibility

Scans produced under v5 (`schema_version: "5.0"`) are a **legacy baseline**. They are internally comparable to each other but not to v6 scans. The axes mean different things.

When running a v6 scan on a repo with a v5 scan history:
- Include the v5 quadrant position as historical context in the Evolution section
- Do not compute delta from v5 to v6 scores
- The first v6 scan is the new baseline for trajectory tracking

---

## References

- [ADR-019](../../docs/decisions/019-aamm-v5-wrong-question.md) — Why v5 answered the wrong question
- [ADR-018](../../docs/decisions/018-aamm-v5-single-agent-architecture.md) — Single agent architecture (still valid)
- [scoring-model.md](scoring-model.md) — Operational manual for the agent (update pending for v6)
- [knowledge-base/](knowledge-base/) — Ecosystem patterns and use-case criteria
