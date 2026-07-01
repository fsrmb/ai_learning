<template>
  <div class="ai-management">
    <el-card shadow="hover">
      <template #header>
        <div class="card-header">
          <span>AI调用统计</span>
        </div>
      </template>

      <el-table :data="aiStats" stripe>
        <el-table-column prop="userId" label="用户ID" width="80" />
        <el-table-column prop="username" label="用户名" />
        <el-table-column prop="nickname" label="昵称" />
        <el-table-column prop="chatCount" label="AI调用次数" width="120">
          <template #default="{ row }">
            <span class="chat-count">{{ row.chatCount }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="totalTokens" label="累计Token" width="120">
          <template #default="{ row }">
            <span>{{ row.totalTokens || 0 }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="totalDurationMs" label="累计耗时(ms)" width="140">
          <template #default="{ row }">
            <span>{{ row.totalDurationMs || 0 }}</span>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import { getUserAiStats } from '@/api/dashboard'

const aiStats = ref([])

async function fetchData() {
  try {
    aiStats.value = await getUserAiStats()
  } catch (error) {
    console.error('获取AI统计数据失败:', error)
    aiStats.value = []
  }
}

onMounted(fetchData)
</script>

<style scoped>
.ai-management {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.chat-count {
  color: #409EFF;
  font-weight: bold;
}
</style>