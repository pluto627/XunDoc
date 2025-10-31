# 🔐 API Key 安全配置指南

## ⚠️ 重要提醒

**永远不要将 API Key 硬编码在代码中或提交到 Git 仓库！**

已暴露的 API Key 必须立即撤销并重新生成！

---

## 📋 快速设置步骤

### 1️⃣ 获取新的 API Key

由于之前的 API Key 已经泄露，请立即：

#### Moonshot AI (Kimi)
1. 访问：https://platform.moonshot.cn/console/api-keys
2. 登录你的账号
3. **撤销旧的 API Key**（如果还在列表中）
4. 点击"创建新的 API Key"
5. 复制新生成的 Key（只会显示一次）

#### Moonshot AI (通用)
1. 访问 Moonshot AI 控制台
2. 找到 API Key 管理页面
3. **撤销旧的 API Key**
4. 生成新的 API Key

### 2️⃣ 配置本地开发环境

#### 方法 A：使用 Config.swift 文件（推荐）

1. 复制示例配置文件：
```bash
cd XunDoc
cp Config.example.swift Config.swift
```

2. 编辑 `Config.swift`，填入你的新 API Key：
```swift
struct APIConfig {
    static let kimiAPIKey = "sk-YOUR-NEW-KIMI-KEY-HERE"
    static let moonshotAPIKey = "sk-YOUR-NEW-MOONSHOT-KEY-HERE"
}
```

3. **验证** `Config.swift` 已被 `.gitignore` 排除：
```bash
git status  # 不应该显示 Config.swift
```

#### 方法 B：直接修改 Manager 文件（仅本地测试）

⚠️ **注意**：如果选择这个方法，务必不要提交这些更改！

编辑以下文件，但**千万不要 git add 它们**：
- `XunDoc/Managers/KimiAPIManager.swift` (第 98 行)
- `XunDoc/Managers/MoonshotAPIManager.swift` (第 14 行)

### 3️⃣ 在 Xcode 中添加 Config.swift

如果使用方法 A：

1. 打开 `XunDoc.xcodeproj`
2. 右键点击 `XunDoc` 文件夹
3. 选择 "Add Files to XunDoc..."
4. 选择 `Config.swift`
5. 确保勾选 "Copy items if needed"

---

## 🔒 最佳实践

### ✅ 应该做的：
- ✅ 使用 `.gitignore` 排除配置文件
- ✅ 定期更换 API Key
- ✅ 为不同环境使用不同的 Key
- ✅ 限制 API Key 的权限和配额
- ✅ 监控 API Key 的使用情况

### ❌ 不应该做的：
- ❌ 将 API Key 硬编码在代码中
- ❌ 将 API Key 提交到 Git
- ❌ 在公共场所（截图、视频等）展示 API Key
- ❌ 与他人共享 API Key
- ❌ 在日志中打印 API Key

---

## 🚨 如果 API Key 泄露了怎么办？

1. **立即撤销**泄露的 API Key
2. **生成新的** API Key
3. **检查使用记录**，看是否有异常调用
4. **更新本地配置**使用新 Key
5. 如果已推送到 Git，考虑清理历史记录：

```bash
# ⚠️ 警告：这会改写 Git 历史，需要谨慎操作
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch XunDoc/Managers/KimiAPIManager.swift XunDoc/Managers/MoonshotAPIManager.swift" \
  --prune-empty --tag-name-filter cat -- --all

# 强制推送（会覆盖远程历史）
git push origin --force --all
git push origin --force --tags
```

---

## 📱 生产环境部署

对于生产环境，建议使用更安全的方式：

1. **环境变量**
2. **密钥管理服务**（如 AWS Secrets Manager、Azure Key Vault）
3. **CI/CD 工具的密钥存储**（如 GitHub Secrets）

---

## 💡 需要帮助？

- 📧 Email: plutoguogg@gmail.com
- 🔗 GitHub Issues: https://github.com/pluto627/XunDoc/issues

---

**记住：安全第一！🔒**

