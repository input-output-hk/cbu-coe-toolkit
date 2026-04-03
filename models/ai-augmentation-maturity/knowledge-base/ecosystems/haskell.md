# Haskell Ecosystem — Opportunity Patterns + Readiness Criteria

## Corner case discovery in property-based tests

```yaml
id: hs_quickcheck_corner_cases
type: opportunity
ecosystem: haskell
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - QuickCheck or Hedgehog used for property-based testing
  - Arbitrary instances exist per domain type
  - High-churn modules with complex invariants

value: HIGH
value_context: "Property-test-heavy repos benefit most — AI can identify invariants humans miss, especially in cross-era state transitions"
effort: Low
evidence_to_look_for:
  - testlib/*/Arbitrary.hs or Gen*.hs files
  - Absence of shrinking implementations in existing generators
  - New modules added without corresponding generators
  - Formal spec modules with invariants not reflected in tests
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "identified gap in dijkstra era generators (2026-03-28 scan)"

learning_entry: |
  Start with one Arbitrary instance for a core data type. Ask Claude to:
  1. Read the formal spec for that type's invariants
  2. Identify which invariants the current generator doesn't cover
  3. Propose additional property tests targeting those gaps
  Review output against the formal spec before committing.
  Key: AI finds gaps in coverage, human validates against spec.

readiness_criteria:
  - criterion: "Arbitrary instances exist per domain type"
    type: Objective
    check: "testlib/ or test/ directories contain Arbitrary.hs or Gen*.hs files matching source modules"
  - criterion: "Shrinking implemented in generators"
    type: Objective
    check: "Arbitrary instances define shrink or derive via Generics"
  - criterion: "Formal spec exists for core invariants"
    type: Objective
    check: "formal-spec/ or spec/ directory exists with property definitions"
  - criterion: "CI runs property tests"
    type: Objective
    check: "CI workflow invokes cabal test or nix flake check covering test suites"

kb_version: "6.2"

adoption_signals:
  active:
    - description: "AI-attributed commits in test/generator paths"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching testlib/*/Arbitrary.hs or testlib/*/Gen*.hs"
      threshold: "count >= 3 in last 90 days"
    - description: "AI config references property testing workflow"
      method: content_analysis
      pattern: "CLAUDE.md or .claude/docs/ mentions QuickCheck, property testing, or generator authoring with >50 words on topic"
      threshold: "exists: true"
      verification_hint: "Generic mention of testing is not enough — must reference property testing specifically"
    - description: "AI-generated property test PRs"
      method: pr_analysis
      pattern: "PRs with AI co-authorship or bot labels touching test/ or testlib/ with Arbitrary or property test content"
      threshold: "count >= 2 in last 90 days"
  partial:
    - description: "1-2 AI commits touching test generators"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching testlib/ or test/"
      threshold: "count >= 1 AND count < 3 in last 90 days"
    - description: "AI config exists but doesn't reference testing"
      method: file_search
      pattern: "CLAUDE.md or .cursorrules or .mcp.json exists"
      threshold: "exists: true"
      verification_hint: "File exists but may not reference testing — Partial infrastructure"
    - description: "AI tool referenced in CI or build config"
      method: file_search
      pattern: "AI tool references in flake.nix or CI workflow files"
      threshold: "exists: true"
  absent:
    - description: "No AI config files"
      method: file_search
      pattern: "CLAUDE.md, .cursorrules, .mcp.json, copilot-instructions.md, AGENTS.md"
      threshold: "none exist"
    - description: "No AI attribution in commits"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini|AI)"
      threshold: "count == 0 in last 180 days"
    - description: "No AI bot PRs"
      method: pr_analysis
      pattern: "PR authors matching *[bot]* or known AI bots (copilot[bot], coderabbit-ai[bot])"
      threshold: "count == 0"
  anti_patterns:
    - description: "Empty CLAUDE.md or generic content"
      method: content_analysis
      pattern: "CLAUDE.md exists but <100 words or no project-specific content"
      actual_state: "Absent — generic file is not an adoption signal"
    - description: "AI tool configured but explicitly disabled"
      method: commit_scan
      pattern: "Recent commit messages containing 'disable' AND (claude OR copilot OR AI)"
      actual_state: "Partial at best — was Active, now degraded"
  confidence_threshold: 60

readiness_levels:
  undiscovered:
    description: "No property testing infrastructure"
    criteria:
      - description: "No QuickCheck/Hedgehog in dependencies"
        method: file_search
        pattern: "QuickCheck or Hedgehog in *.cabal files or cabal.project"
        threshold: "count == 0"
      - description: "No Arbitrary instances"
        method: file_search
        pattern: "Arbitrary.hs or Gen*.hs in testlib/ or test/"
        threshold: "count == 0"
  exploring:
    description: "Property testing exists but limited"
    requires: [undiscovered]
    criteria:
      - description: "Arbitrary instances exist but few"
        method: file_search
        pattern: "Arbitrary.hs or Gen*.hs files in testlib/ or test/"
        threshold: "count >= 1 AND count < 10"
      - description: "No shrinking implementations"
        method: content_analysis
        pattern: "shrink function definitions or Generic derivation in Arbitrary instances"
        threshold: "count == 0 in sampled files"
        sampling: "sample 5 Arbitrary.hs files"
      - description: "No formal spec alignment"
        method: file_search
        pattern: "formal-spec/ or spec/ directory"
        threshold: "exists: false"
    quantitative: "1-9 generator files, no shrinking, no formal spec"
  practiced:
    description: "Comprehensive property testing ready for AI augmentation"
    requires: [exploring]
    criteria:
      - description: "Extensive Arbitrary instances across modules"
        method: file_search
        pattern: "Arbitrary.hs or Gen*.hs files"
        threshold: "count >= 10"
      - description: "Shrinking implemented"
        method: content_analysis
        pattern: "shrink or Generic derivation in Arbitrary instances"
        threshold: "found in >= 50% of sampled Arbitrary files"
        sampling: "sample 5 Arbitrary.hs files"
      - description: "Formal spec exists for invariants"
        method: file_search
        pattern: "formal-spec/ or formal-ledger-specifications referenced in cabal.project"
        threshold: "exists: true"
      - description: "CI runs property tests"
        method: file_search
        pattern: "cabal test or nix flake check in CI workflow files"
        threshold: "exists: true"
    quantitative: "10+ generator files, shrinking in 50%+, formal spec, CI coverage"
    temporal_check: "Last 3 new source modules added have corresponding Arbitrary instances"
  confidence_threshold: 60
```

