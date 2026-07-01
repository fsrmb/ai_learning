<template>
  <div class="learning-container">
    <el-card class="page-card">
      <div class="search-bar">
        <el-form :model="searchForm" inline>
          <el-form-item label="用户名">
            <el-input
              v-model="searchForm.username"
              placeholder="请输入用户名"
              style="width: 200px;"
            />
          </el-form-item>
          <el-form-item label="课程类型">
            <el-select
              v-model="searchForm.courseType"
              placeholder="请选择课程类型"
              style="width: 150px;"
            >
              <el-option label="全部" value="" />
              <el-option label="编程" value="PROGRAMMING" />
              <el-option label="数学" value="MATH" />
              <el-option label="英语" value="ENGLISH" />
              <el-option label="算法" value="ALGORITHM" />
              <el-option label="数据库" value="DATABASE" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleSearch">搜索</el-button>
            <el-button @click="handleReset">重置</el-button>
          </el-form-item>
        </el-form>
      </div>

      <el-table :data="recordList" border style="width: 100%;" :loading="loading">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="username" label="用户名" width="120" />
        <el-table-column prop="courseName" label="课程名称" width="180" />
        <el-table-column prop="courseType" label="课程类型" width="120">
          <template #default="scope">
            <el-tag type="info">{{ getCourseTypeLabel(scope.row.courseType) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="duration" label="学习时长(分钟)" width="140" />
        <el-table-column prop="score" label="成绩" width="100">
          <template #default="scope">
            <el-tag :type="getScoreType(scope.row.score)">
              {{ scope.row.score !== null ? scope.row.score + '分' : '-' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.status === 'COMPLETED' ? 'success' : 'warning'">
              {{ scope.row.status === 'COMPLETED' ? '已完成' : '进行中' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="learnDate" label="学习日期" width="150" />
      </el-table>

      <el-pagination
        :current-page="pagination.page"
        :page-size="pagination.size"
        :total="pagination.total"
        layout="total, prev, pager, next, jumper"
        @current-change="handlePageChange"
        @size-change="handleSizeChange"
        style="margin-top: 20px; text-align: right;"
      />
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { getLearningRecordList } from '@/api/learningRecord'

const searchForm = reactive({
  username: '',
  courseType: ''
})

const pagination = reactive({
  page: 1,
  size: 10,
  total: 0
})

const recordList = ref([])
const loading = ref(false)

const courseTypeMap = {
  PROGRAMMING: '编程',
  MATH: '数学',
  ENGLISH: '英语',
  ALGORITHM: '算法',
  DATABASE: '数据库'
}

const getCourseTypeLabel = (type) => {
  return courseTypeMap[type] || type
}

const getScoreType = (score) => {
  if (score === null) return 'info'
  if (score >= 90) return 'success'
  if (score >= 60) return 'info'
  return 'danger'
}

const loadRecords = async () => {
  loading.value = true
  try {
    const params = {}
    if (searchForm.username) {
      params.userName = searchForm.username
    }
    if (searchForm.courseType) {
      params.courseType = searchForm.courseType
    }

    const response = await getLearningRecordList(params)
    const data = response.data || []
    
    recordList.value = data.map(record => ({
      ...record,
      username: record.userName,
      learnDate: record.learnDate
    }))
    pagination.total = data.length
  } catch (error) {
    console.error('获取学习记录失败:', error)
    recordList.value = []
    pagination.total = 0
    ElMessage.error('获取学习记录失败')
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  pagination.page = 1
  loadRecords()
}

const handleReset = () => {
  searchForm.username = ''
  searchForm.courseType = ''
  pagination.page = 1
  loadRecords()
}

const handlePageChange = (page) => {
  pagination.page = page
  loadRecords()
}

const handleSizeChange = (size) => {
  pagination.size = size
  pagination.page = 1
  loadRecords()
}

onMounted(() => {
  loadRecords()
})
</script>

<style scoped>
.learning-container {
  min-height: 100%;
  padding: 0;
}

.page-card {
  height: 100%;
}

.search-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 20px;
  border-bottom: 1px solid #eee;
}
</style>