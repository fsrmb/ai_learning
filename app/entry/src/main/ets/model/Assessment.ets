// 答题相关数据模型

// 难度选项
export class DifficultyOption {
  level: number = 0
  exp: number = 0
  description: string = ''
  color: string = ''
  passed: boolean = false
}

// 开始评估请求
export class StartAssessmentRequest {
  nodeId: number = 0
  difficulty: number = 0
}

// 答题问题
export class AssessmentQuestion {
  questionId: number = 0
  questionText: string = ''
  options: string[] = []
  difficulty: number = 0
}

// 开始评估响应
export class StartAssessmentResponse {
  assessmentId: number = 0
  nodeId: number = 0
  difficulty: number = 0
  questions: AssessmentQuestion[] = []
  passThreshold: number = 70
  totalQuestions: number = 5
}

// 答题项
export class AnswerItem {
  questionId: number = 0
  answer: string = ''
  timeSpent: number = 0
}

// 提交答案请求
export class SubmitAnswerRequest {
  answers: AnswerItem[] = []
  totalTime: number = 0
}

// 答题详情
export class AnswerDetail {
  questionId: number = 0
  userAnswer: string = ''
  correctAnswer: string = ''
  isCorrect: boolean = false
  explanation: string = ''
}

// 提交答案响应（评估结果）
export class AssessmentResult {
  assessmentId: number = 0
  correctCount: number = 0
  wrongCount: number = 0
  score: number = 0
  passed: boolean = false
  previousExp: number = 0
  newExp: number = 0
  expIncreased: boolean = false
  nodeCompleted: boolean = false
  details: AnswerDetail[] = []
}