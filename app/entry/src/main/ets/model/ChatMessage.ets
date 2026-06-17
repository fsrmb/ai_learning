export class ChatMessage {
  role: string = ''  // 'user' or 'assistant'
  content: string = ''
  timestamp: number = 0
}

export class ChatRequest {
  message: string = ''
  conversationId: string = ''
}

export class InterviewSession {
  id: number = 0
  status: string = ''
  questions: InterviewQuestion[] = []
  score: number = 0
}

export class InterviewQuestion {
  id: number = 0
  question: string = ''
  answer: string = ''
  score: number = 0
}
