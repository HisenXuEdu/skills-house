# SkillHub Skills 下载地址完全解析

## ✅ **结论：可以直接获取任意 Skill 的下载地址！**

---

## 🎯 **核心发现**

### **SkillHub 的完整下载机制**

SkillHub 使用 **双通道下载策略**：

1. **主通道（Primary）**：腾讯云负载均衡器
2. **备用通道（Fallback）**：腾讯云 COS 直连

---

## 📦 **完整的技术架构**

### 1. **索引文件**

#### 本地索引（打包在 CLI 中）
```
https://skillhub-1251783334.cos.ap-guangzhou.myqcloud.com/install/latest.tar.gz
└── cli/skills_index.local.json       # 12,891 个 Skills 的元数据（8.9MB）
```

#### 在线索引（实时更新）
```
https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills.json
```

---

### 2. **下载地址模板**

#### 主下载通道（负载均衡）
```
http://lb-3zbg86f6-0gwe3n7q8t4sv2za.clb.gz-tencentclb.com/api/v1/download?slug={slug}
```

- **类型**：腾讯云 CLB（Cloud Load Balancer）
- **用途**：统计下载量、动态路由、A/B 测试
- **特点**：可控制、可统计、可监控

#### 备用下载通道（COS 直连）
```
https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/{slug}.zip
```

- **类型**：腾讯云 COS 对象存储
- **用途**：高速直连、备用通道
- **特点**：稳定、快速、可靠

---

### 3. **Skills 元数据示例**

```json
{
  "slug": "github",
  "name": "Github",
  "description": "通过 gh CLI 与 GitHub 进行高效交互...",
  "source": "clawhub",
  "zip_url": "https://clawhub.ai/api/v1/download?slug=github",
  "homepage": "https://clawhub.ai/github",
  "version": "1.0.0",
  "tags": ["latest"],
  "updated_at": 1772063136179,
  "stats": {
    "downloads": 59000,
    "stars": 198,
    "installs_current": 1234,
    "installs_all_time": 5678,
    "versions": 1
  }
}
```

---

## 🔓 **获取下载地址的方法**

### 方法 1：从本地索引获取（最快）

```bash
# 步骤 1：下载并解压 SkillHub CLI
curl -sL "https://skillhub-1251783334.cos.ap-guangzhou.myqcloud.com/install/latest.tar.gz" | tar xz

# 步骤 2：查询 Skill 信息
python3 << 'EOF'
import json

with open('cli/skills_index.local.json', 'r') as f:
    data = json.load(f)

skills = data.get('skills', [])

# 查找 github skill
for skill in skills:
    if skill['slug'] == 'github':
        print(f"Name: {skill['name']}")
        print(f"Description: {skill['description']}")
        print(f"Version: {skill['version']}")
        print(f"Downloads: {skill['stats']['downloads']}")
        print(f"\nOriginal URL: {skill['zip_url']}")
        print(f"SkillHub Mirror: https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/{skill['slug']}.zip")
        break
EOF
```

**输出示例**：
```
Name: Github
Description: 通过 gh CLI 与 GitHub 进行高效交互...
Version: 1.0.0
Downloads: 59000

Original URL: https://clawhub.ai/api/v1/download?slug=github
SkillHub Mirror: https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/github.zip
```

---

### 方法 2：直接构造 COS URL（最简单）

如果知道 Skill 的 `slug`，直接构造下载链接：

```bash
# 模板
https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/{slug}.zip

# 示例
https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/github.zip
https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/whisper.zip
https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/summarize.zip
```

---

### 方法 3：从在线索引获取（实时数据）

```bash
# 下载在线索引
curl -sL "https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills.json" > skills.json

# 查询特定 Skill
jq '.skills[] | select(.slug == "github")' skills.json
```

---

## 🧪 **验证测试**

### 测试 1：直接下载 github skill

```bash
curl -O "https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/github.zip"

# 查看文件信息
file github.zip
unzip -l github.zip
```

**结果**：
```
HTTP/1.1 200 OK
Content-Type: application/zip
Content-Length: 895
```

✅ **成功下载！**

---

### 测试 2：批量获取 Skills 信息

