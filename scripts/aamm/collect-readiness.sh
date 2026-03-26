#!/usr/bin/env bash
# AAMM Readiness Data Collector
# Usage: ./collect-readiness.sh owner/repo [output_dir]
# Collects all data needed to score the 17 Readiness signals + 3 penalties.
# Requires GITHUB_TOKEN environment variable.

set -euo pipefail

REPO="${1:?Usage: $0 owner/repo [output_dir]}"
OUTDIR="${2:-/tmp/aamm-$(echo "$REPO" | tr '/' '-')}"
OWNER="${REPO%%/*}"
REPONAME="${REPO##*/}"
API="https://api.github.com"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  # Try loading from zshrc
  source ~/.zshrc 2>/dev/null || true
  if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "ERROR: GITHUB_TOKEN not set" >&2
    exit 1
  fi
fi

AUTH=(-H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3+json")
mkdir -p "$OUTDIR"

echo "=== AAMM Readiness Collector: $REPO ==="
echo "Output: $OUTDIR"
echo ""

# --- 1. Repo metadata ---
echo "[1/14] Repo metadata..."
curl -s "${AUTH[@]}" "$API/repos/$REPO" | jq '{
  name, full_name, description, default_branch, size, open_issues_count,
  topics, stargazers_count, forks_count, archived, license: .license.spdx_id,
  created_at, pushed_at, private
}' > "$OUTDIR/metadata.json"
DEFAULT_BRANCH=$(jq -r '.default_branch' "$OUTDIR/metadata.json")
echo "  Default branch: $DEFAULT_BRANCH"

# --- 2. Languages ---
echo "[2/14] Languages..."
curl -s "${AUTH[@]}" "$API/repos/$REPO/languages" > "$OUTDIR/languages.json"
TOTAL_BYTES=$(jq 'to_entries | map(.value) | add' "$OUTDIR/languages.json")
jq --argjson total "$TOTAL_BYTES" 'to_entries | map({key, pct: ((.value / $total) * 100 | . * 10 | round / 10)}) | sort_by(-.pct)' "$OUTDIR/languages.json" > "$OUTDIR/languages-pct.json"
PRIMARY_LANG=$(jq -r '.[0].key' "$OUTDIR/languages-pct.json")
echo "  Primary: $PRIMARY_LANG ($(jq -r '.[0].pct' "$OUTDIR/languages-pct.json")%)"

# --- 3. Recursive tree ---
echo "[3/14] Recursive tree..."
curl -s "${AUTH[@]}" "$API/repos/$REPO/git/trees/$DEFAULT_BRANCH?recursive=1" > "$OUTDIR/tree.json"
TRUNCATED=$(jq -r '.truncated' "$OUTDIR/tree.json")
TREE_COUNT=$(jq '.tree | length' "$OUTDIR/tree.json")
echo "  Entries: $TREE_COUNT (truncated: $TRUNCATED)"

# Compute tree stats
jq -r '.tree[] | select(.type == "tree") | .path' "$OUTDIR/tree.json" > "$OUTDIR/directories.txt"
DIR_COUNT=$(wc -l < "$OUTDIR/directories.txt")
MAX_DEPTH=$(awk -F'/' '{print NF}' "$OUTDIR/directories.txt" | sort -n | tail -1)

# Exclusion patterns for generated/vendored code
EXCLUDE='node_modules/|dist/|build/|\.git/|\.yarn/|\.stack-work/|target/|vendor/|generated/|gen/|autogen/|dist-newstyle/'

# Source file extensions by language (used with awk '$1 ~ ext' on path column)
case "$PRIMARY_LANG" in
  Haskell) SRC_EXT='\\.(hs)$'; BYTES_PER_LINE=50 ;;
  Rust)    SRC_EXT='\\.(rs)$'; BYTES_PER_LINE=55 ;;
  TypeScript) SRC_EXT='\\.(ts|tsx)$'; BYTES_PER_LINE=35 ;;
  Python)  SRC_EXT='\\.(py)$'; BYTES_PER_LINE=35 ;;
  Go)      SRC_EXT='\\.(go)$'; BYTES_PER_LINE=40 ;;
  Java)    SRC_EXT='\\.(java)$'; BYTES_PER_LINE=50 ;;
  *)       SRC_EXT='\\.(ts|tsx|js|jsx|py|hs|rs|go|java|kt|rb|cs|cpp|c|swift)$'; BYTES_PER_LINE=40 ;;
esac

# Source files (excluding test patterns and generated)
# Note: Use awk for extension matching since grep -E '\.(ts|tsx)$' won't match
# in TSV lines where the extension is followed by a tab and file size.
jq -r '.tree[] | select(.type == "blob") | "\(.path)\t\(.size)"' "$OUTDIR/tree.json" \
  | awk -F'\t' -v ext="$SRC_EXT" '$1 ~ ext' \
  | grep -vE "$EXCLUDE" \
  > "$OUTDIR/all-source.tsv" || true

# Test files (include Haskell Spec.hs convention for hspec)
grep -iE '(^|/)tests?/|_test\.|\.test\.|\.spec\.|_spec\.|Spec\.(hs|ts|tsx|js)\t' "$OUTDIR/all-source.tsv" > "$OUTDIR/test-files.tsv" || true

# Non-test source files
grep -viE '(^|/)tests?/|_test\.|\.test\.|\.spec\.|_spec\.|Spec\.(hs|ts|tsx|js)\t|testlib/' "$OUTDIR/all-source.tsv" > "$OUTDIR/source-files.tsv" || true

SRC_COUNT=$(wc -l < "$OUTDIR/source-files.tsv")
TEST_COUNT=$(wc -l < "$OUTDIR/test-files.tsv")
echo "  Dirs: $DIR_COUNT, Max depth: $MAX_DEPTH, Source: $SRC_COUNT, Test: $TEST_COUNT"

