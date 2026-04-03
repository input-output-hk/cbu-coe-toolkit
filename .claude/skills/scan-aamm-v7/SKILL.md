---
name: scan-aamm-v7
description: Run AAMM v7 scan — tri-agent (Claude + Gemini + Grok) consensus. Each agent independently requests files from a local clone, analyzes independently, then reaches tiered consensus. Produces ROI-ordered opportunities and recommendations.
---

# AAMM v7 Scan

## Input

Target repo specified as:
- **Single repo:** `owner/repo` directly
- **From config:** "scan all" or "scan next" → read `models/config.yaml`

Optional flags:
- `--mode=learning` — learning scan (union model, kb-proposals output only)
- `--subproject=path/to/subproject` — target specific subproject in monorepos

Set variables:
```
OWNER=<org name>
REPO=<repo name>
ECOSYSTEM=<language, lowercased: haskell|typescript|rust|python|lean|nix|shell>
SCAN_TYPE=<scoring (default) | learning>
SUBPROJECT=<subproject path | null>
SCAN_DIR=/tmp/aamm-v7-$OWNER-$REPO
```

## Phase 0 — Setup

### Step 0.1: Health Checks (parallel)

```bash
source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null

# Gemini health check
GEMINI_OK=$(gemini -p "Reply with exactly: AAMM_READY" --yolo -m gemini-2.5-pro -o text \
  2>/dev/null | grep -c "AAMM_READY")

# Grok health check
GROK_OK=$(bash scripts/grok-invoke.sh grok-4-0709 "Reply with exactly: AAMM_READY" \
  2>/dev/null | grep -c "AAMM_READY")

if [ "$GEMINI_OK" != "1" ]; then
  echo "FATAL: Gemini health check failed. Cannot start scan."
  echo "Verify: gemini CLI installed, authenticated, not rate-limited."
  # STOP — do not continue
fi

if [ "$GROK_OK" != "1" ]; then
  echo "FATAL: Grok health check failed. Cannot start scan."
  echo "Verify: XAI_API_KEY set, api.x.ai reachable."
  # STOP — do not continue
fi

echo "Health checks passed: Gemini ✓ Grok ✓"
```

### Step 0.2: GitHub Access Check

```bash
source ~/.zshrc 2>/dev/null || true
if [ -z "$GITHUB_TOKEN" ]; then
  echo "FATAL: GITHUB_TOKEN not set."
  # STOP
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO")

if [ "$HTTP_CODE" != "200" ]; then
  echo "FATAL: Cannot access $OWNER/$REPO (HTTP $HTTP_CODE). Check GITHUB_TOKEN scope."
  # STOP — no clone attempted
fi
```

### Step 0.3: Clone Repository

```bash
mkdir -p "$SCAN_DIR"

if [ "$SCAN_TYPE" = "learning" ]; then
  git clone --shallow-since="12 months ago" \
    "https://$GITHUB_TOKEN@github.com/$OWNER/$REPO" \
    "$SCAN_DIR/clone/"
  if [ $? -ne 0 ]; then
    echo "FATAL: Clone failed for $OWNER/$REPO. Check GITHUB_TOKEN scope and network."
    # STOP
  fi
  # B6 fix: if shallow clone produced fewer than 500 commits, go deeper for KB signal coverage
  COMMIT_COUNT=$(git -C "$SCAN_DIR/clone" rev-list --count HEAD 2>/dev/null || echo 0)
  if [ "$COMMIT_COUNT" -lt 500 ]; then
    echo "[clone] Only $COMMIT_COUNT commits — re-cloning with 24-month window for better signal coverage"
    rm -rf "$SCAN_DIR/clone"
    git clone --shallow-since="24 months ago" \
      "https://$GITHUB_TOKEN@github.com/$OWNER/$REPO" \
      "$SCAN_DIR/clone/"
    if [ $? -ne 0 ]; then
      echo "FATAL: Deep clone failed for $OWNER/$REPO."
      # STOP
    fi
  fi
else
  git clone --depth=100 \
    "https://$GITHUB_TOKEN@github.com/$OWNER/$REPO" \
    "$SCAN_DIR/clone/"
  if [ $? -ne 0 ]; then
    echo "FATAL: Clone failed for $OWNER/$REPO. Check GITHUB_TOKEN scope and network."
    # STOP
  fi
fi

# LFS handling
if [ -f "$SCAN_DIR/clone/.gitattributes" ]; then
  cd "$SCAN_DIR/clone" && git lfs install && git lfs pull 2>/dev/null || true
  cd -
fi
```

### Step 0.4: Detect Repo Type

