#!/usr/bin/env bash
# AAMM Score Reviewer — Principal Engineer Lens
# Usage: ./review-scores.sh owner/repo [data_dir]
#
# Reads raw score JSONs + collected data and applies language/domain-specific
# validation. Produces:
#   - corrections.json: overrides for false positives/negatives
#   - review-notes.json: flags for operator attention
#
# This script applies deterministic heuristics that catch known patterns
# where the generic scorer gets it wrong for specific ecosystems.
# It does NOT replace agent judgment — it catches the obvious misses.
#
# Run after score-readiness.sh + score-adoption.sh, before generate-report.sh.

set -euo pipefail

REPO="${1:?Usage: $0 owner/repo [data_dir]}"
DATADIR="${2:-/tmp/aamm-$(echo "$REPO" | tr '/' '-')}"

READINESS_JSON="$DATADIR/readiness-scores.json"
ADOPTION_JSON="$DATADIR/adoption-scores.json"

if [[ ! -f "$READINESS_JSON" || ! -f "$ADOPTION_JSON" ]]; then
  echo "ERROR: Score JSONs not found in $DATADIR. Run scorers first." >&2
  exit 1
fi

echo "=== AAMM Score Review: $REPO ==="

# Load context
PRIMARY_LANG=$(jq -r '.primary_language' "$READINESS_JSON")
IS_HIGH_ASSURANCE=0
[[ -f "$DATADIR/high-assurance-domain.json" ]] && IS_HIGH_ASSURANCE=$(jq -r '.is_high_assurance' "$DATADIR/high-assurance-domain.json")

CORRECTIONS='{}' # signal -> corrected score
REVIEW_NOTES='[]' # [{signal, severity, note, action}]

add_correction() {
  local signal="$1" score="$2" reason="$3"
  CORRECTIONS=$(echo "$CORRECTIONS" | jq --arg s "$signal" --argjson v "$score" --arg r "$reason" \
    '. + {($s): {"score": $v, "reason": $r}}')
}

add_note() {
  local signal="$1" severity="$2" note="$3" action="$4"
  REVIEW_NOTES=$(echo "$REVIEW_NOTES" | jq --arg s "$signal" --arg sev "$severity" --arg n "$note" --arg a "$action" \
    '. + [{"signal": $s, "severity": $sev, "note": $n, "action": $a}]')
}

# ============================================================
# LANGUAGE-SPECIFIC VALIDATION
# ============================================================

echo "  Language: $PRIMARY_LANG"

# --- N5: Code Consistency — Haskell linter detection ---
N5_SCORE=$(jq -r '.pillars.navigate.signals.N5_code_consistency.score' "$READINESS_JSON")
if [[ "$PRIMARY_LANG" == "Haskell" ]]; then
  HAS_HLINT=0
  HAS_FORMATTER=0
  if [[ -f "$DATADIR/lint-format-configs.txt" ]]; then
    grep -qiE '(\.hlint|flake\.nix:linter)' "$DATADIR/lint-format-configs.txt" 2>/dev/null && HAS_HLINT=1
    grep -qiE '(fourmolu|ormolu|stylish-haskell|flake\.nix:formatter)' "$DATADIR/lint-format-configs.txt" 2>/dev/null && HAS_FORMATTER=1
  fi
  # Nix fallback: check flake.nix directly (catches linters invisible as standalone config files)
  if [[ $HAS_HLINT -eq 0 && -f "$DATADIR/flake.nix" ]]; then
    grep -qiE '\bhlint\b' "$DATADIR/flake.nix" 2>/dev/null && HAS_HLINT=1
  fi
  if [[ $HAS_FORMATTER -eq 0 && -f "$DATADIR/flake.nix" ]]; then
    grep -qiE '\b(fourmolu|ormolu|stylish-haskell)\b' "$DATADIR/flake.nix" 2>/dev/null && HAS_FORMATTER=1
  fi
  # Check CI enforcement — per-tool for accuracy
  CI_HLINT=0
  CI_FORMATTER=0
  for wf in "$DATADIR"/wf_*; do
    [[ -f "$wf" ]] || continue
    grep -qiE '\bhlint\b' "$wf" 2>/dev/null && CI_HLINT=1
    grep -qiE '(fourmolu|ormolu|stylish-haskell)' "$wf" 2>/dev/null && CI_FORMATTER=1
    grep -qiE '(nix flake check)' "$wf" 2>/dev/null && { CI_HLINT=1; CI_FORMATTER=1; }
  done

  if [[ $HAS_HLINT -eq 1 && $HAS_FORMATTER -eq 1 && $CI_HLINT -eq 1 && $CI_FORMATTER -eq 1 ]]; then
    if [[ $N5_SCORE -lt 100 ]]; then
      add_correction "N5" 100 "hlint + fourmolu/ormolu + both CI-enforced"
      echo "  [CORRECTED] N5: $N5_SCORE → 100 (hlint + formatter + both CI)"
    fi
  elif [[ $HAS_HLINT -eq 1 && $HAS_FORMATTER -eq 1 ]]; then
    if [[ $N5_SCORE -lt 80 ]]; then
      add_correction "N5" 80 "hlint + fourmolu/ormolu present (CI: hlint=$CI_HLINT, formatter=$CI_FORMATTER)"
      echo "  [CORRECTED] N5: $N5_SCORE → 80 (hlint + formatter, partial CI)"
    fi
  elif [[ $HAS_HLINT -eq 1 || $HAS_FORMATTER -eq 1 ]]; then
    if [[ $N5_SCORE -lt 60 ]]; then
      add_correction "N5" 60 "Haskell linter/formatter detected"
      echo "  [CORRECTED] N5: $N5_SCORE → 60 (partial Haskell tooling)"
    fi
  fi
