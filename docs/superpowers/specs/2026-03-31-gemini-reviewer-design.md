# Gemini Reviewer — Design Spec

> Independent, skeptical, data-driven reviewer powered by Gemini 3.1 Pro.
> Available across cbu-coe-toolkit and cbu-coe repos.

---

## Problem

All current review gates (adversarial Stage A/B, peer-review skill) use Claude-to-Claude subagents. A single-model review ecosystem has blind spots — the same biases and failure modes repeat. We need an independent reviewer that:

- Brings a different model's perspective (Gemini 3.1 Pro)
- Understands the full project context (CBU, CoE, tech leads, repo owners)
- Challenges with evidence, not assumptions
- Is always available — on-demand and as a pre-commit gate

## Scope

- **In scope:** Review skill (`/review-model`), GEMINI.md context files, pre-commit hook on `models/`, on-demand invocation
- **Out of scope:** Replacing adversarial Stage A/B (those remain Claude subagents), Gemini writing code, Gemini modifying files

---

## Architecture

### Components

1. **GEMINI.md** — Context file in repo root (both repos). Tells Gemini who it is, what perspectives to adopt, how to review, output format. Equivalent of CLAUDE.md but for the Gemini reviewer persona.

2. **`/review-model` skill** — Claude Code skill that orchestrates Gemini invocation. Receives a target, builds a review prompt, invokes `gemini` CLI, captures and presents output.

3. **Pre-commit hook** — Triggers `/review-model` automatically when committing changes to `models/`. Blocks commit if score < 9.0.

### Flow

```
On-demand:
  Operator: /review-model <target>
    → Claude Code builds review prompt (target + context)
    → Writes prompt to /tmp/gemini-review-prompt.md
    → Invokes: cat /tmp/gemini-review-prompt.md | gemini -m gemini-3.1-pro
    → Gemini reads GEMINI.md from working directory (auto-loaded by CLI) + prompt via stdin
    → Gemini produces structured review
    → Claude Code presents review to operator

Pre-commit:
  git commit (staged files include models/*)
    → Hook checks: is gemini CLI installed? If not → warning + allow commit
    → Hook identifies changed files in models/
    → Batches all changed files into ONE review prompt
    → Invokes gemini review via stdin pipe
    → Parses score from output (regex: /Score:\s*(\d+\.?\d*)\s*\/\s*10/)
    → Score ≥ 9.0 → commit proceeds
    → Score < 9.0 → commit blocked, findings displayed
    → Parse failure → warning + allow commit (fail-open)
```

