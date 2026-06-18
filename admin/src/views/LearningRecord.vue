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
              <el-option label="编程" value="programming" />
              <el-option label="数学" value="math" />
              <el-option label="英语" value="english" />
              <el-option label="算法" value="algorithm" />
              <el-option label="数据库" value="database" />
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
              {{ scope.row.score }}分
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.status === 'completed' ? 'success' : 'warning'">
              {{ scope.row.status === 'completed' ? '已完成' : '进行中' }}
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
const allRecords = ref([])
const loading = ref(false)

const courseTypeMap = {
  programming: '编程',
  math: '数学',
  english: '英语',
  algorithm: '算法',
  database: '数据库'
}

const getCourseTypeLabel = (type) => {
  return courseTypeMap[type] || type
}

const getScoreType = (score) => {
  if (score >= 90) return 'success'
  if (score >= 60) return 'info'
  return 'danger'
}

const mockRecords = () => {
  const types = ['programming', 'math', 'english', 'algorithm', 'database']
  const courses = {
    programming: ['Vue3 入门教程', 'React 实战', 'TypeScript 基础', 'Node.js 后端开发', 'Webpack 配置'],
    math: ['高等数学', '线性代数', '概率论', '离散数学', '微积分'],
    english: ['大学英语四级', '雅思听力', '商务英语', '英语口语', '英语写作'],
    algorithm: ['数据结构', '算法导论', '动态规划', '图论基础', '排序算法'],
    database: ['MySQL 基础', 'Redis 实战', 'MongoDB', 'PostgreSQL', 'SQL 优化']
  }
  const records = []
  for (let i = 1; i <= 100; i++) {
    const type = types[Math.floor(Math.random() * types.length)]
    const courseList = courses[type]
    const courseName = courseList[Math.floor(Math.random() * courseList.length)]
    records.push({
      id: i,
      username: `user${Math.floor(Math.random() * 20) + 1}`,
      courseName: courseName,
      courseType: type,
      duration: Math.floor(Math.random() * 120) + 10,
      score: Math.floor(Math.random() * 100),
      status: Math.random() > 0.3 ? 'completed' : 'ongoing',
      learnDate: `2024-${String(Math.floor(Math.random() * 12) + 1).padStart(2, '0')}-${String(Math.floor(Math.random() * 28) + 1).padStart(2, '0')} ${String(Math.floor(Math.random() * 24)).padStart(2, '0')}:${String(Math.floor(Math.random() * 60)).padStart(2, '0')}:00`
    })
  }
  return records
}

const filterRecords = () => {
  let filtered = [...allRecords.value]
  
  if (searchForm.username) {
    const keyword = searchForm.username.toLowerCase()
    filtered = filtered.filter(record => 
      record.username.toLowerCase().includes(keyword)
    )
  }
  
  if (searchForm.courseType) {
    filtered = filtered.filter(record => record.courseType === searchForm.courseType)
  }
  
  return filtered
}

const loadRecords = async () => {
  loading.value = true
  try {
    if (allRecords.value.length === 0) {
      allRecords.value = mockRecords()
    }
    
    const filtered = filterRecords()
    
    const start = (pagination.page - 1) * pagination.size
    const end = start + pagination.size
    recordList.value = filtered.slice(start, end)
    pagination.total = filtered.length
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
