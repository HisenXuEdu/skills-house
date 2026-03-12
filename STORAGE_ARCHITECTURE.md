# 📦 Skills House 数据存储架构

## 📂 存储位置

所有数据存储在服务器的以下目录：
```
/data/skills-house/uploads/
```

---

## 🗂️ 目录结构

```
/data/skills-house/uploads/
├── users.json           # 用户数据（JSON 文件）
├── metadata.json        # Skills 元数据（JSON 文件）
├── skills/              # Skills 文件存储目录
│   └── <skill-id>/      # 每个 skill 一个独立目录
│       ├── SKILL.md     # Skill 说明文档
│       ├── index.js     # Skill 主文件
│       └── ...          # 其他 skill 文件
└── temp/                # 临时文件目录（上传时使用）
```

---

## 👥 用户数据存储

### 文件位置
```
/data/skills-house/uploads/users.json
```

### 数据格式
```json
[
  {
    "id": "1773158054446",
    "username": "testuser",
    "email": "test@example.com",
    "password": "$2a$10$h8tzNNtt/e9EA4rSDzpWtuo/Wbhz/iK.CYBwsbW3CMOQAE5oKikvm",
    "createdAt": "2026-03-10T15:54:14.446Z",
    "role": "user"
  },
  {
    "id": "1773245764921",
    "username": "admin",
    "email": "admin@skills-house.com",
    "password": "$2a$10$v/uS5S2Gjl.QFptHEDmGBO9TZZPmIqo0tCAEOx2HpW5MQOSdswEae",
    "createdAt": "2026-03-11T16:16:05.023Z",
    "role": "admin"
  }
]
```

### 字段说明

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `id` | String | 唯一用户 ID（时间戳生成） | "1773158054446" |
| `username` | String | 用户名（唯一） | "admin" |
| `email` | String | 邮箱（可选） | "admin@example.com" |
| `password` | String | bcrypt 加密密码（10 rounds） | "$2a$10$..." |
| `createdAt` | String | 注册时间（ISO 8601） | "2026-03-11T16:16:05.023Z" |
| `role` | String | 用户角色：`"user"` 或 `"admin"` | "admin" |

### 密码加密
- 使用 **bcryptjs** 加密
- Salt rounds: **10**
- 示例代码：
  ```javascript
  const bcrypt = require('bcryptjs');
  const hashedPassword = bcrypt.hashSync('admin123456', 10);
  ```

---

## 📦 Skills 数据存储

### 元数据文件位置
```
/data/skills-house/uploads/metadata.json
```

### 元数据格式
```json
[
  {
    "id": "11-1773246212507",
    "name": "11",
    "description": "11",
    "version": "1.0.0",
    "author": "admin",
    "uploadedBy": "1773245764921",
    "uploadedAt": "2026-03-11T16:23:33.079Z",
    "downloadCount": 0,
    "crawledFrom": "https://example.com/skill.zip"
  }
]
```

### 字段说明

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `id` | String | 唯一 Skill ID（`{name}-{timestamp}`） | "my-skill-1773246212507" |
| `name` | String | Skill 名称 | "my-skill" |
| `description` | String | Skill 描述 | "A useful skill" |
| `version` | String | 版本号 | "1.0.0" |
| `author` | String | 作者用户名 | "admin" |
| `uploadedBy` | String | 上传者用户 ID | "1773245764921" |
| `uploadedAt` | String | 上传时间（ISO 8601） | "2026-03-11T16:23:33.079Z" |
| `downloadCount` | Number | 下载次数 | 5 |
| `crawledFrom` | String | 爬虫来源 URL（可选） | "https://example.com/skill.zip" |

### Skills 文件存储

#### 存储位置
```
/data/skills-house/uploads/skills/{skill-id}/
```

#### 目录结构示例
```
/data/skills-house/uploads/skills/
└── my-skill-1773246212507/
    ├── SKILL.md          # Skill 说明文档
    ├── package.json      # npm 包配置（如果有）
    ├── index.js          # 主文件
    ├── lib/              # 库文件
    ├── assets/           # 资源文件
    └── ...               # 其他文件
```

