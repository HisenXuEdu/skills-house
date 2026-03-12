# COS 对象存储集成指南

本文档介绍如何为 Skills House 配置腾讯云 COS 对象存储。

---

## 🎯 **为什么使用 COS？**

### 本地存储的局限
- ❌ 磁盘空间有限
- ❌ 单服务器存储，无法扩展
- ❌ 没有 CDN 加速
- ❌ 备份困难
- ❌ 不支持多地域访问加速

### COS 的优势
- ✅ **无限存储**：按需扩展，无需担心磁盘空间
- ✅ **高可用性**：99.95% 可用性
- ✅ **CDN 加速**：全球加速节点
- ✅ **自动备份**：多地域冗余存储
- ✅ **低成本**：按使用量计费
- ✅ **安全性**：访问权限控制、数据加密

---

## 📦 **架构设计**

### 存储策略
- **Skills 压缩包**：存储在 COS `skills/{skill-id}.zip`
- **元数据**：仍存储在本地 JSON 文件
- **临时文件**：上传时暂存本地，上传完成后删除
- **下载**：从 COS 生成临时签名 URL

### 工作流程

#### 上传流程
```
用户上传 → 保存到本地临时目录 → 上传到 COS → 删除本地文件 → 更新元数据
```

#### 下载流程
```
用户请求下载 → 从 COS 获取签名 URL → 重定向到 COS URL → 用户直接从 COS 下载
```

---

## 🚀 **快速开始**

### 1. 获取 COS 密钥

访问腾讯云 CAM 控制台：
```
https://console.cloud.tencent.com/cam/capi
```

创建或查看 **API 密钥**：
- **SecretId**：如 `AKIDxxxxxxxxxxxxxxxxxxxxxxxx`
- **SecretKey**：如 `xxxxxxxxxxxxxxxxxxxxxxxx`

⚠️ **重要**：密钥具有账号所有权限，请妥善保管，不要泄露！

---

### 2. 创建 COS Bucket

访问 COS 控制台：
```
https://console.cloud.tencent.com/cos5/bucket
```

#### 创建 Bucket
1. 点击 **创建存储桶**
2. 填写配置：
   - **名称**：`skills-house`（自动添加 AppId 后缀）
   - **所属地域**：选择离服务器最近的地域（如广州）
   - **访问权限**：私有读写
   - **存储桶标签**：可选

3. 点击 **创建**

#### 获取 Bucket 信息
创建完成后，记录：
- **Bucket 名称**：`skills-house-1234567890`（完整名称，包含 AppId）
- **所属地域**：`ap-guangzhou`

---

### 3. 配置环境变量

在服务器上创建 `.env` 文件：

```bash
ssh root@175.27.141.110
cd /data/skills-house
nano .env
```

填入以下内容（替换为实际值）：

```bash
# JWT Secret
JWT_SECRET=your-random-secret-key-here

# 服务器端口
PORT=3100

# COS 配置
COS_SECRET_ID=AKIDxxxxxxxxxxxxxxxxxxxxxxxx
COS_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxx
COS_BUCKET=skills-house-1234567890
COS_REGION=ap-guangzhou

# CDN 加速域名（可选，如果配置了 CDN）
COS_CDN=
```

**保存并退出**：`Ctrl + O` → `Enter` → `Ctrl + X`

---

### 4. 重启服务

```bash
systemctl restart skills-house
journalctl -u skills-house -f
```

查看日志，应该看到：
```
✅ COS 存储已启用: { bucket: 'skills-house-1234567890', region: 'ap-guangzhou' }
```

---

## 🔧 **COS SDK 使用说明**

### API 文档

项目已集成 `cos-nodejs-sdk-v5`，提供以下方法：

#### 上传文件
```javascript
const cosStorage = require('./server/cos-storage');

// 上传单个文件
await cosStorage.uploadFile(
  '/path/to/local/file.zip',  // 本地路径
  'skill-name-123456.zip'      // COS 路径（相对于 skills/ 前缀）
);

// 上传整个目录（自动压缩）
await cosStorage.uploadDirectory(
  '/path/to/local/dir',
  'skill-name-123456.zip'
);
```

#### 下载文件
```javascript
// 下载到本地
await cosStorage.downloadFile(
  'skill-name-123456.zip',     // COS 路径
  '/path/to/save/file.zip'     // 本地路径
);

// 获取临时下载 URL（1 小时有效）
const url = await cosStorage.getDownloadUrl('skill-name-123456.zip', 3600);
// 返回: https://skills-house-xxx.cos.ap-guangzhou.myqcloud.com/skills/...?sign=...
```

#### 删除文件
```javascript
await cosStorage.deleteFile('skill-name-123456.zip');
```

#### 列出文件
```javascript
const files = await cosStorage.listFiles('prefix/');
```

#### 检查文件是否存在
```javascript
const exists = await cosStorage.fileExists('skill-name-123456.zip');
```

---

## 📊 **数据迁移**

### 从本地存储迁移到 COS

如果之前使用本地存储，现在想迁移到 COS：

#### 1. 迁移脚本

创建 `migrate-to-cos.js`：