## Haddock documentation for underdocumented modules

```yaml
id: hs_haddock_generation
type: opportunity
ecosystem: haskell
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Haskell repo with exported public API
  - Doc comment coverage below 60% (sample 10 source files)
  - Modules with complex type signatures that benefit from explanation

value: HIGH
value_context: "Domain-specific Haddock docs are expensive to write manually; AI can draft accurate docs from type signatures + usage context"
effort: Low
evidence_to_look_for:
  - Source files without "-- |" or "{- |" doc comments on exported functions
  - Complex type signatures (3+ type parameters, GADTs, type families)
  - Modules that are imported by many other modules (high fan-in)
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "45.8% Haddock coverage across 38 packages — significant gap in era-specific modules"

learning_entry: |
  Pick one module with complex types and no Haddock. Ask Claude to:
  1. Read the module's exports and type signatures
  2. Read modules that import this one (usage context)
  3. Draft Haddock comments explaining purpose, invariants, and usage
  Review for accuracy — AI captures structure well but may miss domain subtleties.

readiness_criteria:
  - criterion: "Haddock tooling configured"
    type: Objective
    check: "cabal haddock works or haddock referenced in CI/nix"
  - criterion: "Module exports are explicit (not module re-exports of everything)"
    type: Semi-objective
    check: "Source files use explicit export lists, not 'module X (module Y)' re-exports"
  - criterion: "At least some existing Haddock as style reference"
    type: Semi-objective
    check: "At least 3 modules have substantive doc comments (not just '-- | TODO')"

kb_version: "6.2"

adoption_signals:
  active:
    - description: "AI-attributed commits in doc paths"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching src/**/*.hs where diff adds '-- |' or '{- |' doc comments"
      threshold: "count >= 3 in last 90 days"
    - description: "AI config references Haddock workflow"
      method: content_analysis
      pattern: "CLAUDE.md or .claude/docs/ mentions Haddock, documentation generation, or doc coverage with >50 words on topic"
      threshold: "exists: true"
      verification_hint: "Generic mention of docs is not enough — must reference Haddock specifically"
    - description: "AI-generated documentation PRs"
      method: pr_analysis
      pattern: "PRs with AI co-authorship adding or improving Haddock comments across multiple modules"
      threshold: "count >= 2 in last 90 days"
  partial:
    - description: "1-2 AI commits adding doc comments"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits where diff adds '-- |' or '{- |'"
      threshold: "count >= 1 AND count < 3 in last 90 days"
    - description: "AI config exists but doesn't reference documentation"
      method: file_search
      pattern: "CLAUDE.md or .cursorrules or .mcp.json exists"
      threshold: "exists: true"
      verification_hint: "File exists but may not reference Haddock — Partial infrastructure"
  absent:
    - description: "No AI config files"
      method: file_search
      pattern: "CLAUDE.md, .cursorrules, .mcp.json, copilot-instructions.md, AGENTS.md"
      threshold: "none exist"
    - description: "No AI attribution in commits"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini|AI)"
      threshold: "count == 0 in last 180 days"
    - description: "No AI bot PRs"
      method: pr_analysis
      pattern: "PR authors matching *[bot]* or known AI bots"
      threshold: "count == 0"
  anti_patterns:
    - description: "AI-generated docs with placeholder content"
      method: content_analysis
      pattern: "Haddock comments containing 'TODO', 'FIXME', or single-word descriptions on exported functions"
      actual_state: "Absent — placeholder docs are not real adoption"
    - description: "Haddock comments copied verbatim from type signature"
      method: content_analysis
      pattern: "Doc comments that merely restate the function name/type with no added context"
      actual_state: "Absent — parroting signatures adds no value"
  confidence_threshold: 60

readiness_levels:
  undiscovered:
    description: "No Haddock infrastructure or doc comments"
    criteria:
      - description: "No Haddock in build config"
        method: file_search
        pattern: "haddock in *.cabal, cabal.project, flake.nix, or CI workflow files"
        threshold: "count == 0"
      - description: "No doc comments in source"
        method: content_analysis
        pattern: "'-- |' or '{- |' in *.hs files"
        threshold: "count == 0 in sampled files"
        sampling: "sample 10 src/*.hs files"
  exploring:
    description: "Haddock configured but low coverage"
    requires: [undiscovered]
    criteria:
      - description: "Haddock configured in build"
        method: file_search
        pattern: "haddock referenced in cabal config, flake.nix, or CI"
        threshold: "exists: true"
      - description: "Module exports mostly implicit"
        method: content_analysis
        pattern: "Modules using explicit export lists (not 'module X where')"
        threshold: "< 50% of sampled modules"
        sampling: "sample 10 src/*.hs files"
      - description: "Low doc comment coverage"
        method: content_analysis
        pattern: "'-- |' or '{- |' on exported functions"
        threshold: "< 30% of exported functions in sampled modules"
        sampling: "sample 10 modules"
    quantitative: "Haddock configured, <50% explicit exports, <30% doc coverage"
  practiced:
    description: "Haddock well-established, ready for AI-assisted gap-filling"
    requires: [exploring]
    criteria:
      - description: "Explicit exports in majority of modules"
        method: content_analysis
        pattern: "Modules using explicit export lists"
        threshold: ">= 50% of sampled modules"
        sampling: "sample 10 src/*.hs files"
      - description: "Existing doc comments as style reference"
        method: content_analysis
        pattern: "Modules with substantive '-- |' comments (not just TODO)"
        threshold: "count >= 3 modules with >= 5 doc comments each"
        sampling: "sample 10 modules"
      - description: "Haddock builds in CI or nix"
        method: file_search
        pattern: "cabal haddock or haddock in CI workflow or flake.nix"
        threshold: "exists: true"
    quantitative: "50%+ explicit exports, 3+ well-documented modules, CI builds Haddock"
  confidence_threshold: 60
```

## Debug assistance for complex state transitions

