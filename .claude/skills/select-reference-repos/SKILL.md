---
name: select-reference-repos
description: Tri-agent consensus selection of external reference repos for AAMM KB enrichment. Each agent independently researches best-practice repos per ecosystem, then reaches consensus (all 3 ≥9/10 HIGH tier only).
---

# Select Reference Repos

## Purpose

Populate `models/config.yaml reference_repos` section with external repos that represent
AI readiness best practices per ecosystem. These become the benchmark for KB enrichment via learning scans.

Each entry: `scope: learning` only — never scored, never reported to teams.

## Ecosystems to cover

haskell | rust | typescript | python

## Phase 0: Health Checks

```bash
source ~/.zshrc 2>/dev/null || source ~/.bashrc 2>/dev/null

GEMINI_OK=$(gemini -p "Reply with exactly: AAMM_READY" --yolo -m gemini-2.5-pro -o text \
  2>/dev/null | grep -c "AAMM_READY")
GROK_OK=$(bash scripts/grok-invoke.sh grok-4-0709 "Reply with exactly: AAMM_READY" \
  2>/dev/null | grep -c "AAMM_READY")

if [ "$GEMINI_OK" != "1" ] || [ "$GROK_OK" != "1" ]; then
  echo "FATAL: Health checks failed. Cannot proceed."
  # STOP
fi

SCAN_DIR=/tmp/aamm-v7-select-reference-repos
mkdir -p "$SCAN_DIR"
```

## Phase 1: Independent Research

Each agent independently proposes 3-5 repos per ecosystem.

**Evaluation criteria (apply independently):**
- AI tooling config present (AGENTS.md, CLAUDE.md, .cursorrules, .mcp.json, copilot instructions, etc.)
- AI attribution in recent commit history (Co-authored-by AI tools in git log)
- CI/CD with AI-assisted steps (e.g., GitHub Actions using AI for review, test gen, or summarization)
- Complexity comparable to CBU internal repos (not toy projects — real production codebases)
- Active maintenance (commits in last 6 months)
- Recognized for engineering practices (not just popularity/stars)
- SDLC coverage: AI adoption signals across planning, dev, review, testing, security, delivery

**Claude subagent** → `$SCAN_DIR/reference-repos-claude.json`

Claude is the orchestrator — dispatch a subagent with explicit instructions:
```
Dispatch Claude subagent with task:
  "Research 3-5 best-practice repos per ecosystem (haskell, rust, typescript, python) for AI adoption benchmarking.
   Use GitHub API with $GITHUB_TOKEN to search for repos with: AGENTS.md or CLAUDE.md at root, AI attribution
   in commits, AI in CI/CD. Criteria: active (6 months), complex (not toy), good practices.
   Example search: curl -H 'Authorization: Bearer $GITHUB_TOKEN'
   'https://api.github.com/search/code?q=filename:AGENTS.md+language:Haskell&per_page=20'
   Output JSON: {\"proposals\": [{\"repo\": \"owner/name\", \"ecosystem\": \"haskell\", \"rationale\": \"...\", \"signals\": [...]}]}"
Output: $SCAN_DIR/reference-repos-claude.json
```

**Gemini** → research via `--yolo` web search + GitHub API → `$SCAN_DIR/reference-repos-gemini.json`

Prompt Gemini:
```bash
PROMPT="You are selecting external reference repos for AI adoption benchmarking.
Find 3-5 best-practice repos per ecosystem: haskell, rust, typescript, python.
Criteria: AI tooling config present, active (last 6 months), complex (not toy), good engineering practices, SDLC AI signals.
Search GitHub and the web. Output JSON only:
{\"proposals\": [{\"repo\": \"owner/name\", \"ecosystem\": \"typescript\", \"rationale\": \"one line\", \"signals\": [\"CLAUDE.md at root\", \"AI in CI\"]}]}"

cd "$SCAN_DIR"
gemini -p "$PROMPT" --yolo -m gemini-2.5-pro -o text > reference-repos-gemini-raw.md 2>/dev/null
```