fi

# --- N5: Code Consistency — TypeScript/Rust CI detection fallback ---
# Safety net: score-readiness.sh should detect these, but review catches remaining gaps.
# See also: score-readiness.sh CI_LINTER/CI_FORMATTER patterns.
if [[ "$PRIMARY_LANG" == "TypeScript" || "$PRIMARY_LANG" == "JavaScript" ]]; then
  if [[ $N5_SCORE -lt 100 ]]; then
    TS_CI_LINTER=0; TS_CI_FORMATTER=0
    for wf in "$DATADIR"/wf_*; do
      [[ -f "$wf" ]] || continue
      grep -qiE '(eslint|nx.*--target=lint|npm run lint|check:lint|biome check)' "$wf" 2>/dev/null && TS_CI_LINTER=1
      grep -qiE '(prettier|check:format|biome format)' "$wf" 2>/dev/null && TS_CI_FORMATTER=1
    done
    if [[ $TS_CI_LINTER -eq 1 && $TS_CI_FORMATTER -eq 1 ]]; then
      HAS_LINT_CFG=0; HAS_FMT_CFG=0
      [[ -f "$DATADIR/lint-format-configs.txt" ]] && {
        grep -qiE '(eslintrc|eslint\.config|biome\.json)' "$DATADIR/lint-format-configs.txt" 2>/dev/null && HAS_LINT_CFG=1
        grep -qiE '(prettierrc|biome\.json)' "$DATADIR/lint-format-configs.txt" 2>/dev/null && HAS_FMT_CFG=1
      }
      if [[ $HAS_LINT_CFG -eq 1 && $HAS_FMT_CFG -eq 1 ]]; then
        add_correction "N5" 100 "TypeScript: linter + formatter configured + both CI-enforced (npm/nx patterns)"
        echo "  [CORRECTED] N5: $N5_SCORE → 100 (TypeScript linter + formatter + both CI)"
      fi
    fi
  fi
fi

if [[ "$PRIMARY_LANG" == "Rust" && $N5_SCORE -lt 100 ]]; then
  RUST_CI_CLIPPY=0; RUST_CI_RUSTFMT=0
  for wf in "$DATADIR"/wf_*; do
    [[ -f "$wf" ]] || continue
    grep -qiE '(clippy|cargo clippy)' "$wf" 2>/dev/null && RUST_CI_CLIPPY=1
    grep -qiE '(cargo fmt|rustfmt)' "$wf" 2>/dev/null && RUST_CI_RUSTFMT=1
  done
  if [[ $RUST_CI_CLIPPY -eq 1 && $RUST_CI_RUSTFMT -eq 1 ]]; then
    add_correction "N5" 100 "Rust: clippy + rustfmt both CI-enforced"
    echo "  [CORRECTED] N5: $N5_SCORE → 100 (clippy + rustfmt + both CI)"
  fi
fi

