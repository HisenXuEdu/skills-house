#!/bin/bash

# Skills House - Push to GitHub Script
# 使用方法：./push-to-github.sh YOUR_GITHUB_USERNAME

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Skills House - GitHub 推送脚本${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# 检查参数
if [ -z "$1" ]; then
    echo -e "${YELLOW}使用方法：${NC}"
    echo -e "  ${GREEN}./push-to-github.sh YOUR_GITHUB_USERNAME${NC}"
    echo ""
    echo -e "${YELLOW}或者设置环境变量：${NC}"
    echo -e "  ${GREEN}export GITHUB_USERNAME=your_username${NC}"
    echo -e "  ${GREEN}./push-to-github.sh${NC}"
    echo ""
    
    # 尝试从环境变量获取
    if [ -z "$GITHUB_USERNAME" ]; then
        echo -e "${RED}❌ 错误：请提供 GitHub 用户名${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ 使用环境变量中的用户名：$GITHUB_USERNAME${NC}"
    fi
else
    GITHUB_USERNAME="$1"
    echo -e "${GREEN}✓ GitHub 用户名：$GITHUB_USERNAME${NC}"
fi

REPO_NAME="skills-house"
GITHUB_REPO="https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

echo ""
echo -e "${BLUE}📋 仓库信息${NC}"
echo -e "  用户名：${GREEN}${GITHUB_USERNAME}${NC}"
echo -e "  仓库名：${GREEN}${REPO_NAME}${NC}"
echo -e "  GitHub URL：${GREEN}${GITHUB_REPO}${NC}"
echo ""

# 切换到项目目录
cd /root/.openclaw/workspace/skills-house

# 检查是否已存在 github 远程仓库
if git remote get-url github &>/dev/null; then
    echo -e "${YELLOW}⚠️  远程仓库 'github' 已存在${NC}"
    CURRENT_URL=$(git remote get-url github)
    echo -e "  当前 URL：${CURRENT_URL}"
    echo ""
    
    if [ "$CURRENT_URL" != "$GITHUB_REPO" ]; then
        echo -e "${YELLOW}是否更新为新 URL？(y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            git remote set-url github "$GITHUB_REPO"
            echo -e "${GREEN}✓ 远程仓库 URL 已更新${NC}"
        fi
    fi
else
    echo -e "${BLUE}📌 添加 GitHub 远程仓库...${NC}"
    git remote add github "$GITHUB_REPO"
    echo -e "${GREEN}✓ 远程仓库已添加${NC}"
fi

echo ""
echo -e "${BLUE}📦 当前远程仓库列表：${NC}"
git remote -v

echo ""
echo -e "${BLUE}🚀 开始推送到 GitHub...${NC}"
echo ""

# 推送到 GitHub
if git push github master; then
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}  ✅ 推送成功！${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
    echo -e "${BLUE}🔗 访问你的仓库：${NC}"
    echo -e "  ${GREEN}https://github.com/${GITHUB_USERNAME}/${REPO_NAME}${NC}"
    echo ""
    echo -e "${BLUE}📝 后续操作：${NC}"
    echo -e "  1. 推送到工蜂：${GREEN}git push origin master${NC}"
    echo -e "  2. 推送到 GitHub：${GREEN}git push github master${NC}"
    echo -e "  3. 同时推送：${GREEN}git push origin master && git push github master${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}================================================${NC}"
    echo -e "${RED}  ❌ 推送失败${NC}"
    echo -e "${RED}================================================${NC}"
    echo ""
    echo -e "${YELLOW}可能的原因：${NC}"
    echo -e "  1. GitHub 仓库不存在，请先创建：${BLUE}https://github.com/new${NC}"
    echo -e "  2. 需要认证，请配置 GitHub Token："
    echo -e "     ${GREEN}gh auth login${NC}"
    echo -e "     或设置：${GREEN}git config --global credential.helper store${NC}"
    echo -e "  3. 网络连接问题"
    echo ""
    echo -e "${YELLOW}📖 详细步骤请查看：${GREEN}GITHUB_SETUP.md${NC}"
    exit 1
fi
