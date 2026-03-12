/**
 * SkillHub Sync Tool - Lightweight Version
 * 只同步元数据，不下载文件
 */

const axios = require('axios');
const fs = require('fs').promises;
const path = require('path');

// SkillHub 配置
const SKILLHUB_INDEX_URL = 'https://skillhub-1251783334.cos.ap-guangzhou.myqcloud.com/install/latest.tar.gz';
const SKILLHUB_COS_TEMPLATE = 'https://skillhub-1388575217.cos.ap-guangzhou.myqcloud.com/skills/{slug}.zip';

// 本地配置
const METADATA_FILE = path.join(__dirname, '../uploads/metadata.json');
const SYNC_STATE_FILE = path.join(__dirname, '../uploads/skillhub-sync-state.json');

/**
 * 获取 SkillHub 索引
 */
async function fetchSkillHubIndex() {
  console.log('📥 正在下载 SkillHub 索引...');
  
  try {
    // 下载 tar.gz
    const response = await axios.get(SKILLHUB_INDEX_URL, {
      responseType: 'arraybuffer',
      timeout: 60000
    });

    // 保存到临时文件
    const tmpFile = path.join(__dirname, '../uploads/skillhub-index.tar.gz');
    await fs.writeFile(tmpFile, response.data);

    // 解压 tar.gz
    const { execSync } = require('child_process');
    const tmpDir = path.join(__dirname, '../uploads/skillhub-index-tmp');
    
    // 创建临时目录
    await fs.mkdir(tmpDir, { recursive: true });
    
    // 解压
    execSync(`tar -xzf "${tmpFile}" -C "${tmpDir}"`, { stdio: 'inherit' });
    
    // 读取 JSON 索引
    const indexPath = path.join(tmpDir, 'cli/skills_index.local.json');
    const indexData = await fs.readFile(indexPath, 'utf-8');
    const index = JSON.parse(indexData);
    
    // 清理临时文件
    execSync(`rm -rf "${tmpDir}" "${tmpFile}"`, { stdio: 'inherit' });
    
    console.log(`✅ 成功获取 ${index.skills.length} 个 Skills`);
    return index;
  } catch (error) {
    console.error('❌ 下载 SkillHub 索引失败:', error.message);
    throw error;
  }
}

/**
 * 获取本地已同步的 Skills 状态
 */
async function getSyncState() {
  try {
    const data = await fs.readFile(SYNC_STATE_FILE, 'utf-8');
    return JSON.parse(data);
  } catch (error) {
    return {
      lastSync: null,
      syncedSkills: {},
      totalSynced: 0
    };
  }
}

/**
 * 保存同步状态
 */
async function saveSyncState(state) {
  await fs.writeFile(SYNC_STATE_FILE, JSON.stringify(state, null, 2));
}

/**
 * 获取本地 metadata
 */
async function getLocalMetadata() {
  try {
    const data = await fs.readFile(METADATA_FILE, 'utf-8');
    return JSON.parse(data);
  } catch (error) {
    return [];
  }
}

/**
 * 保存本地 metadata
 */
async function saveLocalMetadata(metadata) {
  await fs.writeFile(METADATA_FILE, JSON.stringify(metadata, null, 2));
}

/**
 * 检查 Skill 是否需要同步
 */
function needsSync(skillhubSkill, syncState, localMetadata) {
  const slug = skillhubSkill.slug;
  
  // 检查是否已经存在
  const existingSkill = localMetadata.find(s => 
    s.id === slug || 
    s.skillhub?.slug === slug
  );
  
  if (existingSkill) {
    // 已存在，检查是否有更新
    const lastSyncTime = syncState.syncedSkills[slug]?.syncedAt || 0;
    const skillUpdateTime = skillhubSkill.updated_at || 0;
    
    return skillUpdateTime > lastSyncTime;
  }
  
  // 不存在，需要同步
  return true;
}

/**
 * 同步单个 Skill（只保存元数据，不下载文件）
 */
async function syncSkillMetadata(skillhubSkill, userId = 'skillhub-sync') {
  const slug = skillhubSkill.slug;
  const cosUrl = SKILLHUB_COS_TEMPLATE.replace('{slug}', slug);
  
  console.log(`📋 同步元数据: ${skillhubSkill.name} (${slug})`);
  
  try {
    // 创建 metadata（只保存 URL，不下载文件）
    const metadata = {
      id: slug,
      name: skillhubSkill.name,
      description: skillhubSkill.description || '',
      version: skillhubSkill.version || '1.0.0',
      uploadedBy: userId,
      uploadedAt: new Date().toISOString(),
      
      // 存储方式：URL（不下载文件）
      storageType: 'url',
      downloadUrl: cosUrl,
      
      // SkillHub 元数据
      skillhub: {
        slug: slug,
        source: skillhubSkill.source,
        homepage: skillhubSkill.homepage,
        originalZipUrl: skillhubSkill.zip_url,
        stats: skillhubSkill.stats,
        tags: skillhubSkill.tags || [],
        updated_at: skillhubSkill.updated_at
      },
      
      downloadCount: 0
    };
    
    // 更新本地 metadata
    const localMetadata = await getLocalMetadata();
    const existingIndex = localMetadata.findIndex(s => 
      s.id === slug || 
      s.skillhub?.slug === slug
    );
    
    if (existingIndex >= 0) {
      // 更新现有 Skill
      localMetadata[existingIndex] = {
        ...localMetadata[existingIndex],
        ...metadata,
        downloadCount: localMetadata[existingIndex].downloadCount // 保留下载计数
      };
      console.log(`   ✅ 更新成功`);
    } else {
      // 添加新 Skill
      localMetadata.push(metadata);
      console.log(`   ✅ 新增成功`);
    }
    
    await saveLocalMetadata(localMetadata);
    
    return {
      success: true,
      slug: slug,
      name: skillhubSkill.name,
      action: existingIndex >= 0 ? 'updated' : 'added'
    };
    
  } catch (error) {
    console.error(`   ❌ 同步失败: ${error.message}`);
    return {
      success: false,
      slug: slug,
      name: skillhubSkill.name,
      error: error.message
    };
  }
}

