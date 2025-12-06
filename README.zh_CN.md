# PyImport2Pkg

> 🐍 Python 导入语句到 pip 包名的反向映射工具

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Latest Release](https://img.shields.io/badge/release-v1.0.0-brightgreen.svg)](https://github.com/buptanswer/pyimport2pkg/releases/tag/v1.0.0)

## 📋 目录

- [简介](#简介)
- [核心功能](#核心功能)
- [安装](#安装)
- [快速开始](#快速开始)
- [命令详解](#命令详解)
- [高级特性](#高级特性)
- [Python API](#python-api)
- [项目架构](#项目架构)
- [常见问题](#常见问题)
- [贡献指南](#贡献指南)

---

## 简介

**PyImport2Pkg** 解决了 AI 辅助编码时代的核心问题：

> 给定 Python 代码中的 import 语句，如何快速准确地知道需要安装哪个 pip 包？

### 为什么需要这个工具？

传统开发流程中，pip 包名和 import 模块名通常是相同的。但在实际情况中，许多流行的库存在**模块名 ≠ 包名**的情况：

- `import cv2` → 需要安装 `pip install opencv-python`
- `from PIL import Image` → 需要安装 `pip install Pillow`
- `import sklearn` → 需要安装 `pip install scikit-learn`
- `import google.cloud.storage` → 需要安装 `pip install google-cloud-storage`

当 AI 生成包含大量 import 的代码时，手动查找每个映射关系非常耗时且容易出错。**PyImport2Pkg** 自动化解决这个问题。

---

## 核心功能

### 🎯 主要特性

| 功能 | 描述 |
|------|------|
| **项目分析** | 递归扫描 Python 项目，提取所有 import 语句，生成 requirements.txt |
| **智能映射** | 通过优先级方案处理模块名与包名的映射关系 |
| **命名空间支持** | 正确处理 `google.*`、`azure.*`、`zope.*` 等命名空间包 |
| **可选依赖识别** | 区分必需依赖和可选依赖（try-except、平台特定导入等） |
| **版本感知** | 自动检测 Python 目标版本，处理 backport 包 |
| **高效数据库** | 智能增量更新、真正的并行处理、批量写入 |
| **中断恢复** | 支持从中断点继续构建，不丢失进度 |

### 映射优先级

PyImport2Pkg 使用多层优先级方案确保映射准确率：

1. **命名空间包** - 当检测到子模块时（如 `google.cloud.storage`）
2. **硬编码映射** - 已知的特殊情况（如 `cv2` → `opencv-python`）
3. **PyPI 数据库** - 从 wheel 文件的 `top_level.txt` 查找
4. **智能猜测** - 假设模块名等于包名

---

## 安装

### 推荐方式

```bash
# 使用 pip 安装
pip install pyimport2pkg

# 或在开发模式安装
pip install -e ".[dev]"
```

### 需求

- Python 3.10+
- 无重型依赖（仅 `httpx>=0.25.0`）

---

## 快速开始

### 1️⃣ 分析单个项目

```bash
# 分析当前目录，输出到终端
pyimport2pkg analyze .

# 输出示例：
# Analyzing: .
# Found imports from 24 files
# 
# Dependencies:
#   numpy
#   pandas
#   requests
#   ... (more packages)
```

### 2️⃣ 查询单个模块

```bash
# 查询模块对应的包
pyimport2pkg query cv2

# 输出示例：
# Module: cv2
# Source: hardcoded
# Candidates:
#   1. opencv-python (recommended)
#   2. opencv-contrib-python
#   3. opencv-python-headless
```

### 3️⃣ 保存分析结果

```bash
# 保存为 requirements.txt
pyimport2pkg analyze . -o requirements.txt

# 保存为 JSON 格式
pyimport2pkg analyze . -o dependencies.json -f json
```

---

## 命令详解

### analyze - 分析项目

分析 Python 项目中的所有 import 语句，识别需要的依赖包。

```bash
pyimport2pkg analyze <project_path> [options]
```

**选项：**

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `-o, --output` | 输出文件路径 | 标准输出 |
| `-f, --format` | 输出格式 (requirements\|json\|simple) | requirements |
| `--python-version` | 目标 Python 版本 | 当前版本 |

**示例：**

```bash
# 基础分析
pyimport2pkg analyze /path/to/project

# 指定目标 Python 版本
pyimport2pkg analyze . --python-version 3.11

# 保存为 JSON 格式
pyimport2pkg analyze . -o deps.json -f json
```

**输出格式：**

- **txt** (默认)：标准 requirements.txt 格式
- **json**：详细的 JSON 格式，包含依赖来源、是否可选等信息
- **simple**：简单的包名列表，每行一个

---

### query - 查询映射

查询单个 Python 模块对应的 pip 包名。

```bash
pyimport2pkg query <module_name>
```

**示例：**

```bash
# 查询常见包
pyimport2pkg query numpy       # → numpy
pyimport2pkg query cv2         # → opencv-python（以及其他选项）
pyimport2pkg query PIL         # → Pillow
pyimport2pkg query google.cloud.storage  # → google-cloud-storage
```

---

### build-db - 构建映射数据库

构建 PyPI 包的映射数据库。这个操作从 PyPI 下载元数据，建立完整的模块名→包名映射。

```bash
pyimport2pkg build-db [options]
```

**选项：**

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `--max-packages` | 目标包数量（PyPI top N） | 5000 |
| `--concurrency` | 并发数 | 50 |
| `--resume` | 恢复中断的构建 | 否 |
| `--retry-failed` | 只重试失败的包 | 否 |
| `--rebuild` | 强制重建（删除旧数据库） | 否 |
| `--db-path` | 数据库文件路径 | `data/mapping.db` |

**典型使用场景：**

```bash
# 首次构建 5000 个包的数据库
pyimport2pkg build-db --max-packages 5000

# 如果中间被中断，恢复构建
pyimport2pkg build-db --resume

# 重试上次失败的包
pyimport2pkg build-db --retry-failed

# 扩展现有数据库
pyimport2pkg build-db --max-packages 10000

# 强制重建
pyimport2pkg build-db --rebuild --max-packages 5000
```

**特性：**

- ✅ **智能增量更新** - 只处理新包，不重复处理已有的
- ✅ **中断恢复** - 保存进度，支持从断点继续
- ✅ **并行处理** - 高并发（默认 50）下载和处理
- ✅ **批量写入** - 每 100 个包批量提交数据库
- ✅ **速率限制检测** - 自动检测 PyPI 限流并暂停
- ✅ **内存优化** - 分块处理大规模数据

---

### build-status - 查看构建状态

查看当前或上次的数据库构建进度。

```bash
pyimport2pkg build-status
```

**输出示例：**

```
构建状态: 进行中
总包数: 5000
已处理: 2500
失败: 12
成功率: 99.5%
最后更新: 2025-12-06 10:30:45
```

---

### db-info - 数据库信息

显示当前映射数据库的统计信息。

```bash
pyimport2pkg db-info
```

**输出示例：**

```
数据库信息
===========
数据库文件: data/mapping.db
包数量: 5000
模块总数: 25000
最后更新: 2025-12-06 08:00:00
```

---

## 高级特性

### v1.0.0 更新 (2025-12-06)

**首个稳定版本，主要改进：**

- ✅ 全面国际化 - 所有 CLI 输出改为英文
- ✅ API 稳定性 - 核心类现可从包根目录导入
- ✅ 修复 JSON 导出版本号（之前硬编码 0.2.0）
- ✅ JSON 导出现包含未解析的 import
- ✅ 修正文档中的 API 方法名
- ✅ 开发状态更新为 Production/Stable

详见 [CHANGELOG v1.0.0](documents/CHANGELOG/CHANGELOG_v1.0.0.md)

### v0.3.0 新特性

#### 1. 智能增量更新

默认就是增量模式，扩展数据库时只处理新包：

```bash
# 数据库已有 500 个包，想扩展到 1000 个
pyimport2pkg build-db --max-packages 1000
# 自动只处理新增的 500 个包
```

#### 2. 构建进度跟踪

系统自动保存构建进度，支持查看和恢复：

- 实时保存已处理和失败的包信息
- 中断恢复不会丢失已完成的工作
- 可查看失败的包列表便于调试

#### 3. 中断恢复 (--resume)

从上次中断的位置继续构建：

```bash
# 开始构建（可能被中断）
pyimport2pkg build-db --max-packages 14100

# 中断后恢复（自动使用 14100）
pyimport2pkg build-db --resume
```

#### 4. 失败重试 (--retry-failed)

只重试上次失败的包，成功的包自动标记：

```bash
# 重试所有失败的包
pyimport2pkg build-db --retry-failed

# 多次重试，每次都只处理新失败的
pyimport2pkg build-db --retry-failed
```

#### 5. 强制重建 (--rebuild)

删除现有数据库，从头开始构建：

```bash
pyimport2pkg build-db --rebuild --max-packages 5000
```

#### 6. 性能优化

- **批量数据库写入** - 每 100 个包批量提交，性能提升 5-10 倍
- **并发提升** - 默认 50 并发（v0.2.0 是 20）
- **内存优化** - 分块处理（每 500 个包），支持 15000+ 包构建
- **批量进度保存** - 每 100 个包保存一次进度

#### 7. 速率限制检测

自动检测 PyPI 速率限制并暂停：

```
检测到连续 20 次失败，可能遇到速率限制。
暂停 30 秒后重试 (第 1/5 次暂停)...
继续处理...
```

#### 8. 优雅中断处理

按下 Ctrl+C 时安全退出：

```
^C
正在保存进度，请稍候... (再次按 Ctrl+C 强制退出)
构建已中断。已处理 2500/5000 个包。
使用 --resume 继续构建。
```

---

## Python API

除了 CLI，PyImport2Pkg 也提供 Python API 供程序化调用：

### 基础导入

```python
from pyimport2pkg import (
    Scanner,
    Parser,
    Filter,
    Mapper,
    Resolver,
    Exporter,
    ImportInfo,
    MappingResult,
)
```

### 完整管道示例

```python
from pathlib import Path
from pyimport2pkg import (
    Scanner,
    Parser,
    Filter,
    Mapper,
    Exporter,
)

# 1. 扫描项目
scanner = Scanner()
python_files = scanner.scan(Path("./my_project"))

# 2. 解析 import 语句
parser = Parser()
imports = []
for file_path in python_files:
    file_imports = parser.parse_file(file_path)
    imports.extend(file_imports)

# 3. 过滤标准库和本地模块
filter = Filter(project_root=Path("./my_project"))
third_party, _ = filter.filter_imports(imports)

# 4. 映射到包名
mapper = Mapper()
mapping_results = mapper.map_imports(third_party)

# 5. 解决冲突
resolver = Resolver()
resolved = resolver.resolve_mappings(mapping_results)

# 6. 导出结果
exporter = Exporter()
exporter.export_requirements_txt(resolved, output=Path("requirements.txt"))
exporter.export_json(resolved, output=Path("dependencies.json"))
```

### 单个查询

```python
from pyimport2pkg import Mapper, ImportInfo

mapper = Mapper()
imp = ImportInfo.from_module_name("cv2")
result = mapper.map_import(imp)
for candidate in result.candidates:
    print(f"{candidate.package_name}: {candidate.download_count} 下载")
# 输出:
#   opencv-python: 1000000 下载
#   opencv-contrib-python: 500000 下载
#   ...
```

### 查询构建状态

```python
from pyimport2pkg.database import get_build_progress

progress = get_build_progress()
status = progress.get_status()
print(status)
# {
#     'status': 'in_progress',
#     'total': 5000,
#     'processed': 2500,
#     'failed': 10,
#     'success_rate': 0.995
# }
```

---

## 项目架构

### 系统设计

PyImport2Pkg 采用管道架构（Pipeline Architecture），各模块职责清晰：

```
Python 项目
    ↓
Scanner (扫描器)
    ↓ 找到所有 Python 文件
Parser (解析器)
    ↓ 提取 import 语句
Filter (过滤器)
    ↓ 移除标准库、本地模块
Mapper (映射器)
    ↓ 映射到 pip 包名
Resolver (解决器)
    ↓ 解决冲突和多选项
Exporter (导出器)
    ↓
requirements.txt / JSON / 列表
```

### 核心模块

| 模块 | 职责 | 关键方法 |
|------|------|---------|
| `scanner.py` | 递归查找 Python 文件，排除 venv、.git 等 | `scan()` |
| `parser.py` | 使用 AST 解析 import，记录上下文 | `parse()` |
| `filter.py` | 过滤标准库、本地模块、backport 检测 | `filter()` |
| `mapper.py` | 多优先级映射查询 | `map()` |
| `resolver.py` | 处理一对多冲突 | `resolve()` |
| `exporter.py` | 导出多种格式 | `to_requirements_txt()` 等 |
| `database.py` | 构建和查询 SQLite 映射数据库 | `build_database()` |

### 数据结构

```python
# ImportInfo - 单个 import 语句
ImportInfo(
    module_name: str,              # e.g., "cv2"
    file_path: Path,               # 源文件路径
    line_number: int,              # 行号
    is_optional: bool,             # try-except 中导入?
    import_type: ImportType,       # 导入类型
    import_context: ImportContext, # 上下文信息
)

# MappingResult - 映射结果
MappingResult(
    module_name: str,              # e.g., "cv2"
    package_candidates: List[PackageCandidate],  # 候选包
    mapping_source: str,           # 映射来源
    confidence: float,             # 置信度
)

# PackageCandidate - 包候选项
PackageCandidate(
    name: str,                     # e.g., "opencv-python"
    download_count: int,           # PyPI 下载数
    is_recommended: bool,          # 推荐?
)
```

### 映射优先级详解

映射器按以下优先级查询：

1. **命名空间包（带子模块）** - 如 `google.cloud.storage` → `google-cloud-storage`
2. **硬编码映射** - 编码在 `mappings/hardcoded.py` 中
3. **命名空间包（顶级）** - 如 `google` → `google-auth`
4. **数据库查询** - 从 wheel 的 `top_level.txt`
5. **智能猜测** - `module_name == package_name`

---

## 常见问题

### Q: 如何排除某些目录（如 tests、venv）？

A: Scanner 自动排除常见的目录：
- `.git`, `.venv`, `venv`, `env`
- `__pycache__`, `.pytest_cache`, `.tox`
- `node_modules`, `.venv`

如需自定义，使用 Python API：

```python
scanner = Scanner(exclude_dirs=["tests", "docs"])
```

### Q: 支持相对导入吗？

A: 支持。Parser 会记录相对导入，Filter 会自动识别为本地模块。

### Q: 如何处理条件导入（如 `if sys.platform == "win32"`）？

A: 条件导入会被标记为 `is_optional=True`。使用 JSON 格式输出时会有特殊标记，便于手动审查。

### Q: 数据库构建需要多长时间？

A: 取决于包数量和网络速度：
- 5000 个包：约 10-20 分钟（默认 50 并发）
- 14000 个包：约 30-60 分钟
- 支持中断恢复，可分次构建

### Q: 如何更新 PyPI 映射数据库？

A: 直接运行 `build-db`，会覆盖旧数据库：

```bash
pyimport2pkg build-db --rebuild --max-packages 10000
```

### Q: 为什么某些导入识别不出来？

A: 可能原因：
1. 数据库还未构建或数据不全
2. 是非常新的或非常冷门的包
3. 包的 `top_level.txt` 配置不当

使用 `query` 命令诊断，或提交 Issue。

---

## 性能指标

### 分析速度

| 项目规模 | 分析时间 | 扫描文件数 |
|---------|---------|----------|
| 小型（<100 文件） | < 1 秒 | ~50 |
| 中型（100-1000 文件） | 1-5 秒 | ~500 |
| 大型（1000+ 文件） | 5-30 秒 | ~2000 |

### 数据库构建

| 包数量 | 构建时间 | 内存占用 |
|--------|---------|---------|
| 5000 | 10-20 分钟 | ~200 MB |
| 10000 | 20-40 分钟 | ~400 MB |
| 15000 | 40-80 分钟 | ~600 MB |

---

## 贡献指南

### 报告 Bug

如发现问题，请在 [GitHub Issues](https://github.com/buptanswer/pyimport2pkg/issues) 中提交，包含：

1. Python 版本
2. PyImport2Pkg 版本
3. 完整错误堆栈
4. 最小复现示例

### 提交改进

1. Fork 本仓库
2. 创建特性分支：`git checkout -b feature/your-feature`
3. 提交改动：`git commit -m "Add your feature"`
4. 推送分支：`git push origin feature/your-feature`
5. 发起 Pull Request

### 开发环境

```bash
# 克隆仓库
git clone https://github.com/buptanswer/pyimport2pkg.git
cd pyimport2pkg

# 安装开发依赖
pip install -e ".[dev]"

# 运行测试
pytest tests/ -v

# 查看代码覆盖率
pytest tests/ --cov=pyimport2pkg
```

---

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

---

## 联系方式

- 📧 GitHub Issues：[提交问题](https://github.com/buptanswer/pyimport2pkg/issues)
- 🐛 Bug 报告：[Bug Tracker](https://github.com/buptanswer/pyimport2pkg/issues)
- 💡 功能建议：[Discussions](https://github.com/buptanswer/pyimport2pkg/discussions)

---

**Made with ❤️ for the AI-assisted coding era**