```yaml
id: hs_debug_state_transitions
type: opportunity
ecosystem: haskell
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - State machine or era-transition logic present
  - Cross-module state dependencies (state flows through multiple modules)
  - History of subtle bugs in state transition code (reverts, fix commits)

value: HIGH
value_context: "State transition debugging in formal-spec-aligned code is expert-level work; AI excels at tracing state through call chains"
effort: Low
evidence_to_look_for:
  - Modules with "Rules" or "Transition" in path (e.g., Rules/Cert.hs, Rules/Gov.hs)
  - Type-level era indexing (ShelleyEra, ConwayEra type parameters)
  - Revert commits or multi-commit fixes in state transition modules
  - STS (Signal-Transition-State) framework usage
seen_in: []

learning_entry: |
  When debugging a failing property test or unexpected state:
  1. Give Claude the failing test output + the relevant STS rule module
  2. Ask it to trace the state transition step by step
  3. Ask it to identify which precondition or postcondition is violated
  AI is very good at mechanical state tracing — use it for the tedious part,
  validate the conclusion against the formal spec yourself.

readiness_criteria:
  - criterion: "State transition modules are identifiable in file tree"
    type: Objective
    check: "Directories or files named *Rules*, *Transition*, or *STS* exist"
  - criterion: "Formal spec or invariant documentation exists"
    type: Objective
    check: "formal-spec/ directory or inline spec comments in transition modules"
  - criterion: "Test coverage exists for state transitions"
    type: Objective
    check: "Test files exist that exercise transition rules (property or unit tests)"

kb_version: "6.2"

adoption_signals:
  active:
    - description: "AI-attributed commits in state transition or debug paths"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching **/Rules/*.hs or **/Transition*.hs"
      threshold: "count >= 3 in last 90 days"
    - description: "AI debug/troubleshoot skill configured"
      method: file_search
      pattern: ".claude/skills/*troubleshoot* or .claude/skills/*debug* files"
      threshold: "exists: true"
    - description: "AI-assisted debug PRs referencing state transitions"
      method: pr_analysis
      pattern: "PRs with AI co-authorship fixing bugs in Rules/ or Transition/ modules"
      threshold: "count >= 2 in last 90 days"
  partial:
    - description: "1-2 AI commits touching transition modules"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching **/Rules/*.hs or **/STS/**"
      threshold: "count >= 1 AND count < 3 in last 90 days"
    - description: "AI config exists but doesn't reference debugging workflow"
      method: file_search
      pattern: "CLAUDE.md or .cursorrules exists"
      threshold: "exists: true"
      verification_hint: "File exists but may not mention state transition debugging"
  absent:
    - description: "No AI config files"
      method: file_search
      pattern: "CLAUDE.md, .cursorrules, .mcp.json, copilot-instructions.md, AGENTS.md"
      threshold: "none exist"
    - description: "No AI attribution in commits"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini|AI)"
      threshold: "count == 0 in last 180 days"
  anti_patterns:
    - description: "AI debug suggestions that bypass formal spec validation"
      method: pr_analysis
      pattern: "AI-attributed PRs modifying Rules/*.hs without corresponding test changes"
      actual_state: "Partial at best — debug fix without test is incomplete"
    - description: "AI config references debugging but no transition modules exist"
      method: content_analysis
      pattern: "CLAUDE.md mentions state debugging but repo has no Rules/ or Transition/ modules"
      actual_state: "Absent — aspirational config with no applicable code"
  confidence_threshold: 60

readiness_levels:
  undiscovered:
    description: "No identifiable state transition modules"
    criteria:
      - description: "No Rules or Transition modules"
        method: file_search
        pattern: "**/Rules/*.hs or **/Transition*.hs or **/STS/**"
        threshold: "count == 0"
      - description: "No formal spec or invariant docs"
        method: file_search
        pattern: "formal-spec/ or spec/ directory"
        threshold: "exists: false"
  exploring:
    description: "State transition modules exist but limited test coverage"
    requires: [undiscovered]
    criteria:
      - description: "Rules modules identifiable"
        method: file_search
        pattern: "**/Rules/*.hs files"
        threshold: "count >= 1 AND count < 10"
      - description: "Formal spec or invariant comments exist"
        method: file_search
        pattern: "formal-spec/ or spec/ directory, or inline STS comments in Rules/*.hs"
        threshold: "exists: true"
      - description: "Limited test coverage for transitions"
        method: file_search
        pattern: "Test files matching **/Test/**/Rules/*.hs or **/Imp/**/*Spec.hs"
        threshold: "count < 5"
    quantitative: "1-9 Rules/*.hs modules, spec exists, <5 transition test files"
  practiced:
    description: "Rich state transition codebase ready for AI debug assistance"
    requires: [exploring]
    criteria:
      - description: "Extensive Rules modules"
        method: file_search
        pattern: "**/Rules/*.hs files"
        threshold: "count >= 10"
      - description: "Formal spec with extractable invariants"
        method: file_search
        pattern: "formal-spec/ or formal-ledger-specifications in cabal.project"
        threshold: "exists: true"
      - description: "Test coverage for transition rules"
        method: file_search
        pattern: "Test files exercising Rules/ modules"
        threshold: "count >= 5"
      - description: "Bug-fix history in transition modules"
        method: git_log_search
        pattern: "Commits with 'fix' or 'revert' touching Rules/*.hs or Transition*.hs"
        threshold: "count >= 3 in last 180 days"
    quantitative: "10+ Rules modules, formal spec, 5+ test files, bug-fix history"
  confidence_threshold: 60
```

## AI-assisted code review for cross-era changes

