// api/user.js - 用户相关接口
// 提供用户信息查询、用户列表等功能的 API 调用

import request from './request'

/**
 * 获取当前登录用户信息
 * @returns {Promise<Object>} 返回当前用户信息
 */
export function getCurrentUser() {
  return request.get('/api/users/me')
}

/**
 * 生成 Mock 用户数据
 * @param {number} count - 生成数量
 * @returns {Array} Mock 用户列表
 */
function generateMockUsers(count = 100) {
  const roles = ['admin', 'user', 'guest']
  const users = []
  for (let i = 1; i <= count; i++) {
    const role = roles[Math.floor(Math.random() * roles.length)]
    users.push({
      id: i,
      username: `user${i}`,
      nickname: `用户${i}`,
      email: `user${i}@example.com`,
      role: role,
      status: Math.random() > 0.15 ? 1 : 0,
      createTime: `2024-01-${String(Math.floor(Math.random() * 30) + 1).padStart(2, '0')} 10:30:00`
    })
  }
  return users
}

/**
 * 获取用户列表
 * @param {Object} params - 查询参数
 * @param {number} params.page - 页码
 * @param {number} params.size - 每页数量
 * @param {string} params.keyword - 关键词（用户名/昵称/邮箱）
 * @param {string} params.role - 角色筛选
 * @returns {Promise<Object>} 返回用户列表和分页信息
 * @description 调用后端 API，如果失败则返回 Mock 数据兜底
 */
export function getUserList(params) {
  return request.get('/api/users', { params }).catch((error) => {
    console.warn('API 请求失败，使用 Mock 数据兜底:', error)
    
    // 生成 Mock 数据
    const allUsers = generateMockUsers(100)
    
    // 关键词过滤
    let filtered = [...allUsers]
    if (params.keyword) {
      const keyword = params.keyword.toLowerCase()
      filtered = filtered.filter(user => 
        user.username.toLowerCase().includes(keyword) ||
        user.nickname.toLowerCase().includes(keyword) ||
        user.email.toLowerCase().includes(keyword)
      )
    }
    
    // 角色过滤
    if (params.role) {
      filtered = filtered.filter(user => user.role === params.role)
    }
    
    // 分页处理
    const page = params.page || 1
    const size = params.size || 10
    const start = (page - 1) * size
    const end = start + size
    const list = filtered.slice(start, end)
    
    return {
      list,
      total: filtered.length
    }
  })
}

/**
 * 更新用户角色
 * @param {number} id - 用户 ID
 * @param {string} role - 新角色
 * @returns {Promise<Object>} 返回更新结果
 */
export function updateUserRole(id, role) {
  return request.put(`/api/users/${id}/role`, { role })
}