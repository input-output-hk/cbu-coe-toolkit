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
| `README.md`, `adoption-scoring.md`, `readiness-scoring.md`, `backlog.md` decisions | **Head of CoE** |
| `scripts/aamm/*`, `collect-*.sh`, `score-*.sh`, `generate-report.sh` | **Principal Engineer (PE)** |
| `CLAUDE.md`, `config.yaml`, pipeline architecture | **Head of CoE** |
| Scan reports and recommendations | **Both** (PE on accuracy, Head of CoE on narrative) |
| Mixed (spec + script) | **Both, sequentially** |
| Everything else | **PE** (default) |

## How to Invoke

1. **Determine checkpoint type** based on where you are in the workflow.
2. **Declare the artifacts** under review (file paths or deliverable description).
3. **Read the appropriate checkpoint prompt** from `.claude/skills/peer-review/prompts/checkpoint-{type}.md`.
4. **Dispatch a reviewer subagent** with the checkpoint prompt + required context (see Context Requirements below).
5. **Process the verdict:**
   - **Pass / Conditional pass** → proceed, log score in backlog.md or report
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
- Content of relevant spec files (README.md, scoring files)
- Related backlog.md items and prior decisions

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

Config-only changes (adding a repo to config.yaml) and documentation-only changes (learnings.md, backlog.md updates) get a pass/fail review without dimensional scoring at checkpoint 3. The reviewer confirms correctness and alignment in one sentence.

## Contestation

The implementing agent may contest an objection with evidence (spec reference, test result, scan data). The reviewer accepts or maintains. One contest per objection. Deadlock → escalate.

## Audit Trail

- **Scan reports:** Embed checkpoint 3 JSON in the "Principal Engineer Review" section
- **Code/spec changes:** Single line in backlog.md Done section: `Reviewed: X/10 (persona, round, objections)`
- **Failed reviews requiring iteration:** Lesson in `learnings.md`
