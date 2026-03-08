#!/bin/bash

# Skills House Docker 远程部署脚本
# 目标服务器: hisenxu-any3.devcloud.woa.com

set -e

REMOTE_HOST="hisenxu-any3.devcloud.woa.com"
REMOTE_USER="root"
REMOTE_DIR="/data/skills-house"
LOCAL_DIR="/root/.openclaw/workspace/skills-house"

echo "🐳 开始 Docker 部署 Skills House 到 ${REMOTE_HOST}..."

# 1. 创建部署包（包含所有文件）
echo "📦 创建完整部署包..."
cd $LOCAL_DIR
tar -czf /tmp/skills-house-full.tar.gz \
  --exclude=node_modules \
  --exclude=client/node_modules \
  --exclude=uploads \
  --exclude=.git \
  .

echo "✅ 部署包创建完成: /tmp/skills-house-full.tar.gz ($(du -h /tmp/skills-house-full.tar.gz | cut -f1))"

# 2. 上传到远程服务器
echo "⬆️  上传文件到远程服务器..."
ssh ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_DIR}"
scp /tmp/skills-house-full.tar.gz ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/

# 3. 在远程服务器上部署
echo "🚀 远程服务器部署中..."
ssh ${REMOTE_USER}@${REMOTE_HOST} << 'ENDSSH'
set -e

cd /data/skills-house

# 解压
echo "📂 解压文件..."
tar -xzf skills-house-full.tar.gz
rm skills-house-full.tar.gz

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先安装"
    exit 1
fi

# 停止旧容器（如果存在）
echo "🛑 停止旧容器..."
docker-compose down 2>/dev/null || true

# 构建并启动
echo "🔨 构建 Docker 镜像..."
docker-compose build

echo "🚀 启动容器..."
docker-compose up -d

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 5

# 检查状态
echo "📊 容器状态:"
docker-compose ps

echo "📋 查看日志:"
docker-compose logs --tail=20

ENDSSH

# 4. 清理本地临时文件
rm /tmp/skills-house-full.tar.gz

echo ""
echo "🎉 Docker 部署完成！"
echo ""
echo "📡 访问地址: http://${REMOTE_HOST}:3000"
echo ""
echo "🔧 管理命令:"
echo "  查看日志: ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ${REMOTE_DIR} && docker-compose logs -f'"
echo "  重启服务: ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ${REMOTE_DIR} && docker-compose restart'"
echo "  停止服务: ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ${REMOTE_DIR} && docker-compose down'"
echo "  查看状态: ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd ${REMOTE_DIR} && docker-compose ps'"
echo ""
