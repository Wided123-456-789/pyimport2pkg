# GitHub Project Configuration for PyImport2Pkg

## Repository Settings

### About Section

**Description:**
```
🐍 Reverse mapping tool: from Python import statements to pip package names. Perfect for AI-generated code!
```

**Website:**
```
https://pypi.org/project/pyimport2pkg/
```

**Topics (Keywords):**
```
python
pip
package-manager
dependencies
import
requirements
packaging
pypi
developer-tools
ai-coding
code-analysis
dependency-management
module-mapping
reverse-mapping
static-analysis
```

---

## Repository Features

Enable the following features:

- ✅ Issues
- ✅ Projects
- ✅ Wiki (optional)
- ✅ Discussions (recommended for Q&A)
- ✅ Sponsorships (if applicable)

---

## Social Preview

**Image recommendation:** Create a 1280x640px banner with:
- PyImport2Pkg logo/name
- Tagline: "Python Import → Pip Package"
- Example: `import cv2` → `opencv-python`

---

## README Badges

Current badges in README.md:
- Python 3.10+
- MIT License
- Latest Release v1.0.0

Consider adding:
- PyPI Downloads: `![PyPI - Downloads](https://img.shields.io/pypi/dm/pyimport2pkg)`
- PyPI Version: `![PyPI](https://img.shields.io/pypi/v/pyimport2pkg)`
- GitHub Stars: `![GitHub stars](https://img.shields.io/github/stars/buptanswer/pyimport2pkg)`
- Tests: `![Tests](https://img.shields.io/badge/tests-304%20passed-brightgreen)`

---

## Release Configuration

### v1.0.0 Release

**Title:**
```
v1.0.0 - First Stable Release 🎉
```

**Tag:**
```
v1.0.0
```

**Target:** `master` branch

**Release Notes:** Use content from `RELEASE_v1.0.0.md`

**Assets:** Automatically included from git tag

---

## GitHub Actions (Optional)

Consider setting up:

1. **Tests on PR/Push**
   ```yaml
   - Run pytest on Python 3.10, 3.11, 3.12, 3.13
   - Check code style
   - Run type checking
   ```

2. **Auto-publish to PyPI**
   ```yaml
   - Trigger on new tag `v*.*.*`
   - Build and publish to PyPI
   ```

3. **Auto-generate Release Notes**
   ```yaml
   - Extract changes from CHANGELOG
   - Post to GitHub Releases
   ```

---

## Community Files

Already have:
- ✅ README.md (English)
- ✅ README.zh_CN.md (Chinese)
- ✅ LICENSE (MIT)

Consider adding:
- `CONTRIBUTING.md` - How to contribute
- `CODE_OF_CONDUCT.md` - Community guidelines
- `SECURITY.md` - Security policy
- `.github/ISSUE_TEMPLATE/` - Issue templates
- `.github/PULL_REQUEST_TEMPLATE.md` - PR template

---

## Branch Protection (Recommended)

For `master` branch:
- ✅ Require pull request reviews before merging
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ✅ Include administrators

---

## Labels

Recommended labels:

**Type:**
- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Improvements or additions to documentation
- `question` - Further information is requested

**Priority:**
- `priority: high` - High priority
- `priority: medium` - Medium priority
- `priority: low` - Low priority

**Status:**
- `wontfix` - This will not be worked on
- `duplicate` - This issue or pull request already exists
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention is needed

**Area:**
- `area: cli` - CLI related
- `area: api` - Python API related
- `area: database` - Database building
- `area: mapping` - Module-to-package mapping

---

## Project Board (Optional)

Create a project board for issue tracking:

Columns:
1. 📋 **To Do** - Planned features/fixes
2. 🚧 **In Progress** - Currently working on
3. 👀 **Review** - Awaiting review
4. ✅ **Done** - Completed

---

## Discussions Categories

Recommended categories:

1. **💬 General** - General discussions
2. **💡 Ideas** - Feature requests and ideas
3. **🙏 Q&A** - Questions and answers
4. **📣 Announcements** - Project announcements
5. **🎉 Show and Tell** - Share your usage

---

## Package Settings

On PyPI (https://pypi.org/project/pyimport2pkg/):

**Project Links:**
- Homepage: `https://github.com/buptanswer/pyimport2pkg`
- Documentation: `https://github.com/buptanswer/pyimport2pkg/blob/master/README.md`
- Bug Tracker: `https://github.com/buptanswer/pyimport2pkg/issues`
- Changelog: `https://github.com/buptanswer/pyimport2pkg/blob/master/documents/CHANGELOG/`
- Source Code: `https://github.com/buptanswer/pyimport2pkg`

---

## README Improvements (Optional)

Consider adding sections:

1. **Star History** - Show growth
2. **Contributors** - Thank contributors
3. **Sponsors** - If applicable
4. **Similar Projects** - Comparison with alternatives
5. **Citation** - How to cite in academic work

---

*This document provides configuration guidelines for maintaining the PyImport2Pkg GitHub repository.*
