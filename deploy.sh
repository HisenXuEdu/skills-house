#!/bin/bash

# Skills House 远程部署脚本
# 目标服务器: hisenxu-any3.devcloud.woa.com

set -e

REMOTE_HOST="hisenxu-any3.devcloud.woa.com"
REMOTE_USER="root"  # 根据实际情况修改
REMOTE_DIR="/data/skills-house"
LOCAL_DIR="/root/.openclaw/workspace/skills-house"

echo "🚀 开始部署 Skills House 到 ${REMOTE_HOST}..."

# 1. 创建部署包
echo "📦 创建部署包..."
cd $LOCAL_DIR
tar -czf /tmp/skills-house.tar.gz \
  --exclude=node_modules \
  --exclude=client/node_modules \
  --exclude=uploads \
  --exclude=.git \
  --exclude=client/dist \
  .

echo "✅ 部署包创建完成: /tmp/skills-house.tar.gz"

# 2. 上传到远程服务器
echo "⬆️  上传文件到远程服务器..."
ssh ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_DIR}"
scp /tmp/skills-house.tar.gz ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/

# 3. 在远程服务器上解压和安装
echo "📂 解压和配置..."
ssh ${REMOTE_USER}@${REMOTE_HOST} << 'ENDSSH'
cd /data/skills-house
tar -xzf skills-house.tar.gz
rm skills-house.tar.gz

# 安装依赖
echo "📦 安装依赖..."
npm install
cd client && npm install && cd ..

# 构建前端
echo "🔨 构建前端..."
cd client && npm run build && cd ..

# 创建 systemd 服务
echo "⚙️  配置 systemd 服务..."
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

[Install]
WantedBy=multi-user.target
EOF

# 重载 systemd 并启动服务
systemctl daemon-reload
systemctl enable skills-house
systemctl restart skills-house

echo "✅ 服务已启动！"
systemctl status skills-house --no-pager

ENDSSH

# 4. 清理本地临时文件
rm /tmp/skills-house.tar.gz

echo ""
echo "🎉 部署完成！"
echo ""
echo "📡 访问地址: http://${REMOTE_HOST}:3100"
echo ""
echo "🔧 管理命令:"
echo "  查看状态: ssh ${REMOTE_USER}@${REMOTE_HOST} 'systemctl status skills-house'"
echo "  查看日志: ssh ${REMOTE_USER}@${REMOTE_HOST} 'journalctl -u skills-house -f'"
echo "  重启服务: ssh ${REMOTE_USER}@${REMOTE_HOST} 'systemctl restart skills-house'"
echo "  停止服务: ssh ${REMOTE_USER}@${REMOTE_HOST} 'systemctl stop skills-house'"
echo ""
