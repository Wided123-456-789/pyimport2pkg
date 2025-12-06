# PyImport2Pkg v1.0.0 User Guide

> Reverse mapping tool: from Python import statements to pip package names

## Table of Contents

- [Introduction](#introduction)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Commands](#commands)
  - [analyze - Analyze Project](#analyze---analyze-project)
  - [query - Query Mapping](#query---query-mapping)
  - [build-db - Build Database](#build-db---build-database)
  - [build-status - Build Status](#build-status---build-status)
  - [db-info - Database Info](#db-info---database-info)
- [Output Formats](#output-formats)
- [Advanced Usage](#advanced-usage)
- [Python API](#python-api)
- [FAQ](#faq)

---

## Introduction

PyImport2Pkg solves a common problem: **Given import statements in Python code, how do you know which pip package to install?**

For example:
- `import cv2` → need to install `opencv-python`
- `from PIL import Image` → need to install `Pillow`
- `import sklearn` → need to install `scikit-learn`

### Core Features

1. **Project Analysis**: Scan entire projects and generate requirements.txt
2. **Smart Mapping**: Handle cases where module name ≠ package name
3. **Namespace Support**: Correctly handle `google.cloud.*`, `azure.*`, etc.
4. **Optional Dependencies**: Distinguish required vs optional dependencies (try-except, platform checks)
5. **Python Version Aware**: Auto-detect target Python version, handle backports
6. **High-Performance Database**: Smart incremental updates, parallel processing, batch writes

---

## Installation

### From PyPI (Recommended)

```bash
pip install pyimport2pkg
```

### From Source

```bash
git clone https://github.com/buptanswer/pyimport2pkg.git
cd pyimport2pkg
pip install -e ".[dev]"
```

### Verify Installation

```bash
pyimport2pkg --version
# pyimport2pkg 1.0.0
```

---

## Quick Start

### 1. Analyze a Project

```bash
# Analyze current directory
pyimport2pkg analyze .

# Output will show:
# Analyzing: .
# Found imports from 24 files
#
# Dependencies:
#   numpy
#   pandas
#   requests
#   ...
```

### 2. Generate requirements.txt

```bash
pyimport2pkg analyze . -o requirements.txt
```

### 3. Query a Single Module

```bash
pyimport2pkg query cv2

# Output:
# Module: cv2
# Source: hardcoded
# Candidates:
#   1. opencv-python (recommended)
#   2. opencv-contrib-python
#   3. opencv-python-headless
```

---

## Commands

### analyze - Analyze Project

Scan a Python project for imports and identify required packages.

```bash
pyimport2pkg analyze <path> [options]
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `-o, --output` | Output file path | stdout |
| `-f, --format` | Format (requirements\|json\|simple) | requirements |
| `--python-version` | Target Python version | current |
| `--exclude` | Directories to exclude | - |
| `--exclude-optional` | Exclude optional packages | False |
| `--no-comments` | Disable comments in output | False |

**Examples:**

```bash
# Basic analysis
pyimport2pkg analyze /path/to/project

# Specify target Python version
pyimport2pkg analyze . --python-version 3.11

# Save as JSON
pyimport2pkg analyze . -o deps.json -f json

# Exclude test directories
pyimport2pkg analyze . --exclude tests,docs

# Simple package list (no comments)
pyimport2pkg analyze . -f simple
```

---

### query - Query Mapping

Look up which package provides a specific module.

```bash
pyimport2pkg query <module_name>
```

**Examples:**

```bash
# Query a module
pyimport2pkg query cv2

# Query namespace package
pyimport2pkg query google.cloud.storage
```

---

### build-db - Build Database

Build or update the module-to-package mapping database from PyPI.

```bash
pyimport2pkg build-db [options]
```

**Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--max-packages` | Maximum packages to process | 5000 |
| `--concurrency` | Number of concurrent requests | 50 |
| `--resume` | Resume interrupted build | False |
| `--retry-failed` | Retry only failed packages | False |
| `--rebuild` | Force rebuild from scratch | False |
| `--db-path` | Custom database path | data/mapping.db |

**Examples:**

```bash
# Build database with top 5000 packages
pyimport2pkg build-db --max-packages 5000

# Expand existing database to 10000 packages (only processes new ones)
pyimport2pkg build-db --max-packages 10000

# Resume interrupted build
pyimport2pkg build-db --resume

# Retry failed packages
pyimport2pkg build-db --retry-failed

# Force rebuild
pyimport2pkg build-db --rebuild --max-packages 5000
```

---

### build-status - Build Status

Check the status of database building.

```bash
pyimport2pkg build-status
```

**Example Output:**

```
Build Status:
  Status: completed
  Total packages: 5000
  Processed: 5000
  Failed: 15
  Started at: 2025-12-06T10:00:00
  Last updated: 2025-12-06T12:30:45
```

---

### db-info - Database Info

Display database statistics.

```bash
pyimport2pkg db-info
```

**Example Output:**

```
Database: data/mapping.db
Total packages: 5000
Module mappings: 12543
Last build: 2025-12-06T12:30:45
Source: https://hugovk.github.io/top-pypi-packages/top-pypi-packages-30-days.min.json
```

---

## Output Formats

### 1. requirements.txt (Default)

```bash
pyimport2pkg analyze . -o requirements.txt
```

**Output:**

```
# Auto-generated by pyimport2pkg
# Generated at: 2025-12-06T15:30:00

# === Required packages ===
numpy
pandas
requests

# === Conditional imports (platform/environment specific) ===
pywin32  # conditional

# === Try-except imports (optional dependencies) ===
ujson  # try_except
```

### 2. JSON Format

```bash
pyimport2pkg analyze . -f json -o dependencies.json
```

**Output:**

```json
{
  "meta": {
    "generated_at": "2025-12-06T15:30:00",
    "tool": "pyimport2pkg",
    "version": "1.0.0"
  },
  "required": [
    {
      "package": "numpy",
      "module": "numpy",
      "source": "database"
    }
  ],
  "optional": [],
  "unresolved": [],
  "warnings": []
}
```

### 3. Simple List

```bash
pyimport2pkg analyze . -f simple
```

**Output:**

```
numpy
pandas
requests
```

---

## Advanced Usage

### 1. Target Specific Python Version

```bash
# Analyze for Python 3.8 (will include backports)
pyimport2pkg analyze . --python-version 3.8

# This will include packages like:
# - dataclasses (built-in in 3.7+)
# - importlib-metadata (built-in in 3.8+)
```

### 2. Exclude Optional Dependencies

```bash
# Only show required dependencies
pyimport2pkg analyze . --exclude-optional
```

### 3. Custom Exclusions

```bash
# Exclude test and documentation directories
pyimport2pkg analyze . --exclude tests,docs,examples
```

### 4. Incremental Database Updates

```bash
# Start with top 500 packages
pyimport2pkg build-db --max-packages 500

# Later, expand to 5000 (automatically skips existing 500)
pyimport2pkg build-db --max-packages 5000

# Further expand to 10000
pyimport2pkg build-db --max-packages 10000
```

### 5. Handle Build Interruptions

```bash
# Start building
pyimport2pkg build-db --max-packages 15000

# Press Ctrl+C if needed
# System saves progress automatically

# Resume later
pyimport2pkg build-db --resume
```

---

## Python API

### Basic Usage

```python
from pyimport2pkg import Scanner, Parser, Filter, Mapper, Exporter
from pathlib import Path

# 1. Scan project
scanner = Scanner()
files = scanner.scan(Path("./my_project"))

# 2. Parse imports
parser = Parser()
imports = []
for file_path in files:
    imports.extend(parser.parse_file(file_path))

# 3. Filter stdlib & local modules
filter = Filter(project_root=Path("./my_project"))
third_party, _ = filter.filter_imports(imports)

# 4. Map to packages
mapper = Mapper()
results = mapper.map_imports(third_party)

# 5. Export results
exporter = Exporter()
exporter.export_requirements_txt(results, output=Path("requirements.txt"))
```

### Query Single Module

```python
from pyimport2pkg import Mapper, ImportInfo

mapper = Mapper()
imp = ImportInfo.from_module_name("cv2")
result = mapper.map_import(imp)

for candidate in result.candidates:
    print(f"{candidate.package_name}: {candidate.download_count} downloads")
```

### Using Database

```python
from pyimport2pkg.database import MappingDatabase

db = MappingDatabase("data/mapping.db")
results = db.lookup("cv2")

for pkg_name, downloads in results:
    print(f"{pkg_name}: {downloads}")

db.close()
```

### Advanced: Custom Resolution Strategy

```python
from pyimport2pkg import Resolver, ResolveStrategy

resolver = Resolver(strategy=ResolveStrategy.ALL)
resolved = resolver.resolve_mappings(results)
# Returns all candidates instead of just the most popular
```

---

## FAQ

### Q: How does PyImport2Pkg handle module name mismatches?

**A:** PyImport2Pkg uses a priority system:

1. **Namespace packages** (if submodules exist) - e.g., `google.cloud.storage` → `google-cloud-storage`
2. **Hardcoded mappings** - Known mismatches like `cv2` → `opencv-python`
3. **Namespace packages** (top-level only)
4. **Database lookup** - From PyPI wheel `top_level.txt`
5. **Guess** - Assume module name equals package name

### Q: What if the database doesn't have a package?

**A:** PyImport2Pkg will:
1. Check hardcoded mappings first
2. Check namespace packages
3. Fall back to guessing (module name = package name)
4. Add a warning to review the guess

### Q: How do I update the database?

**A:** Simply run:
```bash
pyimport2pkg build-db --max-packages <new_count>
```

The tool automatically detects existing packages and only processes new ones.

### Q: Can I use my own database?

**A:** Yes! Use the `--db-path` option:

```bash
pyimport2pkg analyze . --db-path /path/to/custom.db
```

### Q: How are optional dependencies detected?

**A:** PyImport2Pkg analyzes import context:
- **try-except blocks** → optional
- **if platform.system()** → conditional
- **if TYPE_CHECKING** → type-checking only
- **Function/class level** → may be optional

### Q: Does it support Python 2?

**A:** No. PyImport2Pkg requires Python 3.10+.

### Q: How accurate is the mapping?

**A:** Very high for popular packages:
- Top 5000 PyPI packages: ~99% accurate
- Hardcoded mappings: 100% accurate (manually curated)
- Namespace packages: 100% accurate (follows PEP 420)

### Q: Can I contribute mappings?

**A:** Yes! Add to `src/pyimport2pkg/mappings/hardcoded.py` and submit a PR.

---

## Troubleshooting

### Issue: "No build records found"

**Solution:** Run `build-db` first to create the database.

### Issue: Rate limiting from PyPI

**Solution:** The tool automatically detects and pauses. If it persists, reduce `--concurrency`:

```bash
pyimport2pkg build-db --concurrency 20
```

### Issue: Out of memory during large builds

**Solution:** The tool uses chunked processing. For very large builds (15000+), ensure 4GB+ RAM available.

### Issue: Import not found

**Solution:**
1. Check if it's a local module (should be excluded)
2. Try `query` command to see mapping: `pyimport2pkg query <module>`
3. If incorrect, report an issue on GitHub

---

## What's New in v1.0.0

**First Stable Release!**

- ✅ Full internationalization (English CLI output)
- ✅ Stable API with root-level imports
- ✅ Dynamic versioning in exports
- ✅ Complete JSON export with unresolved imports
- ✅ Comprehensive documentation
- ✅ Production/Stable status

See [CHANGELOG](../CHANGELOG/CHANGELOG_v1.0.0.md) for details.

---

**Need Help?**

- 📖 [README](../../README.md)
- 🐛 [Report Issues](https://github.com/buptanswer/pyimport2pkg/issues)
- 💬 [Discussions](https://github.com/buptanswer/pyimport2pkg/discussions)

---

*PyImport2Pkg v1.0.0 - December 2025*
