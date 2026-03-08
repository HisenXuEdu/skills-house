# 🔧 构建错误修复指南

## 问题：crypto.getRandomValues is not a function

这个错误通常是 Node.js 版本与 Vite 不兼容导致的。

---

## ✅ 解决方案

### 方案 1: 使用简化部署脚本（推荐）

如果遇到构建问题，使用简化版本（使用 CDN 资源，不需要构建）：

```bash
# 在目标服务器上执行
curl -fsSL https://git.woa.com/hisenxu/skills-house/-/raw/master/install-simple.sh | bash
```

**或手动执行**：
```bash
git clone https://git.woa.com/hisenxu/skills-house.git /data/skills-house
cd /data/skills-house
chmod +x install-simple.sh
./install-simple.sh
```

这个脚本会：
- ✅ 跳过前端构建
- ✅ 使用 CDN 提供的 Vue 和 Axios
- ✅ 创建简化的 HTML 页面
- ✅ 功能完整（上传、下载、搜索都可用）

---

### 方案 2: 升级 Node.js

确保 Node.js 版本 >= 18：

```bash
# 检查版本
node -v

# 如果版本低于 v18，升级：
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# 或使用 apt (Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# 验证
node -v
npm -v
```

然后重新运行部署：
```bash
cd /data/skills-house
./install.sh
```

---

### 方案 3: 手动构建（已有最新代码）

如果你已经拉取了最新代码：

```bash
cd /data/skills-house

# 拉取最新代码
git pull

# 安装依赖
npm install
cd client && npm install && cd ..

# 尝试构建
cd client
npm run build
cd ..

# 启动服务
systemctl restart skills-house
```

---

### 方案 4: 使用 Docker

Docker 会使用确定的 Node.js 版本，避免兼容性问题：

```bash
cd /data/skills-house

# 拉取最新代码
git pull

# Docker 构建并启动
docker-compose build
docker-compose up -d

# 查看状态
docker-compose ps
docker-compose logs -f
```

访问: `http://your-server:3000`

---

## 🧪 测试构建

在服务器上测试构建是否成功：

```bash
cd /data/skills-house/client

# 尝试构建
npm run build

# 如果成功，应该看到 dist/ 目录
ls -la dist/
```

---

## 📋 当前已有的部署脚本

| 脚本 | 说明 | 适用场景 |
|------|------|----------|
| `install-simple.sh` | ⭐ 简化部署，不需要构建 | **构建失败时推荐** |
| `install.sh` | 完整部署，包含前端构建 | Node.js >= v18 |
| `deploy-docker.sh` | Docker 部署 | 有 Docker 环境 |
| `deploy.sh` | 从本地推送部署 | 本地有 SSH 访问 |

---

## 🆘 仍然失败？

### 检查环境

```bash
# 查看系统信息
cat /etc/os-release

# 查看 Node.js 信息
node -v
npm -v

# 查看可用内存
free -h

# 查看磁盘空间
df -h
```

### 查看完整错误日志

```bash
cd /data/skills-house/client
npm run build 2>&1 | tee build.log
cat build.log
```

### 清理并重试

```bash
cd /data/skills-house

# 清理旧的 node_modules
rm -rf node_modules client/node_modules

# 重新安装
npm install
cd client && npm install && cd ..

# 再次尝试构建
cd client && npm run build
```

---

## ✅ 推荐的快速解决方式

**如果你只是想快速部署使用，直接运行**：

```bash
curl -fsSL https://git.woa.com/hisenxu/skills-house/-/raw/master/install-simple.sh | bash
```

这个版本虽然简化了前端，但所有核心功能都可用，足够日常使用！

---

**更新时间**: 2026-03-08  
**问题反馈**: hisenxu
