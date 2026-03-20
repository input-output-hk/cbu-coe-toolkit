#!/usr/bin/env bash
# AAMM Adoption Scorer
# Usage: ./score-adoption.sh owner/repo [data_dir] [overrides.json]
# Reads collected adoption data (L1-L5) and scores all 5 dimensions.
# Run collect-adoption.sh first to populate data_dir/adoption/.
#
# Overrides: optional JSON with dimension overrides and content-category results.
# Format: {
#   "dimensions": {"code": {"stage": "Configured", "score": 33, "evidence": "..."}},
#   "content_categories": {"CLAUDE.md": {"architecture":1,"conventions":1,"testing":1,...,"total":3}},
#   "condition_a": {"code": true, "testing": true, ...},
#   "condition_b": {"code": true, "testing": false, ...}
# }
#
# Output: JSON to stdout with stage per dimension + composite.

set -euo pipefail

REPO="${1:?Usage: $0 owner/repo [data_dir] [overrides.json]}"
DATADIR="${2:-/tmp/aamm-$(echo "$REPO" | tr '/' '-')}"
OVERRIDES="${3:-}"
ADOPTDIR="$DATADIR/adoption"

if [[ ! -d "$ADOPTDIR" ]]; then
  echo "ERROR: No adoption data in $ADOPTDIR. Run collect-adoption.sh first." >&2
  exit 1
fi

# --- Helper: read override ---
get_dim_override() {
  local dim="$1" field="$2"
  if [[ -n "$OVERRIDES" && -f "$OVERRIDES" ]]; then
    jq -r --arg d "$dim" --arg f "$field" '.dimensions[$d][$f] // empty' "$OVERRIDES" 2>/dev/null || true
  fi
}

get_condition_override() {
  local type="$1" dim="$2"
  if [[ -n "$OVERRIDES" && -f "$OVERRIDES" ]]; then
    jq -r --arg d "$dim" --arg t "$type" '.[$t][$d] // empty' "$OVERRIDES" 2>/dev/null || true
  fi
}

# ============================================================
# LAYER RESULTS
# ============================================================

# L1: AI config files
L1_COUNT=$(wc -l < "$ADOPTDIR/L1-ai-configs.txt" 2>/dev/null | tr -d ' ' || echo 0)
L1_FILES=""
[[ -f "$ADOPTDIR/L1-ai-configs.txt" ]] && L1_FILES=$(cat "$ADOPTDIR/L1-ai-configs.txt" | tr '\n' ', ' | sed 's/,$//')

# L2: AI co-authored commits
L2_COUNT=$(wc -l < "$ADOPTDIR/L2-ai-commits.txt" 2>/dev/null | tr -d ' ' || echo 0)

# L3: Bot PRs
L3_COPILOT_SWE=$(jq '.total_count // 0' "$ADOPTDIR/L3-app_copilot-swe-agent.json" 2>/dev/null || echo 0)
L3_CODERABBIT=$(jq '.total_count // 0' "$ADOPTDIR/L3-app_coderabbit-ai.json" 2>/dev/null || echo 0)
L3_COPILOT=$(jq '.total_count // 0' "$ADOPTDIR/L3-Copilot.json" 2>/dev/null || echo 0)
L3_TOTAL=$((L3_COPILOT_SWE + L3_CODERABBIT + L3_COPILOT))

# L4: PR body AI signatures
L4_COUNT=$(wc -l < "$ADOPTDIR/L4-ai-pr-body-dedup.txt" 2>/dev/null | tr -d ' ' || echo 0)

# L5: Submodule AI configs
L5_FILES=""
L5_COUNT=0
for f in "$ADOPTDIR"/L5-*-ai-configs.txt; do
  [[ -f "$f" ]] || continue
  c=$(wc -l < "$f" | tr -d ' ')
  L5_COUNT=$((L5_COUNT + c))
  [[ $c -gt 0 ]] && L5_FILES="$L5_FILES$(cat "$f" | tr '\n' ', ')"
