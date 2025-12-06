# PyImport2Pkg v0.3.0 更新日志

**发布日期**: 2025-12-05

## 概述

v0.3.0 版本重点改进了数据库构建的性能和用户体验，实现了真正的并行处理、批量数据库写入、智能增量更新、内存优化、速率限制检测等功能，使大规模数据库构建更加高效稳健。

---

## 新功能

### 1. 智能增量更新（默认行为）

**默认就是增量模式**，按包名匹配剔除已有包：

```bash
# 已有 500 个包的数据库，想扩展到 1000 个
# 直接指定目标数量即可，自动只处理新包
pyimport2pkg build-db --max-packages 1000

# 输出:
# 数据库已有 500 个包
# 目标: top 1000 个包
# 将处理 500 个新包
```

**安全性**：
- 按包名匹配（`p["project"] not in existing_packages`），不是按顺序
- 即使第一次构建有失败的包，扩展时也会自动包含（因为失败的包不在数据库中）
- 中间出错不会丢失包

**使用场景**：
- 已构建小数据库，想扩展到更大范围
- 定期增量更新，添加新上榜的热门包

### 2. 构建进度跟踪

新增 `BuildProgress` 类，实现构建状态的持久化跟踪：

- 记录已处理和失败的包
- 保存到 `build_progress.json` 文件
- **批量保存**（每 100 个包），兼顾性能和安全性

```python
from pyimport2pkg.database import get_build_progress

progress = get_build_progress()
status = progress.get_status()
# {'status': 'in_progress', 'total': 5000, 'processed': 2500, 'failed': 10, ...}
```

### 3. 中断恢复功能 (--resume)

支持从上次中断的位置继续构建，**自动记住上次的包数量限制**：

```bash
# 开始构建（可能被中断）
pyimport2pkg build-db --max-packages 14100

# 中断后恢复（自动使用 14100）
pyimport2pkg build-db --resume
```

**注意**：`--resume` 只用于恢复**中断**的构建。如果想扩展已完成的数据库，直接使用 `--max-packages N` 即可。

**优化**：
- 进度文件保存 `max_packages` 值
- `--resume` 和 `--retry-failed` 自动使用保存的值
- 避免因使用默认值导致的包匹配失败

### 4. 失败重试功能 (--retry-failed)

只重试上次失败的包，**成功的包自动从失败列表移除**：

```bash
# 第一次重试：860 个失败包，成功 834，失败 26
pyimport2pkg build-db --retry-failed

# 第二次重试：只处理剩余的 26 个
pyimport2pkg build-db --retry-failed
```

**优化**：
- `mark_processed(success=True)` 时自动从 failed 集合移除
- 避免重复处理已成功的包
- 自动使用上次保存的包数量限制

### 5. 强制重建功能 (--rebuild)

**新增**：强制删除现有数据库并从头开始：

```bash
# 清除旧数据库，完全重建
pyimport2pkg build-db --rebuild --max-packages 5000
```

### 6. 内存优化 - 分块处理

**新增**：使用分块处理减少内存占用，支持大规模构建（15000+ 包）：

- 每 500 个包为一个分块处理
- 每个分块处理完成后立即释放内存
- 支持中断恢复，不会丢失已完成的分块

### 7. 速率限制检测

**新增**：自动检测 PyPI 速率限制并暂停：

- 连续 20 次失败时检测为可能遇到速率限制
- 自动暂停 30 秒后重试
- 最多暂停 5 次，超过则停止构建
- 暂停期间保存进度，可安全中断

```
检测到连续 20 次失败，可能遇到速率限制。
暂停 30 秒后重试 (第 1/5 次暂停)...
继续处理...
```

### 8. 性能优化

#### 批量数据库写入
- 每 100 个包批量写入数据库，而不是每个包单独写入
- 使用 `executemany()` 批量 INSERT
- SQLite WAL 模式 + 优化的缓存设置

#### 批量进度保存
- 每 100 个包保存一次进度，而不是每个包都写文件
- 中断/完成时立即保存，确保数据安全

#### 并发提升
- 默认并发从 20 提升到 **50**
- 使用 `httpx.Limits` 优化连接池

### 9. 优雅中断处理 (Ctrl+C)