```yaml
id: hs_cross_era_review
type: opportunity
ecosystem: haskell
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Multi-era architecture (era-indexed types, era-specific modules)
  - PRs frequently touch multiple eras simultaneously
  - Backward compatibility constraints between eras

value: MEDIUM
value_context: "Cross-era changes require understanding interactions between era-specific implementations — AI can surface missed interactions"
effort: Low
evidence_to_look_for:
  - Directory structure with era names (shelley/, allegra/, conway/, etc.)
  - Type-level era parameters in signatures
  - PRs that modify files across multiple era directories
seen_in: []

learning_entry: |
  When reviewing a PR that touches multiple eras:
  1. Give Claude the diff + the type signatures of affected functions across eras
  2. Ask: "Which era-specific invariants could this change violate?"
  3. Ask: "Does this change maintain backward compatibility with the previous era?"
  Focus on: serialization compatibility, state migration paths, and predicate changes.

readiness_criteria:
  - criterion: "Era modules are clearly separated in file tree"
    type: Objective
    check: "Directories or package names contain era identifiers"
  - criterion: "Era compatibility tests exist"
    type: Objective
    check: "Test files that exercise cross-era serialization or migration"

kb_version: "6.2"

adoption_signals:
  active:
    - description: "AI PR reviews on multi-era PRs"
      method: pr_analysis
      pattern: "PRs with AI review comments or AI co-authorship touching files across 2+ era directories"
      threshold: "count >= 3 in last 90 days"
    - description: "AI review bot active on cross-era changes"
      method: pr_analysis
      pattern: "PR comments from AI bots (coderabbit-ai[bot], copilot[bot]) on PRs touching multiple eras"
      threshold: "count >= 2 in last 90 days"
    - description: "AI config references era review workflow"
      method: content_analysis
      pattern: "CLAUDE.md or .claude/docs/ mentions cross-era review, era compatibility, or multi-era changes"
      threshold: "exists: true"
  partial:
    - description: "1-2 AI interactions on cross-era PRs"
      method: pr_analysis
      pattern: "PRs with AI co-authorship or review touching multiple era directories"
      threshold: "count >= 1 AND count < 3 in last 90 days"
    - description: "AI config exists but doesn't reference era review"
      method: file_search
      pattern: "CLAUDE.md or .cursorrules exists"
      threshold: "exists: true"
  absent:
    - description: "No AI config files"
      method: file_search
      pattern: "CLAUDE.md, .cursorrules, .mcp.json, copilot-instructions.md, AGENTS.md"
      threshold: "none exist"
    - description: "No AI attribution in commits or PRs"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini|AI)"
      threshold: "count == 0 in last 180 days"
  anti_patterns:
    - description: "AI reviews that miss era-specific implications"
      method: pr_analysis
      pattern: "AI review comments on cross-era PRs that only address style, not compatibility"
      actual_state: "Partial at best — shallow review misses the point"
    - description: "Single-era repo claiming cross-era review"
      method: file_search
      pattern: "Only one era directory exists (e.g., only conway/, no shelley/ or allegra/)"
      actual_state: "Absent — no cross-era work to review"
  confidence_threshold: 60

readiness_levels:
  undiscovered:
    description: "No multi-era architecture"
    criteria:
      - description: "No era-specific directories or packages"
        method: file_search
        pattern: "Directories or package names containing era identifiers (shelley, allegra, mary, alonzo, babbage, conway, dijkstra)"
        threshold: "count <= 1"
      - description: "No translation tests"
        method: file_search
        pattern: "**/Translation*.hs or **/TranslationSpec*.hs"
        threshold: "count == 0"
  exploring:
    description: "Multi-era structure exists but limited cross-era testing"
    requires: [undiscovered]
    criteria:
      - description: "Multiple era directories exist"
        method: file_search
        pattern: "Directories containing era identifiers"
        threshold: "count >= 2 AND count < 5"
      - description: "Few translation tests"
        method: file_search
        pattern: "**/Translation*.hs or **/TranslationSpec*.hs"
        threshold: "count >= 1 AND count < 5"
      - description: "Cross-era PRs exist but are rare"
        method: pr_analysis
        pattern: "PRs touching files in 2+ era directories"
        threshold: "count >= 1 AND count < 10 in last 180 days"
    quantitative: "2-4 eras, 1-4 translation tests, <10 cross-era PRs in 180 days"
  practiced:
    description: "Mature multi-era codebase with active cross-era development"
    requires: [exploring]
    criteria:
      - description: "Extensive era coverage"
        method: file_search
        pattern: "Directories containing era identifiers"
        threshold: "count >= 5"
      - description: "Translation tests per era boundary"
        method: file_search
        pattern: "**/Translation*.hs or **/TranslationSpec*.hs"
        threshold: "count >= 5"
      - description: "Active cross-era PRs"
        method: pr_analysis
        pattern: "PRs touching files in 2+ era directories"
        threshold: "count >= 10 in last 180 days"
    quantitative: "5+ eras, 5+ translation tests, 10+ cross-era PRs in 180 days"
  confidence_threshold: 60
```

## CDDL/schema conformance testing assistance