done
L5_INACCESSIBLE=""
[[ -f "$ADOPTDIR/L5-inaccessible.txt" ]] && L5_INACCESSIBLE=$(cat "$ADOPTDIR/L5-inaccessible.txt" | tr '\n' '; ')

# Total AI signals
TOTAL_AI_SIGNALS=$((L1_COUNT + L2_COUNT + L3_TOTAL + L4_COUNT + L5_COUNT))

# ============================================================
# CONTENT-CATEGORY ANALYSIS (for Condition B)
# ============================================================
# The script checks AI config file content for the 6 categories.
# This is a heuristic — agent overrides are recommended for accuracy.

check_content_categories() {
  local file="$1"
  local cats=0
  [[ -f "$file" ]] || return
  local size
  size=$(wc -c < "$file" | tr -d ' ')
  [[ $size -lt 50 ]] && echo "0" && return

  # Architecture keywords
  grep -qiE '(architecture|module|package|component|boundary|dependency|monorepo|workspace|layer|domain)' "$file" 2>/dev/null && cats=$((cats+1))
  # Conventions keywords
  grep -qiE '(convention|naming|style|format|pattern|prefer|avoid|anti-pattern|standard|rule)' "$file" 2>/dev/null && cats=$((cats+1))
  # Testing keywords
  grep -qiE '(test|coverage|jest|vitest|pytest|spec|assertion|mock|fixture|e2e|unit test)' "$file" 2>/dev/null && cats=$((cats+1))
  # Security keywords
  grep -qiE '(security|trust|sensitive|secret|credential|auth|token|permission|vulnerability)' "$file" 2>/dev/null && cats=$((cats+1))
  # Delivery keywords
  grep -qiE '(version|release|changelog|deploy|branch|merge|ci/cd|pipeline|estimation)' "$file" 2>/dev/null && cats=$((cats+1))
  # Operations keywords
  grep -qiE '(deploy|monitor|runbook|environment|infra|docker|kubernetes|logging|observ)' "$file" 2>/dev/null && cats=$((cats+1))

  echo "$cats"
}

# Check each AI config file for content categories
BEST_CONFIG=""
BEST_CATS=0
CONFIG_DETAILS=""
for f in "$ADOPTDIR"/L1-content-*; do
  [[ -f "$f" ]] || continue
  fname=$(basename "$f" | sed 's/^L1-content-//' | tr '_' '/')
  cats=$(check_content_categories "$f")
  CONFIG_DETAILS="${CONFIG_DETAILS}${fname}=${cats},"
  if [[ $cats -gt $BEST_CATS ]]; then
    BEST_CATS=$cats
    BEST_CONFIG="$fname"
  fi
done
CONFIG_DETAILS=$(echo "$CONFIG_DETAILS" | sed 's/,$//')

CONDITION_B_MET=false
[[ $BEST_CATS -ge 3 ]] && CONDITION_B_MET=true

# Check specific category presence for dimension-specific Condition B
has_category() {
  local cat_keyword="$1"
  for f in "$ADOPTDIR"/L1-content-*; do
    [[ -f "$f" ]] || continue
    grep -qiE "$cat_keyword" "$f" 2>/dev/null && echo 1 && return
  done
  echo 0
}

HAS_ARCH=$(has_category '(architecture|module|package|component|boundary|monorepo|workspace)')
HAS_CONV=$(has_category '(convention|naming|style|format|pattern|prefer|avoid|standard|rule)')
HAS_TEST=$(has_category '(test|coverage|jest|vitest|pytest|spec|fixture|e2e)')
HAS_SEC=$(has_category '(security|trust|sensitive|secret|credential|auth|vulnerability)')
HAS_DEL=$(has_category '(version|release|changelog|deploy|branch|merge|pipeline)')

# Governance-only files (don't satisfy Condition B for dimensions)
GOVERNANCE_ONLY_FILES=(".mcp.json" "mcp.json" ".aiignore" ".cursorignore")

