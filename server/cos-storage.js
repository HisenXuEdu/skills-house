const COS = require('cos-nodejs-sdk-v5');
const fs = require('fs');
const path = require('path');
const cosConfig = require('./cos-config');

class COSStorage {
  constructor() {
    if (!cosConfig.enabled) {
      console.warn('⚠️  COS 未配置，将使用本地存储');
      this.enabled = false;
      return;
    }

    this.enabled = true;
    this.cos = new COS({
      SecretId: cosConfig.SecretId,
      SecretKey: cosConfig.SecretKey
    });
    this.bucket = cosConfig.Bucket;
    this.region = cosConfig.Region;
    this.prefix = cosConfig.Prefix;
    this.cdn = cosConfig.CDN;

    console.log('✅ COS 存储已启用:', {
      bucket: this.bucket,
      region: this.region,
      cdn: this.cdn || '未配置'
    });
  }

  /**
   * 上传文件到 COS
   * @param {String} localPath - 本地文件路径
   * @param {String} remotePath - COS 远程路径（相对于 prefix）
   * @returns {Promise<Object>} 上传结果
   */
  async uploadFile(localPath, remotePath) {
    if (!this.enabled) {
      throw new Error('COS 未启用');
    }

    const key = path.join(this.prefix, remotePath).replace(/\\/g, '/');
    
    return new Promise((resolve, reject) => {
      this.cos.uploadFile({
        Bucket: this.bucket,
        Region: this.region,
        Key: key,
        FilePath: localPath,
        onProgress: (progressData) => {
          // console.log('上传进度:', Math.round(progressData.percent * 100) + '%');
        }
      }, (err, data) => {
        if (err) {
          console.error('COS 上传失败:', err);
          reject(err);
        } else {
          const url = this.cdn 
            ? `${this.cdn}/${key}`
            : `https://${data.Location}`;
          
          resolve({
            success: true,
            url: url,
            location: data.Location,
            key: key
          });
        }
      });
    });
  }

  /**
   * 上传目录到 COS（压缩后上传）
   * @param {String} localDir - 本地目录路径
   * @param {String} remotePath - COS 远程路径
   * @returns {Promise<Object>}
   */
  async uploadDirectory(localDir, remotePath) {
    if (!this.enabled) {
      throw new Error('COS 未启用');
    }

    // 压缩目录
    const archiver = require('archiver');
    const tempZip = path.join(require('os').tmpdir(), `${Date.now()}.zip`);
    
    await new Promise((resolve, reject) => {
      const output = fs.createWriteStream(tempZip);
      const archive = archiver('zip', { zlib: { level: 9 } });

      output.on('close', resolve);
      archive.on('error', reject);

      archive.pipe(output);
      archive.directory(localDir, false);
      archive.finalize();
    });

    // 上传压缩包
    const result = await this.uploadFile(tempZip, remotePath);

    // 删除临时文件
    fs.unlinkSync(tempZip);

    return result;
  }

  /**
   * 下载文件从 COS
   * @param {String} remotePath - COS 远程路径
   * @param {String} localPath - 本地保存路径
   * @returns {Promise<void>}
   */
  async downloadFile(remotePath, localPath) {
    if (!this.enabled) {
      throw new Error('COS 未启用');
    }

    const key = path.join(this.prefix, remotePath).replace(/\\/g, '/');

    return new Promise((resolve, reject) => {
      this.cos.getObject({
        Bucket: this.bucket,
        Region: this.region,
        Key: key
      }, (err, data) => {
        if (err) {
          reject(err);
        } else {
          fs.writeFileSync(localPath, data.Body);
          resolve();
        }
      });
    });
  }

  /**
   * 获取文件下载 URL
   * @param {String} remotePath - COS 远程路径
   * @param {Number} expires - 过期时间（秒），默认 1 小时
   * @returns {Promise<String>} 签名 URL
   */
  async getDownloadUrl(remotePath, expires = 3600) {
    if (!this.enabled) {
      throw new Error('COS 未启用');
    }

    const key = path.join(this.prefix, remotePath).replace(/\\/g, '/');

    return new Promise((resolve, reject) => {
      this.cos.getObjectUrl({
        Bucket: this.bucket,
        Region: this.region,
        Key: key,
        Sign: true,
        Expires: expires
      }, (err, data) => {
        if (err) {
          reject(err);
        } else {
          resolve(data.Url);
        }
      });
    });
  }

  /**
   * 删除文件
   * @param {String} remotePath - COS 远程路径
   * @returns {Promise<void>}
   */
  async deleteFile(remotePath) {
    if (!this.enabled) {
      throw new Error('COS 未启用');
    }

    const key = path.join(this.prefix, remotePath).replace(/\\/g, '/');

    return new Promise((resolve, reject) => {
      this.cos.deleteObject({
        Bucket: this.bucket,
        Region: this.region,
        Key: key
      }, (err, data) => {
        if (err) {
          reject(err);
        } else {
          resolve(data);
        }
      });
    });
  }

  /**
   * 列出文件
   * @param {String} prefix - 前缀
   * @returns {Promise<Array>}
   */
  async listFiles(prefix = '') {
    if (!this.enabled) {
      throw new Error('COS 未启用');
    }

    const fullPrefix = path.join(this.prefix, prefix).replace(/\\/g, '/');

    return new Promise((resolve, reject) => {
      this.cos.getBucket({
        Bucket: this.bucket,
        Region: this.region,
        Prefix: fullPrefix
      }, (err, data) => {
        if (err) {
          reject(err);
        } else {
          resolve(data.Contents || []);
        }
      });
    });
  }

  /**
   * 检查文件是否存在
   * @param {String} remotePath - COS 远程路径
   * @returns {Promise<Boolean>}
   */
  async fileExists(remotePath) {
    if (!this.enabled) {
      return false;
    }

    const key = path.join(this.prefix, remotePath).replace(/\\/g, '/');

    return new Promise((resolve) => {
      this.cos.headObject({
        Bucket: this.bucket,
        Region: this.region,
        Key: key
      }, (err, data) => {
        resolve(!err);
      });
    });
  }
}

// 导出单例
module.exports = new COSStorage();