```bash
CLONE="$SCAN_DIR/clone"

# B2 fix: bash-first detection — apply rules in order, write result to file
REPO_TYPE="mixed"  # default

# Rule 1: infrastructure
if find "$CLONE" -maxdepth 1 \( -name "*.tf" -o -name "flake.nix" -o -name "default.nix" -o -name "Chart.yaml" \) | grep -q . ; then
  REPO_TYPE="infrastructure"
# Rule 2: web-app (check package.json for server deps)
elif [ -f "$CLONE/package.json" ] && python3 -c "
import json,sys
pkg=json.load(open(sys.argv[1]))
deps={**pkg.get('dependencies',{}),**pkg.get('devDependencies',{})}
webkw=['react','next','vue','express','fastify','koa','hapi','nuxt']
sys.exit(0 if any(k in deps for k in webkw) else 1)
" "$CLONE/package.json" 2>/dev/null; then
  REPO_TYPE="web-app"
# Rule 3: cli-tool
elif [ -f "$CLONE/Cargo.toml" ] && grep -q '^\[\[bin\]\]' "$CLONE/Cargo.toml" 2>/dev/null; then
  REPO_TYPE="cli-tool"
elif [ -f "$CLONE/package.json" ] && python3 -c "
import json,sys; pkg=json.load(open(sys.argv[1])); sys.exit(0 if 'bin' in pkg else 1)
" "$CLONE/package.json" 2>/dev/null; then
  REPO_TYPE="cli-tool"
elif find "$CLONE" -maxdepth 2 -name "*.cabal" | xargs grep -l "^executable" 2>/dev/null | grep -q .; then
  REPO_TYPE="cli-tool"
# Rule 4: library
elif [ -f "$CLONE/Cargo.toml" ] && grep -q '^\[lib\]' "$CLONE/Cargo.toml" 2>/dev/null; then
  REPO_TYPE="library"
elif find "$CLONE" -maxdepth 2 -name "*.cabal" | xargs grep -l "^library" 2>/dev/null | grep -q .; then
  REPO_TYPE="library"
elif [ -f "$CLONE/package.json" ] && ! python3 -c "
import json,sys; pkg=json.load(open(sys.argv[1])); sys.exit(0 if 'bin' in pkg else 1)
" "$CLONE/package.json" 2>/dev/null; then
  REPO_TYPE="library"
fi

echo "$REPO_TYPE" > "$SCAN_DIR/repo_type.txt"
echo "Detected repo_type: $REPO_TYPE"
```

### Step 0.5: Detect Monorepo

```bash
CLONE="$SCAN_DIR/clone"

# Find package manifests at depth > 1, outside deny-listed dirs
MANIFESTS=$(find "$CLONE" -mindepth 2 -maxdepth 4 \
  \( -name "package.json" -o -name "Cargo.toml" -o -name "*.cabal" -o -name "pyproject.toml" \) \
  | grep -vE "/(vendor|deps|third_party|extern|node_modules|\.git|_build|dist)/" \
  | head -20)

MANIFEST_COUNT=$(echo "$MANIFESTS" | grep -c . 2>/dev/null || echo 0)
```

If MANIFEST_COUNT >= 2: monorepo detected. Build subprojects list:
- For each manifest: extract name, root_dir, language, last_commit_date
- Cross-check churn: `git log --since="90 days ago" -- "$subdir" | wc -l`
- Exclude subprojects with < 5 commits in 90 days (vendored/stale)
- Write `$SCAN_DIR/subprojects.json`

If `--subproject` flag provided: use that subproject.
If monorepo but no `--subproject`: select highest-churn non-deny-listed subproject; if churn tie → select alphabetically first.
Log selection to stdout: `echo "[monorepo] Selected subproject: $SUBPROJECT (churn rank: $RANK)"` — no operator prompt, fully autonomous.

### Step 0.6: Generate Manifest

Claude (orchestrator) generates manifest.json from the clone. Read the repository to populate all fields.

```bash
# B5 fix: explicit bash for manifest generation
cd "$SCAN_DIR/clone"

# File tree (exclude deny-listed dirs)
python3 -c "
import os, json

deny = {'vendor','deps','third_party','extern','node_modules','.git','_build','dist'}
tree = []
for root, dirs, files in os.walk('.'):
    dirs[:] = [d for d in dirs if d not in deny]
    for f in files:
        p = os.path.join(root, f).lstrip('./')
        size = os.path.getsize(os.path.join(root, f))
        ext = os.path.splitext(f)[1]
        tree.append({'path': p, 'size_bytes': size, 'ext': ext})
print(json.dumps(tree))
" > /tmp/file_tree.json

# Git stats: commit counts per file (last 100 commits)
git log --pretty=format: --name-only -n 100 | sort | uniq -c | sort -rn \
  | awk '{print \$2, \$1}' > /tmp/file_commit_counts.txt

python3 -c "
import json
counts = {}
for line in open('/tmp/file_commit_counts.txt'):
    parts = line.strip().split()
    if len(parts) == 2:
        counts[parts[0]] = int(parts[1])
print(json.dumps(counts))
" > /tmp/file_commit_counts.json

# Contributor count
CONTRIBUTORS=$(git shortlog -sn --no-merges | wc -l)

# Open PR count via GitHub API
OPEN_PRS=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/pulls?state=open&per_page=1" \
  -I | grep -i x-total-count | awk '{print $2}' | tr -d '[:space:]' || echo "unknown")

python3 - << 'MANIFEST_END'
import json, os
from datetime import date

tree = json.load(open('/tmp/file_tree.json'))
counts = json.load(open('/tmp/file_commit_counts.json'))

# Commit counts per dir
dir_counts = {}
for path, c in counts.items():
    d = path.split('/')[0] + '/' if '/' in path else path
    dir_counts[d] = dir_counts.get(d, 0) + c

manifest = {
    'repo': f"{os.environ['OWNER']}/{os.environ['REPO']}",
    'scan_date': str(date.today()),
    'repo_type': open(os.environ['SCAN_DIR'] + '/repo_type.txt').read().strip(),
    'subproject': os.environ.get('SUBPROJECT', None),
    'language': os.environ['ECOSYSTEM'],
    'last_commit_date': os.popen('git log -1 --format=%cs').read().strip(),
    'contributor_count': int(os.environ.get('CONTRIBUTORS', 0)),
    'open_pr_count': os.environ.get('OPEN_PRS', 'unknown'),
    'file_tree': tree,
    'git_stats': {
        'commit_count_per_dir': dir_counts,
        'file_commit_counts': counts,
    },
    'subprojects': [],
    'deny_listed_paths': ['vendor/', 'deps/', 'third_party/', 'extern/', 'node_modules/', '.git/', '_build/', 'dist/'],
}
json.dump(manifest, open(os.environ['SCAN_DIR'] + '/manifest.json', 'w'), indent=2)
print('Manifest generated:', os.environ['SCAN_DIR'] + '/manifest.json')
MANIFEST_END

cd -
```

