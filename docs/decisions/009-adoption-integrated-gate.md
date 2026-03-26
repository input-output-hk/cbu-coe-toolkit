# ADR-009: Adoption Integrated Stage — Branch Protection Gate

**Date:** 2026-03-26 · **Status:** Accepted
**Applies to:** `scripts/aamm/score-adoption.sh`, `models/ai-augmentation-maturity/adoption-scoring.md`

## Rule

The Integrated adoption stage requires that the branch protection API returns a non-404 response. When branch protection returns 404 (org-level GitHub Rulesets, insufficient token scope, or genuinely absent), AI-in-CI candidates are downgraded to Active.

```
AI workflow detected in repo + branch protection accessible (non-404) → Integrated eligible
AI workflow detected in repo + branch protection 404                  → Active (cap)
No AI workflow detected                                                → Configured or lower
```

"AI workflow detected" means a workflow file contains `claude-code-action`, `copilot`, `coderabbit`, `ai-review`, `ai-check`, `ai-test`, or `ai-security`. Generic mentions of "claude" (e.g., documentation) do not trigger this — use `claude-code-action` specifically.

## Anti-patterns

- Do NOT award Integrated based on AI tool presence in a workflow alone — a read-only AI reviewer (e.g., `claude.yml` with `permissions: pull-requests: read`) reviews PRs but does not gate merges.
- Do NOT infer blocking from workflow permissions — write permissions allow commenting/modifying, not necessarily blocking. Branch protection is the authoritative signal.
- Do NOT penalise repos that are Active for not being Integrated — Active is a strong, positive stage. The distinction is precision, not judgment.

## Context

lace-platform scored Integrated (100) on Code, Testing, Delivery, and Governance because `claude.yml` was detected in the workflow tree. Adversarial review found: `claude.yml` has `permissions: pull-requests: read, contents: read` — it can comment on PRs but cannot block merges. Without confirmed branch protection (all three IOG repos returned 404), the claim that AI "gates merges" cannot be substantiated.

Branch protection 404 is ambiguous: it can mean no protection, org-level GitHub Ruleset (invisible to the repo API endpoint), or insufficient token scope. All sampled PRs across mithril, cardano-node, and lace-platform had ≥1 review (0 unreviewed of 200+ checked), suggesting protection exists somewhere. Until a reliable signal distinguishes "no protection" from "org-level protection", the conservative default is Active.

Corrected lace-platform Adoption: 80.00 → 52.80 (Code/Testing/Delivery/Governance all 100 → 66).

## Consequences

- **Changed:** `score-adoption.sh` — `HAS_AI_IN_CI` is now a two-step check: candidate detection + BP confirmation
- **Adoption impact:** Any repo with AI workflows but 404 branch protection will be capped at Active going forward. This affects all IOG repos until BP becomes accessible.
- **Must maintain:** The `claude-code-action` keyword (not generic `claude`) is the AI-in-CI trigger. If Anthropic changes the action name, update the grep pattern.
- **Future:** If GitHub adds an org-level ruleset API endpoint, revisit this decision — Integrated may become reliably detectable for IOG repos without a token scope change.
