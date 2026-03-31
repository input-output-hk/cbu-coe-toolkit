# Anti-Patterns

Detection traps and false signals the scanner agent must avoid.

## Empty PR template placeholders are not AI signals

```yaml
id: ap_empty_pr_placeholders
type: anti-pattern
ecosystem: cross-cutting
status: validated
discovered: 2026-03-26
updated: 2026-03-30
```

`<!-- CURSOR_SUMMARY --><!-- /CURSOR_SUMMARY -->` without content = template marker, not AI activity. Only content-filled markers count as evidence of AI use. Empty placeholders indicate the tool is configured but not actively used.

**Agent instruction:** When checking for AI-attributed PR descriptions, verify that AI markers contain actual content. Empty markers → Absent, not Partial.

## Generic CLAUDE.md is not operational AI config

```yaml
id: ap_generic_claude_md
type: anti-pattern
ecosystem: cross-cutting
status: validated
discovered: 2026-03-27
updated: 2026-03-30
```

"Use AI responsibly" or "This project uses Claude" without specific module boundaries, critical paths, or coding conventions = no operational value. The file exists but provides zero guidance to an AI agent.

**Agent instruction:** When assessing CLAUDE.md for the `cc_claude_md_context` opportunity, check for substantive content (architecture, conventions, security paths), not just file existence. A generic CLAUDE.md scores the same as no CLAUDE.md for Adoption State purposes.

## docs/ is NOT architecture documentation

```yaml
id: ap_docs_not_architecture
type: anti-pattern
ecosystem: cross-cutting
status: validated
discovered: 2026-03-27
updated: 2026-03-30
```

docs/ commonly contains: agda-spec, formal-spec, haddocks, website content, API reference. None of these are architecture documentation. ARCHITECTURE.md or an explicit architecture section in README describes system structure, module boundaries, and design decisions.

**Agent instruction:** Do not credit docs/ directory existence as "architecture documented." Look specifically for ARCHITECTURE.md, explicit architecture sections in README, or ADRs that describe structural decisions.

## AI attribution absence ≠ no AI usage

```yaml
id: ap_attribution_absence
type: anti-pattern
ecosystem: cross-cutting
status: validated
discovered: 2026-03-28
updated: 2026-03-30
```

Many teams use AI tools without Co-authored-by attribution. Absence of attribution means "we cannot observe AI usage from repo data," not "AI is not being used." This is an industry-wide limitation — most AI tools do not enforce attribution.

**Agent instruction:** When recording Adoption State = Absent, always state: "No observable AI attribution found. This does not confirm absence of AI use — attribution is not universally enforced." Never frame Absent as a negative judgment.

## Misconfigured security scanning gives false confidence

```yaml
id: ap_misconfigured_security
type: anti-pattern
ecosystem: rust
status: validated
discovered: 2026-03-26
updated: 2026-03-30
```

`cargo deny check licenses` is NOT security scanning. Only `cargo deny check advisories` or bare `cargo deny check` (which includes advisories by default) counts as vulnerability scanning. Similar: dependabot configured for version updates only (not security alerts).

**Agent instruction:** When assessing security scanning in Risk Surface, verify the specific cargo-deny command or dependabot configuration. License checking ≠ advisory checking.

## High readiness ≠ AI readiness (v5 lesson)

```yaml
id: ap_readiness_not_ai_readiness
type: anti-pattern
ecosystem: cross-cutting
status: validated
discovered: 2026-03-28
updated: 2026-03-30
```

A well-engineered repo (good CI, tests, documentation, linting) is easier for AI to work with — but "well-engineered" and "AI-ready" are correlated, not identical. v5 made this mistake: it measured engineering quality and called the result "AI readiness."

**Agent instruction:** Readiness in v6 is assessed per use case from KB criteria, NOT from general engineering quality signals. Good CI, tests, and docs are prerequisites for specific opportunities (which the KB criteria capture), not a global readiness score.
