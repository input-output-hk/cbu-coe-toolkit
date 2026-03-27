# AAMM v5 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the v4 bash scoring pipeline with a single AI agent that assesses repos via rubric + depth methodology, produces ROI-prioritized recommendations, and maintains a cross-repo Knowledge Base.

**Architecture:** Single AI agent (Claude Code skill) reads repo data via GitHub API (`$GITHUB_TOKEN`), evaluates 5 readiness pillars and 5 adoption zones using structured rubrics, then a separate adversarial subagent challenges the assessment. Reports are markdown + JSON, stored in git.

**Spec:** `docs/superpowers/specs/2026-03-27-aamm-v5-spec.md`
**ADR:** `docs/decisions/018-aamm-v5-single-agent-architecture.md`
**Repo list:** `models/config.yaml` (29 repos, 4 orgs — source of truth)

---

## File Structure

### New files

```
kb/                                          # Knowledge Base root
├── README.md                                # KB format, lifecycle, consolidation rules
├── ecosystems/
│   ├── haskell.md                           # Haskell patterns (pre-seeded)
│   ├── typescript.md                        # TypeScript patterns (pre-seeded)
│   ├── rust.md                              # Rust patterns (pre-seeded)
│   └── python.md                            # Python patterns (pre-seeded)
├── cross-cutting.md                         # Universal patterns (pre-seeded)
└── anti-patterns.md                         # What doesn't work (pre-seeded)

.claude/skills/scan-aamm-v5/
├── SKILL.md                                 # Scanner skill (main entry point)
├── prompts/
│   ├── scanner-system.md                    # Full scanner prompt with all rubrics + rules
│   └── adversarial-system.md                # Adversarial agent prompt
└── schema/
    └── assessment-v5.schema.json            # JSON schema for assessment.json
```

### Files to modify

```
CLAUDE.md                                    # Full rewrite of AAMM sections for v5
scans/ai-augmentation/config.yaml            # Update to v5 format
```

### Files to archive

```
.claude/skills/scan-ai-augmentation/         → .claude/skills/scan-ai-augmentation-v4/
models/ai-augmentation-maturity/             # Add ARCHIVED header to each file
scripts/aamm/                                # Keep in place, reference as v4
```

---

## Task 1: Create Knowledge Base

**Files:**
- Create: `kb/README.md`, `kb/ecosystems/haskell.md`, `kb/ecosystems/typescript.md`, `kb/ecosystems/rust.md`, `kb/ecosystems/python.md`, `kb/cross-cutting.md`, `kb/anti-patterns.md`

- [ ] **Step 1: Create directories**

```bash
mkdir -p /home/devuser/repos/cbu-coe/cbu-coe-toolkit/kb/ecosystems
mkdir -p /home/devuser/repos/cbu-coe/cbu-coe-toolkit/kb/external
```

- [ ] **Step 2: Write kb/README.md — format, lifecycle, consolidation rules**

This file defines how the KB scales. Write `kb/README.md`:

```markdown
# AAMM Knowledge Base

Accumulated knowledge of the CoE — patterns, anti-patterns, and best practices
from IOG portfolio scans and external exemplary repos.

## Format

Each ecosystem file contains multiple patterns. Each pattern is a level-2 heading
with structured metadata in a fenced block:

    ## Pattern Title

    ```yaml
    source: iog-scan | external | ecosystem-standard
    repos: [cardano-ledger, ouroboros-consensus]
    category: structure | clarity | purpose | workflow | safety-net | adoption
    status: validated | proposed | needs-revalidation | deprecated
    discovered: 2026-03-27
    updated: 2026-03-27
    ```

    Description of the pattern with evidence.

    **Recommendation template:** "..."
    **Applicability:** Which repos/ecosystems this applies to.

## Lifecycle

1. Scanner agent proposes new patterns after each scan → `proposed`
2. CoE lead reviews → `proposed` → `validated`
3. Scanner re-validates on subsequent scans → stays `validated` or → `needs-revalidation`
4. External patterns expire after 6 months → `needs-revalidation`
5. CoE quarterly review cleans up → `deprecated` or re-validated

## Consolidation (quarterly)

KB files grow with each scan. Quarterly, CoE lead runs consolidation:

1. **Dedup:** Merge patterns that describe the same thing with different wording
2. **Validate:** Re-check `validated` patterns against current repo state
3. **Expire:** Mark `needs-revalidation` for patterns whose source repos changed
4. **Prune:** Move `deprecated` patterns to a `kb/archive/` directory
5. **Split:** If an ecosystem file exceeds 200 patterns, split by category
   (e.g., `haskell-testing.md`, `haskell-structure.md`)

## File Conventions

- `kb/ecosystems/{language}.md` — per-ecosystem patterns
- `kb/cross-cutting.md` — patterns that apply to all ecosystems
- `kb/anti-patterns.md` — things that don't work
- `kb/external/{repo-name}.md` — patterns from external exemplary repos
- `kb/archive/` — deprecated patterns (for history)
```

- [ ] **Step 3: Write kb/ecosystems/haskell.md**

