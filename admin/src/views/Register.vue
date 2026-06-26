<template>
  <div class="login-container">
    <div class="bg-decoration">
      <div class="bg-circle bg-circle-1"></div>
      <div class="bg-circle bg-circle-2"></div>
      <div class="bg-circle bg-circle-3"></div>
    </div>
    
    <div class="login-wrapper">
      <div class="login-left">
        <div class="brand-content">
          <div class="brand-logo">
            <div class="logo-icon">
              <span class="logo-text">智</span>
            </div>
          </div>
          <h1 class="brand-title">智能管理平台</h1>
          <p class="brand-subtitle">高效协作，智能管理</p>
          
          <div class="feature-grid">
            <div class="feature-card">
              <div class="feature-icon security"></div>
              <span class="feature-label">安全可靠</span>
            </div>
            <div class="feature-card">
              <div class="feature-icon speed"></div>
              <span class="feature-label">快速响应</span>
            </div>
            <div class="feature-card">
              <div class="feature-icon team"></div>
              <span class="feature-label">团队协作</span>
            </div>
          </div>
        </div>
      </div>
      
      <div class="login-right">
        <div class="login-card">
          <div class="card-header">
            <h2 class="card-title">创建账号</h2>
            <p class="card-desc">注册后即可使用完整功能</p>
          </div>
          
          <el-form 
            ref="registerFormRef" 
            :model="form" 
            :rules="rules" 
            label-position="top"
            class="login-form"
          >
            <el-form-item prop="username" class="form-item">
              <el-input
                v-model="form.username"
                placeholder="请输入用户名"
                size="large"
                class="form-input"
              >
                <template #prefix>
                  <div class="input-icon-wrapper">
                    <span class="input-icon">👤</span>
                  </div>
                </template>
              </el-input>
            </el-form-item>
            
            <el-form-item prop="password" class="form-item">
              <el-input
                v-model="form.password"
                type="password"
                placeholder="请输入密码（至少6位）"
                size="large"
                class="form-input"
                show-password
              >
                <template #prefix>
                  <div class="input-icon-wrapper">
                    <span class="input-icon">🔒</span>
                  </div>
                </template>
              </el-input>
            </el-form-item>
            
            <el-form-item prop="confirmPassword" class="form-item">
              <el-input
                v-model="form.confirmPassword"
                type="password"
                placeholder="请确认密码"
                size="large"
                class="form-input"
                show-password
              >
                <template #prefix>
                  <div class="input-icon-wrapper">
                    <span class="input-icon">🔑</span>
                  </div>
                </template>
              </el-input>
            </el-form-item>
            
            <el-form-item prop="email" class="form-item">
              <el-input
                v-model="form.email"
                placeholder="请输入邮箱（选填）"
                size="large"
                class="form-input"
              >
                <template #prefix>
                  <div class="input-icon-wrapper">
                    <span class="input-icon">📧</span>
                  </div>
                </template>
              </el-input>
            </el-form-item>
            
            <el-form-item class="form-item-btn">
              <el-button
                type="primary"
                class="login-btn"
                size="large"
                :loading="loading"
                @click="handleRegister"
              >
                <span v-if="!loading">注 册</span>
              </el-button>
            </el-form-item>
          </el-form>
          
          <div class="register-hint">
            <span class="hint-text">已有账号？</span>
            <span class="register-link" @click="goToLogin">立即登录</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElForm, ElFormItem, ElInput, ElButton } from 'element-plus'
import { useUserStore } from '../stores/user'

const router = useRouter()
const userStore = useUserStore()
const registerFormRef = ref(null)
const loading = ref(false)

const form = reactive({
  username: '',
  password: '',
  confirmPassword: '',
  email: ''
})

const rules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 20, message: '用户名长度在 3 到 20 个字符', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 30, message: '密码长度在 6 到 30 个字符', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认密码', trigger: 'blur' },
    {
      validator: (rule, value, callback) => {
        if (value !== form.password) {
          callback(new Error('两次输入的密码不一致'))
        } else {
          callback()
        }
      },
      trigger: 'blur'
    }
  ],
  email: [
    { type: 'email', message: '邮箱格式不正确', trigger: 'blur' }
  ]
}

const handleRegister = async () => {
  if (!registerFormRef.value) return
  
  await registerFormRef.value.validate(async (valid) => {
    if (valid) {
      loading.value = true
      
      try {
        await userStore.register(form)
        ElMessage.success('注册成功，请登录')
        router.push('/login')
        
      } catch (error) {
        ElMessage.error('注册失败，请重试')
        
      } finally {
        loading.value = false
      }
    }
  })
}

const goToLogin = () => {
  router.push('/login')
}
</script>

<style scoped>
.login-container {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 40px 20px;
  position: relative;
  overflow: hidden;
}

.bg-decoration {
  position: absolute;
  width: 100%;
  height: 100%;
  top: 0;
  left: 0;
  pointer-events: none;
  overflow: hidden;
}

.bg-circle {
  position: absolute;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  animation: float 6s ease-in-out infinite;
}

.bg-circle-1 {
  width: 300px;
  height: 300px;
  top: -100px;
  right: -100px;
  animation-delay: 0s;
}