# ============================================================
# CONDITION A CHECKS (practice active)
# ============================================================

# Load readiness data for Condition A checks
HAS_LINTER=0
HAS_FORMATTER=0
HAS_CODEOWNERS=0
HAS_BRANCH_PROT=0
if [[ -f "$DATADIR/lint-format-configs.txt" ]]; then
  [[ $(wc -l < "$DATADIR/lint-format-configs.txt" | tr -d ' ') -gt 0 ]] && HAS_LINTER=1
fi
[[ -f "$DATADIR/CODEOWNERS" ]] && HAS_CODEOWNERS=1

WF_COUNT=$(wc -l < "$DATADIR/workflow-files.txt" 2>/dev/null | tr -d ' ' || echo 0)

# Code: Condition A = linter OR formatter OR branch protection + CODEOWNERS
CODE_A=false
[[ $HAS_LINTER -eq 1 || $HAS_CODEOWNERS -eq 1 ]] && CODE_A=true
CODE_A_EVIDENCE="linter=$HAS_LINTER, codeowners=$HAS_CODEOWNERS"

# Testing: Condition A = test suite runs in CI
TESTING_A=false
TESTING_A_EVIDENCE="no CI test execution detected"
if [[ $WF_COUNT -gt 0 ]]; then
  for wf in "$DATADIR"/wf_*; do
    [[ -f "$wf" ]] || continue
    if grep -qiE '(test|jest|vitest|pytest|cabal test|cargo test|npm test|yarn test)' "$wf" 2>/dev/null; then
      TESTING_A=true
      TESTING_A_EVIDENCE="test execution found in CI workflows"
      break
    fi
  done
fi

# Security: Condition A = automated dep/security scanning for primary language
SECURITY_A=false
SECURITY_A_EVIDENCE="no security scanning detected"
HAS_DEPENDABOT=0
if [[ -f "$DATADIR/tree.json" ]]; then
  jq -e '.tree[] | select(.path == ".github/dependabot.yml" or .path == ".github/dependabot.yaml")' "$DATADIR/tree.json" >/dev/null 2>&1 && HAS_DEPENDABOT=1
fi
# Check if dependabot covers primary language
PRIMARY_LANG=$(jq -r '.[0].key' "$DATADIR/languages-pct.json")
if [[ $HAS_DEPENDABOT -eq 1 ]]; then
  if [[ -f "$DATADIR/dependabot.yml" ]]; then
    case "$PRIMARY_LANG" in
      TypeScript|JavaScript) grep -qiE '(npm|yarn|pnpm)' "$DATADIR/dependabot.yml" 2>/dev/null && SECURITY_A=true ;;
      Haskell) grep -qiE '(cabal|haskell)' "$DATADIR/dependabot.yml" 2>/dev/null && SECURITY_A=true ;;
      Rust) grep -qiE '(cargo)' "$DATADIR/dependabot.yml" 2>/dev/null && SECURITY_A=true ;;
      Python) grep -qiE '(pip|poetry)' "$DATADIR/dependabot.yml" 2>/dev/null && SECURITY_A=true ;;
      *) SECURITY_A=true ;;
    esac
  fi
  [[ "$SECURITY_A" == "true" ]] && SECURITY_A_EVIDENCE="dependabot covers primary language ($PRIMARY_LANG)"
  [[ "$SECURITY_A" == "false" ]] && SECURITY_A_EVIDENCE="dependabot exists but doesn't cover $PRIMARY_LANG"
fi
# Also check for security scanning tools in CI
if [[ "$SECURITY_A" == "false" && $WF_COUNT -gt 0 ]]; then
  for wf in "$DATADIR"/wf_*; do
    [[ -f "$wf" ]] || continue
    if grep -qiE '(codeql|trivy|snyk|semgrep|cargo-deny|npm audit|safety check|bandit)' "$wf" 2>/dev/null; then
      SECURITY_A=true
      SECURITY_A_EVIDENCE="security scanning in CI"
      break
    fi
  done