# Median file size
MEDIAN_BYTES=$(awk -F'\t' '{print $2}' "$OUTDIR/source-files.tsv" | sort -n | awk 'NR==1{n=0} {a[n++]=$1} END{if(n%2) print a[int(n/2)]; else printf "%d", (a[n/2-1]+a[n/2])/2}')
MEDIAN_LINES=$((MEDIAN_BYTES / BYTES_PER_LINE))
echo "  Median source file: ${MEDIAN_BYTES} bytes (~${MEDIAN_LINES} lines at ${BYTES_PER_LINE} bytes/line)"

# Large files (>1000 lines estimated)
LARGE_THRESHOLD=$((1000 * BYTES_PER_LINE))
awk -F'\t' -v thresh="$LARGE_THRESHOLD" '$2 > thresh {print $0}' "$OUTDIR/source-files.tsv" > "$OUTDIR/large-files.tsv" || true
LARGE_COUNT=$(wc -l < "$OUTDIR/large-files.tsv")
echo "  Large files (>1000 est. lines): $LARGE_COUNT"

# --- 4. AI config files ---
echo "[4/14] AI config files..."
jq -r '.tree[] | select(.type == "blob") | .path' "$OUTDIR/tree.json" \
  | grep -iE '(CLAUDE\.md|claude\.md|AGENTS\.md|GEMINI\.md|copilot-instructions\.md|copilot-setup-steps\.yml|\.cursorrules|\.cursor/rules|\.claude/|\.mcp\.json|mcp\.json|\.coderabbit\.yaml|\.aiignore|\.cursorignore|\.aider|\.windsurfrules|\.continue/|\.sourcegraph/cody|\.codex/)' \
  > "$OUTDIR/ai-config-files.txt" || true
AI_CONFIG_COUNT=$(wc -l < "$OUTDIR/ai-config-files.txt")
echo "  AI config files: $AI_CONFIG_COUNT"

# --- 5. Module boundaries ---
echo "[5/14] Module boundaries..."
jq -r '.tree[] | select(.type == "blob") | .path' "$OUTDIR/tree.json" \
  | grep -E '(cabal\.project|Cargo\.toml|pnpm-workspace\.yaml|nx\.json|turbo\.json|lerna\.json)$' \
  > "$OUTDIR/workspace-files.txt" || true
# Count package manifests (NX/Yarn/pnpm/Lerna packages, Cargo crates, Cabal packages)
jq -r '.tree[] | select(.type == "blob") | .path' "$OUTDIR/tree.json" \
  | grep -E '(\.cabal$|/Cargo\.toml$|packages/.*/package\.json$|apps/.*/package\.json$)' \
  | grep -vE 'node_modules' \
  > "$OUTDIR/package-manifests.txt" || true
MANIFEST_COUNT=$(wc -l < "$OUTDIR/package-manifests.txt")
echo "  Workspace files: $(wc -l < "$OUTDIR/workspace-files.txt"), Package manifests: $MANIFEST_COUNT"

# --- 6. Code consistency (linter/formatter) ---
echo "[6/14] Linter/formatter configs..."
jq -r '.tree[] | select(.type == "blob") | .path' "$OUTDIR/tree.json" \
  | grep -iE '(\.eslintrc|eslint\.config|biome\.json|\.hlint\.yaml|\.hlint\.yml|clippy\.toml|\.pylintrc|ruff\.toml|\.prettierrc|\.rustfmt\.toml|fourmolu\.yaml|\.ormolu|\.stylish-haskell|\.editorconfig|\.stan\.toml|weeder\.toml|\.weeder\.yaml)' \
  > "$OUTDIR/lint-format-configs.txt" || true

# Nix fallback: linters/formatters defined in flake.nix are invisible as standalone files.
# Fetch flake.nix and check for tool definitions (hlint, fourmolu, ormolu, stylish-haskell, clippy).
if jq -e '.tree[] | select(.path == "flake.nix")' "$OUTDIR/tree.json" >/dev/null 2>&1; then
  if [[ ! -f "$OUTDIR/flake.nix" ]]; then
    echo "  Fetching flake.nix for linter/formatter detection..."
    curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/flake.nix" | jq -r '.content // empty' | base64 -d > "$OUTDIR/flake.nix" 2>/dev/null || true
  fi
  if [[ -s "$OUTDIR/flake.nix" ]]; then
    # Detect linters defined in Nix (hlint, stan, weeder, clippy, pylint, ruff)
    if grep -qiE '\b(hlint|stan|weeder|clippy|pylint|ruff)\b' "$OUTDIR/flake.nix" 2>/dev/null; then
      echo "flake.nix:linter" >> "$OUTDIR/lint-format-configs.txt"
      echo "  Linter detected in flake.nix"
    fi
    # Detect formatters defined in Nix (fourmolu, ormolu, stylish-haskell, rustfmt, prettier)
    if grep -qiE '\b(fourmolu|ormolu|stylish-haskell|rustfmt|prettier)\b' "$OUTDIR/flake.nix" 2>/dev/null; then
      echo "flake.nix:formatter" >> "$OUTDIR/lint-format-configs.txt"
      echo "  Formatter detected in flake.nix"
    fi
  fi
fi

echo "  Found: $(cat "$OUTDIR/lint-format-configs.txt" | tr '\n' ', ')"

# Fetch tsconfig.json if present (TypeScript projects)
if jq -e '.tree[] | select(.path == "tsconfig.json")' "$OUTDIR/tree.json" >/dev/null 2>&1; then
  echo "  Fetching tsconfig.json..."
  curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/tsconfig.json" | jq -r '.content // empty' | base64 -d > "$OUTDIR/tsconfig.json" 2>/dev/null || true
fi

