#!/bin/bash

# 🚀 Skills House AnyDev 一键部署脚本
# 在 hisenxu-any3.devcloud.woa.com 上执行

set -e

echo "=========================================="
echo "🏠 Skills House 部署到 AnyDev"
echo "目标: hisenxu-any3.devcloud.woa.com"
echo "=========================================="
echo ""

# 检查是否在正确的机器上
HOSTNAME=$(hostname)
if [[ "$HOSTNAME" != *"hisenxu-any3"* ]]; then
    echo "⚠️  警告: 当前主机名是 $HOSTNAME"
    echo "请确认你在正确的机器上运行此脚本"
    echo ""
    read -p "继续部署吗? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 配置
DEPLOY_DIR="/data/skills-house"
REPO_URL="https://git.woa.com/hisenxu/skills-house.git"
PORT=3100

# 1. 检查环境
echo "🔍 检查环境..."

# 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装，正在安装..."
    curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
    yum install -y nodejs
fi

NODE_VERSION=$(node -v)
echo "✅ Node.js $NODE_VERSION"
echo "✅ npm $(npm -v)"

# 检查 Git
if ! command -v git &> /dev/null; then
    echo "📦 安装 Git..."
    yum install -y git || apt-get install -y git
fi
echo "✅ Git $(git --version | cut -d' ' -f3)"

# 2. 克隆/更新代码
echo ""
echo "📥 获取代码..."

if [ -d "$DEPLOY_DIR" ]; then
    echo "目录已存在，更新代码..."
    cd $DEPLOY_DIR
    
    # 保存 uploads 目录
    if [ -d "uploads" ]; then
        echo "💾 备份数据..."
        cp -r uploads uploads.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    git fetch origin
    git reset --hard origin/master
    git pull origin master
else
    echo "克隆仓库..."
    git clone $REPO_URL $DEPLOY_DIR
    cd $DEPLOY_DIR
fi

echo "✅ 代码已更新"
git log -1 --oneline

# 3. 安装依赖
echo ""
echo "📦 安装依赖..."

# 清理旧的依赖
rm -rf node_modules client/node_modules

# 安装后端依赖
npm install

# 4. 构建前端（使用简化版本）
echo ""
echo "🎨 准备前端..."

# 检查 Node 版本，决定构建策略
NODE_MAJOR=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)

if [ "$NODE_MAJOR" -ge 18 ]; then
    echo "Node.js >= v18，尝试完整构建..."
    cd client
    npm install
    
    if npm run build; then
        echo "✅ 前端构建成功"
    else
        echo "⚠️  构建失败，使用简化版本..."
        cd ..
        ./install-simple.sh
        exit 0
    fi
    cd ..
