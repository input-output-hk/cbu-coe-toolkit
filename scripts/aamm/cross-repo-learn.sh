#!/usr/bin/env bash
# AAMM Cross-Repo Learning Engine
# Usage: ./cross-repo-learn.sh [results_dir]
#
# Scans all *-report.json files in results_dir, identifies best practices
# that some repos do well and others don't, and outputs:
#   - best-practices.json: exemplar signals + which repos could benefit
#   - cross-repo-insights.md: human-readable summary
#
# Designed to be run AFTER a batch scan of multiple repos.
# The output feeds into per-repo recommendations in the next scan cycle.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="${1:-$TOOLKIT_ROOT/scans/ai-augmentation/results}"

if [[ ! -d "$RESULTS_DIR" ]]; then
  echo "ERROR: Results directory not found: $RESULTS_DIR" >&2
  exit 1
fi

REPORTS=("$RESULTS_DIR"/*-report.json)
if [[ ${#REPORTS[@]} -lt 2 ]]; then
  echo "Need at least 2 repo reports for cross-repo analysis. Found: ${#REPORTS[@]}" >&2
  exit 0
fi

echo "=== AAMM Cross-Repo Learning Engine ==="
echo "  Reports: ${#REPORTS[@]}"
echo ""

LEARNINGS_FILE="$RESULTS_DIR/best-practices.json"
INSIGHTS_FILE="$RESULTS_DIR/cross-repo-insights.md"

# ============================================================
# COLLECT SIGNAL SCORES ACROSS ALL REPOS
# ============================================================

# Build a JSON array of all repos with key scores
ALL_REPOS="[]"
for report in "${REPORTS[@]}"; do
  [[ -f "$report" ]] || continue
  REPO_NAME=$(jq -r '.repo // .repository.full_name // "unknown"' "$report" 2>/dev/null || continue)
  [[ "$REPO_NAME" == "unknown" || "$REPO_NAME" == "null" ]] && continue

  # Extract key signals — handle both direct and nested formats
  R_COMPOSITE=$(jq -r '.readiness.composite // 0' "$report" 2>/dev/null || echo 0)
  A_COMPOSITE=$(jq -r '.adoption.composite // 0' "$report" 2>/dev/null || echo 0)
  PRIMARY_LANG=$(jq -r '.primary_language // "unknown"' "$report" 2>/dev/null || echo "unknown")

  # Navigate signals
  N5=$(jq -r '.pillars.navigate.signals.N5_code_consistency.score // 0' "$report" 2>/dev/null || echo 0)
  N7=$(jq -r '.pillars.navigate.signals.N7_reproducible_env.score // 0' "$report" 2>/dev/null || echo 0)
  N8=$(jq -r '.pillars.navigate.signals.N8_repo_foundations.score // 0' "$report" 2>/dev/null || echo 0)

  # Understand signals
  U2=$(jq -r '.pillars.understand.signals.U2_doc_coverage.score // 0' "$report" 2>/dev/null || echo 0)
  U3=$(jq -r '.pillars.understand.signals.U3_readme_substance.score // 0' "$report" 2>/dev/null || echo 0)
  U4=$(jq -r '.pillars.understand.signals.U4_architecture_docs.score // 0' "$report" 2>/dev/null || echo 0)

  # Verify signals
  V2=$(jq -r '.pillars.verify.signals.V2_test_categorization.score // 0' "$report" 2>/dev/null || echo 0)
  V4=$(jq -r '.pillars.verify.signals.V4_coverage_config.score // 0' "$report" 2>/dev/null || echo 0)

  # Domain profile
  HAS_DOMAIN=$(jq -r 'if .domain_profile != null then "true" else "false" end' "$report" 2>/dev/null || echo "false")

  ALL_REPOS=$(echo "$ALL_REPOS" | jq \
    --arg repo "$REPO_NAME" --arg lang "$PRIMARY_LANG" \
    --argjson r "$R_COMPOSITE" --argjson a "$A_COMPOSITE" \
    --argjson n5 "$N5" --argjson n7 "$N7" --argjson n8 "$N8" \
    --argjson u2 "$U2" --argjson u3 "$U3" --argjson u4 "$U4" \
    --argjson v2 "$V2" --argjson v4 "$V4" \
    --argjson dom "$HAS_DOMAIN" \
    '. + [{
      repo: $repo, language: $lang,
      readiness: $r, adoption: $a,
      N5: $n5, N7: $n7, N8: $n8,
      U2: $u2, U3: $u3, U4: $u4,
      V2: $v2, V4: $v4,
      has_domain: $dom
    }]')
done

REPO_COUNT=$(echo "$ALL_REPOS" | jq 'length')
echo "  Analyzed: $REPO_COUNT repos"

# ============================================================
# IDENTIFY EXEMPLARS AND GAPS
# ============================================================

BEST_PRACTICES="[]"

# For each signal, find repos that score high (>= 80) and repos that score low (<= 40)
for signal in N5 N7 N8 U2 U3 U4 V2 V4; do
  SIGNAL_NAME=""
  case "$signal" in
    N5) SIGNAL_NAME="Code Consistency (linter + formatter)" ;;
    N7) SIGNAL_NAME="Reproducible Environment (Nix/Docker + lockfiles)" ;;
    N8) SIGNAL_NAME="Repo Foundations (CODEOWNERS + .gitignore + SECURITY.md)" ;;
    U2) SIGNAL_NAME="Documentation Coverage (doc comments on public APIs)" ;;
    U3) SIGNAL_NAME="README Substance (setup, usage, architecture sections)" ;;
    U4) SIGNAL_NAME="Architecture Documentation (ADRs, ARCHITECTURE.md)" ;;
    V2) SIGNAL_NAME="Test Categorization (distinct test types: unit, property, golden, etc.)" ;;
    V4) SIGNAL_NAME="Coverage Configuration (coverage tool + threshold in CI)" ;;
  esac

  EXEMPLARS=$(echo "$ALL_REPOS" | jq -r --arg s "$signal" '[.[] | select(.[$s] >= 80)] | map(.repo) | join(", ")')
  LAGGARDS=$(echo "$ALL_REPOS" | jq -r --arg s "$signal" '[.[] | select(.[$s] <= 40)] | map(.repo) | join(", ")')
  EXEMPLAR_COUNT=$(echo "$ALL_REPOS" | jq --arg s "$signal" '[.[] | select(.[$s] >= 80)] | length')
  LAGGARD_COUNT=$(echo "$ALL_REPOS" | jq --arg s "$signal" '[.[] | select(.[$s] <= 40)] | length')

  if [[ $EXEMPLAR_COUNT -gt 0 && $LAGGARD_COUNT -gt 0 ]]; then
    # Get a specific example from the top exemplar
    TOP_EXEMPLAR=$(echo "$ALL_REPOS" | jq -r --arg s "$signal" '[.[] | select(.[$s] >= 80)] | sort_by(-.[$s]) | .[0].repo')
    TOP_SCORE=$(echo "$ALL_REPOS" | jq -r --arg s "$signal" '[.[] | select(.[$s] >= 80)] | sort_by(-.[$s]) | .[0][$s]')

    BEST_PRACTICES=$(echo "$BEST_PRACTICES" | jq \
      --arg sig "$signal" --arg name "$SIGNAL_NAME" \
      --arg exemplars "$EXEMPLARS" --arg laggards "$LAGGARDS" \
      --arg top "$TOP_EXEMPLAR" --argjson topScore "$TOP_SCORE" \
      --argjson exCount "$EXEMPLAR_COUNT" --argjson lagCount "$LAGGARD_COUNT" \
      '. + [{
        signal: $sig,
        signal_name: $name,
        exemplar_repos: $exemplars,
        exemplar_count: $exCount,
        laggard_repos: $laggards,
        laggard_count: $lagCount,
        top_exemplar: $top,
        top_score: $topScore,
        recommendation: "See \($top) for a working example of \($name)"
      }]')
  fi
done

# ============================================================
# OUTPUT
# ============================================================

BP_COUNT=$(echo "$BEST_PRACTICES" | jq 'length')

# JSON output
cat > "$LEARNINGS_FILE" << ENDJSON
{
  "scan_date": "$(date +%Y-%m-%d)",
  "repos_analyzed": $REPO_COUNT,
  "best_practices_found": $BP_COUNT,
  "repos": $ALL_REPOS,
  "best_practices": $BEST_PRACTICES
}
ENDJSON

# Markdown insights
cat > "$INSIGHTS_FILE" << INSEOF
# AAMM Cross-Repo Insights

**Scan date:** $(date +%Y-%m-%d) · **Repos analyzed:** $REPO_COUNT

---

## Best Practices: Learn from Peers

These signals show clear exemplars that others can learn from:

| Signal | Exemplars (≥80) | Can Improve (≤40) | Top Example |
|--------|-----------------|-------------------|-------------|
INSEOF

echo "$BEST_PRACTICES" | jq -r '.[] | "| **\(.signal)** \(.signal_name) | \(.exemplar_repos) (\(.exemplar_count)) | \(.laggard_repos) (\(.laggard_count)) | \(.top_exemplar) (\(.top_score)) |"' >> "$INSIGHTS_FILE"

cat >> "$INSIGHTS_FILE" << INSEOF2

---

## Repo Comparison

| Repo | Language | Readiness | Adoption | Quadrant |
|------|----------|-----------|----------|----------|
INSEOF2

echo "$ALL_REPOS" | jq -r '.[] | "| \(.repo) | \(.language) | \(.readiness) | \(.adoption) | \(if .readiness >= 45 and .adoption >= 45 then "AI-Native" elif .readiness >= 45 then "Fertile Ground" elif .adoption >= 45 then "Risky Acceleration" else "Traditional" end) |"' >> "$INSIGHTS_FILE"

cat >> "$INSIGHTS_FILE" << INSEOF3

---

## How to Use These Insights

1. **Per-repo reports** now include recommendations referencing exemplar repos
2. **Teams scoring low** on a signal can look at the exemplar's implementation for a working example
3. **Run this after each batch scan** to update cross-repo learnings
4. **Feed \`best-practices.json\`** into the next scan cycle for contextual recommendations
INSEOF3

echo ""
echo "=== Cross-Repo Learning Complete ==="
echo "  Best practices found: $BP_COUNT"
echo "  Insights: $INSIGHTS_FILE"
echo "  Data: $LEARNINGS_FILE"
