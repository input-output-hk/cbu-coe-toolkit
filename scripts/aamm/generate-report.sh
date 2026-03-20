#!/usr/bin/env bash
# AAMM Report Generator
# Usage: ./generate-report.sh owner/repo [data_dir] [output_dir]
# Takes readiness + adoption score JSONs and generates .md + .json report.
# Run score-readiness.sh and score-adoption.sh first.
#
# Input: $data_dir/readiness-scores.json, $data_dir/adoption-scores.json
# Output: $output_dir/{repo}-report.md + .json

set -euo pipefail

REPO="${1:?Usage: $0 owner/repo [data_dir] [output_dir]}"
DATADIR="${2:-/tmp/aamm-$(echo "$REPO" | tr '/' '-')}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${3:-$TOOLKIT_ROOT/scans/ai-augmentation/results}"

REPONAME="${REPO##*/}"
READINESS_JSON="$DATADIR/readiness-scores.json"
ADOPTION_JSON="$DATADIR/adoption-scores.json"

if [[ ! -f "$READINESS_JSON" ]]; then
  echo "ERROR: $READINESS_JSON not found. Run score-readiness.sh first." >&2
  exit 1
fi
if [[ ! -f "$ADOPTION_JSON" ]]; then
  echo "ERROR: $ADOPTION_JSON not found. Run score-adoption.sh first." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# --- Extract scores ---
R_COMPOSITE=$(jq -r '.readiness.composite' "$READINESS_JSON")
R_RAW=$(jq -r '.readiness.raw' "$READINESS_JSON")
R_PENALTIES=$(jq -r '.readiness.penalties_total' "$READINESS_JSON")
NAV_SCORE=$(jq -r '.pillars.navigate.score' "$READINESS_JSON")
UND_SCORE=$(jq -r '.pillars.understand.score' "$READINESS_JSON")
VER_SCORE=$(jq -r '.pillars.verify.score' "$READINESS_JSON")
HARD_GATE=$(jq -r '.pillars.verify.hard_gate' "$READINESS_JSON")

A_COMPOSITE=$(jq -r '.adoption.composite' "$ADOPTION_JSON")
PRIMARY_LANG=$(jq -r '.primary_language' "$READINESS_JSON")
PRIMARY_PCT=$(jq -r '.primary_language_pct' "$READINESS_JSON")

# Determine quadrant
QUADRANT="Traditional"
R_NUM=$(echo "$R_COMPOSITE" | bc -l)
A_NUM=$(echo "$A_COMPOSITE" | bc -l)
if (( $(echo "$R_NUM >= 45" | bc -l) )) && (( $(echo "$A_NUM >= 45" | bc -l) )); then
  QUADRANT="AI-Native"
elif (( $(echo "$R_NUM >= 45" | bc -l) )); then
  QUADRANT="Fertile Ground"
elif (( $(echo "$A_NUM >= 45" | bc -l) )); then
  QUADRANT="Risky Acceleration"
fi

# Metadata
SCAN_DATE=$(date +%Y-%m-%d)
DESCRIPTION=$(jq -r '.description // "N/A"' "$DATADIR/metadata.json" 2>/dev/null || echo "N/A")
DEFAULT_BRANCH=$(jq -r '.default_branch // "main"' "$DATADIR/metadata.json" 2>/dev/null || echo "main")
REPO_SIZE=$(jq -r '.size // 0' "$DATADIR/metadata.json" 2>/dev/null || echo 0)
OPEN_ISSUES=$(jq -r '.open_issues_count // 0' "$DATADIR/metadata.json" 2>/dev/null || echo 0)
STARS=$(jq -r '.stargazers_count // 0' "$DATADIR/metadata.json" 2>/dev/null || echo 0)
LICENSE=$(jq -r '.license // "Unknown"' "$DATADIR/metadata.json" 2>/dev/null || echo "Unknown")
CREATED=$(jq -r '.created_at // "Unknown"' "$DATADIR/metadata.json" 2>/dev/null || echo "Unknown")
LAST_PUSH=$(jq -r '.pushed_at // "Unknown"' "$DATADIR/metadata.json" 2>/dev/null || echo "Unknown")
IS_PRIVATE=$(jq -r '.private // false' "$DATADIR/metadata.json" 2>/dev/null || echo false)

# Language breakdown
LANG_BREAKDOWN=$(jq -r '.[] | "\(.key): \(.pct)%"' "$DATADIR/languages-pct.json" 2>/dev/null | head -5 | tr '\n' ', ' | sed 's/,$//')

