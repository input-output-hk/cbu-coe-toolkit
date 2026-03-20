#!/usr/bin/env bash
# AAMM Full Scan Orchestrator
# Usage: ./scan-repo.sh owner/repo [overrides.json]
# Runs the complete pipeline: collect → score → generate report.
# Output: scans/ai-augmentation/results/{repo}-report.{md,json}
#
# Optional overrides.json for signals requiring agent judgment.
# The overrides file is passed to both score-readiness.sh and score-adoption.sh.
#
# This script runs non-interactively — no confirmations needed.

set -euo pipefail

REPO="${1:?Usage: $0 owner/repo [overrides.json]}"
OVERRIDES="${2:-}"
REPONAME="${REPO##*/}"
DATADIR="/tmp/aamm-$(echo "$REPO" | tr '/' '-')"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="$TOOLKIT_ROOT/scans/ai-augmentation/results"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  AAMM Full Scan: $REPO"
echo "║  Output: $OUTPUT_DIR/${REPONAME}-report.{md,json}"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# --- Step 1: Collect all data ---
echo "━━━ Step 1/4: Data Collection ━━━"
"$SCRIPT_DIR/collect-all.sh" "$REPO" "$DATADIR"
echo ""

# --- Step 2: Score Readiness ---
echo "━━━ Step 2/4: Readiness Scoring ━━━"
"$SCRIPT_DIR/score-readiness.sh" "$REPO" "$DATADIR" "$OVERRIDES" > "$DATADIR/readiness-scores.json"
R_SCORE=$(jq -r '.readiness.composite' "$DATADIR/readiness-scores.json")
echo "  Readiness composite: $R_SCORE"
echo ""

# --- Step 3: Score Adoption ---
echo "━━━ Step 3/4: Adoption Scoring ━━━"
"$SCRIPT_DIR/score-adoption.sh" "$REPO" "$DATADIR" "$OVERRIDES" > "$DATADIR/adoption-scores.json"
A_SCORE=$(jq -r '.adoption.composite' "$DATADIR/adoption-scores.json")
echo "  Adoption composite: $A_SCORE"
echo ""

# --- Step 4: Generate Report ---
echo "━━━ Step 4/4: Report Generation ━━━"
"$SCRIPT_DIR/generate-report.sh" "$REPO" "$DATADIR" "$OUTPUT_DIR"
echo ""

# --- Summary ---
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Scan Complete: $REPO"
echo "║"
echo "║  Readiness: $R_SCORE / 100"
echo "║  Adoption:  $A_SCORE / 100"
echo "║"

# Quadrant
if (( $(echo "$R_SCORE >= 45" | bc -l) )) && (( $(echo "$A_SCORE >= 45" | bc -l) )); then
  echo "║  Quadrant:  AI-Native"
elif (( $(echo "$R_SCORE >= 45" | bc -l) )); then
  echo "║  Quadrant:  Fertile Ground"
elif (( $(echo "$A_SCORE >= 45" | bc -l) )); then
  echo "║  Quadrant:  Risky Acceleration"
else
  echo "║  Quadrant:  Traditional"
fi

echo "║"
echo "║  Reports:"
echo "║    $OUTPUT_DIR/${REPONAME}-report.md"
echo "║    $OUTPUT_DIR/${REPONAME}-report.json"
echo "║  Raw data: $DATADIR/"
echo "╚══════════════════════════════════════════════════════════════╝"
