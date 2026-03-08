#!/bin/bash

# 🚀 Skills House 简化部署脚本
# 适用于 Node.js 版本较低或构建失败的情况
# 使用预构建的前端资源

set -e

REPO_URL="https://git.woa.com/hisenxu/skills-house.git"
DEPLOY_DIR="/data/skills-house"
PORT=3100

echo "🏠 Skills House 简化部署"
echo "================================"
echo ""

# 1. 检查 Node.js
echo "🔍 检查环境..."

if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装"
    exit 1
fi

echo "✅ Node.js $(node -v)"

# 2. 克隆代码
echo ""
echo "📥 获取代码..."

if [ -d "$DEPLOY_DIR" ]; then
    cd $DEPLOY_DIR
    git pull origin master
else
    git clone $REPO_URL $DEPLOY_DIR
    cd $DEPLOY_DIR
fi

# 3. 安装后端依赖
echo ""
echo "📦 安装后端依赖..."
npm install

# 4. 创建简单的静态前端（如果构建失败）
echo ""
echo "📝 创建前端页面..."

mkdir -p client/dist

cat > client/dist/index.html << 'EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Skills House</title>
  <script src="https://cdn.jsdelivr.net/npm/vue@3.3.11/dist/vue.global.prod.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/axios@1.6.2/dist/axios.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
    .header { background: rgba(255,255,255,0.95); padding: 30px 0; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 30px; text-align: center; }
    .header h1 { font-size: 2.5rem; color: #667eea; margin-bottom: 10px; }
    .container { max-width: 1200px; margin: 0 auto; padding: 0 20px; }
    .action-bar { display: flex; justify-content: space-between; margin-bottom: 30px; gap: 20px; }
    .search-input { flex: 1; padding: 12px 20px; border: none; border-radius: 25px; font-size: 1rem; }
    .btn { padding: 12px 24px; border: none; border-radius: 8px; cursor: pointer; background: #667eea; color: white; font-weight: 600; }
    .btn:hover { background: #5568d3; }
    .skills-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 20px; }
    .skill-card { background: white; border-radius: 12px; padding: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
    .skill-card h3 { color: #333; margin-bottom: 10px; }
    .loading { color: white; text-align: center; padding: 60px; }
  </style>
</head>
<body>
  <div id="app">
    <header class="header">
      <h1>🏠 Skills House</h1>
      <p>OpenClaw Skills 管理平台</p>
    </header>
    <main class="container">
      <div class="action-bar">
        <input v-model="searchQuery" @input="searchSkills" class="search-input" placeholder="🔍 搜索 Skills...">
        <button @click="showUpload = true" class="btn">⬆️ 上传</button>
      </div>
      <div class="skills-grid">
        <div v-if="loading" class="loading">加载中...</div>
        <div v-else-if="skills.length === 0" class="loading">还没有 Skills</div>
        <div v-else class="skill-card" v-for="skill in skills" :key="skill.id">
          <h3>{{ skill.name }}</h3>
          <p>{{ skill.description }}</p>
          <small>{{ skill.author }} - v{{ skill.version }}</small>
          <div style="margin-top:10px">
            <button @click="download(skill.id)" class="btn" style="padding:6px 12px;font-size:0.9rem">下载</button>
          </div>
        </div>
      </div>
    </main>
  </div>
  <script>
    const { createApp } = Vue;
    createApp({
      data() {
        return { skills: [], loading: false, searchQuery: '', showUpload: false };
      },
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
        async searchSkills() {
          this.loading = true;
          try {
            const res = await axios.get('/api/skills/search?q=' + this.searchQuery);
            this.skills = res.data;
          } finally { this.loading = false; }
        },
        async download(id) {
          window.location.href = '/api/skills/' + id + '/download';
          setTimeout(() => this.loadSkills(), 1000);
        }
      }
    }).mount('#app');
  </script>
</body>
</html>
EOF

echo "✅ 前端页面创建完成"

# 5. 配置服务
echo ""
echo "⚙️  配置服务..."

mkdir -p logs

cat > /etc/systemd/system/skills-house.service << EOF
[Unit]
Description=Skills House Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DEPLOY_DIR
Environment="PORT=$PORT"
Environment="NODE_ENV=production"
ExecStart=$(which node) server/index.js
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable skills-house
systemctl restart skills-house

sleep 3

echo ""
echo "✅ 服务已启动！"
systemctl status skills-house --no-pager -l || true

echo ""
echo "================================"
echo "🎉 部署完成！"
echo ""
echo "📡 访问地址: http://$(hostname):$PORT"
echo ""
echo "🔧 管理命令:"
echo "  systemctl status skills-house"
echo "  journalctl -u skills-house -f"
echo ""
