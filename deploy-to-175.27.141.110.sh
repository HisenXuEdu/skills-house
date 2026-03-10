#!/bin/bash

# Skills House 部署脚本 - 保留原有 Node.js 版本
# 目标机器: 175.27.141.110
# 使用方法: curl -fsSL https://raw.githubusercontent.com/HisenXuEdu/skills-house/master/deploy-to-175.27.141.110.sh | bash

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Skills House 部署脚本${NC}"
echo -e "${BLUE}  目标机器: 175.27.141.110${NC}"
echo -e "${BLUE}  保留原有 Node.js 版本${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# 1. 检查 Node.js 版本
echo -e "${BLUE}📋 检查当前 Node.js 环境...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ 错误：未安装 Node.js${NC}"
    echo -e "${YELLOW}请先安装 Node.js (>= v14)${NC}"
    exit 1
fi

NODE_VERSION=$(node --version)
echo -e "${GREEN}✓ Node.js 版本: ${NODE_VERSION}${NC}"

# 检查版本是否满足要求 (>= v14)
NODE_MAJOR=$(node --version | cut -d'.' -f1 | sed 's/v//')
if [ "$NODE_MAJOR" -lt 14 ]; then
    echo -e "${RED}❌ 错误：Node.js 版本过低 (需要 >= v14)${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ 错误：未安装 npm${NC}"
    exit 1
fi

NPM_VERSION=$(npm --version)
echo -e "${GREEN}✓ npm 版本: ${NPM_VERSION}${NC}"
echo ""

# 2. 设置部署目录
DEPLOY_DIR="/data/skills-house"
echo -e "${BLUE}📂 部署目录: ${DEPLOY_DIR}${NC}"

# 3. 备份旧版本（如果存在）
if [ -d "$DEPLOY_DIR" ]; then
    BACKUP_DIR="${DEPLOY_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}⚠️  检测到已存在的部署，备份到: ${BACKUP_DIR}${NC}"
    mv "$DEPLOY_DIR" "$BACKUP_DIR"
fi

# 4. 创建部署目录
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

# 5. 克隆仓库
echo -e "${BLUE}📥 克隆仓库...${NC}"
if command -v git &> /dev/null; then
    git clone https://github.com/HisenXuEdu/skills-house.git .
else
    echo -e "${YELLOW}⚠️  未安装 git，使用 curl 下载...${NC}"
    curl -L https://github.com/HisenXuEdu/skills-house/archive/refs/heads/master.tar.gz -o skills-house.tar.gz
    tar -xzf skills-house.tar.gz --strip-components=1
    rm -f skills-house.tar.gz
fi

echo -e "${GREEN}✓ 代码下载完成${NC}"
echo ""

# 6. 安装依赖（服务端）
echo -e "${BLUE}📦 安装服务端依赖...${NC}"
npm install --production
echo -e "${GREEN}✓ 服务端依赖安装完成${NC}"
echo ""

# 7. 创建 uploads 目录
mkdir -p uploads
echo -e "${GREEN}✓ 创建 uploads 目录${NC}"
echo ""

# 8. 配置环境变量
cat > .env << 'EOF'
PORT=3100
NODE_ENV=production
UPLOAD_DIR=uploads
EOF
echo -e "${GREEN}✓ 环境配置完成${NC}"
echo ""

# 9. 创建 systemd 服务
echo -e "${BLUE}🔧 配置 systemd 服务...${NC}"

cat > /etc/systemd/system/skills-house.service << EOF
[Unit]
Description=Skills House - OpenClaw Skills Management Platform
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${DEPLOY_DIR}
ExecStart=$(which node) ${DEPLOY_DIR}/server/index.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=skills-house

Environment=NODE_ENV=production
Environment=PORT=3100

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✓ systemd 服务文件创建完成${NC}"
echo ""

# 10. 重载 systemd 并启动服务
echo -e "${BLUE}🚀 启动服务...${NC}"
systemctl daemon-reload
systemctl enable skills-house
systemctl restart skills-house

# 等待服务启动
sleep 3

# 11. 检查服务状态
if systemctl is-active --quiet skills-house; then
    echo -e "${GREEN}✓ 服务启动成功！${NC}"
    systemctl status skills-house --no-pager -l
else
    echo -e "${RED}❌ 服务启动失败${NC}"
    echo -e "${YELLOW}查看日志：${NC}"
    journalctl -u skills-house -n 50 --no-pager
    exit 1
fi

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  ✅ 部署完成！${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${BLUE}📊 服务信息${NC}"
echo -e "  服务名称: ${GREEN}skills-house${NC}"
echo -e "  部署目录: ${GREEN}${DEPLOY_DIR}${NC}"
echo -e "  访问地址: ${GREEN}http://175.27.141.110:3100${NC}"
echo -e "  Node.js:  ${GREEN}${NODE_VERSION}${NC}"
echo ""
echo -e "${BLUE}📝 常用命令${NC}"
echo -e "  查看状态: ${GREEN}systemctl status skills-house${NC}"
echo -e "  停止服务: ${GREEN}systemctl stop skills-house${NC}"
echo -e "  启动服务: ${GREEN}systemctl start skills-house${NC}"
echo -e "  重启服务: ${GREEN}systemctl restart skills-house${NC}"
echo -e "  查看日志: ${GREEN}journalctl -u skills-house -f${NC}"
echo ""
echo -e "${BLUE}🔥 测试访问${NC}"
echo -e "  ${GREEN}curl http://175.27.141.110:3100${NC}"
echo ""