Write `kb/ecosystems/haskell.md`:

```markdown
# Haskell Ecosystem Patterns

## Nix-wrapped CI hides tools from direct grep

```yaml
source: iog-scan
repos: [cardano-ledger, cardano-node, ouroboros-consensus]
category: structure
status: validated
discovered: 2026-03-26
updated: 2026-03-27
```

Haskell repos run hlint/fourmolu via `nix develop --command`. CI enforcement
checks must match `nix develop|nix build|nix flake check` patterns, not just
direct tool names. `flake.nix` is a first-class detection surface.

**Applicability:** All Haskell repos using Nix.

## QuickCheck property tests for state machine correctness

```yaml
source: iog-scan
repos: [cardano-ledger, plutus]
category: safety-net
status: validated
discovered: 2026-03-20
updated: 2026-03-27
```

Repos with QuickCheck generators per module have stronger boundary test
coverage. Pattern: `Gen*.hs` + `Arbitrary` instances per data type.

**Recommendation template:**
"Add QuickCheck generators for [module]. Start with Arbitrary instances
for your core data types. Effort: 🟢 Low (days). Impact: HIGH."

**Applicability:** Haskell repos with algebraic data types at module boundaries.

## Haddock documentation coverage

```yaml
source: iog-scan
repos: [cardano-ledger, ouroboros-consensus]
category: clarity
status: validated
discovered: 2026-03-26
updated: 2026-03-27
```

Haddock `-- |` and `{- | -}` on exported functions. Sample source files
for doc comment density. cardano-ledger: 45.8% coverage across 38 packages.

**Applicability:** All Haskell repos.

## cabal multi-package as module boundary signal

```yaml
source: iog-scan
repos: [cardano-ledger]
category: structure
status: validated
discovered: 2026-03-20
updated: 2026-03-27
```

`cabal.project` with `packages:` listing multiple paths. cardano-ledger
has 38 packages with explicit boundaries.

**Applicability:** Haskell repos with multiple libraries.

## HLint + fourmolu as standard tooling

```yaml
source: ecosystem-standard
repos: []
category: structure
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

HLint for linting, fourmolu (or ormolu/stylish-haskell) for formatting.
Detection: `.hlint.yaml`, or `hlint`/`fourmolu` in `flake.nix` or CI.

**Applicability:** All Haskell repos.
```

- [ ] **Step 4: Write kb/ecosystems/typescript.md**

Write `kb/ecosystems/typescript.md`:

```markdown
# TypeScript Ecosystem Patterns

## strict mode as baseline type safety

```yaml
source: ecosystem-standard
repos: []
category: clarity
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

`tsconfig.json` with `"strict": true`. Detection: parse compilerOptions.

**Applicability:** All TypeScript repos.

## Contract packages as boundary definitions

```yaml
source: iog-scan
repos: [lace-platform]
category: clarity
status: validated
discovered: 2026-03-26
updated: 2026-03-27
```

`packages/contract/` packages define typed interfaces at module boundaries.
lace-platform has 30+ contract packages. Functionally equivalent to schema
definitions but not detected by .proto/.graphql search.

**Recommendation template:**
"Define typed interfaces in dedicated contract packages. Effort: 🟡 Medium. Impact: HIGH."

**Applicability:** TypeScript monorepos.

## NX/pnpm workspaces for monorepo structure

```yaml
source: ecosystem-standard
repos: [lace-platform]
category: structure
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

pnpm-workspace.yaml or nx.json. Note: `npm run check:format` and
`npx nx affected --target=lint` don't contain tool names directly.

**Applicability:** TypeScript monorepos.

## ESLint + Prettier as standard tooling

```yaml
source: ecosystem-standard
repos: []
category: structure
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

ESLint (including naming-convention rules), Prettier for formatting.
Detection: `.eslintrc.*`, `.prettierrc.*`, or config in package.json.

**Applicability:** All TypeScript repos.
```

- [ ] **Step 5: Write kb/ecosystems/rust.md**

Write `kb/ecosystems/rust.md`:

```markdown
# Rust Ecosystem Patterns

## Inline test modules invisible to file-count ratio

```yaml
source: iog-scan
repos: [mithril]
category: safety-net
status: validated
discovered: 2026-03-26
updated: 2026-03-27
```

Rust `#[cfg(test)]` inline modules are invisible to file-based detection.
mithril: 53% of files had inline tests, 169+ `#[test]` not counted.
Depth must sample source files for `#[cfg(test)]` blocks.

**Applicability:** All Rust repos.

## clippy + rustfmt as standard tooling

```yaml
source: ecosystem-standard
repos: []
category: structure
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

Clippy (including `clippy::style`), rustfmt. Detection in CI or Makefile.

**Applicability:** All Rust repos.

## cargo-deny advisories vs licenses

```yaml
source: iog-scan
repos: [mithril]
category: safety-net
status: validated
discovered: 2026-03-26
updated: 2026-03-27
```

`cargo deny check advisories` = CVE scanning. `cargo deny check licenses` = NOT CVE scanning.
Only `check advisories` or bare `check` counts for security.

**Applicability:** All Rust repos using cargo-deny.
```

