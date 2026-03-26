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

# --- Helpers ---
# Escape pipe characters in strings destined for markdown table cells.
# Unescaped | breaks column alignment (e.g., Haddock "{- |" syntax).
md_escape_pipes() { echo "$1" | sed 's/|/\\|/g'; }

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

# Pre-compute adoption dimension summaries (jq interpolation can't live inside heredocs)
ADOPTION_DIM_SUMMARY=$(jq -r '.dimensions | to_entries | map("\(.key | . as $k | ascii_upcase[0:1] + $k[1:]): \(.value.stage)") | join(", ")' "$ADOPTION_JSON")
ADOPTION_DIM_DETAIL=$(jq -r '.dimensions | to_entries | map("\(.key | . as $k | ascii_upcase[0:1] + $k[1:]): \(.value.stage) (\(.value.score))") | join(", ")' "$ADOPTION_JSON")

cat >> "$MD_FILE" << EOF

---

## Summary

| Axis | Score | Detail |
|------|-------|--------|
| **AI Readiness** | **$R_COMPOSITE / 100** | Navigate: $NAV_SCORE, Understand: $UND_SCORE, Verify: $VER_SCORE. Penalties: $R_PENALTIES. |
| **AI Adoption** | **$A_COMPOSITE / 100** | $ADOPTION_DIM_SUMMARY |
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
EOF

# Domain profile section (if high-assurance)
HAS_DOMAIN_PROFILE=$(jq -r 'if .domain_profile != null then "object" else "null" end' "$READINESS_JSON" 2>/dev/null || echo "null")
if [[ "$HAS_DOMAIN_PROFILE" == "object" ]]; then
  DOMAIN_NAME=$(jq -r '.domain_profile.domain' "$READINESS_JSON")
  DOMAIN_EVIDENCE=$(jq -r '.domain_profile.detection_evidence' "$READINESS_JSON")
  DOMAIN_FRAMING=$(jq -r '.domain_profile.recommendation_framing' "$READINESS_JSON")

  cat >> "$MD_FILE" << DOMEOF

## Domain Profile: ${DOMAIN_NAME^}

**Detected via:** $DOMAIN_EVIDENCE

**AI Value Framing:** $DOMAIN_FRAMING

### Supplementary Signals

