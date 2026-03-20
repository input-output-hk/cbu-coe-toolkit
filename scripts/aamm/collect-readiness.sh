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
echo "[1/12] Repo metadata..."
curl -s "${AUTH[@]}" "$API/repos/$REPO" | jq '{
  name, full_name, description, default_branch, size, open_issues_count,
  topics, stargazers_count, forks_count, archived, license: .license.spdx_id,
  created_at, pushed_at, private
}' > "$OUTDIR/metadata.json"
DEFAULT_BRANCH=$(jq -r '.default_branch' "$OUTDIR/metadata.json")
echo "  Default branch: $DEFAULT_BRANCH"

# --- 2. Languages ---
echo "[2/12] Languages..."
curl -s "${AUTH[@]}" "$API/repos/$REPO/languages" > "$OUTDIR/languages.json"
TOTAL_BYTES=$(jq 'to_entries | map(.value) | add' "$OUTDIR/languages.json")
jq --argjson total "$TOTAL_BYTES" 'to_entries | map({key, pct: ((.value / $total) * 100 | . * 10 | round / 10)}) | sort_by(-.pct)' "$OUTDIR/languages.json" > "$OUTDIR/languages-pct.json"
PRIMARY_LANG=$(jq -r '.[0].key' "$OUTDIR/languages-pct.json")
echo "  Primary: $PRIMARY_LANG ($(jq -r '.[0].pct' "$OUTDIR/languages-pct.json")%)"

# --- 3. Recursive tree ---
echo "[3/12] Recursive tree..."
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
MEDIAN_BYTES=$(awk -F'\t' '{print $2}' "$OUTDIR/source-files.tsv" | sort -n | awk 'NR==1{n=0} {a[n++]=$1} END{if(n%2) print a[int(n/2)]; else print (a[n/2-1]+a[n/2])/2}')
MEDIAN_LINES=$((MEDIAN_BYTES / BYTES_PER_LINE))
echo "  Median source file: ${MEDIAN_BYTES} bytes (~${MEDIAN_LINES} lines at ${BYTES_PER_LINE} bytes/line)"

# Large files (>1000 lines estimated)
LARGE_THRESHOLD=$((1000 * BYTES_PER_LINE))
awk -F'\t' -v thresh="$LARGE_THRESHOLD" '$2 > thresh {print $0}' "$OUTDIR/source-files.tsv" > "$OUTDIR/large-files.tsv" || true
LARGE_COUNT=$(wc -l < "$OUTDIR/large-files.tsv")
echo "  Large files (>1000 est. lines): $LARGE_COUNT"

# --- 4. AI config files ---
echo "[4/12] AI config files..."
jq -r '.tree[] | select(.type == "blob") | .path' "$OUTDIR/tree.json" \
  | grep -iE '(CLAUDE\.md|claude\.md|AGENTS\.md|GEMINI\.md|copilot-instructions\.md|copilot-setup-steps\.yml|\.cursorrules|\.cursor/rules|\.claude/|\.mcp\.json|mcp\.json|\.coderabbit\.yaml|\.aiignore|\.cursorignore|\.aider|\.windsurfrules|\.continue/|\.sourcegraph/cody|\.codex/)' \
  > "$OUTDIR/ai-config-files.txt" || true
AI_CONFIG_COUNT=$(wc -l < "$OUTDIR/ai-config-files.txt")
echo "  AI config files: $AI_CONFIG_COUNT"

# --- 5. Module boundaries ---
echo "[5/12] Module boundaries..."
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
echo "[6/12] Linter/formatter configs..."
jq -r '.tree[] | select(.type == "blob") | .path' "$OUTDIR/tree.json" \
  | grep -iE '(\.eslintrc|eslint\.config|biome\.json|\.hlint\.yaml|\.hlint\.yml|clippy\.toml|\.pylintrc|ruff\.toml|\.prettierrc|\.rustfmt\.toml|fourmolu\.yaml|\.ormolu|\.stylish-haskell|\.editorconfig|\.stan\.toml|weeder\.toml|\.weeder\.yaml)' \
  > "$OUTDIR/lint-format-configs.txt" || true
echo "  Found: $(cat "$OUTDIR/lint-format-configs.txt" | tr '\n' ', ')"

