# Python Ecosystem — Opportunity Patterns + Readiness Criteria

## Test generation for untested modules

```yaml
id: py_test_generation
type: opportunity
ecosystem: python
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - pytest configured but test coverage sparse
  - Modules with business logic and no corresponding test files
  - conftest.py fixtures exist (infrastructure is ready)

value: MEDIUM
value_context: "Python's dynamic typing makes untested code risky; AI can generate comprehensive test suites using existing fixtures as reference"
effort: Low
evidence_to_look_for:
  - src/ or app/ modules without corresponding tests/ files
  - pytest in pyproject.toml or requirements
  - conftest.py with fixtures (test infrastructure exists)
  - Coverage config showing low coverage areas
seen_in: []

learning_entry: |
  Pick an untested module. Give Claude:
  1. The module source
  2. conftest.py fixtures relevant to this module
  3. One existing test file (for style reference)
  Ask: generate pytest tests covering normal cases, edge cases, and error paths.
  Review: are assertions testing behavior? Are fixtures used correctly?

readiness_criteria:
  - criterion: "pytest configured"
    type: Objective
    check: "pytest in pyproject.toml [project.optional-dependencies] or requirements-dev.txt"
  - criterion: "Test directory structure exists"
    type: Objective
    check: "tests/ directory with __init__.py or conftest.py"
  - criterion: "At least one test file exists as reference"
    type: Objective
    check: "Any test_*.py file exists"
  - criterion: "CI runs tests"
    type: Objective
    check: "CI workflow invokes pytest"
```

## Type annotation and mypy adoption assistance

```yaml
id: py_type_annotations
type: opportunity
ecosystem: python
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Python 3.8+ codebase
  - Limited type annotations on functions/methods
  - mypy not configured or configured but many errors suppressed

value: MEDIUM
value_context: "Type annotations improve AI code understanding and catch bugs at development time; AI can draft annotations from runtime behavior and usage patterns"
effort: Medium
evidence_to_look_for:
  - Functions without type hints (def foo(x, y): instead of def foo(x: int, y: str) -> bool:)
  - mypy.ini or pyproject.toml [tool.mypy] with many ignore_errors or type: ignore comments
  - pydantic models (already typed) coexisting with untyped utility functions
seen_in: []

learning_entry: |
  Start with one utility module. Give Claude:
  1. The module source (untyped functions)
  2. Call sites from other modules (usage context)
  Ask: draft type annotations for all functions. Include Optional, Union,
  and generic types where appropriate.
  Review: run mypy on the annotated file. Fix any errors. Commit one module at a time.

readiness_criteria:
  - criterion: "Python 3.8+ (supports modern type syntax)"
    type: Objective
    check: "python_requires >= 3.8 in pyproject.toml or .python-version"
  - criterion: "mypy configured"
    type: Objective
    check: "mypy in dev dependencies, mypy.ini or [tool.mypy] in pyproject.toml"
  - criterion: "Some type annotations exist as reference"
    type: Semi-objective
    check: "At least 3 modules have function-level type annotations"
```

## Documentation generation for API modules

```yaml
id: py_docstring_generation
type: opportunity
ecosystem: python
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Public API modules (Flask/FastAPI routes, library interfaces)
  - Docstring coverage below 50%
  - Complex functions with multiple parameters

value: MEDIUM
value_context: "Python docstrings power IDE help, Sphinx docs, and AI understanding; AI can draft accurate docstrings from signatures + usage"
effort: Low
evidence_to_look_for:
  - Functions without docstrings (no triple-quoted string after def)
  - Complex function signatures (>3 parameters, **kwargs)
  - Sphinx or MkDocs configuration (docs infrastructure exists but content sparse)
seen_in: []

learning_entry: |
  Pick a module with complex undocumented functions. Give Claude:
  1. The module source
  2. Call sites from other modules
  Ask: draft Google-style or NumPy-style docstrings (match existing repo convention).
  Include: description, Args, Returns, Raises, Example.
  Review for accuracy — especially default values and exception conditions.

readiness_criteria:
  - criterion: "Docstring convention established"
    type: Semi-objective
    check: "At least 3 functions have docstrings in consistent format (Google, NumPy, or Sphinx)"
  - criterion: "Documentation tooling configured"
    type: Objective
    check: "Sphinx conf.py or mkdocs.yml exists, or pdoc in dependencies"
```

## Debugging data pipeline issues

```yaml
id: py_debug_pipelines
type: opportunity
ecosystem: python
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Data processing pipelines (pandas, polars, dask, custom ETL)
  - Multi-step transformations where intermediate state is hard to inspect
  - History of data integrity bugs (wrong joins, missing nulls, type coercion errors)

value: HIGH
value_context: "Data pipeline debugging requires tracing transformations step by step; AI excels at identifying where data shape changes break assumptions"
effort: Low
evidence_to_look_for:
  - pandas, polars, or dask in dependencies
  - Pipeline modules with chained transformations
  - Data validation code (great_expectations, pandera, custom assertions)
  - Bug-fix commits mentioning "null", "missing", "dtype", "join"
seen_in: []

learning_entry: |
  When debugging a data issue:
  1. Give Claude the pipeline code + a sample of the input data schema
  2. Describe the symptom ("output has unexpected nulls after step 3")
  3. Ask: "Trace the data shape through each transformation. Where do nulls get introduced?"
  AI traces data transformations step by step — validate with a sample dataset.

readiness_criteria:
  - criterion: "Data processing library in use"
    type: Objective
    check: "pandas, polars, or dask in project dependencies"
  - criterion: "Data validation exists"
    type: Objective
    check: "pandera, great_expectations, or custom assertion functions in pipeline code"
```

## Hypothesis property-based testing

```yaml
id: py_hypothesis_testing
type: opportunity
ecosystem: python
status: seed
discovered: 2026-03-30
updated: 2026-03-30

applies_when:
  - Functions with complex input domains
  - hypothesis not yet adopted but pytest is configured
  - Serialization/deserialization code, parsers, validators

value: MEDIUM
value_context: "Hypothesis finds edge cases that example-based tests miss; AI can draft strategies and property definitions from function signatures"
effort: Medium
evidence_to_look_for:
  - hypothesis NOT in dependencies (adoption opportunity)
  - Functions with complex input validation (parsers, validators, serializers)
  - Existing tests that only cover happy paths
seen_in: []

learning_entry: |
  Pick a function with complex input domain (e.g., a parser or validator).
  Give Claude the function + its input types.
  Ask: "What properties should always hold for this function?"
  Then: "Draft hypothesis strategies and @given-decorated tests for these properties."
  Start with one function. Run the tests. Hypothesis will find edge cases you didn't think of.

readiness_criteria:
  - criterion: "pytest configured"
    type: Objective
    check: "pytest in dependencies and CI"
  - criterion: "Functions with validatable properties exist"
    type: Semi-objective
    check: "Functions that parse, validate, serialize, or transform data with defined contracts"
```

---

## Detection Notes (from v5 scans)

- **mypy + ruff:** Modern Python tooling. ruff replaces flake8, black, isort. Detection: `ruff` in pyproject.toml or CI.
- **pyproject.toml:** Unified project config. Detection: `pyproject.toml` at root with `[project]` or `[tool.*]` sections.
- **pytest with conftest:** `tests/` directory, `test_*.py` files, `conftest.py` for shared fixtures.