| Signal | Status | Detail |
|--------|--------|--------|
DOMEOF

  # Formal spec
  BD_AGDA=$(jq -r '.domain_profile.supplementary_signals.formal_spec_presence.agda_files // 0' "$READINESS_JSON")
  BD_FORMAL=$(jq -r '.domain_profile.supplementary_signals.formal_spec_presence.formal_spec_dirs // 0' "$READINESS_JSON")
  BD_CDDL=$(jq -r '.domain_profile.supplementary_signals.formal_spec_presence.cddl_files // 0' "$READINESS_JSON")
  if [[ $BD_AGDA -gt 0 || $BD_FORMAL -gt 0 ]]; then
    echo "| Formal spec presence | ✓ | $BD_AGDA .agda files, $BD_FORMAL formal-spec dirs, $BD_CDDL .cddl files |" >> "$MD_FILE"
  else
    echo "| Formal spec presence | ✗ | Not detected |" >> "$MD_FILE"
  fi

  # Conformance
  BD_CONF_DIRS=$(jq -r '.domain_profile.supplementary_signals.conformance_testing.conformance_dirs // 0' "$READINESS_JSON")
  BD_CONF_ORACLE=$(jq -r '.domain_profile.supplementary_signals.conformance_testing.conformance_oracle // 0' "$READINESS_JSON")
  if [[ $BD_CONF_DIRS -gt 0 || $BD_CONF_ORACLE -gt 0 ]]; then
    echo "| Conformance testing | ✓ | $BD_CONF_DIRS conformance dirs, oracle=$BD_CONF_ORACLE |" >> "$MD_FILE"
  else
    echo "| Conformance testing | ✗ | Not detected |" >> "$MD_FILE"
  fi

  # Generator discipline
  BD_COVER=$(jq -r '.domain_profile.supplementary_signals.generator_discipline.cover_classify // 0' "$READINESS_JSON")
  BD_ARB=$(jq -r '.domain_profile.supplementary_signals.generator_discipline.custom_arbitrary // 0' "$READINESS_JSON")
  BD_ADV=$(jq -r '.domain_profile.supplementary_signals.generator_discipline.adversarial_generators // 0' "$READINESS_JSON")
  GD_STATUS="✗"
  [[ $BD_COVER -gt 0 || $BD_ARB -gt 0 ]] && GD_STATUS="✓"
  echo "| Generator discipline | $GD_STATUS | cover/classify=$BD_COVER, custom Arbitrary=$BD_ARB, adversarial=$BD_ADV |" >> "$MD_FILE"

  # Concurrency testing
  BD_IOSIM=$(jq -r '.domain_profile.supplementary_signals.concurrency_testing.io_sim // 0' "$READINESS_JSON")
  IO_STATUS=$([[ $BD_IOSIM -gt 0 ]] && echo "✓" || echo "✗")
  echo "| Concurrency testing (io-sim) | $IO_STATUS | io-sim=$BD_IOSIM |" >> "$MD_FILE"

  # Benchmark regression
  BD_BENCH_F=$(jq -r '.domain_profile.supplementary_signals.benchmark_regression.bench_files // 0' "$READINESS_JSON")
  BD_BENCH_D=$(jq -r '.domain_profile.supplementary_signals.benchmark_regression.bench_dirs // 0' "$READINESS_JSON")
  BD_BENCH_CI=$(jq -r '.domain_profile.supplementary_signals.benchmark_regression.ci_regression // 0' "$READINESS_JSON")
  BENCH_STATUS=$([[ $BD_BENCH_F -gt 0 || $BD_BENCH_D -gt 0 ]] && echo "✓" || echo "✗")
  echo "| Benchmark regression | $BENCH_STATUS | files=$BD_BENCH_F, dirs=$BD_BENCH_D, CI regression=$BD_BENCH_CI |" >> "$MD_FILE"

  # Strict discipline
  BD_STRICT=$(jq -r '.domain_profile.supplementary_signals.strict_discipline // 0' "$READINESS_JSON")
  STRICT_STATUS=$([[ $BD_STRICT -gt 0 ]] && echo "✓" || echo "✗")
  echo "| Strict evaluation discipline | $STRICT_STATUS | StrictData/BangPatterns=$BD_STRICT |" >> "$MD_FILE"

  # .aiignore
  BD_AIIGNORE=$(jq -r '.domain_profile.supplementary_signals.aiignore_on_critical // 0' "$READINESS_JSON")
  AI_STATUS=$([[ $BD_AIIGNORE -gt 0 ]] && echo "✓" || echo "✗")
  echo "| .aiignore on critical paths | $AI_STATUS | $BD_AIIGNORE |" >> "$MD_FILE"

  # Domain risk flags
  DOMAIN_RISKS=$(jq -r '.domain_profile.risk_flags | length' "$READINESS_JSON" 2>/dev/null || echo 0)
  if [[ $DOMAIN_RISKS -gt 0 ]]; then
    echo "" >> "$MD_FILE"
    echo "### Domain Risk Flags" >> "$MD_FILE"
    echo "" >> "$MD_FILE"
    echo "| Severity | Risk | Detail |" >> "$MD_FILE"
    echo "|----------|------|--------|" >> "$MD_FILE"
    jq -r '.domain_profile.risk_flags[] | "| \(if .severity == "high" then "🔴 High" elif .severity == "medium" then "🟡 Medium" else "ℹ️ Info" end) | \(.risk) | \(.detail) |"' "$READINESS_JSON" >> "$MD_FILE"
  fi

  echo "" >> "$MD_FILE"
  echo "---" >> "$MD_FILE"
fi

cat >> "$MD_FILE" << EOF

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
  evidence=$(md_escape_pipes "$evidence")
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
  evidence=$(md_escape_pipes "$evidence")
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
  evidence=$(md_escape_pipes "$evidence")
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
  $ADOPTION_DIM_DETAIL