else
    echo "Node.js < v18，使用简化版本..."
    mkdir -p client/dist
    
    cat > client/dist/index.html << 'HTMLEOF'
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
    body { font-family: -apple-system, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; }
    .header { background: rgba(255,255,255,0.95); padding: 30px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 30px; text-align: center; }
    .header h1 { font-size: 2.5rem; color: #667eea; margin-bottom: 10px; }
    .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
    .action-bar { display: flex; gap: 20px; margin-bottom: 30px; }
    .search-input { flex: 1; padding: 12px 20px; border: none; border-radius: 25px; font-size: 1rem; }
    .btn { padding: 12px 24px; border: none; border-radius: 8px; cursor: pointer; background: #667eea; color: white; font-weight: 600; }
    .btn:hover { background: #5568d3; transform: translateY(-2px); }
    .skills-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 20px; }
    .skill-card { background: white; border-radius: 12px; padding: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
    .skill-card h3 { color: #333; margin-bottom: 10px; }
    .loading { color: white; text-align: center; padding: 60px; font-size: 1.2rem; }
    .version { background: #667eea; color: white; padding: 4px 10px; border-radius: 12px; font-size: 0.85rem; }
  </style>
</head>
<body>
  <div id="app">
    <header class="header">
      <h1>🏠 Skills House</h1>
      <p>OpenClaw Skills 管理平台 - 部署在 AnyDev</p>
    </header>
    <main class="container">
      <div class="action-bar">
        <input v-model="searchQuery" @input="searchSkills" class="search-input" placeholder="🔍 搜索 Skills...">
        <button @click="showUpload = true" class="btn">⬆️ 上传 Skill</button>
      </div>
      <div class="skills-grid">
        <div v-if="loading" class="loading">加载中...</div>
        <div v-else-if="skills.length === 0" class="loading">📦 还没有 Skills，快来上传第一个吧！</div>
        <div v-else class="skill-card" v-for="skill in skills" :key="skill.id">
          <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px">
            <h3>{{ skill.name }}</h3>
            <span class="version">v{{ skill.version }}</span>
          </div>
          <p style="color:#666;margin-bottom:15px">{{ skill.description }}</p>
          <div style="display:flex;justify-content:space-between;color:#999;font-size:0.9rem;margin-bottom:15px">
            <span>👤 {{ skill.author }}</span>
            <span>📥 {{ skill.downloadCount }} 次下载</span>
          </div>
          <div style="display:flex;gap:8px">
            <button @click="download(skill.id)" class="btn" style="padding:6px 12px;font-size:0.9rem">下载</button>
            <button @click="deleteSkill(skill.id)" class="btn" style="padding:6px 12px;font-size:0.9rem;background:#e74c3c">删除</button>
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
          } catch(e) { alert('加载失败: ' + e.message); }
          finally { this.loading = false; }
        },
        async searchSkills() {
          if (!this.searchQuery) { this.loadSkills(); return; }
          this.loading = true;
          try {
            const res = await axios.get('/api/skills/search?q=' + this.searchQuery);
            this.skills = res.data;
          } finally { this.loading = false; }
        },
        async download(id) {
          window.location.href = '/api/skills/' + id + '/download';
          setTimeout(() => this.loadSkills(), 1000);
        },
        async deleteSkill(id) {
          if (!confirm('确定要删除这个 Skill 吗？')) return;
          try {
            await axios.delete('/api/skills/' + id);
            alert('✅ 删除成功');
            this.loadSkills();
          } catch(e) { alert('删除失败: ' + e.message); }
        }
      }
    }).mount('#app');
  </script>
</body>
</html>
HTMLEOF
    
    echo "✅ 简化前端页面已创建"
fi

# 5. 配置 Systemd 服务
echo ""
echo "⚙️  配置服务..."

mkdir -p logs

cat > /etc/systemd/system/skills-house.service << EOF
[Unit]
Description=Skills House Service on AnyDev
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

# 6. 启动服务
echo ""
echo "🚀 启动服务..."

systemctl daemon-reload
systemctl enable skills-house
systemctl restart skills-house

# 等待服务启动
sleep 3

# 7. 检查状态
echo ""
echo "📊 服务状态:"
systemctl status skills-house --no-pager -l || true

# 8. 检查端口
echo ""
echo "🔌 检查端口..."
netstat -tlnp | grep $PORT || lsof -i :$PORT || echo "端口检查工具不可用"

echo ""
echo "=========================================="
echo "🎉 部署完成！"
echo "=========================================="
echo ""
echo "📡 访问地址:"
echo "   http://$(hostname):$PORT"
echo "   http://hisenxu-any3.devcloud.woa.com:$PORT"
echo ""
echo "🔧 管理命令:"
echo "   查看状态: systemctl status skills-house"
echo "   查看日志: journalctl -u skills-house -f"
echo "   重启服务: systemctl restart skills-house"
echo "   停止服务: systemctl stop skills-house"
echo ""
echo "📂 部署目录: $DEPLOY_DIR"
echo "📊 当前版本: $(cd $DEPLOY_DIR && git log -1 --oneline)"
echo ""