#### 实际存储示例
当前系统中：
```
/data/skills-house/uploads/skills/11-1773246212507/
大小: 36MB
```

---

## 🔄 数据操作流程

### 用户注册流程
1. 前端发送 POST `/api/auth/register`
2. 后端验证用户名是否已存在
3. 使用 bcrypt 加密密码
4. 生成唯一 ID（时间戳）
5. 写入 `users.json` 文件
6. 返回 JWT token

### 用户登录流程
1. 前端发送 POST `/api/auth/login`
2. 后端从 `users.json` 读取用户
3. 使用 bcrypt 验证密码
4. 生成 JWT token（有效期 7 天）
5. 返回 token 和用户信息

### Skill 上传流程
1. 用户上传压缩包（.zip/.tgz/.tar.gz）
2. 保存到临时目录 `/uploads/temp/`
3. 生成 Skill ID（`{name}-{timestamp}`）
4. 创建 Skill 目录 `/uploads/skills/{skill-id}/`
5. 解压文件到 Skill 目录
6. 写入元数据到 `metadata.json`
7. 删除临时文件

### Skill 下载流程
1. 用户请求 GET `/api/skills/{id}/download`
2. 读取 Skill 目录
3. 实时压缩为 .zip 文件
4. 流式传输给用户
5. 更新 `downloadCount` 字段

### Skill 删除流程
1. 验证用户权限（管理员或作者）
2. 从 `metadata.json` 移除记录
3. 删除 Skill 目录（递归删除所有文件）
4. 返回成功响应

---

## 🔐 安全考虑

### 密码安全
- ✅ 使用 bcrypt 加密（不可逆）
- ✅ Salt rounds = 10（推荐值）
- ✅ 永不存储明文密码
- ✅ API 不返回密码字段

### 文件安全
- ✅ 上传文件自动解压验证
- ✅ 文件大小限制（可配置）
- ✅ 文件类型验证（.zip/.tgz/.tar.gz）
- ⚠️ 暂无病毒扫描（建议添加）

### 权限控制
- ✅ JWT Token 认证
- ✅ 角色权限验证（admin/user）
- ✅ 用户只能删除自己的 Skill
- ✅ 管理员可删除任意 Skill/用户

---

## 📊 当前数据统计

### 用户数据
```
总用户数: 3
├── 普通用户: 2 (testuser, hisen)
└── 管理员: 1 (admin)
```

### Skills 数据
```
总 Skills 数: 1
├── Skill ID: 11-1773246212507
├── 名称: 11
├── 作者: admin
├── 大小: 36MB
└── 下载量: 0
```

### 存储使用
```
用户数据: 710 bytes (users.json)
Skills 元数据: 235 bytes (metadata.json)
Skills 文件: 36MB
总占用: ~36MB
```

---

## 🚀 性能考虑

### JSON 文件存储
- **优点**：
  - ✅ 简单易用，无需数据库
  - ✅ 易于备份和迁移
  - ✅ 可读性强，便于调试
  
- **缺点**：
  - ⚠️ 大量数据时性能下降
  - ⚠️ 并发写入需要锁机制
  - ⚠️ 查询效率低于数据库

### 建议优化方案

#### 当用户数 > 1000 时
迁移到数据库（推荐 PostgreSQL 或 MongoDB）

#### 当 Skills 数 > 500 时
- 添加索引文件
- 使用分页查询
- 实现搜索引擎（Elasticsearch）

#### 当存储 > 100GB 时
- 迁移到对象存储（S3/OSS）
- 实现 CDN 加速
- 使用文件压缩

---

## 🔄 数据迁移方案

### 迁移到数据库

#### 用户表结构（PostgreSQL）
```sql
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100),
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  role VARCHAR(20) DEFAULT 'user'
);

CREATE INDEX idx_username ON users(username);
CREATE INDEX idx_role ON users(role);
```