- [ ] **Step 6: Write kb/ecosystems/python.md**

Write `kb/ecosystems/python.md`:

```markdown
# Python Ecosystem Patterns

## mypy + ruff as modern tooling

```yaml
source: ecosystem-standard
repos: []
category: structure
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

mypy for type checking, ruff for linting + formatting (replaces flake8, black, isort).
Detection: `mypy` in pyproject.toml or mypy.ini, `ruff` in pyproject.toml or CI.

**Applicability:** All Python repos.

## pytest with conftest fixtures

```yaml
source: ecosystem-standard
repos: []
category: safety-net
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

`tests/` directory, `test_*.py` files, conftest.py for shared fixtures.
Property-based testing via `hypothesis`.

**Applicability:** All Python repos.
```

- [ ] **Step 7: Write kb/cross-cutting.md and kb/anti-patterns.md**

Write `kb/cross-cutting.md`:

```markdown
# Cross-Cutting Patterns

## CLAUDE.md content-category coverage

```yaml
source: iog-scan
repos: [lace-platform, cardano-ledger]
category: governance
status: validated
discovered: 2026-03-20
updated: 2026-03-27
```

Effective CLAUDE.md covers: architecture/module boundaries, coding conventions,
testing standards, security-critical areas, build commands, delivery workflow.
Generic CLAUDE.md without project context = minimal AI value.

**Recommendation template:**
"Your CLAUDE.md covers [N]/6 categories. Add: [missing]. Effort: 🟢 Low. Impact: HIGH."

**Applicability:** All repos with AI config.

## .aiignore on critical paths

```yaml
source: iog-scan
repos: []
category: workflow
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

High-assurance repos must define trust boundaries via .aiignore listing
critical paths (crypto/, signing/, formal-spec/, key-management/).

**Recommendation template:**
"Add .aiignore listing [critical paths]. Effort: 🟢 Low. Impact: HIGH."

**Applicability:** High-assurance repos.

## Undocumented workflow = AI cannot follow it

```yaml
source: iog-scan
repos: []
category: workflow
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

If PR process, branching strategy, and trust boundaries are not documented
(CONTRIBUTING.md, PR templates, CODEOWNERS), AI cannot respect them.

**Applicability:** All repos.
```

Write `kb/anti-patterns.md`:

```markdown
# Anti-Patterns

## Empty PR template placeholders are not AI signals

```yaml
source: iog-scan
repos: [lace-platform]
category: adoption-detection
status: validated
discovered: 2026-03-26
updated: 2026-03-27
```

`<!-- CURSOR_SUMMARY --><!-- /CURSOR_SUMMARY -->` without content = template marker,
not AI activity. Only content-filled markers count.

## Generic CLAUDE.md without trust boundaries

```yaml
source: iog-scan
repos: []
category: governance
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

"Use AI responsibly" without specific critical paths or module boundaries
= no operational guardrails.

## docs/ is NOT architecture documentation

```yaml
source: iog-scan
repos: [ouroboros-consensus]
category: purpose
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

docs/ commonly contains: agda-spec, formal-spec, haddocks, website.
Do not credit docs/ existence as ARCHITECTURE.md.
```

- [ ] **Step 8: Commit KB**

```bash
cd /home/devuser/repos/cbu-coe/cbu-coe-toolkit
git add kb/
git commit -m "feat: create AAMM v5 Knowledge Base with pre-seeded patterns

- KB README with format, lifecycle, consolidation rules
- 4 ecosystem files (Haskell, TypeScript, Rust, Python)
- Cross-cutting patterns and anti-patterns
- All entries validated from 9 sessions of operational experience
ADR-018"
```

---

## Task 2: Write Scanner Agent Skill

**Files:**
- Create: `.claude/skills/scan-aamm-v5/SKILL.md`
- Create: `.claude/skills/scan-aamm-v5/prompts/scanner-system.md`
- Create: `.claude/skills/scan-aamm-v5/prompts/adversarial-system.md`
- Create: `.claude/skills/scan-aamm-v5/schema/assessment-v5.schema.json`

- [ ] **Step 1: Create directories**

```bash
mkdir -p /home/devuser/repos/cbu-coe/cbu-coe-toolkit/.claude/skills/scan-aamm-v5/prompts
mkdir -p /home/devuser/repos/cbu-coe/cbu-coe-toolkit/.claude/skills/scan-aamm-v5/schema
```

- [ ] **Step 2: Write SKILL.md**

Write `.claude/skills/scan-aamm-v5/SKILL.md`:

