import request from './request'

export function getDashboardData() {
  return request.get('/dashboard')
}

export function getUserAiStats(params) {
  return request.get('/dashboard/user-ai-stats', { params })
}