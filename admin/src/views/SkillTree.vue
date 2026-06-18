<template>
  <div class="skilltree-container">
    <el-card class="page-card">
      <div class="search-bar">
        <el-form :model="searchForm" inline>
          <el-form-item label="技能名称">
            <el-input
              v-model="searchForm.name"
              placeholder="请输入技能名称"
              style="width: 200px;"
            />
          </el-form-item>
          <el-form-item label="所属分类">
            <el-select
              v-model="searchForm.category"
              placeholder="请选择分类"
              style="width: 150px;"
            >
              <el-option label="全部" value="" />
              <el-option label="前端开发" value="frontend" />
              <el-option label="后端开发" value="backend" />
              <el-option label="数据库" value="database" />
              <el-option label="算法" value="algorithm" />
              <el-option label="操作系统" value="os" />
            </el-select>
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="handleSearch">搜索</el-button>
            <el-button @click="handleReset">重置</el-button>
          </el-form-item>
        </el-form>
        <el-button type="primary" icon="Plus" @click="handleAdd">新增技能</el-button>
      </div>

      <el-table :data="skillList" border style="width: 100%;" :loading="loading">
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="name" label="技能名称" width="150" />
        <el-table-column prop="category" label="所属分类" width="120">
          <template #default="scope">
            <el-tag type="info">{{ getCategoryLabel(scope.row.category) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="level" label="难度等级" width="100">
          <template #default="scope">
            <el-tag :type="getLevelType(scope.row.level)">
              {{ getLevelLabel(scope.row.level) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="parentName" label="父级技能" width="150" />
        <el-table-column prop="description" label="描述" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="scope">
            <el-tag :type="scope.row.status === 1 ? 'success' : 'danger'">
              {{ scope.row.status === 1 ? '启用' : '禁用' }}
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

    <el-dialog :title="dialogTitle" v-model="dialogVisible" width="500px">
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px">
        <el-form-item label="技能名称" prop="name">
          <el-input v-model="form.name" placeholder="请输入技能名称" />
        </el-form-item>
        <el-form-item label="所属分类" prop="category">
          <el-select v-model="form.category" placeholder="请选择分类">
            <el-option label="前端开发" value="frontend" />
            <el-option label="后端开发" value="backend" />
            <el-option label="数据库" value="database" />
            <el-option label="算法" value="algorithm" />
            <el-option label="操作系统" value="os" />
          </el-select>
        </el-form-item>
        <el-form-item label="难度等级" prop="level">
          <el-select v-model="form.level" placeholder="请选择难度等级">
            <el-option label="入门" value="beginner" />
            <el-option label="初级" value="primary" />
            <el-option label="中级" value="intermediate" />
            <el-option label="高级" value="advanced" />
            <el-option label="专家" value="expert" />
          </el-select>
        </el-form-item>
        <el-form-item label="父级技能">
          <el-select v-model="form.parentId" placeholder="请选择父级技能（可选）">
            <el-option label="无" :value="null" />
            <el-option
              v-for="skill in parentOptions"
              :key="skill.id"
              :label="skill.name"
              :value="skill.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="form.description" type="textarea" :rows="3" placeholder="请输入技能描述" />
        </el-form-item>
        <el-form-item label="状态">
          <el-radio-group v-model="form.status">
            <el-radio :value="1">启用</el-radio>
            <el-radio :value="0">禁用</el-radio>
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
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'

const searchForm = reactive({
  name: '',
  category: ''
})

const pagination = reactive({
  page: 1,
  size: 10,
  total: 0
})

const skillList = ref([])
const allSkills = ref([])
const loading = ref(false)
const dialogVisible = ref(false)
const dialogTitle = ref('新增技能')
const formRef = ref(null)

const form = reactive({
  id: null,
  name: '',
  category: '',
  level: 'beginner',
  parentId: null,
  parentName: '',
  description: '',
  status: 1
})

const rules = {
  name: [{ required: true, message: '请输入技能名称', trigger: 'blur' }],
  category: [{ required: true, message: '请选择所属分类', trigger: 'change' }],
  level: [{ required: true, message: '请选择难度等级', trigger: 'change' }],
  description: [{ required: true, message: '请输入描述', trigger: 'blur' }]
}

const categoryMap = {
  frontend: '前端开发',
  backend: '后端开发',
  database: '数据库',
  algorithm: '算法',
  os: '操作系统'
}

const levelMap = {
  beginner: '入门',
  primary: '初级',
  intermediate: '中级',
  advanced: '高级',
  expert: '专家'
}

const getCategoryLabel = (category) => categoryMap[category] || category

const getLevelLabel = (level) => levelMap[level] || level

const getLevelType = (level) => {
  const types = {
    beginner: 'success',
    primary: 'success',
    intermediate: 'warning',
    advanced: 'danger',
    expert: 'danger'
  }
  return types[level] || 'info'
}

const parentOptions = computed(() => {
  return allSkills.value.filter(s => s.id !== form.id)
})

const mockSkills = () => {
  const categories = ['frontend', 'backend', 'database', 'algorithm', 'os']
  const levels = ['beginner', 'primary', 'intermediate', 'advanced', 'expert']
  
  const skills = [
    { id: 1, name: 'HTML/CSS', category: 'frontend', level: 'beginner', parentId: null, parentName: '', description: '网页结构与样式基础', status: 1 },
    { id: 2, name: 'JavaScript', category: 'frontend', level: 'primary', parentId: null, parentName: '', description: '前端脚本语言', status: 1 },
    { id: 3, name: 'Vue.js', category: 'frontend', level: 'intermediate', parentId: 2, parentName: 'JavaScript', description: '渐进式前端框架', status: 1 },
    { id: 4, name: 'React', category: 'frontend', level: 'intermediate', parentId: 2, parentName: 'JavaScript', description: '声明式UI库', status: 1 },
    { id: 5, name: 'TypeScript', category: 'frontend', level: 'primary', parentId: 2, parentName: 'JavaScript', description: 'JavaScript超集', status: 1 },
    { id: 6, name: 'Spring Boot', category: 'backend', level: 'intermediate', parentId: null, parentName: '', description: 'Java后端框架', status: 1 },
    { id: 7, name: 'Node.js', category: 'backend', level: 'primary', parentId: 2, parentName: 'JavaScript', description: '服务端运行时', status: 1 },
    { id: 8, name: 'MySQL', category: 'database', level: 'primary', parentId: null, parentName: '', description: '关系型数据库', status: 1 },
    { id: 9, name: 'Redis', category: 'database', level: 'intermediate', parentId: null, parentName: '', description: '缓存数据库', status: 1 },
    { id: 10, name: 'MongoDB', category: 'database', level: 'intermediate', parentId: null, parentName: '', description: '文档型数据库', status: 1 },
    { id: 11, name: '数据结构', category: 'algorithm', level: 'primary', parentId: null, parentName: '', description: '基础数据结构', status: 1 },
    { id: 12, name: '排序算法', category: 'algorithm', level: 'intermediate', parentId: 11, parentName: '数据结构', description: '常见排序算法', status: 1 },
    { id: 13, name: '动态规划', category: 'algorithm', level: 'advanced', parentId: 11, parentName: '数据结构', description: '高级算法技巧', status: 1 },
    { id: 14, name: 'Linux', category: 'os', level: 'primary', parentId: null, parentName: '', description: '操作系统基础', status: 1 },
    { id: 15, name: 'Docker', category: 'os', level: 'intermediate', parentId: null, parentName: '', description: '容器技术', status: 1 },
    { id: 16, name: 'Webpack', category: 'frontend', level: 'intermediate', parentId: 2, parentName: 'JavaScript', description: '模块打包工具', status: 1 },
    { id: 17, name: 'Vite', category: 'frontend', level: 'beginner', parentId: 2, parentName: 'JavaScript', description: '新一代构建工具', status: 1 },
    { id: 18, name: 'Git', category: 'os', level: 'beginner', parentId: null, parentName: '', description: '版本控制工具', status: 1 },
    { id: 19, name: '算法复杂度', category: 'algorithm', level: 'primary', parentId: 11, parentName: '数据结构', description: '时间空间复杂度分析', status: 1 },
    { id: 20, name: '微服务', category: 'backend', level: 'advanced', parentId: 6, parentName: 'Spring Boot', description: '分布式架构设计', status: 1 }
  ]
  
  for (let i = 21; i <= 60; i++) {
    const category = categories[Math.floor(Math.random() * categories.length)]
    const level = levels[Math.floor(Math.random() * levels.length)]
    const hasParent = Math.random() > 0.5
    const parentSkill = hasParent ? skills[Math.floor(Math.random() * skills.length)] : null
    
    skills.push({
      id: i,
      name: `技能${i}`,
      category: category,
      level: level,
      parentId: parentSkill ? parentSkill.id : null,
      parentName: parentSkill ? parentSkill.name : '',
      description: `技能${i}的描述信息`,
      status: Math.random() > 0.1 ? 1 : 0
    })
  }
  
  return skills
}

const filterSkills = () => {
  let filtered = [...allSkills.value]
  
  if (searchForm.name) {
    const keyword = searchForm.name.toLowerCase()
    filtered = filtered.filter(skill => 
      skill.name.toLowerCase().includes(keyword)
    )
  }
  
  if (searchForm.category) {
    filtered = filtered.filter(skill => skill.category === searchForm.category)
  }
  
  return filtered
}

const loadSkills = async () => {
  loading.value = true
  try {
    if (allSkills.value.length === 0) {
      allSkills.value = mockSkills()
    }
    
    const filtered = filterSkills()
    
    const start = (pagination.page - 1) * pagination.size
    const end = start + pagination.size
    skillList.value = filtered.slice(start, end)
    pagination.total = filtered.length
  } catch (error) {
    console.error('获取技能树失败:', error)
    skillList.value = []
    pagination.total = 0
    ElMessage.error('获取技能树失败')
  } finally {
    loading.value = false
  }
}

const handleSearch = () => {
  pagination.page = 1
  loadSkills()
}

const handleReset = () => {
  searchForm.name = ''
  searchForm.category = ''
  pagination.page = 1
  loadSkills()
}

const handlePageChange = (page) => {
  pagination.page = page
  loadSkills()
}

const handleSizeChange = (size) => {
  pagination.size = size
  pagination.page = 1
  loadSkills()
}

const handleAdd = () => {
  dialogTitle.value = '新增技能'
  Object.assign(form, {
    id: null,
    name: '',
    category: '',
    level: 'beginner',
    parentId: null,
    parentName: '',
    description: '',
    status: 1
  })
  dialogVisible.value = true
}

const handleEdit = (row) => {
  dialogTitle.value = '编辑技能'
  Object.assign(form, {
    id: row.id,
    name: row.name,
    category: row.category,
    level: row.level,
    parentId: row.parentId,
    parentName: row.parentName,
    description: row.description,
    status: row.status
  })
  dialogVisible.value = true
}

const handleDelete = async (row) => {
  try {
    await ElMessageBox.confirm(
      `确定要删除技能「${row.name}」吗？`,
      '提示',
      {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
    
    const index = allSkills.value.findIndex(s => s.id === row.id)
    if (index !== -1) {
      allSkills.value.splice(index, 1)
      ElMessage.success('删除成功')
      loadSkills()
    }
  } catch {}
}

const handleSubmit = () => {
  formRef.value.validate((valid) => {
    if (!valid) return
    
    if (form.id) {
      const index = allSkills.value.findIndex(s => s.id === form.id)
      if (index !== -1) {
        const parentSkill = allSkills.value.find(s => s.id === form.parentId)
        allSkills.value[index] = {
          ...form,
          parentName: parentSkill ? parentSkill.name : ''
        }
        ElMessage.success('修改成功')
      }
    } else {
      const maxId = Math.max(...allSkills.value.map(s => s.id))
      const parentSkill = allSkills.value.find(s => s.id === form.parentId)
      allSkills.value.unshift({
        ...form,
        id: maxId + 1,
        parentName: parentSkill ? parentSkill.name : ''
      })
      ElMessage.success('新增成功')
    }
    
    dialogVisible.value = false
    loadSkills()
  })
}

onMounted(() => {
  loadSkills()
})
</script>

<style scoped>
.skilltree-container {
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