# --- U2: Doc Coverage — validate sampling results ---
U2_SCORE=$(jq -r '.pillars.understand.signals.U2_doc_coverage.score' "$READINESS_JSON")
if [[ $U2_SCORE -eq 25 ]]; then
  # Score 25 could mean: (a) doc-coverage.json was missing (fallback), or (b) actual ratio 10-30%
  U2_EV=$(jq -r '.pillars.understand.signals.U2_doc_coverage.evidence' "$READINESS_JSON")
  if echo "$U2_EV" | grep -q "Not sampled"; then
    add_note "U2" "warning" "U2 was not sampled (doc-coverage.json missing). Re-run collect-readiness.sh." "rescan_recommended"
    echo "  [FLAG] U2: not sampled — doc-coverage.json missing"
  fi
fi

# --- Vulnerability monitoring — Haskell ecosystem exception ---
PENALTY_DEPS=$(jq -r '.penalties.no_vulnerability_monitoring.impact' "$READINESS_JSON" | tr -d '-')
if [[ "$PRIMARY_LANG" == "Haskell" && $PENALTY_DEPS -gt 0 ]]; then
  # Check if team has active dep management strategy
  HAS_CABAL_PROJECT=0
  HAS_FLAKE_LOCK=0
  [[ -f "$DATADIR/tree.json" ]] && jq -e '.tree[] | select(.path == "cabal.project")' "$DATADIR/tree.json" >/dev/null 2>&1 && HAS_CABAL_PROJECT=1
  grep -q 'flake.lock' "$DATADIR/repro-files.txt" 2>/dev/null && HAS_FLAKE_LOCK=1

  if [[ $HAS_CABAL_PROJECT -eq 1 || $HAS_FLAKE_LOCK -eq 1 ]]; then
    add_note "penalty_deps" "warning" "Haskell penalty of -$PENALTY_DEPS applied, but team has active dep management (cabal.project=$HAS_CABAL_PROJECT, flake.lock=$HAS_FLAKE_LOCK). Per audit decision: Haskell ecosystem lacks vulnerability scanning tooling. Should be 0 penalty + risk flag." "correction_recommended"
    add_correction "penalty_deps" 0 "Haskell ecosystem lacks tooling; cabal.project/flake.lock = active dep management → 0 penalty + risk flag"
    echo "  [CORRECTED] penalty_deps: -$PENALTY_DEPS → 0 (Haskell dep management exception)"
  fi
fi

# --- Branch protection — 403 ambiguity ---
BP_STATUS=$(jq -r '.penalties.no_branch_protection.status' "$READINESS_JSON")
PENALTY_BP=$(jq -r '.penalties.no_branch_protection.impact' "$READINESS_JSON" | tr -d '-')
if [[ "$BP_STATUS" == "forbidden_403" && $PENALTY_BP -gt 0 ]]; then
  # 403 means we can't read protection settings (common for public repos)
  UNREVIEWED=$(jq -r '.penalties.prs_without_review.unreviewed' "$READINESS_JSON")
  TOTAL_REVIEWED=$(jq -r '.penalties.prs_without_review.total_checked' "$READINESS_JSON")
  if [[ $TOTAL_REVIEWED -gt 0 && $UNREVIEWED -eq 0 ]]; then
    add_note "penalty_bp" "info" "Branch protection returned 403 (can't read), but all $TOTAL_REVIEWED checked PRs have reviews. Protection likely exists." "correction_recommended"
    add_correction "penalty_bp" 0 "403 inconclusive but 100% PR review rate suggests protection exists"
    echo "  [CORRECTED] penalty_bp: -$PENALTY_BP → 0 (all PRs reviewed despite 403)"
  fi
fi

# ============================================================
# HIGH-ASSURANCE DOMAIN VALIDATION
# ============================================================