```yaml
id: hs_cddl_conformance
type: opportunity
ecosystem: haskell
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - CDDL or similar schema definitions exist in repo
  - Serialization/deserialization code must conform to external specs
  - Conformance tests exist but may not cover all schema variants

value: MEDIUM
value_context: "CDDL conformance is tedious to verify exhaustively; AI can identify untested schema branches"
effort: Medium
evidence_to_look_for:
  - .cddl files in repo
  - CddlSpec.hs or similar conformance test files
  - Serialization modules (ToCBOR, FromCBOR instances)
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "CddlSpec.hs covers main types but some era-specific variants untested"

learning_entry: |
  Give Claude the CDDL schema + the corresponding CddlSpec test file.
  Ask: "Which schema alternatives are not covered by the existing tests?"
  Then: generate test cases for the uncovered alternatives.
  Verify generated tests compile and exercise the correct serialization paths.

readiness_criteria:
  - criterion: "CDDL or schema files exist"
    type: Objective
    check: ".cddl files or equivalent schema definitions in repo"
  - criterion: "Conformance tests exist"
    type: Objective
    check: "Test files that verify serialization against schema (CddlSpec, etc.)"
  - criterion: "Serialization modules are identifiable"
    type: Objective
    check: "Modules with ToCBOR/FromCBOR/ToJSON/FromJSON instances"

kb_version: "6.2"

adoption_signals:
  active:
    - description: "AI-attributed commits in CDDL or serialization paths"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching **/*.cddl or **/CddlSpec*.hs or **/CBOR*.hs"
      threshold: "count >= 3 in last 90 days"
    - description: "AI-generated conformance test PRs"
      method: pr_analysis
      pattern: "PRs with AI co-authorship adding or modifying CddlSpec or CBOR conformance tests"
      threshold: "count >= 2 in last 90 days"
    - description: "AI config references CDDL or serialization testing"
      method: content_analysis
      pattern: "CLAUDE.md or .claude/docs/ mentions CDDL, CBOR conformance, or serialization testing"
      threshold: "exists: true"
  partial:
    - description: "1-2 AI commits in serialization paths"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching **/*.cddl or **/CBOR*.hs"
      threshold: "count >= 1 AND count < 3 in last 90 days"
    - description: "AI config exists but doesn't reference CDDL"
      method: file_search
      pattern: "CLAUDE.md or .cursorrules exists"
      threshold: "exists: true"
  absent:
    - description: "No AI config files"
      method: file_search
      pattern: "CLAUDE.md, .cursorrules, .mcp.json, copilot-instructions.md, AGENTS.md"
      threshold: "none exist"
    - description: "No AI attribution in commits"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini|AI)"
      threshold: "count == 0 in last 180 days"
  anti_patterns:
    - description: "AI-generated CDDL tests that don't compile"
      method: pr_analysis
      pattern: "AI-attributed PRs adding CddlSpec tests with CI failures in serialization"
      actual_state: "Absent — broken conformance tests are worse than none"
    - description: "AI modifying .cddl files without spec alignment"
      method: commit_scan
      pattern: "AI-attributed commits changing .cddl files without corresponding spec reference"
      actual_state: "Partial at best — CDDL must match external spec"
  confidence_threshold: 60

readiness_levels:
  undiscovered:
    description: "No CDDL or schema conformance infrastructure"
    criteria:
      - description: "No CDDL files"
        method: file_search
        pattern: "**/*.cddl files"
        threshold: "count == 0"
      - description: "No conformance tests"
        method: file_search
        pattern: "**/CddlSpec*.hs or **/Cddl*.hs"
        threshold: "count == 0"
  exploring:
    description: "CDDL exists but conformance testing is sparse"
    requires: [undiscovered]
    criteria:
      - description: "CDDL files exist"
        method: file_search
        pattern: "**/*.cddl files"
        threshold: "count >= 1 AND count < 5"
      - description: "Few CddlSpec files"
        method: file_search
        pattern: "**/CddlSpec*.hs"
        threshold: "count >= 1 AND count < 3"
      - description: "ToCBOR/FromCBOR instances exist but coverage unknown"
        method: content_analysis
        pattern: "ToCBOR or FromCBOR instance declarations in *.hs files"
        threshold: "count >= 1"
        sampling: "sample 10 era source files"
    quantitative: "1-4 .cddl files, 1-2 CddlSpec files, some CBOR instances"
  practiced:
    description: "Comprehensive CDDL conformance infrastructure ready for AI augmentation"
    requires: [exploring]
    criteria:
      - description: "CDDL files per era"
        method: file_search
        pattern: "**/*.cddl files"
        threshold: "count >= 5"
      - description: "CddlSpec per era"
        method: file_search
        pattern: "**/CddlSpec*.hs"
        threshold: "count >= 3"
      - description: "ToCBOR/FromCBOR coverage across eras"
        method: content_analysis
        pattern: "ToCBOR and FromCBOR instances in era-specific modules"
        threshold: "found in >= 80% of sampled era modules"
        sampling: "sample 5 era packages, 2 modules each"
      - description: "Conformance tests in CI"
        method: file_search
        pattern: "CDDL or cddl referenced in CI workflow or flake.nix"
        threshold: "exists: true"
    quantitative: "5+ .cddl files, 3+ CddlSpec files, 80%+ CBOR coverage, CI runs conformance"
  confidence_threshold: 60
```

## Conformance testing against Agda formal specification

```yaml
id: hs_agda_conformance
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30
source_scan: IntersectMBO/cardano-ledger (learning, 2026-03-30)

applies_when:
  - Agda or Coq formal specification exists for the protocol/system
  - Haskell implementation must conform to formal spec
  - Executable spec can be extracted and tested against implementation

value: HIGH
value_context: "Formal spec conformance is the gold standard for correctness in financial ledger systems — AI can help identify gaps between spec and impl"
effort: Medium
evidence_to_look_for:
  - formal-spec/ or formal-ledger-specifications/ referenced in cabal.project
  - ExecSpecRule modules (bridge between Agda-extracted spec and Haskell tests)
  - Conformance test directories
  - source-repository-package pointing to formal spec repo
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "Complete Agda formal spec for Conway era, partial for earlier eras. Conformance testing via libs/cardano-ledger-conformance/ with ExecSpecRule modules per STS rule."

learning_entry: |
  When a new STS rule is added or modified:
  1. Give Claude the Agda spec extract + the Haskell implementation of the rule
  2. Ask: "Where does the Haskell implementation diverge from the formal spec?"
  3. Ask: "What conformance test cases would exercise the divergence points?"
  Particularly valuable during era transitions where rules are modified
  and conformance must be re-verified.

readiness_criteria:
  - criterion: "Formal spec exists and is extractable"
    type: Objective
    check: "source-repository-package in cabal.project pointing to formal spec, or formal-spec/ directory"
  - criterion: "Conformance bridge exists (ExecSpecRule or equivalent)"
    type: Objective
    check: "Conformance test modules that bridge extracted spec to Haskell implementation"
  - criterion: "CI runs conformance tests"
    type: Objective
    check: "Conformance test package included in CI test suite"

kb_version: "6.2"

adoption_signals:
  active:
    - description: "AI-attributed commits in conformance test paths"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching **/conformance/** or **/ExecSpecRule*.hs"
      threshold: "count >= 3 in last 90 days"
    - description: "AI spec-gap analysis in PRs"
      method: pr_analysis
      pattern: "PRs with AI co-authorship identifying or closing gaps between formal spec and implementation"
      threshold: "count >= 2 in last 90 days"
    - description: "AI config references Agda conformance workflow"
      method: content_analysis
      pattern: "CLAUDE.md or .claude/docs/ mentions Agda, formal spec, conformance testing, or ExecSpecRule"
      threshold: "exists: true"
  partial:
    - description: "1-2 AI commits in conformance paths"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching **/conformance/** or **/ExecSpecRule*.hs"
      threshold: "count >= 1 AND count < 3 in last 90 days"
    - description: "AI config exists but doesn't reference formal spec"
      method: file_search
      pattern: "CLAUDE.md or .cursorrules exists"
      threshold: "exists: true"
  absent:
    - description: "No AI config files"
      method: file_search
      pattern: "CLAUDE.md, .cursorrules, .mcp.json, copilot-instructions.md, AGENTS.md"
      threshold: "none exist"
    - description: "No AI attribution in commits"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini|AI)"
      threshold: "count == 0 in last 180 days"
  anti_patterns:
    - description: "AI modifying extracted spec output directly"
      method: commit_scan
      pattern: "AI-attributed commits changing Agda-extracted Haskell files instead of the Agda source"
      actual_state: "Absent — extracted code must not be hand-edited"
    - description: "AI conformance tests that skip spec extraction step"
      method: pr_analysis
      pattern: "AI-attributed conformance PRs that hardcode expected values instead of extracting from spec"
      actual_state: "Absent — conformance must test against actual spec extraction"
  confidence_threshold: 60

readiness_levels:
  undiscovered:
    description: "No formal spec or conformance infrastructure"
    criteria:
      - description: "No formal spec reference"
        method: file_search
        pattern: "source-repository-package pointing to formal-ledger-specifications or formal-spec/ directory"
        threshold: "count == 0"
      - description: "No ExecSpecRule modules"
        method: file_search
        pattern: "**/ExecSpecRule*.hs"
        threshold: "count == 0"
  exploring:
    description: "Formal spec exists but conformance bridge is limited"
    requires: [undiscovered]
    criteria:
      - description: "Formal spec referenced in project"
        method: file_search
        pattern: "source-repository-package for formal spec in cabal.project"
        threshold: "exists: true"
      - description: "Few ExecSpecRule modules"
        method: file_search
        pattern: "**/ExecSpecRule*.hs"
        threshold: "count >= 1 AND count < 5"
      - description: "Conformance package exists but not all rules covered"
        method: file_search
        pattern: "cardano-ledger-conformance or equivalent conformance package in cabal.project"
        threshold: "exists: true"
    quantitative: "Formal spec linked, 1-4 ExecSpecRule modules, conformance package exists"
  practiced:
    description: "Comprehensive conformance infrastructure ready for AI gap analysis"
    requires: [exploring]
    criteria:
      - description: "Extensive ExecSpecRule coverage"
        method: file_search
        pattern: "**/ExecSpecRule*.hs"
        threshold: "count >= 5"
      - description: "Conformance tests in CI"
        method: file_search
        pattern: "conformance test package in CI workflow or cabal test targets"
        threshold: "exists: true"
      - description: "Active formal spec development"
        method: git_log_search
        pattern: "Commits referencing formal spec or conformance in last 180 days"
        threshold: "count >= 5"
    quantitative: "5+ ExecSpecRule modules, CI conformance, active spec development"
  confidence_threshold: 60
```

