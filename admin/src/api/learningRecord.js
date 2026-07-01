import request from './request'

export function getLearningRecordList(params) {
  return request.get('/learning-records', { params })
}

export function getLearningRecordById(id) {
  return request.get(`/learning-records/${id}`)
}

export function createLearningRecord(data) {
  return request.post('/learning-records', data)
}

export function updateLearningRecord(id, data) {
  return request.put(`/learning-records/${id}`, data)
}

export function deleteLearningRecord(id) {
  return request.delete(`/learning-records/${id}`)
}

export function getLearningRecordsByUserId(userId) {
  return request.get(`/learning-records/user/${userId}`)
}