# If no root tsconfig.json, try NX/Turborepo patterns
if [[ ! -s "$OUTDIR/tsconfig.json" ]]; then
  for ts_candidate in tsconfig.base.json tsconfig.app.json; do
    if jq -e --arg p "$ts_candidate" '.tree[] | select(.path == $p)' "$OUTDIR/tree.json" > /dev/null 2>&1; then
      echo "  $ts_candidate: present (NX/Turborepo pattern) — fetching as tsconfig.json"
      curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/$ts_candidate" | jq -r '.content' | base64 -d > "$OUTDIR/tsconfig.json" 2>/dev/null || true
      break
    fi
  done
fi

# --- 7. CI/CD workflows ---
echo "[7/14] CI/CD workflows..."
jq -r '.tree[] | select(.type == "blob") | .path' "$OUTDIR/tree.json" \
  | grep -E '^\.github/workflows/.*\.ya?ml$' \
  > "$OUTDIR/workflow-files.txt" || true
WF_COUNT=$(wc -l < "$OUTDIR/workflow-files.txt")
echo "  Workflows: $WF_COUNT"

# Fetch up to 20 workflow files
head -20 "$OUTDIR/workflow-files.txt" | while IFS= read -r wf; do
  SAFE_NAME=$(echo "$wf" | tr '/' '_')
  echo "  Fetching $wf..."
  curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/$wf" | jq -r '.content' | base64 -d > "$OUTDIR/wf_$SAFE_NAME" 2>/dev/null || true
done

# --- 8. Reproducible environment ---
echo "[8/14] Reproducible environment..."
jq -r '.tree[] | select(.type == "blob") | .path' "$OUTDIR/tree.json" \
  | grep -iE '(^flake\.nix$|^shell\.nix$|^default\.nix$|^Dockerfile$|^docker-compose\.ya?ml$|devcontainer\.json|^flake\.lock$|^cabal\.project\.freeze$|^stack\.yaml\.lock$|yarn\.lock$|package-lock\.json$|Cargo\.lock$|poetry\.lock$|Pipfile\.lock$|^\.nvmrc$|^\.node-version$)' \
  > "$OUTDIR/repro-files.txt" || true
echo "  Found: $(cat "$OUTDIR/repro-files.txt" | tr '\n' ', ')"

# --- 9. Repo foundations ---
echo "[9/14] Repo foundations..."
for f in .gitignore SECURITY.md CONTRIBUTING.md LICENSE; do
  if jq -e --arg p "$f" '.tree[] | select(.path == $p)' "$OUTDIR/tree.json" > /dev/null 2>&1; then
    echo "  $f: present"
    curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/$f" | jq -r '.content' | base64 -d > "$OUTDIR/$f" 2>/dev/null || true
  else
    echo "  $f: absent"
  fi
done

# CODEOWNERS — check root, .github/, docs/ (all valid per GitHub spec)
for co_path in "CODEOWNERS" ".github/CODEOWNERS" "docs/CODEOWNERS"; do
  if jq -e --arg p "$co_path" '.tree[] | select(.path == $p)' "$OUTDIR/tree.json" > /dev/null 2>&1; then
    echo "  CODEOWNERS: present at $co_path"
    curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/$co_path" | jq -r '.content' | base64 -d > "$OUTDIR/CODEOWNERS" 2>/dev/null || true
    break
  fi
done

# --- 10. README ---
echo "[10/14] README..."
curl -s "${AUTH[@]}" "$API/repos/$REPO/readme" | jq -r '.content' | base64 -d > "$OUTDIR/README.md" 2>/dev/null || true
README_LINES=$(wc -l < "$OUTDIR/README.md" 2>/dev/null || echo 0)
echo "  README: $README_LINES lines"

# --- 11. Recent PRs + reviews (for penalties + adoption L4) ---
echo "[11/14] Recent PRs + reviews..."
curl -s "${AUTH[@]}" "$API/repos/$REPO/pulls?state=closed&sort=updated&direction=desc&per_page=30" > "$OUTDIR/recent-prs.json"

# Extract 10 most recent merged PRs for penalty check
jq '[.[] | select(.merged_at != null)] | sort_by(.merged_at) | reverse | .[0:10]' "$OUTDIR/recent-prs.json" > "$OUTDIR/merged-prs-10.json"

# Get review counts for merged PRs
jq -r '.[].number' "$OUTDIR/merged-prs-10.json" | while IFS= read -r pr_num; do
  curl -s "${AUTH[@]}" "$API/repos/$REPO/pulls/$pr_num/reviews" | jq "{ pr: $pr_num, review_count: length }" >> "$OUTDIR/pr-reviews.jsonl"
done
echo "  Merged PRs checked: $(jq length "$OUTDIR/merged-prs-10.json")"

# --- 12. Recent commits + branch protection ---
echo "[12/14] Commits + branch protection..."
curl -s "${AUTH[@]}" "$API/repos/$REPO/commits?per_page=50" > "$OUTDIR/recent-commits.json"
curl -s "${AUTH[@]}" "$API/repos/$REPO/branches/$DEFAULT_BRANCH/protection" > "$OUTDIR/branch-protection.json" 2>/dev/null || echo '{"error": "404"}' > "$OUTDIR/branch-protection.json"

# Check for submodules
if jq -e '.tree[] | select(.path == ".gitmodules")' "$OUTDIR/tree.json" > /dev/null 2>&1; then
  echo "  .gitmodules: present (submodules detected)"
  curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/.gitmodules" | jq -r '.content' | base64 -d > "$OUTDIR/.gitmodules" 2>/dev/null || true
else
  echo "  .gitmodules: absent"
fi

# --- 13. Doc Coverage Sampling (U2) ---
echo "[13/14] Doc coverage sampling..."

