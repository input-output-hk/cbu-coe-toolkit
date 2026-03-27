# TypeScript Ecosystem Patterns

## strict mode as baseline type safety

```yaml
source: ecosystem-standard
repos: []
category: clarity
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

`tsconfig.json` with `"strict": true`. Detection: parse compilerOptions.

**Applicability:** All TypeScript repos.

## Contract packages as boundary definitions

```yaml
source: iog-scan
repos: [lace-platform]
category: clarity
status: validated
discovered: 2026-03-26
updated: 2026-03-27
```

`packages/contract/` packages define typed interfaces at module boundaries.
lace-platform has 30+ contract packages. Functionally equivalent to schema
definitions but not detected by .proto/.graphql search.

**Recommendation template:**
"Define typed interfaces in dedicated contract packages. Effort: Medium. Impact: HIGH."

**Applicability:** TypeScript monorepos.

## NX/pnpm workspaces for monorepo structure

```yaml
source: ecosystem-standard
repos: [lace-platform]
category: structure
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

pnpm-workspace.yaml or nx.json. Note: `npm run check:format` and
`npx nx affected --target=lint` don't contain tool names directly.

**Applicability:** TypeScript monorepos.

## ESLint + Prettier as standard tooling

```yaml
source: ecosystem-standard
repos: []
category: structure
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

ESLint (including naming-convention rules), Prettier for formatting.
Detection: `.eslintrc.*`, `.prettierrc.*`, or config in package.json.

**Applicability:** All TypeScript repos.
