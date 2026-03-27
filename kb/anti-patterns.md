# Anti-Patterns

## Empty PR template placeholders are not AI signals

```yaml
source: iog-scan
repos: [lace-platform]
category: adoption-detection
status: validated
discovered: 2026-03-26
updated: 2026-03-27
```

`<!-- CURSOR_SUMMARY --><!-- /CURSOR_SUMMARY -->` without content = template marker,
not AI activity. Only content-filled markers count.

## Generic CLAUDE.md without trust boundaries

```yaml
source: iog-scan
repos: []
category: governance
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

"Use AI responsibly" without specific critical paths or module boundaries
= no operational guardrails.

## docs/ is NOT architecture documentation

```yaml
source: iog-scan
repos: [ouroboros-consensus]
category: purpose
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

docs/ commonly contains: agda-spec, formal-spec, haddocks, website.
Do not credit docs/ existence as ARCHITECTURE.md.