# Select 15 source files: 10 largest + 5 breadth (one per top-level dir)
DOC_SIZE_GROUP=$(sort -t$'\t' -k2 -nr "$OUTDIR/source-files.tsv" | head -10 | cut -f1)

# Breadth group: distinct path prefixes at depth <= 2, largest file per prefix
DOC_BREADTH_GROUP=""
if [[ -s "$OUTDIR/source-files.tsv" ]]; then
  DOC_PREFIXES=$(cut -f1 "$OUTDIR/source-files.tsv" | awk -F'/' 'NF>=3{print $1"/"$2}' | sort -u | head -5)
  for prefix in $DOC_PREFIXES; do
    CANDIDATE=$(grep "^${prefix}/" "$OUTDIR/source-files.tsv" | sort -t$'\t' -k2 -nr | head -1 | cut -f1)
    if [[ -n "$CANDIDATE" ]] && ! echo "$DOC_SIZE_GROUP" | grep -qF "$CANDIDATE"; then
      DOC_BREADTH_GROUP="${DOC_BREADTH_GROUP:+$DOC_BREADTH_GROUP
}$CANDIDATE"
    fi
  done
fi

DOC_SAMPLE=$(echo -e "${DOC_SIZE_GROUP}\n${DOC_BREADTH_GROUP}" | grep -v '^$' | sort -u || true)
DOC_SAMPLE_COUNT=$(echo "$DOC_SAMPLE" | grep -c . || echo 0)
echo "  Selected $DOC_SAMPLE_COUNT files for doc coverage sampling"

DOC_TOTAL=0
EXPORT_TOTAL=0
DOC_IDX=0
DOC_FETCH_FAILURES=0
DOC_PER_FILE="[]"

while IFS= read -r filepath; do
  [[ -z "$filepath" ]] && continue
  EXT="${filepath##*.}"
  TARGET="$OUTDIR/sampled_doc_${DOC_IDX}.${EXT}"

  # Fetch file content (Contents API, blob fallback for >1MB)
  RESP=$(curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/$filepath")
  MSG=$(echo "$RESP" | jq -r '.message // empty')
  if [[ -n "$MSG" ]]; then
    SHA=$(jq -r ".tree[] | select(.path == \"$filepath\") | .sha" "$OUTDIR/tree.json")
    if [[ -n "$SHA" && "$SHA" != "null" ]]; then
      curl -s "${AUTH[@]}" "$API/repos/$REPO/git/blobs/$SHA" | jq -r '.content // empty' | base64 -d > "$TARGET" 2>/dev/null || true
    fi
  else
    echo "$RESP" | jq -r '.content // empty' | base64 -d > "$TARGET" 2>/dev/null || true
  fi

  if [[ ! -s "$TARGET" ]]; then
    echo "  SKIP: $(basename "$filepath") (fetch failed)"
    DOC_FETCH_FAILURES=$((DOC_FETCH_FAILURES + 1))
    continue
  fi

  FILE_LINES=$(wc -l < "$TARGET")
  FILE_DOCS=0
  FILE_EXPORTS=0

  case "$EXT" in
    hs)
      H_PIPE=$(grep -cE '^\s*-- \|' "$TARGET" 2>/dev/null || true); H_PIPE=${H_PIPE:-0}
      H_CARET=$(grep -cE '^\s*-- \^' "$TARGET" 2>/dev/null || true); H_CARET=${H_CARET:-0}
      H_BLOCK=$(grep -cE '\{-\s*[\|^]' "$TARGET" 2>/dev/null || true); H_BLOCK=${H_BLOCK:-0}
      FILE_DOCS=$((H_PIPE + H_CARET + H_BLOCK))
      HAS_EXPORT_LIST=$(grep -cE '^module\s+\S+\s*\(' "$TARGET" 2>/dev/null || true)
      if [[ ${HAS_EXPORT_LIST:-0} -gt 0 ]]; then
        FILE_EXPORTS=$(awk '/^module.*\(/{found=1; next} found && /^\s*\)\s*(where\s*)?$/{found=0; next} found{print}' "$TARGET" | grep -cE '^\s*,?\s*[a-zA-Z]' 2>/dev/null || true)
        FILE_EXPORTS=${FILE_EXPORTS:-0}
      else
        SIGS=$(grep -cE "^[a-z][a-zA-Z0-9_']*\s+::" "$TARGET" 2>/dev/null || true); SIGS=${SIGS:-0}
        DECLS=$(grep -cE '^(data|type|newtype|class)\s' "$TARGET" 2>/dev/null || true); DECLS=${DECLS:-0}
        FILE_EXPORTS=$((SIGS + DECLS))
      fi
      ;;
    lhs)
      H_PIPE=$(grep -cE '^>\s*-- \|' "$TARGET" 2>/dev/null || true); H_PIPE=${H_PIPE:-0}
      H_CARET=$(grep -cE '^>\s*-- \^' "$TARGET" 2>/dev/null || true); H_CARET=${H_CARET:-0}
      FILE_DOCS=$((H_PIPE + H_CARET))
      SIGS=$(grep -cE "^>\s*[a-z][a-zA-Z0-9_']*\s+::" "$TARGET" 2>/dev/null || true); SIGS=${SIGS:-0}
      DECLS=$(grep -cE '^>\s*(data|type|newtype|class)\s' "$TARGET" 2>/dev/null || true); DECLS=${DECLS:-0}
      FILE_EXPORTS=$((SIGS + DECLS))
      ;;
    ts|tsx)
      FILE_DOCS=$(grep -cE '^\s*/\*\*' "$TARGET" 2>/dev/null || true); FILE_DOCS=${FILE_DOCS:-0}
      FILE_EXPORTS=$(grep -cE '^export\s+(default\s+)?(function|class|const|type|interface|enum)' "$TARGET" 2>/dev/null || true); FILE_EXPORTS=${FILE_EXPORTS:-0}
      ;;
    rs)
      OUTER=$(grep -cE '^\s*///' "$TARGET" 2>/dev/null || true); OUTER=${OUTER:-0}
      INNER=$(grep -cE '^\s*//!' "$TARGET" 2>/dev/null || true); INNER=${INNER:-0}
      FILE_DOCS=$((OUTER + INNER))
      FILE_EXPORTS=$(grep -cE '^pub\s+(fn|struct|enum|trait|type|const|static)' "$TARGET" 2>/dev/null || true); FILE_EXPORTS=${FILE_EXPORTS:-0}
      ;;
    py)
      FILE_DOCS=$(grep -cE '^\s+"""' "$TARGET" 2>/dev/null || true); FILE_DOCS=${FILE_DOCS:-0}
      FUNCS=$(grep -cE '^def\s' "$TARGET" 2>/dev/null || true); FUNCS=${FUNCS:-0}
      CLASSES=$(grep -cE '^class\s' "$TARGET" 2>/dev/null || true); CLASSES=${CLASSES:-0}
      FILE_EXPORTS=$((FUNCS + CLASSES))
      ;;
    go)
      FILE_DOCS=$(grep -cE '^//\s+[A-Z]' "$TARGET" 2>/dev/null || true); FILE_DOCS=${FILE_DOCS:-0}
      FUNCS=$(grep -cE '^func\s+[A-Z]' "$TARGET" 2>/dev/null || true); FUNCS=${FUNCS:-0}
      TYPES=$(grep -cE '^type\s+[A-Z]' "$TARGET" 2>/dev/null || true); TYPES=${TYPES:-0}
      FILE_EXPORTS=$((FUNCS + TYPES))
      ;;
    java)
      FILE_DOCS=$(grep -cE '^\s*/\*\*' "$TARGET" 2>/dev/null || true); FILE_DOCS=${FILE_DOCS:-0}
      FILE_EXPORTS=$(grep -cE '^\s*public\s+(class|interface|enum|abstract)' "$TARGET" 2>/dev/null || true); FILE_EXPORTS=${FILE_EXPORTS:-0}
      ;;
    *)
      echo "  SKIP: $(basename "$filepath") (unknown extension .$EXT)"
      continue
      ;;
  esac

  DOC_IDX=$((DOC_IDX + 1))
  DOC_TOTAL=$((DOC_TOTAL + FILE_DOCS))
  EXPORT_TOTAL=$((EXPORT_TOTAL + FILE_EXPORTS))
  DOC_PER_FILE=$(echo "$DOC_PER_FILE" | jq --arg p "$filepath" --argjson l "$FILE_LINES" --argjson d "$FILE_DOCS" --argjson e "$FILE_EXPORTS" \
    '. + [{"path": $p, "lines": $l, "doc_comments": $d, "exports": $e}]')
  echo "  [$DOC_IDX] $(basename "$filepath"): docs=$FILE_DOCS, exports=$FILE_EXPORTS"
