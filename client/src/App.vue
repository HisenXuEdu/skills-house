<template>
  <div id="app">
    <!-- 头部 -->
    <header class="header">
      <div class="container">
        <h1>🏠 Skills House</h1>
        <p>OpenClaw Skills 管理平台 - 上传、浏览和分享你的 Skills</p>
      </div>
    </header>

    <!-- 主内容 -->
    <main class="container">
      <!-- 搜索和上传栏 -->
      <div class="action-bar">
        <div class="search-box">
          <input 
            v-model="searchQuery" 
            @input="searchSkills"
            type="text" 
            placeholder="🔍 搜索 Skills..." 
            class="search-input"
          />
        </div>
        <button @click="showUploadModal = true" class="btn btn-primary">
          ⬆️ 上传 Skill
        </button>
      </div>

      <!-- Skills 列表 -->
      <div class="skills-grid">
        <div v-if="loading" class="loading">加载中...</div>
        <div v-else-if="skills.length === 0" class="empty">
          <p>📦 还没有 Skills，快来上传第一个吧！</p>
        </div>
        <div v-else class="skill-card" v-for="skill in skills" :key="skill.id">
          <div class="skill-header">
            <h3>{{ skill.name }}</h3>
            <span class="version">v{{ skill.version }}</span>
          </div>
          <p class="description">{{ skill.description }}</p>
          <div class="skill-meta">
            <span>👤 {{ skill.author }}</span>
            <span>📥 {{ skill.downloadCount }} 次下载</span>
          </div>
          <div class="skill-footer">
            <small>{{ formatDate(skill.uploadedAt) }}</small>
            <div class="actions">
              <button @click="downloadSkill(skill.id)" class="btn btn-sm">下载</button>
              <button @click="deleteSkill(skill.id)" class="btn btn-sm btn-danger">删除</button>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- 上传模态框 -->
    <div v-if="showUploadModal" class="modal" @click.self="showUploadModal = false">
      <div class="modal-content">
        <div class="modal-header">
          <h2>⬆️ 上传 Skill</h2>
          <button @click="showUploadModal = false" class="close-btn">✕</button>
        </div>
        <form @submit.prevent="uploadSkill" class="upload-form">
          <div class="form-group">
            <label>Skill 名称 *</label>
            <input v-model="uploadForm.name" type="text" required placeholder="例如: my-awesome-skill" />
          </div>
          <div class="form-group">
            <label>描述 *</label>
            <textarea v-model="uploadForm.description" required placeholder="简要描述这个 Skill 的功能..." rows="3"></textarea>
          </div>
          <div class="form-group">
            <label>版本</label>
            <input v-model="uploadForm.version" type="text" placeholder="例如: 1.0.0" />
          </div>
          <div class="form-group">
            <label>作者</label>
            <input v-model="uploadForm.author" type="text" placeholder="你的名字" />
          </div>
          <div class="form-group">
            <label>文件 * (支持 .zip 或单文件)</label>
            <input @change="handleFileSelect" type="file" required />
          </div>
          <div class="form-actions">
            <button type="button" @click="showUploadModal = false" class="btn">取消</button>
            <button type="submit" class="btn btn-primary" :disabled="uploading">
              {{ uploading ? '上传中...' : '上传' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  name: 'App',
  data() {
    return {
      skills: [],
      searchQuery: '',
      loading: false,
      showUploadModal: false,
      uploading: false,
      uploadForm: {
        name: '',
        description: '',
        version: '1.0.0',
        author: '',
        file: null
      }
    };
  },
  mounted() {
    this.loadSkills();
  },
  methods: {
    async loadSkills() {
      this.loading = true;
      try {
        const response = await axios.get('/api/skills');
        this.skills = response.data;
      } catch (error) {
        alert('加载失败: ' + error.message);
      } finally {
        this.loading = false;
      }
    },
    async searchSkills() {
      this.loading = true;
      try {
        const response = await axios.get('/api/skills/search', {
          params: { q: this.searchQuery }
        });
        this.skills = response.data;
      } catch (error) {
        alert('搜索失败: ' + error.message);
      } finally {
        this.loading = false;
      }
    },
    handleFileSelect(event) {
      this.uploadForm.file = event.target.files[0];
    },
    async uploadSkill() {
      if (!this.uploadForm.file) {
        alert('请选择文件');
        return;
      }

      this.uploading = true;
      const formData = new FormData();
      formData.append('name', this.uploadForm.name);
      formData.append('description', this.uploadForm.description);
      formData.append('version', this.uploadForm.version);
      formData.append('author', this.uploadForm.author);
      formData.append('file', this.uploadForm.file);

      try {
        await axios.post('/api/skills/upload', formData, {
          headers: { 'Content-Type': 'multipart/form-data' }
        });
        alert('✅ 上传成功！');
        this.showUploadModal = false;
        this.resetUploadForm();
        this.loadSkills();
      } catch (error) {
        alert('上传失败: ' + error.message);
      } finally {
        this.uploading = false;
      }
    },
    async downloadSkill(id) {
      try {
        const response = await axios.get(`/api/skills/${id}/download`, {
          responseType: 'blob'
        });
        const url = window.URL.createObjectURL(new Blob([response.data]));
        const link = document.createElement('a');
        link.href = url;
        link.setAttribute('download', `${id}.zip`);
        document.body.appendChild(link);
        link.click();
        link.remove();
        this.loadSkills(); // 刷新下载计数
      } catch (error) {
        alert('下载失败: ' + error.message);
      }
    },
    async deleteSkill(id) {
      if (!confirm('确定要删除这个 Skill 吗？')) return;
      
      try {
        await axios.delete(`/api/skills/${id}`);
        alert('✅ 删除成功！');
        this.loadSkills();
      } catch (error) {
        alert('删除失败: ' + error.message);
      }
    },
    resetUploadForm() {
      this.uploadForm = {
        name: '',
        description: '',
        version: '1.0.0',
        author: '',
        file: null
      };
    },
    formatDate(dateString) {
      const date = new Date(dateString);
      return date.toLocaleString('zh-CN');
    }
  }
};
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
}

