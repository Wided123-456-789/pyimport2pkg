# PyImport2Pkg v0.3.0 Release Notes

**Release Date:** December 6, 2025

## 🎉 Overview

v0.3.0 represents a major performance and reliability upgrade focused on making large-scale database builds practical and user-friendly. With intelligent incremental updates, true parallel processing, batch database writes, and smart error recovery, building a comprehensive mapping database is now faster and more robust than ever.

**Key Highlights:**
- 🚀 10-50x faster database writes (batch processing)
- 📈 50x parallel concurrency (up from 20x)
- 💾 Seamless interrupt & resume capability
- 🧠 Intelligent incremental updates (smart delta logic)
- 🛡️ Rate limit detection & graceful handling
- ⚙️ Memory-optimized chunked processing for 15000+ packages

---

## ✨ New Features

### 1. **Intelligent Incremental Updates** (Default Behavior)

No need for manual tracking. Extend your database with a single command:

```bash
# Database has 500 packages, want to expand to 1000
pyimport2pkg build-db --max-packages 1000

# Output:
# Database contains 500 packages
# Target: top 1000 packages
# Will process 500 new packages only
```

**Why this matters:**
- Smart package matching (by name, not order)
- Safe expansion workflow
- Automatic recovery of previously failed packages
- No duplication, no data loss

**Use Cases:**
- Incrementally build larger databases
- Regular database maintenance and updates
- Add newly popular packages

---

### 2. **Build Progress Tracking**

Persistent build state with `BuildProgress` class:

- Track processed and failed packages
- Automatic progress snapshots
- Batch saves (every 100 packages) for performance
- Safe interruption and recovery

```python
from pyimport2pkg.database import get_build_progress

progress = get_build_progress()
status = progress.get_status()
# {'status': 'in_progress', 'total': 5000, 'processed': 2500, 'failed': 10, ...}
```

---

### 3. **Interrupt & Resume (--resume)**

Resume from the exact breakpoint:

```bash
# Start building
pyimport2pkg build-db --max-packages 14100

# Network issue? Interrupted?
# Later, simply resume (remembers your target):
pyimport2pkg build-db --resume
```

**Smart Recovery:**
- Automatically remembers `--max-packages` value
- Works with `--retry-failed` too
- No reprocessing of completed packages
- Data always safe

---

### 4. **Failed Package Retry (--retry-failed)**

Intelligently retry only failed packages from previous runs:

```bash
# First attempt: 5000 packages, 860 failed, 4140 succeeded
pyimport2pkg build-db --max-packages 5000

# Retry only the 860 that failed
pyimport2pkg build-db --retry-failed
# 834 succeed now, only 26 remain failed

# Try again
pyimport2pkg build-db --retry-failed
# Only 26 packages processed this time
```

**Smart Tracking:**
- Successful packages auto-removed from failed list
- Reduces retry time with each iteration
- Automatic --max-packages preservation

---

### 5. **Force Rebuild (--rebuild)**

Clean slate database construction:

```bash
# Delete old mapping.db and start fresh
pyimport2pkg build-db --rebuild --max-packages 5000
```

---

### 6. **Memory-Optimized Chunked Processing**

Handle 15000+ packages without memory bloat:

- Processes 500 packages per chunk
- Memory freed after each chunk completes
- Interrupt-safe: no chunk loss on resume
- Perfect for large-scale builds

```bash
# Build database with 20000 packages (memory efficient)
pyimport2pkg build-db --max-packages 20000 --concurrency 50
```

---

### 7. **Rate Limit Detection & Auto-Recovery**

Automatic detection and graceful handling of PyPI rate limits:

- Detects 20 consecutive failures as potential rate limiting
- Auto-pauses 30 seconds, then retries
- Up to 5 pause attempts before stopping
- Progress saved during pauses (safe to interrupt)

```
Detected 20 consecutive failures - possible rate limiting.
Pausing 30 seconds before retry (pause 1/5)...
Resuming...
```

---

### 8. **Performance Optimization**

#### Batch Database Writes
- 100 packages per batch commit (vs. one-at-a-time in v0.2.0)
- Uses `executemany()` for batch inserts
- SQLite WAL mode + optimized cache settings
- **Result: 10-50x faster writes**

#### Batch Progress Saves
- 100 packages per progress file update
- Immediate saves on interrupt/complete
- Balances safety and performance

#### Increased Concurrency
- Default concurrency: **50** (up from 20)
- Uses `httpx.Limits` for optimized connection pooling
- **Result: 2-3x faster package fetching**

---

### 9. **Graceful Interrupt Handling (Ctrl+C)**

Press Ctrl+C and the tool handles it elegantly:

```
^C
Saving progress, please wait... (Ctrl+C again to force quit)

Build interrupted. Processed 2500/5000 packages.
Use --resume to continue building, or --retry-failed to retry failures.
```

Progress is always saved safely.

---

### 10. **Build Status Command (NEW)**

Check current or last build status:

```bash
pyimport2pkg build-status

# Output:
# Build Status: in_progress
# Total: 5000
# Processed: 2500
# Failed: 12
# Success Rate: 99.5%
# Last Updated: 2025-12-06 10:30:45
```

