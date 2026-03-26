# U2 Doc Coverage Auto-Sampling — Design Spec

**Date:** 2026-03-26 · **Status:** Draft
**Goal:** Automate U2 (doc coverage) sampling in the scan pipeline so every repo gets an evidence-based score instead of the default 25.

---

## 1. Problem

U2 (Documentation Coverage, weight 0.25 in Understand pillar) defaults to 25 for every repo because the pipeline never samples actual files. This is the single largest systematic inaccuracy in AAMM — it understates repos with good docs and overstates repos with none. Proven with cardano-ledger: actual coverage 45.8% → score 50, not 25.

## 2. Approach

Add a doc-coverage sampling step to `collect-readiness.sh`. Score from the collected data in `score-readiness.sh`. No new scripts — extends existing pipeline steps.

## 3. Sampling Strategy

### File Selection (deterministic)

1. **Size group (10 files):** Take the 10 largest source files by byte size from the tree API (excluding test files, generated files, Setup.hs, Paths_).
2. **Breadth group (5 files):** Extract distinct path prefixes at depth ≤ 2 that contain at least one source file (e.g., `eras/conway`, `libs/cardano-ledger-core`). Sort alphabetically. For each prefix (up to 5), take the largest source file not already in the size group. If fewer than 5 prefixes exist, the breadth group is smaller.
3. **Deduplicate** — union of both groups → 10-15 unique files.

Same tree = same selection = same score. Determinism guaranteed.

**Truncated trees:** If `tree.truncated == true`, the sample is drawn from whatever the API returned. This is acknowledged as a limitation — the score is "best available from API data." Log a warning in evidence: `"tree_truncated": true`.

### Source File Identification

Source files are identified by extension per primary language:

| Language | Extensions | Exclude patterns |
|---|---|---|
| Haskell | `.hs`, `.lhs` | `test/`, `Test/`, `Setup.hs`, `Paths_` |
| TypeScript | `.ts`, `.tsx` | `test/`, `spec/`, `__test__/`, `.d.ts`, `node_modules/` |
| Rust | `.rs` | `test/`, `tests/`, `benches/` |
| Python | `.py` | `test/`, `tests/`, `conftest.py` |
| Generic | `.hs`, `.ts`, `.rs`, `.py`, `.go`, `.java` | `test/`, `spec/` |

### File Fetching

Use GitHub Contents API (`GET /repos/{owner}/{repo}/contents/{path}`). For files >1MB (API limit), fall back to Blob API (`GET /repos/{owner}/{repo}/git/blobs/{sha}`). Store fetched files as `$OUTDIR/sampled_doc_{index}.ext`.

## 4. Detection Patterns Per Language

### Haskell

**Doc comments:**
- `^\s*-- \|` — single-line Haddock (next declaration)
- `^\s*-- \^` — single-line Haddock (previous declaration)
- `\{-\s*\|` — block Haddock (opening)
- `\{-\s*\^` — block Haddock for previous declaration (opening)

**Export proxies (declarations that should be documented):**

Haskell modules with explicit export lists (`module Foo (bar, baz) where`) only expose a subset of their internal declarations. Counting all type signatures would inflate the denominator and deflate the ratio.

**Strategy:** Check if the file has an explicit export list. If yes, count exported names from the list. If no (module exports everything), count all top-level type signatures.

- **Detect export list:** `^module\s+\S+\s*\(` — if present, the module has an explicit export list
- **Count exported names from list:** Extract the content between `module ... (` and the closing `)` before `where`. Count comma-separated names. This is a regex heuristic: `grep -cE '^\s*,?\s*[a-zA-Z]' ` on the export block lines.
- **Fallback (no export list):** `^[a-z][a-zA-Z0-9_']*\s+::` (all top-level type signatures) + `^(data|type|newtype|class)\s` (type/class declarations)

**`.lhs` (literate Haskell):** Bird-track style prefixes code lines with `> `. Adapt patterns: `^>\s*-- \|` for doc comments, `^>\s*[a-z].*::` for type signatures. If `.lhs` files are encountered, apply adapted patterns. If `\begin{code}` style is detected instead, treat lines between `\begin{code}` and `\end{code}` as normal Haskell.

**Accuracy disclaimer:** Export list parsing via regex is approximate — it doesn't handle re-exports (`module X (module Y)`), pattern synonyms, or operators. For the purpose of a ratio heuristic, this is acceptable. The spec in readiness-scoring.md acknowledges "regex heuristic, not AST parsing."

### TypeScript

**Doc comments:**
- Count lines matching `^\s*/\*\*` — each `/**` opening is one doc block. Do NOT count continuation lines (`*`) or closing (`*/`). Implementation: `grep -cE '^\s*/\*\*' "$file"`.

**Export proxies:**
- `^export\s+(function|class|const|type|interface|enum)` — exported declarations
- `^export\s+default\s+(function|class)` — default exports

### Rust

**Doc comments:**
- `^\s*///` — outer doc comment
- `^\s*//!` — inner doc comment (module-level)

**Export proxies:**
- `^pub\s+(fn|struct|enum|trait|type|const|static)` — public declarations

### Python

**Doc comments:**
- A docstring is a triple-quoted string on the line immediately after a `def` or `class` declaration. Single-line grep cannot detect "immediately after."
- **Implementation:** Use `grep -cE '^\s+"""' "$file"` as an approximation — indented triple-quotes are almost always docstrings (module-level `"""` at column 0 could be a string, but indented ones after def/class are docstrings). This overcounts slightly but is the best regex heuristic without multi-line parsing.
- Alternative: `awk '/^(def |class )/{getline; if(/"""/){c++}} END{print c}'` for precise adjacent-line detection. Use this if the simpler grep proves inaccurate.

