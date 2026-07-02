import request from './request'

export function getSkillTreeList(params) {
  return request.get('/skill-trees', { params })
}

export function getSkillCategories() {
  return request.get('/skill-trees/categories')
}

export function getSkillTreeDetail(id) {
  return request.get(`/skill-trees/${id}`)
}

export function getSkillNodeTree(treeId) {
  return request.get(`/skill-trees/${treeId}/nodes`)
}

export function createSkillTree(data) {
  return request.post('/skill-trees', data)
}

export function updateSkillTree(id, data) {
  return request.put(`/skill-trees/${id}`, data)
}

export function deleteSkillTree(id) {
  return request.delete(`/skill-trees/${id}`)
}

export function createSkillNode(data) {
  return request.post('/skill-trees/nodes', data)
}

export function updateSkillNode(id, data) {
  return request.put(`/skill-trees/nodes/${id}`, data)
}

export function deleteSkillNode(id) {
  return request.delete(`/skill-trees/nodes/${id}`)
}