```json
{
  "repo": "owner/repo",
  "scan_date": "YYYY-MM-DD",
  "repo_type": "library|web-app|cli-tool|infrastructure|mixed",
  "subproject": "path/or/null",
  "language": "haskell",
  "topics": ["cardano", "blockchain"],
  "last_commit_date": "YYYY-MM-DD",
  "contributor_count": 42,
  "open_pr_count": 7,
  "file_tree": [
    {"path": "src/Main.hs", "size_bytes": 4200, "ext": ".hs"}
  ],
  "git_stats": {
    "commit_count_per_dir": {"src/": 87, "test/": 34},
    "file_commit_counts": {"src/Main.hs": 23, "src/Lib.hs": 45}
  },
  "subprojects": [],
  "deny_listed_paths": ["vendor/", "node_modules/"]
}
```

RULE: No file contents. No signals. Raw structure and stats only.
Save to `$SCAN_DIR/manifest.json`.

Determine active SDLC sections from repo_type (see spec Section 4 pruning table).
Save to `$SCAN_DIR/active_sdlc_sections.json`.

Save state: `$SCAN_DIR/consensus-state.json`:
```json
{"phase": 0, "status": "setup_complete", "scan_type": "scoring", "partial": false, "partial_reason": null, "agents_active": ["claude", "gemini", "grok"]}
```

State is updated at EVERY phase boundary and after each consensus round (B3 fix):
- After Phase 1 file requests: `{"phase": 1, "status": "file_requests_complete"}`
- After each consensus round N: `{"phase": 3, "status": "consensus_round_N_complete", "round": N, "pending_items": K}`
- After Phase 3: `{"phase": 3, "status": "complete"}`
- After Phase 4: `{"phase": 4, "status": "complete"}`
- After Phase 5: `{"phase": 5, "status": "report_complete"}`

Restart handling: if `$SCAN_DIR/consensus-state.json` exists at start, read phase and resume from that point rather than re-cloning.

## Phase 1 — Independent File Requests

### Step 1.1: Dispatch file requests (independent — no agent sees another's request)

```bash
mkdir -p "$SCAN_DIR/phase-1" "$SCAN_DIR/audit"

# Load shared injection variables (used by all three agents below)
MANIFEST_JSON=$(cat "$SCAN_DIR/manifest.json")
REPO_TYPE_VAL=$(cat "$SCAN_DIR/repo_type.txt")
ACTIVE_SDLC=$(cat "$SCAN_DIR/active_sdlc_sections.json")
KB_ECOSYSTEM=$(cat "models/ai-augmentation-maturity/knowledge-base/ecosystems/$ECOSYSTEM.md" 2>/dev/null || echo "No ecosystem KB found for $ECOSYSTEM")
KB_CROSSCUTTING=$(cat "models/ai-augmentation-maturity/knowledge-base/cross-cutting.md")
KB_ANTIPATTERNS=$(cat "models/ai-augmentation-maturity/knowledge-base/anti-patterns.md")
```

**Claude Subagent — File Request:**
Dispatch a Claude subagent with:
- Input: manifest.json + KB ecosystem file + cross-cutting.md + anti-patterns.md + scoring-model.md + active_sdlc_sections.json
- Task: "Based on this manifest and KB, list the files you want to examine. Output a JSON array of file paths only: [\"path1\", \"path2\", ...]"
- Output: `$SCAN_DIR/phase-1/file-request-claude.json` (JSON array of paths)
- Context released after output

**Gemini — File Request:**
```bash
# B1 fix: write python script to temp file to avoid heredoc-PYEOF collision if KB content
# contains the literal string PYEOF (would close heredoc early and corrupt the prompt).
cat > /tmp/aamm-v7-inject.py << 'INJECT_SCRIPT_END'
import os, sys

template_path = sys.argv[1]
output_path = sys.argv[2]

with open(template_path) as f:
    prompt = f.read()

eco = os.environ['ECOSYSTEM']
scan_dir = os.environ['SCAN_DIR']
kb_eco_path = f"models/ai-augmentation-maturity/knowledge-base/ecosystems/{eco}.md"

replacements = {
    '{OWNER}': os.environ['OWNER'],
    '{REPO}': os.environ['REPO'],
    '{CLONE_PATH}': scan_dir + '/clone',
    '{ECOSYSTEM}': eco,
    '{REPO_TYPE}': open(scan_dir + '/repo_type.txt').read().strip(),
    '{ACTIVE_SDLC_SECTIONS}': open(scan_dir + '/active_sdlc_sections.json').read(),
    '{MANIFEST_JSON}': open(scan_dir + '/manifest.json').read(),
    '{KB_ECOSYSTEM_CONTENT}': open(kb_eco_path).read() if os.path.exists(kb_eco_path) else 'No ecosystem KB',
    '{KB_CROSSCUTTING_CONTENT}': open('models/ai-augmentation-maturity/knowledge-base/cross-cutting.md').read(),
    '{KB_ANTIPATTERNS_CONTENT}': open('models/ai-augmentation-maturity/knowledge-base/anti-patterns.md').read(),
}
for k, v in replacements.items():
    prompt = prompt.replace(k, v)

with open(output_path, 'w') as f:
    f.write(prompt)
INJECT_SCRIPT_END

python3 /tmp/aamm-v7-inject.py \
  '.claude/skills/scan-aamm-v7/prompts/gemini-file-request.md' \
  "$SCAN_DIR/phase-1/gemini-file-request-prompt.md"

cd "$SCAN_DIR/clone"
gemini -p "$(cat $SCAN_DIR/phase-1/gemini-file-request-prompt.md)" \
  --yolo -m gemini-2.5-pro -o text \
  2>"$SCAN_DIR/phase-1/gemini-file-request-stderr.txt" \
  | tee "$SCAN_DIR/phase-1/gemini-file-request-raw.md"
cd -
```

