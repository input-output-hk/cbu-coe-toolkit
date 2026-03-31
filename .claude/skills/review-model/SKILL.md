---
name: review-model
description: Run a Gemini Pro review on any file or directory — independent, skeptical, data-driven. Produces scored findings (HIGH/MEDIUM/LOW) with a target of ≥9.0 to pass.
---

# Review Model

Invoke an independent Gemini reviewer on a target file or directory.

## Input

Target is provided as the ARGUMENTS to this skill:
- A file path: `models/ai-augmentation-maturity/scoring-model.md`
- A directory: `scans/ai-augmentation/results/2026-03-31/IntersectMBO--cardano-ledger/`

Optional flags:
- `--save` — save review output to `reviews/YYYY-MM-DD-<target-slug>.md`

## Prerequisites Check

```bash
if ! command -v gemini &> /dev/null; then
  echo "ERROR: Gemini CLI not installed."
  echo "Install with: npm install -g @google/gemini-cli"
  echo "Then authenticate: run 'gemini' once interactively"
  # STOP — do not proceed
fi
```

## Step 1: Resolve Target

Read the target argument. Determine if it is a file or directory.

- If **file**: the target is that single file.
- If **directory**: the target is ALL files in that directory (non-recursive for scan results, recursive for model dirs).
- If target does not exist: print error with suggestion of similar paths (use `find` or `ls`). STOP.

## Step 2: Gather Context

Based on the target path, gather context files. Read them into memory (agent reads, not bash).

| Target path pattern | Context files to include |
|---------------------|--------------------------|
| `models/` | `models/ai-augmentation-maturity/scoring-model.md`, `models/ai-augmentation-maturity/spec.md`, relevant KB files from `models/ai-augmentation-maturity/knowledge-base/`, `CLAUDE.md` |
| `scans/` | The scan's `assessment.json` (if not the target itself), `models/ai-augmentation-maturity/scoring-model.md`, relevant KB for the scanned repo's ecosystem |
| `docs/decisions/` | Other ADRs referenced in the target, `models/ai-augmentation-maturity/spec.md` |
| `knowledge-base/` | `models/ai-augmentation-maturity/scoring-model.md`, `models/ai-augmentation-maturity/knowledge-base/anti-patterns.md`, `models/ai-augmentation-maturity/knowledge-base/cross-cutting.md` |
| **Fallback** (no pattern match) | `CLAUDE.md` + any files explicitly referenced by the target (imports, links, citations) |

## Step 3: Build Prompt

Write a prompt file to `/tmp/gemini-review-prompt.md` with this structure:

```markdown
## INSTRUCTIONS

You are reviewing the TARGET below. Use CONTEXT for background only — do not review it.

Produce your review in the exact output format specified in your GEMINI.md system prompt.
Be skeptical. Challenge every claim with evidence. Cite file paths and line numbers.
If you cannot verify a claim, say so explicitly.

## TARGET (review this)

### <file path>
<file content>

### <file path 2>
<file content 2>

## CONTEXT (background — do not review, use for reference only)

### <context file path>
<context file content>

### <context file path 2>
<context file content 2>
```

## Step 4: Health Check + Invoke Gemini

**MANDATORY health check before sending the real prompt.** Never send a large prompt without confirming the model responds first.

Two-level fallback:
1. **Gemini CLI** (OAuth, Google One AI Pro — free) → models: `gemini-3.1-pro`, `gemini-2.5-pro`
2. **Gemini API** (API key, `$GEMINI_API_KEY`, $4/mo budget cap) → model: `gemini-2.5-pro`

### Level 1: Gemini CLI

For each CLI model, health check:
```bash
echo "ok" | timeout 45 gemini -m <model> 2>/dev/null
```

- Responds within 45 seconds → use it
- Timeout or 429 → try next CLI model
- All CLI models fail → fall through to Level 2

Invoke (once healthy model found):
```bash
cd <repo-root>
cat /tmp/gemini-review-prompt.md | timeout 300 gemini -m "$MODEL" 2>/tmp/gemini-review-stderr.txt | tee /tmp/gemini-review-output.md
```

Notes:
- Run from repo root so GEMINI.md is auto-loaded by Gemini CLI
- `timeout 300` — large prompts need time for generation
- If output is empty after successful health check → CLI dropped connection mid-request, fall through to Level 2

### Level 2: Gemini API (fallback)

Used when ALL CLI models are capacity-exhausted. Requires `$GEMINI_API_KEY` env var (from `~/.zshrc`).

Health check:
```bash
source ~/.zshrc 2>/dev/null
curl -s -m 30 "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"contents":[{"parts":[{"text":"Reply: ok"}]}]}' | head -c 200
```

Invoke:
```bash
source ~/.zshrc 2>/dev/null
# Read GEMINI.md and prepend to prompt as system instruction
GEMINI_MD=$(cat GEMINI.md)
PROMPT=$(cat /tmp/gemini-review-prompt.md)

# Build API request — system instruction from GEMINI.md, user content from prompt
cat > /tmp/gemini-api-request.json << APIREQ
{
  "system_instruction": {"parts": [{"text": $(echo "$GEMINI_MD" | python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))")}]},
  "contents": [{"parts": [{"text": $(echo "$PROMPT" | python3 -c "import json,sys; print(json.dumps(sys.stdin.read()))")}]}]
}
APIREQ

curl -s -m 300 "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=$GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -d @/tmp/gemini-api-request.json | python3 -c "
import json, sys
r = json.load(sys.stdin)
if 'candidates' in r:
    print(r['candidates'][0]['content']['parts'][0]['text'])
elif 'error' in r:
    print(f'API ERROR: {r[\"error\"][\"message\"]}', file=sys.stderr)
" | tee /tmp/gemini-review-output.md
```

Note: GEMINI.md is NOT auto-loaded via API — we include it as `system_instruction`.

### If both levels fail

Print "All Gemini endpoints unavailable. Skipping review." and STOP (fail-open).

## Step 5: Present Results

Read `/tmp/gemini-review-output.md` and present the review to the operator.

Parse the score using this pattern: look for a line containing `Score:` followed by a number, `/`, and `10`.

Display:
1. The score and verdict prominently
2. All findings (HIGH first, then MEDIUM, then LOW)
3. The "What to fix to reach 9.0" section
4. The "What works well" section

If score parsing fails: present the full raw output and note "Could not parse score — review output manually."

## Step 6: Optional Save

If `--save` flag was provided:

```bash
DATE=$(date +%Y-%m-%d)
SLUG=$(echo "<target>" | sed 's/[^a-zA-Z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')
cp /tmp/gemini-review-output.md reviews/${DATE}-${SLUG}.md
echo "Review saved to reviews/${DATE}-${SLUG}.md"
```

## Important

- **Read-only on target repo** — Gemini reviews, it does not modify files
- **Fail-open** — If anything goes wrong (CLI missing, auth failure, parse error), warn and continue. Never silently block.
- **No confirmations** — Run the review end-to-end without asking the operator for permission mid-flow