if [[ $IS_HIGH_ASSURANCE -eq 1 ]]; then
  echo "  Domain: high-assurance"

  # --- io-sim detection via cabal.project / dependencies ---
  BD_IO_SIM=$(jq -r '.supplementary_signals.concurrency_testing.io_sim' "$DATADIR/high-assurance-domain.json")
  if [[ $BD_IO_SIM -eq 0 ]]; then
    # Check cabal.project for io-sim dependency
    CABAL_HAS_IO_SIM=0
    if [[ -f "$DATADIR/tree.json" ]]; then
      # Check if any package name contains io-sim or io-classes
      jq -r '.tree[] | select(.type == "blob") | .path' "$DATADIR/tree.json" | grep -qiE '(io-sim|io-classes)' && CABAL_HAS_IO_SIM=1
      # Also check package manifests
      if [[ -f "$DATADIR/package-manifests.txt" ]]; then
        grep -qiE 'io-sim|io-classes' "$DATADIR/package-manifests.txt" 2>/dev/null && CABAL_HAS_IO_SIM=1
      fi
    fi
    # Check workflow files for io-sim references
    for wf in "$DATADIR"/wf_*; do
      [[ -f "$wf" ]] || continue
      grep -qiE 'io-sim|io-classes' "$wf" 2>/dev/null && CABAL_HAS_IO_SIM=1
    done

    DESC=$(jq -r '.description // ""' "$DATADIR/metadata.json")
    if echo "$DESC" | grep -qiE '(consensus|network|distributed|protocol)' && [[ $CABAL_HAS_IO_SIM -eq 0 ]]; then
      add_note "domain_io_sim" "warning" "Network/consensus repo without io-sim detected. Verify manually — io-sim may be a transitive dependency not visible in tree." "verify_manually"
      echo "  [FLAG] io-sim not found in tree for consensus repo — may be transitive dep"
    elif [[ $CABAL_HAS_IO_SIM -eq 1 ]]; then
      add_note "domain_io_sim" "info" "io-sim/io-classes references found in project files but not detected by tree scanner. Domain profile should show io-sim=1." "auto_corrected"
      echo "  [CORRECTED] io-sim found in project references"
    fi
  fi

  # --- Generator discipline — sampling bias check ---
  BD_COVER=$(jq -r '.supplementary_signals.generator_discipline.cover_classify' "$DATADIR/high-assurance-domain.json")
  BD_ARBITRARY=$(jq -r '.supplementary_signals.generator_discipline.custom_arbitrary' "$DATADIR/high-assurance-domain.json")
  if [[ $BD_COVER -eq 0 && $BD_ARBITRARY -eq 0 ]]; then
    # Check if repo has generator files that weren't sampled
    GEN_FILES=0
    [[ -f "$DATADIR/tree.json" ]] && GEN_FILES=$(jq -r '[.tree[] | select(.type == "blob") | .path | select(test("(Gen|Generator|Arbitrary).*\\.hs$"))] | length' "$DATADIR/tree.json" 2>/dev/null || echo 0)
    if [[ $GEN_FILES -gt 3 ]]; then
      add_note "domain_generators" "warning" "$GEN_FILES generator files (Gen*.hs/Generators.hs) found but none sampled. cover/classify/Arbitrary likely present." "correction_applied"
      # Apply conservative correction: mark as inferred (not measured) in domain profile
      jq --argjson gf "$GEN_FILES" \
        '.supplementary_signals.generator_discipline.cover_classify_inferred = 1 |
         .supplementary_signals.generator_discipline.inferred_note = ("inferred from " + ($gf | tostring) + " generator files (not sampled)")' \
        "$DATADIR/high-assurance-domain.json" > "$DATADIR/high-assurance-domain-tmp.json" && \
        mv "$DATADIR/high-assurance-domain-tmp.json" "$DATADIR/high-assurance-domain.json"
      echo "  [CORRECTED] generator discipline: inferred from $GEN_FILES generator files"
    fi
  fi

  # --- Conformance testing — broader detection ---
  BD_CONF=$(jq -r '.supplementary_signals.conformance_testing.conformance_dirs' "$DATADIR/high-assurance-domain.json")
  BD_ORACLE=$(jq -r '.supplementary_signals.conformance_testing.conformance_oracle' "$DATADIR/high-assurance-domain.json")
  if [[ $BD_CONF -eq 0 && $BD_ORACLE -eq 0 ]]; then
    # Check for spec-derived testing patterns (ThreadNet, protocol tests, etc.)
    SPEC_TEST_FILES=0
    [[ -f "$DATADIR/tree.json" ]] && SPEC_TEST_FILES=$(jq -r '[.tree[] | select(.type == "blob") | .path | select(test("(ThreadNet|SpecTest|Protocol.*Test|Spec.*Test).*\\.hs$"; "i"))] | length' "$DATADIR/tree.json" 2>/dev/null || echo 0)
    if [[ $SPEC_TEST_FILES -gt 0 ]]; then
      add_note "domain_conformance" "info" "No conformance/ directory, but $SPEC_TEST_FILES spec-derived test files found (ThreadNet/SpecTest patterns). Conformance testing likely happens through different naming conventions." "verify_manually"
      echo "  [FLAG] $SPEC_TEST_FILES spec-test files found — conformance may use different naming"
    fi

    # Check for Agda-derived test infrastructure
    BD_AGDA=$(jq -r '.supplementary_signals.formal_spec.agda_files' "$DATADIR/high-assurance-domain.json")
    if [[ $BD_AGDA -gt 0 && $BD_CONF -eq 0 ]]; then
      add_note "domain_conformance_agda" "warning" "$BD_AGDA Agda files present but no conformance testing detected. Either conformance exists under different naming, or this is a genuine gap where formal specs aren't being tested against implementation." "verify_manually"
      echo "  [FLAG] Agda specs present ($BD_AGDA files) without detected conformance testing"
    fi
  fi

  # --- StrictData detection — check cabal defaults more thoroughly ---
  BD_STRICT=$(jq -r '.supplementary_signals.strict_discipline' "$DATADIR/high-assurance-domain.json")
  if [[ $BD_STRICT -eq 0 && "$PRIMARY_LANG" == "Haskell" ]]; then
    # StrictData is typically in cabal file default-extensions, not in CI
    # Flag for manual check rather than false-negative
    add_note "domain_strict" "info" "StrictData/BangPatterns not found in .cabal default-extensions or CI files. This repo may use per-module pragmas instead of project-wide defaults." "info_only"
  fi
