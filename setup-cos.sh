#!/bin/bash

# Skills House - COS 快速配置脚本
# 用法：./setup-cos.sh

set -e

echo "========================================="
echo "Skills House - COS 对象存储配置向导"
echo "========================================="
echo ""

# 检查是否在正确的目录
if [ ! -f "server/index.js" ]; then
  echo "❌ 错误：请在 Skills House 项目根目录运行此脚本"
  exit 1
fi

echo "📋 本脚本将帮助你配置腾讯云 COS 对象存储"
echo ""

# 询问是否要配置 COS
read -p "是否要配置 COS 存储？(y/n): " CONFIGURE_COS
if [ "$CONFIGURE_COS" != "y" ]; then
  echo "⏭️  跳过 COS 配置"
  exit 0
fi

echo ""
echo "📝 请准备以下信息："
echo "1. COS SecretId（从腾讯云 CAM 控制台获取）"
echo "2. COS SecretKey"
echo "3. COS Bucket 名称（如：skills-house-1234567890）"
echo "4. COS Region（如：ap-guangzhou）"
echo ""
read -p "按 Enter 继续..."

echo ""
echo "🔧 开始配置..."
echo ""

# 输入 SecretId
read -p "请输入 COS_SECRET_ID: " SECRET_ID
if [ -z "$SECRET_ID" ]; then
  echo "❌ SecretId 不能为空"
  exit 1
fi

# 输入 SecretKey
read -p "请输入 COS_SECRET_KEY: " SECRET_KEY
if [ -z "$SECRET_KEY" ]; then
  echo "❌ SecretKey 不能为空"
  exit 1
fi

# 输入 Bucket
read -p "请输入 COS_BUCKET (如 skills-house-1234567890): " BUCKET
if [ -z "$BUCKET" ]; then
  echo "❌ Bucket 不能为空"
  exit 1
fi

# 输入 Region
read -p "请输入 COS_REGION (默认 ap-guangzhou): " REGION
REGION=${REGION:-ap-guangzhou}

# 输入 CDN（可选）
read -p "请输入 CDN 域名（可选，直接按 Enter 跳过）: " CDN

# 输入 JWT Secret
read -p "请输入 JWT_SECRET（默认使用随机生成）: " JWT_SECRET
if [ -z "$JWT_SECRET" ]; then
  JWT_SECRET=$(openssl rand -hex 32)
  echo "🔐 已生成随机 JWT_SECRET"
fi

# 创建 .env 文件
echo ""
echo "📝 创建 .env 文件..."

cat > .env << EOF
# Skills House 环境变量配置
# 生成时间: $(date)

# JWT Secret
JWT_SECRET=$JWT_SECRET

# 服务器端口
PORT=3100

# COS 对象存储配置
COS_SECRET_ID=$SECRET_ID
COS_SECRET_KEY=$SECRET_KEY
COS_BUCKET=$BUCKET
COS_REGION=$REGION
EOF

if [ -n "$CDN" ]; then
  echo "COS_CDN=$CDN" >> .env
fi

echo "✅ .env 文件已创建"

# 安装依赖
echo ""
echo "📦 安装 COS SDK..."
npm install cos-nodejs-sdk-v5 --save

echo ""
echo "========================================="
echo "✅ COS 配置完成！"
echo "========================================="
echo ""
echo "配置信息："
echo "  Bucket: $BUCKET"
echo "  Region: $REGION"
if [ -n "$CDN" ]; then
  echo "  CDN: $CDN"
fi
echo ""
echo "⚠️  重要提示："
echo "1. .env 文件包含敏感信息，请勿提交到 Git"
echo "2. 已添加到 .gitignore"
echo "3. 需要修改 server/index.js 以支持 COS"
echo ""
echo "📚 下一步："
echo "1. 阅读 COS_CODE_CHANGES.md 了解如何修改代码"
echo "2. 或使用自动补丁脚本: ./apply-cos-patch.sh"
echo "3. 重启服务: systemctl restart skills-house"
echo ""
echo "🔍 验证配置："
echo "journalctl -u skills-house -n 20"
echo "应该看到: ✅ COS 存储已启用"
echo ""
