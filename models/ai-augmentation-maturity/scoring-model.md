# AAMM v6 — Scoring Model

> **This file is the operational manual for the AAMM v6 scanner agent.**
> Read this file at scan time. Follow it step by step. Do not improvise.
>
> For design rationale: see [spec.md](spec.md).
> For KB patterns and criteria: see [knowledge-base/](knowledge-base/).
> For scan skill: see [scan-aamm-v6 skill](../../.claude/skills/scan-aamm-v6/SKILL.md).

---

## How to Read This File

You are an AI agent running an AAMM v6 scan. This file tells you:
1. What data to collect (Section 1)
2. How to generate the Opportunity Map (Section 2)
3. How to assess Adoption, Readiness, and Risk (Section 3)
4. How to generate Recommendations (Section 4)
5. Rules you cannot break (Section 5)
6. Output format (Section 6)

Adversarial reviews (Stage A and Stage B) are handled by separate agent invocations. You do not run them yourself — the scan skill orchestrates them. But you must produce output that can withstand them.

---

## 1. Data Collection

Collect all of the following before any assessment begins. Do not assess while collecting — collect first, assess after.

### Required data

| Data | Source | Notes |
|------|--------|-------|
| File tree (full) | GitHub API: repo contents / git ls-tree | Needed for: module structure, test directories, config files, documentation density |
| Key file contents | GitHub API: file contents | Read: README.md, CLAUDE.md, CONTRIBUTING.md, .aiignore, CI workflow files, package manifests, AI config files (.cursorrules, .mcp.json, AGENTS.md, copilot-instructions.md). If a file doesn't exist, record its absence — that's data too. |
| Git history summary | GitHub API: commits (last 100) | Extract: commit authors, co-authored-by trailers, AI attribution patterns, files changed per commit, commit frequency |
| High-churn modules | Derived from git history | For each file changed in the last 100 commits, strip the filename and take the parent directory. Exclude root-level files (files with no parent directory — e.g., `README.md`, `flake.nix`). Count how many times each directory appears. Top 10 directories by count = active development areas. Example: `eras/conway/impl/src/Cardano/Ledger/Conway/Rules/Gov.hs` → increment `eras/conway/impl/src/Cardano/Ledger/Conway/Rules`. |
| PR data | GitHub API: PRs (last 30 merged) | Extract: review counts, CI check status, AI bot activity, PR descriptions |
| CI configuration | Workflow YAML files | Extract: test steps, linter steps, security scanning, AI tools in CI |
| Ecosystem detection | Package manifests + file extensions | Primary ecosystem determines which KB patterns to load |

### What NOT to collect