```markdown
---
name: scan-aamm-v5
description: Run AAMM v5 scan — AI agent assesses repo readiness (5 pillars) and adoption (5 zones) via rubric + depth, produces ROI-prioritized recommendations with mandatory adversarial review.
---

# AAMM v5 Scan

## Input

Target repo is specified either as:
- **Single repo:** User provides `owner/repo` directly
- **From config:** User says "scan all" or "scan next" — read `models/config.yaml` for the tracked repo list. Each entry has `repo`, `language` (= ecosystem), and `project`.

Set variables from input:
```
OWNER=<org name from config or user input>
REPO=<repo name from config or user input>
ECOSYSTEM=<language field from config, lowercased: haskell|typescript|rust|python|lean|nix|shell>
```

## Prerequisites

```bash
source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null
if [ -z "$GITHUB_TOKEN" ]; then
  echo "FATAL: GITHUB_TOKEN not set. Cannot proceed."
  # STOP — do not continue
fi
# Verify token works
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  https://api.github.com/user)
if [ "$HTTP_CODE" != "200" ]; then
  echo "FATAL: GITHUB_TOKEN invalid (HTTP $HTTP_CODE). Cannot proceed."
  # STOP — do not continue
fi
```

## Step 1: Load Context

Read these files (agent context, not bash):
1. `docs/superpowers/specs/2026-03-27-aamm-v5-spec.md` — v5 spec
2. `kb/ecosystems/$ECOSYSTEM.md` — KB patterns for this ecosystem
3. `kb/cross-cutting.md` — universal patterns
4. `kb/anti-patterns.md` — what to watch for
5. `scans/ai-augmentation/config.yaml` — scan config, overrides
6. Previous results in `scans/ai-augmentation/results/` — for evolution

Read overrides for this repo from config.yaml `scan.repos[].overrides` if any.

## Step 2: Collect Repo Data

```bash
TMPDIR="/tmp/aamm-v5-$OWNER-$REPO"
mkdir -p "$TMPDIR"

# Repo metadata (language, topics, description)
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO" > "$TMPDIR/metadata.json"

# Check access
if grep -q '"message": "Not Found"' "$TMPDIR/metadata.json" 2>/dev/null; then
  echo "FATAL: Repo $OWNER/$REPO not accessible (404). Check token scope."
  # STOP — report failure, no assessment
fi

# Default branch
DEFAULT_BRANCH=$(jq -r '.default_branch' "$TMPDIR/metadata.json")

# Repo tree (recursive)
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/git/trees/$DEFAULT_BRANCH?recursive=1" \
  > "$TMPDIR/tree.json"

# Recent merged PRs (last 30)
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/pulls?state=closed&sort=updated&per_page=30" \
  > "$TMPDIR/prs.json"

# Recent commits (last 100)
curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/commits?sha=$DEFAULT_BRANCH&per_page=100" \
  > "$TMPDIR/commits.json"
```

Then read key file contents via the Contents API (agent reads these, not bash):
- Always: README.md, CI workflow files (all .github/workflows/*.yml)
- If present (check tree.json): CLAUDE.md, CONTRIBUTING.md, CODEOWNERS,
  ARCHITECTURE.md, .aiignore, .github/PULL_REQUEST_TEMPLATE.md,
  .github/ISSUE_TEMPLATE/, package manifests, tsconfig.json, ADRs
- Sample: 5-10 source files (for C2 doc comments, across packages for monorepos),
  5-10 test files (for SN depth — test quality assessment)

## Step 3: Assess — Rubric + Depth

Read `prompts/scanner-system.md` which contains all rubric tables, scoring rules,
confidence model, and output format.

Execute Phase 1 (rubric) then Phase 2 (depth) for each pillar and zone.
Produce the assessment JSON and draft 5-7 recommendations.

**Override handling:** If config.yaml has overrides for this repo:
- Evaluate the criterion independently (agent's own assessment)
- Record both: agent's evaluation AND the override
- If they conflict, flag in the report
- Override carries MEDIUM confidence
- Populate `overrides_applied` in assessment.json

## Step 4: Adversarial Review — MANDATORY

Dispatch a separate Agent subagent with the adversarial prompt.

**Invocation (Claude Code Agent tool):**
```
Agent tool call:
  prompt: [contents of prompts/adversarial-system.md]
         + "ASSESSMENT TO REVIEW:" + [full assessment JSON]
         + "REPO DATA:" + [key file contents that scanner read]
  description: "Adversarial review of AAMM scan for {OWNER}/{REPO}"
```

The adversarial agent:
1. Spot-checks 3-5 rubric criteria (re-reads files independently)
2. Spot-checks 3-5 depth findings (re-reads cited files)
3. Challenges each recommendation
4. Returns: rubric corrections + approved/rejected recommendations with reasons

Apply corrections to the assessment before generating the report.

## Step 5: Generate Report

Generate 3 output files:

### report.md (team-facing)
Structure: Summary → Recommendations (3-5) → Risk Flags → Skill Tree →
Findings → Cross-repo Insights → Evolution → Evidence Log.
See spec Section 5 for details.

Quadrant derivation:
```
Readiness: ≥4 pillars at Practiced/Mastered = High; 2-3 = Medium; ≤1 = Low
Adoption:  ≥3 zones at Exploring+ (with ≥1 at Practiced+) = High; 1-2 = Medium; 0 = Low