Parse JSON array from output → `$SCAN_DIR/phase-1/file-request-gemini.json`:
```bash
python3 -c "
import sys, json, re
raw = open('$SCAN_DIR/phase-1/gemini-file-request-raw.md').read()
m = re.search(r'\[.*?\]', raw, re.DOTALL)
if not m:
    print('ERROR: No JSON array in Gemini file request output', file=sys.stderr)
    sys.exit(1)
paths = json.loads(m.group(0))
json.dump(paths, open('$SCAN_DIR/phase-1/file-request-gemini.json','w'), indent=2)
print(f'Gemini requested {len(paths)} files')
"
```

**Grok — File Request (batch 1):**
```bash
# B1 fix: reuse /tmp/aamm-v7-inject.py (already written above) with Grok template.
# Also add BATCH_NUMBER to replacements for Grok-specific batching.
cat > /tmp/aamm-v7-inject-grok.py << 'INJECT_GROK_END'
import os, sys

template_path = sys.argv[1]
output_path = sys.argv[2]
batch_num = sys.argv[3] if len(sys.argv) > 3 else '1'
prior_findings = sys.argv[4] if len(sys.argv) > 4 else 'None — this is batch 1'

with open(template_path) as f:
    prompt = f.read()

eco = os.environ['ECOSYSTEM']
scan_dir = os.environ['SCAN_DIR']
kb_eco_path = f"models/ai-augmentation-maturity/knowledge-base/ecosystems/{eco}.md"

replacements = {
    '{OWNER}': os.environ['OWNER'],
    '{REPO}': os.environ['REPO'],
    '{REPO_TYPE}': open(scan_dir + '/repo_type.txt').read().strip(),
    '{ACTIVE_SDLC_SECTIONS}': open(scan_dir + '/active_sdlc_sections.json').read(),
    '{BATCH_NUMBER}': batch_num,
    '{MANIFEST_JSON}': open(scan_dir + '/manifest.json').read(),
    '{KB_ECOSYSTEM_CONTENT}': open(kb_eco_path).read() if os.path.exists(kb_eco_path) else 'No ecosystem KB',
    '{KB_CROSSCUTTING_CONTENT}': open('models/ai-augmentation-maturity/knowledge-base/cross-cutting.md').read(),
    '{KB_ANTIPATTERNS_CONTENT}': open('models/ai-augmentation-maturity/knowledge-base/anti-patterns.md').read(),
    '{PRIOR_BATCH_FINDINGS_OR_NONE}': prior_findings,
}
for k, v in replacements.items():
    prompt = prompt.replace(k, v)

with open(output_path, 'w') as f:
    f.write(prompt)
INJECT_GROK_END

python3 /tmp/aamm-v7-inject-grok.py \
  '.claude/skills/scan-aamm-v7/prompts/grok-file-request.md' \
  "$SCAN_DIR/phase-1/grok-file-request-prompt.md" \
  "1" "None — this is batch 1"

source ~/.zshrc 2>/dev/null
bash scripts/grok-invoke.sh grok-4-0709 "$(cat $SCAN_DIR/phase-1/grok-file-request-prompt.md)" \
  > "$SCAN_DIR/phase-1/grok-file-request-raw.md" \
  2>"$SCAN_DIR/phase-1/grok-file-request-stderr.txt"
```

Parse JSON array → `$SCAN_DIR/phase-1/file-request-grok-batch-1.json`:
```bash
python3 -c "
import sys, json, re
raw = open('$SCAN_DIR/phase-1/grok-file-request-raw.md').read()
m = re.search(r'\[.*?\]', raw, re.DOTALL)
if not m:
    print('ERROR: No JSON array in Grok file request output', file=sys.stderr)
    sys.exit(1)
paths = json.loads(m.group(0))
json.dump(paths, open('$SCAN_DIR/phase-1/file-request-grok-batch-1.json','w'), indent=2)
print(f'Grok requested {len(paths)} files (batch 1)')
"
```

RULE: Claude, Gemini, Grok file request outputs are NOT shown to each other.

### Step 1.2: Serve files from clone

Orchestrator reads each agent's file request list and serves files from `$SCAN_DIR/clone/`:

```bash
# B5 fix: explicit file-serving loop
serve_files() {
  local AGENT=$1
  local REQUEST_FILE=$2
  local OUTPUT_FILE=$3

  python3 - "$SCAN_DIR/clone" "$REQUEST_FILE" "$OUTPUT_FILE" << 'SERVE_END'
import json, sys, os

clone_dir = sys.argv[1]
requests = json.load(open(sys.argv[2]))
results = []

for path in requests:
    full_path = os.path.join(clone_dir, path.lstrip('/'))
    if os.path.isfile(full_path):
        try:
            content = open(full_path, 'r', errors='replace').read()
            results.append({"path": path, "content": content})
        except Exception as e:
            results.append({"path": path, "error": str(e)})
    else:
        results.append({"path": path, "error": "not found"})

json.dump(results, open(sys.argv[3], 'w'), indent=2)
print(f"Served {len(results)} files for {sys.argv[3]}")
SERVE_END
}

serve_files "claude" "$SCAN_DIR/phase-1/file-request-claude.json" "$SCAN_DIR/phase-1/served-files-claude.json"
serve_files "gemini" "$SCAN_DIR/phase-1/file-request-gemini.json" "$SCAN_DIR/phase-1/served-files-gemini.json"
# Grok: serve batch 1 (subsequent batches served during Phase 2 loop)
# Prioritize by git_stats.file_commit_counts (highest churn first) if >50 files requested (B6 fix)
python3 -c "
import json
req = json.load(open('$SCAN_DIR/phase-1/file-request-grok-batch-1.json'))
stats = json.load(open('$SCAN_DIR/manifest.json')).get('git_stats', {}).get('file_commit_counts', {})
req_sorted = sorted(req, key=lambda p: stats.get(p, 0), reverse=True)[:50]
json.dump(req_sorted, open('$SCAN_DIR/phase-1/file-request-grok-batch-1-prioritized.json', 'w'), indent=2)
print(f'Grok batch 1: {len(req_sorted)} files (prioritized by commit churn)')
"
serve_files "grok" "$SCAN_DIR/phase-1/file-request-grok-batch-1-prioritized.json" "$SCAN_DIR/phase-1/served-files-grok-batch-1.json"
```