fi

# Delivery: Condition A = automated build/release + issue tracking
DELIVERY_A=false
DELIVERY_A_EVIDENCE="no delivery workflow detected"
HAS_BUILD_WF=false
HAS_ISSUES=false
OPEN_ISSUES=$(jq -r '.open_issues_count // 0' "$DATADIR/metadata.json" 2>/dev/null || echo 0)
[[ $OPEN_ISSUES -gt 0 ]] && HAS_ISSUES=true
if [[ $WF_COUNT -gt 0 ]]; then
  for wf in "$DATADIR"/wf_*; do
    [[ -f "$wf" ]] || continue
    grep -qiE '(build|deploy|release|publish)' "$wf" 2>/dev/null && HAS_BUILD_WF=true
  done
fi
[[ "$HAS_BUILD_WF" == "true" && "$HAS_ISSUES" == "true" ]] && DELIVERY_A=true
DELIVERY_A_EVIDENCE="build_workflow=$HAS_BUILD_WF, issues=$HAS_ISSUES (open=$OPEN_ISSUES)"

# Governance: Condition A = any AI config file present
GOVERNANCE_A=false
GOVERNANCE_A_EVIDENCE="no AI config files"
[[ $L1_COUNT -gt 0 || $L5_COUNT -gt 0 ]] && GOVERNANCE_A=true && GOVERNANCE_A_EVIDENCE="$L1_COUNT AI config files in tree, $L5_COUNT in submodules"

# ============================================================
# CONDITION B CHECKS (AI config quality)
# ============================================================

# Code: ≥3 categories + Architecture + Conventions
CODE_B=false
CODE_B_EVIDENCE="no AI config with Architecture + Conventions"
if [[ "$CONDITION_B_MET" == "true" && $HAS_ARCH -eq 1 && $HAS_CONV -eq 1 ]]; then
  CODE_B=true
  CODE_B_EVIDENCE="AI config $BEST_CONFIG: $BEST_CATS/6 categories, includes Architecture + Conventions"
fi

# Testing: ≥3 categories + Testing
TESTING_B=false
TESTING_B_EVIDENCE="no AI config with Testing category"
if [[ "$CONDITION_B_MET" == "true" && $HAS_TEST -eq 1 ]]; then
  TESTING_B=true
  TESTING_B_EVIDENCE="AI config $BEST_CONFIG: $BEST_CATS/6 categories, includes Testing"
fi

# Security: ≥3 categories + Security
SECURITY_B=false
SECURITY_B_EVIDENCE="no AI config with Security category"
if [[ "$CONDITION_B_MET" == "true" && $HAS_SEC -eq 1 ]]; then
  SECURITY_B=true
  SECURITY_B_EVIDENCE="AI config $BEST_CONFIG: $BEST_CATS/6 categories, includes Security"
fi

# Delivery: ≥3 categories + Delivery
DELIVERY_B=false
DELIVERY_B_EVIDENCE="no AI config with Delivery category"
if [[ "$CONDITION_B_MET" == "true" && $HAS_DEL -eq 1 ]]; then
  DELIVERY_B=true
  DELIVERY_B_EVIDENCE="AI config $BEST_CONFIG: $BEST_CATS/6 categories, includes Delivery"
fi

# Governance: AI usage expectations documented + .aiignore/.cursorignore
GOVERNANCE_B=false
GOVERNANCE_B_EVIDENCE="no usage expectations or .aiignore"
HAS_AIIGNORE=0
if [[ -f "$ADOPTDIR/L1-ai-configs.txt" ]]; then
  grep -qiE '(\.aiignore|\.cursorignore)' "$ADOPTDIR/L1-ai-configs.txt" 2>/dev/null && HAS_AIIGNORE=1