```bash
# 下载本地索引
curl -sL "https://skillhub-1251783334.cos.ap-guangzhou.myqcloud.com/install/latest.tar.gz" | tar xz

# 列出所有 Skills
python3 << 'EOF'
import json

with open('cli/skills_index.local.json', 'r') as f:
    data = json.load(f)

skills = data.get('skills', [])

print(f"Total skills: {len(skills)}\n")
print("Top 10 Skills:\n")

# 按下载量排序
sorted_skills = sorted(skills, key=lambda x: x['stats']['downloads'], reverse=True)

for i, skill in enumerate(sorted_skills[:10], 1):
    print(f"{i}. {skill['name']} ({skill['slug']})")
    print(f"   Downloads: {skill['stats']['downloads']:,}")
    print(f"   URL: https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/{skill['slug']}.zip")
    print()
EOF
```

**输出示例**：
```
Total skills: 12891

Top 10 Skills:

1. self-improving-agent (self-improving-agent)
   Downloads: 81,000
   URL: https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/self-improving-agent.zip

2. Gog (gog)
   Downloads: 75,000
   URL: https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/gog.zip

...
```

---

## 📊 **完整的 URL 体系**

### 索引相关
| 类型 | URL | 说明 |
|------|-----|------|
| **本地索引** | `https://skillhub-1251783334.cos.ap-guangzhou.myqcloud.com/install/latest.tar.gz` | 打包的完整索引 |
| **在线索引** | `https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills.json` | 实时更新的索引 |
| **搜索 API** | `http://lb-3zbg86f6-0gwe3n7q8t4sv2za.clb.gz-tencentclb.com/api/v1/search` | 搜索服务 |

### 下载相关
| 类型 | URL 模板 | 说明 |
|------|----------|------|
| **主下载** | `http://lb-3zbg86f6-0gwe3n7q8t4sv2za.clb.gz-tencentclb.com/api/v1/download?slug={slug}` | 负载均衡器 |
| **备用下载** | `https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/{slug}.zip` | COS 直连 |
| **原始来源** | `https://clawhub.ai/api/v1/download?slug={slug}` | ClawHub 官方 |

### 更新相关
| 类型 | URL | 说明 |
|------|-----|------|
| **版本信息** | `https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/version.json` | CLI 版本信息 |
| **安装脚本** | `https://skillhub-1251783334.cos.ap-guangzhou.myqcloud.com/install/install.sh` | 安装脚本 |

---

## 🔍 **数据结构分析**

### skills_index.local.json 结构

```json
{
  "version": 1,
  "name": "clawhub-mirror-index",
  "description": "SkillHub mirror index for ClawHub skills",
  "generated_at": 1736145234567,
  "site": "https://skillhub.tencent.com",
  "skills": [
    {
      "slug": "skill-name",
      "name": "Skill Display Name",
      "description": "Skill description...",
      "source": "clawhub",
      "zip_url": "https://clawhub.ai/api/v1/download?slug=skill-name",
      "homepage": "https://clawhub.ai/skill-name",
      "version": "1.0.0",
      "tags": ["latest"],
      "updated_at": 1736145234567,
      "stats": {
        "downloads": 12345,
        "stars": 123,
        "installs_current": 456,
        "installs_all_time": 789,
        "versions": 1
      }
    }
  ]
}
```

### metadata.json 配置

```json
{
  "skills_index_url": "COS 索引地址",
  "skills_search_url": "搜索 API 地址",
  "skills_primary_download_url_template": "主下载通道模板",
  "skills_download_url_template": "备用下载通道模板",
  "self_update_manifest_url": "更新清单地址"
}
```

---

## 💡 **Skills House 可以借鉴的点**

### 1. **双通道下载策略**

```javascript
// Skills House 实现
app.get('/api/skills/:id/download', async (req, res) => {
  const skill = await getSkill(req.params.id);
  
  // 更新统计
  skill.downloadCount++;
  await saveSkill(skill);
  
  // 尝试主通道（服务器）
  if (skill.storedInCos) {
    try {
      const cosUrl = await cosStorage.getDownloadUrl(`${skill.id}.zip`, 3600);
      return res.redirect(cosUrl);
    } catch (error) {
      console.error('COS download failed, fallback to local');
    }
  }
  
  // 备用通道（本地文件）
  const localZip = await createLocalZip(skill.id);
  res.download(localZip);
});
```

---

### 2. **本地索引 + 在线索引**

