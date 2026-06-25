import { ChatMessage } from '../model/ChatMessage'
import { ResumeApi } from '../http/ResumeApi'
import { ConversationHistory, ConversationRecord } from '../common/ConversationHistory'
import { Context } from '@kit.AbilityKit'

@Observed
export class ResumeOptimizeViewModel {
  messages: ChatMessage[] = []
  sending: boolean = false
  currentTitle: string = ''
  history: ConversationRecord[] = []

  private historyManager: ConversationHistory

  constructor() {
    this.historyManager = ConversationHistory.getInstance()
  }

  async initHistory(context: Context): Promise<void> {
    await this.historyManager.init(context)
    await this.loadAllHistory()
  }

  async loadAllHistory(): Promise<void> {
    this.history = await this.historyManager.getAllConversations()
  }

  /**
   * 发送简历进行优化
   * 调用工作流 API（/v1/workflows/run），工作流内部完成评分→分支→优化
   */
  async sendResume(content: string, fileUri?: string): Promise<void> {
    const userMsg: ChatMessage = {
      role: 'user',
      content: fileUri ? `📎 ${fileUri.split('/').pop()}\n${content}` : content,
      timestamp: Date.now()
    }
    this.messages.push(userMsg)

    this.sending = true

    try {
      const processingMsg: ChatMessage = {
        role: 'assistant',
        content: '🔍 正在分析并优化简历...',
        timestamp: Date.now()
      }
      this.messages.push(processingMsg)

      // 调用工作流 API，工作流内部完成所有步骤
      const optimizedResume: string = await ResumeApi.optimizeResume(content, fileUri)

      this.messages.pop()

      const aiMsg: ChatMessage = {
        role: 'assistant',
        content: optimizedResume,
        timestamp: Date.now()
      }
      this.messages.push(aiMsg)

      this.currentTitle = content.substring(0, 20) + (content.length > 20 ? '...' : '')

      await this.saveToHistory(content, optimizedResume)

    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : '优化失败'
      console.error(`ResumeOptimizeViewModel sendResume error: ${errorMessage}`)

      const errorMsg: ChatMessage = {
        role: 'assistant',
        content: `❌ ${errorMessage}`,
        timestamp: Date.now()
      }
      this.messages.push(errorMsg)
    } finally {
      this.sending = false
    }
  }

  async newConversation(): Promise<void> {
    this.messages = []
    this.currentTitle = ''
  }

  async switchConversation(record: ConversationRecord): Promise<void> {
    this.messages = []
    this.currentTitle = record.title

    if (record.messages && record.messages.length > 0) {
      try {
        const savedMessages: ChatMessage[] = JSON.parse(record.messages) as ChatMessage[]
        this.messages = savedMessages
      } catch (err) {
        console.error('ResumeOptimizeViewModel switchConversation: failed to parse saved messages:', err)
      }
    }

    if (this.messages.length === 0) {
      const welcomeMsg: ChatMessage = {
        role: 'assistant',
        content: `欢迎回来！继续"${record.title}"的简历优化`,
        timestamp: Date.now()
      }
      this.messages.push(welcomeMsg)
    }

    await this.historyManager.updateLastMessage(
      record.conversationId,
      record.lastMessage,
      Date.now()
    )
    await this.loadAllHistory()
  }

  async deleteConversation(record: ConversationRecord): Promise<void> {
    await this.historyManager.deleteConversation(record.conversationId)
    await this.loadAllHistory()
  }

  private async saveToHistory(userMessage: string, aiReply: string): Promise<void> {
    const now: number = Date.now()
    const title: string = userMessage.length > 20 ? userMessage.substring(0, 20) + '...' : userMessage

    const record: ConversationRecord = new ConversationRecord(
      'resume-' + now,
      title,
      aiReply.substring(0, 50) + (aiReply.length > 50 ? '...' : ''),
      now,
      this.messages.length,
      JSON.stringify(this.messages)
    )
    await this.historyManager.addOrUpdate(record)
    await this.loadAllHistory()
  }
}