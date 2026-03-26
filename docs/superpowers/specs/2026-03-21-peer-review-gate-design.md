# Peer Review Gate — Design Specification

**Date:** 2026-03-21
**Version:** 1.0
**Author:** Head of CoE + Claude (implementing agent)
**Status:** Approved — pending implementation

---

## 1. Purpose

Every implementation change, report generation, logic change, and model revision must pass peer review by a principal engineer persona with 20+ years of experience in Haskell, TypeScript, and Rust. The reviewer is rigorous, adversarial, and outcome-oriented. The review gate requires all deliverables to score ≥9.0/10 (with conditional pass at 8.5-8.9 for cosmetic-only objections) before delivery.

The reviewer evaluates work backward from the final outcome: **better, faster value delivery to users** — with heightened scrutiny for high-assurance projects (blockchain wallets, consensus code, financial transactions).

### Limitations

The reviewer is an AI subagent operating via persona-switching — the same AI system reviewing its own work through a different lens. This is effective at catching:
- Mechanical errors (bash pitfalls, jq context loss, missing edge cases)
- Checklist enforcement (rubric compliance, spec-code alignment, recommendation quality)
- Consistency violations (contradicting prior decisions, scope creep, model boundary confusion)

It is NOT a substitute for human judgment on:
- Novel model design decisions that require domain intuition
- Strategic framing that depends on stakeholder relationships
- Quality assessments that require understanding how teams actually work

**The Head of CoE escalation path is the true quality gate for judgment calls.** The AI reviewer catches what's mechanically catchable; escalation to the Head of CoE handles what requires human insight.

---

## 2. Two Reviewer Personas

### Principal Engineer (PE)

20+ years across Haskell, TypeScript, Rust. Reviews:

- Script/code changes (collect, score, review, generate scripts)
- Scoring logic and signal detection
- Scan output and per-repo reports
- Bug fixes and robustness improvements

Thinks: *"Would I trust this code in production? Would a team trust this score? Does this edge case break on a repo I haven't seen yet?"*

### Head of CoE

Reviews:

- Model spec changes (pillars, dimensions, stages, weights)
- Recommendation framing and report narrative
- Strategic alignment (three-model architecture, stakeholder needs)
- Cross-model decisions (what belongs in CMM vs AI Aug vs Vitals)

Thinks: *"Does this serve better, faster value delivery? Will VP/CEO/engineers find this useful? Does this create clarity or confusion?"*

### Persona Routing (automatic)

The skill routes to the correct persona based on what's being reviewed. The implementing agent declares what files/artifacts are under review; the skill applies the routing table.

| Files/artifacts touched | Persona | Rationale |
|------------------------|---------|-----------|
| `README.md`, `adoption-scoring.md`, `readiness-scoring.md`, `backlog.md` decisions | **Head of CoE** | Model design, stage definitions, scoring philosophy |
| `scripts/aamm/*`, `collect-*.sh`, `score-*.sh`, `generate-report.sh` | **PE** | Technical implementation, code correctness |
| `CLAUDE.md`, `config.yaml`, pipeline architecture | **Head of CoE** | Strategic direction, process design |
| Scan reports and recommendations | **Both** | PE on score accuracy, Head of CoE on narrative and actionability |
| Mixed (spec + script in same change) | **Both, sequentially** | Head of CoE on the decision first, PE on the implementation second (see Dual-Persona Scoring below) |
| **Everything else** | **PE** | Default. If PE observes model implications, escalates to both lenses. |

If the agent misroutes (e.g., declares "scripts only" but the diff includes spec changes), the reviewer flags this as a procedural concern.

### Dual-Persona Scoring

When both personas apply (scan reports, mixed changes), the reviewer produces **one score** by applying both lenses sequentially:

1. Head of CoE lens evaluates Impact, Actionability, and Alignment dimensions
2. PE lens evaluates Accuracy and Safety dimensions
3. Each dimension gets one score (not two averaged). If the lenses disagree on a dimension, the stricter score wins.
4. The weighted average produces the final score as usual

---

