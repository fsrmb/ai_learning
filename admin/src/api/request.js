import axios from 'axios'
import { ElMessage } from 'element-plus'
import { getToken } from '../utils/token'

const service = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,  // 从环境变量读取
  timeout: 15000,                                // 请求超时 15 秒
  headers: { 'Content-Type': 'application/json' },
})

// ---- 请求拦截器：自动注入 Bearer Token，检查 Token 有效性 ----
service.interceptors.request.use(
  (config) => {
    const token = getToken()
    console.log('[Request Interceptor] Token:', token, 'Type:', typeof token)
    if (token && config.headers) {
      console.log('[Request Interceptor] Token starts with invalid-:', token.startsWith('invalid-'))
      if (token.startsWith('invalid-')) {
          // 模拟 Token 无效，直接处理 401 逻辑
          console.log('[Request Interceptor] Invalid token detected, redirecting to login')
          localStorage.removeItem('ai_companion_token')
          ElMessage.error('授权认证失败，请重新登录')
          setTimeout(() => {
            window.location.href = '/login'
          }, 1500)
          return Promise.reject(new Error('Unauthorized'))
        }
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => Promise.reject(error),
)

// ---- 响应拦截器：解包 ApiResponse，统一处理错误 ----
service.interceptors.response.use(
  (response) => {
    const res = response.data

    // 不是标准 ApiResponse 格式，直接返回
    if (res.code === undefined) {
      return response
    }

    // 成功：解包返回 data 字段
    if (res.code === 200 || res.code === 0) {
      return res.data
    }

    // 业务层 401：Token 无效或过期（后端返回 code: 401）
    if (res.code === 401) {
      ElMessage.error('授权认证失败，请重新登录')
      localStorage.removeItem('ai_companion_token')
      return Promise.reject(new Error('Unauthorized'))
    }

    // 业务错误（code 非 200）
    ElMessage.error(res.message || '请求失败')
    return Promise.reject(new Error(res.message || '请求失败'))
  },
  (error) => {
    const status = error.response?.status

    if (status === 401) {
      // Token 过期或无效，授权认证失败
      ElMessage.error('授权认证失败，请重新登录')
      localStorage.removeItem('ai_companion_token')
      // 不直接跳转，让上层逻辑（路由守卫）处理
    } else if (status === 403) {
      // 没有权限
      ElMessage.error('没有权限访问该资源')
    } else if (status === 500) {
      // 服务器错误
      ElMessage.error('服务器内部错误，请稍后再试')
    } else {
      // 其他错误
      ElMessage.error(error.response?.data?.message || error.message || '网络错误')
    }

    return Promise.reject(error)
  },
)

export default service
 