Audit log: `$SCAN_DIR/audit/file-requests.json`:
```json
{
  "claude": ["src/Main.hs", ".github/workflows/ci.yml"],
  "gemini": ["src/Main.hs", "CLAUDE.md", ".github/workflows/"],
  "grok_batch_1": [".github/workflows/ci.yml", "docs/architecture.md"]
}
```

### Step 1.3: Handle Grok batching

After receiving Grok's initial analysis (Phase 2), check for `need_more_files` field.
If present and non-empty, AND batch count < 5:
- Serve next batch of up to 50 files
- Invoke Grok again with batch N + prior batch findings
- Repeat until `need_more_files` is empty or batch 5 reached

If batch 5 exhausted and Grok still needs files:
- Set `$SCAN_DIR/grok-partial.txt` with list of unserved files
- Report will include ⚠ WARNING banner

## Phase 2 — Independent Analysis

Each agent receives its served files and produces an opportunity map independently.
No agent sees another's output at this stage.

### Step 2.1: Claude Subagent Analysis

Dispatch Claude subagent with:
- Input: served-files-claude.json + KB + scoring-model.md + active_sdlc_sections.json
- Task: Follow scoring-model.md Section 2 to produce opportunity map
- Output: `$SCAN_DIR/phase-1/opportunity-map-claude.json`
- Context released after output

### Step 2.2: Gemini Analysis

Build prompt from `prompts/gemini-phase1-analysis.md` using the same python3 injection pattern from Step 1.1.
Additional substitutions:
- `{SUBPROJECT_OR_NONE}` = subproject path or "null"
- `{SERVED_FILE_CONTENTS}` = contents of served-files-gemini.json (file paths + contents)

```bash
cd "$SCAN_DIR/clone"
gemini -p "$(cat $SCAN_DIR/phase-1/gemini-analysis-prompt.md)" \
  --yolo -m gemini-2.5-pro -o text \
  2>"$SCAN_DIR/phase-1/gemini-analysis-stderr.txt" \
  | tee "$SCAN_DIR/phase-1/gemini-analysis-raw.md"
cd -
```

Handle Gemini unavailability mid-scan:
```
If gemini call fails with 429/timeout:
  → Wait 120s, retry ×5
  → If still failing after 5 retries:
      Set $SCAN_DIR/gemini-partial.txt = "Phase 2 — analysis"
      Update consensus-state.json: {"partial": true, "partial_reason": "Gemini unavailable after 5 retries in Phase 2", "agents_active": ["claude", "grok"]}
      Continue with Claude + Grok only
```

Parse + validate JSON from output → `$SCAN_DIR/phase-1/opportunity-map-gemini.json`:
```bash
# B3 fix: validate JSON — retry with format-correction prompt if parse fails
python3 -c "
import json, sys, re
raw = open('$SCAN_DIR/phase-1/gemini-analysis-raw.md').read()
m = re.search(r'\{.*\}', raw, re.DOTALL)
if not m:
    sys.exit(1)
data = json.loads(m.group(0))
json.dump(data, open('$SCAN_DIR/phase-1/opportunity-map-gemini.json','w'), indent=2)
" 2>/dev/null || {
  echo "[gemini] Phase 2 output is not valid JSON — retrying with format reminder"
  FORMAT_REMINDER="Your previous response was not valid JSON. Reply with ONLY a JSON object matching: {\"opportunities\": [...]}. No prose, no markdown fences."
  cd "$SCAN_DIR/clone"
  gemini -p "$FORMAT_REMINDER" \
    --yolo -m gemini-2.5-pro -o text \
    2>>"$SCAN_DIR/phase-1/gemini-analysis-stderr.txt" \
    | tee "$SCAN_DIR/phase-1/gemini-analysis-retry-raw.md"
  cd -
  python3 -c "
import json, sys, re
raw = open('$SCAN_DIR/phase-1/gemini-analysis-retry-raw.md').read()
m = re.search(r'\{.*\}', raw, re.DOTALL)
if not m:
    print('ERROR: Gemini analysis still not valid JSON after retry — triggering PARTIAL', file=sys.stderr)
    open('$SCAN_DIR/gemini-partial.txt','w').write('Phase 2 — analysis: JSON parse failed after retry')
    sys.exit(0)  # continue with PARTIAL, not STOP
data = json.loads(m.group(0))
json.dump(data, open('$SCAN_DIR/phase-1/opportunity-map-gemini.json','w'), indent=2)
" 2>&1
}
```

### Step 2.3: Grok Analysis (batched)