## 3. Three Graduated Checkpoints

### Checkpoint 1: Design (light)

**When:** Before implementing non-trivial changes — new signals, scoring changes, pipeline modifications, spec revisions.

**Lens:** Head of CoE for model/spec decisions. PE for technical approach.

**Format:** 2-3 provocative questions. No scoring.

**The reviewer asks:**

- "What happens when this meets a repo that looks like X?" (edge case probe)
- "Does this conflict with decision Y we already made?" (consistency check)
- "Is this the simplest way to achieve the outcome?" (YAGNI check)
- For model changes: "Does this create clarity or confusion for teams? Does it serve value delivery?"

**Pass criteria:** The implementing agent must answer each question convincingly. If the reviewer isn't satisfied, the agent revises the approach before writing code.

**Boundary:** Checkpoint 1 covers the *what and why* — the decision, the approach, the model intent. Not the code.

### Checkpoint 2: Implementation (medium)

**When:** After code/spec changes are written, before running verification scans.

**Lens:** PE always. Head of CoE added when spec text changed.

**Format:** Targeted review of the diff against these principles:

- **Absent input:** Does every code path handle missing files, empty results, API failures, unexpected types?
- **Ecosystem correctness:** Does the implementation account for how this language/tool/framework actually behaves?
- **Spec-code alignment:** Does the spec text describe what the code actually does? Would someone reading only the spec predict the code's behavior?
- **Blast radius:** Could this change break a scan on a repo we haven't tested yet? What class of repo would fail?

**Pass criteria:** No blocking objections. Minor suggestions logged but don't block.

