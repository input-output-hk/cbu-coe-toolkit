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
          "scenario": "string — specific failure scenario: When X happens, Y fails because Z",
          "detection_difficulty": "HIGH|MEDIUM|LOW",
          "blast_radius": "HIGH|MEDIUM|LOW",
          "ai_exposure": "confirmed|potential|none",
          "evidence": "string — file:line or commit SHA"
        }
      ]
    }
  ]
}
```

Output JSON only.