Quadrant grid:
  High readiness + Low adoption    = Fertile Ground
  High readiness + Medium adoption = Growing
  High readiness + High adoption   = AI-Native
  Medium readiness + Low adoption  = Traditional+
  Medium readiness + Medium        = Emerging
  Medium readiness + High          = Risky Acceleration
  Low readiness + Low              = Traditional
  Low readiness + Medium/High      = Risky Acceleration
```

Cross-pillar caveat: note that pillar difficulty varies (Structure criteria
are common; Purpose criteria are rare across the industry).

### assessment.json (structured data)
Follow `schema/assessment-v5.schema.json`. Include all rubric evaluations,
depth findings, recommendations with adversarial status, KB nominations.

### detailed-log.md (audit trail)
Everything: files read with excerpts, rubric reasoning per criterion,
all draft recommendations including rejected, adversarial dialogue.

## Step 6: Save Results

```bash
DATE=$(date +%Y-%m-%d)
RESULT_DIR="scans/ai-augmentation/results/$DATE/$OWNER--$REPO"
mkdir -p "$RESULT_DIR"
# Write report.md, assessment.json, detailed-log.md to $RESULT_DIR
```

## Step 7: Propose KB Updates

If new patterns or anti-patterns discovered, write proposed entries
(status: proposed) to `scans/ai-augmentation/results/$DATE/kb-updates.md`.
CoE lead reviews and merges into kb/ files.

## Failure Handling

| Failure | Detection | Action |
|---------|-----------|--------|
| Repo inaccessible | 404 from metadata API | STOP. Write failure report (reason only). No assessment. |
| Rate limited | 429 from any API call | Wait 60s, retry. After 3 retries, write partial report with "incomplete" flag. |
| Context window exceeded | Agent can't fit all data | Skip depth phase for remaining pillars. Flag "partial depth" in report. |
| Adversarial rejects ALL recs | 0 approved | Include all rejected recs with reasons. Flag for CoE lead manual review. |
| Unknown language | Ecosystem not in kb/ | Use cross-cutting rubric only. Mark ecosystem-specific criteria as N/A. |
| Hallucination caught | Adversarial spot-check fails | Remove finding. Downgrade confidence. Log incident in detailed-log. |

## Important

- Never print, log, or display $GITHUB_TOKEN
- Adversarial review is MANDATORY — never present results without Step 4
- No confirmations during scans — run fully autonomously
- Mastered nominations require CoE lead confirmation
- Never publish to Notion without human approval
```

- [ ] **Step 3: Write prompts/scanner-system.md**

Write `.claude/skills/scan-aamm-v5/prompts/scanner-system.md` — the full scanner prompt with ALL rubrics, rules, and constraints. This must contain:

1. All 5 readiness pillar rubrics (5 criteria each) — copy from spec Section 3d
2. All 5 adoption zone rubrics (3 criteria each) — copy from spec Section 3e
3. Readiness status levels (0-1=Undiscovered, 2-3=Exploring, 4-5=Practiced, 5/5+depth+CoE=Mastered)
4. Adoption status levels (0=Undiscovered, 1=Exploring, 2-3=Practiced, 3/3+depth+CoE=Mastered)
5. **Confidence rules:** objective→HIGH, semi-objective→MEDIUM, subjective→LOW. Agent CANNOT self-assign HIGH on subjective.
6. **Grounding rule:** every finding cites file path + content excerpt
7. **Inferred-evidence ceiling:** zones with only inferred evidence → max 🟡 Exploring, LOW confidence
8. **Overlap resolution:** CI config→Structure, CI enforcement→Safety Net, ARCHITECTURE.md→Purpose, schemas→Clarity, .aiignore→Workflow
9. **Cross-pillar caveat:** pillar difficulty varies, Structure criteria common, Purpose criteria rare
10. **Depth rule:** depth does NOT change status level. Depth adds findings only.
11. **Override handling:** if override exists, evaluate independently + report both
12. **Recommendation format** with all required fields
13. **Quadrant derivation rules**
14. **Output format:** assessment.json schema + report structure

The actual file content is the rubric tables from the spec (too large to inline in this plan). The implementing agent should:
- Read spec Section 3 in full
- Copy all rubric tables verbatim
- Add the 8 rules listed above (items 5-12) as explicit sections
- Add S1 note: single-package scoped libraries pass with depth note
- Add S2: include `cabal.project freeze` for Haskell lockfile equivalent
- Add C2 note: for multi-language monorepos, evaluate primary ecosystem, report per-ecosystem in depth
- Add adoption industry limitation note from spec Section 3e

- [ ] **Step 4: Write prompts/adversarial-system.md**

Write `.claude/skills/scan-aamm-v5/prompts/adversarial-system.md`:

