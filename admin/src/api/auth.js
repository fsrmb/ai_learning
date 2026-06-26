// api/auth.js - 认证相关接口
// 提供登录、登出等认证功能的 API 调用

import request from './request'

/**
 * 用户登录
 * @param {Object} data - 登录表单数据
 * @param {string} data.username - 用户名
 * @param {string} data.password - 密码
 * @returns {Promise<Object>} 返回登录结果，包含 token 和用户信息
 */
export function login(data) {
  return request.post('/auth/login', data)
}

/**
 * 用户注册
 * @param {Object} data - 注册表单数据
 * @param {string} data.username - 用户名
 * @param {string} data.password - 密码
 * @returns {Promise<Object>} 返回注册结果
 */
export function register(data) {
  return request.post('/auth/register', data)
}

/**
 * 用户登出
 * @returns {Promise<Object>} 返回登出结果
 */
export function logout() {
  return request.post('/auth/logout')
}
