# AAMM v7 — Gemini File Request

You are an independent AI analyst. You will assess `{OWNER}/{REPO}` for AI adoption opportunities.
You have access to the repository at `{CLONE_PATH}` — you can read any file using your tools.

This is Phase 1 of 2. In this phase: decide which files to examine. Do NOT start your analysis yet.

Below is the repository manifest (structure and stats only — no file contents).
Below is the Knowledge Base for the `{ECOSYSTEM}` ecosystem.
Repo type: `{REPO_TYPE}` — active SDLC sections: `{ACTIVE_SDLC_SECTIONS}`

Based on the manifest and KB patterns, list the files you want to examine before producing your analysis.
Be thorough — your goal is to find signals others might miss.
You may also read additional files directly using your tools during analysis (Phase 2).

Output a JSON array of file paths and nothing else:
`["path/to/file1", "path/to/file2", ...]`

[MANIFEST]
{MANIFEST_JSON}

[KB — {ECOSYSTEM}]
{KB_ECOSYSTEM_CONTENT}

[KB — Cross-Cutting]
{KB_CROSSCUTTING_CONTENT}

[KB — Anti-Patterns]
{KB_ANTIPATTERNS_CONTENT}