## Imp test generation for new STS rules

```yaml
id: hs_imp_test_generation
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30
source_scan: IntersectMBO/cardano-ledger (learning, 2026-03-30)

applies_when:
  - Imp test framework in use (imperative property test style)
  - New STS rules or rule modifications in active development
  - Existing Imp tests as template/reference per era

value: HIGH
value_context: "Imp tests are the primary testing strategy for STS rules — AI can generate new Imp tests from existing patterns + rule specifications"
effort: Low
evidence_to_look_for:
  - testlib/Test/Cardano/Ledger/{Era}/Imp/ directories with *Spec.hs files
  - New rules added without corresponding Imp tests
  - Newest era Imp tests (likely sparse compared to established eras)
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "Extensive Imp test suite for Conway (11+ Spec files). Dijkstra coverage in early stages."

learning_entry: |
  When adding a new STS rule to an era:
  1. Give Claude an existing ImpSpec from the same era as reference
  2. Give Claude the new rule module
  3. Ask: "Generate an Imp test suite following the same patterns as the reference"
  Imp tests follow a consistent style per era — AI replicates the pattern accurately.
  Review: verify the generated test exercises the rule's preconditions and postconditions.

readiness_criteria:
  - criterion: "Imp test framework available for the target era"
    type: Objective
    check: "testlib/Test/Cardano/Ledger/{Era}/Imp/ directory exists with at least one Spec file"
  - criterion: "STS rule module exists to test"
    type: Objective
    check: "Rules/{RuleName}.hs exists in the era's src directory"
  - criterion: "Era test infrastructure builds"
    type: Objective
    check: "The era's test-suite or testlib compiles in CI"

kb_version: "6.2"

adoption_signals:
  active:
    - description: "AI-attributed commits adding ImpSpec tests"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching **/Imp/**/*Spec.hs"
      threshold: "count >= 3 in last 90 days"
    - description: "AI-generated Imp test PRs"
      method: pr_analysis
      pattern: "PRs with AI co-authorship adding new *Spec.hs files in Imp/ directories"
      threshold: "count >= 2 in last 90 days"
    - description: "AI config references Imp test generation"
      method: content_analysis
      pattern: "CLAUDE.md or .claude/docs/ mentions Imp tests, ImpSpec, or STS test generation"
      threshold: "exists: true"
  partial:
    - description: "1-2 AI commits in Imp test paths"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching **/Imp/**"
      threshold: "count >= 1 AND count < 3 in last 90 days"
    - description: "AI config exists but doesn't reference Imp tests"
      method: file_search
      pattern: "CLAUDE.md or .cursorrules exists"
      threshold: "exists: true"
  absent:
    - description: "No AI config files"
      method: file_search
      pattern: "CLAUDE.md, .cursorrules, .mcp.json, copilot-instructions.md, AGENTS.md"
      threshold: "none exist"
    - description: "No AI attribution in commits"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini|AI)"
      threshold: "count == 0 in last 180 days"
  anti_patterns:
    - description: "AI-generated Imp tests that don't exercise preconditions"
      method: content_analysis
      pattern: "ImpSpec files with only trivial assertions (no state setup, no precondition checks)"
      actual_state: "Absent — tests that don't exercise the rule are not real coverage"
    - description: "AI Imp tests copied from wrong era without adaptation"
      method: pr_analysis
      pattern: "AI-attributed ImpSpec PRs where code references types from a different era"
      actual_state: "Absent — era-mismatched tests indicate copy-paste without understanding"
  confidence_threshold: 60

readiness_levels:
  undiscovered:
    description: "No Imp test framework in use"
    criteria:
      - description: "No Imp test directories"
        method: file_search
        pattern: "**/Imp/ directories in testlib/ or test/"
        threshold: "count == 0"
      - description: "No Rules modules to test"
        method: file_search
        pattern: "**/Rules/*.hs in era source directories"
        threshold: "count == 0"
  exploring:
    description: "Imp tests exist in some eras but not the newest"
    requires: [undiscovered]
    criteria:
      - description: "Imp directories exist in some eras"
        method: file_search
        pattern: "**/Imp/ directories per era in testlib/"
        threshold: "count >= 1 AND count < 3 eras"
      - description: "Rules modules in newest era"
        method: file_search
        pattern: "**/Rules/*.hs in the newest era's source directory"
        threshold: "count >= 1"
      - description: "Newest era Imp tests sparse"
        method: file_search
        pattern: "*Spec.hs in newest era's Imp/ directory"
        threshold: "count < 5"
    quantitative: "Imp in 1-2 eras, Rules exist in newest era, <5 Imp tests in newest era"
  practiced:
    description: "Extensive Imp test infrastructure ready for AI-assisted generation"
    requires: [exploring]
    criteria:
      - description: "Imp directories in multiple eras"
        method: file_search
        pattern: "**/Imp/ directories per era"
        threshold: "count >= 3 eras"
      - description: "Rich ImpSpec coverage in established eras"
        method: file_search
        pattern: "*Spec.hs in established era Imp/ directories"
        threshold: "count >= 10 across established eras"
      - description: "Era test builds pass in CI"
        method: file_search
        pattern: "Era test packages in CI workflow or cabal test targets"
        threshold: "exists: true"
      - description: "Rules modules exist in newest era for gap analysis"
        method: file_search
        pattern: "**/Rules/*.hs in newest era"
        threshold: "count >= 3"
    quantitative: "3+ eras with Imp, 10+ ImpSpec files in established eras, CI builds, 3+ Rules in newest era"
  confidence_threshold: 60
```