fi
# Check if any AI config has usage expectations (more than just tool config)
HAS_USAGE_EXPECTATIONS=0
for f in "$ADOPTDIR"/L1-content-*; do
  [[ -f "$f" ]] || continue
  size=$(wc -c < "$f" | tr -d ' ')
  [[ $size -lt 100 ]] && continue
  # Governance-only files (.mcp.json etc.) don't count
  fname=$(basename "$f")
  echo "$fname" | grep -qiE '(mcp\.json|aiignore|cursorignore)' && continue
  HAS_USAGE_EXPECTATIONS=1
  break
done
if [[ $HAS_USAGE_EXPECTATIONS -eq 1 && $HAS_AIIGNORE -eq 1 ]]; then
  GOVERNANCE_B=true
  GOVERNANCE_B_EVIDENCE="usage expectations documented + .aiignore present"
elif [[ $HAS_USAGE_EXPECTATIONS -eq 1 ]]; then
  GOVERNANCE_B_EVIDENCE="usage expectations found but no .aiignore"
fi

# ============================================================
# APPLY OVERRIDES for conditions
# ============================================================
for dim in code testing security delivery governance; do
  ca_override=$(get_condition_override "condition_a" "$dim")
  cb_override=$(get_condition_override "condition_b" "$dim")
  [[ -n "$ca_override" ]] && eval "${dim^^}_A=$ca_override"
  [[ -n "$cb_override" ]] && eval "${dim^^}_B=$cb_override"
done

# ============================================================
# STAGE DETERMINATION (Decision Trees)
# ============================================================

# AI activity signals (shared across dimensions for Active check)
HAS_AI_ACTIVITY=false
[[ $L2_COUNT -gt 0 || $L3_TOTAL -gt 0 || $L4_COUNT -gt 0 ]] && HAS_AI_ACTIVITY=true

# AI in CI (for Integrated check)
HAS_AI_IN_CI=false
if [[ $WF_COUNT -gt 0 ]]; then
  for wf in "$DATADIR"/wf_*; do
    [[ -f "$wf" ]] || continue
    grep -qiE '(copilot|coderabbit|claude|ai-review|ai-check|ai-test|ai-security)' "$wf" 2>/dev/null && HAS_AI_IN_CI=true
  done
fi

# --- Score each dimension ---
score_dimension() {
  local dim="$1" cond_a="$2" cond_b="$3"

  # Check for override first
  local stage_override
  stage_override=$(get_dim_override "$dim" "stage")
  if [[ -n "$stage_override" ]]; then
    case "$stage_override" in
      None) echo "0" ;; Configured) echo "33" ;; Active) echo "66" ;; Integrated) echo "100" ;; *) echo "0" ;;
    esac
    return
  fi

  # Gate: both A and B required for Configured
  if [[ "$cond_a" != "true" || "$cond_b" != "true" ]]; then
    echo "0"
    return
  fi

  # Configured. Check Active.
  if [[ "$HAS_AI_ACTIVITY" == "true" ]]; then
    # Active. Check Integrated.
    if [[ "$HAS_AI_IN_CI" == "true" ]]; then
      echo "100"
    else
      echo "66"
    fi
  else
    echo "33"
  fi
}

stage_label() {
  case "$1" in
    0) echo "None" ;; 33) echo "Configured" ;; 66) echo "Active" ;; 100) echo "Integrated" ;; *) echo "None" ;;
  esac
}

annotation() {
  local dim="$1" cond_a="$2" cond_b="$3" score="$4"
  if [[ "$cond_a" == "true" && "$cond_b" != "true" ]]; then
    echo "Practice active, no AI config"
  elif [[ "$cond_a" != "true" && "$cond_b" == "true" ]]; then
    echo "AI config present, practice not active"
  elif [[ "$cond_a" != "true" && "$cond_b" != "true" ]]; then
    if [[ $L1_COUNT -gt 0 ]]; then
      echo "Emerging AI usage"
    else
      echo "No AI presence"
    fi
  elif [[ "$score" == "33" ]]; then
    echo "Configured but no active AI signals in last 30 PRs/50 commits"
  elif [[ "$score" == "66" ]]; then
    echo "Active AI usage detected"
  elif [[ "$score" == "100" ]]; then
    echo "AI integrated in CI pipeline"
  else
    echo ""
  fi
}

