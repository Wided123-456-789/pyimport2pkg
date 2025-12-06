# GitHub Release 发布指南

## 📋 前置条件

在发布 Release 之前，请确保：

- ✅ 代码已提交到 Git：`git commit -m "..."`
- ✅ 已创建 Git tag：`git tag -a v0.3.0 -m "..."`
- ✅ README.md 已更新
- ✅ RELEASE_NOTE.md 已创建
- ✅ pyproject.toml 版本号为 0.3.0
- ✅ src/pyimport2pkg/__init__.py 版本号为 0.3.0

**状态：全部已完成 ✅**

---

## 🚀 三种发布方式

### 方式 1️⃣: 使用 GitHub CLI (gh)（推荐）

GitHub CLI 是最便捷的方式。如果你未安装，可从 https://cli.github.com 下载。

#### 第一步：推送代码和标签到 GitHub

```bash
cd "c:\Users\14044\Desktop\PyProj\PyImport2Pkg\v0.3.0"

# 添加 GitHub 远程仓库（首次）
# 替换 YOUR_USERNAME 为你的 GitHub 用户名
git remote add origin https://github.com/YOUR_USERNAME/pyimport2pkg.git

# 推送主分支
git push -u origin master

# 推送标签
git push origin v0.3.0
```

#### 第二步：使用 GitHub CLI 发布 Release

```bash
# 读取 RELEASE_NOTE.md 作为 Release 正文
gh release create v0.3.0 --title "PyImport2Pkg v0.3.0" --notes-file RELEASE_NOTE.md

# 或者直接指定正文（从文件读取）
gh release create v0.3.0 -F RELEASE_NOTE.md
```

---

### 方式 2️⃣: 使用 GitHub 网页界面

#### 第一步：推送代码

```bash
cd "c:\Users\14044\Desktop\PyProj\PyImport2Pkg\v0.3.0"
git remote add origin https://github.com/YOUR_USERNAME/pyimport2pkg.git
git push -u origin master
git push origin v0.3.0
```

#### 第二步：在网页创建 Release

1. 访问：https://github.com/YOUR_USERNAME/pyimport2pkg/releases
2. 点击 **"Draft a new release"** 按钮
3. 在 **"Choose a tag"** 中选择 `v0.3.0`
4. 填写 Release 信息：
   - **Release title**: `PyImport2Pkg v0.3.0`
   - **Describe this release**: 复制粘贴 `RELEASE_NOTE.md` 的内容
5. 点击 **"Publish release"**

---

### 方式 3️⃣: 使用 Python 脚本自动化

创建一个 `publish_release.py` 脚本来自动化所有步骤：

```python
#!/usr/bin/env python3
"""
Automated GitHub Release Publisher
This script automates the release creation process.
"""

import subprocess
import sys
from pathlib import Path

def run_command(cmd: str, description: str) -> bool:
    """Run a shell command and report results."""
    print(f"\n{'='*60}")
    print(f"📝 {description}")
    print(f"{'='*60}")
    print(f"Command: {cmd}")
    
    try:
        result = subprocess.run(cmd, shell=True, check=True, text=True)
        print(f"✅ Success: {description}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Failed: {description}")
        print(f"Error: {e}")
        return False

def main():
    project_root = Path(__file__).parent
    release_note = project_root / "RELEASE_NOTE.md"
    
    if not release_note.exists():
        print(f"❌ Error: RELEASE_NOTE.md not found at {release_note}")
        return False
    
    version = "v0.3.0"
    
    # Check if gh CLI is installed
    if not run_command("gh --version", "Checking GitHub CLI"):
        print("\n⚠️  GitHub CLI not installed. Please install from https://cli.github.com")
        return False
    
    # Step 1: Configure Git remote (if not already done)
    print("\n" + "="*60)
    print("📋 Step 1: Configure Git Remote")
    print("="*60)
    
    try:
        # Check if origin already exists
        result = subprocess.run(
            "git remote get-url origin",
            shell=True,
            capture_output=True,
            text=True,
            cwd=project_root,
            check=False
        )
        if result.returncode == 0:
            print(f"✅ Git remote already configured: {result.stdout.strip()}")
        else:
            username = input("🔑 Enter your GitHub username: ").strip()
            remote_url = f"https://github.com/{username}/pyimport2pkg.git"
            run_command(
                f'git remote add origin "{remote_url}"',
                f"Adding Git remote: {remote_url}"
            )
    except Exception as e:
        print(f"⚠️  Could not configure remote: {e}")
    
    # Step 2: Push code
    print("\n" + "="*60)
    print("📤 Step 2: Push Code to GitHub")
    print("="*60)
    
    if not run_command(
        "git push -u origin master",
        "Pushing master branch",
    ):
        print("⚠️  Push failed (may already be pushed)")
    
    if not run_command(
        "git push origin v0.3.0",
        "Pushing version tag",
    ):
        print("⚠️  Tag push failed (may already be pushed)")
    
    # Step 3: Create release using gh CLI
    print("\n" + "="*60)
    print("🚀 Step 3: Create Release on GitHub")
    print("="*60)
    
    cmd = f'gh release create {version} -F RELEASE_NOTE.md --title "PyImport2Pkg {version}"'
    if run_command(cmd, f"Creating GitHub Release {version}"):
        print(f"\n{'='*60}")
        print(f"✅ Release Published Successfully!")
        print(f"{'='*60}")
        print(f"\n🎉 Your release is now live:")
        print(f"   https://github.com/YOUR_USERNAME/pyimport2pkg/releases/tag/{version}")
        return True
    else:
        print(f"\n❌ Failed to create release via gh CLI")
        print(f"📝 Manual step: Create release at:")
        print(f"   https://github.com/YOUR_USERNAME/pyimport2pkg/releases")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
```