**GEMINI.md auto-loading:** Gemini CLI automatically reads `GEMINI.md` from the current working directory as system context ([Gemini CLI docs: GEMINI.md](https://geminicli.com/docs/)). The skill always invokes `gemini` from the repo root to ensure GEMINI.md is loaded. If this behavior changes in a future CLI version, the skill must explicitly include GEMINI.md content in the prompt.

### Dependencies

- **Gemini CLI**: `npm install -g @google/gemini-cli` (Node.js 20+)
- **Model**: `gemini-3.1-pro` (default), configurable
- **Auth**: Gemini CLI handles auth via Google account (similar to Claude Code with Anthropic account)

### Prerequisites

Before using the Gemini reviewer:

1. **Install Gemini CLI**: `npm install -g @google/gemini-cli`
2. **Authenticate**: Run `gemini` once interactively to complete Google account auth
3. **Verify**: `gemini -m gemini-3.1-pro -p "hello"` should return a response
4. **Cost**: Gemini CLI uses the free tier for users with Google AI Pro/Ultra subscription (similar to Claude Max). Without subscription, API rate limits apply per Google's pricing.

---

## GEMINI.md — Persona Definition

Lives in repo root of both `cbu-coe-toolkit/` and `cbu-coe/`.

### Identity

You are an independent reviewer for the Cardano Business Unit (CBU) Centre of Excellence (CoE). You review implementation decisions, model definitions, specifications, knowledge base entries, ADRs, scan reports, and any artifact produced in this project.

### Perspectives

You understand and balance four stakeholder perspectives:

| Perspective | What they care about |
|-------------|---------------------|
| **CoE** | Model quality, cross-portfolio consistency, measurement integrity, KB accuracy |
| **Tech leads** | Actionability, ROI, realistic effort estimates, team impact |
| **Repo owners** | Fairness, accuracy about their repo, no false claims about their codebase |
| **CBU leadership** | Strategic alignment, risk management, value delivered to Cardano ecosystem |

### Behavior Rules

1. **Read-only** — You read everything, you modify nothing. Your output is a review document.
2. **Challenge with data** — Every objection cites a file path, line number, commit SHA, or metric. "This seems wrong" is not acceptable. "This is wrong because file X line Y shows Z" is.
3. **No assumptions** — If you cannot verify a claim, say: "Cannot verify X from available data. If true, then [implication]. Recommend verifying by [method]."
4. **Skeptical by default** — Assume every claim is wrong until you verify it yourself.
5. **Constructive** — Not just "this is wrong" but "this is wrong, it should be Y, because Z."
6. **Honest** — If something is good, say so. Do not invent problems to justify your existence.
7. **Clear** — No hedging. No "might", "could perhaps", "it seems like maybe". State findings directly with evidence.

### Review Checklist

For every artifact reviewed, check:

1. Does every claim have evidence? (file, commit, metric)
2. Is the evidence correct? (verify citations yourself)
3. Do conclusions follow from the data? (no logical jumps)
4. Is something important missing? (blind spots)
5. Is it specific or generic? (would this appear identically in another context?)
6. Is it actionable? (can a tech lead put this in the backlog tomorrow?)

### Output Format

```markdown
## Review: <target>
### Score: X.X / 10
### Verdict: PASS (≥9.0) | NEEDS WORK (7.0–8.9) | FAIL (<7.0)

### Findings

#### HIGH
- [H1] <what is wrong> — evidence: <file:line or commit SHA> — impact: <why it matters>

#### MEDIUM
- [M1] ...

#### LOW
- [L1] ...

### What to fix to reach 9.0
1. [H1] → <concrete, specific action>
2. [M1] → <concrete action>
...

### What works well
- <what is solid and why>
```

### Scoring

- Score 1–10, one decimal place
- ≥9.0 → **PASS** — ready to commit/publish
- 7.0–8.9 → **NEEDS WORK** — fix HIGH findings, re-review
- <7.0 → **FAIL** — fundamental problems, redesign needed
- The score reflects current state, not potential
- Gemini decides the weight of each finding — no mechanical formula

### Project Context

> This section is repo-specific. In cbu-coe-toolkit it references the three-model architecture, AAMM v6, scoring-model.md, KB structure. In cbu-coe it references the guidance, templates, and skills for teams.

The project context section of each GEMINI.md will include:
- What this repo does and who it serves
- The three-model architecture (AAMM, Capability Maturity, Engineering Vitals)
- Key files and their roles (scoring-model.md, spec.md, KB, config.yaml)
- Design principles (measure outcomes not mechanisms, adversarial review mandatory, scan-from-zero)
- Operational rules from CLAUDE.md (adapted for reviewer perspective)

---

## `/review-model` Skill

### Location

`cbu-coe-toolkit/.claude/skills/review-model/SKILL.md`

(Also symlinked or duplicated in cbu-coe if needed.)

### Invocation

```bash
/review-model <target>
# target can be:
#   - a file path: models/ai-augmentation-maturity/scoring-model.md
#   - a directory: scans/ai-augmentation/results/2026-03-31/IntersectMBO--cardano-ledger/
```

Target must be a file path or directory. Topic-based review (natural language queries) is out of scope for v1 — file/directory targets are unambiguous and sufficient.

### What the skill does

1. **Resolve target** — Identify the file(s) to review. If directory, include all files in it.
2. **Gather context** — Based on the target type, include relevant context files:
   - Target in `models/` → include scoring-model.md, spec.md, relevant KB files, CLAUDE.md
   - Target in `scans/` → include the assessment.json, scoring-model.md, relevant KB
   - Target in `docs/decisions/` → include referenced ADRs, spec.md
   - Target in `knowledge-base/` → include scoring-model.md, anti-patterns.md, cross-cutting.md
   - **Fallback** (target doesn't match any pattern above) → include CLAUDE.md as minimal context + any files explicitly referenced by the target (imports, links, citations)
3. **Build prompt** — Combine with clear delimiters:
   ```markdown
   ## INSTRUCTIONS
   <review instructions from SKILL.md>

   ## TARGET (review this)
   <target file content with file paths as headers>

   ## CONTEXT (background — do not review, use for reference only)
   <context files with file paths as headers>
   ```
4. **Write prompt to temp file** — `/tmp/gemini-review-prompt.md`
5. **Invoke Gemini** — `cat /tmp/gemini-review-prompt.md | gemini -m gemini-3.1-pro` from repo root (GEMINI.md auto-loaded)
6. **Capture output** — Parse Gemini's structured review
7. **Present to operator** — Display score, verdict, findings, fix actions
8. **Optional save** — If `--save` flag, write to `reviews/YYYY-MM-DD-<target-slug>.md`

### Score Parsing

The skill extracts the score using regex: `/Score:\s*(\d+\.?\d*)\s*\/\s*10/`

If parsing fails:
- **On-demand**: Present raw Gemini output, note "Could not parse score from output"
- **Pre-commit**: Allow commit with warning "Gemini review produced unparseable output — review manually"

Fail-open policy: when in doubt, allow the action and warn. Never silently block.

### Error Handling

| Condition | Action |
|-----------|--------|
| Gemini CLI not installed | Print install instructions: `npm install -g @google/gemini-cli` |
| Auth failure | Print: "Run `gemini` once to authenticate with your Google account" |
| Model unavailable | Fall back to `gemini-2.5-pro`, note in output |
| Target not found | Error with suggestion of similar paths |
| Gemini output unparseable | Present raw output, note parsing failure |

---

## Pre-commit Hook

### Trigger

Any `git commit` where staged files include paths matching `models/**`.

### Implementation

A **git pre-commit hook** (not a Claude Code hook — this must work independently of any Claude Code session). Implemented as `scripts/gemini-pre-commit-review.sh` and installed via git's standard hook mechanism.

The hook script:

1. Checks: is `gemini` CLI installed? If not → print warning, allow commit, exit 0
2. Checks: is `GEMINI_REVIEW` env var set to `0`? If so → skip review, allow commit
3. Identifies staged files matching `models/**` via `git diff --cached --name-only`
4. If no `models/` files staged → exit 0 (no review needed)
5. Batches ALL changed files into one review prompt (one Gemini call per commit, not per file)
6. Invokes Gemini review via stdin pipe from repo root
7. Parses score from output (regex)
8. Score ≥ 9.0 → exit 0 (commit proceeds)
9. Score < 9.0 → print findings + fix actions, exit 1 (commit blocked)
10. Parse failure → print warning, exit 0 (fail-open)

### Installation

```bash
# Option A: symlink (recommended for development)
ln -sf ../../scripts/gemini-pre-commit-review.sh .git/hooks/pre-commit

# Option B: lefthook (if team uses it)
# Add to lefthook.yml:
#   pre-commit:
#     commands:
#       gemini-review:
#         run: scripts/gemini-pre-commit-review.sh
```

The hook script (`scripts/gemini-pre-commit-review.sh`) is self-contained — no dependency on Claude Code runtime.

### Bypass

Three ways to skip the review:
- `--no-verify` — standard git flag, bypasses all hooks
- `GEMINI_REVIEW=0 git commit` — skips Gemini review specifically, other hooks still run
- Gemini CLI not installed — hook degrades gracefully, prints warning, allows commit

---

## File Layout

```
cbu-coe-toolkit/
├── GEMINI.md                              # Gemini reviewer context (toolkit-specific)
├── .claude/skills/review-model/
│   └── SKILL.md                           # Review skill definition
├── scripts/
│   └── gemini-pre-commit-review.sh        # Git pre-commit hook script (self-contained)
├── .geminiignore                           # Optional: exclude build artifacts, secrets, large files from Gemini context
└── reviews/                               # Saved reviews (gitignored — ephemeral by default, operator commits selectively)

cbu-coe/
├── GEMINI.md                              # Gemini reviewer context (cbu-coe-specific)
└── .claude/skills/review-model/
    └── SKILL.md                           # Duplicated (not symlinked — repos are independent)
```

---

## What This Does NOT Do

- **Does not replace adversarial Stage A/B** — Those remain Claude subagents running in-flight during scans. Gemini reviews finished artifacts.
- **Does not modify files** — Gemini is read-only. It produces review output. Humans and Claude implement fixes.
- **Does not run automatically on every file change** — Only on `models/` pre-commit and on-demand. No file-watcher or continuous review.
- **Does not have a mechanical scoring formula** — Gemini decides finding weights. We give it the framework (1-10, findings, target 9.0), it decides the scoring.

---

## Success Criteria

1. `/review-model scoring-model.md` produces a structured review with score, findings, and fix actions within 120 seconds
2. Pre-commit hook blocks a commit with a known deficiency in `models/` and explains why
3. Gemini catches at least one issue that Claude's peer-review did not catch in a real artifact
4. Reviews are specific (cite files, lines, commits) — not generic advice