fi

# ============================================================
# CROSS-SIGNAL SANITY CHECKS
# ============================================================

# V1 ratio vs V2 categories — high ratio but low categories is suspicious
V1_SCORE=$(jq -r '.pillars.verify.signals.V1_test_source_ratio.score' "$READINESS_JSON")
V2_SCORE=$(jq -r '.pillars.verify.signals.V2_test_categorization.score' "$READINESS_JSON")
if [[ $V1_SCORE -ge 75 && $V2_SCORE -le 25 ]]; then
  add_note "V1_V2_mismatch" "info" "High test ratio (V1=$V1_SCORE) but low categorization (V2=$V2_SCORE). Many test files exist but few distinct test types detected. May indicate monolithic test suite or detection gaps." "verify_manually"
  echo "  [FLAG] V1=$V1_SCORE vs V2=$V2_SCORE mismatch — verify test categorization"
fi

# Navigate very high but Understand very low — unusual for well-structured repos
NAV=$(jq -r '.pillars.navigate.score' "$READINESS_JSON")
UND=$(jq -r '.pillars.understand.score' "$READINESS_JSON")
NAV_INT=${NAV%.*}
UND_INT=${UND%.*}
if [[ $NAV_INT -ge 85 && $UND_INT -le 50 ]]; then
  add_note "nav_und_gap" "warning" "Navigate ($NAV) >> Understand ($UND). Well-structured codebase but AI can't understand intent. Typically means docs/comments gap. High-impact improvement area." "operator_attention"
  echo "  [FLAG] Navigate-Understand gap: $NAV vs $UND"
fi

# ============================================================
# RECALCULATE WITH CORRECTIONS
# ============================================================

# Apply corrections to produce adjusted scores
ADJUSTED_READINESS=""
HAS_SCORE_CORRECTIONS=false

# Check if any signal corrections exist
N5_CORRECTION=$(echo "$CORRECTIONS" | jq -r '.N5.score // empty')
PENALTY_DEPS_CORRECTION=$(echo "$CORRECTIONS" | jq -r '.penalty_deps.score // empty')
PENALTY_BP_CORRECTION=$(echo "$CORRECTIONS" | jq -r '.penalty_bp.score // empty')

