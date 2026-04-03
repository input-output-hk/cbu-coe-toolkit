# AAMM Changelog

## v7.0 — 2026-04-03 (Tri-agent consensus with local clone + request/serve protocol)

**Supersedes:** v6.2 (dual-agent consensus, 2026-04-02)
**ADR:** ADR-020
**Spec:** `docs/superpowers/specs/2026-04-03-aamm-v7-tri-agent-design.md`
**Skill:** `.claude/skills/scan-aamm-v7/SKILL.md`

### What changed from v6.2

**Architecture:**
- Replace dual-agent (Claude + Gemini) with tri-agent (Claude + Gemini + Grok)
- Replace GitHub API pre-collection with local clone + agent-driven file discovery
- Each agent independently decides what files to examine from a neutral manifest — zero pre-selection bias

**Consensus:**
- Tiered consensus: HIGH (all 3 ≥9/10), MEDIUM (2/3 ≥9 + third ≥7, `coe_review_required: true`), `consensus: false`
- MEDIUM cap: 10 items per scan; overflow downgraded to LOW with `downgraded_reason` recorded
- Intersection-first: items all 3 agents find auto-approved at consensus_round: 0

**Data collection:**
- Repos cloned locally to `/tmp/aamm-v7-$OWNER-$REPO/clone/`
- Scoring scans: `--depth=100`; learning scans: `--shallow-since="12 months ago"` (deepens to 24m if <500 commits)
- Neutral manifest: file tree + git stats only (no content, no signals)
- Each agent requests files independently; orchestrator serves unfiltered

**SDLC coverage:**
- Dynamic pruning by repo_type (library/web-app/cli-tool/infrastructure/mixed)
- Monorepo detection with deny-list (vendor/, deps/, third_party/, extern/, node_modules/)
- Active sections selected per scan, not static

**Learning scans:**
- Union model: every evidenced finding enters kb-proposals (not intersection)
- Confidence tiers: HIGH/MEDIUM/LOW/LOW-GROK/LOW-ABSENCE
- Hallucination filter: counter-evidence only (no scoring, no disagreement)
- File cap: 1000 files per agent max

**Infrastructure:**
- New JSON schema: `schema/assessment-v7.schema.json` (adds tri-agent fields, risk_surface.scenario, value_reason, downgraded_reason)
- New skill: `scan-aamm-v7` (replaces scan-aamm-v6)
- New skill: `select-reference-repos` (tri-agent consensus reference repo selection)
- Partial handling: either Gemini or Grok unavailable after 5 retries → continue with ⚠ WARNING
- Adaptive consensus thresholds in PARTIAL mode (2-agent operation)

---

## v6.2 — 2026-04-02 (KB redesign: adoption signals + deep readiness)

**Spec:** `docs/superpowers/specs/2026-04-02-kb-redesign-design.md`

### What changed from v6.1

**KB format:**
- Every opportunity entry now includes `adoption_signals` (active/partial/absent/anti_patterns) with concrete, checkable signals
- Every opportunity entry now includes `readiness_levels` (undiscovered/exploring/practiced) with quantitative thresholds
- `kb_version: "6.2"` on all entries — agents verify version consistency at scan start
- 70% free method mandate per entry — prevents API rate limit exhaustion
- `confidence_threshold: 60` — agents flag "insufficient data" instead of guessing

**Scoring model:**
- Section 3.1 (Adoption State) now references KB adoption_signals with resolution rules
- Section 3.2 (Readiness) now references KB readiness_levels with quantitative evaluation
- Agents MUST use KB-defined signals — no improvisation
- Confidence <60% caps adoption at Partial maximum

**Gemini prompts:**
- Component assessment prompt mandates KB signal usage
- Phase 1 analysis prompt notes adoption signals for later assessment

**Files changed:** 19 KB entries extended (9 haskell, 5 cross-cutting, 5 typescript), scoring-model.md, 2 Gemini prompts, changelog.

**What does NOT change:** Scan flow, report format, assessment schema, SKILL.md, opportunity fields.

## v6.1 — 2026-04-02 (dual-agent consensus)

**Spec:** `docs/superpowers/specs/2026-04-02-dual-agent-consensus-design.md`

### What changed from v6.0

**Architecture:**
- Single-agent scan with Claude-only adversarial subagents → dual-agent (Claude + Gemini) consensus
- Stage A and Stage B replaced by two-phase consensus loops
- Both agents analyze independently, then debate with evidence until ≥9/10 agreement or 5 rounds
- Disagreements preserved as high-value signals for CoE review, not discarded

**Operational:**
- Gemini CLI invoked with `--yolo` for full repo access (independent exploration)
- File-based communication in `/tmp/aamm-scan/` for full audit trail
- Intersection-first merge: findings both agents identify independently are auto-approved
- Gemini health check mandatory before every scoring scan
- If either agent unavailable → STOP, announce, ask operator. No single-agent fallback.

