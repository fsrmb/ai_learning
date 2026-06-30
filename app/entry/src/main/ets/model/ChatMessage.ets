export class ChatMessage {
  role: string = ''
  content: string = ''
  timestamp: number = 0
  isStreaming: boolean = false

  constructor(role?: string, content?: string, isStreaming?: boolean) {
    if (role) this.role = role
    if (content) this.content = content
    if (isStreaming !== undefined) this.isStreaming = isStreaming
    this.timestamp = Date.now()
  }
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