```javascript
const fs = require('fs');
const path = require('path');
const cosStorage = require('./server/cos-storage');

const UPLOADS_DIR = path.join(__dirname, 'uploads');
const SKILLS_DIR = path.join(UPLOADS_DIR, 'skills');
const METADATA_FILE = path.join(UPLOADS_DIR, 'metadata.json');

async function migrateSkills() {
  console.log('开始迁移 Skills 到 COS...\n');

  // 读取元数据
  const metadata = JSON.parse(fs.readFileSync(METADATA_FILE, 'utf-8'));
  console.log(`共 ${metadata.length} 个 Skills 需要迁移\n`);

  for (const skill of metadata) {
    console.log(`迁移: ${skill.name} (${skill.id})...`);
    
    const skillDir = path.join(SKILLS_DIR, skill.id);
    
    if (!fs.existsSync(skillDir)) {
      console.log(`  ⚠️  跳过（目录不存在）\n`);
      continue;
    }

    try {
      // 上传目录（自动压缩）
      const result = await cosStorage.uploadDirectory(
        skillDir,
        `${skill.id}.zip`
      );
      
      console.log(`  ✅ 上传成功: ${result.url}\n`);
      
      // 可选：删除本地文件以节省空间
      // fs.rmSync(skillDir, { recursive: true });
    } catch (error) {
      console.error(`  ❌ 上传失败:`, error.message, '\n');
    }
  }

  console.log('迁移完成！');
}

migrateSkills().catch(console.error);
```

#### 2. 运行迁移

```bash
cd /data/skills-house
node migrate-to-cos.js
```

---

## 💰 **成本估算**

### COS 定价（广州地域）

| 项目 | 价格 | 说明 |
|------|------|------|
| **存储费用** | ¥0.118/GB/月 | 标准存储 |
| **请求费用** | ¥0.01/万次 | PUT/POST 请求 |
| **流量费用** | ¥0.50/GB | 外网下行流量 |
| **CDN 流量** | ¥0.21/GB | 使用 CDN 加速 |

### 示例计算

假设：
- 100 个 Skills，每个 10MB = 1GB 存储
- 每月 1000 次下载 = 10GB 流量

**每月成本**：
```
存储费用: 1 GB × ¥0.118 = ¥0.12
请求费用: 1000 次 ÷ 10000 × ¥0.01 = ¥0.001
流量费用: 10 GB × ¥0.50 = ¥5.00

总计: ¥5.12 / 月
```

**使用 CDN 后**：
```
流量费用: 10 GB × ¥0.21 = ¥2.10

总计: ¥2.23 / 月（节省 56%）
```

---

## 🚀 **配置 CDN 加速（可选）**

### 1. 开通 CDN

访问 CDN 控制台：
```
https://console.cloud.tencent.com/cdn
```

### 2. 添加域名

1. 点击 **添加域名**
2. 填写配置：
   - **加速域名**：`skills-cdn.example.com`
   - **业务类型**：下载加速
   - **源站类型**：COS 源
   - **源站设置**：选择你的 COS Bucket

3. 提交审核（通常几分钟内完成）

### 3. 配置 DNS

在域名解析服务商处添加 CNAME 记录：
```
skills-cdn.example.com  →  xxx.cdn.dnsv1.com
```

### 4. 更新配置

修改服务器 `.env` 文件：
```bash
COS_CDN=https://skills-cdn.example.com
```

重启服务：
```bash
systemctl restart skills-house
```

---

## 🔒 **安全最佳实践**

### 1. 密钥安全
- ✅ 使用子账号密钥（最小权限原则）
- ✅ 定期轮换密钥
- ✅ 不要将密钥提交到 Git
- ✅ 使用环境变量存储密钥

### 2. Bucket 权限
- ✅ 设置为 **私有读写**
- ✅ 通过签名 URL 控制访问
- ✅ 设置防盗链

### 3. 访问控制
- ✅ 使用 CAM 策略限制权限
- ✅ 启用访问日志
- ✅ 监控异常访问

---

## 🐛 **故障排查**

### COS 未启用

**症状**：
```
⚠️  COS 未配置，将使用本地存储
```

**解决**：
1. 检查 `.env` 文件是否存在
2. 确认 `COS_SECRET_ID` 和 `COS_SECRET_KEY` 已填写
3. 重启服务

---

### 上传失败

**症状**：
```
COS 上传失败: NoSuchBucket
```

**解决**：
1. 检查 Bucket 名称是否正确（包含 AppId）
2. 检查 Region 是否正确
3. 确认 Bucket 已创建

---

### 权限错误

**症状**：
```
Access Denied
```

**解决**：
1. 检查密钥是否正确
2. 确认密钥有 COS 操作权限
3. 检查 Bucket 策略

---

## 📚 **相关文档**

- [腾讯云 COS 文档](https://cloud.tencent.com/document/product/436)
- [COS Node.js SDK](https://cloud.tencent.com/document/product/436/8629)
- [COS 最佳实践](https://cloud.tencent.com/document/product/436/38062)

---

## 🎯 **总结**

### 配置步骤回顾
1. ✅ 获取 COS 密钥
2. ✅ 创建 COS Bucket
3. ✅ 配置 `.env` 文件
4. ✅ 重启服务
5. ✅ （可选）配置 CDN

### 验证
```bash
# 查看日志
journalctl -u skills-house -n 50

# 应该看到
✅ COS 存储已启用
```

### 使用
- 上传 Skill 时会自动上传到 COS
- 下载时从 COS 获取临时 URL
- 所有文件存储在 `skills/` 前缀下

---

需要帮助？查看日志或联系管理员。
