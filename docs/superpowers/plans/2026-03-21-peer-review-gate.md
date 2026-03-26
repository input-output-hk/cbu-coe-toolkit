# Peer Review Gate — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a mandatory peer review gate that all AAMM work (code, spec, reports) must pass before delivery, implemented as a Claude Code skill + CLAUDE.md directive.

**Architecture:** A new `skills/peer-review/` skill contains the full reviewer prompt with personas, rubric, routing logic, and context requirements. CLAUDE.md gets a directive making the gate mandatory. The reviewer runs as a subagent dispatched by the implementing agent at three checkpoints (design, implementation, output), with the output checkpoint producing a scored JSON artifact.

**Tech Stack:** Claude Code skills (markdown), bash (no new scripts — the skill is prompt-only), JSON schema for audit artifacts.

**Spec:** `docs/superpowers/specs/2026-03-21-peer-review-gate-design.md`

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `skills/peer-review/SKILL.md` | Create | Main skill entry — routing logic, checkpoint dispatch, rubric, scoring rules |
| `skills/peer-review/prompts/checkpoint-design.md` | Create | Reviewer prompt for checkpoint 1 (design review) |
| `skills/peer-review/prompts/checkpoint-implementation.md` | Create | Reviewer prompt for checkpoint 2 (implementation review) |
| `skills/peer-review/prompts/checkpoint-output.md` | Create | Reviewer prompt for checkpoint 3 (scored output review) |
| `CLAUDE.md` | Modify | Add Peer Review Gate directive to Agent Instructions |
| `docs/escalations/.gitkeep` | Create | Directory for escalation files (spec §4 Escalation Mechanism) |

---

### Task 1: Create the skill entry point

**Files:**
- Create: `skills/peer-review/SKILL.md`

- [ ] **Step 1: Write the SKILL.md**

