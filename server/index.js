const express = require('express');
const multer = require('multer');
const archiver = require('archiver');
const extractZip = require('extract-zip');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs').promises;
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(bodyParser.json());
app.use('/uploads', express.static('uploads'));
app.use(express.static('client/dist'));

// 存储配置
const SKILLS_DIR = path.join(__dirname, '../uploads/skills');
const METADATA_FILE = path.join(__dirname, '../uploads/metadata.json');

// 确保目录存在
async function ensureDirectories() {
  await fs.mkdir(SKILLS_DIR, { recursive: true });
  try {
    await fs.access(METADATA_FILE);
  } catch {
    await fs.writeFile(METADATA_FILE, JSON.stringify([], null, 2));
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

// API: 获取所有 Skills
app.get('/api/skills', async (req, res) => {
  try {
    const metadata = await readMetadata();
    res.json(metadata);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: 上传 Skill
app.post('/api/skills/upload', upload.single('file'), async (req, res) => {
  try {
    const { name, description, version, author } = req.body;
    const file = req.file;

    if (!file) {
      return res.status(400).json({ error: '没有上传文件' });
    }

    // 创建 Skill 目录
    const skillId = `${name}-${Date.now()}`;
    const skillDir = path.join(SKILLS_DIR, skillId);
    await fs.mkdir(skillDir, { recursive: true });

    // 解压文件
    if (file.mimetype === 'application/zip' || file.originalname.endsWith('.zip')) {
      await extractZip(file.path, { dir: skillDir });
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
      description,
      version: version || '1.0.0',
      author: author || 'Anonymous',
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

// API: 下载 Skill
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

// API: 删除 Skill
app.delete('/api/skills/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const skillDir = path.join(SKILLS_DIR, id);

    // 删除目录
    await fs.rm(skillDir, { recursive: true, force: true });

    // 更新元数据
    const metadata = await readMetadata();
    const filtered = metadata.filter(s => s.id !== id);
    await writeMetadata(filtered);

    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: 搜索 Skills
app.get('/api/skills/search', async (req, res) => {
  try {
    const { q } = req.query;
    const metadata = await readMetadata();
    
    if (!q) {
      return res.json(metadata);
    }

    const results = metadata.filter(skill => 
      skill.name.toLowerCase().includes(q.toLowerCase()) ||
      skill.description.toLowerCase().includes(q.toLowerCase()) ||
      skill.author.toLowerCase().includes(q.toLowerCase())
    );

    res.json(results);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 所有其他路由返回前端页面
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../client/dist/index.html'));
});

// 启动服务器
async function start() {
  await ensureDirectories();
  app.listen(PORT, () => {
    console.log(`🚀 Skills House 运行在 http://localhost:${PORT}`);
  });
}

start();
