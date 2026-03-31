# Rust Ecosystem — Opportunity Patterns + Readiness Criteria

## Unsafe code review and audit assistance

```yaml
id: rs_unsafe_audit
type: opportunity
ecosystem: rust
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Crates contain unsafe blocks
  - FFI boundaries exist (C/C++ interop)
  - Safety-critical modules (crypto, consensus, financial)

value: HIGH
value_context: "unsafe blocks require expert review — AI can flag missing safety invariant documentation and identify potentially unsound patterns"
effort: Low
evidence_to_look_for:
  - "unsafe" keyword in source files (grep for unsafe { or unsafe fn)
  - FFI modules (extern "C" blocks)
  - Safety comments absent on unsafe blocks (// SAFETY: convention)
seen_in: []

learning_entry: |
  For each unsafe block without a // SAFETY: comment:
  1. Give Claude the unsafe block + surrounding context (function, module)
  2. Ask: "What safety invariants must hold for this to be sound?"
  3. Ask: "Is there a safe alternative using standard library APIs?"
  Review the safety analysis — AI identifies invariants well but may miss
  subtle aliasing or lifetime issues. Always validate with Miri if possible.

readiness_criteria:
  - criterion: "Clippy configured including unsafe lints"
    type: Objective
    check: "clippy::pedantic or clippy::restriction in clippy.toml/Cargo.toml, or clippy in CI"
  - criterion: "Miri or similar UB detection in CI"
    type: Objective
    check: "cargo miri test or equivalent in CI workflow"
  - criterion: "Safety comments convention established"
    type: Semi-objective
    check: "At least 3 unsafe blocks in codebase have // SAFETY: comments"
```

## Test generation for complex trait implementations

```yaml
id: rs_trait_test_gen
type: opportunity
ecosystem: rust
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Custom trait implementations with complex invariants
  - Multiple types implementing the same trait (correctness consistency)
  - Trait implementations without corresponding test coverage

value: MEDIUM
value_context: "Trait impl correctness is hard to verify exhaustively across all implementing types; AI can generate property-based tests for trait contracts"
effort: Medium
evidence_to_look_for:
  - impl blocks for custom traits across multiple types
  - Trait definitions with documented invariants (e.g., "must be commutative")
  - proptest or quickcheck in dev-dependencies
  - Trait impls without corresponding test coverage
seen_in: []

learning_entry: |
  Pick a trait with multiple implementations. Give Claude:
  1. The trait definition with any documented contracts
  2. 2-3 impl blocks for different types
  Ask: "What invariants should hold across all implementations?"
  Then: "Generate proptest strategies that verify these invariants for each impl."
  Review: are the invariants correct? Do the strategies produce meaningful inputs?

readiness_criteria:
  - criterion: "Property-based testing framework available"
    type: Objective
    check: "proptest or quickcheck in Cargo.toml dev-dependencies"
  - criterion: "Trait definitions exist with documented contracts"
    type: Semi-objective
    check: "Trait definitions have doc comments describing invariants (/// or //!)"
  - criterion: "CI runs tests including property tests"
    type: Objective
    check: "cargo test in CI workflow without --lib-only (runs all test targets)"
```

## Documentation for complex module interfaces

```yaml
id: rs_rustdoc_generation
type: opportunity
ecosystem: rust
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Public API crates with underdocumented interfaces
  - Complex generic signatures or lifetime annotations
  - Crate used by other crates in the workspace (high fan-in)

value: MEDIUM
value_context: "Rust doc comments become the crate's API docs — AI can draft accurate docs from type signatures and usage in dependent crates"
effort: Low
evidence_to_look_for:
  - lib.rs or public modules without /// doc comments on pub items
  - Complex signatures (multiple lifetimes, generic bounds, associated types)
  - Crates listed as dependencies by ≥3 other workspace crates
seen_in: []

learning_entry: |
  Pick a public module with complex types and sparse docs. Give Claude:
  1. The module's public API (pub fn, pub struct, pub trait)
  2. One or two call sites from dependent crates
  Ask it to draft /// doc comments with: description, # Arguments,
  # Returns, # Errors, # Examples (using actual types from the codebase).
  Review for accuracy, especially lifetime and ownership descriptions.

readiness_criteria:
  - criterion: "rustdoc builds without warnings"
    type: Objective
    check: "cargo doc --no-deps succeeds, or rustdoc in CI"
  - criterion: "Crate-level documentation exists"
    type: Semi-objective
    check: "lib.rs has //! module-level doc comment with substantive content"
```

