#!/usr/bin/env bash
# AAMM Readiness Scorer
# Usage: ./score-readiness.sh owner/repo [data_dir] [overrides.json]
# Reads collected data and computes all 17 readiness signal scores + penalties.
# Run collect-readiness.sh first to populate data_dir.
#
# Overrides: optional JSON file with signal score overrides for signals
# that require agent judgment (e.g., N4, U2, U3, U4, U5).
# Format: {"N4": 75, "U2": 50, "U3": 60, "U4": 75, "U5": 50, "V2": 75, "V3": 80, ...}
#
# Output: JSON to stdout with scores per signal, pillar, composite + penalties.

set -euo pipefail

REPO="${1:?Usage: $0 owner/repo [data_dir] [overrides.json]}"
DATADIR="${2:-/tmp/aamm-$(echo "$REPO" | tr '/' '-')}"
OVERRIDES="${3:-}"

if [[ ! -f "$DATADIR/metadata.json" ]]; then
  echo "ERROR: No data in $DATADIR. Run collect-readiness.sh first." >&2
  exit 1
fi

# --- Helper: read override or use computed value ---
get_score() {
  local signal="$1"
  local computed="$2"
  if [[ -n "$OVERRIDES" && -f "$OVERRIDES" ]]; then
    local override
    override=$(jq -r --arg s "$signal" '.[$s] // empty' "$OVERRIDES" 2>/dev/null || true)
    if [[ -n "$override" ]]; then
      echo "$override"
      return
    fi
  fi
  echo "$computed"
}

get_evidence() {
  local signal="$1"
  local default="$2"
  if [[ -n "$OVERRIDES" && -f "$OVERRIDES" ]]; then
    local override
    override=$(jq -r --arg s "$signal" '.evidence[$s] // empty' "$OVERRIDES" 2>/dev/null || true)
    if [[ -n "$override" ]]; then
      echo "$override"
      return
    fi
  fi
  echo "$default"
}

# --- Load data ---
PRIMARY_LANG=$(jq -r '.[0].key' "$DATADIR/languages-pct.json")
PRIMARY_PCT=$(jq -r '.[0].pct' "$DATADIR/languages-pct.json")

case "$PRIMARY_LANG" in
  Haskell) BPL=50 ;; Rust) BPL=55 ;; TypeScript) BPL=35 ;; Python) BPL=35 ;; Go) BPL=40 ;; Java) BPL=50 ;; *) BPL=40 ;;
esac

DIR_COUNT=$(wc -l < "$DATADIR/directories.txt" | tr -d ' ')
MAX_DEPTH=$(awk -F'/' '{print NF}' "$DATADIR/directories.txt" | sort -n | tail -1)
SRC_COUNT=$(wc -l < "$DATADIR/source-files.tsv" | tr -d ' ')
TEST_COUNT=$(wc -l < "$DATADIR/test-files.tsv" | tr -d ' ')

MEDIAN_BYTES=$(awk -F'\t' '{print $2}' "$DATADIR/source-files.tsv" | sort -n | awk 'NR==1{n=0} {a[n++]=$1} END{if(n==0) print 0; else if(n%2) print a[int(n/2)]; else print int((a[n/2-1]+a[n/2])/2)}')
MEDIAN_LINES=$((MEDIAN_BYTES / BPL))

LARGE_THRESHOLD=$((1000 * BPL))
LARGE_COUNT=$(awk -F'\t' -v t="$LARGE_THRESHOLD" '$2+0 > t+0' "$DATADIR/source-files.tsv" | wc -l | tr -d ' ')
LARGE_PENALTY=$((LARGE_COUNT * 2))
[[ $LARGE_PENALTY -gt 10 ]] && LARGE_PENALTY=10

MANIFEST_COUNT=$(wc -l < "$DATADIR/package-manifests.txt" 2>/dev/null | tr -d ' ' || echo 0)
WF_COUNT=$(wc -l < "$DATADIR/workflow-files.txt" 2>/dev/null | tr -d ' ' || echo 0)

# Test/source ratio
if [[ $SRC_COUNT -gt 0 ]]; then
  TEST_RATIO=$(echo "scale=3; $TEST_COUNT / $SRC_COUNT" | bc)
else
  TEST_RATIO="0"
fi

# ============================================================
# SIGNAL SCORING — applying tables from readiness-scoring.md
# ============================================================

# --- N1: File Organization ---
# 3+ levels meaningful + consistent → 100, 3+ inconsistent → 75, 2 levels → 50, flat → 25, root → 0
if [[ $MAX_DEPTH -ge 5 && $DIR_COUNT -ge 30 ]]; then
  N1_SCORE=100
elif [[ $MAX_DEPTH -ge 4 && $DIR_COUNT -ge 15 ]]; then
  N1_SCORE=75
elif [[ $MAX_DEPTH -ge 3 && $DIR_COUNT -ge 5 ]]; then
  N1_SCORE=50
elif [[ $MAX_DEPTH -ge 2 ]]; then
  N1_SCORE=25
else
  N1_SCORE=0
fi
N1_SCORE=$(get_score "N1" "$N1_SCORE")
N1_EVIDENCE="max_depth=$MAX_DEPTH, directories=$DIR_COUNT"

# --- N2: File Granularity ---
# Median < 150 → 100, 150-300 → 75, 300-500 → 50, 500-1000 → 25, > 1000 → 0
# Per-file penalty: each > 1000 lines → -2, capped at -10
if [[ $MEDIAN_LINES -lt 150 ]]; then
  N2_BASE=100
elif [[ $MEDIAN_LINES -lt 300 ]]; then
  N2_BASE=75
elif [[ $MEDIAN_LINES -lt 500 ]]; then
  N2_BASE=50
elif [[ $MEDIAN_LINES -lt 1000 ]]; then
  N2_BASE=25
else
  N2_BASE=0