.bg-circle-2 {
  width: 200px;
  height: 200px;
  bottom: -50px;
  left: -50px;
  animation-delay: 2s;
}

.bg-circle-3 {
  width: 150px;
  height: 150px;
  top: 50%;
  right: 20%;
  animation-delay: 4s;
}

@keyframes float {
  0%, 100% {
    transform: translateY(0) rotate(0deg);
  }
  50% {
    transform: translateY(-20px) rotate(10deg);
  }
}

.login-wrapper {
  display: flex;
  width: 950px;
  max-width: 95%;
  background: #ffffff;
  border-radius: 24px;
  box-shadow: 0 25px 70px rgba(0, 0, 0, 0.15);
  overflow: hidden;
  position: relative;
  z-index: 1;
  animation: slideUp 0.6s ease-out;
}

@keyframes slideUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.login-left {
  width: 45%;
  background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
  padding: 50px 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
}

.login-left::before {
  content: '';
  position: absolute;
  width: 200%;
  height: 200%;
  background: radial-gradient(circle, rgba(102, 126, 234, 0.1) 0%, transparent 70%);
  top: -50%;
  left: -50%;
  animation: rotate 20s linear infinite;
}

@keyframes rotate {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}

.brand-content {
  position: relative;
  z-index: 1;
  text-align: center;
  color: #ffffff;
}

.brand-logo {
  margin-bottom: 24px;
}

.logo-icon {
  width: 80px;
  height: 80px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 20px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 10px 30px rgba(102, 126, 234, 0.4);
  animation: pulse 2s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}

.logo-text {
  font-size: 32px;
  font-weight: bold;
  color: #ffffff;
}

.brand-title {
  font-size: 28px;
  font-weight: 600;
  margin-bottom: 8px;
  background: linear-gradient(135deg, #ffffff 0%, #e0e0e0 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.brand-subtitle {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.7);
  margin-bottom: 40px;
}

.feature-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}

.feature-card {
  padding: 16px 8px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  transition: all 0.3s ease;
}

.feature-card:hover {
  background: rgba(255, 255, 255, 0.1);
  transform: translateY(-3px);
}

.feature-icon {
  width: 32px;
  height: 32px;
  margin: 0 auto 8px;
  background-size: contain;
  background-repeat: no-repeat;
  background-position: center;
}

.feature-icon.security {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='32' height='32' viewBox='0 0 24 24' fill='none' stroke='%23667eea' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z'%3E%3C/path%3E%3C/svg%3E");
}

.feature-icon.speed {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='32' height='32' viewBox='0 0 24 24' fill='none' stroke='%2367eea' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolygon points='13 2 3 14 12 14 11 22 21 10 12 10 13 2'%3E%3C/polygon%3E%3C/svg%3E");
}

.feature-icon.team {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='32' height='32' viewBox='0 0 24 24' fill='none' stroke='%2367eea' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2'%3E%3C/path%3E%3Ccircle cx='9' cy='7' r='4'%3E%3C/circle%3E%3Cpath d='M23 21v-2a4 4 0 0 0-3-3.87'%3E%3C/path%3E%3Cpath d='M16 3.13a4 4 0 0 1 0 7.75'%3E%3C/path%3E%3C/svg%3E");
}

.feature-label {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.8);
}

.login-right {
  width: 55%;
  padding: 50px 60px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.login-card {
  max-width: 360px;
  margin: 0 auto;
  width: 100%;
}

.card-header {
  text-align: center;
  margin-bottom: 32px;
}

.card-title {
  font-size: 28px;
  font-weight: 600;
  color: #1a1a2e;
  margin-bottom: 8px;
}

.card-desc {
  font-size: 14px;
  color: #8898aa;
}

.login-form {
  margin-bottom: 16px;
}

.form-item {
  margin-bottom: 20px;
}

.form-input {
  height: 48px;
  border-radius: 12px;
  font-size: 15px;
  transition: all 0.3s ease;
}

.form-input:hover {
  border-color: #667eea;
}

.form-input:focus {
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.input-icon-wrapper {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
}

.input-icon {
  font-size: 16px;
}

.form-item-btn {
  margin-bottom: 16px;
}

.login-btn {
  width: 100%;
  height: 48px;
  font-size: 16px;
  font-weight: 500;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 12px;
  color: #ffffff;
  transition: all 0.3s ease;
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
}

.login-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
}

.login-btn:active:not(:disabled) {
  transform: translateY(0);
}

.register-hint {
  text-align: center;
  font-size: 14px;
  color: #8898aa;
  margin-top: 24px;
}

.hint-text {
  margin-right: 4px;
}

.register-link {
  color: #667eea;
  cursor: pointer;
  font-weight: 500;
  transition: color 0.2s;
}

.register-link:hover {
  color: #764ba2;
  text-decoration: underline;
}

@media (max-width: 768px) {
  .login-wrapper {
    flex-direction: column;
    width: 100%;
  }
  
  .login-left {
    width: 100%;
    padding: 40px 30px;
  }
  
  .login-right {
    width: 100%;
    padding: 40px 30px;
  }
  
  .feature-grid {
    gap: 12px;
  }
  
  .feature-card {
    padding: 12px 6px;
  }
}
</style>