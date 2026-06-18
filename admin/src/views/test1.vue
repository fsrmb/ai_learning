<template>
  <div class="form-container">
    <h2>用户信息表单</h2>
    <!-- ref="formRef" 用于获取表单实例，调用校验方法 -->
    <el-form
      :model="formData"
      :rules="rules"
      ref="formRef"
      label-width="100px"
      status-icon
    >
      <!-- 昵称 -->
      <el-form-item label="昵称" prop="nickname">
        <el-input v-model="formData.nickname" placeholder="请输入昵称" />
      </el-form-item>

      <!-- 手机号 -->
      <el-form-item label="手机号" prop="phone">
        <el-input v-model="formData.phone" placeholder="请输入手机号" />
      </el-form-item>

      <!-- 邮箱 -->
      <el-form-item label="邮箱" prop="email">
        <el-input v-model="formData.email" placeholder="请输入邮箱" />
      </el-form-item>

      <!-- 性别（单选框） -->
      <el-form-item label="性别" prop="gender">
        <el-radio-group v-model="formData.gender">
          <el-radio label="male">男</el-radio>
          <el-radio label="female">女</el-radio>
          <el-radio label="other">其他</el-radio>
        </el-radio-group>
      </el-form-item>

      <!-- 系统角色（下拉选择） -->
      <el-form-item label="系统角色" prop="role">
        <el-select v-model="formData.role" placeholder="请选择角色" style="width: 100%">
          <el-option label="管理员" value="admin" />
          <el-option label="普通用户" value="user" />
          <el-option label="访客" value="guest" />
        </el-select>
      </el-form-item>

      <!-- 提交按钮 -->
      <el-form-item>
        <el-button type="primary" @click="submitForm">提交</el-button>
        <el-button @click="resetForm">重置</el-button>
      </el-form-item>
    </el-form>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'

// 1. 表单数据（使用 reactive）
const formData = reactive({
  nickname: '',
  phone: '',
  email: '',
  gender: '',
  role: ''
})

// 2. 获取表单组件实例（用于校验和重置）
const formRef = ref(null)

const validatePhone = (rule, value, callback) => {
  if (!value) {
    return callback(new Error('手机号不能为空'))
  }
  // 中国手机号正则（简单版）
  const reg = /^1[3-9]\d{9}$/
  if (!reg.test(value)) {
    callback(new Error('请输入正确的手机号格式'))
  } else {
    callback()
  }
}
const validateEmail = (rule, value, callback) => {
  if (!value) {
    return callback(new Error('邮箱不能为空'))
  }
  // 邮箱正则（简单版）
  const reg = /^[a-zA-Z0-9_.-]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z0-9]{2,6}$/
  if (!reg.test(value)) {
    callback(new Error('请输入正确的邮箱格式'))
  } else {
    callback()
  }
}
// 4. 定义校验规则
const rules = {
  nickname: [
    { required: true, message: '请输入昵称', trigger: 'blur' },
    { min: 2, max: 12, message: '昵称长度在 2 到 12 个字符', trigger: 'blur' }
  ],
  phone: [
    { validator: validatePhone, trigger: 'blur' }
    
  ],
  email: [
    { validator: validateEmail, trigger: 'blur' }
  ],
  gender: [
    { required: true, message: '请选择性别', trigger: 'change' }
  ],
  role: [
    { required: true, message: '请选择系统角色', trigger: 'change' }
  ]
}
// 5. 提交表单
const submitForm = () => {
  // 获取表单实例的校验方法
  formRef.value.validate((valid) => {
    if (valid) {
      // 校验通过，执行提交逻辑（例如调用 API）
      ElMessage.success('提交成功！')
      console.log('表单数据：', formData)
      // 这里可以调用 axios.post 等
    } else {
      ElMessage.error('请完善表单信息')
      return false
    }
  })
}

// 6. 重置表单
const resetForm = () => {
  formRef.value.resetFields() // 重置字段值和校验状态
}
</script>
