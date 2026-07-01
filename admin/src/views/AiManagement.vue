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

      <div class="pagination-container">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :total="total"
          :page-sizes="[5, 10, 20, 50]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>
  </div>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import { getUserAiStats } from '@/api/dashboard'

const aiStats = ref([])
const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)

async function fetchData() {
  try {
    const result = await getUserAiStats({ page: currentPage.value, size: pageSize.value })
    aiStats.value = result.records || []
    total.value = result.total || 0
  } catch (error) {
    console.error('获取AI统计数据失败:', error)
    aiStats.value = []
    total.value = 0
  }
}

const handleSizeChange = (val) => {
  pageSize.value = val
  currentPage.value = 1
  fetchData()
}

const handleCurrentChange = (val) => {
  currentPage.value = val
  fetchData()
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

.pagination-container {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
  padding-top: 10px;
  border-top: 1px solid #eee;
}
</style>