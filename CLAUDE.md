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

# Run all tests with short traceback
.venv/Scripts/pytest tests/ -v --tb=short

# Run specific test file
.venv/Scripts/pytest tests/test_parser.py -v

# Run specific test class or method
.venv/Scripts/pytest tests/test_parser.py::TestParserBasicImports -v
.venv/Scripts/pytest tests/test_parser.py::TestParserBasicImports::test_simple_import -v

# Run integration tests
.venv/Scripts/pytest tests/test_integration.py::TestIntegration -v

# Run database tests
.venv/Scripts/pytest tests/test_database.py -v --tb=short

# CLI commands
.venv/Scripts/pyimport2pkg analyze ./path/to/project
.venv/Scripts/pyimport2pkg query cv2
.venv/Scripts/pyimport2pkg build-db --max-packages 5000
.venv/Scripts/pyimport2pkg build-db --resume  # Resume interrupted build
.venv/Scripts/pyimport2pkg build-db --retry-failed  # Retry only failed packages
.venv/Scripts/pyimport2pkg build-status  # Check build progress
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
| `resolver.py` | Handles one-to-many conflicts (e.g., cv2 → multiple opencv variants) using strategies |
| `exporter.py` | Generates requirements.txt, JSON, or simple list output |
| `database.py` | Builds SQLite mapping database from PyPI top packages; supports incremental updates and resume |

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
ImportInfo       # Parsed import with context (file, line, is_optional, is_relative)
MappingResult    # Module mapped to package candidates
PackageCandidate # Single package option with download count
AnalysisResult   # Complete analysis result with required/optional packages and stats

# Enums
ImportType       # STANDARD, FROM, DYNAMIC
ImportContext    # TOP_LEVEL, CONDITIONAL, TRY_EXCEPT, FUNCTION, CLASS
ResolveStrategy  # MOST_POPULAR, FIRST, ALL
```

### Mapping Data

- `mappings/hardcoded.py` - Classic mismatches (`CLASSIC_MISMATCHES`), PyWin32 modules (`PTH_INJECTED_MODULES`), and platform-specific packages (`PLATFORM_SPECIFIC`)
- `mappings/namespace.py` - Nested dict for `google.*`, `azure.*`, `zope.*`, `sphinxcontrib.*` namespaces

### Resolver Strategies

The `Resolver` class supports multiple strategies for handling one-to-many mappings:

1. **MOST_POPULAR** (default) - Choose package with highest download count
2. **FIRST** - Choose first candidate (recommended by hardcoded/namespace mappings)
3. **ALL** - Keep all candidates for manual selection

Platform-specific handling: Automatically selects correct package variant for Windows (pywin32), macOS, Linux, etc.

### Database Features (v0.3.0+)

- **Smart incremental updates** - Only downloads new packages when expanding database
- **Resume capability** - Can pause/resume database builds using `--resume`
- **Retry failed** - Target only failed packages with `--retry-failed`
- **Parallel processing** - 50 concurrent workers by default
- **Batch writes** - Optimized SQLite writes for 10-50x speedup
- **Progress tracking** - Saves progress every 100 packages
- **Graceful interrupts** - Ctrl+C saves progress before exiting

## Test Structure

- ~300 tests across 9 test files
- Each module has corresponding `test_<module>.py`
- `test_integration.py` contains end-to-end pipeline tests
- Sample project in `tests/fixtures/sample_project/`

**Test files:**
- `test_scanner.py` - File discovery and exclusion patterns
- `test_parser.py` - AST-based import extraction and context detection
- `test_filter.py` - Stdlib filtering and Python version handling
- `test_mappings.py` - Hardcoded and namespace package mappings
- `test_mapper.py` - Module-to-package mapping logic
- `test_resolver.py` - Conflict resolution strategies
- `test_exporter.py` - Output format generation
- `test_database.py` - Database operations and queries
- `test_integration.py` - End-to-end pipeline workflows

## Key Design Decisions

1. **Namespace packages take priority** over hardcoded mappings when submodules are present
2. **`from xxx import yyy`** only captures `xxx` as the module (cannot infer if `yyy` is a submodule)
3. **Conditional/try-except imports** are marked as `is_optional=True`
4. **Python version awareness** - stdlib list varies by target version; backport detection for `dataclasses`, `tomllib`, etc.
