# ADR-019: AAMM v5 Answers the Wrong Question

**Date:** 2026-03-28 · **Status:** Accepted
**Applies to:** `models/ai-augmentation-maturity/scoring-model.md`, `spec.md`, `changelog.md`, scan skill
**Triggers:** Redesign of readiness rubric and adoption zones for AAMM v6

## Rule

AAMM v5 conflates general software engineering maturity with AI readiness, and treats all AI adoption as equivalent to code generation risk. AAMM v6 must be built around a use-case spectrum: different AI applications (documentation, debugging, analysis, code generation) have different risk profiles and different enablement requirements. A high-assurance repo can have appropriate AI adoption — the question is *which use cases* and *with what guardrails*, not *whether AI is present at all*.

## Anti-patterns

- Treating "AI adoption" as synonymous with "AI writing production code"
- Measuring general engineering quality (CONTRIBUTING.md exists, tests pass CI) as a proxy for AI readiness — these are correlated but not the same thing
- Blocking AI adoption in high-assurance repos because code generation is risky — debugging, documentation, analysis, and corner-case exploration are low-risk and high-value in exactly these environments
- A single risk flag for "AI present without guardrails" that doesn't distinguish between: AI that wrote a PR description vs. AI that modified cryptographic primitives
- Treating absence of `.aiignore` as HIGH risk on a repo where AI has touched only test and documentation files
- Building a rubric of 25 criteria where 24 are not AI-specific, then calling the result "AI Readiness"

## Context

### What v5 implicitly asks

> "Is this a well-engineered repo?"

This is operationalized as: module boundaries defined, reproducible build, CI active, doc comments present, README exists, ADRs present, CONTRIBUTING.md exists, tests block merge, etc.

These are valid engineering quality signals. They are weakly correlated with AI readiness — a well-organized codebase is easier for an AI to navigate. But the correlation is not strong enough to justify calling the measurement "AI readiness."

A repo from 2015 with no AI usage history could score HIGH readiness under v5. A repo where the team uses AI daily for debugging complex state transitions would score the same as one where no one has opened a Claude window.

### What v5 gets wrong about adoption

The adoption zones (Code, Testing, Security, Product & Delivery, Governance & Architecture) all use the same 3-criterion structure:
1. Does an AI config file reference this use case? (AC1/AT1/AS1/APD1/AGA1)
2. Is there evidence of AI being used? (AC2/AT2/AS2/APD2/AGA2)
3. Is there tooling for this? (AC3/AT3/AS3/APD3/AGA3)

This scores artifact existence, not use-case appropriateness. A team that writes excellent PR descriptions with AI assistance but has no config file scores lower than a team that has a CLAUDE.md but never uses AI. The model cannot distinguish between:
- AI used to find corner cases in QuickCheck property tests (low risk, high value)
- AI used to generate consensus logic (high risk, variable value)

Both would produce the same AT2=YES signal.

### What the correct framing looks like

AI adoption in high-assurance repos is not just possible — it is appropriate for a significant portion of the SDLC. The risk is concentrated in specific use cases, not distributed uniformly:

| Use case | Risk profile | Value in high-assurance repos |
|---|---|---|
| Documentation (Haddock, README, ADRs) | Very low | High — domain docs are expensive to write |
| PR titles, commit messages, descriptions | Very low | High — saves time, improves consistency |
| Debug assistance for complex scenarios | Low | Very high — expert-level reasoning on state traces |
| Thread / concurrency analysis | Low | Very high — hard problems, AI augments human review |
| Corner case / edge case discovery in test models | Low | Very high — QuickCheck generators benefit directly |
| Code review / understanding unfamiliar code | Low | High — accelerates onboarding and cross-era work |
| Test generation for non-critical modules | Medium | Medium |
| Code generation for non-critical paths | Medium | Medium |
| Code generation for security-critical paths | High | Requires explicit guardrails, human review mandatory |
| Architecture decisions | Medium | Requires explicit human confirmation |

AAMM v5 has no way to represent this table. It produces a single binary: AI is being used or it isn't. This is not useful for a financial ledger where AI should absolutely be used for documentation and debugging but should have guardrails on cryptographic module changes.

### Implication for the cardano-ledger scan (2026-03-28)

Under v5, cardano-ledger scores:
- Readiness HIGH — because it is a well-engineered repo (correct assessment, wrong label)
- Risk flag HIGH severity for "missing trust boundaries" — because 2 Claude commits exist and no `.aiignore` is present

The risk flag is miscalibrated. Those 2 commits exclusively modified test and spec conformance files (HuddleSpec.hs, CddlSpec.hs) — the lowest-risk category in the table above. HIGH severity for this exposure level is disproportionate and will likely cause the recommendation to be dismissed by the team.

Under a corrected model: the team would get credit for using AI in an appropriate use case (test conformance), and the risk flag would be calibrated to the actual exposure (AI has not touched cryptographic or consensus paths).

## Consequences

**Implemented in v6 (2026-03-30):**
- 25-criterion fixed rubric replaced by KB-driven, per-use-case assessment (5 components: Opportunity Map, Adoption State, Readiness per Use Case, Risk Surface, Recommendations)
- Adoption zones replaced by per-opportunity Adoption State (Active / Partial / Absent)
- Risk assessment is use-case-specific: Risk Surface mapped to concrete code paths with AI exposure calibration
- Two adversarial review stages: Stage A (opportunity map) + Stage B (recommendations)
- Fully autonomous scan — no mid-scan gates. Report is official at completion; CoE challenges post-publication.
- Scored Governance component replaced by Ad-hoc AI Usage flag (measures outcomes, not mechanisms — ADR-011)
- Team Capability component removed — replaced by recommended learning per recommendation

**Preserves:**
- Adversarial review mechanism (ADR-012) — now two-stage, not one
- Scan-from-zero rule — KB reused, prior results not consulted before assessment
- KB/ecosystem pattern approach — patterns now include opportunity patterns + readiness criteria per use-case type
- Output format (report.md + assessment.json + detailed-log.md)
- Leveled indicators (not numeric scores)
- Fully autonomous scan execution (v5 principle, briefly violated in early v6 draft with human gates, restored)

**Compatibility:** Scans produced under v5 are a "legacy baseline." Internally comparable to each other but not to v6. `schema_version` in assessment.json distinguishes them. First v6 scan is the new baseline.
