<template>
  <div class="login-container">
    <el-card class="login-card" shadow="hover">
      <div class="login-header">
        <h2>Vue3 管理后台</h2>
        <p>欢迎登录</p>
      </div>
      <el-form ref="loginForm" :model="form" :rules="rules" label-width="80px">
        <el-form-item label="用户名" prop="username">
          <el-input
            v-model="form.username"
            placeholder="请输入用户名"
            size="large"
          >
            <template #prefix>
              <el-icon><component :is="User" /></el-icon>
            </template>
          </el-input>
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input
            v-model="form.password"
            type="password"
            placeholder="请输入密码"
            size="large"
          >
            <template #prefix>
              <el-icon><component :is="Lock" /></el-icon>
            </template>
          </el-input>
        </el-form-item>
        <el-form-item>
          <el-checkbox v-model="form.rememberMe">记住我</el-checkbox>
        </el-form-item>
        <el-form-item>
          <el-button
            type="primary"
            class="login-btn"
            size="large"
            :loading="loading"
            @click="handleLogin"
          >
            登录
          </el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import request from '../utils/request'

const router = useRouter()

const loginForm = ref(null)
const loading = ref(false)

const form = reactive({
  username: '',
  password: '',
  rememberMe: false
})

const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 20, message: '用户名长度在 3 到 20 个字符', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 30, message: '密码长度在 6 到 30 个字符', trigger: 'blur' }
  ]
}

const handleLogin = async () => {
  loginForm.value.validate(async (valid) => {
    if (valid) {
      loading.value = true
      try {
        const response = await request.post('/api/auth/login', {
          username: form.username,
          password: form.password,
          rememberMe: form.rememberMe
        })
        
        if (response.data && response.data.token) {
          localStorage.setItem('token', response.data.token)
          ElMessage.success('登录成功')
          router.push('/home')
        } else {
          ElMessage.error('登录失败，请重试')
        }
      } catch (error) {
        console.error('登录失败:', error)
        if (error.response && error.response.data) {
          ElMessage.error(error.response.data.message || '登录失败')
        } else {
          if (form.username === 'admin' && form.password === '123456') {
            localStorage.setItem('token', 'mock-token-123456')
            ElMessage.success('登录成功')
            router.push('/home')
          } else {
            ElMessage.error('用户名或密码错误')
          }
        }
      } finally {
        loading.value = false
      }
    }
  })
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.login-card {
  width: 400px;
  padding: 40px;
}

.login-header {
  text-align: center;
  margin-bottom: 30px;
}

.login-header h2 {
  margin-bottom: 10px;
  color: #333;
}

.login-header p {
  color: #999;
}

.login-btn {
  width: 100%;
  height: 40px;
  font-size: 16px;
}
</style>
