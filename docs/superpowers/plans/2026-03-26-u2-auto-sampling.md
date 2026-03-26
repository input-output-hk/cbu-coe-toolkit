# U2 Doc Coverage Auto-Sampling — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Automate U2 (doc coverage) sampling so every repo gets an evidence-based score instead of the default 25.

**Architecture:** collect-readiness.sh gets a new step that fetches 15 source files, counts doc comments per language, writes doc-coverage.json. score-readiness.sh reads raw counts and computes U2 from the ratio. review-scores.sh removes the stale "default 25" override note.

**Tech Stack:** Bash, jq, grep, awk, GitHub REST API

**Spec:** `docs/superpowers/specs/2026-03-26-u2-auto-sampling-design.md`

---

### Task 1: Add doc-coverage sampling step to collect-readiness.sh

**Files:**
- Modify: `scripts/aamm/collect-readiness.sh` (insert new step before step 13, after line ~217)

This is the largest task — the core sampling and detection logic.

- [ ] **Step 1: Insert the new step header after the submodules check (line ~217) and before "# --- 13. High-Assurance Domain Signals ---"**

Find the line `# --- 13. High-Assurance Domain Signals ---` and insert the following BEFORE it:

```bash
# --- 13. Doc Coverage Sampling (U2) ---
echo "[13/14] Doc coverage sampling..."

# Select 15 source files: 10 largest + 5 breadth (one per top-level dir)
# Size group: 10 largest non-test source files
DOC_SIZE_GROUP=$(sort -t$'\t' -k2 -nr "$OUTDIR/source-files.tsv" | head -10 | cut -f1)

# Breadth group: distinct path prefixes at depth ≤ 2, one largest file per prefix
DOC_BREADTH_GROUP=""
if [[ -s "$OUTDIR/source-files.tsv" ]]; then
  # Extract depth-2 prefixes (e.g., "eras/conway", "libs/core")
  DOC_PREFIXES=$(cut -f1 "$OUTDIR/source-files.tsv" | awk -F'/' 'NF>=3{print $1"/"$2}' | sort -u | head -5)
  for prefix in $DOC_PREFIXES; do
    # Largest file in this prefix not already in size group
    CANDIDATE=$(grep "^${prefix}/" "$OUTDIR/source-files.tsv" | sort -t$'\t' -k2 -nr | head -1 | cut -f1)
    if [[ -n "$CANDIDATE" ]] && ! echo "$DOC_SIZE_GROUP" | grep -qF "$CANDIDATE"; then
      DOC_BREADTH_GROUP="${DOC_BREADTH_GROUP:+$DOC_BREADTH_GROUP
}$CANDIDATE"
    fi
  done
fi

# Combine and deduplicate
DOC_SAMPLE=$(echo -e "${DOC_SIZE_GROUP}\n${DOC_BREADTH_GROUP}" | grep -v '^$' | sort -u)
DOC_SAMPLE_COUNT=$(echo "$DOC_SAMPLE" | grep -c . || echo 0)
echo "  Selected $DOC_SAMPLE_COUNT files for doc coverage sampling"

# Fetch files and count doc comments
DOC_TOTAL=0
EXPORT_TOTAL=0
DOC_IDX=0
DOC_FETCH_FAILURES=0
DOC_PER_FILE="[]"

for filepath in $DOC_SAMPLE; do
  [[ -z "$filepath" ]] && continue
  DOC_IDX=$((DOC_IDX + 1))
  EXT="${filepath##*.}"
  SAFE=$(echo "$filepath" | tr '/' '_')
  TARGET="$OUTDIR/sampled_doc_${DOC_IDX}.${EXT}"

  # Fetch file content (Contents API, blob fallback for >1MB)
  RESP=$(curl -s "${AUTH[@]}" "$API/repos/$REPO/contents/$filepath")
  MSG=$(echo "$RESP" | jq -r '.message // empty')
  if [[ "$MSG" == "This API returns blobs up to 1 MB in size"* || "$MSG" == "too_large" ]]; then
    SHA=$(jq -r ".tree[] | select(.path == \"$filepath\") | .sha" "$OUTDIR/tree.json")
    if [[ -n "$SHA" && "$SHA" != "null" ]]; then
      curl -s "${AUTH[@]}" "$API/repos/$REPO/git/blobs/$SHA" | jq -r '.content // empty' | base64 -d > "$TARGET" 2>/dev/null || true
    fi
  else
    echo "$RESP" | jq -r '.content // empty' | base64 -d > "$TARGET" 2>/dev/null || true
  fi

  if [[ ! -s "$TARGET" ]]; then
    echo "  SKIP: $filepath (fetch failed)"
    DOC_FETCH_FAILURES=$((DOC_FETCH_FAILURES + 1))
    continue
  fi

  FILE_LINES=$(wc -l < "$TARGET")
  FILE_DOCS=0
  FILE_EXPORTS=0

  case "$EXT" in
    hs)
      # Haddock doc comments
      H_PIPE=$(grep -cE '^\s*-- \|' "$TARGET" 2>/dev/null || true); H_PIPE=${H_PIPE:-0}
      H_CARET=$(grep -cE '^\s*-- \^' "$TARGET" 2>/dev/null || true); H_CARET=${H_CARET:-0}
      H_BLOCK=$(grep -cE '\{-\s*[\|^]' "$TARGET" 2>/dev/null || true); H_BLOCK=${H_BLOCK:-0}
      FILE_DOCS=$((H_PIPE + H_CARET + H_BLOCK))

      # Export proxies: check for explicit export list
      HAS_EXPORT_LIST=$(grep -cE '^module\s+\S+\s*\(' "$TARGET" 2>/dev/null || true)
      if [[ ${HAS_EXPORT_LIST:-0} -gt 0 ]]; then
        # Count exported names from export list (lines between "module...(" and "where")
        FILE_EXPORTS=$(awk '/^module.*\(/{found=1; next} /\)\s*where/{found=0} found{print}' "$TARGET" | grep -cE '^\s*,?\s*[a-zA-Z]' 2>/dev/null || true)
        FILE_EXPORTS=${FILE_EXPORTS:-0}
      else
        # No export list — count all top-level type sigs + declarations
        SIGS=$(grep -cE '^[a-z][a-zA-Z0-9_'\'']*\s+::' "$TARGET" 2>/dev/null || true); SIGS=${SIGS:-0}
        DECLS=$(grep -cE '^(data|type|newtype|class)\s' "$TARGET" 2>/dev/null || true); DECLS=${DECLS:-0}
        FILE_EXPORTS=$((SIGS + DECLS))
      fi
      ;;
    lhs)
      # Literate Haskell: bird-track style (> prefixed lines)
      H_PIPE=$(grep -cE '^>\s*-- \|' "$TARGET" 2>/dev/null || true); H_PIPE=${H_PIPE:-0}
      H_CARET=$(grep -cE '^>\s*-- \^' "$TARGET" 2>/dev/null || true); H_CARET=${H_CARET:-0}
      FILE_DOCS=$((H_PIPE + H_CARET))
      SIGS=$(grep -cE '^>\s*[a-z][a-zA-Z0-9_'\'']*\s+::' "$TARGET" 2>/dev/null || true); SIGS=${SIGS:-0}
      DECLS=$(grep -cE '^>\s*(data|type|newtype|class)\s' "$TARGET" 2>/dev/null || true); DECLS=${DECLS:-0}
      FILE_EXPORTS=$((SIGS + DECLS))
      ;;
    ts|tsx)
      # JSDoc/TSDoc block starts
      FILE_DOCS=$(grep -cE '^\s*/\*\*' "$TARGET" 2>/dev/null || true); FILE_DOCS=${FILE_DOCS:-0}
      # Exported declarations
      FILE_EXPORTS=$(grep -cE '^export\s+(default\s+)?(function|class|const|type|interface|enum)' "$TARGET" 2>/dev/null || true); FILE_EXPORTS=${FILE_EXPORTS:-0}
      ;;
    rs)
      # Rust doc comments
      OUTER=$(grep -cE '^\s*///' "$TARGET" 2>/dev/null || true); OUTER=${OUTER:-0}
      INNER=$(grep -cE '^\s*//!' "$TARGET" 2>/dev/null || true); INNER=${INNER:-0}
      FILE_DOCS=$((OUTER + INNER))
      # Public declarations
      FILE_EXPORTS=$(grep -cE '^pub\s+(fn|struct|enum|trait|type|const|static)' "$TARGET" 2>/dev/null || true); FILE_EXPORTS=${FILE_EXPORTS:-0}
      ;;
    py)
      # Python docstrings (indented triple-quotes ≈ docstrings)
      FILE_DOCS=$(grep -cE '^\s+"""' "$TARGET" 2>/dev/null || true); FILE_DOCS=${FILE_DOCS:-0}
      # Top-level functions and classes
      FUNCS=$(grep -cE '^def\s' "$TARGET" 2>/dev/null || true); FUNCS=${FUNCS:-0}
      CLASSES=$(grep -cE '^class\s' "$TARGET" 2>/dev/null || true); CLASSES=${CLASSES:-0}
      FILE_EXPORTS=$((FUNCS + CLASSES))
      ;;
    go)
      # Go doc comments (godoc convention: comment starting with capital letter)
      FILE_DOCS=$(grep -cE '^//\s+[A-Z]' "$TARGET" 2>/dev/null || true); FILE_DOCS=${FILE_DOCS:-0}
      # Exported functions and types
      FUNCS=$(grep -cE '^func\s+[A-Z]' "$TARGET" 2>/dev/null || true); FUNCS=${FUNCS:-0}
      TYPES=$(grep -cE '^type\s+[A-Z]' "$TARGET" 2>/dev/null || true); TYPES=${TYPES:-0}
      FILE_EXPORTS=$((FUNCS + TYPES))
      ;;
    java)
      # Javadoc blocks
      FILE_DOCS=$(grep -cE '^\s*/\*\*' "$TARGET" 2>/dev/null || true); FILE_DOCS=${FILE_DOCS:-0}
      # Public declarations
      FILE_EXPORTS=$(grep -cE '^\s*public\s+(class|interface|enum|abstract|static|.*\s+\w+\s*\()' "$TARGET" 2>/dev/null || true); FILE_EXPORTS=${FILE_EXPORTS:-0}
      ;;
    *)
      echo "  SKIP: $filepath (unknown extension .$EXT)"
      continue
      ;;
  esac

  DOC_TOTAL=$((DOC_TOTAL + FILE_DOCS))
  EXPORT_TOTAL=$((EXPORT_TOTAL + FILE_EXPORTS))

  # Add to per-file JSON array
  DOC_PER_FILE=$(echo "$DOC_PER_FILE" | jq --arg p "$filepath" --argjson l "$FILE_LINES" --argjson d "$FILE_DOCS" --argjson e "$FILE_EXPORTS" \
    '. + [{"path": $p, "lines": $l, "doc_comments": $d, "exports": $e}]')

  echo "  [$DOC_IDX] $(basename "$filepath"): docs=$FILE_DOCS, exports=$FILE_EXPORTS"
done

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

```