# --- 7. CI/CD workflows ---
echo "[7/12] CI/CD workflows..."
jq -r '.tree[] | select(.type == "blob") | .path' "$OUTDIR/tree.json" \
  | grep -E '^\.github/workflows/.*\.ya?ml$' \
  > "$OUTDIR/workflow-files.txt" || true
WF_COUNT=$(wc -l < "$OUTDIR/workflow-files.txt")
echo "  Workflows: $WF_COUNT"

# Fetch up to 4 workflow files
head -4 "$OUTDIR/workflow-files.txt" | while IFS= read -r wf; do
  SAFE_NAME=$(echo "$wf" | tr '/' '_')
  echo "  Fetching $wf..."
  curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/$wf" | jq -r '.content' | base64 -d > "$OUTDIR/wf_$SAFE_NAME" 2>/dev/null || true
done

# --- 8. Reproducible environment ---
echo "[8/12] Reproducible environment..."
jq -r '.tree[] | select(.type == "blob") | .path' "$OUTDIR/tree.json" \
  | grep -iE '(^flake\.nix$|^shell\.nix$|^default\.nix$|^Dockerfile$|^docker-compose\.ya?ml$|devcontainer\.json|^flake\.lock$|^cabal\.project\.freeze$|^stack\.yaml\.lock$|yarn\.lock$|package-lock\.json$|Cargo\.lock$|poetry\.lock$|Pipfile\.lock$)' \
  > "$OUTDIR/repro-files.txt" || true
echo "  Found: $(cat "$OUTDIR/repro-files.txt" | tr '\n' ', ')"

# --- 9. Repo foundations ---
echo "[9/12] Repo foundations..."
for f in CODEOWNERS .gitignore SECURITY.md CONTRIBUTING.md LICENSE; do
  if jq -e --arg p "$f" '.tree[] | select(.path == $p)' "$OUTDIR/tree.json" > /dev/null 2>&1; then
    echo "  $f: present"
    curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/$f" | jq -r '.content' | base64 -d > "$OUTDIR/$f" 2>/dev/null || true
  else
    echo "  $f: absent"
  fi
done

# --- 10. README ---
echo "[10/12] README..."
curl -s "${AUTH[@]}" "$API/repos/$REPO/readme" | jq -r '.content' | base64 -d > "$OUTDIR/README.md" 2>/dev/null || true
README_LINES=$(wc -l < "$OUTDIR/README.md" 2>/dev/null || echo 0)
echo "  README: $README_LINES lines"

# --- 11. Recent PRs + reviews (for penalties + adoption L4) ---
echo "[11/12] Recent PRs + reviews..."
curl -s "${AUTH[@]}" "$API/repos/$REPO/pulls?state=closed&sort=updated&direction=desc&per_page=30" > "$OUTDIR/recent-prs.json"

# Extract 10 most recent merged PRs for penalty check
jq '[.[] | select(.merged_at != null)] | sort_by(.merged_at) | reverse | .[0:10]' "$OUTDIR/recent-prs.json" > "$OUTDIR/merged-prs-10.json"

# Get review counts for merged PRs
jq -r '.[].number' "$OUTDIR/merged-prs-10.json" | while IFS= read -r pr_num; do
  curl -s "${AUTH[@]}" "$API/repos/$REPO/pulls/$pr_num/reviews" | jq "{ pr: $pr_num, review_count: length }" >> "$OUTDIR/pr-reviews.jsonl"
done
echo "  Merged PRs checked: $(jq length "$OUTDIR/merged-prs-10.json")"

# --- 12. Recent commits + branch protection ---
echo "[12/12] Commits + branch protection..."
curl -s "${AUTH[@]}" "$API/repos/$REPO/commits?per_page=50" > "$OUTDIR/recent-commits.json"
curl -s "${AUTH[@]}" "$API/repos/$REPO/branches/$DEFAULT_BRANCH/protection" > "$OUTDIR/branch-protection.json" 2>/dev/null || echo '{"error": "404"}' > "$OUTDIR/branch-protection.json"

# Check for submodules
if jq -e '.tree[] | select(.path == ".gitmodules")' "$OUTDIR/tree.json" > /dev/null 2>&1; then
  echo "  .gitmodules: present (submodules detected)"
  curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/.gitmodules" | jq -r '.content' | base64 -d > "$OUTDIR/.gitmodules" 2>/dev/null || true
else
  echo "  .gitmodules: absent"
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
