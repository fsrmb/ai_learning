<template>
  <el-container class="layout-container">
    <el-aside width="200px" class="aside">
      <div class="logo">Vue3 管理后台</div>
      <el-menu
        :default-active="activeMenu"
        class="menu"
        mode="vertical"
        background-color="#2f4050"
        text-color="#fff"
        active-text-color="#409EFF"
      >
        <el-menu-item index="home" @click="handleMenuClick('/home')">
          <el-icon><component :is="House" /></el-icon>
          <span>首页</span>
        </el-menu-item>
        <el-menu-item index="users" @click="handleMenuClick('/users')">
          <el-icon><component :is="User" /></el-icon>
          <span>用户管理</span>
        </el-menu-item>
      </el-menu>
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
import { House, User } from '@element-plus/icons-vue'

const router = useRouter()
const route = useRoute()

const menuMap = {
  home: '首页',
  users: '用户管理'
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
    localStorage.removeItem('token')
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
}

.aside {
  background-color: #2f4050;
}

.logo {
  padding: 20px;
  font-size: 18px;
  font-weight: bold;
  color: #fff;
  text-align: center;
  border-bottom: 1px solid #3d4f65;
}

.menu {
  border-right: none;
}

.header {
  background-color: #fff;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
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
}
</style>
