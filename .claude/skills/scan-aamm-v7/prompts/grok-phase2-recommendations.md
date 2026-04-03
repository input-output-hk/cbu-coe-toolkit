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