```markdown
# AAMM v5 Adversarial Reviewer

You are an adversarial reviewer. Default posture: skeptical. Assume findings
are wrong until you verify them.

## Input

You receive:
1. The scanner agent's full assessment (JSON with rubric scores, findings, recommendations)
2. Key repo files (same data the scanner read)

## Mandate

### 1. Spot-check Rubric Criteria (pick 3-5 across different pillars/zones)

For each:
- Re-read the relevant file or data
- Verify YES/NO was correctly evaluated
- If incorrect: state correct evaluation + evidence

### 2. Spot-check Depth Findings (pick 3-5 with file citations)

For each:
- Re-read the cited file at the cited location
- Verify the finding accurately describes the content
- If hallucinated or misrepresented: flag it

### 3. Challenge Each Recommendation

For each of the 5-7 drafts:
- **Ecosystem fit:** Makes sense for this language/ecosystem?
- **Actionability:** Clear enough for a team to act on?
- **Measurability:** Can next scan verify it was done? Is the check concrete?
- **Already done?** Re-check — is the team already doing this?
- **ROI:** Truly top ROI, or is there something higher-impact?
- **Contradiction:** Conflicts with another finding?

### 4. Output Format

```
RUBRIC CORRECTIONS:
  [criterion ID]: [was YES/NO] → [should be YES/NO] — [evidence: file path + excerpt]

FINDING CORRECTIONS:
  [finding text]: [issue] — [what the file actually says at cited location]

RECOMMENDATIONS:
  APPROVED:
    #N: [title] — [why it passes scrutiny]
  REJECTED:
    #N: [title] — [specific reason: ecosystem mismatch / already done / not measurable / etc.]
```

## Rules

- Be specific. Cite evidence. "Seems wrong" is not acceptable.
- You may approve all if they genuinely pass.
- You may reject all (escalates to CoE lead).
- Do NOT rubber-stamp.
```

- [ ] **Step 5: Write schema/assessment-v5.schema.json**

Write `.claude/skills/scan-aamm-v5/schema/assessment-v5.schema.json` with the JSON Schema from the spec. The schema defines:
- `schema_version: "5.0"`, `criteria_version` (string, initially "5.0.0")
- `readiness`: 5 pillars, each with status/rubric/rubric_score/confidence/depth_findings
- `adoption`: 5 zones, each with status/rubric/rubric_score/confidence/depth_findings
- `recommendations`: array with title/what/why/effort/impact/source/measurable/adversarial_status/adversarial_reason
- `risk_flags`, `kb_nominations`, `overrides_applied`

Criteria version `5.0.0` is the initial version. Canonical source: the spec document. Bump rules: any change that could alter a rubric YES/NO = minor version bump.

- [ ] **Step 6: Commit skill**

```bash
cd /home/devuser/repos/cbu-coe/cbu-coe-toolkit
git add .claude/skills/scan-aamm-v5/
git commit -m "feat: create AAMM v5 scanner skill

- SKILL.md with full scan flow, failure handling, repo list integration
- Scanner system prompt with all rubrics + rules
- Adversarial agent prompt
- Assessment JSON schema v5.0
ADR-018"
```

---

## Task 3: Update CLAUDE.md for v5

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Replace AAMM sections in CLAUDE.md**

The following sections of CLAUDE.md need replacement. Other sections (Project, Three-model architecture, Source of truth, Rules 0-4, Session handoff, References) stay unchanged.

**Replace "Structure" section (lines 14-27) with:**

```markdown
## Structure

```
cbu-coe-toolkit/
├── models/                        # Model definitions (source of truth)
│   ├── ai-augmentation-maturity/  # AAMM v4 (archived — see v5 spec)
│   ├── engineering-vitals/        # KPIs, thresholds (Power BI external)
│   └── capability-maturity/       # Engineering practices (draft)
├── kb/                            # AAMM v5 Knowledge Base (live)
│   ├── ecosystems/                # Per-language patterns
│   ├── cross-cutting.md           # Universal patterns
│   └── anti-patterns.md           # What doesn't work
├── scripts/aamm/                  # v4 scan pipeline (archived)
├── scans/ai-augmentation/         # Config + results
├── .claude/skills/                # Claude Code skills (autodetected)
├── notion/                        # Page registry, publishing guide
└── docs/
    ├── decisions/                 # Architecture Decision Records
    └── learnings.md               # Operational insights log
```
```

**Replace "AAMM model files" section (lines 44-60) with:**

```markdown
## AAMM v5

AAMM v5 uses a single AI agent (not a bash pipeline) to assess repos. See ADR-018.

**Key files:**
- `docs/superpowers/specs/2026-03-27-aamm-v5-spec.md` — v5 spec (authoritative)
- `.claude/skills/scan-aamm-v5/SKILL.md` — scan skill (invoke with `/scan-aamm-v5`)
- `kb/` — Knowledge Base (live, enriched after each scan)
- `models/config.yaml` — tracked repo list (29 repos, 4 orgs)
- `scans/ai-augmentation/config.yaml` — scan configuration

**Read order for agents:**
1. v5 spec — understand rubric + depth methodology
2. KB files for target ecosystem — patterns and anti-patterns
3. `models/config.yaml` — which repos to scan
```

**Replace "Scan pipeline" section (lines 62-78) with:**

