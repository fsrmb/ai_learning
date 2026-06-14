import axios from 'axios'

const instance = axios.create({
  baseURL: process.env.VUE_APP_API_BASE_URL || 'https://api.example.com',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json;charset=UTF-8'
  }
})

instance.interceptors.request.use(
  config => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`
    }
    return config
  },
  error => {
    console.error('请求配置错误:', error)
    return Promise.reject(error)
  }
)

instance.interceptors.response.use(
  response => {
    const { code, message, data } = response.data
    
    if (code === 200 || code === 0) {
      return data
    } else {
      console.error('业务错误:', message)
      return Promise.reject(new Error(message || '操作失败'))
    }
  },
  error => {
    console.error('响应错误:', error)
    
    if (error.response) {
      const { status, data } = error.response
      
      switch (status) {
        case 401:
          console.error('未授权，请重新登录')
          localStorage.removeItem('token')
          window.location.href = '/login'
          break
        case 403:
          console.error('权限不足')
          break
        case 404:
          console.error('请求资源不存在')
          break
        case 500:
          console.error('服务器内部错误')
          break
        default:
          console.error(`请求失败，状态码: ${status}`)
      }
      
      return Promise.reject(data?.message || error.message)
    } else if (error.request) {
      console.error('请求超时或网络异常')
      return Promise.reject(new Error('网络异常，请检查网络连接'))
    } else {
      console.error('请求配置错误:', error.message)
      return Promise.reject(error)
    }
  }
)

export default instance
