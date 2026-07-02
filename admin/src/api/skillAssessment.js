import request from './request'

export function getAllAssessments() {
  return request.get('/skill-assessments')
}

export function getUserAssessments(userId) {
  return request.get(`/skill-assessments/user/${userId}`)
}

export function getAssessmentByNode(nodeId) {
  return request.get(`/skill-assessments/node/${nodeId}`)
}