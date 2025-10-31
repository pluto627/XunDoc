# 🚨 紧急安全通知

## ⚠️ API Key 泄露警告

**日期**: 2025-10-31

**严重程度**: 🔴 高危

---

## 📢 问题说明

在项目的早期提交（commit `e9cd442` 及之前）中，以下 API Key 被意外硬编码在代码中并推送到了公开的 GitHub 仓库：

1. **Kimi API Key**: `sk-CE6JIOSti61TqFYhPFs6OrTS5wMtJvA8v2YsnPIw1SFgeqcu`
2. **Moonshot API Key**: `sk-wc9tcOA0q2ShfOjKZ91YStbbyyoMGpiegf6zq54i9kpaQtke`

### 影响范围

- ✅ **已修复**: Commit `e130c33` 已移除所有硬编码的 API Key
- ⚠️ **历史记录**: Git 历史中仍包含这些 Key（需要手动清理）
- ⚠️ **公开仓库**: 任何人都可以查看历史提交记录

---

## 🔥 立即行动清单

### 作为仓库所有者，你需要：

- [ ] **1. 立即撤销泄露的 API Key**
  - 登录 Moonshot AI 控制台：https://platform.moonshot.cn/console/api-keys
  - 找到并删除以下 Key：
    - `sk-CE6JIOSti61TqFYhPFs6OrTS5wMtJvA8v2YsnPIw1SFgeqcu`
    - `sk-wc9tcOA0q2ShfOjKZ91YStbbyyoMGpiegf6zq54i9kpaQtke`

- [ ] **2. 生成新的 API Key**
  - 在同一控制台创建新的 API Key
  - 妥善保存（只会显示一次）

- [ ] **3. 检查账单和使用记录**
  - 查看是否有异常的 API 调用
  - 确认没有产生意外费用

- [ ] **4. 配置本地开发环境**
  - 按照 `API_KEY_SETUP.md` 的指引配置新 Key
  - 确保不再硬编码 API Key

- [ ] **5. (可选但推荐) 清理 Git 历史记录**
  - 参考下方的"清理 Git 历史"部分

### 作为项目使用者，你需要：

- [ ] **1. 获取自己的 API Key**
  - 不要使用已泄露的 Key（已失效）
  - 按照 `API_KEY_SETUP.md` 配置

- [ ] **2. 更新到最新代码**
```bash
git pull origin main
```

---

## 🧹 清理 Git 历史记录（可选）

⚠️ **警告**: 这会改写整个 Git 历史，所有协作者都需要重新克隆仓库！

### 方法 1：使用 git filter-repo（推荐）

```bash
# 安装 git-filter-repo（如果还没有）
# macOS:
brew install git-filter-repo

# 备份仓库
cd ..
cp -r XunDoc XunDoc-backup

# 清理包含敏感信息的文件
cd XunDoc
git filter-repo --invert-paths \
  --path XunDoc/Managers/KimiAPIManager.swift \
  --path XunDoc/Managers/MoonshotAPIManager.swift \
  --force

# 重新添加清理后的文件
git remote add origin https://github.com/pluto627/XunDoc.git
git push origin --force --all
git push origin --force --tags
```

### 方法 2：使用 BFG Repo-Cleaner

```bash
# 下载 BFG
brew install bfg

# 备份仓库
cd ..
cp -r XunDoc XunDoc-backup

# 清理敏感信息
cd XunDoc
bfg --replace-text passwords.txt  # 创建包含要替换的文本的文件

# 清理和推送
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push origin --force --all
git push origin --force --tags
```

### 方法 3：删除仓库重新开始（最简单）

如果这个仓库还不重要，最简单的方法是：

1. 在 GitHub 上删除整个仓库
2. 创建新的仓库
3. 推送清理后的代码：

```bash
cd /Users/plutoguo/Desktop/XunDoc
rm -rf .git
git init
git add .
git commit -m "Initial commit - v1.0.1 with security fixes"
git branch -M main
git remote add origin https://github.com/pluto627/XunDoc.git
git push -u origin main --force
```

---

## 🛡️ 预防措施

为了避免将来再次泄露敏感信息：

### 1. 使用 pre-commit hooks

创建 `.git/hooks/pre-commit`:

```bash
#!/bin/bash
if git diff --cached | grep -E "(sk-[A-Za-z0-9]{48}|api[_-]?key|password|secret)"; then
    echo "⚠️  警告：检测到可能的敏感信息！"
    echo "请检查是否包含 API Key 或密码"
    exit 1
fi
```

### 2. 使用 git-secrets

```bash
# 安装
brew install git-secrets

# 配置
cd /Users/plutoguo/Desktop/XunDoc
git secrets --install
git secrets --register-aws
git secrets --add 'sk-[A-Za-z0-9]{48}'
```

### 3. 使用 GitHub Secret Scanning

GitHub 会自动扫描公开仓库中的敏感信息，但已经太晚了。

---

## 📞 需要帮助？

如果你有任何问题或需要帮助：

- 📧 Email: plutoguogg@gmail.com
- 🔗 GitHub Issues: https://github.com/pluto627/XunDoc/issues
- 📖 配置指南: [API_KEY_SETUP.md](API_KEY_SETUP.md)

---

## 📋 更新日志

- **2025-10-31**: 发现 API Key 泄露问题
- **2025-10-31**: Commit `e130c33` 修复硬编码问题
- **待定**: 清理 Git 历史记录

---

**安全无小事，请认真对待！🔒**

如果你已经完成了所有必要的操作，可以删除这个通知文件。