使用此脚本：

```bash
# 确保在项目根目录
cd "c:\Users\14044\Desktop\PyProj\PyImport2Pkg\v0.3.0"

# 运行脚本
python publish_release.py
```

---

## 📝 Release Note 正文

以下是本次 Release 的完整正文内容（已保存在 `RELEASE_NOTE.md`）：

```markdown
# PyImport2Pkg v0.3.0 Release Notes

[完整内容见 RELEASE_NOTE.md 文件]
```

---

## 🔐 GitHub 身份认证（首次推送时需要）

如果这是你第一次推送到 GitHub，可能需要认证：

### 方式 A: 使用 GitHub CLI 认证（推荐）

```bash
# 使用浏览器打开 GitHub 认证页面
gh auth login

# 选择：
# - What is your preferred protocol for Git operations? HTTPS
# - Authenticate Git with your GitHub credentials? Yes
# - How would you like to authenticate GitHub CLI? Paste an authentication token
```

### 方式 B: 使用 Personal Access Token (PAT)

1. 在 GitHub 网站上创建 PAT: https://github.com/settings/tokens
   - Scopes: `repo`, `read:user`, `gist`
2. 复制 token
3. 运行推送命令时使用 token 作为密码：

```bash
# 当提示输入密码时，粘贴你的 token
git push -u origin master
```

---

## ✅ 验证发布成功

发布完成后，验证：

1. ✅ 访问 https://github.com/YOUR_USERNAME/pyimport2pkg/releases
2. ✅ 看到 `v0.3.0` 标签和完整的 Release Note
3. ✅ Release Note 中包含所有新功能和改进说明
4. ✅ 如果有二进制文件，确保已上传

---

## 📦 后续步骤（可选）

### 发布到 PyPI

如果想发布到 Python Package Index，可以继续进行：

```bash
# 安装构建工具
pip install build twine

# 构建分发包
python -m build

# 上传到 PyPI（需要账户）
python -m twine upload dist/*
```

---

## 🆘 故障排除

### 问题 1: "fatal: not a git repository"

**原因**: 不在项目目录
**解决**:
```bash
cd "c:\Users\14044\Desktop\PyProj\PyImport2Pkg\v0.3.0"
```

### 问题 2: "Permission denied (publickey)"

**原因**: SSH 密钥配置问题
**解决**: 使用 HTTPS 而不是 SSH
```bash
git remote set-url origin https://github.com/YOUR_USERNAME/pyimport2pkg.git
```

### 问题 3: "tag already exists"

**原因**: Tag 已存在
**解决**: 使用 `-f` 强制覆盖（谨慎）
```bash
git tag -d v0.3.0  # 删除本地标签
git push --delete origin v0.3.0  # 删除远程标签（如果已推送）
git tag -a v0.3.0 -m "PyImport2Pkg v0.3.0"  # 重新创建
```

### 问题 4: "gh: command not found"

**原因**: GitHub CLI 未安装
**解决**: 从 https://cli.github.com 下载安装

---

## 📚 参考资源

- GitHub Release 文档: https://docs.github.com/en/repositories/releasing-projects-on-github
- GitHub CLI 文档: https://cli.github.com/manual
- Git Tag 文档: https://git-scm.com/book/en/v2/Git-Basics-Tagging

---

## 🎯 完整检查清单

在发布前，请确认：

- [ ] Git 仓库已初始化
- [ ] 所有代码已提交
- [ ] v0.3.0 标签已创建
- [ ] README.md 已更新
- [ ] RELEASE_NOTE.md 已创建
- [ ] pyproject.toml 版本为 0.3.0
- [ ] __init__.py 版本为 0.3.0
- [ ] .gitignore 已配置
- [ ] GitHub 账户已设置
- [ ] 已选择发布方式（CLI / 网页 / 脚本）

**状态: 全部准备就绪! ✅**

---

**Next Step**: 按照上述三种方式之一，将代码推送到 GitHub 并发布 Release！