# Tree stats
SRC_COUNT=$(jq -r '.tree_stats.source_files' "$READINESS_JSON")
TEST_COUNT=$(jq -r '.tree_stats.test_files' "$READINESS_JSON")
DIR_COUNT=$(jq -r '.tree_stats.directories' "$READINESS_JSON")
MAX_DEPTH=$(jq -r '.tree_stats.max_depth' "$READINESS_JSON")
TREE_ENTRIES=$(jq '.tree | length' "$DATADIR/tree.json" 2>/dev/null || echo 0)

# --- Generate Markdown Report ---
MD_FILE="$OUTPUT_DIR/${REPONAME}-report.md"

cat > "$MD_FILE" << 'HEADER'
HEADER

cat >> "$MD_FILE" << EOF
# AAMM — Sample Report: $REPO

**Model version:** 1.0 · **Scan date:** $SCAN_DATE · **Scanned by:** CoE (Dorin Solomon)

---

## Risks

EOF

# Add risk flags from both axes
echo "| Severity | Risk | Detail |" >> "$MD_FILE"
echo "|----------|------|--------|" >> "$MD_FILE"

# Readiness penalties as risks
jq -r '.penalties | to_entries[] | select(.value.applied == true) | "| 🟡 Medium | \(.key | gsub("_"; " ") | ascii_upcase) | \(.value.evidence // "See evidence log") |"' "$READINESS_JSON" 2>/dev/null >> "$MD_FILE" || true

# Adoption risk flags
jq -r '.risk_flags[] | "| \(if .severity == "high" then "🔴 High" elif .severity == "medium" then "🟡 Medium" else "ℹ️ Info" end) | \(.risk) | \(.detail) |"' "$ADOPTION_JSON" 2>/dev/null >> "$MD_FILE" || true

cat >> "$MD_FILE" << EOF

---

## Summary

| Axis | Score | Detail |
|------|-------|--------|
| **AI Readiness** | **$R_COMPOSITE / 100** | Navigate: $NAV_SCORE, Understand: $UND_SCORE, Verify: $VER_SCORE. Penalties: $R_PENALTIES. |
| **AI Adoption** | **$A_COMPOSITE / 100** | $(jq -r '.dimensions | to_entries | map("\(.key | ascii_upcase[0:1] + .key[1:]): \(.value.stage)") | join(", ")' "$ADOPTION_JSON") |
| **Quadrant** | **$QUADRANT** | $(case "$QUADRANT" in "Fertile Ground") echo "High readiness, low adoption." ;; "AI-Native") echo "High readiness, high adoption." ;; "Risky Acceleration") echo "Low readiness, high adoption." ;; *) echo "Low readiness, low adoption." ;; esac) |