CODE_SCORE=$(score_dimension "code" "$CODE_A" "$CODE_B")
TESTING_SCORE=$(score_dimension "testing" "$TESTING_A" "$TESTING_B")
SECURITY_SCORE=$(score_dimension "security" "$SECURITY_A" "$SECURITY_B")
DELIVERY_SCORE=$(score_dimension "delivery" "$DELIVERY_A" "$DELIVERY_B")
GOVERNANCE_SCORE=$(score_dimension "governance" "$GOVERNANCE_A" "$GOVERNANCE_B")

CODE_STAGE=$(stage_label "$CODE_SCORE")
TESTING_STAGE=$(stage_label "$TESTING_SCORE")
SECURITY_STAGE=$(stage_label "$SECURITY_SCORE")
DELIVERY_STAGE=$(stage_label "$DELIVERY_SCORE")
GOVERNANCE_STAGE=$(stage_label "$GOVERNANCE_SCORE")

CODE_ANN=$(annotation "code" "$CODE_A" "$CODE_B" "$CODE_SCORE")
TESTING_ANN=$(annotation "testing" "$TESTING_A" "$TESTING_B" "$TESTING_SCORE")
SECURITY_ANN=$(annotation "security" "$SECURITY_A" "$SECURITY_B" "$SECURITY_SCORE")
DELIVERY_ANN=$(annotation "delivery" "$DELIVERY_A" "$DELIVERY_B" "$DELIVERY_SCORE")
GOVERNANCE_ANN=$(annotation "governance" "$GOVERNANCE_A" "$GOVERNANCE_B" "$GOVERNANCE_SCORE")

# ============================================================
# ADOPTION COMPOSITE
# ============================================================
# Adoption = Code*0.25 + Testing*0.25 + Security*0.20 + Delivery*0.15 + Governance*0.15
ADOPTION=$(echo "scale=1; $CODE_SCORE * 0.25 + $TESTING_SCORE * 0.25 + $SECURITY_SCORE * 0.20 + $DELIVERY_SCORE * 0.15 + $GOVERNANCE_SCORE * 0.15" | bc)

# ============================================================
# RISK FLAGS
# ============================================================
RISK_FLAGS="[]"

# AI without governance
if [[ ("$CODE_STAGE" == "Active" || "$CODE_STAGE" == "Integrated" || \
       "$TESTING_STAGE" == "Active" || "$TESTING_STAGE" == "Integrated" || \
       "$SECURITY_STAGE" == "Active" || "$SECURITY_STAGE" == "Integrated" || \
       "$DELIVERY_STAGE" == "Active" || "$DELIVERY_STAGE" == "Integrated") && \
      "$GOVERNANCE_STAGE" == "None" ]]; then
  RISK_FLAGS=$(echo "$RISK_FLAGS" | jq '. + [{"risk": "AI without governance", "severity": "high", "detail": "Active/Integrated AI usage but Governance = None"}]')
fi

# Active without foundation
if [[ "$HAS_AI_ACTIVITY" == "true" && "$CONDITION_B_MET" == "false" ]]; then
  RISK_FLAGS=$(echo "$RISK_FLAGS" | jq '. + [{"risk": "Active without foundation", "severity": "medium", "detail": "AI activity signals found but Configured gate not met (no substantive AI config)"}]')
fi

# AI config stale (check if latest AI config commit is >180 days old)
# This would need commit history for AI config files — mark for agent review
if [[ $L1_COUNT -gt 0 ]]; then
  :  # Agent should check staleness from commit history
fi

# ============================================================
# OUTPUT JSON
# ============================================================

