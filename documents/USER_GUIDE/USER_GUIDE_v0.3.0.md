# PyImport2Pkg v0.3.0 使用说明

> Python 导入语句到 pip 包名的反向映射工具

## 目录

- [简介](#简介)
- [安装](#安装)
- [快速开始](#快速开始)
- [命令详解](#命令详解)
  - [analyze - 分析项目](#analyze---分析项目)
  - [query - 查询映射](#query---查询映射)
  - [build-db - 构建数据库](#build-db---构建数据库)
  - [build-status - 构建状态](#build-status---构建状态)
  - [db-info - 数据库信息](#db-info---数据库信息)
- [输出格式](#输出格式)
- [高级用法](#高级用法)
- [Python API](#python-api)
- [常见问题](#常见问题)

---

## 简介

PyImport2Pkg 解决了一个常见问题：**给定 Python 代码中的 import 语句，如何知道需要安装哪个 pip 包？**

例如：
- `import cv2` → 需要安装 `opencv-python`
- `from PIL import Image` → 需要安装 `Pillow`
- `import sklearn` → 需要安装 `scikit-learn`

### 核心功能

1. **项目分析**: 扫描整个项目，生成 requirements.txt
2. **智能映射**: 处理模块名与包名不一致的情况
3. **命名空间支持**: 正确处理 `google.cloud.*`、`azure.*` 等命名空间包
4. **可选依赖识别**: 区分必需依赖和可选依赖（try-except、平台判断等）
5. **Python 版本感知**: 自动检测目标 Python 版本，处理 backports
6. **高性能数据库构建**: 智能增量更新、真正的并行处理、批量写入

---

## 安装

```bash
# 开发模式安装
pip install -e ".[dev]"

# 或直接安装
pip install pyimport2pkg
```

验证安装：

```bash
pyimport2pkg --version
# pyimport2pkg 0.3.0
```

---

## 快速开始

### 分析当前项目

```bash
# 分析当前目录，输出到终端
pyimport2pkg analyze .

# 分析并保存到文件
pyimport2pkg analyze . -o requirements.txt
```

### 查询单个模块

```bash
# 查询 cv2 对应的包
pyimport2pkg query cv2

# 输出:
# Module: cv2
# Source: hardcoded
# Candidates:
#   1. opencv-python (recommended)
#   2. opencv-contrib-python
#   3. opencv-python-headless
```

### 构建映射数据库

```bash
# 构建数据库（支持中断恢复）
pyimport2pkg build-db --max-packages 5000

# 查看构建状态
pyimport2pkg build-status
```

---

## 命令详解

### analyze - 分析项目

分析 Python 项目中的所有导入语句，生成依赖列表。

#### 基本语法

```bash
pyimport2pkg analyze <path> [options]
```

#### 参数说明

| 参数 | 简写 | 说明 | 默认值 |
|------|------|------|--------|
| `path` | - | 要分析的文件或目录路径 | 必需 |
| `--output` | `-o` | 输出文件路径 | 输出到终端 |
| `--format` | `-f` | 输出格式: `requirements`/`json`/`simple` | `requirements` |
| `--exclude` | - | 排除的目录（逗号分隔） | 无 |
| `--exclude-optional` | - | 排除可选依赖 | 包含可选依赖 |
| `--python-version` | - | 目标 Python 版本（如 3.8） | 自动检测 |
| `--no-comments` | - | 不输出注释 | 输出注释 |
| `--use-database` | - | 使用本地映射数据库 | 不使用 |

#### 使用示例

```bash
# 基本分析
pyimport2pkg analyze ./myproject

# 排除测试目录
pyimport2pkg analyze . --exclude tests,docs

# 输出 JSON 格式
pyimport2pkg analyze . -f json -o deps.json

# 指定 Python 版本（影响 backports 检测）
pyimport2pkg analyze . --python-version 3.8

# 只输出必需依赖（排除 try-except 等可选导入）
pyimport2pkg analyze . --exclude-optional

# 使用数据库增强映射精度
pyimport2pkg analyze . --use-database

# 简洁输出（无注释，适合管道处理）
pyimport2pkg analyze . --no-comments -f simple
```

---

### query - 查询映射

查询单个模块名对应的包名。

#### 基本语法

```bash
pyimport2pkg query <module_name>
```

#### 使用示例

```bash
# 查询经典不匹配
pyimport2pkg query PIL
# Module: PIL
# Source: hardcoded
# Candidates:
#   1. Pillow (recommended)

# 查询命名空间包
pyimport2pkg query google.cloud.storage
# Module: google.cloud.storage
# Source: namespace
# Candidates:
#   1. google-cloud-storage (recommended)

# 查询 PyWin32 模块
pyimport2pkg query win32api
# Module: win32api
# Source: pth_injected
# Candidates:
#   1. pywin32 (recommended)
```

---

### build-db - 构建数据库

从 PyPI 下载热门包信息，构建本地映射数据库。**v0.3.0 默认智能增量更新，支持中断恢复、失败重试。**

#### 基本语法

```bash
pyimport2pkg build-db [options]
```

#### 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--max-packages` | 目标包数量 | 5000 |
| `--concurrency` | 并发下载数 | 50 |
| `--resume` | 恢复中断的构建 | 否 |
| `--retry-failed` | 只重试失败的包 | 否 |
| `--rebuild` | 强制重建（删除旧数据库） | 否 |
| `--db-path` | 数据库文件路径 | 默认位置 |

#### 使用示例

```bash
# 构建数据库（智能增量：自动跳过已有的包）
pyimport2pkg build-db --max-packages 5000

# 扩展现有数据库（无需额外参数）
# 已有 1000 个包，扩展到 5000 个，只处理新的 4000 个
pyimport2pkg build-db --max-packages 5000

# 从中断处恢复（Ctrl+C 或意外中断后）
pyimport2pkg build-db --resume

# 只重试失败的包
pyimport2pkg build-db --retry-failed

# 强制重建（删除现有数据库）
pyimport2pkg build-db --rebuild --max-packages 5000
```

#### 中断和恢复

构建过程中按 Ctrl+C 可以优雅中断：

```
^C
正在保存进度，请稍候... (再次按 Ctrl+C 强制退出)

构建已中断。已处理 2500/5000 个包。
使用 --resume 继续构建，或 --retry-failed 重试失败的包。
```

恢复选项：

```bash
# 继续处理未完成的包
pyimport2pkg build-db --resume

# 只重试失败的包（适合网络临时问题）
pyimport2pkg build-db --retry-failed
```

#### 速率限制检测

工具会自动检测 PyPI 的速率限制并暂停：

```
检测到连续 20 次失败，可能遇到速率限制。
暂停 30 秒后重试 (第 1/5 次暂停)...
继续处理...
```

- 连续 20 次失败时触发暂停
- 自动暂停 30 秒后重试
- 最多暂停 5 次
- 超过后停止构建，可使用 `--resume` 继续

#### 内存优化

工具使用分块处理减少内存占用：

- 每 500 个包为一个分块
- 适合大规模构建（15000+ 包）
- 每个分块处理完成后释放内存

#### 输出说明

```
Building database at ~/.pyimport2pkg/data/mapping.db...
Fetching top 5000 packages from PyPI...
  [100/5000] Processing requests...
  [200/5000] Processing numpy...
  ...

Database built successfully!
  Total packages: 5000
  Successful: 4850
  Failed: 150

Error breakdown:
  - timeout: 80
  - not_found: 45
  - http_error: 25

Detailed error log: ~/.pyimport2pkg/data/build_errors_20251205_143000.json
```

---

### build-status - 构建状态

**v0.3.0 新增命令**。显示当前数据库构建的状态信息。

#### 基本语法

```bash
pyimport2pkg build-status
```

#### 输出示例

**无构建记录时**：
```
没有构建记录。
```

**构建进行中/中断时**：
```
构建状态:
  状态: interrupted
  总包数: 5000
  已处理: 2500
  失败数: 10
  开始时间: 2025-12-05T10:00:00
  最后更新: 2025-12-05T10:15:00

未处理: 2500 个包

可用命令:
  pyimport2pkg build-db --resume        # 继续处理
  pyimport2pkg build-db --retry-failed  # 重试失败的包

失败的包 (前10个):
  - torch
  - tensorflow
  - opencv-python-headless
  ...
```

**构建完成时**：
```
构建状态:
  状态: completed
  总包数: 5000
  已处理: 5000
  失败数: 150
  开始时间: 2025-12-05T10:00:00
  最后更新: 2025-12-05T11:30:00
```

---

### db-info - 数据库信息

显示本地映射数据库的统计信息。

#### 使用示例

```bash
pyimport2pkg db-info
```

#### 输出示例

```
Database Information:
  Path: ~/.pyimport2pkg/data/mapping.db
  Packages: 4850
  Module mappings: 15230
  Unique modules: 12500
  Last updated: 2025-12-05 10:30:00
```

---

## 输出格式

### requirements 格式（默认）

```text
# Auto-generated by pyimport2pkg
# Generated at: 2025-12-05T10:30:00

# === Required packages ===
numpy
pandas
requests
scikit-learn

# === Conditional imports (if块内，平台/环境相关) ===
pywin32  # conditional in utils.py:15

# === Try-except imports (可选依赖，有替代方案) ===
ujson  # try_except in main.py:8
orjson  # try_except in main.py:12

# === Packages with multiple candidates ===
# cv2 -> opencv-python (10.5M downloads)
#   alternatives: opencv-contrib-python (2.1M), opencv-python-headless (1.8M)

# === Errors (需要手动检查) ===
# [Syntax Error] broken.py:10 - invalid syntax
# [Dynamic Import] utils.py:25 - Dynamic import with non-literal argument

# === Warnings ===
# - Package name 'custom_lib' was guessed. Please verify it's correct.
```

#### 各 Section 说明

| Section | 说明 |
|---------|------|
| Required packages | 顶层无条件导入的包 |
| Conditional imports | `if` 块内的导入（通常是平台/环境相关） |
| Try-except imports | `try-except` 块内的导入（有替代方案的可选依赖） |
| Multiple candidates | 一个模块对应多个可能的包（需要用户选择） |
| Errors | 解析错误（语法错误、动态导入等） |
| Warnings | 包名是猜测的，建议验证 |

---

### json 格式

```bash
pyimport2pkg analyze . -f json
```

```json
{
  "meta": {
    "tool": "pyimport2pkg",
    "version": "0.3.0",
    "generated_at": "2025-12-05T10:30:00"
  },
  "required": [
    {
      "package": "numpy",
      "module": "numpy",
      "source": "guessed",
      "files": ["main.py:1", "utils.py:3"]
    },
    {
      "package": "Pillow",
      "module": "PIL",
      "source": "hardcoded",
      "alternatives": [],
      "files": ["image_utils.py:5"]
    }
  ],
  "optional": [
    {
      "package": "ujson",
      "module": "ujson",
      "context": "try_except",
      "source": "guessed",
      "files": ["main.py:8"]
    }
  ],
  "unresolved": [],
  "warnings": [
    "Package name 'custom_lib' was guessed. Please verify it's correct."
  ]
}
```

---

### simple 格式

```bash
pyimport2pkg analyze . -f simple
```

```text
numpy
pandas
requests
scikit-learn
Pillow
```

特点：
- 每行一个包名
- 无注释
- 只包含 required 包
- 适合管道处理：`pyimport2pkg analyze . -f simple | xargs pip install`

---

## 高级用法

### 1. 从小数据库扩展（推荐流程）

```bash
# 步骤1: 先构建少量包试试
pyimport2pkg build-db --max-packages 500

# 步骤2: 效果不错，扩展到 5000 个（自动只处理新包）
pyimport2pkg build-db --max-packages 5000

# 步骤3: 继续扩展到 10000 个
pyimport2pkg build-db --max-packages 10000

# 如果中断，查看状态
pyimport2pkg build-status

# 恢复中断的构建
pyimport2pkg build-db --resume

# 重试失败的包
pyimport2pkg build-db --retry-failed

# 确认完成
pyimport2pkg db-info
```

### 2. 强制重建数据库

```bash
# 数据库可能有问题，想从头开始
pyimport2pkg build-db --rebuild --max-packages 5000
```

### 3. Python 版本自动检测

工具会按以下优先级自动检测目标 Python 版本：

1. `.python-version` 文件（pyenv）
2. `pyproject.toml` 的 `requires-python`
3. `setup.cfg` 的 `python_requires`
4. `.venv/pyvenv.cfg` 虚拟环境配置

```bash
# 查看检测到的版本（在 stderr 中显示）
pyimport2pkg analyze .
# → Detected Python version: 3.8

# 手动覆盖版本
pyimport2pkg analyze . --python-version 3.6
```

### 4. Backports 处理

根据目标 Python 版本自动处理 backports：

| 模块 | 标准库版本 | 低版本需要安装 |
|------|-----------|---------------|
| dataclasses | 3.7+ | `dataclasses` |
| importlib.metadata | 3.8+ | `importlib-metadata` |
| zoneinfo | 3.9+ | `backports.zoneinfo` |
| tomllib | 3.11+ | `tomli` |

```bash
# Python 3.6 项目
pyimport2pkg analyze . --python-version 3.6
# → dataclasses 会出现在依赖列表中

# Python 3.8 项目
pyimport2pkg analyze . --python-version 3.8
# → dataclasses 不会出现（已是标准库）
```

### 5. 排除目录

```bash
# 排除多个目录
pyimport2pkg analyze . --exclude tests,docs,examples,scripts

# 默认已排除的目录：
# - .venv, venv, env, .env
# - __pycache__
# - .git, .hg, .svn
# - node_modules
# - *.egg-info
```

### 6. 与 CI/CD 集成

```yaml
# GitHub Actions 示例
- name: Generate requirements
  run: |
    pip install pyimport2pkg
    pyimport2pkg analyze . -o requirements.txt --exclude-optional

- name: Install dependencies
  run: pip install -r requirements.txt
```

### 7. 管道处理

```bash
# 直接安装分析出的包
pyimport2pkg analyze . -f simple --no-comments | xargs pip install

# 比较现有 requirements.txt
diff <(pyimport2pkg analyze . -f simple | sort) <(cat requirements.txt | grep -v '^#' | sort)

# 检查缺失的依赖
pyimport2pkg analyze . -f simple | while read pkg; do
  pip show "$pkg" > /dev/null 2>&1 || echo "Missing: $pkg"
done
```

---

## Python API

### 基本用法

```python
from pathlib import Path
from pyimport2pkg.scanner import scan_project
from pyimport2pkg.parser import Parser
from pyimport2pkg.filter import Filter
from pyimport2pkg.mapper import Mapper
from pyimport2pkg.resolver import Resolver
from pyimport2pkg.exporter import Exporter

# 1. 扫描项目
project_path = Path("./myproject")
files = scan_project(project_path)

# 2. 解析导入
parser = Parser()
all_imports = []
for f in files:
    all_imports.extend(parser.parse_file(f))

# 3. 过滤（移除标准库、本地模块）
filter_ = Filter(project_root=project_path)
third_party, filtered = filter_.filter_imports(all_imports)

# 4. 映射到包名
mapper = Mapper()
results = mapper.map_imports(third_party)

# 5. 解决冲突
resolver = Resolver()
results = resolver.resolve_all(results)

# 6. 导出
exporter = Exporter(include_optional=True)
required = [r for r in results if not r.import_info.is_optional]
optional = [r for r in results if r.import_info.is_optional]

content = exporter.export_requirements_txt(required, optional)
print(content)
```

### 构建进度 API (v0.3.0 新增)

```python
from pyimport2pkg.database import get_build_progress, BuildProgress

# 获取全局进度跟踪器
progress = get_build_progress()

# 查看状态
status = progress.get_status()
print(f"状态: {status['status']}")
print(f"进度: {status['processed']}/{status['total']}")
print(f"失败: {status['failed']}")

# 获取未处理的包
unprocessed = progress.get_unprocessed()

# 获取失败的包
failed = progress.get_failed()

# 清除进度（重新开始）
progress.clear()
```

### 单独使用各模块

```python
# 只用映射功能
from pyimport2pkg.mappings import get_hardcoded_mapping, resolve_namespace_package

pkg = get_hardcoded_mapping("cv2")  # ['opencv-python', ...]
pkg = resolve_namespace_package("google", ["cloud", "storage"])  # ['google-cloud-storage']

# 只用过滤功能
from pyimport2pkg.filter import Filter, detect_python_version

version = detect_python_version(Path("."))  # (3, 8) or None
filter_ = Filter(python_version=(3, 8))
is_stdlib = filter_.is_stdlib("dataclasses")  # False for 3.6, True for 3.7+

# 只用解析功能
from pyimport2pkg.parser import Parser

parser = Parser()
imports = parser.parse_source("import numpy\nfrom PIL import Image")
for imp in imports:
    print(f"{imp.module_name}: {imp.context}, optional={imp.is_optional}")
```

---

## 常见问题

### Q: 为什么某些包被标记为 "guessed"？

**A**: 当模块名与包名相同且不在硬编码映射中时，工具会猜测包名等于模块名。这通常是正确的（如 `numpy`、`pandas`），但建议验证。

### Q: 如何处理多候选包（如 cv2）？

**A**: 工具会列出所有候选并推荐下载量最高的：

```text
# cv2 -> opencv-python (10.5M downloads)
#   alternatives: opencv-contrib-python, opencv-python-headless
```

根据需求选择：
- `opencv-python`: 标准版本
- `opencv-contrib-python`: 包含额外模块
- `opencv-python-headless`: 无 GUI，适合服务器

### Q: 如何扩展现有数据库？

**A**: 直接指定更大的目标数量即可，工具会**按包名匹配**自动跳过已有的包：

```bash
# 已有 1000 个包，扩展到 5000 个
pyimport2pkg build-db --max-packages 5000

# 输出:
# 数据库已有 1000 个包
# 目标: top 5000 个包
# 将处理 4000 个新包
```

**重要**：即使第一次构建中有失败的包，扩展时也会自动包含它们（因为失败的包不在数据库中）。

```bash
# 场景：第一次构建 5000 个，成功 3240，失败 2760
# 数据库中有 3240 个包

# 扩展到 10000 个
pyimport2pkg build-db --max-packages 10000
# 会处理 10000 - 3240 = 6760 个包
# 其中包含之前失败的 2760 个（按包名匹配，不是按顺序）
```

### Q: 构建数据库时中断了怎么办？

**A**: v0.3.0 支持中断恢复，会自动记住上次的 `--max-packages` 值：

```bash
# 查看当前状态
pyimport2pkg build-status

# 继续构建（自动使用上次的 max-packages）
pyimport2pkg build-db --resume

# 只重试失败的（自动使用上次的 max-packages）
pyimport2pkg build-db --retry-failed
```

**注意**：`--resume` 和 `--retry-failed` 会自动使用上次构建时的包数量限制，无需手动指定。

### Q: `--retry-failed` 会重复处理已成功的包吗？

**A**: 不会。v0.3.0 优化了重试逻辑：

- 重试成功的包会自动从失败列表中移除
- 第二次运行 `--retry-failed` 只会处理仍然失败的包

```bash
# 第一次重试：860 个失败包，成功 834，失败 26
pyimport2pkg build-db --retry-failed

# 第二次重试：只处理剩余的 26 个
pyimport2pkg build-db --retry-failed
```

### Q: 为什么有些包构建失败？

**A**: 常见原因：
- **timeout**: 网络超时，可用 `--retry-failed` 重试
- **not_found**: 包已从 PyPI 移除或重命名
- **http_error**: PyPI 服务器临时问题
- **ConnectError**: 网络连接错误
- **RemoteProtocolError**: 远程协议错误
- **unknown**: 包没有 wheel 文件或 wheel 格式异常

查看详细错误日志：`~/.pyimport2pkg/data/build_errors_YYYYMMDD_HHMMSS.json`

### Q: 遇到 PyPI 速率限制怎么办？

**A**: v0.3.0 自动检测和处理速率限制：

```
检测到连续 20 次失败，可能遇到速率限制。
暂停 30 秒后重试 (第 1/5 次暂停)...
继续处理...
```

**行为**：
- 连续 20 次失败时自动暂停 30 秒
- 最多暂停 5 次
- 超过后停止构建，使用 `--resume` 继续

**如果经常遇到速率限制**：
```bash
# 降低并发数（默认 50）
pyimport2pkg build-db --max-packages 5000 --concurrency 20
```

### Q: 动态导入怎么处理？

**A**: 动态导入（`importlib.import_module(var)`）无法静态分析，会在 Errors section 中报告：

```text
# [Dynamic Import] utils.py:25 - Dynamic import with non-literal argument
```

需要手动检查代码并添加依赖。

### Q: 如何添加自定义映射？

**A**: 目前需要修改源码中的 `mappings/hardcoded.py`。未来版本计划支持配置文件。

### Q: 数据库文件存储在哪里？

**A**: 默认位置：
- Windows: `%USERPROFILE%\.pyimport2pkg\data\mapping.db`
- macOS/Linux: `~/.pyimport2pkg/data/mapping.db`

进度文件：`build_progress.json`（同目录）
错误日志：`build_errors_YYYYMMDD_HHMMSS.json`（同目录）

### Q: 为什么 `--exclude-optional` 后某些包消失了？

**A**: 该选项会排除：
- `try-except` 块中的导入（通常有替代方案）
- `if` 条件块中的导入（通常是平台相关）

这些是可选依赖，不影响核心功能运行。

---

## 映射优先级

工具按以下优先级确定包名：

1. **命名空间包**（有子模块时）
   - `google.cloud.storage` → `google-cloud-storage`

2. **硬编码映射**
   - `cv2` → `opencv-python`
   - `PIL` → `Pillow`

3. **命名空间包**（仅顶层）
   - `google` → 多个候选

4. **数据库查询**（如启用）
   - 从 PyPI 元数据获取

5. **猜测**
   - 假设模块名 = 包名

---

## 支持的导入类型

| 导入语句 | 提取的模块 |
|----------|-----------|
| `import numpy` | `numpy` |
| `import numpy as np` | `numpy` |
| `from PIL import Image` | `PIL` |
| `from sklearn.model_selection import train_test_split` | `sklearn.model_selection` |
| `from google.cloud import storage` | `google.cloud` |
| `from . import utils` | （相对导入，过滤） |
| `from ..core import base` | （相对导入，过滤） |

---

## 版本信息

- **当前版本**: 0.3.0
- **Python 支持**: 3.8+
- **许可证**: MIT

## 更新历史

- **v0.3.0** (2025-12-05): 新增构建进度跟踪、中断恢复、失败重试功能
- **v0.2.0** (2025-12-05): 新增 Python 版本检测、可选依赖默认包含、错误日志

## 获取帮助

```bash
# 查看帮助
pyimport2pkg --help
pyimport2pkg analyze --help
pyimport2pkg build-db --help
pyimport2pkg build-status --help

# 报告问题
https://github.com/your-repo/pyimport2pkg/issues
```
