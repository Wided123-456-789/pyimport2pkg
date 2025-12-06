# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PyImport2Pkg** is a Python tool that performs reverse mapping from Python import statements to pip package names. It solves the problem of identifying which packages to install when given code with imports like `import cv2` → `pip install opencv-python`.

## Development Commands

```bash
# Install in development mode
.venv/Scripts/pip install -e ".[dev]"

# Run all tests
.venv/Scripts/pytest tests/ -v

# Run specific test file
.venv/Scripts/pytest tests/test_parser.py -v

# Run specific test
.venv/Scripts/pytest tests/test_parser.py::TestParserBasicImports::test_simple_import -v

# CLI commands
.venv/Scripts/pyimport2pkg analyze ./path/to/project
.venv/Scripts/pyimport2pkg query cv2
.venv/Scripts/pyimport2pkg build-db --max-packages 5000
.venv/Scripts/pyimport2pkg db-info
```

## Architecture

The tool follows a pipeline architecture:

```
Scanner → Parser → Filter → Mapper → Resolver → Exporter
```

### Core Modules

| Module | Purpose |
|--------|---------|
| `scanner.py` | Recursively finds Python files, excludes `.venv`, `__pycache__`, etc. |
| `parser.py` | Uses AST to extract imports with context (conditional, try-except, function-level) |
| `filter.py` | Removes stdlib and local project modules; handles Python version differences |
| `mapper.py` | Maps module names to package names using priority: namespace → hardcoded → database → guess |
| `resolver.py` | Handles one-to-many conflicts (e.g., cv2 → multiple opencv variants) |
| `exporter.py` | Generates requirements.txt, JSON, or simple list output |
| `database.py` | Builds SQLite mapping database from PyPI top packages |

### Mapping Priority

The `Mapper` queries sources in this order:
1. **Namespace packages** (if submodules exist) - `google.cloud.storage` → `google-cloud-storage`
2. **Hardcoded mappings** - `cv2` → `opencv-python`, `PIL` → `Pillow`
3. **Namespace packages** (top-level only)
4. **Database lookup** - From `top_level.txt` in wheel files
5. **Guess** - Assume module name equals package name

### Key Data Structures

```python
# models.py
ImportInfo      # Parsed import with context (file, line, is_optional, is_relative)
MappingResult   # Module mapped to package candidates
PackageCandidate # Single package option with download count
```

### Mapping Data

- `mappings/hardcoded.py` - Classic mismatches (`CLASSIC_MISMATCHES`) and PyWin32 modules (`PTH_INJECTED_MODULES`)
- `mappings/namespace.py` - Nested dict for `google.*`, `azure.*`, `zope.*` namespaces

## Test Structure

- 297 tests across 9 test files
- Each module has corresponding `test_<module>.py`
- `test_integration.py` contains end-to-end pipeline tests
- Sample project in `tests/fixtures/sample_project/`

## Key Design Decisions

1. **Namespace packages take priority** over hardcoded mappings when submodules are present
2. **`from xxx import yyy`** only captures `xxx` as the module (cannot infer if `yyy` is a submodule)
3. **Conditional/try-except imports** are marked as `is_optional=True`
4. **Python version awareness** - stdlib list varies by target version; backport detection for `dataclasses`, `tomllib`, etc.