done <<< "$DOC_SAMPLE"

# Write doc-coverage.json
cat > "$OUTDIR/doc-coverage.json" << DCJSON
{
  "sampled_files": $DOC_IDX,
  "fetch_failures": $DOC_FETCH_FAILURES,
  "primary_language": "$PRIMARY_LANG",
  "tree_truncated": $TRUNCATED,
  "total_doc_comments": $DOC_TOTAL,
  "total_exports": $EXPORT_TOTAL,
  "per_file": $(echo "$DOC_PER_FILE" | jq -c '.')
}
DCJSON

if [[ $EXPORT_TOTAL -gt 0 ]]; then
  DOC_RATIO=$(echo "scale=3; $DOC_TOTAL / $EXPORT_TOTAL" | bc | sed 's/^\./0./')
else
  DOC_RATIO="0"
fi
echo "  Doc coverage: $DOC_TOTAL docs / $EXPORT_TOTAL exports = ${DOC_RATIO}"

# --- U2 sampling: fetch 5 representative source files for doc coverage ---
echo "[U2] Sampling source files for doc coverage..."
# Determine extension for primary language
case "$PRIMARY_LANG" in
  Rust) U2_EXT=".rs" ;;
  Haskell) U2_EXT=".hs" ;;
  TypeScript) U2_EXT=".ts" ;;
  JavaScript) U2_EXT=".js" ;;
  Python) U2_EXT=".py" ;;
  Go) U2_EXT=".go" ;;
  *) U2_EXT="" ;;
esac

if [[ -n "$U2_EXT" && -f "$OUTDIR/source-files.tsv" ]]; then
  # Pick 5 files: exclude test files, generated files, and very small files (<50 bytes)
  # Sort by size desc to prefer substantive files, take middle 5 (avoid largest/smallest extremes)
  U2_CANDIDATES=$(grep -E "${U2_EXT}"$'\t' "$OUTDIR/source-files.tsv" 2>/dev/null \
    | grep -vE '(test|spec|mock|fixture|generated|__tests__|\.min\.)' \
    | awk -F'\t' '$2 > 500 && $2 < 50000' \
    | sort -t$'\t' -k2 -n \
    | awk 'NR % int(NR/6 + 1) == 0 || NR == 1' \
    | head -5 \
    | cut -f1)

  U2_IDX=0
  DEFAULT_BRANCH=$(jq -r '.default_branch // "main"' "$OUTDIR/metadata.json" 2>/dev/null || echo "main")
  while IFS= read -r filepath; do
    [[ -z "$filepath" ]] && continue
    SAFE=$(echo "$filepath" | tr '/' '_')
    echo "  Sampling $filepath..."
    # Raw URLs must NOT use Authorization header (returns 404)
    curl -s "https://raw.githubusercontent.com/$REPO/$DEFAULT_BRANCH/$filepath" \
      > "$OUTDIR/sampled_u2_${U2_IDX}_${SAFE}" 2>/dev/null || true
    U2_IDX=$((U2_IDX + 1))
  done <<< "$U2_CANDIDATES"
  echo "  Sampled $U2_IDX files for U2"
