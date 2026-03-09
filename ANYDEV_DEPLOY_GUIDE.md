# 使用 AnyDev 部署 Skills House 到 hisenxu-any3.devcloud.woa.com

## 🎯 部署目标

将 Skills House (Node.js + Express + Vue) 项目部署到 `hisenxu-any3.devcloud.woa.com` AnyDev 环境。

---

## ✅ 前提条件

1. ✅ **已安装 anydev-deploy Skill**
2. ✅ **Skills House 代码已推送到工蜂**: https://git.woa.com/hisenxu/skills-house
3. ✅ **AnyDev 环境已分配**: hisenxu-any3.devcloud.woa.com

---

## 🚀 部署步骤

### 步骤 1: 登录到 AnyDev 机器

```bash
# 使用 SSH 或 AnyDev WebShell 登录
ssh root@hisenxu-any3.devcloud.woa.com
```

### 步骤 2: 一键部署命令

在 AnyDev 机器上执行以下命令：

```bash
# 方式 1: 使用简化部署（推荐）
curl -fsSL https://git.woa.com/hisenxu/skills-house/-/raw/master/install-simple.sh | bash

# 方式 2: 使用 AnyDev 专用脚本
curl -fsSL https://git.woa.com/hisenxu/skills-house/-/raw/master/deploy-anydev.sh | bash

# 方式 3: 手动部署
git clone https://git.woa.com/hisenxu/skills-house.git /data/skills-house
cd /data/skills-house
chmod +x deploy-anydev.sh
./deploy-anydev.sh
```

### 步骤 3: 验证部署

```bash
# 检查服务状态
systemctl status skills-house

# 查看日志
journalctl -u skills-house -f

# 测试访问
curl http://localhost:3100
```

---

## 🌐 访问地址

部署成功后，通过以下地址访问：

```
http://hisenxu-any3.devcloud.woa.com:3100
```

---

## 📋 详细步骤（手动部署）

如果自动脚本失败，可以手动执行以下步骤：

### 1. 安装 Node.js

```bash
# 检查 Node.js 版本
node -v

# 如果版本 < v18，升级
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# 验证
node -v  # 应显示 v18.x 或更高
npm -v
```

### 2. 克隆代码

```bash
# 克隆仓库
git clone https://git.woa.com/hisenxu/skills-house.git /data/skills-house
cd /data/skills-house

# 查看最新提交
git log -1 --oneline
```

### 3. 安装依赖

```bash
# 安装后端依赖
npm install

# 如果需要完整构建前端（Node.js >= v18）
cd client
npm install
npm run build
cd ..
```

### 4. 创建简化前端（可选，构建失败时）

