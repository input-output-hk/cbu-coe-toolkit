#!/usr/bin/env bash
#
# Gemini pre-commit review hook for models/ directory.
# Blocks commit if Gemini scores changes < 9.0.
# Fail-open: if gemini is not installed or output is unparseable, warn and allow.
#
set -euo pipefail

# --- Opt-out ---
if [[ "${GEMINI_REVIEW:-}" == "0" ]]; then
  exit 0
fi

# --- Check gemini CLI ---
if ! command -v gemini &> /dev/null; then
  echo "⚠ Gemini CLI not installed — skipping review. Install: npm install -g @google/gemini-cli"
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

# Include CLAUDE.md as context
if [[ -f "$REPO_ROOT/CLAUDE.md" ]]; then
  echo "### CLAUDE.md" >> "$PROMPT_FILE"
  echo '```' >> "$PROMPT_FILE"
  cat "$REPO_ROOT/CLAUDE.md" >> "$PROMPT_FILE"
  echo '```' >> "$PROMPT_FILE"
fi

# --- Health check (find available model, with one retry) ---
MODELS=("gemini-3-pro-preview" "gemini-3-pro" "gemini-2.5-pro")
AVAILABLE_MODEL=""

cd "$REPO_ROOT" || { echo "⚠ Cannot cd to repo root — allowing commit."; exit 0; }

find_model() {
  for MODEL in "${MODELS[@]}"; do
    if echo "ok" | timeout 45 gemini -m "$MODEL" > /dev/null 2>&1; then
      AVAILABLE_MODEL="$MODEL"
      return 0
    fi
  done
  return 1
}

if ! find_model; then
  echo "⚠ All models capacity-exhausted. Retrying in 60s..."
  sleep 60
  if ! find_model; then
    echo "⚠ All Gemini models unavailable after retry (tried: ${MODELS[*]}) — allowing commit."
    rm -f "$PROMPT_FILE"
    exit 0
  fi
fi

echo "   Model: $AVAILABLE_MODEL"

# --- Invoke Gemini ---
OUTPUT_FILE=$(mktemp /tmp/gemini-output-XXXXXX.md)
if ! cat "$PROMPT_FILE" | timeout 120 gemini -m "$AVAILABLE_MODEL" > "$OUTPUT_FILE" 2>/dev/null; then
  echo "⚠ Gemini review timed out or failed — allowing commit."
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
