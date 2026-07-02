<template>
  <el-container class="layout-container">
    <el-aside :width="isCollapse ? '64px' : '200px'" class="aside">
      <div class="logo">
        <span v-show="!isCollapse">AI 伴学平台</span>
        <span v-show="isCollapse" class="logo-icon">V</span>
      </div>
      <el-menu
        :default-active="activeMenu"
        class="menu"
        mode="vertical"
        background-color="#2f4050"
        text-color="#fff"
        active-text-color="#409EFF"
        :collapse="isCollapse"
      >
        <el-menu-item index="home" @click="handleMenuClick('/home')">
          <el-icon><component :is="House" /></el-icon>
          <span>首页</span>
        </el-menu-item>
        <el-menu-item index="users" @click="handleMenuClick('/users')">
          <el-icon><component :is="User" /></el-icon>
          <span>用户管理</span>
        </el-menu-item>
        <el-menu-item index="learning" @click="handleMenuClick('/learning')">
          <el-icon><component :is="Document" /></el-icon>
          <span>学习记录</span>
        </el-menu-item>
        <el-menu-item index="skilltree" @click="handleMenuClick('/skilltree')">
          <el-icon><component :is="Folder" /></el-icon>
          <span>技能树管理</span>
        </el-menu-item>
        <el-menu-item index="skillassessment" @click="handleMenuClick('/skill-assessment')">
          <el-icon><component :is="Star" /></el-icon>
          <span>技能评估</span>
        </el-menu-item>
        <el-menu-item index="aimanagement" @click="handleMenuClick('/ai-management')">
          <el-icon><component :is="Cpu" /></el-icon>
          <span>AI管理</span>
        </el-menu-item>
      </el-menu>
      <el-button
        type="text"
        class="collapse-btn"
        @click="toggleCollapse"
        :title="isCollapse ? '展开菜单' : '收起菜单'"
      >
        <el-icon><component :is="isCollapse ? ArrowRight : ArrowLeft" /></el-icon>
      </el-button>
    </el-aside>
    <el-container>
      <el-header class="header">
        <span class="title">{{ currentTitle }}</span>
        <el-button @click="handleLogout" type="text" class="logout-btn">
          退出登录
        </el-button>
      </el-header>
      <el-main class="main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { House, User, ArrowLeft, ArrowRight, Document, Folder, Cpu, Star } from '@element-plus/icons-vue'
import { useUserStore } from '../stores/user'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

const isCollapse = ref(false)

const toggleCollapse = () => {
  isCollapse.value = !isCollapse.value
}

const menuMap = {
  home: '首页',
  users: '用户管理',
  learning: '学习记录',
  skilltree: '技能树管理',
  skillassessment: '技能评估',
  aimanagement: 'AI管理'
}

const activeMenu = computed(() => {
  return route.name.toLowerCase()
})

const currentTitle = computed(() => {
  return menuMap[activeMenu.value] || '首页'
})

const handleMenuClick = (path) => {
  router.push(path)
}

const handleLogout = async () => {
  try {
    await ElMessageBox.confirm(
      '确定要退出登录吗？',
      '提示',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    userStore.logout()
    ElMessage.success('退出成功')
    router.push('/login')
  } catch (error) {
    ElMessage.info('已取消退出')
  }
}
</script>

<style scoped>
.layout-container {
  height: 100vh;
  display: flex;
}

.aside {
  background-color: #2f4050;
  overflow: hidden;
  transition: width 0.3s ease, min-width 0.3s ease;
  flex-shrink: 0;
  position: relative;
}

.logo {
  padding: 20px;
  font-size: 18px;
  font-weight: bold;
  color: #fff;
  text-align: center;
  border-bottom: 1px solid #3d4f65;
  overflow: hidden;
  white-space: nowrap;
  transition: opacity 0.2s ease;
}

.logo-icon {
  display: inline-block;
  width: 32px;
  height: 32px;
  line-height: 32px;
  font-size: 20px;
  background-color: #409EFF;
  border-radius: 8px;
}

.menu {
  border-right: none;
  overflow: hidden;
}

.collapse-btn {
  position: absolute;
  bottom: 10px;
  right: 10px;
  width: 36px;
  height: 36px;
  display: flex;
  justify-content: center;
  align-items: center;
  color: #a0aec0;
  font-size: 16px;
  padding: 0;
  margin: 0;
  background-color: rgba(255, 255, 255, 0.05);
  border-radius: 6px;
  transition: all 0.3s ease;
}

.collapse-btn:hover {
  background-color: rgba(255, 255, 255, 0.1);
  color: #fff;
}

.header {
  background-color: #fff;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: width 0.3s ease;
}

.title {
  font-size: 18px;
  font-weight: bold;
  color: #333;
}

.logout-btn {
  color: #999;
}

.logout-btn:hover {
  color: #409EFF;
}

.main {
  padding: 20px;
  background-color: #f5f5f5;
  transition: width 0.3s ease;
}
</style>
