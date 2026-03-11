# 🎉 管理后台部署完成！

## 📍 访问地址

### 主站
```
http://175.27.141.110:3100
```

### 管理后台
```
http://175.27.141.110:3100/admin.html
```

---

## 🔐 权限说明

### 管理员身份要求
- 只有 **role = admin** 的用户才能访问管理后台
- 普通用户访问会被重定向回主站

### 如何设置第一个管理员

#### 方法 1：手动编辑用户文件
```bash
# SSH 到服务器
ssh root@175.27.141.110

# 编辑用户文件
vi /data/skills-house/uploads/users.json

# 找到你的用户，将 role 改为 "admin"
{
  "id": "1773158054446",
  "username": "your_username",
  "role": "admin"  # 修改这里
}

# 重启服务
systemctl restart skills-house
```

#### 方法 2：使用测试账号
```bash
# 创建管理员账号（SSH 到服务器执行）
cat > /tmp/create-admin.js << 'EOF'
const fs = require('fs');
const bcrypt = require('bcryptjs');

const users = JSON.parse(fs.readFileSync('/data/skills-house/uploads/users.json', 'utf-8'));

const adminUser = {
  id: Date.now().toString(),
  username: 'admin',
  email: 'admin@skills-house.com',
  password: bcrypt.hashSync('admin123456', 10),
  createdAt: new Date().toISOString(),
  role: 'admin'
};

users.push(adminUser);
fs.writeFileSync('/data/skills-house/uploads/users.json', JSON.stringify(users, null, 2));
console.log('管理员账号创建成功！');
console.log('用户名: admin');
console.log('密码: admin123456');
EOF

cd /data/skills-house && node /tmp/create-admin.js
```

---

## ✨ 功能清单

### 1️⃣ **统计面板**
- 总用户数
- 总 Skills 数
- 总下载量
- 管理员数量

### 2️⃣ **用户管理**
- 查看所有用户列表
- 查看用户角色（admin/user）
- 提升用户为管理员
- 将管理员降为普通用户
- 删除用户（不能删除自己）

### 3️⃣ **Skills 管理**
- 查看所有 Skills 列表
- 查看下载量统计
- 删除任意 Skill

### 4️⃣ **爬虫工具**

#### 功能说明
- 从任意 URL 下载 Skill 包
- 自动解压并以 **admin** 身份上传
- 支持格式：`.zip`、`.tgz`、`.tar.gz`

#### 使用方法
1. 输入 Skill 的直链 URL（指向压缩包）
2. 填写 Skill 名称
3. 填写描述（可选）
4. 填写版本号（默认 1.0.0）
5. 点击"开始爬取并上传"

#### 示例 URL
```
https://example.com/skills/my-skill.zip
https://github.com/user/repo/releases/download/v1.0.0/skill.tgz
```

---

## 🎨 界面特色

### 深色专业风格
- 与主站一致的深色金融科技主题
- 薄荷绿强调色
- 网格背景
- 毛玻璃效果

### 响应式设计
- 桌面、平板、手机全适配
- 表格横向滚动
- 统计卡片自适应布局

---

## 🔧 API 端点

### 管理员 API（需要 admin 权限）

#### 获取所有用户
```http
GET /api/admin/users
Authorization: Bearer <token>
```

#### 更新用户角色
```http
PATCH /api/admin/users/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "role": "admin" | "user"
}
```

#### 删除用户
```http
DELETE /api/admin/users/:id
Authorization: Bearer <token>
```

#### 获取统计信息
```http
GET /api/admin/stats
Authorization: Bearer <token>
```

#### 爬取 Skill
```http
POST /api/admin/crawl-skill
Authorization: Bearer <token>
Content-Type: application/json

{
  "url": "https://example.com/skill.zip",
  "name": "my-skill",
  "description": "A useful skill",
  "version": "1.0.0"
}
```

---

## 📊 数据存储

### 用户数据
```
/data/skills-house/uploads/users.json
```

格式：
```json
[
  {
    "id": "1773158054446",
    "username": "admin",
    "email": "admin@example.com",
    "password": "$2a$10$...",
    "createdAt": "2026-03-12T00:00:00.000Z",
    "role": "admin"
  }
]
```

### Skills 元数据
```
/data/skills-house/uploads/metadata.json
```

格式：
```json
[
  {
    "id": "my-skill-1773158054446",
    "name": "my-skill",
    "description": "A useful skill",
    "version": "1.0.0",
    "author": "admin",
    "uploadedAt": "2026-03-12T00:00:00.000Z",
    "downloadCount": 5,
    "uploadedBy": "1773158054446",
    "crawledFrom": "https://example.com/skill.zip"
  }
]
```

---

## 🛡️ 安全特性

### 权限验证
- JWT Token 认证
- 管理员中间件 `requireAdmin`
- 自动重定向非管理员用户

### 操作保护
- 不能删除自己的账号
- 删除操作需要二次确认
- Token 过期自动退出

### 数据安全
- 密码 bcrypt 加密
- 用户列表不返回密码字段
- API 错误信息脱敏

---

## 🎯 使用流程

### 首次使用

1. **创建账号**
   ```
   访问 http://175.27.141.110:3100
   注册普通账号
   ```

2. **设置为管理员**
   ```bash
   # SSH 到服务器
   ssh root@175.27.141.110
   
   # 编辑用户文件
   vi /data/skills-house/uploads/users.json
   
   # 将你的账号 role 改为 "admin"
   
   # 重启服务
   systemctl restart skills-house
   ```

3. **访问管理后台**
   ```
   http://175.27.141.110:3100/admin.html
   用你的管理员账号登录
   ```

### 日常使用

1. **查看统计** - 顶部卡片显示关键数据
2. **管理用户** - 用户管理标签页
3. **管理 Skills** - Skills 管理标签页
4. **爬取 Skills** - 爬虫工具标签页

---

## 🚀 进阶功能

### 批量导入 Skills

使用爬虫工具可以快速导入外部 Skills：

1. 准备一个 Skills URL 列表
2. 逐个在爬虫工具中输入并爬取
3. 系统自动以 admin 身份上传

### 用户角色管理

- **普通用户**：只能上传/删除自己的 Skills
- **管理员**：可以管理所有用户和 Skills

### 监控和维护

查看服务状态：
```bash
systemctl status skills-house
```

查看实时日志：
```bash
journalctl -u skills-house -f
```

---

## 📝 常见问题

### Q: 忘记管理员密码怎么办？
**A**: SSH 到服务器，编辑 `users.json`，删除对应用户，重新注册并设置为管理员。

### Q: 爬虫工具报错？
**A**: 检查 URL 是否为直链，确保是公开可访问的压缩包。

### Q: 如何添加更多管理员？
**A**: 在用户管理页面，点击"提升为管理员"按钮。

### Q: 删除 Skill 会删除文件吗？
**A**: 是的，会删除 `/data/skills-house/uploads/skills/` 目录下的对应文件夹。

---

## 🔄 更新记录

### v1.0.0 (2026-03-12)
- ✅ 用户管理功能
- ✅ Skills 管理功能
- ✅ 爬虫工具
- ✅ 统计面板
- ✅ 深色主题界面

---

## 📞 技术支持

如有问题，请检查：
1. 服务状态：`systemctl status skills-house`
2. 服务日志：`journalctl -u skills-house -f`
3. 用户数据：`cat /data/skills-house/uploads/users.json`

---

**🎉 享受管理后台的强大功能吧！**

主站：http://175.27.141.110:3100  
管理后台：http://175.27.141.110:3100/admin.html
