# SkillHub 同步功能使用指南

## 🎯 功能概述

Skills House 现已集成 **SkillHub 同步功能**，可以从腾讯 SkillHub (https://skillhub.tencent.com/) 自动同步 Skills 到本地平台。

---

## 🚀 快速开始

### 1. 访问管理面板

```
http://175.27.141.110:3100/admin.html
```

**登录信息**：
- 用户名：`admin`
- 密码：`admin123456`

### 2. 进入 SkillHub 同步标签

点击顶部导航的 **🔄 SkillHub 同步** 标签页。

---

## 📊 功能说明

### 同步状态面板

显示当前的同步状态：
- **已同步 Skills**：从 SkillHub 同步的 Skills 总数
- **本地 Skills**：本地所有 Skills 数量
- **同步记录**：同步状态记录数
- **上次同步**：最近一次同步的时间

点击 **🔄 刷新状态** 可以实时更新状态信息。

---

### 增量同步

**功能特点**：
- ✅ 只同步新增或更新的 Skills
- ✅ 已存在的 Skills 自动跳过
- ✅ 智能比对更新时间
- ✅ 保留本地下载统计

**操作步骤**：

1. **设置同步数量限制**
   ```
   输入框：10
   ```
   建议首次同步设置较小数量（如 10-50）进行测试。

2. **可选：强制重新同步**
   ```
   勾选：☑ 强制重新同步所有 Skills
   ```
   ⚠️ 启用后将忽略已同步状态，重新下载所有 Skills。

3. **点击 "🚀 开始增量同步"**
   
   系统会在后台执行同步任务，每 3 秒自动刷新状态。

---

### 预览 SkillHub

点击 **👀 预览 SkillHub** 按钮，可以查看 SkillHub 索引中的前 50 个 Skills。

**显示信息**：
- Slug（唯一标识）
- 名称
- 描述
- 下载量
- 收藏数
- 版本号

**用途**：
- 了解 SkillHub 有哪些 Skills 可用
- 查看热门 Skills
- 决定是否需要同步

---

### 手动爬取 URL

如果需要从其他来源爬取 Skill，可以使用手动爬取功能：

1. **输入 Skill URL**：指向 .zip、.tgz 或 .tar.gz 文件的直链
2. **输入 Skill 名称**：例如 `my-skill`
3. **输入描述**（可选）：描述 Skill 的功能
4. **输入版本**（可选）：例如 `1.0.0`
5. **点击 "🕷️ 爬取并上传"**

---

## 🔧 技术原理

### 下载策略

**直接 COS 下载**（绕过负载均衡器）：
```
https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/{slug}.zip
```

**优点**：
- ✅ 高速下载（腾讯云 COS 直连）
- ✅ 稳定可靠
- ✅ 无需认证
- ✅ 支持大文件

---

### 同步流程

```
1. 下载 SkillHub 索引（12,891 个 Skills）
   ↓
2. 比对本地状态（跳过已同步）
   ↓
3. 批量下载 Skills 压缩包（从 COS）
   ↓
4. 解压并提取元数据
   ↓
5. 保存到本地数据库
   ↓
6. 更新同步状态
```

---

### 状态持久化

同步状态保存在：
```
/data/skills-house/uploads/skillhub-sync-state.json
```

**内容示例**：
```json
{
  "lastSync": "2026-03-13T00:10:00.000Z",
  "totalSynced": 50,
  "syncedSkills": {
    "github": {
      "name": "Github",
      "syncedAt": 1710280200000,
      "action": "added"
    },
    "whisper": {
      "name": "Whisper",
      "syncedAt": 1710280205000,
      "action": "updated"
    }
  }
}
```

---

## 💡 使用建议

### 首次同步

```
1. 点击 "预览 SkillHub" 查看可用 Skills
2. 设置同步数量为 10，测试同步功能
3. 检查同步结果和状态
4. 逐步增加数量，直到同步完成
```

### 日常使用

```
1. 定期点击 "开始增量同步"（推荐每周一次）
2. 设置数量为 50-100（增量模式只同步新增/更新）
3. 查看同步状态确认完成
```

### 全量同步

```
1. 勾选 "强制重新同步所有 Skills"
2. 设置数量为空（或较大数值）
3. 点击 "开始增量同步"
4. 等待所有 Skills 同步完成（可能需要较长时间）
```

---

## 📈 数据统计

### SkillHub 索引规模

- **总 Skills 数**：12,891 个
- **来源**：ClawHub (https://clawhub.ai)
- **更新频率**：实时同步
- **存储位置**：腾讯云 COS（广州）

### 热门 Skills（示例）

1. **self-improving-agent** - 81,000 下载
2. **Gog** (Google Workspace) - 75,000 下载
3. **Tavily Web Search** - 72,000 下载
4. **Summarize** - 63,000 下载
5. **Agent Browser** - 59,000 下载

---

## 🔒 安全说明

### 下载安全

- ✅ 所有 Skills 来自官方 SkillHub
- ✅ 使用腾讯云 COS 安全存储
- ✅ 下载过程经过完整性验证
- ✅ 自动解压和元数据提取

### 权限控制

- 🔐 **管理员专属**：只有管理员可以执行同步
- 🔐 **JWT 认证**：所有 API 调用需要有效令牌
- 🔐 **后台执行**：同步在服务器端后台进行

---

## 🛠️ 故障排除

### 同步失败

**可能原因**：
1. 网络连接问题
2. COS 访问超时
3. 磁盘空间不足
4. 解压失败

**解决方法**：
1. 检查服务器网络连接
2. 降低同步数量限制
3. 清理磁盘空间
4. 查看服务器日志：`journalctl -u skills-house -f`

### 状态不更新

**解决方法**：
1. 点击 "🔄 刷新状态"
2. 重新加载页面
3. 检查服务器是否正常运行

### 预览加载失败

**可能原因**：
- SkillHub 索引下载失败（较大，约 8.9MB）

**解决方法**：
1. 检查网络连接
2. 稍后重试
3. 直接开始增量同步（不影响功能）

---

## 📚 相关文档

- **SkillHub 官网**：https://skillhub.tencent.com/
- **ClawHub 官网**：https://clawhub.ai
- **SkillHub 分析文档**：`/root/.openclaw/workspace/skills-house/SKILLHUB_ANALYSIS.md`
- **SkillHub 下载机制**：`/root/.openclaw/workspace/skills-house/SKILLHUB_DOWNLOAD_ANALYSIS.md`

---

## 🎉 总结

### 核心优势

1. **自动化同步**：一键同步 12,891 个 Skills
2. **增量更新**：智能跳过已存在的 Skills
3. **高速下载**：直连腾讯云 COS
4. **状态追踪**：实时显示同步进度
5. **零配置**：开箱即用

### 使用场景

- 📦 **快速建站**：一次性同步所有 Skills
- 🔄 **定期更新**：增量同步最新 Skills
- 🔍 **内容发现**：预览并选择性同步
- 🚀 **平台迁移**：从 SkillHub 迁移到 Skills House

---

**开始使用 SkillHub 同步，让 Skills House 拥有丰富的 Skills 资源！** 🎊