## Debugging concurrency and async issues

```yaml
id: rs_debug_async
type: opportunity
ecosystem: rust
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Async runtime in use (tokio, async-std)
  - Multiple concurrent tasks with shared state
  - History of deadlock, race condition, or timeout bugs

value: HIGH
value_context: "Async Rust bugs (deadlocks, cancellation safety, task starvation) are notoriously hard to debug; AI can trace task interactions and identify contention points"
effort: Low
evidence_to_look_for:
  - tokio or async-std in dependencies
  - Arc<Mutex<_>> or RwLock patterns in source
  - Channels (mpsc, broadcast, watch) across modules
  - Bug-fix commits mentioning "deadlock", "timeout", "race"
seen_in: []

learning_entry: |
  When debugging an async issue:
  1. Give Claude the task spawning code + the shared state definitions
  2. Describe the symptom ("task hangs after X", "intermittent timeout")
  3. Ask: "Trace the lock acquisition order across tasks. Is there a deadlock potential?"
  4. Ask: "Is this cancellation-safe? What happens if the task is dropped mid-await?"
  AI traces async flows mechanically — validate with tokio-console or tracing output.

readiness_criteria:
  - criterion: "Async runtime is explicit (not hidden behind framework)"
    type: Objective
    check: "tokio or async-std in Cargo.toml dependencies"
  - criterion: "Tracing or logging configured for async tasks"
    type: Objective
    check: "tracing crate in dependencies, or log/env_logger configured"
```

## Dependency advisory scanning gaps

```yaml
id: rs_cargo_deny_audit
type: opportunity
ecosystem: rust
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - cargo-deny or cargo-audit configured
  - Advisory scanning may be misconfigured (licenses-only, not advisories)
  - Dependencies with known advisories not yet addressed

value: MEDIUM
value_context: "Misconfigured cargo-deny gives false sense of security — AI can audit the deny.toml configuration and flag gaps"
effort: Low
evidence_to_look_for:
  - deny.toml exists
  - "cargo deny check licenses" in CI WITHOUT "cargo deny check advisories"
  - Stale deny.toml (not updated in >6 months)
seen_in:
  - repo: input-output-hk/mithril
    outcome: "cargo deny check licenses found but cargo deny check advisories was the actual security check"

learning_entry: |
  Review deny.toml with Claude:
  1. Is `check advisories` running (not just `check licenses`)?
  2. Are there allow-listed advisories that should be revisited?
  3. Is the deny.toml configuration aligned with the project's security requirements?

readiness_criteria:
  - criterion: "cargo-deny configured"
    type: Objective
    check: "deny.toml exists at repo root or in .cargo/"
  - criterion: "Advisory check runs in CI"
    type: Objective
    check: "CI workflow contains 'cargo deny check advisories' or 'cargo deny check' (which includes advisories)"
```

---

## Detection Notes (from v5 scans)

- **Inline test modules:** Rust `#[cfg(test)]` modules are invisible to file-count detection. Agent must sample source files for `#[cfg(test)]` blocks.
- **clippy + rustfmt:** Standard Rust tooling. Detection in CI, Makefile, or cargo config.
- **Cargo workspace:** `[workspace]` in root `Cargo.toml` with `members` list indicates multi-crate boundaries.
