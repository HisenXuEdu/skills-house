# SkillHub 同步 - 轻量版说明

## 🎯 **新的设计方案**

### 核心改进

✅ **不下载文件** - 只同步元数据
✅ **保存 URL** - 存储 SkillHub COS 下载地址
✅ **按需下载** - 用户下载时才从 URL 获取
✅ **超快同步** - 10倍速度提升
✅ **节省空间** - 不占用本地存储

---

## 📦 **存储类型**

### 两种存储方式

#### 1. URL 类型（SkillHub 同步）
```json
{
  "id": "github",
  "name": "Github",
  "storageType": "url",
  "downloadUrl": "https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/github.zip",
  "skillhub": {
    "slug": "github",
    "stats": { "downloads": 59000, "stars": 198 }
  }
}
```

**特点**：
- ⚡ 不下载文件
- 💾 不占用磁盘
- 🔄 始终获取最新版本
- 📊 统计下载次数

#### 2. File 类型（用户上传）
```json
{
  "id": "my-skill",
  "name": "My Skill",
  "storageType": "file",
  "zipFile": "my-skill.zip",
  "uploadedBy": "user123"
}
```

**特点**：
- 📁 存储在本地
- 🔒 完全控制
- ⚡ 快速访问
- 📦 打包下载

---

## 🚀 **下载流程**

### URL 类型（重定向）
```
用户点击下载
   ↓
GET /api/skills/github/download
   ↓
查询 metadata（storageType: 'url'）
   ↓
更新下载计数
   ↓
重定向到 SkillHub COS
   ↓
302 → https://skillhub-xxx.cos.ap-guangzhou.myqcloud.com/skills/github.zip
   ↓
用户直接从 COS 下载
```

### File 类型（本地）
```
用户点击下载
   ↓
GET /api/skills/my-skill/download
   ↓
查询 metadata（storageType: 'file'）
   ↓
从本地目录打包 zip
   ↓
更新下载计数
   ↓
返回 zip 文件
```

---

## ⚡ **同步性能**

### 对比

| 特性 | 旧版本（下载文件） | 新版本（只保存 URL） |
|------|-------------------|---------------------|
| **同步速度** | ~5 秒/skill | ~0.1 秒/skill |
| **同步 100 个** | ~8 分钟 | ~10 秒 |
| **同步 1000 个** | ~1.5 小时 | ~2 分钟 |
| **磁盘占用** | ~500 MB | ~1 MB |
| **网络流量** | 下载全部文件 | 只下载索引 |

### 实测性能

- **索引下载**：8.9 MB（一次性）
- **单个 Skill**：约 0.1 秒（只写元数据）
- **100 个 Skills**：约 10 秒
- **12,891 个 Skills**：约 20 分钟（全量）

---

## 📖 **使用指南**

### 快速同步

1. **访问管理面板**
   ```
   http://175.27.141.110:3100/admin.html
   ```

2. **点击 "🔄 SkillHub 同步"**

3. **设置同步数量**
   - 建议：100-1000（元数据同步很快）
   - 全量：留空或设为 15000

4. **点击 "🚀 开始增量同步"**

5. **等待完成**
   - 100 个：约 10 秒
   - 1000 个：约 2 分钟
   - 全量（12,891）：约 20 分钟

---

## 💡 **常见问题**

### Q: 用户下载会变慢吗？

**A: 不会！**
- 重定向到 SkillHub COS（腾讯云）
- 高速 CDN 分发
- 和从 SkillHub 官网下载速度一样

---

### Q: 如何区分 SkillHub 和上传的 Skills？

**A: 通过 storageType 字段**
```javascript
// SkillHub Skills
skill.storageType === 'url'  // 从 URL 下载

// 上传的 Skills
skill.storageType === 'file'  // 从本地下载
// 或 skill.storageType === undefined（兼容旧数据）
```

在前端可以显示不同的标识：
- 🌐 SkillHub
- 📁 本地上传

---

### Q: 如何同步全部 12,891 个 Skills？

**A: 两种方法**

**方法 1：增量同步（推荐）**
```
1. 设置数量: 1000
2. 点击 "开始增量同步"
3. 等待完成（约 2 分钟）
4. 重复步骤 2-3，直到 "需要同步: 0"
```

**方法 2：全量同步**
```
1. 勾选 "强制重新同步所有 Skills"
2. 设置数量: 留空（或 15000）
3. 点击 "开始增量同步"
4. 等待完成（约 20 分钟）
```

---

### Q: 下载统计还准确吗？

**A: 准确！**
- 每次下载前更新计数
- 存储在本地 metadata.json
- 不影响 SkillHub 官方统计

---

### Q: 可以离线使用吗？

**A: 部分可以**
- **URL 类型**：需要网络（从 SkillHub 下载）
- **File 类型**：完全离线

---

## 🔧 **技术细节**

### Metadata 结构

```json
{
  "id": "github",
  "name": "Github",
  "description": "通过 gh CLI 与 GitHub 进行高效交互",
  "version": "1.0.0",
  "uploadedBy": "skillhub-sync",
  "uploadedAt": "2026-03-13T00:19:00.000Z",
  
  "storageType": "url",
  "downloadUrl": "https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/github.zip",
  
  "skillhub": {
    "slug": "github",
    "source": "clawhub",
    "homepage": "https://clawhub.ai/github",
    "originalZipUrl": "https://clawhub.ai/api/v1/download?slug=github",
    "stats": {
      "downloads": 59000,
      "stars": 198,
      "installs_current": 1234,
      "installs_all_time": 5678,
      "versions": 1
    },
    "tags": ["latest"],
    "updated_at": 1772063136179
  },
  
  "downloadCount": 0
}
```

---

### API 端点

#### 下载 Skill
```
GET /api/skills/{id}/download
```

**响应**：
- **URL 类型**：`302 Redirect` → SkillHub COS
- **File 类型**：`200 OK` + zip 文件流

---

### 兼容性

#### 旧数据兼容
```javascript
// 旧的 Skill（没有 storageType）
if (!skill.storageType) {
  // 默认为 file 类型
  storageType = 'file';
}
```

#### 新的 Skill
- 上传：自动设为 `storageType: 'file'`
- 同步：自动设为 `storageType: 'url'`

---

## 📊 **性能优化建议**

### 首次同步

```
1. 同步 100 个测试（10 秒）
2. 同步 1000 个（2 分钟）
3. 全量同步（20 分钟）
```

### 日常更新

```
每周执行一次增量同步（数量：500-1000）
只同步新增或更新的 Skills
```

### 磁盘管理

- **URL 类型**：几乎不占用空间
- **File 类型**：定期清理旧版本

---

## 🎉 **总结**

### 新方案优势

1. ✅ **超快同步**：10倍速度提升
2. ✅ **节省空间**：不存储文件
3. ✅ **简单维护**：只管理元数据
4. ✅ **高速下载**：直连 SkillHub COS
5. ✅ **灵活存储**：支持两种类型

### 使用建议

- **SkillHub Skills**：使用 URL 类型（推荐）
- **自己的 Skills**：上传为 File 类型
- **定期同步**：每周增量更新一次

---

**立即体验轻量级 SkillHub 同步！** 🚀
