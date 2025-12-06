# 🎉 PyImport2Pkg v1.0.0 - First Stable Release

**Release Date:** December 6, 2025

We're excited to announce the first stable release of PyImport2Pkg! This release marks the transition from alpha to production-ready status, with comprehensive internationalization, API stability improvements, and bug fixes.

---

## 🌟 What is PyImport2Pkg?

PyImport2Pkg solves a common problem in the AI-assisted coding era:

> **Given Python code with import statements, quickly identify which pip packages need to be installed.**

```python
import cv2           # → pip install opencv-python
from PIL import Image  # → pip install Pillow
import sklearn       # → pip install scikit-learn
```

Perfect for when AI generates code with lots of imports and you need to set up dependencies!

---

## ✨ Highlights of v1.0.0

### 🌍 Full Internationalization
All CLI output has been translated from Chinese to English for better international accessibility.

**Before (v0.3.0):**
```
构建状态:
  状态: completed
  总包数: 5000
```

**After (v1.0.0):**
```
Build Status:
  Status: completed
  Total packages: 5000
```

### 📦 Stable Python API
Core classes are now exported from the package root for easier imports:

```python
# Now you can do:
from pyimport2pkg import Scanner, Parser, Filter, Mapper, Exporter

# Instead of:
from pyimport2pkg.scanner import Scanner
from pyimport2pkg.parser import Parser
# ...
```

### 🔧 Bug Fixes

1. **Dynamic Version in JSON Export** - Fixed hardcoded "0.2.0" in JSON export metadata
2. **Complete JSON Export** - Unresolved imports now properly included in JSON output
3. **Documentation Accuracy** - Fixed all Python API examples in README
4. **CLI Documentation** - Corrected parameter names (`--python-version`, `requirements` format)

### 📚 Production Ready

- Development Status: **Alpha → Production/Stable**
- All 304 tests passing
- Comprehensive documentation
- English + Chinese README

---

## 📥 Installation

```bash
pip install pyimport2pkg
```

Or upgrade from earlier versions:

```bash
pip install --upgrade pyimport2pkg
```

---

## 🚀 Quick Start

```bash
# Analyze a project
pyimport2pkg analyze /path/to/project

# Generate requirements.txt
pyimport2pkg analyze . -o requirements.txt

# Query a specific module
pyimport2pkg query cv2
```

---

## 📋 What's Changed

### Code Changes
- Update version to 1.0.0
- Internationalize all CLI output (Chinese → English)
- Export core classes from package root (`__init__.py`)
- Fix dynamic version in JSON export (was hardcoded 0.2.0)
- Fix missing `unresolved` parameter in JSON export
- Fix mapper.py documentation and comment numbering
- Remove unused `Path` import from mapper.py
- Update development status to Production/Stable

### Documentation
- Fix README Python API examples (correct method names)
- Fix README CLI documentation (`--python-version`, `requirements` format)
- Update both English and Chinese READMEs
- Add comprehensive v1.0.0 changelog
- Create v1.0.0 user guide

### Testing
- All 304 tests passing
- Updated test assertions to use dynamic version

---

## 📖 Documentation

- **User Guide:** [USER_GUIDE_v1.0.0.md](documents/USER_GUIDE/USER_GUIDE_v1.0.0.md)
- **Changelog:** [CHANGELOG_v1.0.0.md](documents/CHANGELOG/CHANGELOG_v1.0.0.md)
- **README:** [English](README.md) | [中文](README.zh_CN.md)

---

## 🔄 Upgrade Guide

### From v0.3.0

Simply upgrade via pip - **fully backward compatible**:

```bash
pip install --upgrade pyimport2pkg
```

No configuration or code changes required for CLI usage.

### For Python API Users

If you import classes from submodules, you can now use the cleaner root imports:

```python
# Old (still works)
from pyimport2pkg.scanner import Scanner

# New (recommended)
from pyimport2pkg import Scanner
```

---

## 🙏 Acknowledgments

Thank you to everyone who tested the v0.x releases and provided feedback. Your input helped shape this stable release!

---

## 🔗 Links

- **PyPI:** https://pypi.org/project/pyimport2pkg/
- **GitHub:** https://github.com/buptanswer/pyimport2pkg
- **Issues:** https://github.com/buptanswer/pyimport2pkg/issues
- **Documentation:** See README.md

---

## 📦 Release Assets

- Source code (zip)
- Source code (tar.gz)
- PyPI packages: `pyimport2pkg-1.0.0.tar.gz` and `pyimport2pkg-1.0.0-py3-none-any.whl`

---

**Full Changelog:** v0.3.0...v1.0.0

Made with ❤️ for developers using AI code generators

🤖 *This release was prepared with assistance from [Claude Code](https://claude.com/claude-code)*
