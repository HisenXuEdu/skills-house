#!/bin/bash

# Skills House - 部署脚本（支持 COS 存储）
# 用法：./deploy-with-cos.sh

set -e

echo "==================================="
echo "Skills House 部署脚本（COS 版本）"
echo "==================================="

# 配置
SERVER="175.27.141.110"
USER="root"
PASSWORD="Xuhaixin123"
DEPLOY_DIR="/data/skills-house"

echo ""
echo "📦 1. 打包项目文件..."
tar czf /tmp/skills-house-deploy.tar.gz \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='uploads/skills/*' \
  --exclude='uploads/temp/*' \
  --exclude='.env' \
  server/ client/ package.json .env.example

echo "✅ 打包完成"

echo ""
echo "📤 2. 上传到服务器..."
sshpass -p "$PASSWORD" scp /tmp/skills-house-deploy.tar.gz $USER@$SERVER:/tmp/

echo ""
echo "🔧 3. 在服务器上部署..."
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no $USER@$SERVER << 'ENDSSH'
  set -e
  
  echo "📂 解压文件..."
  cd /data/skills-house
  tar xzf /tmp/skills-house-deploy.tar.gz
  
  echo "📦 安装依赖（包含 COS SDK）..."
  npm install --production
  
  echo "🔐 检查环境变量配置..."
  if [ ! -f .env ]; then
    echo "⚠️  警告：.env 文件不存在"
    echo "   COS 存储将不会启用，使用本地文件存储"
    echo "   如需启用 COS，请参考 .env.example 创建 .env 文件"
  else
    echo "✅ .env 文件已存在"
    if grep -q "COS_SECRET_ID=" .env && ! grep -q "COS_SECRET_ID=$" .env; then
      echo "✅ COS 配置已启用"
    else
      echo "⚠️  COS 未配置，将使用本地存储"
    fi
  fi
  
  echo "🔄 重启服务..."
  systemctl restart skills-house
  
  echo "✅ 服务已重启"
  
  sleep 2
  echo ""
  echo "📊 服务状态："
  systemctl status skills-house --no-pager -l
  
ENDSSH

echo ""
echo "=================================="
echo "✅ 部署完成！"
echo "=================================="
echo ""
echo "访问地址: http://$SERVER:3100"
echo ""
echo "COS 配置说明："
echo "1. 如果需要启用 COS 存储，请在服务器上配置 .env 文件"
echo "2. 参考 .env.example 填写 COS 配置"
echo "3. 重启服务使配置生效: systemctl restart skills-house"
echo ""
echo "查看日志: journalctl -u skills-house -f"
echo ""