**Boundary:** Checkpoint 2 covers the *how* — the code, the diff, the spec text updates. Not the model decision (that was checkpoint 1) and not the final output (that's checkpoint 3).

### Checkpoint 3: Output (heavy — the gate)

**When:** After the final deliverable is produced — scan report, spec document, model change, recommendation set.

**Lens:** Both. PE on technical accuracy. Head of CoE on strategic value.

**Format:** Full 5-dimension scored review. This is the ≥9.0 gate (with conditional pass at 8.5-8.9 for cosmetic-only objections). **Never skipped.**

**Reduced scope for non-deliverable changes:** Config-only changes (adding a repo to config.yaml, updating a version field) and documentation-only changes (learnings.md entries, backlog.md updates) get a pass/fail review without dimensional scoring. The reviewer confirms correctness and alignment in one sentence. This prevents meaningless 10/10 reviews on trivial changes from eroding the gate's credibility.

### Skip Policy

Checkpoints 1 and 2 may be skipped by the implementing agent **only with an explicit justification** logged in the session. Examples:

- "Skipping design checkpoint — single-line bug fix, root cause is decimal output from awk, fix is printf %d"
- "Skipping implementation checkpoint — change is adding a repo to config.yaml, no logic"

**The output checkpoint (3) retroactively audits skips.** If the reviewer at checkpoint 3 finds an issue that would have been caught at a skipped checkpoint, this is flagged as a **"missed checkpoint"** and automatically reduces the Safety & Rigor dimension score. Every skip is a bet that the output reviewer won't find something.

---

## 4. Scoring Rubric

Weighted average across 5 outcome-backward dimensions. Gate: ≥9.0.

| Dimension | Weight | 9-10 (pass) | 7-8 (insufficient) | ≤6 (blocking) |
|-----------|--------|-------------|---------------------|---------------|
| **Impact on value delivery** | 30% | Recommendations reference specific signals from the scan, not generic advice. Next steps include impact/effort. Report connects each score to a concrete action the team can take. For mission-critical: explicitly protects critical paths. | Recommendations exist but are generic ("improve documentation") or disconnected from the actual scores. Team would need to do their own analysis to act. | No recommendations, or recommendations that are copy-paste boilerplate regardless of the repo's actual profile. |
| **Accuracy & trustworthiness** | 25% | Every score is traceable to evidence in the scan data. A principal engineer reviewing the same data would arrive at the same score ±5 points. No signal is obviously wrong. | One or more signals feel off given the evidence. A skeptical engineer would push back on a specific score. | Demonstrably wrong score — evidence contradicts the assigned value. Would damage model credibility if published. |
| **Actionability** | 20% | "Read this, do that." Actions are specific ("add Haddock to exported types in Ledger.Core"), prioritized (ordered by impact/effort), and achievable (team can do it without external dependencies). | Actions exist but vague ("improve test coverage"), unprioritized, or require context the team doesn't have from the report alone. | No actions, or actions that are impossible given the repo's constraints (e.g., "add Dependabot" for an ecosystem without support). |
| **Safety & rigor** | 15% | Edge cases for the repo's language/domain are addressed. No dangerous recommendations for mission-critical code. Skipped checkpoints were justified and nothing was missed. | Generally safe but one edge case unexamined. Recommendation could be misinterpreted without additional context. | Dangerous advice without qualification (e.g., "increase AI co-authorship on consensus code"). Missed checkpoint that would have caught a real problem. |
| **Alignment with model vision** | 10% | Serves the three-model architecture without blurring boundaries. Readiness measures structure, Adoption measures AI presence, Vitals measures outcomes. No scope creep. | Aligned but introduces minor boundary confusion (e.g., measuring an outcome in a readiness signal). | Contradicts a recorded decision. Measures something that belongs in a different model. |

### Scoring Rules

- Each dimension: integer 1-10
- Final score: weighted average, one decimal (e.g., 9.2)
- **≥9.0** → pass
- **8.5-8.9** → reviewer explicitly declares each objection as **blocking** or **cosmetic**. If all objections are cosmetic → **conditional pass** (proceeds with objections logged). If any objection is blocking → fail, agent iterates.
- **7.0-8.4** → fail with specific objections and suggested fixes, agent iterates
- **<7.0** → fail, escalate to the Head of CoE immediately (fundamentally wrong)
- Every dimension scored <9 requires a written objection with a concrete suggested fix
- Max 3 rounds. Each resubmission must address or contest every blocking objection from the previous round. If round 3 still fails, escalate to the Head of CoE with the full review history

### Escalation Mechanism

"Escalate to Dorin" means: write a summary to `docs/escalations/YYYY-MM-DD-topic.md` containing the review history (scores, objections, agent responses, deadlocked items). Halt the current task — do not deliver the artifact. The implementing agent informs the Head of CoE that an escalation is pending and waits for human guidance before proceeding.

---

## 5. Audit Trail

### Single artifact: Checkpoint 3 output

The only persistent review artifact is the checkpoint 3 scored review. It lives where the work lives.

**For scan reports** — embedded in the "Principal Engineer Review" section:

```json
{
  "peer_review": {
    "spec_version": "1.0",
    "round": 1,
    "score": 9.2,
    "verdict": "pass",
    "persona": "PE + Head of CoE",
    "dimensions": {
      "impact_on_value_delivery": 9,
      "accuracy_and_trustworthiness": 9,
      "actionability": 10,
      "safety_and_rigor": 9,
      "alignment_with_model_vision": 9
    },
    "upstream_checkpoints": {
      "design": "passed",
      "implementation": "passed, 1 objection resolved"
    },
    "missed_checkpoints": [],
    "blocking_objections": [],
    "cosmetic_objections": [],
    "resolved_objections": ["blast radius: added || true to grep pipeline"]
  }
}
```

Example for a **conditional pass** (8.5-8.9, all cosmetic):

```json
{
  "peer_review": {
    "spec_version": "1.0",
    "round": 1,
    "score": 8.7,
    "verdict": "conditional_pass",
    "persona": "PE",
    "dimensions": {
      "impact_on_value_delivery": 9,
      "accuracy_and_trustworthiness": 9,
      "actionability": 8,
      "safety_and_rigor": 9,
      "alignment_with_model_vision": 9
    },
    "upstream_checkpoints": {
      "design": "skipped — bug fix with clear root cause",
      "implementation": "passed"
    },
    "missed_checkpoints": [],
    "blocking_objections": [],
    "cosmetic_objections": ["Actionability: recommendation says 'improve tests' — could be more specific about which test category to add"],
    "resolved_objections": []
  }
}
```

**For code/spec changes** — a single line in `backlog.md` Done section:

```
- [x] Multi-cabal support — Reviewed: 9.2/10 (PE, round 1, 0 objections)
```

**For failed reviews that required iteration** — the lesson goes in `learnings.md`:

```
### 2026-03-21 — Peer review: recommendation framing rejected (round 1: 7.8/10)
Reviewer (Head of CoE) objected: "Recommending AI co-authorship increase on a
blockchain wallet is dangerous without qualifying which modules." Fixed by adding
domain-aware recommendation filtering. Passed round 2: 9.1/10.
```

### What does NOT get persisted

- Checkpoint 1 questions and answers (conversational, dies with the session)
- Checkpoint 2 diff review details (conversational, summarized in checkpoint 3)
- Passing reviews with no interesting findings (the score in backlog.md is sufficient)

---

## 6. Integration: CLAUDE.md + Skill

### CLAUDE.md directive

Added to the repo's CLAUDE.md under Agent Instructions:

```markdown
## Peer Review Gate

All work must pass peer review before delivery. This is mandatory, not optional.

- **Checkpoint 1 (Design):** Before implementing non-trivial changes, invoke the
  peer-review skill with type=design. May be skipped with explicit justification.
- **Checkpoint 2 (Implementation):** After writing code/spec changes, invoke the
  peer-review skill with type=implementation. May be skipped with explicit justification.
- **Checkpoint 3 (Output):** After producing any deliverable, invoke the peer-review
  skill with type=output. Never skipped. Must score ≥9.0/10 (conditional pass at
  8.5-8.9 if all objections are cosmetic).

Skipped checkpoints are audited at checkpoint 3. See the peer-review skill for the
full rubric, personas, escalation rules, and context requirements.
```

### Context requirements per checkpoint type

The skill defines exactly what the reviewer receives:

**Checkpoint 1 (Design):**
- The proposed approach (what and why, written by the implementing agent)
- Relevant spec files (README.md, scoring files — read by the skill)
- Related backlog.md items and prior decisions

**Checkpoint 2 (Implementation):**
- The diff (files modified, lines changed)
- The full content of modified files
- The spec section that describes the expected behavior
- For scripts: sample input/output demonstrating the change works

**Checkpoint 3 (Output):**
- The complete deliverable (report .md, .json, or spec document)
- The raw data that produced it (score JSONs, collected data)
- The spec files defining what the output should look like
- Any skipped checkpoint justifications for retroactive audit

### Contestation rules

The implementing agent may contest a reviewer objection **only with evidence:**

- A spec reference that supports the agent's approach
- A test result or scan output that demonstrates correctness
- Data from the collected scan that contradicts the reviewer's claim

The reviewer evaluates the evidence and either:

- **Accepts** — revises the objection, adjusts score
- **Maintains** — restates why the evidence is insufficient

If they deadlock on any objection after one exchange, it escalates to the Head of CoE. No multi-round arguments. One contest attempt per objection, then escalate or comply.

---

## 7. Summary of Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Scope | All changes (code, spec, reports, model) | Quality gate must be universal |
| Failure handling | Iterative with 3-round cap, then escalate | Avoids infinite loops and pure advisory |
| Persona | Domain-adaptive (PE + Head of CoE) | One voice, different lens per domain |
| Review approach | Checkpoint-based (design → implementation → output) | Catches problems early when cheap to fix |
| Rubric orientation | Outcome-backward (value delivery first) | Aligns with three-model philosophy |
| Where it lives | CLAUDE.md directive + skill | Non-negotiable rule + maintainable prompt |
| Audit trail | Single artifact (checkpoint 3 JSON only) | Minimal bureaucracy, maximum signal |
| Contestation | Evidence-based, one attempt, then escalate or comply | Prevents performative compliance without argument loops |
| Conditional pass | 8.5-8.9 with all-cosmetic objections | Eliminates false precision at the gate boundary |
