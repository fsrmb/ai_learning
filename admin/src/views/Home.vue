<template>
  <div class="home-container">
    <el-card class="welcome-card">
      <div class="welcome-content">
        <h2>欢迎来到 Vue3 管理后台</h2>
        <p>这是一个基于 Vue3 + Element Plus 的现代化管理后台系统</p>
        <div class="features">
          <el-card class="feature-card">
            <el-icon class="icon"><component :is="User" /></el-icon>
            <span>用户管理</span>
          </el-card>
          <el-card class="feature-card">
            <el-icon class="icon"><component :is="Setting" /></el-icon>
            <span>系统设置</span>
          </el-card>
          <el-card class="feature-card">
            <el-icon class="icon"><component :is="PieChart" /></el-icon>
            <span>数据统计</span>
          </el-card>
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { User, Setting, PieChart } from '@element-plus/icons-vue'
</script>

<style scoped>
.home-container {
  min-height: 100%;
}

.welcome-card {
  margin-bottom: 20px;
}

.welcome-content {
  padding: 20px;
}

.welcome-content h2 {
  margin-bottom: 10px;
  color: #333;
}

.welcome-content p {
  color: #999;
  margin-bottom: 30px;
}

.features {
  display: flex;
  gap: 20px;
}

.feature-card {
  flex: 1;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s;
}

.feature-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 10px 20px rgba(0, 0, 0, 0.1);
}

.icon {
  font-size: 48px;
  color: #409EFF;
  margin-bottom: 15px;
}

.feature-card span {
  font-size: 16px;
  color: #666;
}
</style>