#app {
  min-height: 100vh;
  padding-bottom: 50px;
}

.header {
  background: rgba(255, 255, 255, 0.95);
  padding: 30px 0;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  margin-bottom: 30px;
}

.header h1 {
  font-size: 2.5rem;
  color: #667eea;
  margin-bottom: 10px;
}

.header p {
  color: #666;
  font-size: 1.1rem;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
}

.action-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 30px;
  gap: 20px;
}

.search-box {
  flex: 1;
  max-width: 500px;
}

.search-input {
  width: 100%;
  padding: 12px 20px;
  border: none;
  border-radius: 25px;
  font-size: 1rem;
  background: white;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.btn {
  padding: 12px 24px;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.3s;
  background: white;
  color: #667eea;
  font-weight: 600;
}

.btn-primary {
  background: #667eea;
  color: white;
}

.btn-primary:hover {
  background: #5568d3;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
}

.btn-sm {
  padding: 6px 12px;
  font-size: 0.9rem;
}

.btn-danger {
  background: #e74c3c;
  color: white;
}

.btn-danger:hover {
  background: #c0392b;
}

.skills-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 20px;
}

.skill-card {
  background: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
  transition: transform 0.3s, box-shadow 0.3s;
}

.skill-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
}

.skill-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.skill-header h3 {
  color: #333;
  font-size: 1.3rem;
}

.version {
  background: #667eea;
  color: white;
  padding: 4px 10px;
  border-radius: 12px;
  font-size: 0.85rem;
}

.description {
  color: #666;
  margin-bottom: 15px;
  line-height: 1.5;
}

.skill-meta {
  display: flex;
  justify-content: space-between;
  color: #999;
  font-size: 0.9rem;
  margin-bottom: 15px;
  padding-bottom: 15px;
  border-bottom: 1px solid #eee;
}

.skill-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.skill-footer small {
  color: #999;
}

.actions {
  display: flex;
  gap: 8px;
}

.loading, .empty {
  grid-column: 1 / -1;
  text-align: center;
  padding: 60px 20px;
  color: white;
  font-size: 1.2rem;
}

.modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  border-radius: 12px;
  width: 90%;
  max-width: 600px;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #eee;
}

.modal-header h2 {
  color: #333;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #999;
}

.upload-form {
  padding: 20px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  color: #333;
  font-weight: 600;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 1rem;
  font-family: inherit;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #667eea;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  margin-top: 20px;
}
</style>
