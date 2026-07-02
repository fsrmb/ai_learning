<template>
  <div class="assessment-page">
    <el-card class="box-card">
      <template #header>
        <div class="card-header">
          <span>技能评估管理</span>
          <div>
            <el-select v-model="filterType" placeholder="筛选类型" style="width: 140px; margin-right: 8px">
              <el-option label="全部" value="all" />
              <el-option label="通过" value="passed" />
              <el-option label="未通过" value="failed" />
            </el-select>
            <el-input v-model="searchText" placeholder="搜索用户或技能" style="width: 200px" @keyup.enter="loadAssessments" />
          </div>
        </div>
      </template>
      <div v-loading="loading">
        <el-table :data="assessmentList" border style="width: 100%">
          <el-table-column prop="userName" label="用户名" min-width="100" />
          <el-table-column prop="treeName" label="技能树" min-width="120" />
          <el-table-column prop="nodeName" label="技能节点" min-width="120" />
          <el-table-column prop="difficultyText" label="难度" min-width="80" />
          <el-table-column prop="totalScore" label="得分" min-width="80">
            <template #default="scope">
              <span :class="scope.row.passed === 1 ? 'text-green' : 'text-red'">{{ scope.row.totalScore }}</span>
            </template>
          </el-table-column>
          <el-table-column prop="passedText" label="结果" min-width="80">
            <template #default="scope">
              <el-tag :type="scope.row.passed === 1 ? 'success' : 'danger'">{{ scope.row.passedText }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="questionCount" label="题目数" min-width="80" />
          <el-table-column prop="correctCount" label="正确数" min-width="80" />
          <el-table-column prop="durationSeconds" label="耗时(秒)" min-width="100" />
          <el-table-column prop="assessmentTime" label="评估时间" min-width="160" />
        </el-table>
      </div>
      <div v-if="assessmentList.length === 0 && !loading" class="empty-state">
        <el-empty description="暂无评估记录" />
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { getAllAssessments } from '@/api/skillAssessment'

const loading = ref(false)
const assessmentList = ref([])
const filterType = ref('all')
const searchText = ref('')

async function loadAssessments() {
  loading.value = true
  try {
    let result = await getAllAssessments()
    
    if (filterType.value === 'passed') {
      result = result.filter(item => item.passed === 1)
    } else if (filterType.value === 'failed') {
      result = result.filter(item => item.passed === 0)
    }
    
    if (searchText.value) {
      const text = searchText.value.toLowerCase()
      result = result.filter(item => 
        (item.userName && item.userName.toLowerCase().includes(text)) ||
        (item.nodeName && item.nodeName.toLowerCase().includes(text)) ||
        (item.treeName && item.treeName.toLowerCase().includes(text))
      )
    }
    
    assessmentList.value = result
  } catch (error) {
    console.error('获取评估记录失败:', error)
    assessmentList.value = []
    ElMessage.error('获取评估记录失败')
  } finally {
    loading.value = false
  }
}

onMounted(loadAssessments)
</script>

<style scoped>
.assessment-page {
  padding: 20px;
}

.box-card {
  margin-top: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.text-green {
  color: #67c23a;
  font-weight: bold;
}

.text-red {
  color: #f56c6c;
  font-weight: bold;
}

.empty-state {
  padding: 40px;
}
</style>