---

### 11. **Timestamped Error Logs**

Error logs no longer overwrite each other:

```
data/
├── mapping.db
├── build_progress.json
├── build_errors_20251206_082307.json  (timestamp included)
└── build_errors_20251206_100000.json  (timestamp included)
```

---

## 📋 CLI Changes

### build-db Command Options

| Option | Description | Default |
|--------|-------------|---------|
| `--max-packages` | Target number of PyPI packages | 5000 |
| `--concurrency` | Number of parallel workers | **50** |
| `--resume` | Resume interrupted build | — |
| `--retry-failed` | Retry only failed packages | — |
| `--rebuild` | **NEW** Force rebuild (delete old DB) | — |
| `--db-path` | Custom database file path | `data/mapping.db` |

### Removed Options
- `--incremental` - No longer needed; intelligent incrementalism is now default

### New Command: build-status
```bash
pyimport2pkg build-status
```

---

## 📊 Performance Improvements

### Speed

| Operation | v0.2.0 | v0.3.0 | Improvement |
|-----------|--------|--------|-------------|
| 5000 packages | 50-100 min | 10-20 min | **5-10x** |
| Database writes | Per-package | Batch (100) | **10-50x** |
| Concurrency | 20x | 50x | **2.5x** |

### Memory Usage

| Dataset | Memory Footprint |
|---------|-----------------|
| 5000 packages | ~200 MB |
| 10000 packages | ~400 MB |
| 20000 packages | ~600 MB (chunked, not monolithic) |

---

## 🔄 Typical Workflows

### Build and Expand Incrementally

```bash
# Start small
pyimport2pkg build-db --max-packages 500

# Expand later (only new packages processed)
pyimport2pkg build-db --max-packages 5000

# Keep growing
pyimport2pkg build-db --max-packages 10000
```

### Robust Large-Scale Build

```bash
# Build 20000 packages with resume capability
pyimport2pkg build-db --max-packages 20000

# If interrupted:
pyimport2pkg build-db --resume

# If failures occur:
pyimport2pkg build-db --retry-failed
```

### Network Recovery

```bash
# Build starts
pyimport2pkg build-db --max-packages 5000

# Network issues → auto-detected and paused
# Auto-resume on timeout recovery

# Or manually retry failures
pyimport2pkg build-db --retry-failed
```

---

## 🧪 Testing

- **Total Test Cases:** 304 (↑ from 263)
- **New Test Cases:** 41
- **Test Coverage:** BuildProgress, batch operations, CLI options, chunked processing, rate limiting
- **Status:** All tests passing ✅

---

## 📝 Breaking Changes

⚠️ **Important for v0.2.0 Users:**

1. **`--incremental` option removed** - Use direct `--max-packages` instead
2. **Default concurrency increased to 50** - Faster, but uses more bandwidth
3. **Progress save frequency changed** - Now every 100 packages (was every package)

### Migration Guide

```bash
# OLD (v0.2.0)
pyimport2pkg build-db --max-packages 5000 --incremental

# NEW (v0.3.0)
pyimport2pkg build-db --max-packages 5000  # incremental is default now!

# Expand database
pyimport2pkg build-db --max-packages 10000  # smart delta applied automatically
```

---

## 🐛 Bug Fixes & Stability

- Fixed edge cases in incremental update logic
- Improved error handling for network timeouts
- Better memory cleanup in long-running builds
- More informative error messages for debugging

---

## 📚 Documentation Updates

- ✅ New comprehensive README.md
- ✅ Updated USER_GUIDE with all v0.3.0 features
- ✅ CLI help messages improved
- ✅ API documentation updated

---

## 🚀 Upgrade Instructions

### From v0.2.0

```bash
# Update via pip
pip install --upgrade pyimport2pkg

# Or reinstall from source
pip install -e ".[dev]"

# Verify installation
pyimport2pkg --version
# pyimport2pkg 0.3.0
```

**Recommended Actions:**
1. Backup existing `data/mapping.db` if valuable
2. Run `pyimport2pkg build-status` to check build state
3. Try `pyimport2pkg build-db --max-packages 5000` to rebuild efficiently

---

## 📋 What's Next? (v0.4.0 Roadmap)

- [ ] Conda environment detection and analysis
- [ ] Version constraint inference from code patterns
- [ ] `pyproject.toml` output format support
- [ ] Interactive candidate selection UI
- [ ] Custom mapping configuration file support
- [ ] Plugin system for third-party mapping providers

---

## 🙏 Thanks

This release includes improvements suggested by users encountering large-scale database builds. Special thanks to the community for feedback and testing!

---

## 📞 Support

- 📧 **Issues:** [GitHub Issues](https://github.com/buptanswer/pyimport2pkg/issues)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/buptanswer/pyimport2pkg/discussions)
- 🐛 **Bug Reports:** [Bug Tracker](https://github.com/buptanswer/pyimport2pkg/issues)

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details

---

**Made with ❤️ for the AI-assisted coding era**

*PyImport2Pkg v0.3.0 - Released December 6, 2025*
