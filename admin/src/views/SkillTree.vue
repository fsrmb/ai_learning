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
              <el-option label="算法" value="ALGORITHM" />
              <el-option label="移动端" value="MOBILE" />
            </el-select>
            <el-button type="primary" @click="openDialog()">新增技能树</el-button>
          </div>
        </div>
      </template>

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
            <div class="node-left">
              <span class="node-label">{{ data.name }}</span>
              <el-button
                type="text"
                size="small"
                :icon="Plus"
                class="add-child-btn"
                @click.stop="openDialog(null, data)"
                title="添加子技能"
              />
            </div>
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
            <el-option label="算法" value="ALGORITHM" />
            <el-option label="移动端" value="MOBILE" />
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
import { Plus } from '@element-plus/icons-vue'
import { getSkillTreeList, getSkillNodeTree, createSkillTree, updateSkillTree, deleteSkillTree, createSkillNode, updateSkillNode, deleteSkillNode } from '@/api/skill'

const treeData = ref([])
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
  ALGORITHM: '算法',
  MOBILE: '移动端',
  DEVOPS: '运维',
  SOFT_SKILLS: '软技能'
}

const getCategoryLabel = (category) => categoryLabelMap[category] || category

const form = reactive({
  name: '',
  category: 'FRONTEND',
  description: '',
  parentId: 0,
  icon: '',
  difficultyLevel: 1
})

const rules = {
  name: [{ required: true, message: '请输入技能名称', trigger: 'blur' }],
  category: [{ required: true, message: '请选择分类', trigger: 'change' }]
}

const buildNodeTree = (nodes, parentId = 0) => {
  const tree = []
  const filtered = nodes.filter(item => item.parentId === parentId)
  filtered.forEach(item => {
    const children = buildNodeTree(nodes, item.id)
    const node = { ...item }
    if (children.length > 0) {
      node.children = children
    }
    node.label = item.name
    tree.push(node)
  })
  return tree
}

async function fetchTree() {
  loading.value = true
  try {
    const skillTrees = await getSkillTreeList({ category: filterCategory.value || undefined })
    
    const tree = []
    for (const treeItem of skillTrees) {
      const nodeData = await getSkillNodeTree(treeItem.id)
      const nodes = buildNodeTree(nodeData)
      
      const skillNode = {
        id: treeItem.id,
        name: treeItem.name,
        category: treeItem.category,
        description: treeItem.description,
        parentId: 0,
        icon: treeItem.icon,
        label: treeItem.name,
        isTree: true
      }
      
      if (nodes.length > 0) {
        skillNode.children = nodes
      }
      
      tree.push(skillNode)
    }
    
    treeData.value = tree
  } catch (error) {
    console.error('获取技能树失败:', error)
    treeData.value = []
    ElMessage.error('获取技能树失败')
  } finally {
    loading.value = false
  }
}

function openDialog(skill, parentSkill) {
  editingSkill.value = skill || null
  if (skill) {
    Object.assign(form, {
      name: skill.name,
      category: skill.category || 'FRONTEND',
      description: skill.description || '',
      parentId: skill.parentId || 0,
      icon: skill.icon || ''
    })
  } else {
    Object.assign(form, {
      name: '',
      category: parentSkill ? parentSkill.category : 'FRONTEND',
      description: '',
      parentId: parentSkill ? parentSkill.id : 0,
      icon: ''
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
      if (editingSkill.value.isTree) {
        await updateSkillTree(editingSkill.value.id, {
          name: form.name,
          category: form.category,
          description: form.description,
          icon: form.icon,
          difficultyLevel: form.difficultyLevel
        })
      } else {
        await updateSkillNode(editingSkill.value.id, {
          name: form.name,
          description: form.description,
          icon: form.icon,
          parentId: form.parentId,
          nodeType: 'SKILL',
          treeId: editingSkill.value.treeId
        })
      }
      ElMessage.success('更新成功')
    } else {
      if (form.parentId === 0) {
        await createSkillTree({
          name: form.name,
          category: form.category,
          description: form.description,
          icon: form.icon,
          difficultyLevel: form.difficultyLevel
        })
      } else {
        const parentNode = findNode(treeData.value, form.parentId)
        const treeId = parentNode?.isTree ? parentNode.id : parentNode?.treeId || 1
        
        await createSkillNode({
          treeId,
          parentId: form.parentId,
          name: form.name,
          description: form.description,
          icon: form.icon,
          nodeType: 'SKILL'
        })
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

function findNode(nodes, targetId) {
  for (const node of nodes) {
    if (node.id === targetId) return node
    if (node.children) {
      const found = findNode(node.children, targetId)
      if (found) return found
    }
  }
  return null
}

async function handleDelete(skill) {
  await ElMessageBox.confirm(`确定删除技能 "${skill.name}" 吗？`, '提示', { type: 'warning' })
  try {
    if (skill.isTree) {
      await deleteSkillTree(skill.id)
    } else {
      await deleteSkillNode(skill.id)
    }
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

.node-left {
  display: flex;
  align-items: center;
  flex: 1;
  min-width: 0;
}

.node-label {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.add-child-btn {
  color: #409EFF;
  font-size: 12px;
  width: 20px;
  height: 20px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  margin-left: 8px;
  flex-shrink: 0;
}

.add-child-btn:hover {
  color: #fff;
  background-color: #409EFF;
}

.node-actions {
  display: flex;
  align-items: center;
}
</style>