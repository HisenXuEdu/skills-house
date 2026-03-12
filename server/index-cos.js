const express = require('express');
const multer = require('multer');
const archiver = require('archiver');
const extractZip = require('extract-zip');
const cors = require('cors');
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fs = require('fs').promises;
const fsSync = require('fs');
const path = require('path');

// COS 存储支持
const cosStorage = require('./cos-storage');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'skills-house-secret-key-change-in-production';

// 打印 COS 状态
console.log('🚀 启动 Skills House...');
console.log('📦 存储模式:', cosStorage.enabled ? 'COS 对象存储' : '本地文件系统');

// ... 保持其余代码不变，只修改上传和下载部分

module.exports = app;