- [ ] **Step 2: Renumber step 13 (High-Assurance) to 14**

Find `# --- 13. High-Assurance Domain Signals ---` and change to `# --- 14. High-Assurance Domain Signals ---`.

Find `echo "[13/13] High-assurance domain signals` and change to `echo "[14/14] High-assurance domain signals`.

Also update the step count reference in step headers `[1/12]` through `[12/12]` — change all `/12]` to `/14]` and `/13]` to `/14]`.

- [ ] **Step 3: Verify the script is syntactically valid**

Run: `bash -n scripts/aamm/collect-readiness.sh`
Expected: no output (no syntax errors)

- [ ] **Step 4: Commit**

```bash
git add scripts/aamm/collect-readiness.sh
git commit -m "feat: add U2 doc coverage sampling to collect-readiness.sh

Samples 15 source files (10 largest + 5 breadth) per repo.
Counts doc comments per language (Haskell/TS/Rust/Python/Go/Java).
Writes doc-coverage.json with per-file counts + aggregates."
```

---

### Task 2: Update score-readiness.sh to use doc-coverage.json

**Files:**
- Modify: `scripts/aamm/score-readiness.sh` (replace lines 354-357)

- [ ] **Step 1: Replace the U2 default scoring block**

Find these exact lines:

```bash
# --- U2: Documentation Coverage ---
# Requires agent sampling. Default: 25 (conservative)
U2_SCORE=$(get_score "U2" "25")
U2_EVIDENCE="Not sampled — requires agent file content analysis. Override recommended."
```