\`\`\`
                        AI Adoption →
                   Low                High
              ┌─────────────┬─────────────┐
         High │$([ "$QUADRANT" = "Fertile Ground" ] && echo " ★ FERTILE   " || echo "  FERTILE    ")│$([ "$QUADRANT" = "AI-Native" ] && echo " ★ AI-NATIVE " || echo "  AI-NATIVE  ")│
              │$([ "$QUADRANT" = "Fertile Ground" ] && echo "   GROUND    " || echo "   GROUND    ")│$([ "$QUADRANT" = "AI-Native" ] && echo "             " || echo "             ")│
AI Readiness  │$([ "$QUADRANT" = "Fertile Ground" ] && echo " ($REPONAME) " || echo "             ") │              │
    ↑         │             │              │
              ├─────────────┼─────────────┤
              │$([ "$QUADRANT" = "Traditional" ] && echo " ★           " || echo "             ")│$([ "$QUADRANT" = "Risky Acceleration" ] && echo " ★ RISKY     " || echo "  RISKY      ")│
         Low  │ TRADITIONAL │ ACCELERATION │
              └─────────────┴─────────────┘
\`\`\`

---

## AI Readiness: $R_COMPOSITE / 100

### Pillar 1: Navigate — $NAV_SCORE / 100 (weight: 0.35)

**Poate AI-ul lucra eficient aici?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
EOF

# Navigate signals
for sig in N1_file_organization N2_file_granularity N3_module_boundaries N4_separation_of_concerns N5_code_consistency N6_cicd_pipeline N7_reproducible_env N8_repo_foundations; do
  score=$(jq -r ".pillars.navigate.signals.${sig}.score" "$READINESS_JSON")
  weight=$(jq -r ".pillars.navigate.signals.${sig}.weight" "$READINESS_JSON")
  evidence=$(jq -r ".pillars.navigate.signals.${sig}.evidence" "$READINESS_JSON")
  label=$(echo "$sig" | sed 's/_/ /g' | sed 's/\b\(.\)/\U\1/g' | sed 's/^N[0-9] /N\0/')
  num=$(echo "$sig" | grep -oP 'N\d')
  echo "| $num | ${sig#*_} | **$score** | $weight | $evidence |" >> "$MD_FILE"
done

cat >> "$MD_FILE" << EOF

---

### Pillar 2: Understand — $UND_SCORE / 100 (weight: 0.35)

**Poate AI-ul înțelege intent-ul codului?**

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
EOF

# Understand signals
for sig in U1_type_safety U2_doc_coverage U3_readme_substance U4_architecture_docs U5_schema_definitions; do
  score=$(jq -r ".pillars.understand.signals.${sig}.score" "$READINESS_JSON")
  weight=$(jq -r ".pillars.understand.signals.${sig}.weight" "$READINESS_JSON")
  evidence=$(jq -r ".pillars.understand.signals.${sig}.evidence" "$READINESS_JSON")
  num=$(echo "$sig" | grep -oP 'U\d')
  echo "| $num | ${sig#*_} | **$score** | $weight | $evidence |" >> "$MD_FILE"
done

cat >> "$MD_FILE" << EOF

---

### Pillar 3: Verify — $VER_SCORE / 100 (weight: 0.30)

**Poate AI-ul verifica ce produce?**

**Hard Gate:** $HARD_GATE

| # | Signal | Score | Weight | Evidence |
|---|--------|-------|--------|----------|
EOF

# Verify signals
for sig in V1_test_source_ratio V2_test_categorization V3_ci_test_execution V4_coverage_config; do
  score=$(jq -r ".pillars.verify.signals.${sig}.score" "$READINESS_JSON")
  weight=$(jq -r ".pillars.verify.signals.${sig}.weight" "$READINESS_JSON")
  evidence=$(jq -r ".pillars.verify.signals.${sig}.evidence" "$READINESS_JSON")
  num=$(echo "$sig" | grep -oP 'V\d')
  echo "| $num | ${sig#*_} | **$score** | $weight | $evidence |" >> "$MD_FILE"
done

cat >> "$MD_FILE" << EOF

---

### Cross-Pillar Constraints

\`\`\`
Readiness_raw = Navigate × 0.35 + Understand × 0.35 + Verify × 0.30
              = $NAV_SCORE × 0.35 + $UND_SCORE × 0.35 + $VER_SCORE × 0.30
              = $R_RAW

Constraints: $(jq -r '.readiness.constraints_applied | if length == 0 then "none applied" else join(", ") end' "$READINESS_JSON")

Penalties: $R_PENALTIES
Readiness = $R_COMPOSITE
\`\`\`

### Penalties

| Penalty | Applied? | Impact | Evidence |
|---------|----------|--------|----------|
EOF

jq -r '.penalties | to_entries[] | "| \(.key | gsub("_"; " ")) | \(if .value.applied then "**YES**" else "NO" end) | \(.value.impact) | \(.value.evidence // "N/A") |"' "$READINESS_JSON" 2>/dev/null >> "$MD_FILE" || true

cat >> "$MD_FILE" << EOF

---

## AI Adoption: $A_COMPOSITE / 100

### Detection Layer Results

| Layer | Method | Result |
|-------|--------|--------|
EOF

jq -r '.detection_layers | to_entries[] | "| **\(.key)** | \(.key | split("_")[0]) | \(if .value.count == 0 then "None" elif .value.count > 0 then "\(.value.count) found" else "N/A" end) — \(.value.files // .value.inaccessible // "") |"' "$ADOPTION_JSON" 2>/dev/null >> "$MD_FILE" || true

cat >> "$MD_FILE" << EOF

### Per-Dimension Scoring

| Dimension | Stage | Score | Condition A | Condition B | Annotation |
|-----------|-------|-------|-------------|-------------|------------|
EOF

for dim in code testing security delivery governance; do
  stage=$(jq -r ".dimensions.${dim}.stage" "$ADOPTION_JSON")
  score=$(jq -r ".dimensions.${dim}.score" "$ADOPTION_JSON")
  ca=$(jq -r ".dimensions.${dim}.condition_a.met" "$ADOPTION_JSON")
  ca_ev=$(jq -r ".dimensions.${dim}.condition_a.evidence" "$ADOPTION_JSON")
  cb=$(jq -r ".dimensions.${dim}.condition_b.met" "$ADOPTION_JSON")
  cb_ev=$(jq -r ".dimensions.${dim}.condition_b.evidence" "$ADOPTION_JSON")
  ann=$(jq -r ".dimensions.${dim}.annotation" "$ADOPTION_JSON")
  ca_mark=$([[ "$ca" == "true" ]] && echo "✓" || echo "✗")
  cb_mark=$([[ "$cb" == "true" ]] && echo "✓" || echo "✗")
  echo "| **${dim^}** | $stage | $score | $ca_mark $ca_ev | $cb_mark $cb_ev | $ann |" >> "$MD_FILE"
done

cat >> "$MD_FILE" << EOF

---

## Evidence Log

### Repository Metadata

| Field | Value |
|-------|-------|
| Repository | \`$REPO\` |
| Description | $DESCRIPTION |
| Default branch | \`$DEFAULT_BRANCH\` |
| Private | $IS_PRIVATE |
| Primary language | $PRIMARY_LANG ($PRIMARY_PCT%) |
| Languages | $LANG_BREAKDOWN |
| Size | ${REPO_SIZE} KB |
| Open issues | $OPEN_ISSUES |
| Stars | $STARS |
| License | $LICENSE |
| Created | $CREATED |
| Last push | $LAST_PUSH |
| Tree entries | $TREE_ENTRIES |
| Source files | $SRC_COUNT |
| Test files | $TEST_COUNT |
| Directories | $DIR_COUNT |
| Max depth | $MAX_DEPTH |

### Score Summary

\`\`\`
Navigate   = $NAV_SCORE  (weight 0.35)
Understand = $UND_SCORE  (weight 0.35)
Verify     = $VER_SCORE  (weight 0.30)

Readiness_raw = $R_RAW
Penalties: $R_PENALTIES
Readiness = $R_COMPOSITE

Adoption composite = $A_COMPOSITE
  $(jq -r '.dimensions | to_entries | map("\(.key | ascii_upcase[0:1] + .key[1:]): \(.value.stage) (\(.value.score))") | join(", ")' "$ADOPTION_JSON")

Quadrant: $QUADRANT
\`\`\`
EOF

echo "" >> "$MD_FILE"
echo "Report generated: $MD_FILE"

# --- Generate JSON Report ---
JSON_FILE="$OUTPUT_DIR/${REPONAME}-report.json"

jq -s --arg date "$SCAN_DATE" --arg quad "$QUADRANT" '
{
  metadata: {
    model_version: "1.0",
    scan_date: $date,
    scanned_by: "CoE (Dorin Solomon)"
  },
  repository: (.[2] // {} | {
    full_name: .full_name,
    description: .description,
    default_branch: .default_branch,
    primary_language: .[3][0].key,
    size_kb: .size,
    license: .license,
    stars: .stargazers_count,
    open_issues: .open_issues_count,
    private: .private
  }),
  readiness: .[0].readiness + {
    pillars: .[0].pillars
  } + {
    penalties: .[0].penalties
  },
  adoption: .[1].adoption + {
    detection_layers: .[1].detection_layers,
    dimensions: .[1].dimensions,
    annotations: .[1].annotations,
    risk_flags: .[1].risk_flags
  },
  quadrant: $quad
}' "$READINESS_JSON" "$ADOPTION_JSON" "$DATADIR/metadata.json" "$DATADIR/languages-pct.json" > "$JSON_FILE" 2>/dev/null || {
  # Fallback: simpler merge if jq -s fails
  echo "Warning: Complex jq merge failed, using simple merge" >&2
  jq --arg date "$SCAN_DATE" --arg quad "$QUADRANT" \
    --slurpfile adopt "$ADOPTION_JSON" \
    '. + {
      metadata: { model_version: "1.0", scan_date: $date, scanned_by: "CoE (Dorin Solomon)" },
      adoption: $adopt[0].adoption,
      adoption_dimensions: $adopt[0].dimensions,
      adoption_layers: $adopt[0].detection_layers,
      quadrant: $quad
    }' "$READINESS_JSON" > "$JSON_FILE"
}

echo "JSON generated: $JSON_FILE"
echo ""
echo "=== Report generation complete ==="
echo "  Markdown: $MD_FILE"
echo "  JSON:     $JSON_FILE"