fi

# --- 14. High-Assurance Domain Signals ---
echo "[14/14] High-assurance domain signals + .cabal dependency parsing..."

# Detect high-assurance domain
IS_HIGH_ASSURANCE=0
HA_EVIDENCE=""

# Check repo topics/description for high-assurance keywords
if jq -e '.topics[]? | select(test("blockchain|cardano|ledger|consensus|crypto"; "i"))' "$OUTDIR/metadata.json" >/dev/null 2>&1; then
  IS_HIGH_ASSURANCE=1
  HA_EVIDENCE="repo topics"
fi
DESC_CHECK=$(jq -r '.description // ""' "$OUTDIR/metadata.json")
echo "$DESC_CHECK" | grep -qiE '(blockchain|cardano|ledger|consensus|ouroboros)' && { IS_HIGH_ASSURANCE=1; HA_EVIDENCE="${HA_EVIDENCE:+$HA_EVIDENCE, }description"; }

# Check for .agda files (formal specs)
AGDA_FILES=$(jq -r '[.tree[] | select(.type == "blob") | .path | select(test("\\.agda$"))] | length' "$OUTDIR/tree.json")
[[ $AGDA_FILES -gt 0 ]] && { IS_HIGH_ASSURANCE=1; HA_EVIDENCE="${HA_EVIDENCE:+$HA_EVIDENCE, }.agda files ($AGDA_FILES)"; }

# Check for formal-spec directory
FORMAL_SPEC_DIRS=$(jq -r '[.tree[] | select(.type == "tree") | .path | select(test("formal-spec|formal_spec"; "i"))] | length' "$OUTDIR/tree.json")
[[ $FORMAL_SPEC_DIRS -gt 0 ]] && { IS_HIGH_ASSURANCE=1; HA_EVIDENCE="${HA_EVIDENCE:+$HA_EVIDENCE, }formal-spec dirs"; }

# Check for CDDL files
CDDL_FILES=$(jq -r '[.tree[] | select(.type == "blob") | .path | select(test("\\.cddl$"))] | length' "$OUTDIR/tree.json")
[[ $CDDL_FILES -gt 0 ]] && { IS_HIGH_ASSURANCE=1; HA_EVIDENCE="${HA_EVIDENCE:+$HA_EVIDENCE, }.cddl files ($CDDL_FILES)"; }

# Check for conformance directories (including spec-derived test patterns)
CONFORMANCE_DIRS=$(jq -r '[.tree[] | select(.type == "tree") | .path | select(test("conformance|ThreadNet|spec-test|formal-spec.*test"; "i"))] | length' "$OUTDIR/tree.json")

# Fetch up to 3 .cabal files for build-depends / default-extensions parsing.
# Monorepos may have different deps/extensions per sub-package, so we check multiple.
# This is the authoritative source for Hackage dependencies (io-sim, io-classes)
# and language extensions (StrictData, BangPatterns) which aren't in tree or CI files.
CABAL_FILES=""
if [[ -f "$OUTDIR/tree.json" ]]; then
  CABAL_FILES=$(jq -r '[.tree[] | select(.type == "blob") | select(.path | test("\\.cabal$"))] | sort_by(-.size) | .[0:3] | .[].path' "$OUTDIR/tree.json" 2>/dev/null || true)
fi
CABAL_IDX=0
for CABAL_FILE in $CABAL_FILES; do
  [[ -z "$CABAL_FILE" ]] && continue
  TARGET="$OUTDIR/cabal_${CABAL_IDX}.cabal"
  if [[ ! -f "$TARGET" ]]; then
    echo "  Fetching .cabal file: $CABAL_FILE..."
    curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/$CABAL_FILE" | jq -r '.content // empty' | base64 -d > "$TARGET" 2>/dev/null || true
  fi
  # Keep backward compat: first one is also "largest.cabal"
  [[ $CABAL_IDX -eq 0 && ! -f "$OUTDIR/largest.cabal" ]] && cp "$TARGET" "$OUTDIR/largest.cabal" 2>/dev/null || true
  CABAL_IDX=$((CABAL_IDX + 1))
done

# Check for io-sim / io-classes — .cabal build-depends + tree paths + cabal.project + workflow refs
HAS_IO_SIM=0
# Priority 1: .cabal build-depends (authoritative for Hackage deps) — check all fetched .cabal files
for cabal_f in "$OUTDIR"/cabal_*.cabal "$OUTDIR/largest.cabal"; do
  [[ -f "$cabal_f" ]] || continue
  grep -qiE 'build-depends.*\b(io-sim|io-classes)\b' "$cabal_f" 2>/dev/null && HAS_IO_SIM=1
  # Also check multi-line build-depends blocks (dep may be on its own line after build-depends:)
  if [[ $HAS_IO_SIM -eq 0 ]]; then
    grep -qiE '^\s*(,\s*)?(io-sim|io-classes)\b' "$cabal_f" 2>/dev/null && HAS_IO_SIM=1
  fi
  [[ $HAS_IO_SIM -eq 1 ]] && break
done
# Priority 2: tree paths (in-tree io-sim/io-classes packages)
if [[ $HAS_IO_SIM -eq 0 && -f "$OUTDIR/tree.json" ]]; then
  jq -e '.tree[] | select(.path | test("io-sim|io-classes"; "i"))' "$OUTDIR/tree.json" >/dev/null 2>&1 && HAS_IO_SIM=1
