# PyImport2Pkg v1.0.0 Release Notes

**Release Date**: 2025-12-06

## Overview

v1.0.0 is the first stable release of PyImport2Pkg. This release focuses on internationalization, API stability, documentation accuracy, and bug fixes to ensure a production-ready tool for the global developer community.

---

## Key Changes

### 1. Internationalization - English Output

All CLI output has been translated from Chinese to English for better international accessibility:

```bash
# Before (v0.3.0)
构建状态:
  状态: completed
  总包数: 5000

# After (v1.0.0)
Build Status:
  Status: completed
  Total packages: 5000
```

Affected areas:
- `build-db` command output
- `build-status` command output
- Progress messages during database building
- Error messages and warnings
- Rate limit detection messages
- Requirements.txt section headers

### 2. API Stability - Public Class Exports

Core classes are now exported from the package root for easier API usage:

```python
# Now available from package root
from pyimport2pkg import (
    Scanner, scan_project,
    Parser,
    Filter,
    Mapper,
    Resolver, ResolveStrategy,
    Exporter,
    # Models
    ImportInfo, ImportType, ImportContext,
    MappingResult, PackageCandidate, AnalysisResult,
)
```

### 3. Dynamic Version in JSON Export

Fixed hardcoded version "0.2.0" in JSON export. Now uses dynamic `__version__`:

```python
# Before
"version": "0.2.0"  # Hardcoded

# After
"version": "1.0.0"  # Dynamic from __version__
```

### 4. JSON Export Now Includes Unresolved Imports

Fixed missing `unresolved` parameter in JSON export. Unresolved imports (syntax errors, dynamic imports) are now properly included in JSON output.

### 5. Documentation Accuracy

Fixed several inaccuracies in README Python API examples:

| Before | After |
|--------|-------|
| `parser.parse(file)` | `parser.parse_file(file)` |
| `filter.filter(imports)` | `filter.filter_imports(imports)` |
| `mapper.map(imports)` | `mapper.map_imports(imports)` |
| `mapper.map_single("cv2")` | `mapper.map_import(ImportInfo.from_module_name("cv2"))` |
| `exporter.to_requirements_txt()` | `exporter.export_requirements_txt()` |

Fixed CLI documentation:
| Before | After |
|--------|-------|
| `-f, --format (txt\|json\|simple)` | `-f, --format (requirements\|json\|simple)` |
| `-t, --target-version` | `--python-version` |

### 6. Code Quality Improvements

- Removed unused `Path` import from mapper.py
- Fixed comment numbering in mapper.py (steps 1-5 now correctly numbered)
- Updated docstring in mapper.py to accurately reflect mapping priority order
- Fixed test assertions to use dynamic version instead of hardcoded strings

---

## Breaking Changes

None. v1.0.0 is fully backward compatible with v0.3.0 for CLI usage.

**API Note**: If you were importing classes directly from submodules, you can now import from the package root:

```python
# Old (still works)
from pyimport2pkg.scanner import Scanner
from pyimport2pkg.parser import Parser

# New (recommended)
from pyimport2pkg import Scanner, Parser
```

---

## Mapping Priority (Clarified)

The Mapper now correctly documents its priority order:

1. **Namespace packages** (if submodules exist) - e.g., `google.cloud.storage` → `google-cloud-storage`
2. **Hardcoded mappings** - Known mismatches like `cv2` → `opencv-python`
3. **Namespace packages** (top-level only) - e.g., `import google`
4. **Database lookup** - From PyPI wheel `top_level.txt`
5. **Guess** - Assume module name equals package name

---

## Development Status

Changed from "Alpha" to "Production/Stable" in package classifiers, reflecting the maturity and stability of this release.

---

## Test Results

- **Total tests**: 304
- **All passing**: Yes
- **Test coverage**: Comprehensive coverage of all core modules

---

## Upgrade Guide

### From v0.3.0

Simply upgrade via pip:

```bash
pip install --upgrade pyimport2pkg
```

No configuration or code changes required.

### For API Users

If you encounter `ImportError` when using the old import style, update your imports:

```python
# If this fails:
from pyimport2pkg import Scanner  # Now works in v1.0.0!

# Previously required:
from pyimport2pkg.scanner import Scanner
```

---

## What's Next

Potential features for future versions:
- Conda environment detection
- Version constraint inference
- pyproject.toml output format
- Interactive candidate selection
- Custom mapping configuration files

---

## Acknowledgments

Thank you to all users who provided feedback during the v0.x development cycle. Your input helped shape this stable release.

---

*PyImport2Pkg v1.0.0 - First Stable Release - December 2025*
