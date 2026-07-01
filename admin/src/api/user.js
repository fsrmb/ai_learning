// api/user.js - 用户相关接口
// 提供用户信息查询、用户列表等功能的 API 调用

import request from './request'

/**
 * 获取当前登录用户信息
 * @returns {Promise<Object>} 返回当前用户信息
 */
export function getCurrentUser() {
  return request.get('/users/me')
}

/**
 * 获取单个用户信息
 * @param {number} id - 用户 ID
 * @returns {Promise<Object>} 返回用户信息
 */
export function getUserById(id) {
  return request.get(`/users/${id}`)
}

/**
 * 更新用户信息
 * @param {number} id - 用户 ID
 * @param {Object} data - 更新数据
 * @returns {Promise<Object>} 返回更新结果
 */
export function updateUser(id, data) {
  return request.put(`/users/${id}`, data)
}

/**
 * 删除用户
 * @param {number} id - 用户 ID
 * @returns {Promise<Object>} 返回删除结果
 */
export function deleteUser(id) {
  return request.delete(`/users/${id}`)
}

export function createUser(data) {
  return request.post('/users', data)
}

/**
 * 获取用户列表
 * @param {Object} params - 查询参数
 * @param {string} params.keyword - 关键词（用户名/昵称）
 * @param {string} params.role - 角色筛选
 * @returns {Promise<Object>} 返回用户列表
 * @description 调用后端 API 获取真实数据库数据
 */
export function getUserList(params) {
  return request.get('/users', { params })
}

/**
 * 更新用户角色
 * @param {number} id - 用户 ID
 * @param {string} role - 新角色
 * @returns {Promise<Object>} 返回更新结果
 */
export function updateUserRole(id, role) {
  return request.put(`/users/${id}/role`, { role })
}