```bash
mkdir -p client/dist

cat > client/dist/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Skills House on AnyDev</title>
  <script src="https://cdn.jsdelivr.net/npm/vue@3.3.11/dist/vue.global.prod.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/axios@1.6.2/dist/axios.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
    .header { background: rgba(255,255,255,0.95); padding: 30px; text-align: center; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header h1 { color: #667eea; font-size: 2.5rem; margin-bottom: 10px; }
    .header .badge { background: #28a745; color: white; padding: 4px 12px; border-radius: 12px; font-size: 0.85rem; }
    .container { max-width: 1200px; margin: 30px auto; padding: 20px; }
    .btn { padding: 12px 24px; border: none; border-radius: 8px; background: #667eea; color: white; cursor: pointer; font-weight: 600; }
    .btn:hover { background: #5568d3; }
    .skills-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 20px; }
    .skill-card { background: white; border-radius: 12px; padding: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
    .loading { color: white; text-align: center; padding: 60px; font-size: 1.2rem; }
  </style>
</head>
<body>
  <div id="app">
    <header class="header">
      <h1>🏠 Skills House</h1>
      <p>OpenClaw Skills 管理平台 <span class="badge">on AnyDev</span></p>
    </header>
    <main class="container">
      <div style="display:flex;gap:20px;margin-bottom:30px">
        <input v-model="searchQuery" @input="search" placeholder="🔍 搜索..." style="flex:1;padding:12px 20px;border:none;border-radius:25px;font-size:1rem">
        <button class="btn">⬆️ 上传</button>
      </div>
      <div class="skills-grid">
        <div v-if="loading" class="loading">加载中...</div>
        <div v-else-if="skills.length === 0" class="loading">还没有 Skills</div>
        <div v-else class="skill-card" v-for="s in skills" :key="s.id">
          <h3>{{ s.name }}</h3>
          <p>{{ s.description }}</p>
          <button @click="download(s.id)" class="btn" style="margin-top:15px;padding:8px 16px;font-size:0.9rem">下载</button>
        </div>
      </div>
    </main>
  </div>
  <script>
    const { createApp } = Vue;
    createApp({
      data() { return { skills: [], loading: false, searchQuery: '' }; },
      mounted() { this.loadSkills(); },
      methods: {
        async loadSkills() {
          this.loading = true;
          try { 
            const res = await axios.get('/api/skills');
            this.skills = res.data;
          } catch(e) { alert('加载失败'); }
          finally { this.loading = false; }
        },
        async search() {
          if (!this.searchQuery) { this.loadSkills(); return; }
          this.loading = true;
          try {
            const res = await axios.get('/api/skills/search?q=' + this.searchQuery);
            this.skills = res.data;
          } finally { this.loading = false; }
        },
        download(id) { window.location.href = '/api/skills/' + id + '/download'; }
      }
    }).mount('#app');
  </script>
</body>
</html>
EOF

echo "✅ 简化前端页面已创建"
```

### 5. 配置 Systemd 服务

```bash
cat > /etc/systemd/system/skills-house.service << 'EOF'
[Unit]
Description=Skills House Service on AnyDev
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

# 重载并启动
systemctl daemon-reload
systemctl enable skills-house
systemctl start skills-house
```

### 6. 检查服务

```bash
# 查看状态
systemctl status skills-house

# 查看日志
journalctl -u skills-house -n 50

# 测试访问
curl http://localhost:3100
```

---

## 🔧 管理命令

```bash
# 查看服务状态
systemctl status skills-house

# 启动服务
systemctl start skills-house

# 停止服务
systemctl stop skills-house

# 重启服务
systemctl restart skills-house

# 查看实时日志
journalctl -u skills-house -f

# 查看最近100行日志
journalctl -u skills-house -n 100

# 更新代码并重启
cd /data/skills-house && git pull && systemctl restart skills-house
```

---

## 🔍 故障排查

### 端口被占用

```bash
# 查看端口占用
netstat -tlnp | grep 3100
lsof -i :3100

# 杀掉占用进程
kill -9 <PID>
```

### 服务无法启动

```bash
# 查看详细错误日志
journalctl -u skills-house -xe

# 手动启动测试
cd /data/skills-house
node server/index.js
```

### Node.js 版本问题

```bash
# 检查版本
node -v

# 如果是旧版本，使用 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 18
nvm use 18
```

### 防火墙问题

```bash
# 检查防火墙
firewall-cmd --list-ports

# 开放端口
firewall-cmd --zone=public --add-port=3100/tcp --permanent
firewall-cmd --reload
```

---

## 📊 环境信息

| 项目 | 值 |
|------|-----|
| **服务器** | hisenxu-any3.devcloud.woa.com |
| **部署路径** | /data/skills-house |
| **服务名称** | skills-house |
| **端口** | 3100 |
| **工蜂仓库** | https://git.woa.com/hisenxu/skills-house |
| **日志路径** | journalctl -u skills-house |

---

## 🎉 部署完成后

### 访问应用

```
http://hisenxu-any3.devcloud.woa.com:3100
```

### 测试功能

1. 上传 Skill
2. 搜索 Skill
3. 下载 Skill
4. 删除 Skill

---

## 📚 相关文档

- [部署脚本](./deploy-anydev.sh)
- [简化部署脚本](./install-simple.sh)
- [构建错误修复](./BUILD_FIX.md)
- [远程部署指南](./REMOTE_DEPLOY.md)

---

**部署愉快！** 🚀