cat <<ENDJSON
{
  "repo": "$REPO",
  "model_version": "1.0",
  "axis": "adoption",
  "adoption": {
    "composite": $ADOPTION,
    "total_ai_signals": $TOTAL_AI_SIGNALS
  },
  "detection_layers": {
    "L1_tree": { "count": $L1_COUNT, "files": "$L1_FILES" },
    "L2_commits": { "count": $L2_COUNT },
    "L3_pr_author": { "copilot_swe": $L3_COPILOT_SWE, "coderabbit": $L3_CODERABBIT, "copilot": $L3_COPILOT, "total": $L3_TOTAL },
    "L4_pr_body": { "count": $L4_COUNT },
    "L5_submodules": { "count": $L5_COUNT, "inaccessible": "$L5_INACCESSIBLE" }
  },
  "content_categories": {
    "best_config": "$BEST_CONFIG",
    "best_score": $BEST_CATS,
    "threshold": 3,
    "condition_b_met": $CONDITION_B_MET,
    "details": "$CONFIG_DETAILS"
  },
  "dimensions": {
    "code": {
      "stage": "$CODE_STAGE", "score": $CODE_SCORE, "weight": 0.25,
      "condition_a": { "met": $CODE_A, "evidence": "$CODE_A_EVIDENCE" },
      "condition_b": { "met": $CODE_B, "evidence": "$CODE_B_EVIDENCE" },
      "annotation": "$CODE_ANN"
    },
    "testing": {
      "stage": "$TESTING_STAGE", "score": $TESTING_SCORE, "weight": 0.25,
      "condition_a": { "met": $TESTING_A, "evidence": "$TESTING_A_EVIDENCE" },
      "condition_b": { "met": $TESTING_B, "evidence": "$TESTING_B_EVIDENCE" },
      "annotation": "$TESTING_ANN"
    },
    "security": {
      "stage": "$SECURITY_STAGE", "score": $SECURITY_SCORE, "weight": 0.20,
      "condition_a": { "met": $SECURITY_A, "evidence": "$SECURITY_A_EVIDENCE" },
      "condition_b": { "met": $SECURITY_B, "evidence": "$SECURITY_B_EVIDENCE" },
      "annotation": "$SECURITY_ANN"
    },
    "delivery": {
      "stage": "$DELIVERY_STAGE", "score": $DELIVERY_SCORE, "weight": 0.15,
      "condition_a": { "met": $DELIVERY_A, "evidence": "$DELIVERY_A_EVIDENCE" },
      "condition_b": { "met": $DELIVERY_B, "evidence": "$DELIVERY_B_EVIDENCE" },
      "annotation": "$DELIVERY_ANN"
    },
    "governance": {
      "stage": "$GOVERNANCE_STAGE", "score": $GOVERNANCE_SCORE, "weight": 0.15,
      "condition_a": { "met": $GOVERNANCE_A, "evidence": "$GOVERNANCE_A_EVIDENCE" },
      "condition_b": { "met": $GOVERNANCE_B, "evidence": "$GOVERNANCE_B_EVIDENCE" },
      "annotation": "$GOVERNANCE_ANN"
    }
  },
  "risk_flags": $RISK_FLAGS,
  "annotations": [
    $(
      anns=""
      [[ -n "$CODE_ANN" ]] && anns="$anns\"Code: $CODE_ANN\","
      [[ -n "$TESTING_ANN" ]] && anns="$anns\"Testing: $TESTING_ANN\","
      [[ -n "$SECURITY_ANN" ]] && anns="$anns\"Security: $SECURITY_ANN\","
      [[ -n "$DELIVERY_ANN" ]] && anns="$anns\"Delivery: $DELIVERY_ANN\","
      [[ -n "$GOVERNANCE_ANN" ]] && anns="$anns\"Governance: $GOVERNANCE_ANN\","
      echo "$anns" | sed 's/,$//'
    )
  ]
}
ENDJSON