- File contents beyond key files (don't read every source file — use tree structure and git history for module-level understanding)
- Issues (too noisy, low signal for AI opportunity assessment)
- Deployment config (out of scope — AAMM assesses development practices, not operations)

---

## 2. Opportunity Map Generation

### Input

1. **KB opportunity patterns** for the detected ecosystem (from `knowledge-base/ecosystems/{ecosystem}.md`)
2. **KB cross-cutting patterns** (from `knowledge-base/cross-cutting.md`)
3. **Repo data** collected in Section 1

### Process

For each KB pattern, check its `applies_when` conditions against the repo data:

1. **Match conditions:** Do the pattern's `applies_when` conditions match this repo? Check each condition against file tree, git history, CI config, key file contents.
2. **Find evidence:** If conditions match, locate the specific repo artifacts that demonstrate the match. Use the pattern's `evidence_to_look_for` as a guide.
3. **Assess value and effort:** Use the pattern's base `value` and `effort`, adjusted for this repo's context. A pattern marked "HIGH value for property-test-heavy repos" is HIGH only if this repo is property-test-heavy. State the adjustment reasoning.
4. **Check for cross-portfolio references:** If the pattern's `seen_in` includes repos in this portfolio, cite the reference. This is evidence the pattern works in a similar context.

Also look for opportunities NOT in the KB:
- Gaps visible from repo structure that no KB pattern covers (e.g., a module with complex logic, no tests, and high churn — even if no KB pattern specifically addresses this)
- These are flagged as `kb_pattern: null` and noted as candidates for KB expansion

### Output

Produce opportunities ordered by **ROI descending**.

**ROI calculation:**

| Category | Numeric value |
|----------|--------------|
| HIGH value | 3 |
| MEDIUM value | 2 |
| LOW value | 1 |
| Low effort | 3 (easy = high ROI) |
| Medium effort | 2 |
| High effort | 1 (hard = low ROI) |

`ROI = value_numeric × effort_numeric` — range 1–9. Rank by ROI descending. Ties broken by value (higher value wins).

Each opportunity must have ALL of these fields (schema: `$defs.opportunity` in `schema/assessment-v6.schema.json`):
```
id:          hash(repo_slug + kb_pattern_id) for KB-derived; hash(repo_slug + normalized_title) for novel
title:       specific action — "Use AI for corner case discovery in Conway era ledger rules" not "AI for testing"
value:       HIGH / MEDIUM / LOW — with one-line justification referencing this repo
effort:      High / Medium / Low — with one-line justification
roi_rank:    1 = highest ROI
evidence:    specific file paths, commit SHAs, CI config lines from THIS repo
kb_pattern:  KB pattern ID or null if novel
seen_in:     [{repo, outcome}] from KB or empty
```

**Self-check before proceeding:** For each opportunity, ask: "Would this identical opportunity appear on any other repo in this ecosystem?" If yes, it's too generic — make it specific or drop it. Stage A will reject it anyway.

### Minimum quality bar

- Minimum 3 opportunities (if the repo has fewer than 3 real opportunities, explain why in the report)
- No upper limit — produce what the evidence supports
- Every opportunity must cite at least one specific file path or commit SHA from this repo
- No opportunity can be a restatement of a KB pattern without repo-specific evidence

---

## 3. Component Assessment

After Stage A filters the Opportunity Map, assess the remaining approved opportunities.

### 3.1 Adoption State

For each approved opportunity, determine: **Active** / **Partial** / **Absent**

| State | Definition | Evidence required |
|-------|-----------|-------------------|
| **Active** | Regular AI-attributed activity in this area within the last 90 days | ≥3 AI-attributed commits touching relevant files, OR AI config explicitly references this use case with evidence of use |
| **Partial** | Some evidence but not systematic | 1-2 AI-attributed commits, or one-off usage pattern, or AI config references the area but no commit evidence |
| **Absent** | No positive evidence | No AI attribution in relevant files, no AI config referencing this area |

**Detection methods for AI attribution:**
- `Co-authored-by:` trailers mentioning Claude, Copilot, Cursor, Gemini, or other AI tools
- Bot-authored PRs (copilot[bot], coderabbit-ai[bot], etc.)
- AI CI actions in workflow YAML
- AI config files (CLAUDE.md, .cursorrules, etc.) referencing specific use cases

**Do not infer.** Absence of attribution means absence of observable signal, not absence of AI use. State this explicitly when recording Absent.

### 3.2 Readiness per Use Case

For each approved opportunity, assess readiness using **KB criteria only**.

**Step 1:** Look up the opportunity's use-case type in the KB (`knowledge-base/` readiness criteria for that use-case type).

**Step 2:** If KB criteria exist — evaluate each criterion:
- Check: execute the criterion's `check` instruction against repo data
- Result: YES / NO
- Confidence: based on evidence type (Objective → HIGH ceiling, Semi-objective → MEDIUM, Subjective → LOW)
- Evidence: cite the specific file/config/commit that proves or disproves the criterion

**Step 3:** Determine level from criteria results:

| Level | Criteria met |
|-------|-------------|
| ⬜ Undiscovered | <50% of criteria met |
| 🟡 Exploring | 50-74% of criteria met |
| 🟢 Practiced | ≥75% of criteria met |
| 💎 Mastered | Agent cannot assign. Flag as candidate if 100% met + practices well-documented. CoE confirms. |

**If KB has no readiness criteria for this use-case type:** Mark readiness as **Not Assessable**. Record reason: "No KB criteria for use-case type: {type}." The opportunity still appears in the report with Adoption State and in Recommendations. It is excluded from Quadrant computation.

**Risky Acceleration flag:** If Adoption State = Active AND Readiness = Undiscovered for any opportunity → flag it. This appears in the executive summary.

### 3.3 Risk Surface

Map AI risk to **concrete code paths**, not the repo as a whole.

**Step 1 — Identify risk-relevant paths:**
From git history and file tree, identify modules/directories that are:
- Security-sensitive: directory or file names containing `crypto`, `auth`, `consensus`, `signing`, `keys`, `Rules`, `protocol`, or identified as security-critical in CLAUDE.md/.aiignore
- High-complexity: directories with ≥5 cross-imports from other packages (infer from file tree + package manifests), or directories that appear in ≥3 high-churn modules
- Low-test-coverage: source directories where no test files reference or exercise code in this path. Detection: search all test directories in the repo (`test/`, `tests/`, `testlib/`, `__tests__/`, `spec/`) for imports or references to modules in this path. If none found → low coverage. If test files exist but only cover a subset → note partial coverage.

**Step 2 — Check AI exposure per path:**

| AI exposure | Evidence | Classification |
|-------------|----------|---------------|
| **Confirmed** | AI-attributed commits touching files in this path | Active risk |
| **Potential** | AI config exists but no AI commits in this path | Preventive note |
| **None** | No AI config, no AI commits near this path | No flag |

**Step 3 — Assess two dimensions per risk path:**

| Dimension | HIGH | MEDIUM | LOW |
|-----------|------|--------|-----|
| **Detection difficulty** | No test directory for this path; no CI step targeting it | Test directory exists but no property tests (only unit tests or no `Arbitrary`/`Gen` files) | Property tests, formal verification, CDDL conformance tests, or conformance test modules exist for this path |
| **Blast radius** | Path names match security-sensitive patterns (consensus, crypto, financial state, serialization); or path is imported by ≥5 other packages | API contracts, data migration, auth flows; or path is imported by 2–4 other packages | Presentation, documentation, non-critical utilities; or path has ≤1 downstream import |

**Calibration rules:**
- AI commits touching test files only → flag test paths, not source paths
- No AI commits but AI config present → "Potential" exposure, preventive note only
- AI commits touching critical paths without mandatory review evidence → HIGH severity flag

**Step 4 — Intersect with Opportunity Map:**
For each approved opportunity, infer which code paths it would touch if adopted. This mapping is **inferential** (MEDIUM confidence ceiling). State explicitly: "This opportunity intersects with risk paths [list] — confidence: MEDIUM (inferred)."

### 3.4 Ad-hoc AI Usage Flag

Check: Are AI-attributed commits present across multiple areas AND are there zero intentionality signals?

**Intentionality signals** (any one is sufficient to NOT trigger the flag):
- CLAUDE.md or equivalent AI config with substantive content (not just a filename)
- .aiignore with meaningful paths
- AI policy section in CONTRIBUTING.md
- Consistent attribution pattern (>50% of AI-detectable commits have Co-authored-by)

**If flag triggers:** Record in the report: "AI is in active use across [areas] but no intentionality signals were detected. This is an observation, not a judgment — governance practices may exist outside the repo."

---

## 4. Recommendation Generation

### Input

- Approved Opportunity Map (post-Stage A)
- Adoption State per opportunity
- Readiness per opportunity
- Risk Surface

### Process

For each approved opportunity, determine recommendation type:

| Adoption | Readiness | Type | Framing |
|----------|-----------|------|---------|
| Absent | Practiced or Exploring | **Start now** | "Everything is in place. The gap is activation, not preparation." |
| Absent | Undiscovered | **Foundation first** | "Before adopting X, set up Y — it's the prerequisite." |
| Active or Partial | Undiscovered or Exploring | **Fix the foundation** | "You're using X but the setup doesn't support it safely." |
| Active | Practiced | No recommendation needed | Note in report: "Active and well-supported — continue." |
| Any | Not Assessable | **KB gap** | "Readiness cannot be assessed — KB criteria needed for this use-case type." |

### Output

Recommendations ordered by **ROI descending**.

**Recommendation ROI calculation:**

| Adoption gap | Numeric value |
|-------------|--------------|
| Absent | 3 (largest gap = highest priority) |
| Partial | 2 |
| Active | 1 |

`Recommendation ROI = impact_numeric × effort_numeric × gap_numeric` — using the same value/effort mapping as opportunity ROI (Section 2). Range 1–27. Rank descending. Ties broken by impact (higher wins).

Recommendation #1 is the highest-ROI action. If the team reads nothing else, they read #1.

Each recommendation must have ALL fields (schema: `$defs.recommendation` in `schema/assessment-v6.schema.json`):
```
id:                    hash(repo_slug + opportunity_id + type)
title:                 specific action — not generic advice
type:                  start_now / foundation_first / fix_the_foundation / kb_gap
effort:                Low / Medium / High
impact:                HIGH / MEDIUM / LOW
opportunity_id:        linked opportunity
measurable_outcome:    "done when X is true" — must be verifiable from repo data
recommended_learning:  from KB learning_entry for this use-case; what the team needs
                       to know to execute this recommendation (concrete, not generic)
kb_ref:                KB pattern reference or null
```

**Measurability rule:** Every `measurable_outcome` must be checkable by an agent at the next scan. "Code quality improves" is not measurable. "test/Conway/CertSpec.hs exists with ≥5 property tests covering delegation invariants" is measurable.

**Self-check before proceeding:** For each recommendation, ask:
1. "Can a tech lead put this in the team backlog tomorrow with a clear owner and scope?" If no → too vague.
2. "Is this specific to this team, or would it appear on any report?" If any report → too generic.
3. "Can I verify the measurable outcome from repo data?" If no → fix the outcome.

Stage B will test all three. Fix them now.

---

## 5. Rules You Cannot Break

### Read-only — non-negotiable
AAMM is strictly read-only on scanned repositories. You MUST NOT:
- Create PRs, commits, issues, or comments in the target repo
- Push branches, tags, or any data to the target repo
- Post reviews, reactions, or labels on the target repo's PRs/issues
- Write to any repository other than `cbu-coe-toolkit`

All scan output (reports, assessments, KB proposals) is written to `cbu-coe-toolkit/scans/` only. The GitHub API is used exclusively with read scope. If a token has write permissions, you still MUST NOT use them.

### Grounding rule
Every finding MUST cite: file path + content excerpt, OR commit SHA + relevant diff, OR API response excerpt.

Example: "CLAUDE.md covers architecture and testing but not security boundaries [CLAUDE.md:L12-L45: '## Architecture\nThe repo follows...' but no Security section]"

Ungrounded findings are automatically LOW confidence.

### Confidence ceilings

| Evidence type | Examples | Confidence ceiling |
|---------------|---------|-------------------|
| **Objective** | File exists, config parsed, count verified, attribution confirmed in commit | HIGH |
| **Semi-objective** | Content matches expected structure, pattern detected, churn inferred from git log | MEDIUM |
| **Subjective** | Quality judgment, effort estimate | LOW |

**You CANNOT self-assign HIGH confidence on subjective evaluations.** Non-negotiable.

### Scan-from-zero

**Phase 1 (assessment):** You read KB + current repo data ONLY. You do NOT read previous scan results. Your assessment is completed and frozen before Phase 2.

**Phase 2 (delta):** AFTER Phase 1 is frozen, you read the previous `assessment.json` (if it exists) and compute delta MECHANICALLY:
- Opportunity IDs: which are new, which are discontinued, which persist
- Readiness levels: which changed, which held
- Adoption states: which changed
- Recommendation statuses: which were verified, which remain open

Delta goes into the Evolution section of report.md. It does NOT alter any Phase 1 output. If you notice something in the previous scan that contradicts your current assessment, your current assessment stands — note the discrepancy in Evolution, do not change your findings.

### No improvisation
- Readiness criteria come from KB only. Do not invent criteria.
- If KB has no criteria for a use-case type, mark "Not Assessable." Do not fill the gap with ad-hoc checks.
- If KB has no opportunity patterns for this ecosystem, use cross-cutting only and mark the limitation.

### No judgment of teams
- AAMM informs and recommends. It does not evaluate team competence.
- "Absent" means no observable signal, not "the team isn't doing this."
- "Undiscovered" means the repo lacks prerequisites, not "the team is behind."
- Frame everything as: "here is the state → here is the opportunity → here is what to do next."

### ROI ordering
- Opportunities: ordered by ROI descending (value × 1/effort)
- Recommendations: ordered by ROI descending (value × 1/effort × adoption gap size)
- #1 is always the highest-ROI item. If the reader reads nothing else, they read #1.

---

## 6. Output Format

### report.md (team-facing)

Section order is fixed. Do not rearrange.

```markdown
# AAMM Report: {owner}/{repo}
> Scan date: {YYYY-MM-DD} | Ecosystem: {ecosystem} | Schema: v6.0

## Executive Summary
<!-- First 15 lines. Everything a tech lead needs. -->
**Top opportunities** (ROI-ordered):
1. {title} — {value} value, {effort} effort
2. ...
3. ...

**Top recommendations** (ROI-ordered):
1. {title} — {type}
2. ...
3. ...

**Risk flags:**
- {Risky Acceleration flags, if any}
- {Ad-hoc AI Usage flag, if triggered}

**Quadrant:** {position label}

## Opportunity Map
<!-- Per opportunity: id, title, value, effort, evidence, kb_pattern, seen_in -->

## Risk Surface
<!-- Per risk path: path, detection difficulty, blast radius, AI exposure, evidence -->
<!-- Opportunity-risk intersections with confidence noted -->

## Recommendations
<!-- Per recommendation: all fields from Section 4 output -->

## Adoption State
<!-- Per opportunity: state + evidence -->

## Readiness per Use Case
<!-- Per opportunity: level + criteria results + confidence -->

## Evolution
<!-- Delta vs previous scan. "First assessment" if no previous. -->
<!-- v5 history: include as context, do not compute delta -->

## Evidence Log
<!-- Files read, API calls, confidence per finding, adversarial outcomes -->
```

### assessment.json (structured data)

Schema version 6.0. Full schema in spec.md Section 6.

Key fields:
- `schema_version: "6.0"`
- `scan_type: "scoring"` or `"learning"`
- `opportunity_map[]` — all opportunities (approved + rejected, with adversarial_status)
- `adoption_state[]` — per approved opportunity
- `readiness[]` — per approved opportunity, with criteria_results
- `risk_surface[]` — per risk path
- `recommendations[]` — all recommendations (approved + rejected, with adversarial_status)
- `flags.risky_acceleration[]` — opportunity IDs with Active + Undiscovered
- `flags.adhoc_usage` — boolean
- `quadrant` — ai_potential, ai_activity, position

### detailed-log.md (audit trail)

Everything:
- API calls made (endpoints, parameters, response summaries)
- Files read with relevant excerpts
- KB patterns matched and not matched, with reasoning
- Opportunity generation reasoning per opportunity
- Adversarial Stage A dialogue (full)
- Component assessment reasoning (adoption, readiness, risk per opportunity)
- Recommendation generation reasoning
- Adversarial Stage B dialogue (full)
- Rejected opportunities: what + why
- Rejected recommendations: what + why
- Any anomalies, limitations, or uncertainties encountered

### Output location

```
scans/ai-augmentation/results/YYYY-MM-DD/OWNER--REPO/
├── report.md
├── assessment.json
└── detailed-log.md
```

For learning scans, output is:
```
scans/ai-augmentation/results/YYYY-MM-DD/OWNER--REPO/
└── kb-proposals.md
```

KB update proposals from scoring scans:
```
scans/ai-augmentation/results/YYYY-MM-DD/kb-updates.md
```