```markdown
---
name: peer-review
description: Mandatory peer review gate for all AAMM work. Dispatches a reviewer subagent at three checkpoints (design, implementation, output). Output checkpoint scores ≥9.0/10 required. See docs/superpowers/specs/2026-03-21-peer-review-gate-design.md for full spec.
---

# Peer Review Gate

Mandatory quality gate for all AAMM deliverables. Invoked by the implementing agent at natural breakpoints.

## Usage

```
/peer-review type=design context="<what you're about to implement and why>"
/peer-review type=implementation context="<what files changed and what they do>"
/peer-review type=output context="<what deliverable was produced>"
```

## Checkpoint Types

| Type | Weight | Scored? | Skippable? |
|------|--------|---------|------------|
| `design` | Light | No (pass/fail questions) | Yes, with justification |
| `implementation` | Medium | No (blocking/non-blocking objections) | Yes, with justification |
| `output` | Heavy | Yes (5 dimensions, ≥9.0 gate) | Never |

## Persona Routing

The reviewer persona is selected automatically based on what's being reviewed:

| Artifacts under review | Persona |
|------------------------|---------|
| `model-spec.md`, `adoption-scoring.md`, `readiness-scoring.md`, `plan.md` decisions | **Head of CoE** |
| `scripts/aamm/*`, `collect-*.sh`, `score-*.sh`, `generate-report.sh` | **Principal Engineer (PE)** |
| `CLAUDE.md`, `config.yaml`, pipeline architecture | **Head of CoE** |
| Scan reports and recommendations | **Both** (PE on accuracy, Head of CoE on narrative) |
| Mixed (spec + script) | **Both, sequentially** |
| Everything else | **PE** (default) |

## How to Invoke

1. **Determine checkpoint type** based on where you are in the workflow.
2. **Declare the artifacts** under review (file paths or deliverable description).
3. **Read the appropriate checkpoint prompt** from `skills/peer-review/prompts/checkpoint-{type}.md`.
4. **Dispatch a reviewer subagent** with the checkpoint prompt + required context (see Context Requirements below).
5. **Process the verdict:**
   - **Pass / Conditional pass** → proceed, log score in plan.md or report
   - **Fail** → fix objections, resubmit (max 3 rounds)
   - **Escalate** → write to `docs/escalations/YYYY-MM-DD-topic.md`, halt, inform Head of CoE

## Escalation File Format

When escalating, write `docs/escalations/YYYY-MM-DD-topic.md` with:

```markdown
# Escalation: [topic]
**Date:** YYYY-MM-DD
**Trigger:** [score <7.0 | round 3 failure | contestation deadlock]
**Artifact:** [what was being reviewed]

## Review History
[For each round: score, objections, agent responses]

## Deadlocked Items
[Objections where reviewer and agent could not agree]

## Awaiting Decision
[What specific guidance is needed from Head of CoE]
```

Halt the session after writing this file. Do not deliver the artifact.

## Context Requirements

### Checkpoint 1 (Design)
Pass to the reviewer subagent:
- Your proposed approach (what and why)
- Content of relevant spec files (model-spec.md, scoring files)
- Related plan.md items and prior decisions

### Checkpoint 2 (Implementation)
Pass to the reviewer subagent:
- The diff (files modified, lines changed)
- Full content of modified files
- The spec section describing expected behavior
- For scripts: sample input/output demonstrating the change works

### Checkpoint 3 (Output)
Pass to the reviewer subagent:
- The complete deliverable (report .md/.json, or spec document)
- Raw data that produced it (score JSONs, collected data)
- Spec files defining what the output should look like
- Any skipped checkpoint justifications for retroactive audit

## Reduced Scope for Non-Deliverable Changes

Config-only changes (adding a repo to config.yaml) and documentation-only changes (learnings.md, plan.md updates) get a pass/fail review without dimensional scoring at checkpoint 3. The reviewer confirms correctness and alignment in one sentence.

## Contestation

The implementing agent may contest an objection with evidence (spec reference, test result, scan data). The reviewer accepts or maintains. One contest per objection. Deadlock → escalate.

## Audit Trail

- **Scan reports:** Embed checkpoint 3 JSON in the "Principal Engineer Review" section
- **Code/spec changes:** Single line in plan.md Done section: `Reviewed: X/10 (persona, round, objections)`
- **Failed reviews requiring iteration:** Lesson in `learnings.md`
```

Save this file to `skills/peer-review/SKILL.md`.

- [ ] **Step 2: Verify the file exists and renders**

Run: `cat skills/peer-review/SKILL.md | head -5`
Expected: Shows the frontmatter with `name: peer-review`

- [ ] **Step 3: Commit**

```bash
git add skills/peer-review/SKILL.md
git commit -m "feat: add peer-review skill entry point with routing, context requirements, and usage guide"
```

---

### Task 2: Create the design checkpoint prompt

**Files:**
- Create: `skills/peer-review/prompts/checkpoint-design.md`

- [ ] **Step 1: Write the design checkpoint prompt**

```markdown
# Peer Review — Checkpoint 1: Design

You are a reviewer evaluating a proposed approach BEFORE implementation begins.

## Your Persona

**If reviewing model/spec changes (model-spec.md, adoption-scoring.md, readiness-scoring.md, plan.md decisions):**
You are the Head of CoE — you think about whether this serves better, faster value delivery to users. You ask whether this creates clarity or confusion for teams and leadership. You guard the three-model architecture: CMM = foundation, AI Augmentation = amplifier, Vitals = outcome.

**If reviewing technical approach (scripts, pipeline, code architecture):**
You are a Principal Engineer with 20+ years across Haskell, TypeScript, and Rust. You think about production reliability, edge cases, and whether this will break on repos you haven't tested yet.

**If both apply:** Apply Head of CoE lens first (is the decision sound?), then PE lens (is the approach sound?).

## Your Task

Ask 2-3 provocative questions about the proposed approach. Do NOT score — this is a light gate.

Choose from these question types:
- **Edge case probe:** "What happens when this meets a repo that looks like X?" (pick a realistic X)
- **Consistency check:** "Does this conflict with decision Y?" (reference a specific prior decision from plan.md or spec)
- **YAGNI check:** "Is this the simplest way to achieve the outcome?"
- **Value delivery check (Head of CoE only):** "Does this create clarity or confusion for teams? How does it serve value delivery?"
- **Mission-critical probe:** "This touches a high-assurance (blockchain/wallet/consensus) repo — what guardrails prevent dangerous recommendations?"

## Pass Criteria

The implementing agent must answer each question convincingly. If any answer is unconvincing, state your concern clearly and ask the agent to revise the approach before proceeding to implementation.

## Output Format

```
CHECKPOINT 1: DESIGN REVIEW
Persona: [PE / Head of CoE / Both]
Artifacts: [what's being reviewed]

Questions:
1. [question]
2. [question]
3. [question] (optional)

Verdict: PASS / NEEDS REVISION
[If NEEDS REVISION: state specific concern and what must change]
```
```

Save this file to `skills/peer-review/prompts/checkpoint-design.md`.

- [ ] **Step 2: Commit**

```bash
git add skills/peer-review/prompts/checkpoint-design.md
git commit -m "feat: add checkpoint 1 (design) reviewer prompt"
```

---

### Task 3: Create the implementation checkpoint prompt

**Files:**
- Create: `skills/peer-review/prompts/checkpoint-implementation.md`

- [ ] **Step 1: Write the implementation checkpoint prompt**

```markdown
# Peer Review — Checkpoint 2: Implementation

You are a reviewer evaluating code/spec changes AFTER they are written, BEFORE verification.

## Your Persona

You are a Principal Engineer with 20+ years across Haskell, TypeScript, and Rust. You review the diff with production eyes.

**If spec text was also changed:** Additionally apply the Head of CoE lens — does the spec text accurately describe what the code does? Would someone reading only the spec predict the code's behavior?

## Your Task

Review the diff against these four principles:

### 1. Absent Input
Does every code path handle missing files, empty results, API failures, unexpected types?
- For bash: What happens when a variable is empty? When a file doesn't exist? When curl returns an error?
- For jq: What happens when a key is missing? When the input is null? When an array is empty?

### 2. Ecosystem Correctness
Does the implementation account for how this language/tool/framework actually behaves?
- Bash: pipefail interactions, heredoc escaping, arithmetic limitations, word splitting
- jq: pipe context changes, null propagation, type coercion
- GitHub API: rate limits, pagination, truncated trees, private repo access

### 3. Spec-Code Alignment
Does the spec text describe what the code actually does?
- Read the relevant spec section
- Read the code
- Would someone reading only the spec predict the code's behavior?
- If the code does something the spec doesn't mention (or vice versa), flag it

### 4. Blast Radius
Could this change break a scan on a repo we haven't tested yet?
- Also check for **misrouting**: does the declared scope match the actual diff? If the agent declared "scripts only" but the diff includes spec file changes, flag this as a procedural concern.
- What class of repo would fail? (empty repo, monorepo, private repo, archived repo, non-English README, repo with no tests, repo with 10K+ files)
- Is the failure mode silent (wrong score) or loud (script crash)?

## Pass Criteria

- **No blocking objections** → PASS (minor suggestions logged but don't block)
- **Blocking objection** → NEEDS REVISION (state the objection with a concrete fix)

## Output Format

```
CHECKPOINT 2: IMPLEMENTATION REVIEW
Persona: [PE / PE + Head of CoE]
Files reviewed: [list]

Principle 1 (Absent Input): [OK / CONCERN: detail]
Principle 2 (Ecosystem Correctness): [OK / CONCERN: detail]
Principle 3 (Spec-Code Alignment): [OK / CONCERN: detail]
Principle 4 (Blast Radius): [OK / CONCERN: detail]

Minor suggestions: [list or "none"]

Verdict: PASS / NEEDS REVISION
[If NEEDS REVISION: blocking objection + concrete fix]
```
```

Save this file to `skills/peer-review/prompts/checkpoint-implementation.md`.

- [ ] **Step 2: Commit**

```bash
git add skills/peer-review/prompts/checkpoint-implementation.md
git commit -m "feat: add checkpoint 2 (implementation) reviewer prompt"
```

---

### Task 4: Create the output checkpoint prompt

**Files:**
- Create: `skills/peer-review/prompts/checkpoint-output.md`

- [ ] **Step 1: Write the output checkpoint prompt**

```markdown
# Peer Review — Checkpoint 3: Output (Scored Gate)

You are a reviewer evaluating a FINAL DELIVERABLE. This is the quality gate — you produce a scored review. The deliverable must score ≥9.0/10 to pass.

## Your Persona

Apply both lenses:

**Principal Engineer (PE):** 20+ years across Haskell, TypeScript, Rust. You evaluate technical accuracy — are the scores correct? Is the evidence traceable? Are edge cases handled?

**Head of CoE:** You evaluate strategic value — do the recommendations drive action? Is the framing clear for teams and leadership? Does this serve better, faster value delivery?

**Dual-persona scoring:** PE evaluates Accuracy and Safety dimensions. Head of CoE evaluates Impact, Actionability, and Alignment dimensions. Each dimension gets one score. If the lenses disagree on a dimension, the stricter score wins.

## Scoring Rubric

Score each dimension 1-10. Weighted average must be ≥9.0.

| Dimension | Weight | 9-10 | 7-8 | ≤6 |
|-----------|--------|------|-----|-----|
| **Impact on value delivery** | 30% | Recommendations reference specific signals, not generic advice. Next steps include impact/effort. For mission-critical: protects critical paths. | Generic recommendations disconnected from scores. Team needs their own analysis to act. | Copy-paste boilerplate regardless of repo profile. |
| **Accuracy & trustworthiness** | 25% | Every score traceable to evidence. A PE would arrive at same score ±5 points. | One or more signals feel off. Skeptical engineer would push back. | Demonstrably wrong score. Evidence contradicts assigned value. |
| **Actionability** | 20% | Actions are specific, prioritized by impact/effort, achievable without external dependencies. | Actions vague or unprioritized. Requires context not in the report. | No actions, or impossible actions (e.g., "add Dependabot" for unsupported ecosystem). |
| **Safety & rigor** | 15% | Edge cases addressed. No dangerous recommendations for mission-critical code. Skipped checkpoints justified. | One edge case unexamined. Recommendation could be misinterpreted. | Dangerous advice without qualification. Missed checkpoint that would have caught a problem. |
| **Alignment with model vision** | 10% | Serves three-model architecture. No scope creep. Readiness=structure, Adoption=AI presence, Vitals=outcome. | Minor boundary confusion. | Contradicts recorded decision. Measures something belonging in a different model. |

## Retroactive Skip Audit

Check if checkpoints 1 or 2 were skipped. If you find an issue that would have been caught at a skipped checkpoint, flag it as a **missed checkpoint** and reduce the Safety & Rigor score accordingly.

## Scoring Rules

- Each dimension: integer 1-10
- Final score: weighted average to one decimal
- **≥9.0** → PASS
- **8.5-8.9** → Declare each objection as BLOCKING or COSMETIC. All cosmetic → CONDITIONAL PASS. Any blocking → FAIL.
- **7.0-8.4** → FAIL with objections and suggested fixes
- **<7.0** → FAIL + ESCALATE (fundamentally wrong)
- Every dimension <9 requires a written objection with a concrete suggested fix
- Max 3 rounds. Each resubmission must address or contest every blocking objection.

## Contestation

If the implementing agent contests an objection with evidence (spec reference, test result, scan data):
- Evaluate the evidence
- **Accept** → revise objection, adjust score
- **Maintain** → restate why evidence is insufficient
- One contest per objection. Deadlock → escalate to Head of CoE.

## Reduced Scope

For **non-deliverable changes** (config-only, documentation-only): skip dimensional scoring. Confirm correctness and alignment in one sentence. Verdict: PASS or FAIL only.

## Output Format

```json
{
  "peer_review": {
    "spec_version": "1.0",
    "round": 1,
    "score": 0.0,
    "verdict": "pass | conditional_pass | fail | escalate",
    "persona": "PE | Head of CoE | PE + Head of CoE",
    "dimensions": {
      "impact_on_value_delivery": 0,
      "accuracy_and_trustworthiness": 0,
      "actionability": 0,
      "safety_and_rigor": 0,
      "alignment_with_model_vision": 0
    },
    "upstream_checkpoints": {
      "design": "passed | skipped — [reason] | not applicable",
      "implementation": "passed | skipped — [reason] | not applicable"
    },
    "missed_checkpoints": [],
    "blocking_objections": [],
    "cosmetic_objections": [],
    "resolved_objections": []
  }
}
```

For each objection (blocking or cosmetic), include:
- Which dimension it affects
- What the specific problem is
- A concrete suggested fix

## Limitations

You are an AI reviewing AI-generated work via persona-switching. You are effective at catching mechanical errors, enforcing checklists, and detecting consistency violations. You are NOT a substitute for human judgment on novel model decisions, strategic framing, or understanding how teams actually work. The Head of CoE escalation path is the true quality gate for judgment calls.
```

Save this file to `skills/peer-review/prompts/checkpoint-output.md`.

- [ ] **Step 2: Commit**

```bash
git add skills/peer-review/prompts/checkpoint-output.md
git commit -m "feat: add checkpoint 3 (output) scored reviewer prompt with rubric and JSON schema"
```

---

### Task 5: Add the Peer Review Gate directive to CLAUDE.md

**Files:**
- Modify: `CLAUDE.md:113-122` (Agent Instructions section)

- [ ] **Step 1: Add the directive after instruction 9**

Insert the following after the existing "9. **When unsure, ask.**" line (line 122) in the Agent Instructions section:

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

Skipped checkpoints are audited at checkpoint 3. See `skills/peer-review/SKILL.md` for the
full rubric, personas, escalation rules, and context requirements.
```

- [ ] **Step 2: Verify the directive is in place**

Run: `grep -A 2 "Peer Review Gate" CLAUDE.md`
Expected: Shows "All work must pass peer review before delivery."

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "feat: add mandatory peer review gate directive to CLAUDE.md"
```

---

### Task 6: Create the escalations directory

**Files:**
- Create: `docs/escalations/.gitkeep`

- [ ] **Step 1: Create the directory with .gitkeep**

```bash
mkdir -p docs/escalations && touch docs/escalations/.gitkeep
```

- [ ] **Step 2: Commit**

```bash
git add docs/escalations/.gitkeep
git commit -m "chore: add escalations directory for peer review gate"
```

---

### Task 7: Verify end-to-end

- [ ] **Step 1: Verify all skill files exist**

Run: `find skills/peer-review -type f | sort`
Expected:
```
skills/peer-review/SKILL.md
skills/peer-review/prompts/checkpoint-design.md
skills/peer-review/prompts/checkpoint-implementation.md
skills/peer-review/prompts/checkpoint-output.md
```

- [ ] **Step 2: Verify CLAUDE.md has the directive**

Run: `grep -c "Peer Review Gate" CLAUDE.md`
Expected: `1`

- [ ] **Step 3: Verify escalations directory exists**

Run: `ls docs/escalations/.gitkeep`
Expected: File exists

- [ ] **Step 4: Dry-run checkpoint 3 on the lace-platform report**

Dispatch a reviewer subagent with the checkpoint-output.md prompt and the existing lace-platform report to verify the skill works. The reviewer should:
- Read `skills/peer-review/prompts/checkpoint-output.md`
- Read `scans/ai-augmentation/results/lace-platform-report.md`
- Read `scans/ai-augmentation/results/lace-platform-report.json`
- Produce a scored JSON verdict

This validates the entire pipeline end-to-end.

- [ ] **Step 5: Update plan.md**

Add to `models/ai-augmentation-maturity/plan.md` Done section:
```
- [x] Peer review gate skill implemented — SKILL.md + 3 checkpoint prompts + CLAUDE.md directive
```
