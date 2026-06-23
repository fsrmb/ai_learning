<!-- views/skill/index.vue -->
<template>
  <div class="skill-page">
    <el-card shadow="hover">
      <template #header>
        <div class="card-header">
          <span>技能树管理</span>
          <div>
            <el-select v-model="filterCategory" placeholder="按分类筛选"
                       clearable style="width: 160px; margin-right: 8px"
                       @change="fetchTree">
              <el-option label="前端" value="FRONTEND" />
              <el-option label="后端" value="BACKEND" />
              <el-option label="数据库" value="DATABASE" />
              <el-option label="运维" value="DEVOPS" />
              <el-option label="软技能" value="SOFT_SKILLS" />
            </el-select>
            <el-button type="primary" @click="openDialog()">新增技能</el-button>
          </div>
        </div>
      </template>

      <!-- 树形结构展示 -->
      <el-tree
        :data="treeData"
        :props="{ label: 'name' }"
        node-key="id"
        default-expand-all
        :expand-on-click-node="false"
        v-loading="loading"
      >
        <template #default="{ data }">
          <div class="tree-node">
            <span class="node-label">{{ data.name }}</span>
            <span class="node-actions">
              <el-tag size="small" type="info" style="margin-right: 8px">
                {{ getCategoryLabel(data.category) }}
              </el-tag>
              <el-button size="small" @click.stop="openDialog(data)">编辑</el-button>
              <el-button size="small" type="danger" @click.stop="handleDelete(data)">删除</el-button>
            </span>
          </div>
        </template>
      </el-tree>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="editingSkill ? '编辑技能' : '新增技能'" width="500px">
      <el-form ref="formRef" :model="form" :rules="rules" label-width="80px">
        <el-form-item label="名称" prop="name">
          <el-input v-model="form.name" />
        </el-form-item>
        <el-form-item label="分类" prop="category">
          <el-select v-model="form.category" style="width: 100%">
            <el-option label="前端" value="FRONTEND" />
            <el-option label="后端" value="BACKEND" />
            <el-option label="数据库" value="DATABASE" />
            <el-option label="运维" value="DEVOPS" />
            <el-option label="软技能" value="SOFT_SKILLS" />
          </el-select>
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="form.description" type="textarea" :rows="3" />
        </el-form-item>
        <el-form-item label="父级ID" prop="parentId">
          <el-input-number v-model="form.parentId" :min="0" />
        </el-form-item>
        <el-form-item label="图标" prop="icon">
          <el-input v-model="form.icon" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>
<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'

const treeData = ref([])
const allSkills = ref([])
const loading = ref(false)
const filterCategory = ref('')
const dialogVisible = ref(false)
const submitting = ref(false)
const editingSkill = ref(null)
const formRef = ref(null)

const categoryLabelMap = {
  FRONTEND: '前端',
  BACKEND: '后端',
  DATABASE: '数据库',
  DEVOPS: '运维',
  SOFT_SKILLS: '软技能'
}

const getCategoryLabel = (category) => categoryLabelMap[category] || category

const form = reactive({
  name: '',
  category: 'FRONTEND',
  description: '',
  parentId: 0,
  icon: ''
})

const rules = {
  name: [{ required: true, message: '请输入技能名称', trigger: 'blur' }],
  category: [{ required: true, message: '请选择分类', trigger: 'change' }]
}

const generateMockSkillTree = () => {
  const skills = [
    { id: 1, name: '前端开发', category: 'FRONTEND', description: '前端开发技术栈', parentId: 0, icon: '🌐', children: [] },
    { id: 2, name: 'HTML/CSS', category: 'FRONTEND', description: '网页结构与样式', parentId: 1, icon: '🎨', children: [] },
    { id: 3, name: 'JavaScript', category: 'FRONTEND', description: '前端脚本语言', parentId: 1, icon: '📜', children: [] },
    { id: 4, name: 'Vue.js', category: 'FRONTEND', description: '渐进式前端框架', parentId: 3, icon: '💚', children: [] },
    { id: 5, name: 'React', category: 'FRONTEND', description: '声明式UI库', parentId: 3, icon: '⚛️', children: [] },
    { id: 6, name: 'TypeScript', category: 'FRONTEND', description: 'JavaScript超集', parentId: 3, icon: '📘', children: [] },
    { id: 7, name: '后端开发', category: 'BACKEND', description: '后端开发技术栈', parentId: 0, icon: '🔧', children: [] },
    { id: 8, name: 'Java', category: 'BACKEND', description: 'Java编程语言', parentId: 7, icon: '☕', children: [] },
    { id: 9, name: 'Spring Boot', category: 'BACKEND', description: 'Java后端框架', parentId: 8, icon: '🌱', children: [] },
    { id: 10, name: 'Node.js', category: 'BACKEND', description: '服务端运行时', parentId: 7, icon: '🟢', children: [] },
    { id: 11, name: '数据库', category: 'DATABASE', description: '数据库技术', parentId: 0, icon: '💾', children: [] },
    { id: 12, name: 'MySQL', category: 'DATABASE', description: '关系型数据库', parentId: 11, icon: '🐬', children: [] },
    { id: 13, name: 'Redis', category: 'DATABASE', description: '缓存数据库', parentId: 11, icon: '⚡', children: [] },
    { id: 14, name: 'MongoDB', category: 'DATABASE', description: '文档型数据库', parentId: 11, icon: '🍃', children: [] },
    { id: 15, name: '运维', category: 'DEVOPS', description: '运维技术', parentId: 0, icon: '🔧', children: [] },
    { id: 16, name: 'Linux', category: 'DEVOPS', description: '操作系统', parentId: 15, icon: '🐧', children: [] },
    { id: 17, name: 'Docker', category: 'DEVOPS', description: '容器技术', parentId: 15, icon: '🐋', children: [] },
    { id: 18, name: 'Git', category: 'DEVOPS', description: '版本控制', parentId: 15, icon: '📦', children: [] },
    { id: 19, name: '软技能', category: 'SOFT_SKILLS', description: '软技能培训', parentId: 0, icon: '💡', children: [] },
    { id: 20, name: '沟通能力', category: 'SOFT_SKILLS', description: '团队沟通技巧', parentId: 19, icon: '🗣️', children: [] },
    { id: 21, name: '时间管理', category: 'SOFT_SKILLS', description: '高效时间管理', parentId: 19, icon: '⏰', children: [] },
    { id: 22, name: '项目管理', category: 'SOFT_SKILLS', description: '项目管理方法', parentId: 19, icon: '📊', children: [] },
    { id: 23, name: 'Webpack', category: 'FRONTEND', description: '模块打包工具', parentId: 3, icon: '📦', children: [] },
    { id: 24, name: 'Vite', category: 'FRONTEND', description: '新一代构建工具', parentId: 3, icon: '⚡', children: [] },
    { id: 25, name: '微服务', category: 'BACKEND', description: '分布式架构', parentId: 9, icon: '🏗️', children: [] }
  ]

  const buildTree = (items, parentId = 0) => {
    const tree = []
    const filtered = items.filter(item => item.parentId === parentId)
    filtered.forEach(item => {
      const children = buildTree(items, item.id)
      const node = { ...item }
      if (children.length > 0) {
        node.children = children
      }
      node.label = item.name
      tree.push(node)
    })
    return tree
  }

  return buildTree(skills)
}

