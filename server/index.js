const express = require('express');
const multer = require('multer');
const archiver = require('archiver');
const extractZip = require('extract-zip');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fs = require('fs').promises;
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'skills-house-secret-key-change-in-production';

// 中间件
app.use(cors());
app.use(bodyParser.json());
app.use('/uploads', express.static('uploads'));
app.use(express.static('client'));

// 存储配置
const SKILLS_DIR = path.join(__dirname, '../uploads/skills');
const METADATA_FILE = path.join(__dirname, '../uploads/metadata.json');
const USERS_FILE = path.join(__dirname, '../uploads/users.json');

// 确保目录存在
async function ensureDirectories() {
  await fs.mkdir(SKILLS_DIR, { recursive: true });
  try {
    await fs.access(METADATA_FILE);
  } catch {
    await fs.writeFile(METADATA_FILE, JSON.stringify([], null, 2));
  }
  try {
    await fs.access(USERS_FILE);
  } catch {
    await fs.writeFile(USERS_FILE, JSON.stringify([], null, 2));
  }
}

// 读取元数据
async function readMetadata() {
  const data = await fs.readFile(METADATA_FILE, 'utf-8');
  return JSON.parse(data);
}

// 写入元数据
async function writeMetadata(data) {
  await fs.writeFile(METADATA_FILE, JSON.stringify(data, null, 2));
}

// 读取用户数据
async function readUsers() {
  const data = await fs.readFile(USERS_FILE, 'utf-8');
  return JSON.parse(data);
}

// 写入用户数据
async function writeUsers(data) {
  await fs.writeFile(USERS_FILE, JSON.stringify(data, null, 2));
}

// JWT 认证中间件
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: '未提供认证令牌' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: '无效的认证令牌' });
    }
    req.user = user;
    next();
  });
}

// API: 用户注册
app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, password, email } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: '用户名和密码不能为空' });
    }

    if (username.length < 3) {
      return res.status(400).json({ error: '用户名至少3个字符' });
    }

    if (password.length < 6) {
      return res.status(400).json({ error: '密码至少6个字符' });
    }

    const users = await readUsers();

    // 检查用户名是否已存在
    if (users.find(u => u.username === username)) {
      return res.status(400).json({ error: '用户名已存在' });
    }

    // 加密密码
    const hashedPassword = await bcrypt.hash(password, 10);

    // 创建新用户
    const newUser = {
      id: Date.now().toString(),
      username,
      email: email || '',
      password: hashedPassword,
      createdAt: new Date().toISOString(),
      role: 'user'
    };

    users.push(newUser);
    await writeUsers(users);

    // 生成 token
    const token = jwt.sign(
      { id: newUser.id, username: newUser.username, role: newUser.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: newUser.id,
        username: newUser.username,
        email: newUser.email,
        role: newUser.role
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: 用户登录
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ error: '用户名和密码不能为空' });
    }

    const users = await readUsers();
    const user = users.find(u => u.username === username);

    if (!user) {
      return res.status(401).json({ error: '用户名或密码错误' });
    }

    // 验证密码
    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return res.status(401).json({ error: '用户名或密码错误' });
    }

    // 生成 token
    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: 验证 token
app.get('/api/auth/me', authenticateToken, (req, res) => {
  res.json({
    success: true,
    user: {
      id: req.user.id,
      username: req.user.username,
      role: req.user.role
    }
  });
});

// 配置文件上传
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const tempDir = path.join(__dirname, '../uploads/temp');
    await fs.mkdir(tempDir, { recursive: true });
    cb(null, tempDir);
  },
  filename: (req, file, cb) => {
    cb(null, `${Date.now()}-${file.originalname}`);
  }
});

const upload = multer({ storage });

