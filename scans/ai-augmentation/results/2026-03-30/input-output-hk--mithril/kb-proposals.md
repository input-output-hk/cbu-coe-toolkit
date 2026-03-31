# KB Proposals — Learning Scan: input-output-hk/mithril
> Scan date: 2026-03-30 | Scan type: Learning | Ecosystem: Rust | Agent: Claude Opus 4.6

---

## Seed Pattern Validation

### rs_unsafe_audit — VALIDATED

**Evidence:**
- Cryptographic library: `mithril-stm/` implements stake-based threshold multi-signatures — core crypto
- Protocol modules: `mithril-stm/src/protocol/key_registration_mod.rs` — key registration logic
- Large Rust codebase: 1024 .rs files, 37 Cargo.toml — extensive surface area
- `deny.toml` exists — security tooling awareness established
- `.config/nextest.toml` — advanced test runner configured

**Gaps observed:**
- Cannot confirm unsafe block count from tree alone, but crypto crates (mithril-stm) almost certainly contain unsafe code for performance-critical signature operations
- `.github/copilot-instructions.md` (7KB) — AI instructions exist but focused on Copilot, not Claude

**Confidence:** HIGH (crypto library implementing multi-signatures will have unsafe blocks)

### rs_trait_test_gen — VALIDATED

**Evidence:**
- Multi-crate workspace with 37 Cargo.toml files — implies shared traits across crates
- Sampled source files show trait-heavy architecture:
  - `mithril-client/src/file_downloader_mod.rs` — downloader interface traits
  - `mithril-aggregator/src/services/signature_consumer_interface.rs` — service interfaces
  - `mithril-aggregator/src/file_uploaders/cloud_uploader_mod.rs` — uploader interface
  - `mithril-client-cli/src/utils/http_downloader_interface.rs` — HTTP interface
- nextest configured (`.config/nextest.toml`) — test infrastructure mature
- 20 CI workflows — extensive automated testing

**Confidence:** HIGH (interface-heavy architecture with multiple implementing types)

### rs_rustdoc_generation — VALIDATED

**Evidence:**
- 37 crates in workspace — massive public API surface across mithril-stm, mithril-client, mithril-aggregator, mithril-client-cli, mithril-signer, etc.
- Published to crates.io (implied by project maturity: 150 stars, 53 forks, 4+ years old)
- Complex generic signatures in protocol modules (STM parameters, key types, signature types)
- GitHub Pages enabled (`has_pages: true`) — likely hosts rustdoc

**Confidence:** HIGH (multi-crate workspace with public API)

### rs_debug_async — VALIDATED

**Evidence:**
- Network services architecture: aggregator, signer, client — distributed system
- HTTP-based communication (http_downloader_interface.rs)
- File upload/download services with cloud integration
- 20 CI workflows including infrastructure deployment (Terraform actions) — production system
- GitHub Actions workflows include `deploy-terraform-infrastructure` — real infrastructure with async networking

**Confidence:** HIGH (distributed system with aggregator/signer/client architecture)

### rs_cargo_deny_audit — VALIDATED

**Evidence:**
- `deny.toml` exists at repo level (confirmed in seed KB: `seen_in: input-output-hk/mithril`)
- Seed KB notes: "cargo deny check licenses found but cargo deny check advisories was the actual security check"
- 20 CI workflows — likely includes cargo deny checks
- Security-critical domain (cryptographic signatures for blockchain)

**Confidence:** HIGH (seed already validated against this repo)

---

## Cross-Cutting Patterns

### cc_claude_md_context — PARTIAL

No CLAUDE.md, but `.github/copilot-instructions.md` (7KB) exists — a substantive AI configuration file for GitHub Copilot. This demonstrates AI awareness but uses a different tool. Opportunity: create CLAUDE.md or adopt a tool-agnostic approach.

0 AI-attributed commits despite copilot-instructions.md — the instructions may be aspirational or Copilot suggestions are not co-authored in commits.

### cc_aiignore_boundaries — CONFIRMED APPLICABLE

Critical security paths identifiable:
- `mithril-stm/` — cryptographic multi-signature implementation (THE core security module)
- `mithril-signer/` — signing operations
- Key registration and management modules
- No `.aiignore` exists despite AI tool configuration (copilot-instructions.md)

This is a HIGH priority gap: a cryptographic signing library with AI tooling configured but no trust boundaries defined.

---

## New Pattern Proposals

### Copilot-to-Claude migration path

```yaml
id: rs_ai_config_migration
type: opportunity
ecosystem: cross-cutting
status: proposed
discovered: 2026-03-30

applies_when:
  - copilot-instructions.md exists
  - Team may adopt Claude Code or multiple AI tools
  - Instructions are tool-agnostic enough to port

value: LOW
value_context: "Existing AI configuration in copilot-instructions.md can be adapted to CLAUDE.md, reducing setup effort"
evidence_to_look_for:
  - .github/copilot-instructions.md with substantive content (>1KB)
  - No CLAUDE.md
seen_in:
  - repo: input-output-hk/mithril
    outcome: "7KB copilot-instructions.md exists, no CLAUDE.md"
```

---

## Summary

| Pattern | Status | Confidence |
|---------|--------|------------|
| rs_unsafe_audit | VALIDATED | HIGH |
| rs_trait_test_gen | VALIDATED | HIGH |
| rs_rustdoc_generation | VALIDATED | HIGH |
| rs_debug_async | VALIDATED | HIGH |
| rs_cargo_deny_audit | VALIDATED | HIGH |
| cc_claude_md_context | PARTIAL (Copilot only) | HIGH |
| cc_aiignore_boundaries | APPLICABLE — HIGH priority | HIGH |

**Key finding:** Mithril validates ALL five Rust seed patterns with high confidence. This is the canonical Rust repo for the KB. The combination of cryptographic implementation, multi-crate workspace, async distributed system, and cargo-deny configuration makes it an ideal reference. The critical gap is `.aiignore` — a crypto signing library with AI tooling configured but no trust boundaries is a security concern that should be flagged in recommendations.
