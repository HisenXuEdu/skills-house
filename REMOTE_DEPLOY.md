# 🚀 远程服务器部署指南

目标服务器: **hisenxu-any3.devcloud.woa.com**

---

## 🎯 方案选择

### 方案 1: 自动部署脚本 (推荐)

#### Docker 部署（最简单）
```bash
cd /root/.openclaw/workspace/skills-house
./deploy-docker.sh
```

**要求**:
- 远程服务器已安装 Docker 和 Docker Compose
- SSH 免密登录已配置

#### Systemd 服务部署
```bash
cd /root/.openclaw/workspace/skills-house
./deploy.sh
```

**要求**:
- 远程服务器已安装 Node.js (v18+)
- SSH 免密登录已配置

---

### 方案 2: 手动部署

#### 步骤 1: 创建部署包

```bash
cd /root/.openclaw/workspace/skills-house

# 创建压缩包
tar -czf skills-house.tar.gz \
  --exclude=node_modules \
  --exclude=client/node_modules \
  --exclude=uploads \
  --exclude=.git \
  --exclude=client/dist \
  .

# 查看包大小
ls -lh skills-house.tar.gz
```

#### 步骤 2: 上传到服务器

```bash
# 方式 1: SCP 上传
scp skills-house.tar.gz root@hisenxu-any3.devcloud.woa.com:/data/

# 方式 2: 通过跳板机
# 先上传到跳板机，再从跳板机传到目标服务器
```

#### 步骤 3: 在远程服务器上解压和配置

SSH 登录到服务器:
```bash
ssh root@hisenxu-any3.devcloud.woa.com
```

执行以下命令:
```bash
# 创建目录
mkdir -p /data/skills-house
cd /data/skills-house

# 解压（如果你已上传到其他位置，修改路径）
tar -xzf /data/skills-house.tar.gz

# 安装依赖
npm install
cd client && npm install && cd ..

# 构建前端
cd client && npm run build && cd ..
```

#### 步骤 4A: Docker 启动（推荐）

```bash
cd /data/skills-house

# 构建镜像
docker-compose build

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 查看状态
docker-compose ps
```

**访问地址**: `http://hisenxu-any3.devcloud.woa.com:3000`

#### 步骤 4B: 直接启动（开发测试）

```bash
cd /data/skills-house

# 后台启动
nohup npm start > logs/app.log 2>&1 &

# 查看日志
tail -f logs/app.log
```

**访问地址**: `http://hisenxu-any3.devcloud.woa.com:3000`

#### 步骤 4C: Systemd 服务（生产环境）

创建服务文件:
```bash
cat > /etc/systemd/system/skills-house.service << 'EOF'
[Unit]
Description=Skills House Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/data/skills-house
Environment="PORT=3100"
Environment="NODE_ENV=production"
ExecStart=/usr/bin/node server/index.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
```

启动服务:
```bash
# 重载配置
systemctl daemon-reload

# 启用开机自启
systemctl enable skills-house

# 启动服务
systemctl start skills-house

# 查看状态
systemctl status skills-house

# 查看日志
journalctl -u skills-house -f
```

**访问地址**: `http://hisenxu-any3.devcloud.woa.com:3100`

---

## 🔧 管理命令

### Docker 方式

```bash
# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启
docker-compose restart

# 停止
docker-compose down

# 重新构建
docker-compose build --no-cache
docker-compose up -d
```

### Systemd 方式

```bash
# 查看状态
systemctl status skills-house

# 启动
systemctl start skills-house

# 停止
systemctl stop skills-house

# 重启
systemctl restart skills-house

# 查看日志
journalctl -u skills-house -f

# 查看最近100行日志
journalctl -u skills-house -n 100
```

---

## 🌐 配置反向代理（可选）

### Nginx 配置

```nginx
server {
    listen 80;
    server_name skills.hisenxu-any3.devcloud.woa.com;

    location / {
        proxy_pass http://localhost:3100;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

应用配置:
```bash
# 测试配置
nginx -t

# 重载 Nginx
nginx -s reload
```

---

## 🔍 问题排查

### 检查端口占用

```bash
# 查看 3000 或 3100 端口
netstat -tlnp | grep 3100
lsof -i :3100
```

### 检查防火墙

```bash
# 开放端口
firewall-cmd --zone=public --add-port=3100/tcp --permanent
firewall-cmd --reload

# 或 iptables
iptables -I INPUT -p tcp --dport 3100 -j ACCEPT
```

### 检查服务状态

```bash
# Docker
docker-compose ps
docker-compose logs --tail=50

# Systemd
systemctl status skills-house
journalctl -u skills-house -n 50

# 进程
ps aux | grep node
```

### 查看磁盘空间

```bash
df -h
du -sh /data/skills-house
```

---

## 📝 配置修改

### 修改端口

**Docker 方式**:
编辑 `docker-compose.yml`:
```yaml
ports:
  - "8080:3000"  # 改为 8080 端口
```

**Systemd 方式**:
编辑 `/etc/systemd/system/skills-house.service`:
```ini
Environment="PORT=8080"
```
然后重启:
```bash
systemctl daemon-reload
systemctl restart skills-house
```

---

## 🔐 安全建议

1. **防火墙配置**: 只开放必要端口
2. **Nginx 反向代理**: 使用 Nginx 作为前端代理
3. **HTTPS**: 配置 SSL 证书
4. **认证**: 添加用户认证机制
5. **限流**: 防止滥用

---

## 📊 监控

### 使用 PM2（可选）

```bash
# 安装 PM2
npm install -g pm2

# 启动
cd /data/skills-house
pm2 start server/index.js --name skills-house

# 查看状态
pm2 status
pm2 logs skills-house

# 重启
pm2 restart skills-house

# 开机自启
pm2 startup
pm2 save
```

---

## 🆘 需要帮助？

- 工蜂仓库: https://git.woa.com/hisenxu/skills-house
- 查看 README.md 和 DEPLOYMENT.md

---

**祝部署顺利！** 🎉