## Constrained generator authoring assistance

```yaml
id: hs_constrained_generators
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30
source_scan: IntersectMBO/cardano-ledger (learning, 2026-03-30)

applies_when:
  - constrained-generators library in use (specialized generator infrastructure)
  - New data types added without corresponding generators
  - Complex invariants that must hold across generated values

value: HIGH
value_context: "constrained-generators produces test data with inter-field constraints — AI can help write generators that satisfy complex invariants"
effort: Medium
evidence_to_look_for:
  - constrained-generators pinned in cabal.project as source-repository-package
  - HasSpec instances or constrained generator definitions
  - New data types in active eras without HasSpec instances
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "constrained-generators pinned. 2 AI-attributed commits (2026-03-23) added plutusScriptGen — actual instance of AI assisting with generator authoring."

learning_entry: |
  When adding a new data type that needs test generators:
  1. Give Claude the data type definition + its validation rules/invariants
  2. Give Claude an existing constrained generator for a similar type
  3. Ask: "Write a generator that produces valid instances satisfying these invariants"
  The invariants are the hard part — AI translates formal constraints into generator code.
  Always test: does the generator produce valid instances? Does shrinking work?

readiness_criteria:
  - criterion: "constrained-generators library available"
    type: Objective
    check: "constrained-generators in cabal.project dependencies"
  - criterion: "Existing generators as reference"
    type: Objective
    check: "At least 3 Arbitrary.hs or generator modules exist in the target era"
  - criterion: "Data type invariants documented or in formal spec"
    type: Semi-objective
    check: "Formal spec or inline comments describe validity conditions for the data type"

kb_version: "6.2"

adoption_signals:
  active:
    - description: "AI-attributed commits adding constrained generators or HasSpec instances"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching **/HasSpec*.hs or **/Gen*.hs or containing 'constrained-generators'"
      threshold: "count >= 3 in last 90 days"
    - description: "Known AI-assisted generator (e.g., plutusScriptGen)"
      method: git_log_search
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) AND (plutusScriptGen|HasSpec|constrained)"
      threshold: "count >= 1"
    - description: "AI-generated generator PRs"
      method: pr_analysis
      pattern: "PRs with AI co-authorship adding HasSpec instances or constrained generator definitions"
      threshold: "count >= 2 in last 90 days"
  partial:
    - description: "1-2 AI commits in generator paths"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching **/Gen*.hs or **/Arbitrary*.hs"
      threshold: "count >= 1 AND count < 3 in last 90 days"
    - description: "AI config exists but doesn't reference generators"
      method: file_search
      pattern: "CLAUDE.md or .cursorrules exists"
      threshold: "exists: true"
  absent:
    - description: "No AI config files"
      method: file_search
      pattern: "CLAUDE.md, .cursorrules, .mcp.json, copilot-instructions.md, AGENTS.md"
      threshold: "none exist"
    - description: "No AI attribution in commits"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini|AI)"
      threshold: "count == 0 in last 180 days"
  anti_patterns:
    - description: "AI generators that don't satisfy invariants"
      method: pr_analysis
      pattern: "AI-attributed generator PRs with CI failures in property tests"
      actual_state: "Absent — generators that produce invalid data are counterproductive"
    - description: "AI using plain Arbitrary instead of constrained-generators"
      method: content_analysis
      pattern: "AI-attributed code adding plain Arbitrary instances where HasSpec should be used"
      actual_state: "Partial at best — bypasses the constrained generator framework"
  confidence_threshold: 60

readiness_levels:
  undiscovered:
    description: "No constrained-generators infrastructure"
    criteria:
      - description: "constrained-generators not in project"
        method: file_search
        pattern: "constrained-generators in cabal.project or *.cabal"
        threshold: "count == 0"
      - description: "No HasSpec instances"
        method: file_search
        pattern: "**/HasSpec*.hs or HasSpec in *.hs files"
        threshold: "count == 0"
  exploring:
    description: "constrained-generators available but few instances"
    requires: [undiscovered]
    criteria:
      - description: "constrained-generators in project dependencies"
        method: file_search
        pattern: "constrained-generators in cabal.project"
        threshold: "exists: true"
      - description: "Few HasSpec instances"
        method: content_analysis
        pattern: "HasSpec instance declarations in *.hs files"
        threshold: "count >= 1 AND count < 10"
      - description: "Formal spec for invariants exists"
        method: file_search
        pattern: "formal-spec/ or spec/ directory with invariant definitions"
        threshold: "exists: true"
    quantitative: "constrained-generators linked, 1-9 HasSpec instances, formal spec exists"
  practiced:
    description: "Rich constrained generator ecosystem ready for AI authoring"
    requires: [exploring]
    criteria:
      - description: "Extensive HasSpec instances"
        method: content_analysis
        pattern: "HasSpec instance declarations in *.hs files"
        threshold: "count >= 10"
      - description: "Generator test coverage"
        method: file_search
        pattern: "Test files exercising constrained generators"
        threshold: "count >= 5"
      - description: "Formal invariant documentation"
        method: file_search
        pattern: "formal-spec/ with extractable invariants for data types"
        threshold: "exists: true"
      - description: "Recent generator development activity"
        method: git_log_search
        pattern: "Commits touching HasSpec or constrained-generators files"
        threshold: "count >= 3 in last 180 days"
    quantitative: "10+ HasSpec instances, 5+ generator tests, formal spec, active development"
  confidence_threshold: 60
```

