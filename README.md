# Skills House

🏠 **OpenClaw Skills 管理平台** - 上传、浏览和分享你的 Skills

## 功能特性

- ⬆️ **上传 Skills** - 支持 ZIP 压缩包或单文件上传
- 📦 **浏览 Skills** - 卡片式展示，清晰美观
- 🔍 **搜索功能** - 快速查找需要的 Skill
- 📥 **下载 Skills** - 一键下载并统计下载次数
- 🗑️ **管理 Skills** - 支持删除不需要的 Skill
- 🎨 **现代化 UI** - 渐变色背景，响应式设计

## 技术栈

### 后端
- Node.js + Express
- Multer (文件上传)
- Archiver (压缩/解压)

### 前端
- Vue 3 (Composition API)
- Vite (构建工具)
- Axios (HTTP 客户端)

## 快速开始

### 1. 安装依赖

```bash
# 安装根目录依赖
npm install

# 安装前端依赖
cd client && npm install && cd ..
```

### 2. 开发模式

```bash
npm run dev
```

- 后端: http://localhost:3000
- 前端: http://localhost:5173

### 3. 生产构建

```bash
# 构建前端
npm run build

# 启动生产服务器
npm start
```

### 4. Docker 部署

```bash
# 使用 Docker Compose
docker-compose up -d

# 或手动构建
docker build -t skills-house .
docker run -p 3000:3000 -v $(pwd)/uploads:/app/uploads skills-house
```

## API 接口

### 获取所有 Skills
```
GET /api/skills
```

### 搜索 Skills
```
GET /api/skills/search?q=关键词
```

### 上传 Skill
```
POST /api/skills/upload
Content-Type: multipart/form-data

Body:
- name: Skill 名称
- description: 描述
- version: 版本号
- author: 作者
- file: 文件
```

### 下载 Skill
```
GET /api/skills/:id/download
```

### 删除 Skill
```
DELETE /api/skills/:id
```

## 目录结构

```
skills-house/
├── server/
│   └── index.js          # 后端服务器
├── client/
│   ├── src/
│   │   ├── App.vue       # 主组件
│   │   └── main.js       # 入口文件
│   ├── index.html        # HTML 模板
│   ├── vite.config.js    # Vite 配置
│   └── package.json      # 前端依赖
├── uploads/              # 文件存储目录
│   ├── skills/           # Skills 文件
│   ├── temp/             # 临时文件
│   └── metadata.json     # 元数据
├── Dockerfile            # Docker 配置
├── docker-compose.yml    # Docker Compose 配置
├── package.json          # 根依赖
└── README.md            # 本文件
```

## 使用说明

### 上传 Skill

1. 点击 "⬆️ 上传 Skill" 按钮
2. 填写 Skill 信息：
   - 名称（必填）
   - 描述（必填）
   - 版本（可选，默认 1.0.0）
   - 作者（可选）
3. 选择文件（ZIP 压缩包或单文件）
4. 点击 "上传" 按钮

### 下载 Skill

- 点击 Skill 卡片上的 "下载" 按钮
- 文件会自动下载为 ZIP 格式

### 搜索 Skill

- 在搜索框输入关键词
- 实时搜索 Skill 名称、描述和作者

### 删除 Skill

- 点击 Skill 卡片上的 "删除" 按钮
- 确认后删除（不可恢复）

## 环境变量

- `PORT`: 服务器端口（默认: 3000）
- `NODE_ENV`: 运行环境（development/production）

## 作者

**hisenxu**

## 许可证

MIT License
