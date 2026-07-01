<template>
  <div class="users-container">
    <el-card class="page-card">
      <div class="search-bar">
        <el-form :model="searchForm" inline>
          <el-form-item label="关键词">
            <el-input
              v-model="searchForm.keyword"
              placeholder="请输入用户名/昵称"
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
              <el-option label="管理员" value="ADMIN" />
              <el-option label="教师" value="TEACHER" />
              <el-option label="学生" value="STUDENT" />
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
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="username" label="用户名" width="120" />
        <el-table-column prop="nickname" label="昵称" width="120" />
        <el-table-column prop="email" label="邮箱" />
        <el-table-column prop="role" label="角色" width="100">
          <template #default="scope">
            <el-tag :type="getRoleTagType(scope.row.role)">{{ getRoleLabel(scope.row.role) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.status === 1 ? 'success' : 'danger'">
              {{ scope.row.status === 1 ? '正常' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="createTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="150">
          <template #default="scope">
            <el-button type="text" icon="Edit" @click="handleEdit(scope.row)">编辑</el-button>
            <el-button type="text" icon="Delete" @click="handleDelete(scope.row)">删除</el-button>
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

    <el-dialog
      v-model="dialogVisible"
      :title="dialogTitle"
      width="500px"
      @close="handleDialogClose"
    >
      <el-form
        ref="userFormRef"
        :model="userForm"
        :rules="userFormRules"
        label-width="80px"
      >
        <el-form-item label="用户名" prop="username">
          <el-input v-model="userForm.username" placeholder="请输入用户名" />
        </el-form-item>
        <el-form-item label="昵称" prop="nickname">
          <el-input v-model="userForm.nickname" placeholder="请输入昵称" />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="userForm.email" placeholder="请输入邮箱" />
        </el-form-item>
        <el-form-item label="角色" prop="role">
          <el-select v-model="userForm.role" placeholder="请选择角色" style="width: 100%;">
            <el-option label="管理员" value="ADMIN" />
            <el-option label="教师" value="TEACHER" />
            <el-option label="学生" value="STUDENT" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="userForm.status">
            <el-radio :label="1">正常</el-radio>
            <el-radio :label="0">禁用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getUserList, updateUser, deleteUser, createUser } from '../api/user'

const searchForm = reactive({
  keyword: '',
  role: ''
})

const userList = ref([])
const loading = ref(false)

const currentPage = ref(1)
const pageSize = ref(10)
const total = ref(0)

const roleMap = {
  ADMIN: '管理员',
  TEACHER: '教师',
  STUDENT: '学生'
}

const roleTagTypeMap = {
  ADMIN: 'danger',
  TEACHER: 'warning',
  STUDENT: 'info'
}

const getRoleLabel = (role) => {
  return roleMap[role] || role
}

const getRoleTagType = (role) => {
  return roleTagTypeMap[role] || 'info'
}

const loadUsers = async () => {
  loading.value = true
  try {
    const params = {
      keyword: searchForm.keyword,
      role: searchForm.role,
      page: currentPage.value,
      size: pageSize.value
    }
    const result = await getUserList(params)
    userList.value = result.records || []
    total.value = result.total || 0
  } catch (error) {
    console.error('获取用户列表失败:', error)
    ElMessage.error('获取用户列表失败')
    userList.value = []
    total.value = 0
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  currentPage.value = 1
  loadUsers()
}

const handleReset = () => {
  searchForm.keyword = ''
  searchForm.role = ''
  currentPage.value = 1
  loadUsers()
}

const handleSizeChange = (val) => {
  pageSize.value = val
  currentPage.value = 1
  loadUsers()
}

const handleCurrentChange = (val) => {
  currentPage.value = val
  loadUsers()
}

const dialogVisible = ref(false)
const dialogTitle = ref('新增用户')
const userFormRef = ref(null)

const userForm = reactive({
  id: null,
  username: '',
  nickname: '',
  email: '',
  role: 'STUDENT',
  status: 1
})

const userFormRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 3, max: 20, message: '长度在 3 到 20 个字符', trigger: 'blur' }
  ],
  nickname: [
    { required: true, message: '请输入昵称', trigger: 'blur' }
  ],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    { type: 'email', message: '请输入正确的邮箱地址', trigger: 'blur' }
  ],
  role: [
    { required: true, message: '请选择角色', trigger: 'change' }
  ]
}

const handleAdd = () => {
  dialogTitle.value = '新增用户'
  resetUserForm()
  dialogVisible.value = true
}

const handleEdit = (row) => {
  dialogTitle.value = '编辑用户'
  Object.assign(userForm, {
    id: row.id,
    username: row.username,
    nickname: row.nickname,
    email: row.email,
    role: row.role,
    status: row.status
  })
  dialogVisible.value = true
}

const resetUserForm = () => {
  userForm.id = null
  userForm.username = ''
  userForm.nickname = ''
  userForm.email = ''
  userForm.role = 'STUDENT'
  userForm.status = 1
  if (userFormRef.value) {
    userFormRef.value.clearValidate()
  }
}

const handleDialogClose = () => {
  resetUserForm()
}

const handleSubmit = async () => {
  if (!userFormRef.value) return
  
  await userFormRef.value.validate(async (valid) => {
    if (valid) {
      loading.value = true
      try {
        if (userForm.id) {
          await updateUser(userForm.id, {
            username: userForm.username,
            nickname: userForm.nickname,
            email: userForm.email,
            role: userForm.role,
            status: userForm.status
          })
          ElMessage.success('编辑成功')
        } else {
          await createUser({
            username: userForm.username,
            nickname: userForm.nickname,
            email: userForm.email,
            password: '123456',
            role: userForm.role,
            status: userForm.status
          })
          ElMessage.success('新增成功')
        }
        dialogVisible.value = false
        loadUsers()
      } catch (error) {
        console.error('操作失败:', error)
        ElMessage.error('操作失败')
      } finally {
        loading.value = false
      }
    }
  })
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除用户 ${row.username} 吗？`,
      '提示',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    await deleteUser(row.id)
    ElMessage.success('删除成功')
    loadUsers()
  } catch (error) {
    // 用户点击取消，不显示消息
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

.pagination-container {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
  padding-top: 10px;
  border-top: 1px solid #eee;
}
</style>