**Export proxies:**
- `^def\s` — function definitions (top-level, not indented = public)
- `^class\s` — class definitions (top-level)

### Generic Fallback

For languages not listed above (Go, Java, etc.): apply detection patterns based on file extension, not primary language. A `.hs` file in a TypeScript repo still uses Haskell patterns.

| Extension | Patterns to apply |
|---|---|
| `.hs`, `.lhs` | Haskell |
| `.ts`, `.tsx` | TypeScript |
| `.rs` | Rust |
| `.py` | Python |
| `.go` | Go: doc = `^//\s+[A-Z]` (godoc convention), exports = `^func\s+[A-Z]` + `^type\s+[A-Z]` |
| `.java` | Java: doc = `^\s*/\*\*`, exports = `^\s*public\s+(class\|interface\|enum\|.*\s+\w+\s*\()` |
| Other | Skip — don't guess patterns for unknown extensions |

## 5. Scoring

Aggregate across all sampled files:

```
total_doc_comments = sum(doc_comments per file)
total_exports = sum(export_proxies per file)
ratio = total_doc_comments / total_exports  (0 if total_exports = 0)
```

| Ratio | U2 Score | Boundary |
|---|---|---|
| >70% | 100 | Exclusive: 70.0% scores 75, 70.1% scores 100 |
| >50% and ≤70% | 75 | |
| >30% and ≤50% | 50 | |
| >10% and ≤30% | 25 | |
| ≤10% | 0 | |

**Implementation:** Use `bc` for float comparison. Bash arithmetic cannot handle decimals.

```bash
if (( $(echo "$RATIO > 0.70" | bc -l) )); then U2_SCORE=100
elif (( $(echo "$RATIO > 0.50" | bc -l) )); then U2_SCORE=75
elif (( $(echo "$RATIO > 0.30" | bc -l) )); then U2_SCORE=50
elif (( $(echo "$RATIO > 0.10" | bc -l) )); then U2_SCORE=25
else U2_SCORE=0; fi
```

**Edge cases:**
- No source files in repo → U2 = 0, evidence = "No source files"
- total_exports = 0 across all files → U2 = 0, evidence = "No exported declarations found"
- **Partial fetch failure:** Compute ratio from successfully fetched files only. Note failure count in evidence: `"fetch_failures": 3`. Do NOT zero out the score — a ratio from 10 of 13 files is still meaningful.
- **All fetches failed** → U2 = 0, evidence = "All file fetches failed"

## 6. Output Format

`collect-readiness.sh` writes `$OUTDIR/doc-coverage.json`:

```json
{
  "sampled_files": 13,
  "primary_language": "Haskell",
  "total_doc_comments": 323,
  "total_exports": 704,
  "ratio": 0.458,
  "per_file": [
    {
      "path": "libs/cardano-ledger-core/src/Cardano/Ledger/Address.hs",
      "lines": 999,
      "doc_comments": 42,
      "exports": 86
    }
  ]
}
```

`score-readiness.sh` reads raw counts from `doc-coverage.json` and computes the ratio itself (scorer is always the source of scoring truth — never trust pre-computed scores from collector):

```bash
if [[ -f "$DATADIR/doc-coverage.json" ]]; then
  DOC_TOTAL=$(jq -r '.total_doc_comments' "$DATADIR/doc-coverage.json")
  EXPORT_TOTAL=$(jq -r '.total_exports' "$DATADIR/doc-coverage.json")
  SAMPLED=$(jq -r '.sampled_files' "$DATADIR/doc-coverage.json")
  if [[ $EXPORT_TOTAL -gt 0 ]]; then
    RATIO=$(echo "scale=3; $DOC_TOTAL / $EXPORT_TOTAL" | bc | sed 's/^\./0./')
  else
    RATIO="0"
  fi
  # Apply thresholds (see Section 5)
  if (( $(echo "$RATIO > 0.70" | bc -l) )); then U2_SCORE=100
  elif (( $(echo "$RATIO > 0.50" | bc -l) )); then U2_SCORE=75
  elif (( $(echo "$RATIO > 0.30" | bc -l) )); then U2_SCORE=50
  elif (( $(echo "$RATIO > 0.10" | bc -l) )); then U2_SCORE=25
  else U2_SCORE=0; fi
  U2_EVIDENCE="sampled=$SAMPLED, ratio=$RATIO ($DOC_TOTAL doc / $EXPORT_TOTAL exports)"
else
  # Fallback: should not happen in normal pipeline — emit warning
  echo "WARNING: doc-coverage.json missing for $REPO. U2 defaults to 25." >&2
  U2_SCORE=25
  U2_EVIDENCE="Not sampled — doc-coverage.json missing. Override recommended."
fi
```

## 7. API Budget Impact

+10-15 calls per repo (file content fetches). Current budget: ~25-35 of 50. New total: ~35-50. Within budget.

For the 29-repo batch scan: +290-435 additional calls. Total batch: ~1,015-1,885. Well within GitHub's 5,000/hour rate limit.

## 8. Files Changed

| File | Change |
|---|---|
| `scripts/aamm/collect-readiness.sh` | New step: sample 15 files, detect doc comments per language, write doc-coverage.json |
| `scripts/aamm/score-readiness.sh` | Read raw counts from doc-coverage.json, compute ratio and U2 score (replaces default 25) |
| `scripts/aamm/review-scores.sh` | Remove U2 "default score" override-recommended note (no longer needed when auto-sampled) |
| `models/ai-augmentation-maturity/readiness-scoring.md` | Update U2 "How to measure" with implementation details |

## 9. Validation

After implementation, rescan cardano-ledger. Expected U2 = 50 (matching manual sampling from today: 45.8% ratio). If score differs significantly, debug the pattern matching.