if [[ -n "$N5_CORRECTION" || -n "$PENALTY_DEPS_CORRECTION" || -n "$PENALTY_BP_CORRECTION" ]]; then
  HAS_SCORE_CORRECTIONS=true

  # Recalculate with corrections
  N1=$(jq -r '.pillars.navigate.signals.N1_file_organization.score' "$READINESS_JSON")
  N2=$(jq -r '.pillars.navigate.signals.N2_file_granularity.score' "$READINESS_JSON")
  N3=$(jq -r '.pillars.navigate.signals.N3_module_boundaries.score' "$READINESS_JSON")
  N4=$(jq -r '.pillars.navigate.signals.N4_separation_of_concerns.score' "$READINESS_JSON")
  N5=${N5_CORRECTION:-$(jq -r '.pillars.navigate.signals.N5_code_consistency.score' "$READINESS_JSON")}
  N6=$(jq -r '.pillars.navigate.signals.N6_cicd_pipeline.score' "$READINESS_JSON")
  N7=$(jq -r '.pillars.navigate.signals.N7_reproducible_env.score' "$READINESS_JSON")
  N8=$(jq -r '.pillars.navigate.signals.N8_repo_foundations.score' "$READINESS_JSON")

  ADJ_NAV=$(echo "scale=2; $N1 * 0.12 + $N2 * 0.13 + $N3 * 0.15 + $N4 * 0.12 + $N5 * 0.13 + $N6 * 0.15 + $N7 * 0.12 + $N8 * 0.08" | bc)
  UND_SCORE=$(jq -r '.pillars.understand.score' "$READINESS_JSON")
  VER_SCORE=$(jq -r '.pillars.verify.score' "$READINESS_JSON")

  ADJ_RAW=$(echo "scale=2; $ADJ_NAV * 0.35 + $UND_SCORE * 0.35 + $VER_SCORE * 0.30" | bc)

  # Adjusted penalties
  ORIG_PENALTY_REVIEW=$(jq -r '.penalties.prs_without_review.impact' "$READINESS_JSON" | tr -d '-')
  ORIG_PENALTY_DEPS=$(jq -r '.penalties.no_vulnerability_monitoring.impact' "$READINESS_JSON" | tr -d '-')
  ORIG_PENALTY_BP=$(jq -r '.penalties.no_branch_protection.impact' "$READINESS_JSON" | tr -d '-')

  ADJ_PENALTY_DEPS=${PENALTY_DEPS_CORRECTION:-$ORIG_PENALTY_DEPS}
  ADJ_PENALTY_BP=${PENALTY_BP_CORRECTION:-$ORIG_PENALTY_BP}
  ADJ_TOTAL_PENALTY=$((ORIG_PENALTY_REVIEW + ADJ_PENALTY_DEPS + ADJ_PENALTY_BP))

  ADJUSTED_READINESS=$(echo "scale=1; r = $ADJ_RAW - $ADJ_TOTAL_PENALTY; if (r < 0) 0 else r" | bc)
  ORIGINAL_READINESS=$(jq -r '.readiness.composite' "$READINESS_JSON")

  echo ""
  echo "  ━━━ Score Adjustment ━━━"
  echo "  Original: $ORIGINAL_READINESS"
  echo "  Adjusted: $ADJUSTED_READINESS (delta: $(echo "scale=1; $ADJUSTED_READINESS - $ORIGINAL_READINESS" | bc))"
fi

# ============================================================
# OUTPUT
# ============================================================

REVIEW_COUNT=$(echo "$REVIEW_NOTES" | jq 'length')
CORRECTION_COUNT=$(echo "$CORRECTIONS" | jq 'keys | length')

cat > "$DATADIR/review-notes.json" << ENDJSON
{
  "repo": "$REPO",
  "primary_language": "$PRIMARY_LANG",
  "is_high_assurance": $IS_HIGH_ASSURANCE,
  "review_summary": {
    "corrections_applied": $CORRECTION_COUNT,
    "notes_raised": $REVIEW_COUNT,
    "original_readiness": $(jq -r '.readiness.composite' "$READINESS_JSON"),
    "adjusted_readiness": ${ADJUSTED_READINESS:-null},
    "has_adjustments": $HAS_SCORE_CORRECTIONS
  },
  "corrections": $CORRECTIONS,
  "notes": $REVIEW_NOTES
}
ENDJSON

echo ""
echo "=== Review Complete ==="
echo "  Corrections: $CORRECTION_COUNT"
echo "  Notes: $REVIEW_COUNT"
if [[ "$HAS_SCORE_CORRECTIONS" == "true" ]]; then
  echo "  Adjusted readiness: $ADJUSTED_READINESS (was $(jq -r '.readiness.composite' "$READINESS_JSON"))"
fi
echo "  Output: $DATADIR/review-notes.json"