```javascript
// 打包本地索引到 CLI
{
  "version": 1,
  "generated_at": "2026-03-12T15:00:00Z",
  "skills": [
    // 12,891 个 Skills 的完整信息
  ]
}

// 在线索引（实时更新）
app.get('/api/skills/index.json', async (req, res) => {
  const skills = await getAllSkills();
  res.json({
    version: 1,
    generated_at: new Date().toISOString(),
    skills: skills
  });
});
```

---

### 3. **CLI 工具集成**

```bash
# skills-house CLI
skills-house install github

# 等价于
curl -O "https://skills-house.com/api/download/github"
```

---

### 4. **统计与监控**

```javascript
// 下载统计（通过主通道）
app.get('/api/v1/download', async (req, res) => {
  const { slug } = req.query;
  
  // 1. 记录统计
  await recordDownload(slug, {
    ip: req.ip,
    userAgent: req.headers['user-agent'],
    timestamp: Date.now()
  });
  
  // 2. 重定向到 COS
  const cosUrl = `https://skills-house-xxx.cos.ap-guangzhou.myqcloud.com/skills/${slug}.zip`;
  res.redirect(cosUrl);
});
```

---

## 🔒 **安全建议**

### 对于 SkillHub

#### 已暴露的信息
- ✅ 两个 COS Bucket 地址
- ✅ 负载均衡器地址
- ✅ 完整的 Skills 索引（12,891 个）
- ✅ 每个 Skill 的下载地址模板

#### 风险评估
**风险等级**：🟡 **中等**

**原因**：
- ⚠️ 用户可以绕过官方统计直接下载
- ⚠️ 完整架构暴露
- ⚠️ 可能被爬虫大量下载

---

### 对于 Skills House

#### 推荐方案：临时签名 URL

```javascript
// 生成临时签名 URL（推荐）
const downloadUrl = await cosStorage.getDownloadUrl(
  `skills/${skillId}.zip`,
  3600  // 1 小时有效期
);

res.json({
  success: true,
  downloadUrl: downloadUrl,  // 包含签名的临时 URL
  expiresAt: Date.now() + 3600000
});
```

**优点**：
- ✅ 控制访问时效
- ✅ 统计下载量
- ✅ 防止爬虫
- ✅ 保护 Bucket 结构

---

## 🚀 **实战：批量下载 Skills**

### 脚本示例

```bash
#!/bin/bash
# download-skills.sh - 批量下载 SkillHub Skills

# 下载索引
curl -sL "https://skillhub-1251783334.cos.ap-guangzhou.myqcloud.com/install/latest.tar.gz" | tar xz

# 提取 top 10 Skills
python3 << 'EOF' > download-list.txt
import json

with open('cli/skills_index.local.json', 'r') as f:
    data = json.load(f)

skills = data['skills']
sorted_skills = sorted(skills, key=lambda x: x['stats']['downloads'], reverse=True)

for skill in sorted_skills[:10]:
    print(skill['slug'])
EOF

# 批量下载
mkdir -p skills
while read slug; do
    echo "Downloading $slug..."
    curl -sL "https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/${slug}.zip" \
         -o "skills/${slug}.zip"
done < download-list.txt

echo "✅ Download complete!"
ls -lh skills/
```

---

## 📚 **总结**

### 关键发现

1. ✅ **可以获取任意 Skill 的下载地址**
2. ✅ **双通道下载**：负载均衡器 + COS 直连
3. ✅ **完整索引**：12,891 个 Skills 的元数据
4. ✅ **直接下载**：无需认证即可从 COS 下载

### 下载地址模板

```
# 主通道（统计）
http://lb-3zbg86f6-0gwe3n7q8t4sv2za.clb.gz-tencentclb.com/api/v1/download?slug={slug}

# 备用通道（直连）
https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/{slug}.zip
```

### Skills House 的改进方向

1. 📝 **添加 CLI 工具**：`skills-house install <skill>`
2. 📝 **双通道下载**：主通道统计 + COS 直连
3. 📝 **本地索引**：打包完整索引到 CLI
4. 📝 **临时签名**：使用 COS 签名 URL 提升安全性

---

**🎯 结论：通过 SkillHub 的安装脚本，可以完全获取到所有 Skills 的下载地址，并且可以直接从 COS 下载！**
