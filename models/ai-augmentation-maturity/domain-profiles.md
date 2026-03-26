# AAMM: Domain Profiles

> Supplementary signals and recommendation framing for specific repo categories. Profiles enrich reports — they don't change universal scores.
> **Depends on:** `README.md` (model overview), `readiness-scoring.md` (V2 sub-signals)
> **Read by:** agents (scanning), teams (understanding their report), CoE (adding new profiles)
> **Implemented in:** `scripts/aamm/collect-readiness.sh` (detection), `scripts/aamm/score-readiness.sh` (profile JSON), `scripts/aamm/generate-report.sh` (report sections)

---

The universal model scores all repos equally. Domain profiles add **supplementary signals and risk flags** without changing the core architecture. Profiles are optional annotations — they enrich the report, they don't replace the universal score.

### 1. High-Assurance Profile

Applies to repos that: implement consensus/validation rules, handle financial transactions, have formal specifications, or process cryptographic operations.

**Detection:** Presence of `.agda` files, `formal-spec/` directory, `.cddl` files, `SECURITY.md` with vulnerability disclosure, or explicit blockchain/ledger keywords in repo description/topics.

**Supplementary signals** (reported alongside universal scores, not replacing them):

| Signal | How to detect | Why it matters |
|--------|--------------|----------------|
| Formal spec presence | `.agda` files, `formal-spec/` dirs | Primary defense against consensus bugs |
| Conformance testing | `conformance/` dirs, Agda refs in test infrastructure | Bridges spec-implementation gap |
| Generator discipline | `cover`/`classify`/`tabulate`/`checkCoverage`/`forAllShrink`/`forAllBlind`/`withMaxSuccess`/`forAllShow` in test files | Property tests are only as good as generators |
| Concurrency testing | `io-sim`, `io-classes`, `dejafu` in `.cabal` build-depends or source tree | Network-layer correctness |
| Strict evaluation discipline | `StrictData`, `BangPatterns` in `.cabal` default-extensions | Memory safety under adversarial load |
| Benchmark with regression detection | `criterion`/`tasty-bench` + CI alert on regression | Performance regression is a DoS vector |
| CDDL completeness | `.cddl` files per era/protocol version | Serialization correctness across versions |
| Reproducible builds | `nix build` in CI + hash verification | Build supply chain integrity |
| .aiignore on critical paths | `.aiignore` excluding consensus/crypto directories | Mature AI governance — team knows where AI should NOT operate |

**Recommendation adjustments for high-assurance repos:**

- Frame AI as **adversarial reviewer/challenger/auditor** on critical code — threat modeling, completeness checks, generator quality review, performance challenge
- Frame AI as **quality driver** on documentation, test scaffolding, PR quality, issue decomposition
- Frame AI as **code generator** only on boilerplate, serialization from specs, mechanical refactoring
- Never recommend "increase AI co-authorship" on consensus/crypto code without qualifying scope
- Recognize `.aiignore` excluding critical paths as a positive governance signal

**Domain-specific risk flags:**

| Risk | Condition | Severity |
|------|-----------|----------|
| No conformance testing | Formal spec detected but no conformance tests | 🔴 High |
| No concurrency testing framework | Network/distributed code but no io-sim/dejafu | 🟡 Medium |
| Formal spec stale | `.agda` files not modified in 6+ months while implementation changed | 🟡 Medium |
| No benchmark regression detection | Performance-sensitive code without CI benchmarks | 🟡 Medium |

### 2. Future Profiles

Additional profiles can be defined for: web applications (npm threat model, runtime validation), libraries (API stability, documentation completeness), infrastructure/DevOps (IaC scanning, secret management). Each profile follows the same pattern: supplementary signals + recommendation adjustments + domain risk flags.