#### Skills 表结构（PostgreSQL）
```sql
CREATE TABLE skills (
  id VARCHAR(100) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  description TEXT,
  version VARCHAR(20),
  author VARCHAR(50),
  uploaded_by BIGINT REFERENCES users(id),
  uploaded_at TIMESTAMP DEFAULT NOW(),
  download_count INTEGER DEFAULT 0,
  crawled_from TEXT,
  file_path VARCHAR(500)
);

CREATE INDEX idx_name ON skills(name);
CREATE INDEX idx_author ON skills(author);
CREATE INDEX idx_uploaded_by ON skills(uploaded_by);
```

### 迁移到对象存储

#### 文件存储（S3/OSS）
```
bucket: skills-house
├── skills/
│   ├── {skill-id}.zip      # 压缩包
│   └── {skill-id}/         # 解压后的文件
└── temp/                   # 临时文件
```

#### 配置示例
```javascript
const AWS = require('aws-sdk');
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY,
  secretAccessKey: process.env.AWS_SECRET_KEY,
  region: 'us-east-1'
});

// 上传文件
await s3.upload({
  Bucket: 'skills-house',
  Key: `skills/${skillId}.zip`,
  Body: fileStream
}).promise();
```

---

## 📋 备份策略

### 定期备份
```bash
#!/bin/bash
# backup.sh - 每天凌晨 2 点执行

BACKUP_DIR="/backup/skills-house/$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR

# 备份用户数据
cp /data/skills-house/uploads/users.json $BACKUP_DIR/

# 备份 Skills 元数据
cp /data/skills-house/uploads/metadata.json $BACKUP_DIR/

# 备份 Skills 文件
tar czf $BACKUP_DIR/skills.tar.gz /data/skills-house/uploads/skills/

# 保留最近 30 天的备份
find /backup/skills-house/ -type d -mtime +30 -exec rm -rf {} \;
```

### 添加到 crontab
```bash
0 2 * * * /data/skills-house/backup.sh
```

---

## 🔍 数据查询示例

### 查询所有管理员
```bash
cat /data/skills-house/uploads/users.json | jq '.[] | select(.role == "admin")'
```

### 查询特定用户的 Skills
```bash
cat /data/skills-house/uploads/metadata.json | jq '.[] | select(.author == "admin")'
```

### 统计总下载量
```bash
cat /data/skills-house/uploads/metadata.json | jq '[.[].downloadCount] | add'
```

### 查询最新上传的 Skills
```bash
cat /data/skills-house/uploads/metadata.json | jq 'sort_by(.uploadedAt) | reverse | .[0:5]'
```

---

## 🛠️ 维护工具

### 清理临时文件
```bash
rm -rf /data/skills-house/uploads/temp/*
```

### 重建下载计数
```bash
node /data/skills-house/scripts/rebuild-download-counts.js
```

### 修复损坏的 JSON
```bash
# 验证 JSON 格式
jq . /data/skills-house/uploads/users.json > /dev/null && echo "OK" || echo "INVALID"

# 格式化 JSON
jq . /data/skills-house/uploads/users.json > /tmp/users.json.fixed
mv /tmp/users.json.fixed /data/skills-house/uploads/users.json
```

---

## 📈 存储方式总结

| 数据类型 | 存储方式 | 文件/路径 | 大小 |
|---------|---------|-----------|------|
| **用户信息** | JSON 文件 | `/uploads/users.json` | 710 bytes |
| **Skills 元数据** | JSON 文件 | `/uploads/metadata.json` | 235 bytes |
| **Skills 文件** | 文件系统目录 | `/uploads/skills/{id}/` | ~36MB |
| **临时文件** | 文件系统目录 | `/uploads/temp/` | 动态 |

**存储架构类型**：文件系统 + JSON 数据库（无外部依赖）

**适用规模**：小型到中型项目（<1000 用户，<500 Skills）

**扩展性**：可迁移到关系型数据库 + 对象存储（见迁移方案）

---

需要我帮你实现数据迁移到数据库，或者添加备份脚本吗？😊
