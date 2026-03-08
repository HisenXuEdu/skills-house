# 🏠 Skills House 部署指南

## 🎉 平台已成功部署！

### 📦 项目信息

- **项目名称**: Skills House
- **工蜂地址**: https://git.woa.com/hisenxu/skills-house
- **本地路径**: /root/.openclaw/workspace/skills-house
- **运行端口**: 3100
- **访问地址**: http://localhost:3100

### ✅ 已完成

1. ✅ 创建完整的 Skills 管理平台
2. ✅ 前端界面（Vue 3 + Vite）
3. ✅ 后端 API（Node.js + Express）
4. ✅ Docker 部署配置
5. ✅ 代码已推送到工蜂仓库
6. ✅ 服务已启动并运行

### 🚀 功能列表

#### 前端功能
- 📦 卡片式 Skills 展示
- 🔍 实时搜索功能
- ⬆️ 文件上传（支持 ZIP 和单文件）
- 📥 一键下载 Skills
- 🗑️ 删除管理
- 📊 下载次数统计
- 🎨 现代化渐变色 UI
- 📱 响应式设计

#### 后端功能
- 🔐 文件上传处理
- 📦 ZIP 自动解压
- 🗄️ 元数据管理
- 🔍 搜索 API
- 📥 自动打包下载
- 🗑️ 删除管理
- 📈 统计功能

### 📂 项目结构

```
skills-house/
├── server/
│   └── index.js          # Express 后端服务
├── client/
│   ├── src/
│   │   ├── App.vue       # 主 Vue 组件
│   │   └── main.js       # Vue 入口
│   ├── dist/             # 构建输出
│   ├── index.html
│   ├── vite.config.js
│   └── package.json
├── uploads/              # 数据存储
│   ├── skills/           # Skills 文件
│   ├── temp/             # 临时文件
│   └── metadata.json     # 元数据
├── Dockerfile
├── docker-compose.yml
├── start.sh              # 启动脚本
├── package.json
└── README.md
```

### 🛠️ 管理命令

#### 启动服务
```bash
cd /root/.openclaw/workspace/skills-house
./start.sh
# 或
PORT=3100 npm start
```

#### 开发模式
```bash
npm run dev
# 后端: http://localhost:3000
# 前端: http://localhost:5173
```

#### 重新构建前端
```bash
cd client
npm run build
```

#### Docker 部署
```bash
# 使用 docker-compose
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 📡 API 接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/skills` | 获取所有 Skills |
| GET | `/api/skills/search?q=关键词` | 搜索 Skills |
| POST | `/api/skills/upload` | 上传 Skill |
| GET | `/api/skills/:id/download` | 下载 Skill |
| DELETE | `/api/skills/:id` | 删除 Skill |

### 🔧 配置选项

#### 环境变量
```bash
PORT=3100              # 服务端口
NODE_ENV=production   # 运行环境
```

### 📊 使用示例

#### 1. 上传 Skill
1. 访问 http://localhost:3100
2. 点击 "⬆️ 上传 Skill"
3. 填写信息：
   - 名称: my-awesome-skill
   - 描述: 这是一个很棒的技能
   - 版本: 1.0.0
   - 作者: hisenxu
4. 选择文件（ZIP 或单文件）
5. 点击上传

#### 2. 搜索和下载
- 在搜索框输入关键词
- 点击 "下载" 按钮获取 Skill
- 自动下载为 ZIP 格式

#### 3. 管理 Skills
- 查看下载次数
- 删除不需要的 Skill
- 浏览所有已上传的 Skills

### 🔐 安全建议

1. **生产环境部署**
   - 添加用户认证
   - 限制文件大小
   - 添加文件类型校验
   - 启用 HTTPS

2. **文件存储**
   - 定期备份 uploads 目录
   - 考虑使用对象存储（COS/OSS）

3. **性能优化**
   - 添加缓存机制
   - CDN 加速静态资源
   - 数据库存储元数据

### 📝 下一步计划

- [ ] 添加用户系统
- [ ] Skill 版本管理
- [ ] 评论和评分功能
- [ ] 分类和标签系统
- [ ] API 文档集成
- [ ] 管理后台
- [ ] 统计面板

### 🐛 问题排查

#### 服务无法启动
```bash
# 检查端口占用
lsof -i :3100

# 查看日志
npm start

# 重新安装依赖
rm -rf node_modules client/node_modules
npm install
cd client && npm install
```

#### 前端无法访问
```bash
# 重新构建
cd client
npm run build
```

#### 文件上传失败
```bash
# 检查权限
chmod -R 755 uploads/

# 检查磁盘空间
df -h
```

### 📞 支持

- 工蜂仓库: https://git.woa.com/hisenxu/skills-house
- 作者: hisenxu

---

**🎊 祝你使用愉快！**
