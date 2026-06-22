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
            <el-option label="管理员" value="admin" />
            <el-option label="普通用户" value="user" />
            <el-option label="访客" value="guest" />
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
/**
 * 用户管理页面组件
 * 提供用户列表展示、搜索、分页、新增、编辑、删除等功能
 */

import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getUserList } from '../api/user'

// ---- 搜索表单 ----
/** 搜索表单数据 */
const searchForm = reactive({
  keyword: '',
  role: ''
})

// ---- 分页配置 ----
/** 分页参数 */
const pagination = reactive({
  page: 1,
  size: 10,
  total: 0
})

// ---- 数据状态 ----
/** 当前页用户列表 */
const userList = ref([])
/** 加载状态 */
const loading = ref(false)

// ---- 角色映射 ----
/** 角色值到标签的映射 */
const roleMap = {
  admin: '管理员',
  user: '普通用户',
  guest: '访客'
}

/**
 * 获取角色标签文本
 * @param {string} role - 角色值
 * @returns {string} 角色标签文本
 */
const getRoleLabel = (role) => {
  return roleMap[role] || role
}

/**
 * 加载用户列表
 * @returns {Promise<void>}
 * @description 调用 getUserList API 获取用户数据，支持分页和搜索
 */
const loadUsers = async () => {
  loading.value = true
  try {
    // 构建查询参数
    const params = {
      page: pagination.page,
      size: pagination.size,
      keyword: searchForm.keyword,
      role: searchForm.role
    }
    
    // 调用 API 获取用户列表
    const result = await getUserList(params)
    
    // 更新用户列表和分页信息
    userList.value = result.list || result.data || []
    pagination.total = result.total || 0
    
  } catch (error) {
    console.error('获取用户列表失败:', error)
    ElMessage.error('获取用户列表失败')
    userList.value = []
    pagination.total = 0
  } finally {
    loading.value = false
  }
}

/**
 * 处理搜索操作
 * @description 重置页码并重新加载用户列表
 */
const handleSearch = () => {
  pagination.page = 1
  loadUsers()
}

/**
 * 处理重置操作
 * @description 清空搜索条件并重新加载用户列表
 */
const handleReset = () => {
  searchForm.keyword = ''
  searchForm.role = ''
  pagination.page = 1
  loadUsers()
}

/**
 * 处理页码变化
 * @param {number} page - 新页码
 */
const handlePageChange = (page) => {
  pagination.page = page
  loadUsers()
}

/**
 * 处理每页数量变化
 * @param {number} size - 新每页数量
 */
const handleSizeChange = (size) => {
  pagination.size = size
  pagination.page = 1
  loadUsers()
}

// ---- 对话框相关 ----
/** 对话框显示状态 */
const dialogVisible = ref(false)
/** 对话框标题 */
const dialogTitle = ref('新增用户')
/** 用户表单引用 */
const userFormRef = ref(null)

/** 用户表单数据 */
const userForm = reactive({
  id: null,
  username: '',
  nickname: '',
  email: '',
  role: 'user',
  status: 1
})

/** 用户表单验证规则 */
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

/**
 * 处理新增用户操作
 * @description 打开新增用户对话框
 */
const handleAdd = () => {
  dialogTitle.value = '新增用户'
  resetUserForm()
  dialogVisible.value = true
}

/**
 * 处理编辑用户操作
 * @param {Object} row - 用户行数据
 * @description 打开编辑用户对话框，填充用户信息
 */
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

/**
 * 重置用户表单
 * @description 清空表单数据和验证状态
 */
const resetUserForm = () => {
  userForm.id = null
  userForm.username = ''
  userForm.nickname = ''
  userForm.email = ''
  userForm.role = 'user'
  userForm.status = 1
  if (userFormRef.value) {
    userFormRef.value.clearValidate()
  }
}

/**
 * 对话框关闭事件
 * @description 重置表单
 */
const handleDialogClose = () => {
  resetUserForm()
}

/**
 * 处理表单提交
 * @returns {Promise<void>}
 * @description 验证表单后提交新增或编辑请求
 */
const handleSubmit = async () => {
  if (!userFormRef.value) return
  
  await userFormRef.value.validate(async (valid) => {
    if (valid) {
      try {
        if (userForm.id) {
          // 编辑用户 - 本地更新（TODO: 调用更新 API）
          const index = userList.value.findIndex(u => u.id === userForm.id)
          if (index !== -1) {
            userList.value[index] = {
              ...userList.value[index],
              username: userForm.username,
              nickname: userForm.nickname,
              email: userForm.email,
              role: userForm.role,
              status: userForm.status
            }
          }
          ElMessage.success('编辑成功')
        } else {
          // 新增用户 - 本地更新（TODO: 调用新增 API）
          const newUser = {
            ...userForm,
            id: Date.now(),
            createTime: new Date().toLocaleString('zh-CN')
          }
          userList.value.unshift(newUser)
          pagination.total += 1
          ElMessage.success('新增成功')
        }
        dialogVisible.value = false
      } catch (error) {
        console.error('操作失败:', error)
        ElMessage.error('操作失败')
      }
    }
  })
}

/**
 * 处理删除用户操作
 * @param {Object} row - 用户行数据
 * @returns {Promise<void>}
 * @description 弹出确认对话框后删除用户
 */
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
    
    // 本地删除 - 从列表中删除（TODO: 调用删除 API）
    const index = userList.value.findIndex(u => u.id === row.id)
    if (index !== -1) {
      userList.value.splice(index, 1)
      pagination.total -= 1
      ElMessage.success('删除成功')
    }
  } catch (error) {
    // 用户点击取消，不显示消息
  }
}

// ---- 生命周期 ----
/** 组件挂载时加载用户列表 */
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