**Grok** → research → `$SCAN_DIR/reference-repos-grok.json`

```bash
source ~/.zshrc 2>/dev/null
GROK_PROMPT="You are selecting external reference repos for AI adoption benchmarking.
Find 3-5 best-practice repos per ecosystem: haskell, rust, typescript, python.
Criteria: AI tooling present, active codebase, complexity similar to production systems, good engineering.
Focus on repos that would survive a 3 AM production incident — look for AI governance, safety, observability.
Output JSON only: {\"proposals\": [{\"repo\": \"owner/name\", \"ecosystem\": \"typescript\", \"rationale\": \"one line\", \"signals\": [\"CLAUDE.md\", \"AI review in CI\"]}]}"

bash scripts/grok-invoke.sh grok-4-0709 "$GROK_PROMPT" > "$SCAN_DIR/reference-repos-grok-raw.md" 2>/dev/null
```

Parse outputs to JSON files using same pattern as Phase 1 of scan-aamm-v7.

Each output format:
```json
{"proposals": [{"repo": "owner/name", "ecosystem": "typescript", "rationale": "...", "signals": [...]}]}
```

## Phase 2: Intersection + Consensus

Same mechanism as scoring scan Phase 3. **HIGH tier only** (all 3 agents ≥9/10).
MEDIUM (2/3 ≥9) is NOT sufficient for reference repo selection — consistency of evidence matters.

Consensus loop: max 3 rounds (shorter — we're selecting repos, not scoring opportunities).

```
For each proposed repo:
  All 3 agents verify independently: does this repo actually have AI adoption signals?
  Each agent scores 1-10:
    - 9-10: Strong AI adoption signals, active, complex, good practices
    - 7-8: Good signals but one concern (recency, complexity, or completeness)
    - 1-6: Missing key criteria

  All 3 ≥9 → approved (HIGH)
  Anything else → rejected (log reason)
```

## Phase 3: Output

```bash
# B1 fix: append-only approach — avoids yaml.dump overwriting comments and key ordering.
# Instead of reload+redump, we replace only the reference_repos: [] line.
python3 - << 'OUTPUT_END'
import json, os
from datetime import date

approved = json.load(open(f"{os.environ['SCAN_DIR']}/reference-repos-approved.json"))

# Build YAML block for reference_repos entries
lines = []
for repo in approved:
    lines.append(f"  - repo: {repo['repo']}")
    lines.append(f"    language: {repo['ecosystem']}")
    lines.append(f"    scope: learning")
    lines.append(f"    rationale: \"{repo['rationale']}\"")
    lines.append(f"    selected_by: tri-agent-consensus")
    lines.append(f"    selected_date: {date.today()}")

new_block = "reference_repos:\n" + "\n".join(lines) + "\n"

# Replace the empty reference_repos: [] line in place, preserving all comments
with open('models/config.yaml', 'r') as f:
    content = f.read()

if 'reference_repos: []' not in content:
    print("ERROR: Could not find 'reference_repos: []' in config.yaml — update manually.")
    exit(1)

content = content.replace('reference_repos: []', new_block.rstrip())

with open('models/config.yaml', 'w') as f:
    f.write(content)

print(f"Added {len(approved)} reference repos to config.yaml (append-only, comments preserved)")
OUTPUT_END
```

**Require operator approval before committing to main:**
```bash
git diff models/config.yaml
read -p "Review the diff above. Approve and commit? (y/n) " APPROVE
if [ "$APPROVE" != "y" ]; then
  echo "Aborted — config.yaml not committed."
  git checkout -- models/config.yaml
  exit 1
fi
git add models/config.yaml
git commit -m "feat: add tri-agent selected reference repos to config.yaml"
echo "Committed. Run /scan-aamm-v7 --mode=learning on new reference repos to enrich KB."
```

## Important

- Never start learning scans on reference repos without operator knowledge
- Reference repos are benchmarks only — their results never appear in team reports
- Selection requires all 3 agents at HIGH tier — no exceptions
