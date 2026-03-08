# 🚀 部署到 hisenxu-any3.devcloud.woa.com

---

## 🎯 最简单的部署方式（推荐）

### 在目标服务器上执行以下命令：

```bash
# 登录到目标服务器
ssh root@hisenxu-any3.devcloud.woa.com

# 执行一键部署脚本
curl -fsSL https://git.woa.com/hisenxu/skills-house/-/raw/master/install.sh | bash
```

**仅需这一条命令！** 脚本会自动完成：
- ✅ 检查环境（Git, Node.js）
- ✅ 克隆代码
- ✅ 安装依赖
- ✅ 构建前端
- ✅ 配置并启动服务

### 或者手动执行：

```bash
# 登录服务器
ssh root@hisenxu-any3.devcloud.woa.com

# 下载并运行脚本
git clone https://git.woa.com/hisenxu/skills-house.git /data/skills-house
cd /data/skills-house
chmod +x install.sh
./install.sh
```

---

## 🎉 部署完成后

### 访问地址
```
http://hisenxu-any3.devcloud.woa.com:3100
```

### 管理命令

**查看服务状态**:
```bash
ssh root@hisenxu-any3.devcloud.woa.com 'systemctl status skills-house'
```

**查看实时日志**:
```bash
ssh root@hisenxu-any3.devcloud.woa.com 'journalctl -u skills-house -f'
```

**重启服务**:
```bash
ssh root@hisenxu-any3.devcloud.woa.com 'systemctl restart skills-house'
```

**更新代码**:
```bash
ssh root@hisenxu-any3.devcloud.woa.com 'cd /data/skills-house && git pull && systemctl restart skills-house'
```

---

## 📋 其他部署方案

### 方案 2: Docker 部署

如果服务器已安装 Docker:

```bash
# 登录服务器
ssh root@hisenxu-any3.devcloud.woa.com

# 克隆代码
git clone https://git.woa.com/hisenxu/skills-house.git /data/skills-house
cd /data/skills-house

# 启动
docker-compose up -d

# 查看状态
docker-compose ps
docker-compose logs -f
```

访问地址: `http://hisenxu-any3.devcloud.woa.com:3000`

### 方案 3: 从本地推送部署

如果你可以从本地 SSH 到目标服务器:

```bash
# 在本地执行
cd /root/.openclaw/workspace/skills-house

# Docker 部署
./deploy-docker.sh

# 或 Systemd 部署
./deploy.sh
```

---

## 🔍 问题排查

### 检查服务状态
```bash
ssh root@hisenxu-any3.devcloud.woa.com 'systemctl status skills-house'
```

### 查看端口占用
```bash
ssh root@hisenxu-any3.devcloud.woa.com 'netstat -tlnp | grep 3100'
```

### 检查防火墙
```bash
ssh root@hisenxu-any3.devcloud.woa.com 'firewall-cmd --list-ports'
```

### 开放端口（如需要）
```bash
ssh root@hisenxu-any3.devcloud.woa.com 'firewall-cmd --zone=public --add-port=3100/tcp --permanent && firewall-cmd --reload'
```

---

## 📚 相关文档

- **完整部署指南**: [REMOTE_DEPLOY.md](./REMOTE_DEPLOY.md)
- **项目说明**: [README.md](./README.md)
- **本地部署**: [DEPLOYMENT.md](./DEPLOYMENT.md)

---

## 🆘 需要帮助？

如果部署遇到问题，请提供以下信息：

1. 服务器环境信息:
   ```bash
   ssh root@hisenxu-any3.devcloud.woa.com 'cat /etc/os-release && node -v && npm -v'
   ```

2. 服务日志:
   ```bash
   ssh root@hisenxu-any3.devcloud.woa.com 'journalctl -u skills-house -n 50'
   ```

3. 端口状态:
   ```bash
   ssh root@hisenxu-any3.devcloud.woa.com 'netstat -tlnp'
   ```

---

**祝部署成功！** 🎊