// API: 获取所有 Skills（公开）
app.get('/api/skills', async (req, res) => {
  try {
    const metadata = await readMetadata();
    res.json(metadata);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: 上传 Skill（需要认证）
app.post('/api/skills/upload', authenticateToken, upload.single('file'), async (req, res) => {
  try {
    const { name, description, version } = req.body;
    const file = req.file;
    const author = req.user.username;

    if (!file) {
      return res.status(400).json({ error: '没有上传文件' });
    }

    if (!name) {
      return res.status(400).json({ error: '技能名称不能为空' });
    }

    // 创建 Skill 目录
    const skillId = `${name}-${Date.now()}`;
    const skillDir = path.join(SKILLS_DIR, skillId);
    await fs.mkdir(skillDir, { recursive: true });

    // 解压文件
    if (file.mimetype === 'application/zip' || file.originalname.endsWith('.zip') || 
        file.originalname.endsWith('.tgz') || file.originalname.endsWith('.tar.gz')) {
      try {
        await extractZip(file.path, { dir: skillDir });
      } catch (err) {
        // 如果是 tar.gz，尝试用 tar 解压
        if (file.originalname.endsWith('.tgz') || file.originalname.endsWith('.tar.gz')) {
          const { execSync } = require('child_process');
          execSync(`tar -xzf "${file.path}" -C "${skillDir}"`);
        } else {
          throw err;
        }
      }
    } else {
      // 单文件直接复制
      await fs.copyFile(file.path, path.join(skillDir, file.originalname));
    }

    // 删除临时文件
    await fs.unlink(file.path);

    // 更新元数据
    const metadata = await readMetadata();
    const skillInfo = {
      id: skillId,
      name,
      description: description || '',
      version: version || '1.0.0',
      author,
      uploadedBy: req.user.id,
      uploadedAt: new Date().toISOString(),
      downloadCount: 0
    };
    metadata.push(skillInfo);
    await writeMetadata(metadata);

    res.json({ success: true, skill: skillInfo });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: 下载 Skill（公开）
app.get('/api/skills/:id/download', async (req, res) => {
  try {
    const { id } = req.params;
    const skillDir = path.join(SKILLS_DIR, id);

    // 检查目录是否存在
    await fs.access(skillDir);

    // 创建 zip 压缩包
    const zipPath = path.join(__dirname, `../uploads/temp/${id}.zip`);
    const output = require('fs').createWriteStream(zipPath);
    const archive = archiver('zip', { zlib: { level: 9 } });

    output.on('close', async () => {
      // 更新下载次数
      const metadata = await readMetadata();
      const skill = metadata.find(s => s.id === id);
      if (skill) {
        skill.downloadCount = (skill.downloadCount || 0) + 1;
        await writeMetadata(metadata);
      }

      // 发送文件
      res.download(zipPath, `${id}.zip`, async (err) => {
        // 清理临时文件
        try {
          await fs.unlink(zipPath);
        } catch {}
      });
    });

    archive.on('error', (err) => {
      throw err;
    });

    archive.pipe(output);
    archive.directory(skillDir, false);
    archive.finalize();
  } catch (error) {
    res.status(404).json({ error: 'Skill 不存在' });
  }
});

// API: 删除 Skill（需要认证，只能删除自己的）
app.delete('/api/skills/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const metadata = await readMetadata();
    const skill = metadata.find(s => s.id === id);

    if (!skill) {
      return res.status(404).json({ error: 'Skill 不存在' });
    }

    // 检查权限（管理员或作者本人）
    if (req.user.role !== 'admin' && skill.uploadedBy !== req.user.id) {
      return res.status(403).json({ error: '无权删除此 Skill' });
    }

    const skillDir = path.join(SKILLS_DIR, id);

    // 删除目录
    await fs.rm(skillDir, { recursive: true, force: true });

    // 更新元数据
    const filtered = metadata.filter(s => s.id !== id);
    await writeMetadata(filtered);

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: 搜索 Skills（公开）
app.get('/api/skills/search', async (req, res) => {
  try {
    const { q } = req.query;
    const metadata = await readMetadata();
    
    if (!q) {
      return res.json(metadata);
    }

    const results = metadata.filter(skill => 
      skill.name.toLowerCase().includes(q.toLowerCase()) ||
      (skill.description && skill.description.toLowerCase().includes(q.toLowerCase())) ||
      skill.author.toLowerCase().includes(q.toLowerCase())
    );

    res.json(results);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ==================== 管理员 API ====================

// 管理员权限中间件
function requireAdmin(req, res, next) {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: '需要管理员权限' });
  }
  next();
}

// API: 获取所有用户（管理员）
app.get('/api/admin/users', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const users = await readUsers();
    // 不返回密码
    const safeUsers = users.map(u => ({
      id: u.id,
      username: u.username,
      email: u.email,
      role: u.role,
      createdAt: u.createdAt
    }));
    res.json(safeUsers);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: 更新用户角色（管理员）
app.patch('/api/admin/users/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { role } = req.body;

    if (!['user', 'admin'].includes(role)) {
      return res.status(400).json({ error: '无效的角色' });
    }

    const users = await readUsers();
    const user = users.find(u => u.id === id);

    if (!user) {
      return res.status(404).json({ error: '用户不存在' });
    }

    user.role = role;
    await writeUsers(users);

    res.json({ success: true, user: { id: user.id, username: user.username, role: user.role } });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: 删除用户（管理员）
app.delete('/api/admin/users/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    // 不能删除自己
    if (id === req.user.id) {
      return res.status(400).json({ error: '不能删除自己的账号' });
    }

    const users = await readUsers();
    const filtered = users.filter(u => u.id !== id);

    if (filtered.length === users.length) {
      return res.status(404).json({ error: '用户不存在' });
    }

    await writeUsers(filtered);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: 获取统计信息（管理员）
app.get('/api/admin/stats', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const users = await readUsers();
    const skills = await readMetadata();

    const totalDownloads = skills.reduce((sum, skill) => sum + (skill.downloadCount || 0), 0);

    res.json({
      totalUsers: users.length,
      totalSkills: skills.length,
      totalDownloads,
      adminUsers: users.filter(u => u.role === 'admin').length,
      recentSkills: skills.slice(-5).reverse()
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: 从 URL 爬取并上传 Skill（管理员）
app.post('/api/admin/crawl-skill', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { url, name, description, version } = req.body;

    if (!url || !name) {
      return res.status(400).json({ error: 'URL 和名称不能为空' });
    }

    // 这里添加爬虫逻辑
    // 示例：下载文件并上传
    const axios = require('axios');
    const tempFile = path.join(__dirname, '../uploads/temp', `crawled-${Date.now()}.zip`);

    // 下载文件
    const response = await axios({
      method: 'get',
      url: url,
      responseType: 'stream'
    });

    const writer = require('fs').createWriteStream(tempFile);
    response.data.pipe(writer);

    await new Promise((resolve, reject) => {
      writer.on('finish', resolve);
      writer.on('error', reject);
    });

    // 创建 Skill
    const skillId = `${name}-${Date.now()}`;
    const skillDir = path.join(SKILLS_DIR, skillId);
    await fs.mkdir(skillDir, { recursive: true });

    // 解压
    await extractZip(tempFile, { dir: skillDir });

    // 保存元数据
    const metadata = await readMetadata();
    const newSkill = {
      id: skillId,
      name,
      description: description || `Crawled from ${url}`,
      version: version || '1.0.0',
      author: 'admin',
      uploadedAt: new Date().toISOString(),
      downloadCount: 0,
      uploadedBy: req.user.id,
      crawledFrom: url
    };

    metadata.push(newSkill);
    await writeMetadata(metadata);

    // 清理临时文件
    await fs.unlink(tempFile);

    res.json({ success: true, skill: newSkill });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// SkillHub 同步 API
const skillhubSync = require('./skillhub-sync');

// 获取 SkillHub 同步状态
app.get('/api/skillhub/status', authenticate, async (req, res) => {
  try {
    const state = await skillhubSync.getSyncState();
    const localMetadata = await readMetadata();
    
    res.json({
      success: true,
      state: {
        lastSync: state.lastSync,
        totalSynced: state.totalSynced,
        localSkills: localMetadata.length,
        syncedSkills: Object.keys(state.syncedSkills).length
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 触发增量同步
app.post('/api/skillhub/sync', authenticate, isAdmin, async (req, res) => {
  try {
    const { limit, forceSync } = req.body;
    
    // 在后台执行同步（不阻塞响应）
    res.json({ 
      success: true, 
      message: '同步任务已启动，请稍后查看状态'
    });
    
    // 异步执行同步
    skillhubSync.syncSkills({
      limit: limit || 10,
      forceSync: forceSync || false,
      userId: req.user.id
    }).catch(error => {
      console.error('SkillHub 同步错误:', error);
    });
    
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 获取 SkillHub 索引预览
app.get('/api/skillhub/preview', authenticate, isAdmin, async (req, res) => {
  try {
    const index = await skillhubSync.fetchSkillHubIndex();
    
    // 返回前 50 个 Skills 预览
    res.json({
      success: true,
      total: index.skills.length,
      preview: index.skills.slice(0, 50).map(skill => ({
        slug: skill.slug,
        name: skill.name,
        description: skill.description,
        downloads: skill.stats.downloads,
        stars: skill.stats.stars,
        version: skill.version,
        tags: skill.tags || []
      }))
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 所有其他路由返回前端页面
app.get('*', (req, res) => {
  const indexPath = path.join(__dirname, '../client/dist/index.html');
  const simplePath = path.join(__dirname, '../client/index.html');
  
  // 优先使用构建后的文件，否则使用简化版
  fs.access(indexPath)
    .then(() => res.sendFile(indexPath))
    .catch(() => res.sendFile(simplePath));
});

// 启动服务器
async function start() {
  await ensureDirectories();
  app.listen(PORT, () => {
    console.log(`🚀 Skills House 运行在 http://localhost:${PORT}`);
  });
}

start();