按下 Ctrl+C 时优雅退出：

```
^C
正在保存进度，请稍候... (再次按 Ctrl+C 强制退出)

构建已中断。已处理 2500/5000 个包。
使用 --resume 继续构建，或 --retry-failed 重试失败的包。
```

### 10. 构建状态查询 (build-status)

新增命令查看当前构建状态：

```bash
pyimport2pkg build-status
```

### 11. 带日期的错误日志

错误日志包含时间戳，不会覆盖旧日志：

```
data/
├── mapping.db
├── build_progress.json
├── build_errors_20251205_100000.json
└── build_errors_20251205_143000.json
```

---

## CLI 变更

### build-db 命令选项

| 选项 | 说明 |
|------|------|
| `--max-packages` | 目标包数量（默认 5000） |
| `--concurrency` | 并发数（默认 **50**） |
| `--resume` | 恢复中断的构建 |
| `--retry-failed` | 重试失败的包 |
| `--rebuild` | **新增** 强制重建（删除旧数据库） |
| `--db-path` | 指定数据库文件路径 |

**移除的选项**：
- `--incremental`：不再需要，智能增量现在是默认行为

### 新增 build-status 命令

```bash
pyimport2pkg build-status
```

---

## 典型使用场景

### 场景1: 从小数据库扩展（最常见）

```bash
# 先构建 500 个包试试
pyimport2pkg build-db --max-packages 500

# 效果不错，扩展到 5000 个（自动只处理新的 4500 个）
pyimport2pkg build-db --max-packages 5000

# 继续扩展到 10000 个
pyimport2pkg build-db --max-packages 10000
```

### 场景2: 大规模数据库构建

```bash
# 构建 20000 个包（分块处理，内存友好）
pyimport2pkg build-db --max-packages 20000

# 如果中途需要离开，按 Ctrl+C
# 回来后继续
pyimport2pkg build-db --resume
```

### 场景3: 网络问题导致失败

```bash
# 构建过程中网络不稳定，很多超时
pyimport2pkg build-db --max-packages 5000

# 网络恢复后只重试失败的
pyimport2pkg build-db --retry-failed
```

### 场景4: 完全重建

```bash
# 数据库可能有问题，想从头开始
pyimport2pkg build-db --rebuild --max-packages 5000
```

---

## 技术参数

| 参数 | 值 | 说明 |
|------|----|----|
| SAVE_INTERVAL | 100 | 每 100 个包保存一次进度 |
| CHUNK_SIZE | 500 | 每 500 个包为一个分块 |
| CONSECUTIVE_FAIL_THRESHOLD | 20 | 连续 20 次失败触发暂停 |
| PAUSE_DURATION | 30 | 暂停 30 秒 |
| MAX_PAUSE_COUNT | 5 | 最多暂停 5 次 |
| 默认并发数 | 50 | 同时处理 50 个请求 |

---

## 测试

- 测试用例总数: **304** (+41)
- 全部通过

新增测试覆盖：
- BuildProgress 类（15个测试，包括 max_packages 保存和 retry 成功移除）
- 批量写入功能（2个测试）
- 进度保存行为（4个测试）
- CLI 构建选项（4个测试）
- 带日期的错误日志（2个测试）
- 分块处理和速率限制检测（4个测试）

---

## 升级指南

### 从 v0.2.0 升级

1. **行为变更**：
   - `--incremental` 选项已移除，智能增量现在是默认行为
   - 默认并发从 20 提升到 50
   - 进度保存从每个包改为批量（每 100 个包）

2. **新增选项**：
   - `--rebuild`: 强制重建数据库

3. **推荐工作流**：
   ```bash
   # 构建/扩展数据库（智能增量，自动跳过已有的包）
   pyimport2pkg build-db --max-packages 10000

   # 中断后恢复
   pyimport2pkg build-db --resume

   # 重试失败
   pyimport2pkg build-db --retry-failed

   # 强制重建
   pyimport2pkg build-db --rebuild
   ```

---

## 下一版本计划 (v0.4.0)

- [ ] 支持 conda 环境检测
- [ ] 添加版本约束推断
- [ ] 支持 pyproject.toml 输出格式
- [ ] 交互式候选选择
- [ ] 自定义映射配置文件支持