Replace with:

```bash
# --- U2: Documentation Coverage ---
# Reads doc-coverage.json from collector. Falls back to 25 if missing.
if [[ -f "$DATADIR/doc-coverage.json" ]]; then
  DOC_TOTAL=$(jq -r '.total_doc_comments' "$DATADIR/doc-coverage.json")
  EXPORT_TOTAL=$(jq -r '.total_exports' "$DATADIR/doc-coverage.json")
  DOC_SAMPLED=$(jq -r '.sampled_files' "$DATADIR/doc-coverage.json")
  DOC_FAILURES=$(jq -r '.fetch_failures' "$DATADIR/doc-coverage.json")
  if [[ $EXPORT_TOTAL -gt 0 ]]; then
    DOC_RATIO=$(echo "scale=3; $DOC_TOTAL / $EXPORT_TOTAL" | bc | sed 's/^\./0./')
  else
    DOC_RATIO="0"
  fi
  if (( $(echo "$DOC_RATIO > 0.70" | bc -l) )); then U2_SCORE=100
  elif (( $(echo "$DOC_RATIO > 0.50" | bc -l) )); then U2_SCORE=75
  elif (( $(echo "$DOC_RATIO > 0.30" | bc -l) )); then U2_SCORE=50
  elif (( $(echo "$DOC_RATIO > 0.10" | bc -l) )); then U2_SCORE=25
  else U2_SCORE=0; fi
  U2_EVIDENCE="sampled=$DOC_SAMPLED, ratio=$DOC_RATIO ($DOC_TOTAL doc / $EXPORT_TOTAL exports)"
  [[ $DOC_FAILURES -gt 0 ]] && U2_EVIDENCE="$U2_EVIDENCE, fetch_failures=$DOC_FAILURES"
else
  echo "WARNING: doc-coverage.json missing for $REPO. U2 defaults to 25." >&2
  U2_SCORE=25
  U2_EVIDENCE="Not sampled — doc-coverage.json missing. Override recommended."
fi
U2_SCORE=$(get_score "U2" "$U2_SCORE")
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n scripts/aamm/score-readiness.sh`
Expected: no output

