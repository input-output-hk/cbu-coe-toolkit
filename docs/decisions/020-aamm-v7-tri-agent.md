# ADR-020 — AAMM v7 Tri-Agent Architecture

**Date:** 2026-04-03
**Status:** Accepted
**Supersedes:** ADR-019 (single-agent), ADR-018 (v5 architecture)

## Context

AAMM v6.1 introduced dual-agent consensus (Claude + Gemini) to eliminate single-model bias. Two issues remained:
1. Pre-selection bias: Claude collected all repo data before Gemini saw it.
2. Two agents share structural blind spots around operational survivability and scale.

## Decision

Replace dual-agent with tri-agent architecture:
- **Claude** (orchestrator + scorer): pattern matching, KB alignment
- **Gemini** (independent scorer): skeptical, methodical, citation-heavy
- **Grok** (independent scorer): survivability, scale, value for personas, absence signals

Replace GitHub API pre-collection with local clone + request/serve protocol:
each agent independently decides what files to examine from a neutral manifest.

Use tiered consensus: all 3 ≥9 → HIGH; 2 of 3 ≥9 + third ≥7 → MEDIUM (CoE review required);
otherwise → consensus:false.

Use union model for learning scans (maximize recall, CoE filters).

## Consequences

- Eliminates pre-selection bias: every agent independently decides what to read
- Eliminates two-agent blind spots: Grok's adversarial perspective catches what Claude+Gemini miss
- Increases scan complexity: 3 agents, batched serving for Grok, PARTIAL handling
- Future-proof: fourth agent enters by following same protocol, no orchestration changes
- Cost: Claude Max (zero) + Gemini Google One AI Pro (zero) + xAI API (low cost per scan)

## Rejected alternatives

- Gemini-only third pass: same blind spots, no structural diversity
- All-or-nothing ≥9: too strict, Grok's adversarial nature would produce 40-60% consensus:false