fi
N2_SCORE=$((N2_BASE - LARGE_PENALTY))
[[ $N2_SCORE -lt 0 ]] && N2_SCORE=0
N2_SCORE=$(get_score "N2" "$N2_SCORE")
N2_EVIDENCE="median_lines=$MEDIAN_LINES, large_files=$LARGE_COUNT, per_file_penalty=-$LARGE_PENALTY"

# --- N3: Module Boundaries ---
# Multi-package + explicit exports → 100, one of these → 75, directory-based → 50, minimal → 25, none → 0
WS_COUNT=$(wc -l < "$DATADIR/workspace-files.txt" 2>/dev/null | tr -d ' ' || echo 0)
if [[ $WS_COUNT -gt 0 && $MANIFEST_COUNT -ge 3 ]]; then
  N3_SCORE=100
elif [[ $WS_COUNT -gt 0 || $MANIFEST_COUNT -ge 2 ]]; then
  N3_SCORE=75
elif [[ $MANIFEST_COUNT -ge 1 || $DIR_COUNT -ge 10 ]]; then
  N3_SCORE=50
elif [[ $DIR_COUNT -ge 3 ]]; then
  N3_SCORE=25
else
  N3_SCORE=0
fi
N3_SCORE=$(get_score "N3" "$N3_SCORE")
N3_EVIDENCE="workspace_files=$WS_COUNT, package_manifests=$MANIFEST_COUNT"

# --- N4: Separation of Concerns ---
# Requires agent judgment. Default heuristic: based on top-level directory diversity
TOP_DIRS=$(awk -F'/' '{print $1}' "$DATADIR/directories.txt" | sort -u | wc -l | tr -d ' ')
if [[ $TOP_DIRS -ge 5 ]]; then
  N4_SCORE=100
elif [[ $TOP_DIRS -ge 4 ]]; then
  N4_SCORE=75
elif [[ $TOP_DIRS -ge 3 ]]; then
  N4_SCORE=50
elif [[ $TOP_DIRS -ge 2 ]]; then
  N4_SCORE=25
else
  N4_SCORE=0
fi
N4_SCORE=$(get_score "N4" "$N4_SCORE")
N4_EVIDENCE="top_level_dirs=$TOP_DIRS (heuristic — override recommended)"

# --- N5: Code Consistency ---
# Both linter+formatter with custom rules + CI → 100, both with rules → 80, one with rules → 60,
# default config → 40, mentioned only → 15, neither → 0
LINT_COUNT=$(wc -l < "$DATADIR/lint-format-configs.txt" 2>/dev/null | tr -d ' ' || echo 0)
HAS_LINTER=0
HAS_FORMATTER=0
if [[ -f "$DATADIR/lint-format-configs.txt" ]]; then
  grep -qiE '(eslintrc|eslint\.config|biome\.json|\.hlint|clippy|\.pylintrc|ruff\.toml|\.stan\.toml|weeder)' "$DATADIR/lint-format-configs.txt" && HAS_LINTER=1
  grep -qiE '(prettierrc|\.rustfmt|fourmolu|\.ormolu|stylish-haskell|biome\.json)' "$DATADIR/lint-format-configs.txt" && HAS_FORMATTER=1
fi

# Check CI enforcement
CI_LINT=0
if [[ $WF_COUNT -gt 0 ]]; then
  for wf in "$DATADIR"/wf_*; do
    [[ -f "$wf" ]] || continue
    grep -qiE '(eslint|biome|hlint|clippy|pylint|ruff|prettier|fourmolu|rustfmt|lint|format)' "$wf" 2>/dev/null && CI_LINT=1
  done
fi

if [[ $HAS_LINTER -eq 1 && $HAS_FORMATTER -eq 1 && $CI_LINT -eq 1 ]]; then
  N5_SCORE=100
elif [[ $HAS_LINTER -eq 1 && $HAS_FORMATTER -eq 1 ]]; then
  N5_SCORE=80
elif [[ $HAS_LINTER -eq 1 || $HAS_FORMATTER -eq 1 ]]; then
  if [[ $LINT_COUNT -gt 0 ]]; then
    N5_SCORE=60
  else
    N5_SCORE=40
  fi
elif [[ $LINT_COUNT -gt 0 ]]; then
  N5_SCORE=40
else
  N5_SCORE=0
fi
N5_SCORE=$(get_score "N5" "$N5_SCORE")
N5_EVIDENCE="linter=$HAS_LINTER, formatter=$HAS_FORMATTER, ci_enforced=$CI_LINT, configs=$LINT_COUNT"