## Era transition documentation generation

```yaml
id: hs_era_transition_docs
type: opportunity
ecosystem: haskell
status: proposed
discovered: 2026-03-30
updated: 2026-03-30
source_scan: IntersectMBO/cardano-ledger (learning, 2026-03-30)

applies_when:
  - Multi-era architecture with active era transitions
  - NewEra.md or equivalent guide exists but may be incomplete
  - New era being developed requires understanding of transition process

value: MEDIUM
value_context: "Era transitions require understanding the full checklist — AI can generate transition documentation from diff between adjacent eras"
effort: Low
evidence_to_look_for:
  - docs/NewEra.md (transition guide)
  - Transition.hs modules per era
  - Translation test modules
  - CHANGELOG.md per era package
seen_in:
  - repo: IntersectMBO/cardano-ledger
    outcome: "docs/NewEra.md exists. Transition.hs per era. Translation tests per era. Dijkstra era actively being developed."

learning_entry: |
  When starting a new era transition:
  1. Give Claude the transition guide + the previous Transition.hs + the new era's initial files
  2. Ask: "What's missing in the new era compared to what the guide prescribes?"
  3. Ask: "Draft the Transition.hs based on the changes from the previous era"
  Review against formal spec — transition logic must match specification.

readiness_criteria:
  - criterion: "Era transition guide exists"
    type: Objective
    check: "docs/NewEra.md or equivalent transition documentation"
  - criterion: "Previous era transition modules exist as reference"
    type: Objective
    check: "At least one Transition.hs from a completed era transition"

kb_version: "6.2"

adoption_signals:
  active:
    - description: "AI-attributed commits on era transition docs"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching docs/NewEra.md or **/Transition*.hs or CHANGELOG.md in era packages"
      threshold: "count >= 3 in last 90 days"
    - description: "AI-generated transition documentation PRs"
      method: pr_analysis
      pattern: "PRs with AI co-authorship updating NewEra.md or adding era transition documentation"
      threshold: "count >= 2 in last 90 days"
    - description: "AI config references era transition workflow"
      method: content_analysis
      pattern: "CLAUDE.md or .claude/docs/ mentions era transition, NewEra, or transition documentation"
      threshold: "exists: true"
  partial:
    - description: "1-2 AI commits on transition docs"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini) in commits touching docs/ or **/Transition*.hs"
      threshold: "count >= 1 AND count < 3 in last 90 days"
    - description: "AI config exists but doesn't reference era transitions"
      method: file_search
      pattern: "CLAUDE.md or .cursorrules exists"
      threshold: "exists: true"
  absent:
    - description: "No AI config files"
      method: file_search
      pattern: "CLAUDE.md, .cursorrules, .mcp.json, copilot-instructions.md, AGENTS.md"
      threshold: "none exist"
    - description: "No AI attribution in commits"
      method: commit_scan
      pattern: "Co-authored-by.*(Claude|Copilot|Cursor|Gemini|AI)"
      threshold: "count == 0 in last 180 days"
  anti_patterns:
    - description: "AI-generated transition docs not validated against formal spec"
      method: pr_analysis
      pattern: "AI-attributed transition doc PRs without reference to formal spec or Transition.hs"
      actual_state: "Partial at best — transition docs must align with actual implementation"
    - description: "NewEra.md updated but Transition.hs unchanged"
      method: commit_scan
      pattern: "AI commits modifying docs/NewEra.md without corresponding Transition.hs changes"
      actual_state: "Partial at best — docs without code alignment are aspirational"
  confidence_threshold: 60

readiness_levels:
  undiscovered:
    description: "No era transition documentation infrastructure"
    criteria:
      - description: "No NewEra.md or transition guide"
        method: file_search
        pattern: "docs/NewEra.md or docs/*transition* or docs/*era*"
        threshold: "count == 0"
      - description: "No Transition.hs modules"
        method: file_search
        pattern: "**/Transition.hs or **/Transition/*.hs"
        threshold: "count == 0"
  exploring:
    description: "Transition infrastructure exists but documentation is sparse"
    requires: [undiscovered]
    criteria:
      - description: "NewEra.md or transition guide exists"
        method: file_search
        pattern: "docs/NewEra.md"
        threshold: "exists: true"
      - description: "Few Transition.hs modules"
        method: file_search
        pattern: "**/Transition.hs per era"
        threshold: "count >= 1 AND count < 4"
      - description: "Newest era in early development"
        method: file_search
        pattern: "Source directory for newest era (e.g., dijkstra/)"
        threshold: "exists: true"
    quantitative: "NewEra.md exists, 1-3 Transition.hs modules, newest era started"
  practiced:
    description: "Mature transition infrastructure ready for AI documentation assistance"
    requires: [exploring]
    criteria:
      - description: "Transition.hs per completed era"
        method: file_search
        pattern: "**/Transition.hs per era"
        threshold: "count >= 4"
      - description: "NewEra.md with substantive content"
        method: content_analysis
        pattern: "docs/NewEra.md with checklist or step-by-step guide"
        threshold: "word count >= 500"
      - description: "Translation tests per era boundary"
        method: file_search
        pattern: "**/Translation*.hs"
        threshold: "count >= 3"
      - description: "Active newest era development"
        method: git_log_search
        pattern: "Commits in newest era directory in last 90 days"
        threshold: "count >= 5"
    quantitative: "4+ Transition.hs, substantive NewEra.md, 3+ translation tests, active newest era"
  confidence_threshold: 60
```

---

## Detection Notes (from v5 scans)

These are not opportunity patterns — they are agent instructions for accurate data collection in Haskell repos.

- **Nix-wrapped CI:** Haskell repos run hlint/fourmolu via `nix develop --command`. Match `nix develop|nix build|nix flake check` patterns, not just direct tool names. `flake.nix` is a first-class detection surface.
- **cabal multi-package:** `cabal.project` with `packages:` listing multiple paths indicates module boundaries. Count packages, not just "cabal exists."
- **HLint + fourmolu:** Standard Haskell tooling. Detection: `.hlint.yaml`, or `hlint`/`fourmolu` in `flake.nix` or CI.
