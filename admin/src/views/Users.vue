<template>
  <div class="users-container">
    <el-card class="page-card">
      <div class="search-bar">
        <el-form :model="searchForm" inline>
          <el-form-item label="关键词">
            <el-input
              v-model="searchForm.keyword"
              placeholder="请输入用户名/昵称/邮箱"
              style="width: 200px;"
            />
          </el-form-item>
          <el-form-item label="角色">
            <el-select
              v-model="searchForm.role"
              placeholder="请选择角色"
              style="width: 150px;"
            >
              <el-option label="全部" value="" />
              <el-option label="管理员" value="admin" />
              <el-option label="普通用户" value="user" />
              <el-option label="访客" value="guest" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleSearch">搜索</el-button>
            <el-button @click="handleReset">重置</el-button>
          </el-form-item>
        </el-form>
        <el-button type="primary" icon="Plus" @click="handleAdd">新增用户</el-button>
      </div>

      <el-table :data="userList" border style="width: 100%;" :loading="loading">
        <el-table-column prop="username" label="用户名" width="120" />
        <el-table-column prop="nickname" label="昵称" width="120" />
        <el-table-column prop="email" label="邮箱" />
        <el-table-column prop="role" label="角色" width="100">
          <template #default="scope">
            <el-tag type="info">{{ getRoleLabel(scope.row.role) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.status === 1 ? 'success' : 'danger'">
              {{ scope.row.status === 1 ? '正常' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150">
          <template #default="scope">
            <el-button type="text" icon="Edit" @click="handleEdit(scope.row)">编辑</el-button>
            <el-button type="text" icon="Delete" @click="handleDelete(scope.row)">删除</el-button>
          </template>
        </el-table-column>
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
import request from '../utils/request'

const searchForm = reactive({
  keyword: '',
  role: ''
})

const pagination = reactive({
  page: 1,
  size: 10,
  total: 0
})

const userList = ref([])
const loading = ref(false)

const roleMap = {
  admin: '管理员',
  user: '普通用户',
  guest: '访客'
}

const getRoleLabel = (role) => {
  return roleMap[role] || role
}

const loadUsers = async () => {
  loading.value = true
  try {
    const params = {
      page: pagination.page,
      size: pagination.size,
      keyword: searchForm.keyword,
      role: searchForm.role
    }
    
    const response = await request.get('/api/users', { params })
    
    if (response.data) {
      userList.value = response.data.list || response.data
      pagination.total = response.data.total || 100
    } else {
      userList.value = mockUsers()
      pagination.total = 100
    }
  } catch (error) {
    console.error('获取用户列表失败:', error)
    userList.value = mockUsers()
    pagination.total = 100
    ElMessage.error('获取用户列表失败')
  } finally {
    loading.value = false
  }
}

const mockUsers = () => {
  const roles = ['admin', 'user', 'guest']
  const users = []
  for (let i = 1; i <= pagination.size; i++) {
    const id = (pagination.page - 1) * pagination.size + i
    const role = roles[Math.floor(Math.random() * roles.length)]
    users.push({
      id: id,
      username: `user${id}`,
      nickname: `用户${id}`,
      email: `user${id}@example.com`,
      role: role,
      status: Math.random() > 0.15 ? 1 : 0,
      createTime: `2024-01-${String(Math.floor(Math.random() * 30) + 1).padStart(2, '0')} 10:30:00`
    })
  }
  return users
}

const handleSearch = () => {
  pagination.page = 1
  loadUsers()
}

const handleReset = () => {
  searchForm.keyword = ''
  searchForm.role = ''
  pagination.page = 1
  loadUsers()
}

const handlePageChange = (page) => {
  pagination.page = page
  loadUsers()
}

const handleSizeChange = (size) => {
  pagination.size = size
  pagination.page = 1
  loadUsers()
}

const handleAdd = () => {
  ElMessage.info('新增用户功能')
}

const handleEdit = (row) => {
  ElMessage.info(`编辑用户: ${row.username}`)
}

const handleDelete = async (row) => {
  try {
    await ElMessage.confirm(
      `确定要删除用户 ${row.username} 吗？`,
      '提示',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    try {
      await request.delete(`/api/users/${row.id}`)
      ElMessage.success('删除成功')
      loadUsers()
    } catch (error) {
      console.error('删除用户失败:', error)
      ElMessage.error('删除失败')
    }
  } catch (error) {
    ElMessage.info('已取消删除')
  }
}

onMounted(() => {
  loadUsers()
})
</script>

<style scoped>
.users-container {
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