# --- N6: CI/CD Pipeline ---
# Build+deploy recently → 100, build recently → 75, minimal → 50, stale → 20, none → 0
LAST_PUSH=$(jq -r '.pushed_at // empty' "$DATADIR/metadata.json")
DAYS_SINCE_PUSH=999
if [[ -n "$LAST_PUSH" ]]; then
  PUSH_EPOCH=$(date -d "$LAST_PUSH" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$LAST_PUSH" +%s 2>/dev/null || echo 0)
  NOW_EPOCH=$(date +%s)
  if [[ $PUSH_EPOCH -gt 0 ]]; then
    DAYS_SINCE_PUSH=$(( (NOW_EPOCH - PUSH_EPOCH) / 86400 ))
  fi
fi

HAS_DEPLOY=0
HAS_BUILD=0
if [[ $WF_COUNT -gt 0 ]]; then
  for wf in "$DATADIR"/wf_*; do
    [[ -f "$wf" ]] || continue
    grep -qiE '(deploy|release|publish|push.*registry|push.*docker)' "$wf" 2>/dev/null && HAS_DEPLOY=1
    grep -qiE '(build|compile|make|cargo build|cabal build|npm run build|tsc|webpack|vite build)' "$wf" 2>/dev/null && HAS_BUILD=1
  done
fi

if [[ $WF_COUNT -gt 0 && $HAS_BUILD -eq 1 && $HAS_DEPLOY -eq 1 && $DAYS_SINCE_PUSH -le 30 ]]; then
  N6_SCORE=100
elif [[ $WF_COUNT -gt 0 && $HAS_BUILD -eq 1 && $DAYS_SINCE_PUSH -le 30 ]]; then
  N6_SCORE=75
elif [[ $WF_COUNT -gt 0 && $DAYS_SINCE_PUSH -le 30 ]]; then
  N6_SCORE=50
elif [[ $WF_COUNT -gt 0 ]]; then
  N6_SCORE=20
else
  N6_SCORE=0
fi
N6_SCORE=$(get_score "N6" "$N6_SCORE")
N6_EVIDENCE="workflows=$WF_COUNT, has_build=$HAS_BUILD, has_deploy=$HAS_DEPLOY, days_since_push=$DAYS_SINCE_PUSH"

# --- N7: Reproducible Environment ---
# Nix flake + devShell + lockfile → 100, Docker + lockfile → 80, lockfile + setup → 60,
# lockfile only → 40, no lockfile → 10, nothing → 0
HAS_FLAKE=$(grep -c 'flake.nix' "$DATADIR/repro-files.txt" 2>/dev/null || echo 0)
HAS_FLAKE_LOCK=$(grep -c 'flake.lock' "$DATADIR/repro-files.txt" 2>/dev/null || echo 0)
HAS_DOCKER=$(grep -ciE 'Dockerfile|docker-compose|devcontainer' "$DATADIR/repro-files.txt" 2>/dev/null || echo 0)
HAS_LOCKFILE=$(grep -ciE '\.lock$|freeze$|package-lock' "$DATADIR/repro-files.txt" 2>/dev/null || echo 0)

if [[ $HAS_FLAKE -gt 0 && $HAS_FLAKE_LOCK -gt 0 ]]; then
  N7_SCORE=100
elif [[ $HAS_DOCKER -gt 0 && $HAS_LOCKFILE -gt 0 ]]; then
  N7_SCORE=80
elif [[ $HAS_LOCKFILE -gt 0 ]]; then
  # Check for setup script or README instructions
  HAS_SETUP=0
  [[ -f "$DATADIR/README.md" ]] && grep -qiE '(setup|install|getting started|build)' "$DATADIR/README.md" 2>/dev/null && HAS_SETUP=1
  if [[ $HAS_SETUP -eq 1 ]]; then
    N7_SCORE=60
  else
    N7_SCORE=40
  fi
elif [[ $HAS_FLAKE -gt 0 || $HAS_DOCKER -gt 0 ]]; then
  N7_SCORE=40
else
  N7_SCORE=0
fi
N7_SCORE=$(get_score "N7" "$N7_SCORE")
N7_EVIDENCE="flake=$HAS_FLAKE, flake_lock=$HAS_FLAKE_LOCK, docker=$HAS_DOCKER, lockfile=$HAS_LOCKFILE"

# --- N8: Repo Foundations ---
HAS_CODEOWNERS=$([[ -f "$DATADIR/CODEOWNERS" ]] && echo 1 || echo 0)
HAS_SECURITY=$([[ -f "$DATADIR/SECURITY.md" ]] && echo 1 || echo 0)
HAS_GITIGNORE=$([[ -f "$DATADIR/.gitignore" ]] && echo 1 || echo 0)

GITIGNORE_CATS=0
if [[ -f "$DATADIR/.gitignore" ]]; then
  grep -qiE '(dist|build|out|target|\.stack-work|dist-newstyle)' "$DATADIR/.gitignore" && GITIGNORE_CATS=$((GITIGNORE_CATS+1))
  grep -qiE '(\.idea|\.vscode|\.vim|\.emacs|\.swp|\.suo)' "$DATADIR/.gitignore" && GITIGNORE_CATS=$((GITIGNORE_CATS+1))
  grep -qiE '(\.DS_Store|Thumbs\.db|desktop\.ini)' "$DATADIR/.gitignore" && GITIGNORE_CATS=$((GITIGNORE_CATS+1))
  grep -qiE '(\.env|secret|credential|\.key|\.pem)' "$DATADIR/.gitignore" && GITIGNORE_CATS=$((GITIGNORE_CATS+1))
  grep -qiE '(node_modules|\.cabal-sandbox|\.stack|__pycache__|\.tox|venv)' "$DATADIR/.gitignore" && GITIGNORE_CATS=$((GITIGNORE_CATS+1))
fi

if [[ $GITIGNORE_CATS -ge 4 ]]; then
  GITIGNORE_SCORE=35
elif [[ $GITIGNORE_CATS -ge 2 ]]; then
  GITIGNORE_SCORE=20
else
  GITIGNORE_SCORE=10
fi

N8_SCORE=$((HAS_CODEOWNERS * 40 + GITIGNORE_SCORE * HAS_GITIGNORE + HAS_SECURITY * 25))
[[ $N8_SCORE -gt 100 ]] && N8_SCORE=100
N8_SCORE=$(get_score "N8" "$N8_SCORE")
N8_EVIDENCE="codeowners=$HAS_CODEOWNERS, gitignore_cats=$GITIGNORE_CATS($GITIGNORE_SCORE), security_md=$HAS_SECURITY"

# --- U1: Type Safety ---
case "$PRIMARY_LANG" in
  Haskell|Rust|OCaml)
    U1_SCORE=100
    U1_EVIDENCE="$PRIMARY_LANG → automatic 100 (statically typed with full inference)"
    ;;
  TypeScript)
    # Try to read tsconfig
    U1_SCORE=40  # default: TS without strict
    U1_EVIDENCE="TypeScript, tsconfig not analyzed"
    if [[ -f "$DATADIR/tsconfig.json" ]]; then
      STRICT=$(jq -r '.compilerOptions.strict // false' "$DATADIR/tsconfig.json" 2>/dev/null || echo "false")
      STRICT_NULL=$(jq -r '.compilerOptions.strictNullChecks // false' "$DATADIR/tsconfig.json" 2>/dev/null || echo "false")
      NO_IMPLICIT_ANY=$(jq -r '.compilerOptions.noImplicitAny // false' "$DATADIR/tsconfig.json" 2>/dev/null || echo "false")
      if [[ "$STRICT" == "true" ]]; then
        U1_SCORE=100
        U1_EVIDENCE="TypeScript strict: true"
      elif [[ "$STRICT_NULL" == "true" && "$NO_IMPLICIT_ANY" == "true" ]]; then
        U1_SCORE=85
        U1_EVIDENCE="TypeScript strictNullChecks + noImplicitAny"
      elif [[ "$STRICT_NULL" == "true" || "$NO_IMPLICIT_ANY" == "true" ]]; then
        U1_SCORE=65
        U1_EVIDENCE="TypeScript partial strict flags"
      else
        U1_SCORE=40
        U1_EVIDENCE="TypeScript without strict flags"
      fi
    else
      # Try to find tsconfig in tree and note it
      if jq -e '.tree[] | select(.path | test("tsconfig.*\\.json$"))' "$DATADIR/tree.json" >/dev/null 2>&1; then
        U1_EVIDENCE="TypeScript, tsconfig exists but not fetched — override recommended"
      fi
    fi
    ;;
  Python)
    U1_SCORE=25
    U1_EVIDENCE="Python — dynamically typed (override if type hints found)"
    ;;
  JavaScript)
    U1_SCORE=0
    U1_EVIDENCE="JavaScript — dynamically typed, no type hints"
    ;;
  *)
    U1_SCORE=40
    U1_EVIDENCE="$PRIMARY_LANG — requires manual type safety assessment"
    ;;
