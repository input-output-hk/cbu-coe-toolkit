# Python Ecosystem Patterns

## mypy + ruff as modern tooling

```yaml
source: ecosystem-standard
repos: []
category: structure
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

mypy for type checking, ruff for linting + formatting (replaces flake8, black, isort).
Detection: `mypy` in pyproject.toml or mypy.ini, `ruff` in pyproject.toml or CI.

**Applicability:** All Python repos.

## pyproject.toml as unified project config

```yaml
source: ecosystem-standard
repos: []
category: structure
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

`pyproject.toml` as single source for project metadata, build system, tool config
(mypy, ruff, pytest). Replaces `setup.py` + `setup.cfg` + per-tool config files.
Detection: `pyproject.toml` at repo root with `[project]` or `[tool.*]` sections.

**Applicability:** All Python repos.

## pytest with conftest fixtures

```yaml
source: ecosystem-standard
repos: []
category: safety-net
status: validated
discovered: 2026-03-27
updated: 2026-03-27
```

`tests/` directory, `test_*.py` files, conftest.py for shared fixtures.
Property-based testing via `hypothesis`.

**Applicability:** All Python repos.