```markdown
## Scan flow (v5)

```
/scan-aamm-v5 owner/repo
  → Load KB + config                    # Agent reads ecosystem patterns
  → Collect repo data via GitHub API     # Tree, PRs, commits, key files
  → Rubric assessment (5 pillars, 5 zones)  # Structured criteria, YES/NO
  → Depth assessment                     # Read files, produce grounded findings
  → Draft recommendations               # 5-7, ROI-prioritized
  → Adversarial review (separate agent)  # Spot-check rubric + challenge recs
  → Generate report (3 files)            # report.md, assessment.json, detailed-log.md
```

Non-interactive. No confirmations. Results go to `scans/ai-augmentation/results/YYYY-MM-DD/`.

Tracked repos: 29 across 4 orgs. See `models/config.yaml`.
```

**Replace Rules 5-7 (lines 96-98) with:**

```markdown
5. **Read `backlog.md` first (if it exists).** Local working doc (gitignored).
6. **Read v5 spec before scanning.** Load spec → KB → config → then scan.
7. **Use `.claude/skills/scan-aamm-v5/`** for scans. Target repo from `models/config.yaml` or manual input.
```

**Replace "Sync protocol" section (lines 107-115) with:**

```markdown
## Sync protocol

When changing AAMM assessment logic, update ALL of these in the same session:
1. **Spec** (`docs/superpowers/specs/2026-03-27-aamm-v5-spec.md`) — the rules
2. **Scanner prompt** (`.claude/skills/scan-aamm-v5/prompts/scanner-system.md`) — rubric tables
3. **This file** (CLAUDE.md) — if the change affects how agents use the model
4. **ADR** (`docs/decisions/`) — if the change is a significant design decision
5. **KB** (`kb/`) — if the change affects patterns or anti-patterns

A change in one without the others is a bug.
```

**Remove the ⚠ Known limitation paragraph (line 78)** — v5 resolves HAS_AI_ACTIVITY with per-zone rubrics.

- [ ] **Step 2: Commit CLAUDE.md**

```bash
cd /home/devuser/repos/cbu-coe/cbu-coe-toolkit
git add CLAUDE.md
git commit -m "chore: update CLAUDE.md for AAMM v5 architecture

- Replace v4 pipeline references with v5 scan skill
- Add kb/ to structure diagram
- Update read order, rules, sync protocol for v5
- Remove HAS_AI_ACTIVITY warning (resolved by per-zone rubrics)
ADR-018"
```

---

## Task 4: Update Config, Archive v4

**Files:**
- Modify: `scans/ai-augmentation/config.yaml`
- Move: `.claude/skills/scan-ai-augmentation/` → `.claude/skills/scan-ai-augmentation-v4/`
- Modify: `models/ai-augmentation-maturity/README.md` (add archived header)

- [ ] **Step 1: Update config.yaml**

Replace the header and add v5 sections. Keep ai_config_files, bot_names, security_scanning_tools, infrastructure_signals (scanner uses these). Remove stale_config and learning_signals (v4 concepts).

Replace lines 1-6 with:
```yaml
# AAMM v5 — Scan Configuration
# Rubric criteria, AI config patterns, bot names, and scan settings.
# Repo list: models/config.yaml (the master list).
#
# Model version: v5.0
# Spec: docs/superpowers/specs/2026-03-27-aamm-v5-spec.md
# Last updated: 2026-03-27
```

Replace model_documents section (lines 17-20) with:
```yaml
model_documents:
  spec: docs/superpowers/specs/2026-03-27-aamm-v5-spec.md
  scanner_prompt: .claude/skills/scan-aamm-v5/prompts/scanner-system.md
  schema: .claude/skills/scan-aamm-v5/schema/assessment-v5.schema.json
```

Add after results section:
```yaml
# --------------------------------------------------------------------------
# v5 Exploration Settings
# --------------------------------------------------------------------------
exploration:
  source_sample_size: 10     # Files to sample for Clarity/Safety Net depth
  test_sample_size: 10       # Test files to sample for Safety Net depth
  pr_sample_size: 30         # Recent merged PRs to analyze
  commit_sample_size: 100    # Recent commits for co-authored-by patterns

# --------------------------------------------------------------------------
# v5 Schema Version
# --------------------------------------------------------------------------
assessment:
  schema_version: "5.0"
  criteria_version: "5.0.0"
```

Remove stale_config section (lines 252-256) and learning_signals section (lines 260-274).

- [ ] **Step 2: Archive v4 skill**

```bash
cd /home/devuser/repos/cbu-coe/cbu-coe-toolkit
git mv .claude/skills/scan-ai-augmentation .claude/skills/scan-ai-augmentation-v4
```

- [ ] **Step 3: Add archived header to v4 model files**

Prepend to `models/ai-augmentation-maturity/README.md`:
```markdown
> **⚠ ARCHIVED:** This is the v4 model definition. AAMM v5 replaces this with
> an AI agent + rubric approach. See `docs/superpowers/specs/2026-03-27-aamm-v5-spec.md`
> and ADR-018. The v4 model files are kept for historical reference.

```

Same header prepended to `readiness-scoring.md` and `adoption-scoring.md`.