Build prompt from `prompts/grok-phase1-analysis.md` with batch 1 files using same injection pattern.
Additional substitutions:
- `{SUBPROJECT_OR_NONE}` = subproject path or "null"
- `{SERVED_FILE_CONTENTS}` = contents of served-files-grok-batch-1.json
- `{PARTIAL_COVERAGE_NOTE}` = "" (empty unless Grok is in PARTIAL mode)
- `{PRIOR_BATCH_FINDINGS_OR_NONE}` = "None — this is batch 1"

```bash
source ~/.zshrc 2>/dev/null
bash scripts/grok-invoke.sh grok-4-0709 \
  "$(cat $SCAN_DIR/phase-1/grok-analysis-prompt-batch-1.md)" \
  > "$SCAN_DIR/phase-1/grok-analysis-batch-1-raw.md" \
  2>"$SCAN_DIR/phase-1/grok-analysis-batch-1-stderr.txt"
```

Handle Grok unavailability mid-scan (same as Gemini above — symmetric).

Check `need_more_files` in Grok's output. If non-empty and batch < 5:
- Build next batch prompt with prior batch findings injected
- Invoke Grok again
- Merge findings across batches into `$SCAN_DIR/phase-1/opportunity-map-grok.json`

If batch 5 exhausted: set `$SCAN_DIR/grok-partial.txt`, update consensus-state.json.

## Phase 3 — Consensus: Opportunity Map

### Step 3.1: Intersection-first merge

Orchestrator compares all three opportunity maps:

```
# B4 fix: read active agents from consensus-state.json (not hardcoded to 3)
ACTIVE_AGENTS=$(python3 -c "
import json
state = json.load(open('$SCAN_DIR/consensus-state.json'))
print(','.join(state.get('agents_active', ['claude','gemini','grok'])))
")
AGENT_COUNT=$(echo "$ACTIVE_AGENTS" | tr ',' '\n' | wc -l)

Match criteria:
  - Same kb_pattern (non-null) → proposed intersection match
  - Same target module/dir + same use-case type (for kb_pattern: null) → proposed match

For each proposed match: build confirmation prompt showing findings from all active agents.
Ask all ACTIVE agents: "Assess as equivalent / partial_overlap / distinct — evidence required."

If AGENT_COUNT == 3:
  Items where all 3 say 'equivalent' → auto-approved, consensus_round: 0, value_reason: "all_high"
  Items where 2+ say 'partial_overlap' or agents disagree → enter consensus loop

If AGENT_COUNT == 2 (PARTIAL mode):
  Items where both say 'equivalent' → auto-approved, consensus_round: 0, value_reason: "all_high"
  Items where 1 says 'partial_overlap' → enter consensus loop
  Thresholds in loop: both ≥9 → HIGH; one ≥9 + other ≥7 → MEDIUM; otherwise → consensus:false

Items unique to 1 agent → enter consensus loop (regardless of AGENT_COUNT)
```

Save:
- `$SCAN_DIR/phase-1/intersection.json` (auto-approved)
- `$SCAN_DIR/phase-1/unique-claude.json`
- `$SCAN_DIR/phase-1/unique-gemini.json`
- `$SCAN_DIR/phase-1/unique-grok.json`

### Step 3.2: Consensus loop (max 5 rounds)

For each round N, for each pending item:

**Claude scores pending items** — B4 fix: dispatch Claude subagent with assembled prompt:

Build `$SCAN_DIR/phase-1/claude-prompt-round-$N.md`:
- Template: `prompts/gemini-consensus-round.md` (same structure, adapted for Claude)
- Inject: `{FINDINGS_JSON}` = pending items JSON, `{ROUND}` = N, `{PREVIOUS_ROUNDS_OR_NONE}` = prior round summaries

Dispatch Claude subagent with this prompt.
Output: `$SCAN_DIR/phase-1/claude-round-$N-raw.md`

Parse + validate JSON → `$SCAN_DIR/phase-1/round-$N-claude-scores.json`:
```bash
python3 -c "
import json, sys, re
raw = open('$SCAN_DIR/phase-1/claude-round-$N-raw.md').read()
m = re.search(r'\{.*\}', raw, re.DOTALL)
if not m: sys.exit(1)
data = json.loads(m.group(0))
json.dump(data, open('$SCAN_DIR/phase-1/round-$N-claude-scores.json','w'), indent=2)
" || echo "WARNING: Claude round $N output unparseable — using empty scores"
```

**Gemini scores pending items** via `prompts/gemini-consensus-round.md`:
```bash
cd "$SCAN_DIR/clone"
gemini -p "$(cat $SCAN_DIR/phase-1/prompt-round-$N.md)" \
  --yolo -m gemini-2.5-pro -o text \
  2>"$SCAN_DIR/phase-1/gemini-round-$N-stderr.txt" \
  | tee "$SCAN_DIR/phase-1/gemini-round-$N-raw.md"
cd -
```

**Grok scores pending items** via `prompts/grok-consensus-round.md`:
```bash
source ~/.zshrc 2>/dev/null
bash scripts/grok-invoke.sh grok-4-0709 \
  "$(cat $SCAN_DIR/phase-1/grok-prompt-round-$N.md)" \
  > "$SCAN_DIR/phase-1/grok-round-$N-raw.md" \
  2>"$SCAN_DIR/phase-1/grok-round-$N-stderr.txt"
```

**Check consensus thresholds:**
```
All 3 ≥9/10                     → approved, confidence: HIGH, value_reason: "all_high"
2 of 3 ≥9 + third ≥7           → approved, confidence: MEDIUM, coe_review_required: true, value_reason: "majority_high"
Any agent <7, or no progress    → stays in loop
After round 5 with no consensus → consensus: false, value_reason: "no_consensus", all positions preserved in disagreement{}
```