fi
# Priority 3: cabal.project source-repository-packages
if [[ $HAS_IO_SIM -eq 0 && -f "$OUTDIR/tree.json" ]]; then
  if jq -e '.tree[] | select(.path == "cabal.project")' "$OUTDIR/tree.json" >/dev/null 2>&1; then
    if [[ ! -f "$OUTDIR/cabal.project" ]]; then
      echo "  Fetching cabal.project for dependency check..."
      curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/cabal.project" | jq -r '.content // empty' | base64 -d > "$OUTDIR/cabal.project" 2>/dev/null || true
    fi
    grep -qiE '(io-sim|io-classes)' "$OUTDIR/cabal.project" 2>/dev/null && HAS_IO_SIM=1
  fi
fi
# Priority 4: workflow file references
if [[ $HAS_IO_SIM -eq 0 ]]; then
  for wf in "$OUTDIR"/wf_*; do
    [[ -f "$wf" ]] || continue
    grep -qiE '(io-sim|io-classes)' "$wf" 2>/dev/null && HAS_IO_SIM=1
  done
fi

# Check for benchmark infrastructure
BENCH_FILES=$(jq -r '[.tree[] | select(.type == "blob") | .path | select(test("bench|benchmark"; "i"))] | length' "$OUTDIR/tree.json")
BENCH_DIRS=$(jq -r '[.tree[] | select(.type == "tree") | .path | select(test("bench|benchmark"; "i"))] | length' "$OUTDIR/tree.json")

# Check for .aiignore (positive governance signal for high-assurance)
HAS_AIIGNORE=0
jq -e '.tree[] | select(.path == ".aiignore" or .path == ".cursorignore")' "$OUTDIR/tree.json" >/dev/null 2>&1 && HAS_AIIGNORE=1

# If high-assurance, sample test files for generator discipline + adversarial patterns
GENERATOR_DISCIPLINE=0
ADVERSARIAL_GENERATORS=0
CUSTOM_ARBITRARY=0
CONFORMANCE_ORACLE=0
if [[ $IS_HIGH_ASSURANCE -eq 1 ]]; then
  # Smart sampling: 4 groups to maximize signal detection
  # Group 1: Generator files (Arbitrary instances, custom generators)
  SAMPLE_GENERATORS=$(jq -r '[.tree[] | select(.type == "blob") | .path | select(test("(Gen[A-Z]|Generators?|Arbitrary).*\\.hs$"))] | .[0:2] | .[]' "$OUTDIR/tree.json" 2>/dev/null || true)
  # Group 2: Test infrastructure files (forAllShrink, cover/classify live here)
  # Prioritize QuickCheck/Property files (most likely to have discipline combinators)
  # Then fall back to Trace/STS files in test paths
  SAMPLE_DISCIPLINE_QC=$(jq -r '[.tree[] | select(.type == "blob") | .path | select(test("(test|testlib).*/QuickCheck.*\\.hs$"; "i")) | select(test("tasty-compat") | not)] | .[0:1] | .[]' "$OUTDIR/tree.json" 2>/dev/null || true)
  SAMPLE_DISCIPLINE_PROP=$(jq -r '[.tree[] | select(.type == "blob") | .path | select(test("(test|testlib).*/Property.*\\.hs$"; "i"))] | .[0:1] | .[]' "$OUTDIR/tree.json" 2>/dev/null || true)
  SAMPLE_DISCIPLINE=$(echo -e "${SAMPLE_DISCIPLINE_QC}\n${SAMPLE_DISCIPLINE_PROP}" | grep -v '^$' | head -2 || true)
  # Group 3: Conformance test files
  SAMPLE_CONFORMANCE=$(jq -r '[.tree[] | select(.type == "blob") | .path | select(test("(conformance|Conformance|ThreadNet|SpecTest).*\\.hs$"; "i"))] | .[0:2] | .[]' "$OUTDIR/tree.json" 2>/dev/null || true)
  # Group 4: General test files (fallback)
  SAMPLE_GENERAL=$(jq -r '[.tree[] | select(.type == "blob") | .path | select(test("(test|spec|Test|Spec).*\\.hs$"))] | .[0:1] | .[]' "$OUTDIR/tree.json" 2>/dev/null || true)
  SAMPLE_TESTS=$(echo -e "${SAMPLE_GENERATORS}\n${SAMPLE_DISCIPLINE}\n${SAMPLE_CONFORMANCE}\n${SAMPLE_GENERAL}" | grep -v '^$' | head -7 || true)

  for test_path in $SAMPLE_TESTS; do
    [[ -z "$test_path" ]] && continue
    echo "  Sampling $test_path for high-assurance patterns..."
    SAFE=$(echo "$test_path" | tr '/' '_')
    curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/$test_path" | jq -r '.content // empty' | base64 -d > "$OUTDIR/sampled_test_$SAFE" 2>/dev/null || true
    [[ ! -s "$OUTDIR/sampled_test_$SAFE" ]] && continue

    grep -qiE '(cover|classify|tabulate|checkCoverage|forAllShrink|forAllBlind|withMaxSuccess|forAllShow)' "$OUTDIR/sampled_test_$SAFE" && GENERATOR_DISCIPLINE=1
    grep -qiE '(Adversarial|Malicious|Invalid|Corrupt)' "$OUTDIR/sampled_test_$SAFE" && ADVERSARIAL_GENERATORS=1
    grep -qiE 'instance.*Arbitrary' "$OUTDIR/sampled_test_$SAFE" && CUSTOM_ARBITRARY=1
    grep -qiE '(conformance|agda|formal.spec)' "$OUTDIR/sampled_test_$SAFE" && CONFORMANCE_ORACLE=1
  done

  # Fallback: if generator discipline not yet detected, sample the largest test file
  # Large test files (>15KB) typically contain comprehensive test suites with discipline combinators
  if [[ $GENERATOR_DISCIPLINE -eq 0 ]]; then
    LARGEST_TEST=$(jq -r '[.tree[] | select(.type == "blob") | select(.path | test("(test|Test).*\\.hs$")) | select(.path | test("(Gen[A-Z]|Arbitrary|Setup|Main)") | not)] | sort_by(-.size) | .[0].path // empty' "$OUTDIR/tree.json" 2>/dev/null)
    if [[ -n "$LARGEST_TEST" ]]; then
      echo "  Fallback: sampling largest test file $LARGEST_TEST for discipline patterns..."
      SAFE=$(echo "$LARGEST_TEST" | tr '/' '_')
      curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/$LARGEST_TEST" | jq -r '.content // empty' | base64 -d > "$OUTDIR/sampled_test_$SAFE" 2>/dev/null || true
      if [[ -s "$OUTDIR/sampled_test_$SAFE" ]]; then
        grep -qiE '(cover|classify|tabulate|checkCoverage|forAllShrink|forAllBlind|withMaxSuccess|forAllShow)' "$OUTDIR/sampled_test_$SAFE" && GENERATOR_DISCIPLINE=1
      fi
    fi
  fi

  # Check CI workflows for benchmark regression detection
  BENCH_CI_REGRESSION=0
  for wf in "$OUTDIR"/wf_*; do
    [[ -f "$wf" ]] || continue
    grep -qiE '(criterion|tasty-bench|bench|benchmark)' "$wf" 2>/dev/null && BENCH_CI_REGRESSION=1
  done

  # Check for StrictData / BangPatterns in default-extensions (from .cabal file)
  HAS_STRICT_DISCIPLINE=0
  # Priority 1: .cabal default-extensions (authoritative source) — check all fetched .cabal files
  for cabal_f in "$OUTDIR"/cabal_*.cabal "$OUTDIR/largest.cabal"; do
    [[ -f "$cabal_f" ]] || continue
    grep -qiE '(StrictData|BangPatterns)' "$cabal_f" 2>/dev/null && { HAS_STRICT_DISCIPLINE=1; break; }
  done
  # Fallback: check workflow files and cabal.project
  if [[ $HAS_STRICT_DISCIPLINE -eq 0 ]]; then
    for f in "$OUTDIR"/wf_* "$OUTDIR"/cabal.project; do
      [[ -f "$f" ]] || continue
      grep -qiE '(StrictData|BangPatterns)' "$f" 2>/dev/null && HAS_STRICT_DISCIPLINE=1
    done
  fi