- [ ] **Step 3: Commit**

```bash
git add scripts/aamm/score-readiness.sh
git commit -m "feat: U2 scoring reads doc-coverage.json instead of defaulting to 25"
```

---

### Task 3: Update review-scores.sh — remove stale U2 override note

**Files:**
- Modify: `scripts/aamm/review-scores.sh` (lines ~101-113)

- [ ] **Step 1: Replace the U2 review block**

Find the block starting with `# --- U2: Doc Coverage — flag for agent sampling ---` and ending just before `# --- Vulnerability monitoring`. Replace the entire U2 block with:

```bash
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
```

- [ ] **Step 2: Verify syntax**

Run: `bash -n scripts/aamm/review-scores.sh`
Expected: no output

- [ ] **Step 3: Commit**

```bash
git add scripts/aamm/review-scores.sh
git commit -m "refactor: U2 review checks for missing sampling instead of recommending override"
```

---

### Task 4: Update readiness-scoring.md spec

**Files:**
- Modify: `models/ai-augmentation-maturity/readiness-scoring.md` (U2 section, ~lines 279-297)

- [ ] **Step 1: Update the "How to measure" paragraph in U2**

Find the paragraph starting with `**How to measure:** Use the deterministic sample` and replace through the end of the section (before `---`) with:

```markdown
**How to measure:** Automated by the pipeline. `collect-readiness.sh` samples 15 source files (10 largest by size + 5 from distinct directory prefixes for breadth). For each file, regex-counts doc comments and export proxies per language:

- **Haskell:** `-- |`, `-- ^`, `{- |` for doc comments. Export list names if explicit export list present; all top-level type signatures + data declarations otherwise.
- **TypeScript:** `/**` block starts for doc comments. `export (function|class|const|type|interface|enum)` for exports.
- **Rust:** `///`, `//!` for doc comments. `pub (fn|struct|enum|trait)` for exports.
- **Python:** Indented `"""` for docstrings. Top-level `def`/`class` for exports.
- **Go:** `// CapitalLetter` for godoc. Exported `func`/`type` for exports.

Compute ratio = total_doc_comments / total_exports across all sampled files. This is a regex heuristic, not AST parsing. Results stored in `doc-coverage.json`.

**Partial failures:** If some files fail to fetch, compute ratio from successful files only. Note failure count in evidence.
```

- [ ] **Step 2: Commit**

```bash
git add models/ai-augmentation-maturity/readiness-scoring.md
git commit -m "docs: update U2 spec with automated sampling implementation details"
```

---

### Task 5: Validate — rescan cardano-ledger and verify U2

- [ ] **Step 1: Run the collector on cardano-ledger**

```bash
source ~/.zshrc
scripts/aamm/collect-readiness.sh IntersectMBO/cardano-ledger /tmp/aamm-ledger-u2test
```

Verify: `/tmp/aamm-ledger-u2test/doc-coverage.json` exists and has `sampled_files > 0`, `total_doc_comments > 0`, `total_exports > 0`.

- [ ] **Step 2: Run the scorer**

```bash
scripts/aamm/score-readiness.sh IntersectMBO/cardano-ledger /tmp/aamm-ledger-u2test
```

Check output for U2 score. Expected: U2 around 50 (ratio ~45%, bracket 30-50%). If U2 is still 25 or 0, debug the doc-coverage.json content.

- [ ] **Step 3: Run the reviewer**

```bash
scripts/aamm/review-scores.sh IntersectMBO/cardano-ledger /tmp/aamm-ledger-u2test
```

Verify: NO "override_recommended" note for U2 (that was the old behavior). If U2 was sampled successfully, the review should not flag it.

- [ ] **Step 4: Compare with manual sampling**

Manual sampling from this session: 323 docs / 704 exports = 45.8% → score 50.
Automated sampling should produce a similar ratio (not identical — file selection may differ slightly, and export list parsing changes the denominator).

Acceptable range: U2 = 50 (ratio 30-50%) or U2 = 75 (ratio 50-70%). If U2 = 25 or 0, there's a bug.