Save per-round: `$SCAN_DIR/phase-1/round-$N-scores.json`

**MEDIUM cap:** After loop completes, if MEDIUM count > 10:
- Sort MEDIUM items by ROI (value/effort)
- Top 10 → remain MEDIUM
- Remaining → downgrade to LOW with `downgraded_reason: "MEDIUM overflow — scan had N MEDIUM items, capped at 10"`
- Log to `$SCAN_DIR/phase-1/medium-overflow.json`

### Step 3.3: Component Assessment

For each approved opportunity (HIGH + MEDIUM), independently assess:
- Adoption State (Active/Partial/Absent)
- Readiness per KB criteria
- Risk Surface

Each agent uses its component assessment prompt:
- Claude subagent: via Agent tool with `prompts/gemini-component-assessment.md` (adapted)
- Gemini: via `prompts/gemini-component-assessment.md`
- Grok: via `prompts/grok-component-assessment.md`

Same consensus loop (max 5 rounds, same thresholds).

Save final: `$SCAN_DIR/phase-1/consensus.json` (all approved + consensus:false items)
Update consensus-state.json: `{"phase": 1, "status": "complete"}`

## Phase 4 — Consensus: Recommendations

### Step 4.1: Independent recommendation generation

**Claude subagent:** generate recommendations from approved map + component assessment.
**Gemini:** via `prompts/gemini-phase2-recommendations.md`.
**Grok:** via `prompts/grok-phase2-recommendations.md`.

RULE: No agent receives another's recommendations before producing its own.

### Step 4.2: Intersection-first + consensus loop

Same mechanism as Phase 3. Match criteria: same `opportunity_id` + same `type`.

### Step 4.3: ROI ordering consensus

All 3 independently propose ROI ranking. Where all agree → final. Where rankings diverge → consensus loop (max 5 rounds). Each agent argues with ROI evidence (impact × 1/effort × adoption gap).

Save: `$SCAN_DIR/phase-2/consensus.json`
Update consensus-state.json: `{"phase": 2, "status": "complete"}`

**Freeze assessment.json** at this point. File is immutable after freezing.

## Phase 5 — Report Generation

Dispatch Claude subagent (fresh context, reads assessment.json only):

**Input:** `$SCAN_DIR/phase-2/consensus.json` (frozen) + previous scan if exists.

**Delta computation (if previous scan exists):**
```bash
PREV=$(ls -d scans/ai-augmentation/results/*/$OWNER--$REPO 2>/dev/null | sort -r | head -1)
```
Compare: opportunity IDs (new/discontinued/persisted), readiness changes, recommendation status.

**Write report.md** following scoring-model.md Section 6:
1. Executive Summary — includes:
   ```
   **Agents:** Claude + Gemini + Grok (tri-agent-v1)
   **Consensus:** {N} HIGH, {M} MEDIUM (CoE review required), {K} unresolved
   ```
   If PARTIAL: add ⚠ WARNING banner prominently before summary.
2. Opportunity Map (ROI ordered)
3. Risk Surface
4. Recommendations
5. Adoption State
6. Readiness per Use Case
7. Evolution (if previous scan)
8. Evidence Log
9. MEDIUM Overflow Summary (if medium_overflow_count > 0)

**Write detailed-log.md** with full audit trail:
- File requests per agent (from audit/file-requests.json)
- All consensus rounds (from phase-1/ and phase-2/ round files)
- Grok batch log
- Any PARTIAL events

**Write assessment.json** following `schema/assessment-v7.schema.json`.

## Phase 6 — Save + KB Proposals

```bash
DATE=$(date +%Y-%m-%d)
RESULT_DIR="scans/ai-augmentation/results/$DATE/$OWNER--$REPO"
mkdir -p "$RESULT_DIR"
cp "$SCAN_DIR/phase-2/report.md" "$RESULT_DIR/report.md"
cp "$SCAN_DIR/phase-2/assessment.json" "$RESULT_DIR/assessment.json"
cp "$SCAN_DIR/phase-2/detailed-log.md" "$RESULT_DIR/detailed-log.md"
```

If new KB patterns discovered during scan:
- Write proposed entries to `scans/ai-augmentation/results/$DATE/kb-updates.md`
- CoE reviews before merging to `knowledge-base/`

## Failure Handling Reference

| Failure | Detection | Action |
|---|---|---|
| Gemini/Grok unavailable at start | Health check fails | STOP. Announce. Ask operator. |
| Gemini rate-limited mid-scan | 429/timeout ×5 | Continue without Gemini, flag PARTIAL |
| Grok rate-limited mid-scan | 429/timeout ×5 | Continue without Grok, flag PARTIAL |
| Agent output unparseable | JSON parse fails | Retry once with format reminder. If fails → PARTIAL. |
| Clone fails | git non-zero | STOP. Check token scope. |
| Grok context limit | 5 batches exhausted | Continue with what was analyzed, flag PARTIAL |
| 0 approved items | Consensus → empty | Valid outcome. Report data + rejection log. |
| consensus:false items | After round 5 | Include in report with full disagreement log. CoE decides. |

## Important

- **AAMM is read-only on target repos** — never create PRs, commits, issues on scanned repos
- **Never print $GITHUB_TOKEN or $XAI_API_KEY**
- **Tri-agent is standard** — health check failure at start = STOP; mid-scan failure = PARTIAL
- **No confirmations during scans** — run fully autonomously end-to-end
- **Scan-from-zero** — never read previous results before Phase 5 is frozen

## Learning Scan Flow (`--mode=learning`)