/**
 * 增量同步 Skills（只同步元数据）
 */
async function syncSkills(options = {}) {
  const {
    limit = null,
    forceSync = false,
    userId = 'skillhub-sync'
  } = options;
  
  console.log('\n🚀 开始 SkillHub 元数据同步...\n');
  
  // 1. 获取 SkillHub 索引
  const skillhubIndex = await fetchSkillHubIndex();
  
  // 2. 获取同步状态
  const syncState = await getSyncState();
  
  // 3. 获取本地 metadata
  const localMetadata = await getLocalMetadata();
  
  console.log(`\n📊 当前状态:`);
  console.log(`   - SkillHub Skills: ${skillhubIndex.skills.length}`);
  console.log(`   - 本地 Skills: ${localMetadata.length}`);
  console.log(`   - 已同步: ${syncState.totalSynced}`);
  console.log(`   - 上次同步: ${syncState.lastSync || '从未'}\n`);
  
  // 4. 筛选需要同步的 Skills
  let skillsToSync = skillhubIndex.skills;
  
  if (!forceSync) {
    skillsToSync = skillsToSync.filter(skill => 
      needsSync(skill, syncState, localMetadata)
    );
    console.log(`📝 需要同步: ${skillsToSync.length} 个 Skills\n`);
  } else {
    console.log(`⚠️ 强制同步模式: 将重新同步所有 ${skillsToSync.length} 个 Skills\n`);
  }
  
  if (limit && skillsToSync.length > limit) {
    skillsToSync = skillsToSync.slice(0, limit);
    console.log(`⚡ 限制同步数量: ${limit} 个\n`);
  }
  
  if (skillsToSync.length === 0) {
    console.log('✅ 没有需要同步的 Skills');
    return {
      total: 0,
      success: 0,
      failed: 0,
      skipped: skillhubIndex.skills.length
    };
  }
  
  // 5. 开始同步（只同步元数据，不下载文件）
  const results = {
    total: skillsToSync.length,
    success: 0,
    failed: 0,
    details: []
  };
  
  for (let i = 0; i < skillsToSync.length; i++) {
    const skill = skillsToSync[i];
    console.log(`\n[${i + 1}/${skillsToSync.length}]`);
    
    const result = await syncSkillMetadata(skill, userId);
    results.details.push(result);
    
    if (result.success) {
      results.success++;
      
      // 更新同步状态
      syncState.syncedSkills[result.slug] = {
        name: result.name,
        syncedAt: Date.now(),
        action: result.action
      };
    } else {
      results.failed++;
    }
    
    // 每 50 个保存一次状态
    if ((i + 1) % 50 === 0) {
      syncState.totalSynced = Object.keys(syncState.syncedSkills).length;
      syncState.lastSync = new Date().toISOString();
      await saveSyncState(syncState);
      console.log(`\n💾 已保存同步状态 (${i + 1}/${skillsToSync.length})`);
    }
  }
  
  // 6. 保存最终状态
  syncState.totalSynced = Object.keys(syncState.syncedSkills).length;
  syncState.lastSync = new Date().toISOString();
  await saveSyncState(syncState);
  
  // 7. 输出统计
  console.log(`\n\n🎉 同步完成！`);
  console.log(`   ✅ 成功: ${results.success}`);
  console.log(`   ❌ 失败: ${results.failed}`);
  console.log(`   📊 总计: ${results.total}\n`);
  
  return results;
}

module.exports = {
  syncSkills,
  fetchSkillHubIndex,
  getSyncState
};

// CLI 使用
if (require.main === module) {
  const args = process.argv.slice(2);
  const options = {};
  
  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--limit':
        options.limit = parseInt(args[++i]);
        break;
      case '--force':
        options.forceSync = true;
        break;
    }
  }
  
  syncSkills(options)
    .then(results => {
      process.exit(results.failed > 0 ? 1 : 0);
    })
    .catch(error => {
      console.error('Fatal error:', error);
      process.exit(1);
    });
}