esac
U1_SCORE=$(get_score "U1" "$U1_SCORE")

# --- U2: Documentation Coverage ---
# Requires agent sampling. Default: 25 (conservative)
U2_SCORE=$(get_score "U2" "25")
U2_EVIDENCE="Not sampled — requires agent file content analysis. Override recommended."

# --- U3: README Substance ---
# Sections: Description(20), Setup(20), Usage(20), Architecture(20), Contributing(20)
U3_SCORE=0
if [[ -f "$DATADIR/README.md" ]]; then
  README_LINES=$(wc -l < "$DATADIR/README.md" | tr -d ' ')
  SEC_DESC=0; SEC_SETUP=0; SEC_USAGE=0; SEC_ARCH=0; SEC_CONTRIB=0
  [[ $README_LINES -gt 5 ]] && SEC_DESC=20  # assume description if README has substance
  grep -qiE '(## *(setup|install|getting started|build|quickstart|prerequisites))' "$DATADIR/README.md" && SEC_SETUP=20
  grep -qiE '(## *(usage|how to|examples|commands|running))' "$DATADIR/README.md" && SEC_USAGE=20
  grep -qiE '(## *(architecture|design|system|overview|structure))' "$DATADIR/README.md" && SEC_ARCH=20
  grep -qiE '(## *(contribut|development|develop))' "$DATADIR/README.md" && SEC_CONTRIB=20
  U3_SCORE=$((SEC_DESC + SEC_SETUP + SEC_USAGE + SEC_ARCH + SEC_CONTRIB))
  U3_EVIDENCE="readme_lines=$README_LINES, desc=$((SEC_DESC/20)), setup=$((SEC_SETUP/20)), usage=$((SEC_USAGE/20)), arch=$((SEC_ARCH/20)), contrib=$((SEC_CONTRIB/20))"
else
  U3_EVIDENCE="No README.md found"
fi
U3_SCORE=$(get_score "U3" "$U3_SCORE")

# --- U4: Architecture Documentation ---
# 5+ ADRs + ARCHITECTURE.md recent → 100, 3-4 → 75, 1-2 → 50, scattered → 25, none → 0
ADR_COUNT=0
HAS_ARCH_MD=0
if [[ -f "$DATADIR/tree.json" ]]; then
  ADR_COUNT=$(jq -r '[.tree[] | select(.type == "blob") | .path | select(test("(adr|decisions|rfcs)/.*\\.(md|txt)$"; "i"))] | length' "$DATADIR/tree.json")
  HAS_ARCH_MD=$(jq -r '[.tree[] | select(.type == "blob") | .path | select(test("ARCHITECTURE\\.md$"; "i"))] | length' "$DATADIR/tree.json")
fi

if [[ $ADR_COUNT -ge 5 && $HAS_ARCH_MD -gt 0 ]]; then
  U4_SCORE=100
elif [[ $ADR_COUNT -ge 3 || ($HAS_ARCH_MD -gt 0 && $ADR_COUNT -ge 1) ]]; then
  U4_SCORE=75
elif [[ $ADR_COUNT -ge 1 || $HAS_ARCH_MD -gt 0 ]]; then
  U4_SCORE=50
else
  # Check for any docs directory
  DOCS_EXISTS=$(jq -r '[.tree[] | select(.type == "tree") | .path | select(test("^docs$"; "i"))] | length' "$DATADIR/tree.json" 2>/dev/null || echo 0)
  if [[ $DOCS_EXISTS -gt 0 ]]; then
    U4_SCORE=25
  else
    U4_SCORE=0
  fi
fi
U4_SCORE=$(get_score "U4" "$U4_SCORE")
U4_EVIDENCE="adrs=$ADR_COUNT, architecture_md=$HAS_ARCH_MD"

# --- U5: Schema Definitions ---
# Requires agent judgment. Default heuristic: check for schema files/deps
SCHEMA_COUNT=0
if [[ -f "$DATADIR/tree.json" ]]; then
  SCHEMA_COUNT=$(jq -r '[.tree[] | select(.type == "blob") | .path | select(test("\\.(proto|graphql|gql|cddl)$"; "i") or test("(openapi|swagger)\\.(json|ya?ml)$"; "i"))] | length' "$DATADIR/tree.json")