Phase 0: identical to scoring scan (health checks + clone + manifest).
Phase 1: identical to scoring scan (file requests + serving).
         No file quota per agent — agents request everything they consider relevant.
         Hard cap: max 1000 files per agent (B2 fix). If an agent requests more than 1000 files,
         orchestrator rejects the excess and logs: "Request too broad ($N files) — serving top 1000 by commit churn."
         File requests are bounded by the manifest's file_tree size; agents cannot request more files than exist.

### Learning Phase 2 — Independent Deep Scan

Each agent receives its files and scans all active SDLC sections:
- Match KB patterns
- Log ALL absence signals explicitly with quantification
- Look for patterns not in KB (novel patterns)
- Log confidence (HIGH/MEDIUM/LOW) per signal

Claude subagent → `$SCAN_DIR/learning/findings-claude.json`
Gemini → `$SCAN_DIR/learning/findings-gemini.json`
Grok → `$SCAN_DIR/learning/findings-grok.json`

```bash
mkdir -p "$SCAN_DIR/learning"
```

### Learning Phase 3 — Union with Evidence Filter

Orchestrator builds union of all findings:

```
For each finding in union:
  found_by 3 agents + each with evidence  → HIGH
  found_by 2 agents + each with evidence  → MEDIUM
  found_by 1 agent (Claude/Gemini) + file:line or commit SHA → LOW
  found_by 1 agent (Grok) + evidence      → LOW-GROK
  Any agent + absence signal (quantified with numbers) → LOW-ABSENCE
  Any agent + absence signal (NOT quantified)           → dropped ("unquantified absence" reason)
  No evidence from any agent                            → dropped, logged to $SCAN_DIR/learning/dropped.json
```

```bash
python3 - << 'UNION_END'
import json, os

findings = {}
for agent in ['claude', 'gemini', 'grok']:
    path = f"{os.environ['SCAN_DIR']}/learning/findings-{agent}.json"
    if os.path.exists(path):
        data = json.load(open(path))
        for f in data.get('findings', []):
            # B3 fix: hash-based key to prevent key collision on similar-but-not-identical findings
            import hashlib
            raw_key = json.dumps({'description': f.get('title',''), 'evidence': f.get('evidence','')}, sort_keys=True)
            k = hashlib.md5(raw_key.encode()).hexdigest()
            if k not in findings:
                findings[k] = {'finding': f, 'agents': [], 'evidence': []}
            findings[k]['agents'].append(agent)
            if f.get('evidence'):
                findings[k]['evidence'].append({'agent': agent, 'evidence': f['evidence']})

proposals = []
dropped = []
for k, v in findings.items():
    agents = v['agents']
    evidence = v['evidence']
    finding = v['finding']
    n_with_evidence = len(evidence)

    if len(agents) == 3 and n_with_evidence == 3:
        confidence = 'HIGH'
    elif len(agents) >= 2 and n_with_evidence >= 2:
        confidence = 'MEDIUM'
    elif len(agents) == 1 and n_with_evidence >= 1:
        agent = agents[0]
        if finding.get('absence_signal'):
            # B1 fix: require quantification for absence signals (e.g., "0/5 CI workflows use AI")
            evidence_text = finding.get('evidence', '')
            has_quantification = any(c.isdigit() for c in evidence_text)
            if not has_quantification:
                dropped.append({'key': k, 'reason': 'unquantified absence — must include counts', 'finding': finding})
                continue
            confidence = 'LOW-ABSENCE'
        elif agent == 'grok':
            confidence = 'LOW-GROK'
        else:
            confidence = 'LOW'
    else:
        dropped.append({'key': k, 'reason': 'no evidence from any agent', 'finding': finding})
        continue

    proposals.append({
        'pattern_type': finding.get('pattern_type', 'opportunity'),
        'confidence': confidence,
        'found_by': agents,
        'description': finding.get('title', k),
        'evidence': '; '.join(e['evidence'] for e in evidence),
        'ecosystem': os.environ['ECOSYSTEM'],
        'proposed_addition_to': f"knowledge-base/ecosystems/{os.environ['ECOSYSTEM']}.md"
    })

scan_dir = os.environ['SCAN_DIR']
json.dump({'proposals': proposals}, open(f'{scan_dir}/learning/kb-proposals.json', 'w'), indent=2)
json.dump(dropped, open(f'{scan_dir}/learning/dropped.json', 'w'), indent=2)
print(f'Union: {len(proposals)} proposals, {len(dropped)} dropped')
UNION_END
```

### Learning Phase 4 — Hallucination Filter

Each agent reviews proposals found by others.
**ONLY valid response:** "I found counter-evidence that disproves this: {file:line}"
**No scoring. No disagreement logging.**
If no counter-evidence → proposal stands.

```
For each proposal in kb-proposals.json:
  Ask each agent (excluding those who originally found it): "Do you have counter-evidence
  that disproves this finding? If yes: cite file:line. If no: reply 'no counter-evidence'."

  If any agent provides counter-evidence with file:line → mark proposal as 'contested'
  If no agent provides counter-evidence → proposal stands, status: 'confirmed'
```

### Learning Output

Write `$SCAN_DIR/learning/kb-proposals.json` (already written in Phase 3).
Copy to scan results:
```bash
DATE=$(date +%Y-%m-%d)
RESULT_DIR="scans/ai-augmentation/results/$DATE/$OWNER--$REPO"
mkdir -p "$RESULT_DIR"
cp "$SCAN_DIR/learning/kb-proposals.json" "$RESULT_DIR/kb-proposals.json"
echo "Learning scan complete. $(python3 -c "import json; d=json.load(open('$RESULT_DIR/kb-proposals.json')); print(len(d['proposals']), 'proposals')")"
echo "CoE reviews all proposals before merging to knowledge-base/."
```
