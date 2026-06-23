import request from './request'

export function getSkillTree() {
  return request.get('/api/skills/tree')
}

export function getSkillTreeByCategory(category) {
  return request.get('/api/skills/tree', { params: { category } })
}

export function createSkill(data) {
  return request.post('/api/skills', data)
}

export function updateSkill(id, data) {
  return request.put(`/api/skills/${id}`, data)
}

export function deleteSkill(id) {
  return request.delete(`/api/skills/${id}`)
}