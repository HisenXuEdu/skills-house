# COS 集成 - 代码修改指南

本文档提供将 COS 存储集成到 Skills House 的详细代码修改步骤。

---

## 📝 **修改清单**

### 1. 修改 `server/index.js` - 添加 COS 引用

在文件顶部添加：

```javascript
// 在第 12 行附近，其他 require 语句之后添加
const cosStorage = require('./cos-storage');

// 在第 18 行附近，PORT 定义之后添加
console.log('🚀 启动 Skills House...');
console.log('📦 存储模式:', cosStorage.enabled ? 'COS 对象存储' : '本地文件系统');
```

---

### 2. 修改上传 Skills API

找到 `POST /api/skills/upload` 路由（大约第 100-150 行），修改为：

```javascript
// 上传 Skill
app.post('/api/skills/upload', authenticateToken, upload.single('file'), async (req, res) => {
  try {
    const { name, description, version, author } = req.body;
    const file = req.file;

    if (!file) {
      return res.status(400).json({ error: '请上传文件' });
    }

    // 生成唯一 ID
    const skillId = `${name}-${Date.now()}`;
    const skillDir = path.join(SKILLS_DIR, skillId);

    // 解压文件到临时目录
    await fs.mkdir(skillDir, { recursive: true });
    await extractZip(file.path, { dir: skillDir });

    // 如果启用了 COS，上传到 COS
    let cosUrl = null;
    if (cosStorage.enabled) {
      try {
        console.log(`📤 上传到 COS: ${skillId}...`);
        const result = await cosStorage.uploadDirectory(skillDir, `${skillId}.zip`);
        cosUrl = result.url;
        console.log(`✅ COS 上传成功: ${cosUrl}`);
        
        // 可选：上传成功后删除本地文件以节省空间
        // await fs.rm(skillDir, { recursive: true });
      } catch (cosError) {
        console.error('⚠️  COS 上传失败，保留本地文件:', cosError.message);
      }
    }

    // 保存元数据
    const metadata = await readMetadata();
    const skillMeta = {
      id: skillId,
      name,
      description: description || '',
      version: version || '1.0.0',
      author: author || req.user.username,
      uploadedBy: req.user.id,
      uploadedAt: new Date().toISOString(),
      downloadCount: 0,
      cosUrl: cosUrl, // COS URL（如果启用）
      storedInCos: !!cosUrl // 标记是否存储在 COS
    };

    metadata.push(skillMeta);
    await writeMetadata(metadata);

    // 删除临时上传文件
    await fs.unlink(file.path);

    res.json({
      success: true,
      skill: skillMeta,
      message: `Skill 上传成功${cosUrl ? '（已存储到 COS）' : ''}`
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ error: '上传失败: ' + error.message });
  }
});
```

---

### 3. 修改下载 Skills API

找到 `GET /api/skills/:id/download` 路由（大约第 200-250 行），修改为：

```javascript
// 下载 Skill
app.get('/api/skills/:id/download', async (req, res) => {
  try {
    const skillId = req.params.id;
    const metadata = await readMetadata();
    const skill = metadata.find(s => s.id === skillId);

    if (!skill) {
      return res.status(404).json({ error: 'Skill 不存在' });
    }

    // 更新下载计数
    skill.downloadCount = (skill.downloadCount || 0) + 1;
    await writeMetadata(metadata);

    // 如果存储在 COS，重定向到 COS URL
    if (skill.storedInCos && cosStorage.enabled) {
      try {
        console.log(`📥 从 COS 获取下载链接: ${skillId}...`);
        const downloadUrl = await cosStorage.getDownloadUrl(`${skillId}.zip`, 3600);
        console.log(`✅ COS 下载链接生成成功`);
        return res.redirect(downloadUrl);
      } catch (cosError) {
        console.error('⚠️  COS 下载失败，尝试本地文件:', cosError.message);
        // 失败则继续使用本地文件
      }
    }

    // 从本地文件系统下载
    const skillDir = path.join(SKILLS_DIR, skillId);
    
    // 检查本地文件是否存在
    try {
      await fs.access(skillDir);
    } catch {
      return res.status(404).json({ error: 'Skill 文件不存在' });
    }

    // 创建临时 zip 文件
    const tempZipPath = path.join(__dirname, `../uploads/temp/${skillId}-${Date.now()}.zip`);
    await fs.mkdir(path.dirname(tempZipPath), { recursive: true });

    const output = fsSync.createWriteStream(tempZipPath);
    const archive = archiver('zip', { zlib: { level: 9 } });

    archive.pipe(output);
    archive.directory(skillDir, false);
    await archive.finalize();

    // 等待写入完成
    await new Promise((resolve, reject) => {
      output.on('close', resolve);
      output.on('error', reject);
    });

    // 发送文件
    res.download(tempZipPath, `${skill.name}.zip`, async (err) => {
      // 下载完成后删除临时文件
      try {
        await fs.unlink(tempZipPath);
      } catch (unlinkError) {
        console.error('删除临时文件失败:', unlinkError);
      }

      if (err) {
        console.error('Download error:', err);
      }
    });
  } catch (error) {
    console.error('Download error:', error);
    res.status(500).json({ error: '下载失败: ' + error.message });
  }
});
```