fi

if [[ $SCHEMA_COUNT -ge 5 ]]; then
  U5_SCORE=100
elif [[ $SCHEMA_COUNT -ge 3 ]]; then
  U5_SCORE=75
elif [[ $SCHEMA_COUNT -ge 1 ]]; then
  U5_SCORE=50
else
  U5_SCORE=0
fi
U5_SCORE=$(get_score "U5" "$U5_SCORE")
U5_EVIDENCE="schema_files=$SCHEMA_COUNT (heuristic — override recommended for dep-based schemas like zod/io-ts)"

# --- V1: Test/Source Ratio ---
if (( $(echo "$TEST_RATIO > 0.7" | bc -l) )); then
  V1_SCORE=100
elif (( $(echo "$TEST_RATIO >= 0.4" | bc -l) )); then
  V1_SCORE=75
elif (( $(echo "$TEST_RATIO >= 0.2" | bc -l) )); then
  V1_SCORE=50
elif (( $(echo "$TEST_RATIO >= 0.1" | bc -l) )); then
  V1_SCORE=25
else
  V1_SCORE=0
fi
V1_SCORE=$(get_score "V1" "$V1_SCORE")
V1_EVIDENCE="ratio=$TEST_RATIO ($TEST_COUNT test / $SRC_COUNT source)"

# --- V2: Test Categorization ---
# Heuristic: check test directory structure + file names + package dependencies
TEST_CATS=0
V2_CATS_FOUND=""
if [[ -f "$DATADIR/test-files.tsv" ]]; then
  grep -qiE '(unit|__tests__|Unit)' "$DATADIR/test-files.tsv" && TEST_CATS=$((TEST_CATS+1)) && V2_CATS_FOUND="${V2_CATS_FOUND}unit,"
  grep -qiE '(integration|e2e|end.to.end|playwright|cypress|webdriver|puppeteer|selenium)' "$DATADIR/test-files.tsv" && TEST_CATS=$((TEST_CATS+1)) && V2_CATS_FOUND="${V2_CATS_FOUND}integration/e2e,"
  grep -qiE '(property|quickcheck|hedgehog|fast-check|proptest|Arbitrary|Gen\.)' "$DATADIR/test-files.tsv" && TEST_CATS=$((TEST_CATS+1)) && V2_CATS_FOUND="${V2_CATS_FOUND}property,"
  grep -qiE '(golden|snapshot|Golden)' "$DATADIR/test-files.tsv" && TEST_CATS=$((TEST_CATS+1)) && V2_CATS_FOUND="${V2_CATS_FOUND}golden,"
  grep -qiE '(conformance|compliance|Conformance)' "$DATADIR/test-files.tsv" && TEST_CATS=$((TEST_CATS+1)) && V2_CATS_FOUND="${V2_CATS_FOUND}conformance,"
  grep -qiE '(Spec\.(hs|ts|tsx|js)$|\.spec\.)' "$DATADIR/test-files.tsv" && { echo "$V2_CATS_FOUND" | grep -q 'unit' || { TEST_CATS=$((TEST_CATS+1)); V2_CATS_FOUND="${V2_CATS_FOUND}spec,"; }; }
fi