- [ ] **Step 4: Commit spec, ADR, config, archives**

```bash
cd /home/devuser/repos/cbu-coe/cbu-coe-toolkit
git add docs/superpowers/specs/2026-03-27-aamm-v5-spec.md
git add docs/decisions/018-aamm-v5-single-agent-architecture.md
git add docs/decisions/017-aamm-purpose-and-dual-architecture.md
git add scans/ai-augmentation/config.yaml
git add .claude/skills/scan-ai-augmentation-v4/
git add models/ai-augmentation-maturity/README.md
git add models/ai-augmentation-maturity/readiness-scoring.md
git add models/ai-augmentation-maturity/adoption-scoring.md
git commit -m "docs: AAMM v5 spec, ADR-018, config update, v4 archived

- v5 spec (3 rounds of adversarial review)
- ADR-018 supersedes ADR-017
- config.yaml updated to v5 format
- v4 skill archived, v4 model files marked archived"
```

---

## Task 5: Validation — First Scan

**Files:**
- Create: `scans/ai-augmentation/results/2026-03-27/IntersectMBO--cardano-ledger/report.md`
- Create: `scans/ai-augmentation/results/2026-03-27/IntersectMBO--cardano-ledger/assessment.json`
- Create: `scans/ai-augmentation/results/2026-03-27/IntersectMBO--cardano-ledger/detailed-log.md`

- [ ] **Step 1: Verify skill is discoverable**

```bash
ls /home/devuser/repos/cbu-coe/cbu-coe-toolkit/.claude/skills/scan-aamm-v5/SKILL.md
```

Expected: file exists.

- [ ] **Step 2: Run scan on cardano-ledger**

Invoke the scan-aamm-v5 skill with target `IntersectMBO/cardano-ledger` (ecosystem: haskell).
Follow all steps in SKILL.md. This is the end-to-end validation.

- [ ] **Step 3: Validate output**

Check report.md:
- [ ] Summary with quadrant placement
- [ ] 3-5 recommendations with all fields (what, why, effort, impact, source, measurable)
- [ ] Risk flags section
- [ ] Skill tree with rubric scores + confidence per pillar and zone
- [ ] Findings with file:line citations
- [ ] Cross-repo insights from Haskell KB
- [ ] Evidence log

Check assessment.json:
- [ ] schema_version: "5.0"
- [ ] All 5 readiness pillars with rubric YES/NO per criterion
- [ ] All 5 adoption zones with rubric YES/NO per criterion
- [ ] Recommendations with adversarial_status

- [ ] **Step 4: Commit results**

```bash
cd /home/devuser/repos/cbu-coe/cbu-coe-toolkit
git add scans/ai-augmentation/results/2026-03-27/
git commit -m "feat: first AAMM v5 scan — cardano-ledger validation

First production scan using v5 rubric + depth methodology.
Includes adversarial review. Haskell KB patterns applied."
```

---

## Task 6: Learnings + Session Handoff

- [ ] **Step 1: Draft learnings for docs/learnings.md**

```markdown
### 2026-03-27 — Session 10: AAMM v5 complete redesign

- **Working backwards from the problem is more productive than forward-iterating on signals.**
  9 sessions of pipeline refinement produced precise numbers but superficial recommendations.
  Starting with "what problem does AAMM solve?" produced a fundamentally better model in one session.

- **3 rounds of adversarial review found 59 issues total (31→16→12).**
  Each round caught structural problems the previous missed. Round 1 found the ADR-017
  contradiction. Round 2 found the 3-criteria scale mismatch. Round 3 found CLAUDE.md sync.
  Adversarial review at the spec level is as valuable as at the scan level.

- **Rubric + depth resolves the reproducibility vs quality trade-off.**
  v4 was reproducible but shallow (bash grep). Pure AI is deep but non-reproducible.
  Rubric (structured criteria) + depth (qualitative findings) gives both: rubric anchors
  the level reproducibly, depth adds insight bash couldn't provide.

- **KB pre-seeding from previous sessions is essential for first-scan credibility.**
  An empty KB produces generic recommendations. Pre-seeding with 9 sessions of validated
  patterns means the first v5 scan already has cross-repo insights.

- **Single agent > dual architecture when the rubric provides structure.**
  ADR-017's dual architecture (pipeline + agent) was the right instinct (use each for
  its strength) but wrong implementation (two systems to maintain). The rubric embedded
  in the agent prompt achieves the same goal with one system.
```

- [ ] **Step 2: Present learnings for Dorin's review (do not commit without approval)**

---

## Execution Order

Tasks 1-4 create independent file sets. Commits must be sequential (git index), but file creation can be parallel.

```
Task 1 (KB)        ──┐
Task 2 (Skill)     ──┤
Task 3 (CLAUDE.md) ──┼──→ sequential commits ──→ Task 5 (Validation) ──→ Task 6 (Learnings)
Task 4 (Config+ADR)──┘
```

**Note:** Portfolio summary generation (all 29 repos + quadrant grid) is not in scope for this plan. It requires a full portfolio scan. This plan validates the model on 1 repo.