---

### 4. 修改删除 Skills API

找到 `DELETE /api/skills/:id` 路由（大约第 300-350 行），修改为：

```javascript
// 删除 Skill
app.delete('/api/skills/:id', authenticateToken, async (req, res) => {
  try {
    const skillId = req.params.id;
    const metadata = await readMetadata();
    const skillIndex = metadata.findIndex(s => s.id === skillId);

    if (skillIndex === -1) {
      return res.status(404).json({ error: 'Skill 不存在' });
    }

    const skill = metadata[skillIndex];

    // 权限检查：只有管理员或作者可以删除
    if (req.user.role !== 'admin' && req.user.id !== skill.uploadedBy) {
      return res.status(403).json({ error: '没有权限删除此 Skill' });
    }

    // 如果存储在 COS，从 COS 删除
    if (skill.storedInCos && cosStorage.enabled) {
      try {
        console.log(`🗑️  从 COS 删除: ${skillId}...`);
        await cosStorage.deleteFile(`${skillId}.zip`);
        console.log(`✅ COS 文件已删除`);
      } catch (cosError) {
        console.error('⚠️  COS 删除失败（继续删除本地文件）:', cosError.message);
      }
    }

    // 删除本地文件
    const skillDir = path.join(SKILLS_DIR, skillId);
    try {
      await fs.rm(skillDir, { recursive: true, force: true });
      console.log(`✅ 本地文件已删除: ${skillId}`);
    } catch (fsError) {
      console.error('⚠️  本地文件删除失败:', fsError.message);
    }

    // 从元数据中删除
    metadata.splice(skillIndex, 1);
    await writeMetadata(metadata);

    res.json({
      success: true,
      message: 'Skill 删除成功'
    });
  } catch (error) {
    console.error('Delete error:', error);
    res.status(500).json({ error: '删除失败: ' + error.message });
  }
});
```

---

## 🚀 **部署步骤**

### 1. 安装依赖

```bash
cd /data/skills-house
npm install cos-nodejs-sdk-v5 --save
```

### 2. 配置环境变量

创建 `.env` 文件：

```bash
nano /data/skills-house/.env
```

填入：

```env
JWT_SECRET=your-secret-key-here
PORT=3100

# COS 配置
COS_SECRET_ID=your-secret-id
COS_SECRET_KEY=your-secret-key
COS_BUCKET=skills-house-1234567890
COS_REGION=ap-guangzhou
```

### 3. 应用代码修改

按照上述步骤修改 `server/index.js`

### 4. 重启服务

```bash
systemctl restart skills-house
journalctl -u skills-house -f
```

### 5. 验证

查看日志，应该看到：
```
🚀 启动 Skills House...
📦 存储模式: COS 对象存储
✅ COS 存储已启用: { bucket: 'skills-house-xxx', region: 'ap-guangzhou' }
```

---

## 🧪 **测试**

### 测试上传

```bash
# 上传一个 Skill
curl -X POST http://175.27.141.110:3100/api/skills/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@test-skill.zip" \
  -F "name=test-skill" \
  -F "description=Test Skill" \
  -F "version=1.0.0"
```

查看日志，应该看到：
```
📤 上传到 COS: test-skill-1710234567890...
✅ COS 上传成功: https://...
```

### 测试下载

```bash
curl -I http://175.27.141.110:3100/api/skills/test-skill-1710234567890/download
```

应该返回 302 重定向到 COS URL。

---

## 📊 **监控**

### 查看 COS 使用情况

访问 COS 控制台：
```
https://console.cloud.tencent.com/cos5/bucket
```

查看：
- 存储用量
- 请求次数
- 流量统计

---

## 🔄 **回滚方案**

如果 COS 出现问题，可以临时禁用：

### 方法 1：修改环境变量

```bash
nano /data/skills-house/.env
```

注释掉 COS 配置：
```env
# COS_SECRET_ID=xxx
# COS_SECRET_KEY=xxx
```

重启服务：
```bash
systemctl restart skills-house
```

### 方法 2：修改代码

在 `server/cos-config.js` 中强制禁用：
```javascript
enabled: false, // 强制禁用 COS
```

---

## 📝 **完整示例文件**

完整修改后的 `server/index.js` 已保存在：
```
/root/.openclaw/workspace/skills-house/server/index-cos-example.js
```

可以参考此文件进行修改。

---

需要帮助？查看日志或参考 `COS_INTEGRATION.md` 文档。