# For Haskell: also check .cabal file dependencies for test frameworks
if [[ "$PRIMARY_LANG" == "Haskell" && -f "$DATADIR/tree.json" ]]; then
  # Scan for .cabal files that mention test framework dependencies
  CABAL_DEPS=""
  for cabal_file in "$DATADIR"/package-manifests.txt; do
    [[ -f "$cabal_file" ]] || continue
    # We don't fetch .cabal contents, but we can check tree for test framework indicators
  done
  # Check fetched workflow files and any available .cabal content for framework names
  for f in "$DATADIR"/wf_* "$DATADIR"/*.cabal 2>/dev/null; do
    [[ -f "$f" ]] || continue
    grep -qiE '(QuickCheck|hedgehog)' "$f" 2>/dev/null && { echo "$V2_CATS_FOUND" | grep -q 'property' || { TEST_CATS=$((TEST_CATS+1)); V2_CATS_FOUND="${V2_CATS_FOUND}property,"; }; }
    grep -qiE '(hspec|HSpec)' "$f" 2>/dev/null && { echo "$V2_CATS_FOUND" | grep -q 'spec' || { TEST_CATS=$((TEST_CATS+1)); V2_CATS_FOUND="${V2_CATS_FOUND}spec/bdd,"; }; }
    grep -qiE '(tasty|HUnit)' "$f" 2>/dev/null && { echo "$V2_CATS_FOUND" | grep -q 'unit' || { TEST_CATS=$((TEST_CATS+1)); V2_CATS_FOUND="${V2_CATS_FOUND}unit,"; }; }
  done
fi
V2_CATS_FOUND=$(echo "$V2_CATS_FOUND" | sed 's/,$//')

if [[ $TEST_CATS -ge 3 ]]; then
  V2_SCORE=100
elif [[ $TEST_CATS -ge 2 ]]; then
  V2_SCORE=75
elif [[ $TEST_CATS -ge 1 ]]; then
  V2_SCORE=50
elif [[ $TEST_COUNT -gt 0 ]]; then
  V2_SCORE=25
else
  V2_SCORE=0
fi
V2_SCORE=$(get_score "V2" "$V2_SCORE")
V2_EVIDENCE="detected_categories=$TEST_CATS [$V2_CATS_FOUND] (heuristic — override recommended)"

# --- V3: CI Test Execution ---
# Check for test steps in CI
CI_TEST=0
CI_TEST_BLOCKING=0
if [[ $WF_COUNT -gt 0 ]]; then
  for wf in "$DATADIR"/wf_*; do
    [[ -f "$wf" ]] || continue
    grep -qiE '(test|jest|vitest|pytest|cabal test|cargo test|npm test|yarn test|mocha|rspec)' "$wf" 2>/dev/null && CI_TEST=1
    # Check for required status checks (heuristic: test on pull_request)
    grep -qiE 'pull_request' "$wf" 2>/dev/null && CI_TEST_BLOCKING=1
  done
fi

if [[ $CI_TEST -eq 1 && $CI_TEST_BLOCKING -eq 1 ]]; then
  V3_SCORE=80  # Conservative: "Tests on PR, blocking merge"
elif [[ $CI_TEST -eq 1 ]]; then
  V3_SCORE=50
elif [[ $WF_COUNT -gt 0 ]]; then
  V3_SCORE=20
else
  V3_SCORE=0
fi
V3_SCORE=$(get_score "V3" "$V3_SCORE")
V3_EVIDENCE="ci_test=$CI_TEST, ci_blocking=$CI_TEST_BLOCKING"

# --- V4: Coverage Configuration ---
HAS_COVERAGE=0
HAS_COVERAGE_THRESHOLD=0
if [[ $WF_COUNT -gt 0 ]]; then
  for wf in "$DATADIR"/wf_*; do
    [[ -f "$wf" ]] || continue
    grep -qiE '(coverage|codecov|coveralls|hpc|tarpaulin|c8|istanbul|nyc|--coverage)' "$wf" 2>/dev/null && HAS_COVERAGE=1
    grep -qiE '(threshold|minimum|--min|--check-coverage|coverage-minimum)' "$wf" 2>/dev/null && HAS_COVERAGE_THRESHOLD=1
  done
fi

# Also check tree for coverage config
if [[ -f "$DATADIR/tree.json" ]]; then
  COVERAGE_CONFIG=$(jq -r '[.tree[] | select(.type == "blob") | .path | select(test("(codecov|\.nycrc|coverage|\.c8rc)"; "i"))] | length' "$DATADIR/tree.json")
  [[ $COVERAGE_CONFIG -gt 0 ]] && HAS_COVERAGE=1
fi

if [[ $HAS_COVERAGE -eq 1 && $HAS_COVERAGE_THRESHOLD -eq 1 ]]; then
  V4_SCORE=100
elif [[ $HAS_COVERAGE -eq 1 ]]; then
  V4_SCORE=60
else
  V4_SCORE=0
fi
V4_SCORE=$(get_score "V4" "$V4_SCORE")
V4_EVIDENCE="coverage_tool=$HAS_COVERAGE, threshold=$HAS_COVERAGE_THRESHOLD"

# --- Hard Gate: Verify ---
NO_TESTS=0
if [[ $TEST_COUNT -eq 0 ]]; then
  # Double-check: any test stanza in manifests?
  if [[ -f "$DATADIR/tree.json" ]]; then
    TEST_DIRS=$(jq -r '[.tree[] | select(.type == "tree") | .path | select(test("^(tests?|__tests__|spec)$"; "i") or test("/tests?$"; "i"))] | length' "$DATADIR/tree.json")
    [[ $TEST_DIRS -eq 0 ]] && NO_TESTS=1
  else
    NO_TESTS=1
  fi
fi

# ============================================================
# PILLAR COMPOSITES
# ============================================================

# Navigate = N1*0.12 + N2*0.13 + N3*0.15 + N4*0.12 + N5*0.13 + N6*0.15 + N7*0.12 + N8*0.08
NAVIGATE=$(echo "scale=2; $N1_SCORE * 0.12 + $N2_SCORE * 0.13 + $N3_SCORE * 0.15 + $N4_SCORE * 0.12 + $N5_SCORE * 0.13 + $N6_SCORE * 0.15 + $N7_SCORE * 0.12 + $N8_SCORE * 0.08" | bc)

# Understand = U1*0.30 + U2*0.25 + U3*0.15 + U4*0.15 + U5*0.15
UNDERSTAND=$(echo "scale=2; $U1_SCORE * 0.30 + $U2_SCORE * 0.25 + $U3_SCORE * 0.15 + $U4_SCORE * 0.15 + $U5_SCORE * 0.15" | bc)

# Verify = V1*0.30 + V2*0.20 + V3*0.30 + V4*0.20
VERIFY_RAW=$(echo "scale=2; $V1_SCORE * 0.30 + $V2_SCORE * 0.20 + $V3_SCORE * 0.30 + $V4_SCORE * 0.20" | bc)

if [[ $NO_TESTS -eq 1 ]]; then
  VERIFY=$(echo "scale=2; if ($VERIFY_RAW < 15) $VERIFY_RAW else 15" | bc 2>/dev/null || echo "15")
  # Simpler: cap at 15
  if (( $(echo "$VERIFY_RAW > 15" | bc -l) )); then
    VERIFY="15.00"
  else
    VERIFY="$VERIFY_RAW"
  fi
  HARD_GATE="FAIL (zero tests — capped at 15)"
else
  VERIFY="$VERIFY_RAW"
  HARD_GATE="PASS ($TEST_COUNT test files)"
fi

# ============================================================
# CROSS-PILLAR CONSTRAINTS
# ============================================================

READINESS_RAW=$(echo "scale=2; $NAVIGATE * 0.35 + $UNDERSTAND * 0.35 + $VERIFY * 0.30" | bc)
CONSTRAINTS_APPLIED="[]"

# Constraint 1: Verify < 20 → cap at 50
if (( $(echo "$VERIFY < 20" | bc -l) )); then
  if (( $(echo "$READINESS_RAW > 50" | bc -l) )); then
    READINESS_RAW="50.00"
    CONSTRAINTS_APPLIED='["Verify < 20 → capped at 50"]'
  fi
fi

# Constraint 2: U1 (type_coverage) < 50 → cap at 70
if (( $(echo "$U1_SCORE < 50" | bc -l) )); then
  if (( $(echo "$READINESS_RAW > 70" | bc -l) )); then
    READINESS_RAW="70.00"
    CONSTRAINTS_APPLIED=$(echo "$CONSTRAINTS_APPLIED" | jq '. + ["U1 < 50 → capped at 70"]')
  fi
fi

# ============================================================
# PENALTIES
# ============================================================

# Penalty 1: PRs without review
UNREVIEWED=0
TOTAL_REVIEWED=0
if [[ -f "$DATADIR/pr-reviews.jsonl" ]]; then
  TOTAL_REVIEWED=$(wc -l < "$DATADIR/pr-reviews.jsonl" | tr -d ' ')
  UNREVIEWED=$(awk '/"review_count"/ { gsub(/[^0-9]/,"",$NF); if($NF+0==0) c++ } END { print c+0 }' "$DATADIR/pr-reviews.jsonl")
fi
PENALTY_REVIEW=0
if [[ $TOTAL_REVIEWED -gt 0 ]]; then
  UNREVIEW_PCT=$((UNREVIEWED * 100 / TOTAL_REVIEWED))
  [[ $UNREVIEW_PCT -gt 30 ]] && PENALTY_REVIEW=10
fi

# Penalty 2: No vulnerability monitoring (graduated scale)
PENALTY_DEPS=0
DEPS_STATUS="unknown"
HAS_DEPENDABOT=0
HAS_RENOVATE=0
if [[ -f "$DATADIR/tree.json" ]]; then
  jq -e '.tree[] | select(.path == ".github/dependabot.yml" or .path == ".github/dependabot.yaml")' "$DATADIR/tree.json" >/dev/null 2>&1 && HAS_DEPENDABOT=1
  jq -e '.tree[] | select(.path == "renovate.json" or .path == ".renovate.json" or .path == "renovate.json5")' "$DATADIR/tree.json" >/dev/null 2>&1 && HAS_RENOVATE=1
fi

# Check if scanning covers the primary language
DEPS_COVER_PRIMARY=0
if [[ $HAS_DEPENDABOT -eq 1 && -f "$DATADIR/dependabot.yml" ]]; then
  case "$PRIMARY_LANG" in
    TypeScript|JavaScript) grep -qiE '(npm|yarn|pnpm)' "$DATADIR/dependabot.yml" 2>/dev/null && DEPS_COVER_PRIMARY=1 ;;
    Haskell) grep -qiE '(cabal|haskell|hackage)' "$DATADIR/dependabot.yml" 2>/dev/null && DEPS_COVER_PRIMARY=1 ;;
    Rust) grep -qiE '(cargo|crates)' "$DATADIR/dependabot.yml" 2>/dev/null && DEPS_COVER_PRIMARY=1 ;;
    Python) grep -qiE '(pip|poetry|conda)' "$DATADIR/dependabot.yml" 2>/dev/null && DEPS_COVER_PRIMARY=1 ;;
    *) DEPS_COVER_PRIMARY=1 ;;  # Unknown language — don't penalize
  esac
elif [[ $HAS_RENOVATE -eq 1 ]]; then
  DEPS_COVER_PRIMARY=1  # Renovate generally covers all ecosystems
fi

# Also check for security scanning in CI
HAS_CI_SECURITY=0
if [[ $WF_COUNT -gt 0 ]]; then
  for wf in "$DATADIR"/wf_*; do
    [[ -f "$wf" ]] || continue
    grep -qiE '(codeql|trivy|snyk|semgrep|cargo-deny|npm audit|safety check|bandit|cabal-audit)' "$wf" 2>/dev/null && HAS_CI_SECURITY=1
  done
fi

# Check for active dependency management strategy (lockfile pinning, curated packages)
HAS_DEP_STRATEGY=0
case "$PRIMARY_LANG" in
  Haskell)
    # index-state pinning in cabal.project = active dep management
    if [[ -f "$DATADIR/tree.json" ]]; then
      jq -e '.tree[] | select(.path == "cabal.project")' "$DATADIR/tree.json" >/dev/null 2>&1 && HAS_DEP_STRATEGY=1
    fi
    [[ $HAS_FLAKE -gt 0 && $HAS_FLAKE_LOCK -gt 0 ]] && HAS_DEP_STRATEGY=1
    ;;
  *)
    [[ $HAS_LOCKFILE -gt 0 ]] && HAS_DEP_STRATEGY=1
    ;;
esac

# Graduated penalty logic
if [[ $DEPS_COVER_PRIMARY -eq 1 || $HAS_CI_SECURITY -eq 1 ]]; then
  PENALTY_DEPS=0
  DEPS_STATUS="covered"
elif [[ $HAS_DEPENDABOT -eq 1 && $DEPS_COVER_PRIMARY -eq 0 ]]; then
  PENALTY_DEPS=5
  DEPS_STATUS="partial (wrong ecosystem)"
elif [[ $HAS_DEPENDABOT -eq 0 && $HAS_RENOVATE -eq 0 && $HAS_DEP_STRATEGY -eq 1 ]]; then
  PENALTY_DEPS=5
  DEPS_STATUS="no scanning but active dep management"
elif [[ $HAS_DEPENDABOT -eq 0 && $HAS_RENOVATE -eq 0 ]]; then
  PENALTY_DEPS=10
  DEPS_STATUS="no scanning, no strategy"
fi

# Penalty 3: No branch protection
PENALTY_BP=0
BP_STATUS="unknown"
if [[ -f "$DATADIR/branch-protection.json" ]]; then
  if jq -e '.required_pull_request_reviews' "$DATADIR/branch-protection.json" >/dev/null 2>&1; then
    BP_STATUS="protected"
  elif jq -e '.message' "$DATADIR/branch-protection.json" 2>/dev/null | grep -q "Not Found" 2>/dev/null; then
    BP_STATUS="not_found"
    PENALTY_BP=5
  elif jq -e '.message' "$DATADIR/branch-protection.json" 2>/dev/null | grep -q "403\|Forbidden" 2>/dev/null; then
    BP_STATUS="forbidden_403"
    # Inconclusive — check if PRs have reviews as counter-evidence
    if [[ $TOTAL_REVIEWED -gt 0 && $UNREVIEW_PCT -le 10 ]]; then
      BP_STATUS="inconclusive_but_reviews_found"
      PENALTY_BP=0
    else
      PENALTY_BP=5
    fi
  elif jq -e '.error' "$DATADIR/branch-protection.json" >/dev/null 2>&1; then
    BP_STATUS="error"
  fi
fi

TOTAL_PENALTY=$((PENALTY_REVIEW + PENALTY_DEPS + PENALTY_BP))

# Final readiness
READINESS=$(echo "scale=2; r = $READINESS_RAW - $TOTAL_PENALTY; if (r < 0) 0 else r" | bc)
# Simpler version:
READINESS=$(echo "scale=1; r = $READINESS_RAW - $TOTAL_PENALTY; if (r < 0) 0 else r" | bc)

# ============================================================
# OUTPUT JSON
# ============================================================

cat <<ENDJSON
{
  "repo": "$REPO",
  "model_version": "1.0",
  "axis": "readiness",
  "primary_language": "$PRIMARY_LANG",
  "primary_language_pct": $PRIMARY_PCT,
  "bytes_per_line": $BPL,
  "readiness": {
    "composite": $READINESS,
    "raw": $READINESS_RAW,
    "penalties_total": -$TOTAL_PENALTY,
    "constraints_applied": $CONSTRAINTS_APPLIED
  },
  "pillars": {
    "navigate": {
      "score": $NAVIGATE,
      "weight": 0.35,
      "signals": {
        "N1_file_organization":    { "score": $N1_SCORE, "weight": 0.12, "evidence": "$N1_EVIDENCE" },
        "N2_file_granularity":     { "score": $N2_SCORE, "weight": 0.13, "evidence": "$N2_EVIDENCE" },
        "N3_module_boundaries":    { "score": $N3_SCORE, "weight": 0.15, "evidence": "$N3_EVIDENCE" },
        "N4_separation_of_concerns": { "score": $N4_SCORE, "weight": 0.12, "evidence": "$N4_EVIDENCE" },
        "N5_code_consistency":     { "score": $N5_SCORE, "weight": 0.13, "evidence": "$N5_EVIDENCE" },
        "N6_cicd_pipeline":        { "score": $N6_SCORE, "weight": 0.15, "evidence": "$N6_EVIDENCE" },
        "N7_reproducible_env":     { "score": $N7_SCORE, "weight": 0.12, "evidence": "$N7_EVIDENCE" },
        "N8_repo_foundations":     { "score": $N8_SCORE, "weight": 0.08, "evidence": "$N8_EVIDENCE" }
      }
    },
    "understand": {
      "score": $UNDERSTAND,
      "weight": 0.35,
      "signals": {
        "U1_type_safety":          { "score": $U1_SCORE, "weight": 0.30, "evidence": "$U1_EVIDENCE" },
        "U2_doc_coverage":         { "score": $U2_SCORE, "weight": 0.25, "evidence": "$U2_EVIDENCE" },
        "U3_readme_substance":     { "score": $U3_SCORE, "weight": 0.15, "evidence": "$U3_EVIDENCE" },
        "U4_architecture_docs":    { "score": $U4_SCORE, "weight": 0.15, "evidence": "$U4_EVIDENCE" },
        "U5_schema_definitions":   { "score": $U5_SCORE, "weight": 0.15, "evidence": "$U5_EVIDENCE" }
      }
    },
    "verify": {
      "score": $VERIFY,
      "weight": 0.30,
      "hard_gate": "$HARD_GATE",
      "signals": {
        "V1_test_source_ratio":    { "score": $V1_SCORE, "weight": 0.30, "evidence": "$V1_EVIDENCE" },
        "V2_test_categorization":  { "score": $V2_SCORE, "weight": 0.20, "evidence": "$V2_EVIDENCE" },
        "V3_ci_test_execution":    { "score": $V3_SCORE, "weight": 0.30, "evidence": "$V3_EVIDENCE" },
        "V4_coverage_config":      { "score": $V4_SCORE, "weight": 0.20, "evidence": "$V4_EVIDENCE" }
      }
    }
  },
  "penalties": {
    "prs_without_review": { "unreviewed": $UNREVIEWED, "total_checked": $TOTAL_REVIEWED, "applied": $([ $PENALTY_REVIEW -gt 0 ] && echo true || echo false), "impact": -$PENALTY_REVIEW },
    "no_vulnerability_monitoring": { "dependabot": $HAS_DEPENDABOT, "renovate": $HAS_RENOVATE, "covers_primary": $DEPS_COVER_PRIMARY, "ci_security": $HAS_CI_SECURITY, "dep_strategy": $HAS_DEP_STRATEGY, "status": "$DEPS_STATUS", "applied": $([ $PENALTY_DEPS -gt 0 ] && echo true || echo false), "impact": -$PENALTY_DEPS },
    "no_branch_protection": { "status": "$BP_STATUS", "applied": $([ $PENALTY_BP -gt 0 ] && echo true || echo false), "impact": -$PENALTY_BP }
  },
  "tree_stats": {
    "directories": $DIR_COUNT,
    "max_depth": $MAX_DEPTH,
    "source_files": $SRC_COUNT,
    "test_files": $TEST_COUNT,
    "test_source_ratio": $TEST_RATIO,
    "median_file_bytes": $MEDIAN_BYTES,
    "median_file_lines": $MEDIAN_LINES,
    "large_files_count": $LARGE_COUNT
  }
}
ENDJSON
