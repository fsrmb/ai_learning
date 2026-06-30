// stores/user.js - 用户状态管理
// 使用 Pinia 管理全局用户状态，包括登录认证、用户信息、Token 持久化

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { getCurrentUser } from '../api/user'      // 用户信息接口
import { login as loginApi, register as registerApi } from '../api/auth.js'    // 登录和注册接口
import { setToken, removeToken, getToken } from '../utils/token'  // Token 工具函数

/**
 * 用户状态管理 Store
 * 使用 Pinia 的 setup 模式定义，提供响应式状态和操作方法
 */
export const useUserStore = defineStore('user', () => {
  // ---- State（状态）----
  
  /** 当前用户信息对象，包含 id、username、nickname、role 等字段 */
  const user = ref(null)
  
  /** 
   * JWT Token，用于接口鉴权
   * 初始化时从 localStorage 恢复，实现页面刷新后保持登录状态
   */
  const token = ref(getToken())

  // ---- Getters（计算属性）----
  
  /** 判断用户是否已登录，通过检测 Token 是否存在 */
  const isLoggedIn = computed(() => !!token.value)
  
  /** 判断当前用户是否为管理员，通过检测 user.role 是否为 'admin' */
  const isAdmin = computed(() => user.value?.role === 'ADMIN')

  // ---- Actions（操作方法）----
  
  /**
   * 用户登录操作
   * @param {Object} data - 登录表单数据
   * @param {string} data.username - 用户名
   * @param {string} data.password - 密码
   * @returns {Promise<void>}
   * @description 调用登录接口获取 Token 和用户信息，
   *              将 Token 存储到 localStorage 和 Pinia 状态中，
   *              如果登录响应包含用户信息则直接使用，否则单独调用用户信息接口
   */
  async function login(data) {
    const res = await loginApi(data)
    
    const loginData = res.data || res
    
    token.value = loginData.token
    setToken(loginData.token)
    
    if (loginData.user) {
      user.value = loginData.user
    } else {
      await fetchUserInfo()
    }
  }

  /**
   * 获取当前用户详细信息
   * @returns {Promise<void>}
   * @description 调用用户信息接口，将返回的数据保存到 user 状态中
   *              响应已被拦截器解包为用户对象
   */
  async function fetchUserInfo() {
    const res = await getCurrentUser()
    user.value = res.data || res
  }

  /**
   * 用户登出操作
   * @returns {void}
   * @description 清空用户信息和 Token，同时清除 localStorage 中的 Token
   */
  function logout() {
    // 清空用户信息状态
    user.value = null
    
    // 清空 Token 状态
    token.value = null
    
    // 清除 localStorage 中的 Token
    removeToken()
  }

  /**
   * 用户注册操作
   * @param {Object} data - 注册表单数据
   * @param {string} data.username - 用户名
   * @param {string} data.password - 密码
   * @param {string} data.email - 邮箱（可选）
   * @returns {Promise<void>}
   * @description 调用注册接口，注册成功后返回，不自动登录
   */
  async function register(data) {
    await registerApi(data)
  }

  // 返回所有需要暴露的状态和方法，供组件使用
  return { user, token, isLoggedIn, isAdmin, login, fetchUserInfo, logout, register }
})