const filterTreeByCategory = (tree, category) => {
  if (!category) return tree

  const filterNode = (node) => {
    if (node.category === category) {
      return node
    }
    if (node.children && node.children.length > 0) {
      const filteredChildren = node.children.map(filterNode).filter(Boolean)
      if (filteredChildren.length > 0) {
        return { ...node, children: filteredChildren }
      }
    }
    return null
  }

  return tree.map(filterNode).filter(Boolean)
}

async function fetchTree() {
  loading.value = true
  try {
    if (allSkills.value.length === 0) {
      allSkills.value = generateMockSkillTree()
    }

    if (filterCategory.value) {
      treeData.value = filterTreeByCategory(allSkills.value, filterCategory.value)
    } else {
      treeData.value = allSkills.value
    }
  } finally {
    loading.value = false
  }
}

function openDialog(skill) {
  editingSkill.value = skill || null
  if (skill) {
    Object.assign(form, {
      name: skill.name,
      category: skill.category,
      description: skill.description,
      parentId: skill.parentId,
      icon: skill.icon
    })
  } else {
    Object.assign(form, {
      name: '', category: 'FRONTEND', description: '', parentId: 0, icon: ''
    })
  }
  dialogVisible.value = true
}

async function handleSubmit() {
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return

  submitting.value = true
  try {
    if (editingSkill.value) {
      const updateNode = (nodes) => {
        for (let i = 0; i < nodes.length; i++) {
          if (nodes[i].id === editingSkill.value.id) {
            nodes[i] = { ...nodes[i], ...form }
            return true
          }
          if (nodes[i].children && updateNode(nodes[i].children)) {
            return true
          }
        }
        return false
      }
      updateNode(allSkills.value)
      ElMessage.success('更新成功')
    } else {
      const maxId = Math.max(...allSkills.value.map(n => {
        const getMaxId = (node) => {
          const max = node.children ? Math.max(...node.children.map(getMaxId)) : 0
          return Math.max(node.id, max)
        }
        return getMaxId(n)
      }))
      const newSkill = {
        id: maxId + 1,
        ...form,
        children: []
      }
      if (form.parentId === 0) {
        allSkills.value.push(newSkill)
      } else {
        const addChild = (nodes) => {
          for (let i = 0; i < nodes.length; i++) {
            if (nodes[i].id === form.parentId) {
              if (!nodes[i].children) nodes[i].children = []
              nodes[i].children.push(newSkill)
              return true
            }
            if (nodes[i].children && addChild(nodes[i].children)) {
              return true
            }
          }
          return false
        }
        addChild(allSkills.value)
      }
      ElMessage.success('创建成功')
    }
    dialogVisible.value = false
    fetchTree()
  } catch {
    ElMessage.error('操作失败')
  } finally {
    submitting.value = false
  }
}

async function handleDelete(skill) {
  await ElMessageBox.confirm(`确定删除技能 "${skill.name}" 吗？`, '提示', { type: 'warning' })
  try {
    const removeNode = (nodes, parent) => {
      for (let i = 0; i < nodes.length; i++) {
        if (nodes[i].id === skill.id) {
          nodes.splice(i, 1)
          return true
        }
        if (nodes[i].children && removeNode(nodes[i].children, nodes[i])) {
          return true
        }
      }
      return false
    }
    removeNode(allSkills.value)
    ElMessage.success('删除成功')
    fetchTree()
  } catch {
    ElMessage.error('删除失败')
  }
}

onMounted(fetchTree)
</script>

<style scoped>
.skill-page {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.tree-node {
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
  color: #333;
}

.node-label {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.node-actions {
  display: flex;
  align-items: center;
}
</style>