import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true
      }
    }
  },
  build: {
    // 兼容性配置
    target: 'es2015',
    // 禁用某些优化以兼容旧版 Node
    minify: 'terser'
  }
})
