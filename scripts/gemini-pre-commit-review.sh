#!/usr/bin/env bash
#
# Gemini pre-commit review hook for models/ directory.
# Blocks commit if Gemini scores changes < 9.0.
# Fail-open: if gemini is not installed or output is unparseable, warn and allow.
#
# Fallback chain:
#   Level 1: Gemini CLI (OAuth, Google One AI Pro — free)
#   Level 2: Gemini API ($GEMINI_API_KEY, $4/mo budget cap)
#
set -euo pipefail

# --- Opt-out ---
if [[ "${GEMINI_REVIEW:-}" == "0" ]]; then
  exit 0
fi

# --- Check for models/ changes ---
CHANGED_FILES=$(git diff --cached --name-only -- 'models/' || true)
if [[ -z "$CHANGED_FILES" ]]; then
  exit 0
fi

echo "🔍 Gemini reviewing changes in models/..."
echo "   Files: $(echo "$CHANGED_FILES" | tr '\n' ' ')"

# --- Build prompt ---
PROMPT_FILE=$(mktemp /tmp/gemini-precommit-XXXXXX.md)
REPO_ROOT=$(git rev-parse --show-toplevel)

cat > "$PROMPT_FILE" << 'INSTRUCTIONS'
## INSTRUCTIONS

You are reviewing changes to model definition files before they are committed.
Produce your review in the exact output format specified in your GEMINI.md system prompt.
Be skeptical. Challenge every claim with evidence. Cite file paths and line numbers.

INSTRUCTIONS

echo "" >> "$PROMPT_FILE"
echo "## TARGET (review this)" >> "$PROMPT_FILE"
echo "" >> "$PROMPT_FILE"

for file in $CHANGED_FILES; do
  if [[ -f "$REPO_ROOT/$file" ]]; then
    echo "### $file" >> "$PROMPT_FILE"
    echo '```' >> "$PROMPT_FILE"
    cat "$REPO_ROOT/$file" >> "$PROMPT_FILE"
    echo '```' >> "$PROMPT_FILE"
    echo "" >> "$PROMPT_FILE"
  fi
done

echo "## CONTEXT (background — do not review, use for reference only)" >> "$PROMPT_FILE"
echo "" >> "$PROMPT_FILE"

if [[ -f "$REPO_ROOT/CLAUDE.md" ]]; then
  echo "### CLAUDE.md" >> "$PROMPT_FILE"
  echo '```' >> "$PROMPT_FILE"
  cat "$REPO_ROOT/CLAUDE.md" >> "$PROMPT_FILE"
  echo '```' >> "$PROMPT_FILE"
fi

cd "$REPO_ROOT" || { echo "⚠ Cannot cd to repo root — allowing commit."; exit 0; }

OUTPUT_FILE=$(mktemp /tmp/gemini-output-XXXXXX.md)
REVIEW_OK=false

# --- Level 1: Gemini CLI ---
if command -v gemini &> /dev/null; then
  MODELS=("gemini-3.1-pro" "gemini-2.5-pro")

  for MODEL in "${MODELS[@]}"; do
    if echo "ok" | timeout 45 gemini -m "$MODEL" > /dev/null 2>&1; then
      echo "   Model: $MODEL (CLI)"
      if cat "$PROMPT_FILE" | timeout 300 gemini -m "$MODEL" > "$OUTPUT_FILE" 2>/dev/null; then
        if [[ -s "$OUTPUT_FILE" ]]; then
          REVIEW_OK=true
          break
        fi
      fi
    fi
  done

  # Retry once after 60s if all CLI models failed
  if [[ "$REVIEW_OK" != "true" ]]; then
    echo "   CLI capacity exhausted. Retrying in 60s..."
    sleep 60
    for MODEL in "${MODELS[@]}"; do
      if echo "ok" | timeout 45 gemini -m "$MODEL" > /dev/null 2>&1; then
        echo "   Model: $MODEL (CLI retry)"
        if cat "$PROMPT_FILE" | timeout 300 gemini -m "$MODEL" > "$OUTPUT_FILE" 2>/dev/null; then
          if [[ -s "$OUTPUT_FILE" ]]; then
            REVIEW_OK=true
            break
          fi
        fi
      fi
    done
  fi
fi

# --- Level 2: Gemini API (fallback) ---
if [[ "$REVIEW_OK" != "true" ]]; then
  source ~/.zshrc 2>/dev/null || true

  if [[ -n "${GEMINI_API_KEY:-}" ]]; then
    echo "   Falling back to Gemini API ($4/mo cap)..."

    GEMINI_MD=""
    [[ -f "$REPO_ROOT/GEMINI.md" ]] && GEMINI_MD=$(cat "$REPO_ROOT/GEMINI.md")
    PROMPT_CONTENT=$(cat "$PROMPT_FILE")

    python3 -c "
import json, sys, urllib.request

api_key = '${GEMINI_API_KEY}'
system = json.loads(sys.stdin.readline())
user = json.loads(sys.stdin.readline())

body = json.dumps({
    'system_instruction': {'parts': [{'text': system}]},
    'contents': [{'parts': [{'text': user}]}]
}).encode()

req = urllib.request.Request(
    f'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key={api_key}',
    data=body,
    headers={'Content-Type': 'application/json'},
    method='POST'
)

try:
    with urllib.request.urlopen(req, timeout=300) as resp:
        r = json.loads(resp.read())
        if 'candidates' in r:
            print(r['candidates'][0]['content']['parts'][0]['text'])
        else:
            print('API returned no candidates', file=sys.stderr)
except Exception as e:
    print(f'API error: {e}', file=sys.stderr)
" <<< "$(echo "$GEMINI_MD" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
$(echo "$PROMPT_CONTENT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')" > "$OUTPUT_FILE" 2>/dev/null

    [[ -s "$OUTPUT_FILE" ]] && REVIEW_OK=true
  fi
fi

# --- All levels failed ---
if [[ "$REVIEW_OK" != "true" ]]; then
  echo "⚠ All Gemini endpoints unavailable — allowing commit."
  rm -f "$PROMPT_FILE" "$OUTPUT_FILE"
  exit 0
fi

# --- Parse score ---
SCORE=$(grep -oP 'Score:\s*\K[\d.]+(?=\s*/\s*10)' "$OUTPUT_FILE" | head -1)

if [[ -z "$SCORE" ]]; then
  echo "⚠ Could not parse score from Gemini output — allowing commit. Review manually:"
  echo "---"
  cat "$OUTPUT_FILE"
  echo "---"
  rm -f "$PROMPT_FILE" "$OUTPUT_FILE"
  exit 0
fi

# --- Gate ---
PASS=$(echo "$SCORE >= 9.0" | bc -l 2>/dev/null || echo "0")

if [[ "$PASS" == "1" ]]; then
  echo "✅ Gemini review: $SCORE/10 — PASS"
  rm -f "$PROMPT_FILE" "$OUTPUT_FILE"
  exit 0
else
  echo "❌ Gemini review: $SCORE/10 — NEEDS WORK (threshold: 9.0)"
  echo ""
  cat "$OUTPUT_FILE"
  echo ""
  echo "Fix the findings above and try again. Bypass with: GEMINI_REVIEW=0 git commit ..."
  rm -f "$PROMPT_FILE" "$OUTPUT_FILE"
  exit 1
fi
