// COS 存储配置
module.exports = {
  // COS 基础配置
  SecretId: process.env.COS_SECRET_ID || '',
  SecretKey: process.env.COS_SECRET_KEY || '',
  
  // Bucket 配置
  Bucket: process.env.COS_BUCKET || 'skills-house-1234567890',
  Region: process.env.COS_REGION || 'ap-guangzhou',
  
  // 存储路径前缀
  Prefix: 'skills/',
  
  // CDN 域名（可选）
  CDN: process.env.COS_CDN || '',
  
  // 是否启用 COS（如果未配置，回退到本地存储）
  enabled: !!process.env.COS_SECRET_ID && !!process.env.COS_SECRET_KEY,
  
  // 上传配置
  uploadConfig: {
    maxFileSize: 100 * 1024 * 1024, // 100MB
    allowedTypes: ['.zip', '.tar.gz', '.tgz']
  }
};
