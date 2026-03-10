# 用户认证系统 - 使用指南

## 🎉 新功能

Skills House 现已支持用户认证系统！

### ✨ 主要特性

- **用户注册和登录** - 安全的账号管理
- **权限控制** - 只有登录用户可以上传 Skills
- **公开访问** - 所有人都可以浏览和下载 Skills
- **个人管理** - 只能删除自己上传的 Skills

---

## 🚀 功能说明

### 1. 注册账号

首次访问时，您需要注册一个账号：

1. 访问 http://175.27.141.110:3100
2. 点击"立即注册"
3. 填写：
   - 用户名（至少3个字符）
   - 密码（至少6个字符）
   - 邮箱（可选）
4. 点击"注册"按钮

### 2. 登录系统

已有账号？直接登录：

1. 输入用户名和密码
2. 点击"登录"按钮
3. 系统会保存您的登录状态（7天有效）

### 3. 上传 Skills

**⚠️ 需要登录后才能上传**

1. 登录后，点击右上角的"📤 上传 Skill"
2. 填写 Skill 信息：
   - 名称（必填）
   - 描述（可选）
   - 版本号（默认 1.0.0）
3. 选择 Skill 文件（支持 .zip, .tgz, .tar.gz）
4. 点击"上传"按钮

### 4. 浏览和下载

**✅ 无需登录即可浏览和下载**

- 在首页查看所有 Skills
- 使用搜索框快速查找
- 点击"下载"按钮获取 Skill 文件

### 5. 管理 Skills

- 只能删除自己上传的 Skills
- 在 Skill 卡片上会显示"删除"按钮
- 点击删除按钮需要确认

---

## 🔐 API 接口

### 用户认证

#### 注册
```bash
curl -X POST http://175.27.141.110:3100/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "your_username",
    "password": "your_password",
    "email": "your@email.com"
  }'
```

响应：
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "1773158054446",
    "username": "your_username",
    "email": "your@email.com",
    "role": "user"
  }
}
```

#### 登录
```bash
curl -X POST http://175.27.141.110:3100/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "your_username",
    "password": "your_password"
  }'
```

#### 验证 Token
```bash
curl http://175.27.141.110:3100/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Skills 管理

#### 上传 Skill（需要认证）
```bash
curl -X POST http://175.27.141.110:3100/api/skills/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@skill.tgz" \
  -F "name=my-skill" \
  -F "description=A useful skill" \
  -F "version=1.0.0"
```

#### 获取所有 Skills（公开）
```bash
curl http://175.27.141.110:3100/api/skills
```

#### 搜索 Skills（公开）
```bash
curl "http://175.27.141.110:3100/api/skills/search?q=keyword"
```

#### 下载 Skill（公开）
```bash
curl -O http://175.27.141.110:3100/api/skills/SKILL_ID/download
```

#### 删除 Skill（需要认证，仅作者）
```bash
curl -X DELETE http://175.27.141.110:3100/api/skills/SKILL_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## 🛡️ 安全说明

### 密码安全
- 密码使用 bcrypt 加密存储
- 不会以明文形式保存
- 建议使用强密码

### Token 管理
- Token 有效期为 7 天
- 存储在浏览器 localStorage 中
- 可以随时退出登录清除 Token

### 权限控制
- **公开操作**：浏览、搜索、下载
- **需要认证**：上传、删除（自己的）
- **管理员专属**：删除任何 Skills（role=admin）

---

## 📝 数据存储

### 用户数据
- 位置：`/data/skills-house/uploads/users.json`
- 包含：用户名、加密密码、邮箱、注册时间、角色

### Skills 数据
- 位置：`/data/skills-house/uploads/metadata.json`
- 包含：Skill 信息、作者、上传者 ID、下载次数

### Skills 文件
- 位置：`/data/skills-house/uploads/skills/`
- 每个 Skill 独立目录

---

## 🔧 管理命令

### 重置所有用户（谨慎使用）
```bash
echo '[]' > /data/skills-house/uploads/users.json
systemctl restart skills-house
```

### 查看已注册用户
```bash
cat /data/skills-house/uploads/users.json | jq '.'
```

### 将用户设为管理员
```bash
# 编辑 users.json，将目标用户的 role 改为 "admin"
vi /data/skills-house/uploads/users.json
systemctl restart skills-house
```

---

## 🎯 测试账号

已创建测试账号：
- **用户名**：testuser
- **密码**：test123456
- **角色**：user

---

## 📞 技术支持

如有问题，请检查：
1. 服务状态：`systemctl status skills-house`
2. 服务日志：`journalctl -u skills-house -f`
3. 用户数据：`cat /data/skills-house/uploads/users.json`

---

**访问地址**：http://175.27.141.110:3100

**享受 Skills 管理的乐趣吧！** 🎉
