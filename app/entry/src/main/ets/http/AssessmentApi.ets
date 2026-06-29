import { HttpClient } from './HttpClient'
import {
  DifficultyOption,
  StartAssessmentRequest,
  StartAssessmentResponse,
  SubmitAnswerRequest,
  AssessmentResult
} from '../model/Assessment'

export class AssessmentApi {
  // 获取难度选项
  static async getDifficultyOptions(nodeId: number): Promise<DifficultyOption[]> {
    return HttpClient.get<DifficultyOption[]>(`/api/arkts/assessments/difficulty-options/${nodeId}`)
  }

  // 开始评估
  static async startAssessment(request: StartAssessmentRequest): Promise<StartAssessmentResponse> {
    return HttpClient.post<StartAssessmentResponse>('/api/arkts/assessments/start', request)
  }

  // 提交答案
  static async submitAnswer(assessmentId: number, request: SubmitAnswerRequest): Promise<AssessmentResult> {
    return HttpClient.post<AssessmentResult>(`/api/arkts/assessments/${assessmentId}/submit`, request)
  }
}