Quadrant: $QUADRANT
\`\`\`
EOF

# ============================================================
# REVIEW NOTES (from review-scores.sh)
# ============================================================

REVIEW_JSON="$DATADIR/review-notes.json"
if [[ -f "$REVIEW_JSON" ]]; then
  REVIEW_CORRECTIONS=$(jq -r '.review_summary.corrections_applied' "$REVIEW_JSON")
  REVIEW_NOTES_COUNT=$(jq -r '.review_summary.notes_raised' "$REVIEW_JSON")
  ADJ_READINESS=$(jq -r '.review_summary.adjusted_readiness // null' "$REVIEW_JSON")
  ORIG_READINESS=$(jq -r '.review_summary.original_readiness' "$REVIEW_JSON")

  if [[ $REVIEW_CORRECTIONS -gt 0 || $REVIEW_NOTES_COUNT -gt 0 ]]; then
    cat >> "$MD_FILE" << REVIEWEOF

---

## Principal Engineer Review

**Corrections applied:** $REVIEW_CORRECTIONS · **Notes raised:** $REVIEW_NOTES_COUNT
REVIEWEOF

    if [[ "$ADJ_READINESS" != "null" && "$ADJ_READINESS" != "$ORIG_READINESS" ]]; then
      DELTA=$(echo "scale=1; $ADJ_READINESS - $ORIG_READINESS" | bc)
      echo "" >> "$MD_FILE"
      echo "**Adjusted Readiness: $ORIG_READINESS → $ADJ_READINESS** (delta: $DELTA)" >> "$MD_FILE"
    fi

    # Corrections table
    CORR_COUNT=$(jq '.corrections | keys | length' "$REVIEW_JSON")
    if [[ $CORR_COUNT -gt 0 ]]; then
      echo "" >> "$MD_FILE"
      echo "### Corrections" >> "$MD_FILE"
      echo "" >> "$MD_FILE"
      echo "| Signal | Corrected Score | Reason |" >> "$MD_FILE"
      echo "|--------|----------------|--------|" >> "$MD_FILE"
      jq -r '.corrections | to_entries[] | "| \(.key) | \(.value.score) | \(.value.reason) |"' "$REVIEW_JSON" >> "$MD_FILE"
    fi

    # Notes table
    if [[ $REVIEW_NOTES_COUNT -gt 0 ]]; then
      echo "" >> "$MD_FILE"
      echo "### Review Notes" >> "$MD_FILE"
      echo "" >> "$MD_FILE"
      echo "| Signal | Severity | Note | Action |" >> "$MD_FILE"
      echo "|--------|----------|------|--------|" >> "$MD_FILE"
      jq -r '.notes[] | "| \(.signal) | \(.severity) | \(.note) | \(.action) |"' "$REVIEW_JSON" >> "$MD_FILE"

      # Count unresolved overrides and flag them prominently
      OVERRIDE_COUNT=$(jq '[.notes[] | select(.action == "override_recommended")] | length' "$REVIEW_JSON")
      if [[ $OVERRIDE_COUNT -gt 0 ]]; then
        echo "" >> "$MD_FILE"
        echo "**⚠ $OVERRIDE_COUNT signal(s) use default scores and need agent override.** Scores marked \`override_recommended\` above are heuristic defaults — the scanning agent should sample actual file content and apply evidence-based overrides for accurate results. Until overridden, the affected pillar scores may be understated." >> "$MD_FILE"
      fi
    fi
  fi
fi

# ============================================================
# ACTIONABLE RECOMMENDATIONS
# ============================================================

cat >> "$MD_FILE" << 'RECHEADER'

---

## Recommendations

RECHEADER

# Generate recommendations based on scores + domain
REC_NUM=0

# --- Adoption = 0 → recommend quick wins ---
if (( $(echo "$A_COMPOSITE == 0" | bc -l) )); then
  REC_NUM=$((REC_NUM+1))
  cat >> "$MD_FILE" << 'RECADOPT'
### Start AI Adoption

**Zero AI adoption detected.** Quick wins to establish AI presence:

RECADOPT

  # Language-specific CLAUDE.md recommendation
  echo "1. **Add \`CLAUDE.md\`** (or equivalent AI config) with:" >> "$MD_FILE"
  if [[ "$PRIMARY_LANG" == "Haskell" ]]; then
    cat >> "$MD_FILE" << 'RECCLAUDE'
   - Architecture: module boundaries, package structure, key abstractions
   - Conventions: Haskell idioms, strictness policy, export conventions
   - Testing: test framework (hspec/tasty/QuickCheck), how to run tests, coverage expectations
   - Build system: Nix + Cabal setup, GHC version, how to enter dev shell
   - Security: which modules handle crypto/consensus (where AI should review, not generate)
RECCLAUDE
  elif [[ "$PRIMARY_LANG" == "TypeScript" ]]; then
    cat >> "$MD_FILE" << 'RECTSCLAUDE'
   - Architecture: module boundaries, key abstractions, state management approach
   - Conventions: naming, formatting (prettier config), preferred patterns
   - Testing: framework (jest/vitest), coverage expectations, E2E setup
   - Security: auth flows, sensitive data handling, trust boundaries
RECTSCLAUDE
  elif [[ "$PRIMARY_LANG" == "Rust" ]]; then
    cat >> "$MD_FILE" << 'RECRUST'
   - Architecture: crate boundaries, key traits, unsafe usage policy
   - Conventions: error handling patterns, naming, clippy configuration
   - Testing: test organization, property testing setup, benchmark expectations
   - Security: unsafe blocks, FFI boundaries, crypto handling
RECRUST
  else
    cat >> "$MD_FILE" << 'RECGEN'
   - Architecture, Conventions, Testing, Security (minimum 3 of 8 categories)
RECGEN
  fi

  echo "" >> "$MD_FILE"
  echo "2. **Enable AI-assisted PR review** — lowest risk, highest immediate value. AI reviews documentation, test coverage gaps, and style consistency." >> "$MD_FILE"
  echo "" >> "$MD_FILE"
fi

# --- Domain-specific recommendations ---
if [[ -f "$REVIEW_JSON" ]] && [[ $(jq -r '.is_high_assurance' "$REVIEW_JSON") == "1" ]]; then
  REC_NUM=$((REC_NUM+1))

  echo "" >> "$MD_FILE"
  echo "### High-Assurance AI Value" >> "$MD_FILE"
  echo "" >> "$MD_FILE"
  echo "Frame AI as **adversarial reviewer**, not code generator, on critical paths:" >> "$MD_FILE"
  echo "" >> "$MD_FILE"
  echo "| AI Role | Where to Apply | Example |" >> "$MD_FILE"
  echo "|---------|---------------|---------|" >> "$MD_FILE"

  if [[ "$PRIMARY_LANG" == "Haskell" ]]; then
    echo '| **Threat modeler** | Ledger rules, tx validation | "What if amount overflows? What if block has 0 txs?" |' >> "$MD_FILE"
    echo '| **Completeness auditor** | Conformance tests | "Spec defines 14 UTXO rules, tests cover 11 — missing rules 7, 12, 14" |' >> "$MD_FILE"
    echo '| **Generator quality reviewer** | Property tests | "genBlock never produces >100 txs, cover shows 0% on txCount>50" |' >> "$MD_FILE"
    echo '| **Performance challenger** | Hot paths | "This fold on Map.union is O(n×m) per block — benchmark?" |' >> "$MD_FILE"
    echo '| **API/interface reviewer** | Cross-component boundaries | "Error type for applyTx doesn'\''t distinguish recoverable from fatal" |' >> "$MD_FILE"
    echo '| **Documentation driver** | Haddock, README, ADRs | "Generate docs for all exported types in this era module" |' >> "$MD_FILE"
  elif [[ "$PRIMARY_LANG" == "TypeScript" ]]; then
    echo '| **Threat modeler** | Wallet logic, tx construction | "What if BigInt amount overflows? What if CBOR deserialization gets malformed input?" |' >> "$MD_FILE"
    echo '| **Completeness auditor** | Integration tests | "API defines 8 endpoints, tests cover 5 — missing: /stake, /withdraw, /delegate" |' >> "$MD_FILE"
    echo '| **Security reviewer** | Key management, signing | "Private key buffer not zeroed after use. Mnemonic stored in plaintext localStorage." |' >> "$MD_FILE"
    echo '| **Performance challenger** | UI rendering, API calls | "This useEffect triggers on every render — debounce or memoize the balance fetch" |' >> "$MD_FILE"
    echo '| **API/interface reviewer** | Cross-module contracts | "Error type for submitTx is string — use discriminated union for recoverable vs fatal" |' >> "$MD_FILE"
    echo '| **Documentation driver** | TSDoc, README, ADRs | "Generate TSDoc for all exported types in the SDK package" |' >> "$MD_FILE"
  elif [[ "$PRIMARY_LANG" == "Rust" ]]; then
    echo '| **Threat modeler** | Core logic, serialization | "What if deserialized tx has length 0? What if fee overflows u64?" |' >> "$MD_FILE"
    echo '| **Completeness auditor** | Conformance tests | "Spec defines 14 rules, tests cover 11 — missing rules 7, 12, 14" |' >> "$MD_FILE"
    echo '| **Unsafe reviewer** | FFI, crypto boundaries | "This unsafe block assumes aligned input — add alignment check" |' >> "$MD_FILE"
    echo '| **Performance challenger** | Hot paths | "This allocation in the inner loop creates GC pressure — use arena allocator" |' >> "$MD_FILE"
    echo '| **API/interface reviewer** | Crate boundaries | "Error type for submit_tx doesn'\''t distinguish NetworkError from ValidationError" |' >> "$MD_FILE"
    echo '| **Documentation driver** | rustdoc, README, ADRs | "Generate rustdoc for all pub types in this crate" |' >> "$MD_FILE"
  else
    echo '| **Threat modeler** | Core logic, validation | "What if input is malformed? What if amounts overflow?" |' >> "$MD_FILE"
    echo '| **Completeness auditor** | Test coverage | "Spec defines N rules, tests cover M — identify gaps" |' >> "$MD_FILE"
    echo '| **Security reviewer** | Auth, crypto, key mgmt | "Review all security-critical paths for common vulnerabilities" |' >> "$MD_FILE"
    echo '| **Performance challenger** | Hot paths | "Identify O(n²) patterns, unnecessary allocations, missing caching" |' >> "$MD_FILE"
    echo '| **API/interface reviewer** | Module boundaries | "Review error types, input validation, contract consistency" |' >> "$MD_FILE"
    echo '| **Documentation driver** | API docs, README, ADRs | "Generate docs for all exported public interfaces" |' >> "$MD_FILE"
  fi
  echo "" >> "$MD_FILE"

  # .aiignore recommendation
  BD_AIIGNORE=$(jq -r '.domain_profile.supplementary_signals.aiignore_on_critical // 0' "$READINESS_JSON" 2>/dev/null || echo 0)
  if [[ "$BD_AIIGNORE" == "0" ]]; then
    echo "**Add \`.aiignore\`** excluding consensus/crypto paths — signals mature AI governance and prevents AI from generating code in critical modules." >> "$MD_FILE"
    echo "" >> "$MD_FILE"
  fi
fi

# --- Score-driven recommendations ---
# Low Understand pillar
if (( $(echo "$UND_SCORE < 70" | bc -l) )); then
  REC_NUM=$((REC_NUM+1))
  echo "### Improve AI Understanding (Understand: $UND_SCORE/100)" >> "$MD_FILE"
  echo "" >> "$MD_FILE"

  U2_SC=$(jq -r '.pillars.understand.signals.U2_doc_coverage.score' "$READINESS_JSON")
  U3_SC=$(jq -r '.pillars.understand.signals.U3_readme_substance.score' "$READINESS_JSON")
  U4_SC=$(jq -r '.pillars.understand.signals.U4_architecture_docs.score' "$READINESS_JSON")

  if [[ $U2_SC -le 25 ]]; then
    if [[ "$PRIMARY_LANG" == "Haskell" ]]; then
      echo "- **Documentation coverage (U2=$U2_SC):** Add Haddock comments (\`{- | -}\` / \`-- |\`) to exported functions and types. This is the single highest-impact improvement for AI comprehension." >> "$MD_FILE"
    elif [[ "$PRIMARY_LANG" == "TypeScript" ]]; then
      echo "- **Documentation coverage (U2=$U2_SC):** Add TSDoc/JSDoc (\`/** */\`) to exported functions and types. This is the single highest-impact improvement for AI comprehension." >> "$MD_FILE"
    elif [[ "$PRIMARY_LANG" == "Rust" ]]; then
      echo "- **Documentation coverage (U2=$U2_SC):** Add rustdoc (\`///\`) to public functions, types, and modules. This is the single highest-impact improvement for AI comprehension." >> "$MD_FILE"
    else
      echo "- **Documentation coverage (U2=$U2_SC):** Add doc comments to exported functions and types. This is the single highest-impact improvement for AI comprehension." >> "$MD_FILE"
    fi
  fi
  if [[ $U3_SC -le 40 ]]; then
    echo "- **README substance (U3=$U3_SC):** Add Architecture and Usage sections to README. AI agents read README first — a good README multiplies AI effectiveness across all tasks." >> "$MD_FILE"
  fi
  if [[ $U4_SC -le 25 ]]; then
    echo "- **Architecture docs (U4=$U4_SC):** Add \`ARCHITECTURE.md\` or ADRs. Even a single file explaining module relationships and key design decisions significantly improves AI's ability to make contextually correct suggestions." >> "$MD_FILE"
  fi
  echo "" >> "$MD_FILE"
fi

# Low Verify pillar
VER_NUM=${VER_SCORE%.*}
if [[ ${VER_NUM:-0} -lt 60 ]]; then
  REC_NUM=$((REC_NUM+1))
  echo "### Strengthen Verification (Verify: $VER_SCORE/100)" >> "$MD_FILE"
  echo "" >> "$MD_FILE"

  V1_SC=$(jq -r '.pillars.verify.signals.V1_test_source_ratio.score' "$READINESS_JSON")
  V2_SC_V=$(jq -r '.pillars.verify.signals.V2_test_categorization.score' "$READINESS_JSON")
  V4_SC=$(jq -r '.pillars.verify.signals.V4_coverage_config.score' "$READINESS_JSON")

  if [[ $V1_SC -le 25 ]]; then
    TEST_RATIO=$(jq -r '.pillars.verify.signals.V1_test_source_ratio.evidence' "$READINESS_JSON" | grep -oP 'ratio=\K[0-9.]+' || echo "low")
    echo "- **Test/source ratio (V1=$V1_SC):** Ratio is $TEST_RATIO — add unit tests for modules with zero test coverage. Focus on the most-changed files first for maximum AI verification value." >> "$MD_FILE"
  fi
  if [[ $V2_SC_V -le 50 ]]; then
    echo "- **Test categorization (V2=$V2_SC_V):** Expand test types beyond what's currently detected. Add unit tests (if only integration/e2e exist) or property-based tests (e.g., fast-check for TypeScript, QuickCheck for Haskell) for richer AI verification." >> "$MD_FILE"
  fi
  if [[ $V4_SC -eq 0 ]]; then
    if [[ "$PRIMARY_LANG" == "Haskell" ]]; then
      echo "- **Coverage config (V4=$V4_SC):** Consider HPC integration or property test coverage reporting. For property-heavy repos, conformance completeness metrics (% of spec rules tested) may be more meaningful than line coverage." >> "$MD_FILE"
    else
      echo "- **Coverage config (V4=$V4_SC):** Add coverage tool + threshold to CI." >> "$MD_FILE"
    fi
  elif [[ $V4_SC -le 60 ]]; then
    echo "- **Coverage threshold (V4=$V4_SC):** Coverage tool detected but no enforcement threshold. Add a minimum coverage gate to CI to prevent regression." >> "$MD_FILE"
  fi
  echo "" >> "$MD_FILE"
fi

# No recommendations case
if [[ $REC_NUM -eq 0 ]]; then
  echo "*No critical recommendations. Codebase is well-positioned for AI collaboration.*" >> "$MD_FILE"
  echo "" >> "$MD_FILE"
fi

echo "Report generated: $MD_FILE"

# --- Generate JSON Report ---
JSON_FILE="$OUTPUT_DIR/${REPONAME}-report.json"

jq -s --arg date "$SCAN_DATE" --arg quad "$QUADRANT" '
  .[0] as $readiness | .[1] as $adoption | .[2] as $meta | .[3] as $langs |
{
  metadata: {
    model_version: "1.0",
    scan_date: $date,
    scanned_by: "CoE (Dorin Solomon)"
  },
  repository: {
    full_name: ($meta.full_name // null),
    description: ($meta.description // null),
    default_branch: ($meta.default_branch // null),
    primary_language: (($langs[0].key) // null),
    size_kb: ($meta.size // 0),
    license: ($meta.license // null),
    stars: ($meta.stargazers_count // 0),
    open_issues: ($meta.open_issues_count // 0),
    private: ($meta.private // false)
  },
  readiness: ($readiness.readiness + {
    pillars: $readiness.pillars,
    penalties: $readiness.penalties
  }),
  adoption: ($adoption.adoption + {
    detection_layers: $adoption.detection_layers,
    dimensions: $adoption.dimensions,
    annotations: $adoption.annotations,
    risk_flags: $adoption.risk_flags
  }),
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