**Schema:**
- `scan_metadata` added (agents, consensus_model, round counts)
- Consensus fields per opportunity and recommendation (found_by, scores, debate_summary, disagreement)
- `adversarial_status` gains `"disagreement"` value

**Files changed:** SKILL.md (rewritten), 7 new Gemini prompts, 2 old adversarial prompts removed, GEMINI.md extended, schema updated, scoring-model.md updated, spec.md updated, CLAUDE.md updated.

**What does NOT change:** KB format, report sections, config.yaml, learning scan flow, pre-commit Gemini hook, scan-from-zero rule, ROI ordering.

## v6 — 2026-03-30 (spec + scoring-model complete, KB seed pending)

**ADR-019** — v5 answered the wrong question. v6 built around AI use-case spectrum.

### What changed from v5

**Architecture:**
- Replaced 25-criterion fixed rubric with KB-driven, per-use-case assessment
- Opportunity Map is the core driver — everything downstream depends on it
- Two adversarial review stages: Stage A (opportunity map) + Stage B (recommendations)
- Fully autonomous end-to-end — no mid-scan gates, no confirmations
- Report is official at completion; CoE challenges post-publication
- Two scan types: learning (KB population) + scoring (full assessment)

**Assessment model:**
- 5 pillars + 5 zones replaced by 5 components: Opportunity Map, Adoption State, Readiness per Use Case, Risk Surface, Recommendations
- Readiness criteria live in KB per use-case type (not fixed per pillar)
- Risk Surface mapped to concrete code paths with AI exposure calibration
- Ad-hoc AI Usage flag replaces scored Governance component
- Team Capability removed — replaced by recommended learning per recommendation
- Quadrant labels made neutral/descriptive (no judgmental names)
- Readiness level "Not Assessable" added for missing KB criteria

**Operational:**
- All opportunities and recommendations ROI-ordered (#1 = highest ROI)
- No artificial count targets (min 3 opportunities, no upper cap — Stage A filters)
- Opportunity-risk intersection explicitly marked as inferential (MEDIUM confidence)
- Mastered level requires CoE nomination (transferability is an org signal)
- KB bootstrapping defined as Phase 0 (mandatory before first scoring scan)
- Edge cases and failure modes documented in spec

**Files updated:** spec.md (rewritten), scoring-model.md (rewritten), README.md, changelog.md, CLAUDE.md, ADR-019.

**Pending:** KB restructure to v6 format (seed + learning scans), scan skill `/scan-aamm-v6`.

### Design insights (2026-03-28 → 2026-03-30)

- v5 measured "is this a well-run repo?" and called it "AI readiness." A 2015 repo with zero AI use could score HIGH.
- v6 asks "which AI use cases fit this repo, and is the team set up for them?" — correlated but different question.
- First draft of v6 had 7 components, 2 human gates (max 3 rounds each), Team Capability, scored Governance. Three rounds of aggressive adversarial review on the spec itself reduced to 5 components + 1 flag, zero mid-scan gates, fully autonomous.
- Key principle: human gates sound responsible but become rubber stamps under load. 29 repos × quarterly × iterative review = hundreds of hours for one person. An autonomous scan with post-publication challenge is more honest.
- Governance-as-component measured mechanisms (CLAUDE.md exists, attribution consistent) not outcomes — violated ADR-011. Replaced with a flag that notes absence of signals without judging.

## v5 — 2026-03-27

**ADR-018** — Single AI agent replaces bash pipeline.

Key changes from v4:
- Eliminated 9-script bash pipeline (scripts/aamm/)
- Single AI agent with rubric + depth methodology
- Knowledge Base introduced for cross-repo learning (22 pre-seeded patterns)
- Adversarial reviewer sub-agent (mandatory gate, ADR-012 extended)
- 25 readiness criteria across 5 pillars + 15 adoption criteria across 5 zones
- Confidence model: HIGH/MEDIUM/LOW with explicit ceilings per evidence type
- Inferred-evidence ceiling rule for adoption zones
- Quadrant simplified (from complex scoring to 3×3 grid)
- Model files consolidated under `models/ai-augmentation-maturity/`

Design insight (9 sessions of v4 refinement): the bash pipeline was a workaround for the fact that bash can count but cannot understand. The rubric provides reproducibility; the agent provides understanding.

## v4 — 2026-03-21 to 2026-03-26

Bash pipeline + AI agent (dual architecture). 9 sessions of refinement.
Key learnings: dual architecture creates maintenance burden and sync debt.
ADR-017 (superseded by ADR-018).

## v1–v3 — Earlier

Earlier iterations. Undocumented. v4 was the first versioned architecture.