fi

# Write high-assurance domain data
cat > "$OUTDIR/high-assurance-domain.json" << BDJSON
{
  "is_high_assurance": $IS_HIGH_ASSURANCE,
  "detection_evidence": "$HA_EVIDENCE",
  "supplementary_signals": {
    "formal_spec": {
      "agda_files": $AGDA_FILES,
      "formal_spec_dirs": $FORMAL_SPEC_DIRS,
      "cddl_files": $CDDL_FILES
    },
    "conformance_testing": {
      "conformance_dirs": $CONFORMANCE_DIRS,
      "conformance_oracle": $CONFORMANCE_ORACLE
    },
    "generator_discipline": {
      "cover_classify": $GENERATOR_DISCIPLINE,
      "custom_arbitrary": $CUSTOM_ARBITRARY,
      "adversarial_generators": $ADVERSARIAL_GENERATORS
    },
    "concurrency_testing": {
      "io_sim": $HAS_IO_SIM
    },
    "benchmarks": {
      "bench_files": $BENCH_FILES,
      "bench_dirs": $BENCH_DIRS,
      "ci_regression": ${BENCH_CI_REGRESSION:-0}
    },
    "strict_discipline": ${HAS_STRICT_DISCIPLINE:-0},
    "aiignore": $HAS_AIIGNORE
  }
}
BDJSON

if [[ $IS_HIGH_ASSURANCE -eq 1 ]]; then
  echo "  ★ High-assurance domain detected: $HA_EVIDENCE"
  echo "  Agda: $AGDA_FILES, Formal dirs: $FORMAL_SPEC_DIRS, CDDL: $CDDL_FILES"
  echo "  Conformance dirs: $CONFORMANCE_DIRS, io-sim: $HAS_IO_SIM"
  echo "  Generator discipline: cover=$GENERATOR_DISCIPLINE, adversarial=$ADVERSARIAL_GENERATORS, custom_arbitrary=$CUSTOM_ARBITRARY"
  echo "  Benchmarks: files=$BENCH_FILES, dirs=$BENCH_DIRS, ci_regression=${BENCH_CI_REGRESSION:-0}"
  echo "  .aiignore: $HAS_AIIGNORE"
else
  echo "  Not a high-assurance repo"
fi

echo ""
echo "=== Collection complete ==="
echo "Files: $(ls "$OUTDIR" | wc -l)"
echo "Output: $OUTDIR"

# Summary
echo ""
echo "=== Quick Summary ==="
echo "Repo: $REPO"
echo "Primary language: $PRIMARY_LANG"
echo "Tree entries: $TREE_COUNT (truncated: $TRUNCATED)"
echo "Directories: $DIR_COUNT, Max depth: $MAX_DEPTH"
echo "Source files: $SRC_COUNT, Test files: $TEST_COUNT"
echo "Test/source ratio: $(echo "scale=3; $TEST_COUNT / $SRC_COUNT" | bc 2>/dev/null || echo "N/A")"
echo "Median file: ~$MEDIAN_LINES lines"
echo "Large files (>1000 lines): $LARGE_COUNT"
echo "AI config files: $AI_CONFIG_COUNT"
echo "Workflows: $WF_COUNT"
echo "Package manifests: $MANIFEST_COUNT"
