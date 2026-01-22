# Git LFS 配置指南 - ProjectEmber_Dev

本文档提供使用 Git LFS 管理 Unreal Engine 项目的完整步骤。

## 前置条件

Git LFS 已安装：`git-lfs/3.7.1`

---

## 步骤 1: 初始化 Git 仓库

```bash
cd D:\UserDocument\UnrealProject\ProjectEmber_Dev
git init
```

---

## 步骤 2: 配置 Git LFS

### 2.1 安装 Git LFS 钩子

```bash
git lfs install
```

### 2.2 配置需要 LFS 跟踪的文件类型

```bash
# UE 二进制资源文件
git lfs track "*.uasset"

# UE 地图文件
git lfs track "*.umap"

# UE 其他二进制文件
git lfs track "*.udk"
git lfs track "*.uplugin"

# 3D 模型文件
git lfs track "*.fbx"

# 贴图/图片源文件（建议保留源文件用LFS，生成的uasset也会被LFS跟踪）
git lfs track "*.psd"
git lfs track "*.png"
git lfs track "*.jpg"
git lfs track "*.jpeg"
git lfs track "*.tga"
git lfs track "*.exr"
git lfs track "*.hdr"

# 音频文件
git lfs track "*.wav"
git lfs track "*.mp3"
git lfs track "*.ogg"
git lfs track "*.wma"

# 视频文件
git lfs track "*.mp4"
git lfs track "*.mov"
git lfs track "*.avi"

# 压缩文件
git lfs track "*.zip"
git lfs track "*.rar"
git lfs track "*.7z"
```

### 2.3 验证 LFS 配置

执行完上述命令后，会生成 `.gitattributes` 文件。确认内容包含：

```
*.uasset filter=lfs diff=lfs merge=lfs -text
*.umap filter=lfs diff=lfs merge=lfs -text
...
```

---

## 步骤 3: 创建 .gitignore 文件

在项目根目录创建 `.gitignore` 文件，添加以下内容：

```gitignore
# Unreal Engine generated files
Intermediate/
Binaries/
Build/
Saved/
DerivedDataCache/
.vs/
.vscode/
*.opensdf
*.opendb
*.sdf
*.sln
*.suo
*.xcodeproj/
*.xcworkspace/

# IDE files
.vs/
.idea/
*.swp
*.swo
*~

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
desktop.ini

# Cache files
*.vcxproj
*.vcxproj.filters
*.user

# Plugin metadata
*.ipa
*.apk

# Marketplace files
Marketplace/

# Temporary files
*.tmp
*.temp
*.log
```

---

## 步骤 4: 提交初始配置

```bash
# 添加所有文件
git add .

# 查看状态（确认LFS文件被正确识别）
git status

# 提交
git commit -m "Initial commit with Git LFS configuration"
```

---

## 步骤 5: 关联远程仓库（可选）

如果你有远程仓库（GitHub、GitLab等）：

```bash
# 添加远程仓库（替换为你的仓库地址）
git remote add origin https://github.com/username/ProjectEmber_Dev.git

# 推送到远程
git push -u origin main
```

**注意**: 确保远程仓库支持 LFS（GitHub、GitLab、Bitbucket 等主流平台都支持）。

---

## 验证 LFS 工作正常

```bash
# 查看 LFS 跟踪的文件列表
git lfs track

# 查看 LFS 状态
git lfs status
```

---

## 常用 Git LFS 命令

| 命令 | 说明 |
|------|------|
| `git lfs install` | 安装 LFS 钩子 |
| `git lfs track "*.ext"` | 跟踪指定扩展名的文件 |
| `git lfs untrack "*.ext"` | 取消跟踪 |
| `git lfs track` | 列出所有 LFS 跟踪的文件类型 |
| `git lfs status` | 查看 LFS 文件状态 |
| `git lfs ls-files` | 列出所有 LFS 文件 |
| `git lfs prune` | 清理未引用的 LFS 文件 |
| `git lfs migrate import --include="*.uasset"` | 迁移现有仓库的文件到 LFS |

---

## 注意事项

1. **LFS 配额**: GitHub 免费账户有 1GB LFS 存储限额和每月 1GB 流量限制
2. **首次克隆**: 使用 `git clone` 时会自动下载 LFS 文件
3. **仅下载源码**: 如需不下载 LFS 文件，使用 `GIT_LFS_SKIP_SMUDGE=1 git clone`
4. **团队协作**: 确保所有团队成员都安装了 Git LFS
