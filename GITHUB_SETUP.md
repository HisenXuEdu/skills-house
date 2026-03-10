# 推送 Skills House 到 GitHub

## 步骤 1: 在 GitHub 上创建仓库

访问：https://github.com/new

填写信息：
- **Repository name**: `skills-house`
- **Description**: `Skills House - OpenClaw Skills Management Platform (Vue 3 + Express)`
- **Visibility**: Public (或 Private，根据你的需求)
- **不要勾选**: "Initialize this repository with a README"

点击 "Create repository"

## 步骤 2: 添加 GitHub 远程仓库

创建完成后，GitHub 会显示仓库地址，例如：
```
https://github.com/YOUR_USERNAME/skills-house.git
```

运行以下命令添加 GitHub 远程仓库：

```bash
cd /root/.openclaw/workspace/skills-house
git remote add github https://github.com/YOUR_USERNAME/skills-house.git
```

## 步骤 3: 推送到 GitHub

```bash
git push github master
```

或者推送所有分支和标签：

```bash
git push github --all
git push github --tags
```

## 一键脚本

替换 `YOUR_USERNAME` 为你的 GitHub 用户名，然后运行：

```bash
#!/bin/bash
GITHUB_USERNAME="YOUR_USERNAME"
REPO_NAME="skills-house"

cd /root/.openclaw/workspace/skills-house

# 添加 GitHub 远程仓库
git remote add github "https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

# 推送到 GitHub
git push github master

echo "✅ Skills House 已推送到 GitHub!"
echo "🔗 访问：https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"
```

## 当前仓库信息

- **本地路径**: `/root/.openclaw/workspace/skills-house`
- **工蜂仓库**: `https://git.woa.com/hisenxu/skills-house.git`
- **最新提交**: 已同步所有文件
- **分支**: master

## 注意事项

1. **认证方式**：
   - 使用 HTTPS 需要 Personal Access Token
   - 生成 Token：https://github.com/settings/tokens
   - Token 权限需要包含 `repo`

2. **首次推送**：
   ```bash
   git push -u github master
   ```

3. **查看所有远程仓库**：
   ```bash
   git remote -v
   ```

4. **后续推送**：
   ```bash
   # 推送到工蜂
   git push origin master
   
   # 推送到 GitHub
   git push github master
   
   # 同时推送到两个远程仓库
   git push origin master && git push github master
   ```
