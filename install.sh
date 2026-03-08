#!/bin/bash

# 🚀 Skills House 一键部署脚本
# 在目标服务器 hisenxu-any3.devcloud.woa.com 上直接运行此脚本

set -e

REPO_URL="https://git.woa.com/hisenxu/skills-house.git"
DEPLOY_DIR="/data/skills-house"
PORT=3100

echo "🏠 Skills House 一键部署"
echo "================================"
echo ""

# 1. 检查必要工具
echo "🔍 检查环境..."

if ! command -v git &> /dev/null; then
    echo "❌ Git 未安装，正在安装..."
    yum install -y git || apt-get install -y git
fi

if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装"
    echo "请先安装 Node.js v18+:"
    echo "  curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -"
    echo "  yum install -y nodejs"
    exit 1
fi

echo "✅ Node.js $(node -v)"
echo "✅ npm $(npm -v)"

# 2. 克隆或更新代码
echo ""
echo "📥 获取代码..."

if [ -d "$DEPLOY_DIR" ]; then
    echo "目录已存在，更新代码..."
    cd $DEPLOY_DIR
    git pull origin master
else
    echo "克隆仓库..."
    git clone $REPO_URL $DEPLOY_DIR
    cd $DEPLOY_DIR
fi

# 3. 安装依赖
echo ""
echo "📦 安装依赖..."

npm install

if [ -d "client" ]; then
    cd client
    npm install
    cd ..
fi

# 4. 构建前端
echo ""
echo "🔨 构建前端..."

cd client
npm run build
cd ..

# 5. 配置服务
echo ""
echo "⚙️  配置服务..."

# 创建日志目录
mkdir -p logs

# 检查部署方式偏好
if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
    echo ""
    echo "检测到 Docker，是否使用 Docker 部署？(y/n)"
    read -t 10 -n 1 use_docker || use_docker="n"
    echo ""
    
    if [ "$use_docker" = "y" ] || [ "$use_docker" = "Y" ]; then
        echo "🐳 使用 Docker 部署..."
        docker-compose down 2>/dev/null || true
        docker-compose build
        docker-compose up -d
        
        echo ""
        echo "✅ Docker 容器已启动！"
        docker-compose ps
        
        echo ""
        echo "📡 访问地址: http://$(hostname):3000"
        echo ""
        echo "🔧 管理命令:"
        echo "  查看日志: docker-compose logs -f"
        echo "  重启: docker-compose restart"
        echo "  停止: docker-compose down"
        exit 0
    fi
fi

# 使用 Systemd
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

# 重载并启动
systemctl daemon-reload
systemctl enable skills-house
systemctl restart skills-house

# 等待启动
sleep 3

echo ""
echo "✅ 服务已启动！"
echo ""

# 显示状态
systemctl status skills-house --no-pager -l

echo ""
echo "================================"
echo "🎉 部署完成！"
echo ""
echo "📡 访问地址: http://$(hostname):$PORT"
echo ""
echo "🔧 管理命令:"
echo "  查看状态: systemctl status skills-house"
echo "  查看日志: journalctl -u skills-house -f"
echo "  重启服务: systemctl restart skills-house"
echo "  停止服务: systemctl stop skills-house"
echo ""
echo "📂 部署目录: $DEPLOY_DIR"
echo ""
