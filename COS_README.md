# Skills House - COS 对象存储集成

Skills House 现已支持腾讯云 COS（对象存储）作为文件存储后端，提供更强大的存储能力和CDN加速。

---

## 🎯 **功能特性**

### ✅ **已实现**
- COS 对象存储支持
- 向后兼容（未配置时自动回退到本地存储）
- 自动上传压缩包到 COS
- CDN 加速支持
- 临时签名 URL 下载
- 文件管理（上传/下载/删除）

### 🚀 **优势**
- **无限存储**：不受本地磁盘限制
- **CDN 加速**：全球节点加速访问
- **高可用性**：99.95% SLA
- **自动备份**：多地域冗余存储
- **成本低廉**：按需付费

---

## 📚 **文档**

| 文档 | 说明 |
|------|------|
| **COS_INTEGRATION.md** | 完整的 COS 集成指南（推荐阅读） |
| **COS_CODE_CHANGES.md** | 代码修改详细步骤 |
| **.env.example** | 环境变量配置模板 |
| **setup-cos.sh** | 快速配置脚本 |
| **deploy-with-cos.sh** | 部署脚本 |

---

## 🚀 **快速开始**

### 方法 1：使用配置脚本（推荐）

```bash
cd /data/skills-house
./setup-cos.sh
```

按照提示输入 COS 配置信息即可。

---

### 方法 2：手动配置

#### 1. 获取 COS 密钥

访问：https://console.cloud.tencent.com/cam/capi

#### 2. 创建 COS Bucket

访问：https://console.cloud.tencent.com/cos5/bucket

创建一个私有 Bucket，记录：
- Bucket 名称（如：`skills-house-1234567890`）
- 所属地域（如：`ap-guangzhou`）

#### 3. 配置环境变量

创建 `.env` 文件：

```bash
cp .env.example .env
nano .env
```

填入配置：

```env
# COS 配置
COS_SECRET_ID=AKIDxxxxxxxxxxxxxxxxxxxxxxxx
COS_SECRET_KEY=xxxxxxxxxxxxxxxxxxxxxxxx
COS_BUCKET=skills-house-1234567890
COS_REGION=ap-guangzhou
```

#### 4. 安装依赖

```bash
npm install cos-nodejs-sdk-v5 --save
```

#### 5. 修改代码

参考 `COS_CODE_CHANGES.md` 修改 `server/index.js`

#### 6. 重启服务

```bash
systemctl restart skills-house
journalctl -u skills-house -f
```

---

## 📦 **核心模块**

### server/cos-storage.js

COS 存储服务，提供：

```javascript
const cosStorage = require('./server/cos-storage');

// 上传文件
await cosStorage.uploadFile(localPath, remotePath);

// 上传目录（自动压缩）
await cosStorage.uploadDirectory(localDir, remotePath);

// 下载文件
await cosStorage.downloadFile(remotePath, localPath);

// 获取下载 URL
const url = await cosStorage.getDownloadUrl(remotePath, 3600);

// 删除文件
await cosStorage.deleteFile(remotePath);

// 列出文件
const files = await cosStorage.listFiles(prefix);

// 检查文件存在
const exists = await cosStorage.fileExists(remotePath);
```

### server/cos-config.js

COS 配置管理，从环境变量读取配置。

---

## 🔄 **存储模式**

### 自动检测

系统会自动检测 COS 配置：

- ✅ **COS 启用**：`COS_SECRET_ID` 和 `COS_SECRET_KEY` 已配置
- ⚠️ **本地存储**：COS 未配置或配置错误

启动时会显示：

```
🚀 启动 Skills House...
📦 存储模式: COS 对象存储
✅ COS 存储已启用: { bucket: 'skills-house-xxx', region: 'ap-guangzhou' }
```

### 混合存储

- **Skills 文件**：存储在 COS
- **元数据**：存储在本地 JSON 文件
- **临时文件**：本地临时目录

---

## 💰 **成本估算**

### 示例场景

假设：
- 100 个 Skills，每个 10MB
- 每月 1000 次下载

**每月成本**（广州地域）：
```
存储费用: 1 GB × ¥0.118 = ¥0.12
流量费用: 10 GB × ¥0.50 = ¥5.00
总计: 约 ¥5.12 / 月
```

**使用 CDN 后**：
```
流量费用: 10 GB × ¥0.21 = ¥2.10
总计: 约 ¥2.23 / 月（节省 56%）
```

详细定价：https://cloud.tencent.com/document/product/436/6239

---

## 🔒 **安全建议**

### 密钥安全
- ✅ 使用子账号密钥（最小权限）
- ✅ 定期轮换密钥
- ✅ 不要将 `.env` 提交到 Git
- ✅ 使用环境变量存储敏感信息

### Bucket 安全
- ✅ 设置为私有读写
- ✅ 使用签名 URL 控制访问
- ✅ 启用防盗链
- ✅ 启用访问日志

---

## 🐛 **故障排查**

### COS 未启用

**现象**：
```
⚠️  COS 未配置，将使用本地存储
```

**解决**：
1. 检查 `.env` 文件是否存在
2. 确认 `COS_SECRET_ID` 和 `COS_SECRET_KEY` 已填写
3. 重启服务

### 上传失败

**现象**：
```
COS 上传失败: NoSuchBucket
```

**解决**：
1. 检查 Bucket 名称是否正确（包含 AppId）
2. 检查 Region 是否正确
3. 确认 Bucket 已创建

### 权限错误

**现象**：
```
Access Denied
```

**解决**：
1. 检查密钥是否正确
2. 确认密钥有 COS 操作权限
3. 检查 Bucket 策略

---

## 📊 **数据迁移**

### 从本地迁移到 COS

如果之前使用本地存储，参考 `COS_INTEGRATION.md` 中的迁移脚本。

### 批量上传

```bash
# 迁移现有 Skills
node migrate-to-cos.js
```

---

## 🎯 **下一步**

### 可选优化

1. **配置 CDN**：参考 `COS_INTEGRATION.md` 配置 CDN 加速
2. **生命周期管理**：自动归档旧文件
3. **跨域访问**：配置 CORS 规则
4. **图片处理**：使用 COS 数据处理功能

---

## 📞 **获取帮助**

- 📖 [COS 官方文档](https://cloud.tencent.com/document/product/436)
- 📖 [COS Node.js SDK](https://cloud.tencent.com/document/product/436/8629)
- 💬 查看日志：`journalctl -u skills-house -f`

---

## 📝 **版本历史**

### v1.1.0 (2026-03-12)
- ✅ 添加 COS 对象存储支持
- ✅ 向后兼容本地存储
- ✅ CDN 加速支持
- ✅ 完整文档和配置脚本

---

## ⚡ **总结**

Skills House 现已支持 COS 对象存储，提供：

- 📦 **无限存储**：不受本地磁盘限制
- 🚀 **CDN 加速**：全球访问加速
- 💰 **成本低廉**：按需付费
- 🔒 **安全可靠**：企业级存储
- 🔄 **向后兼容**：未配置时自动回退

**开始使用**：运行 `./setup-cos.sh` 快速配置！
