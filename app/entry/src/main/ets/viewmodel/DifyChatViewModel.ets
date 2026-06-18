import { ChatMessage } from '../model/ChatMessage'
import { DifyApi, StreamCallbacks } from '../http/DifyApi'
import { Constants } from '../common/Constants'
import { ConversationHistory, ConversationRecord } from '../common/ConversationHistory'
import { Context } from '@kit.AbilityKit'

/**
 * Dify 聊天 ViewModel
 *
 * 与 ChatViewModel 的区别：
 *   - ChatViewModel → 调用后端 /api/ai/chat/message（Spring AI，第三周才讲）
 *   - DifyChatViewModel → 直接调用 Dify 平台 API（Day 5 已搭建）
 *
 * 支持两种模式：
 *   - blocking：同步等待，代码简单
 *   - streaming：流式输出，打字机效果（默认）
 *
 * 会话管理：
 *   - 支持多会话切换
 *   - 历史记录持久化存储（Preferences）
 */

@Observed
export class DifyChatViewModel {
  messages: ChatMessage[] = []
  sending: boolean = false
  streamingContent: string = ''
  conversationId: string = ''
  currentTitle: string = ''

  // 对话历史列表（从持久化存储加载）
  history: ConversationRecord[] = []

  // 模式切换：'blocking' 或 'streaming'
  mode: string = 'streaming'

  private difyApi: DifyApi
  private historyManager: ConversationHistory

  constructor() {
    this.difyApi = new DifyApi(
      'app-b3e3vd7rYn1PEThoxkGBB7Kf',
      'http://192.168.100.101/v1'
    )
    this.historyManager = ConversationHistory.getInstance()
  }

  /**
   * 初始化历史记录管理器
   */
  async initHistory(context: Context): Promise<void> {
    await this.historyManager.init(context)
    await this.loadAllHistory()
  }

  /**
   * 加载所有历史会话
   */
  async loadAllHistory(): Promise<void> {
    this.history = await this.historyManager.getAllConversations()
  }

  // ========================================
  // 发送消息（根据 mode 自动选择 blocking / streaming）
  // ========================================

  async sendMessage(content: string): Promise<void> {
    // ① 添加用户消息
    const userMsg: ChatMessage = {
      role: 'user',
      content: content,
      timestamp: Date.now()
    }
    this.messages.push(userMsg)

    // ② 调用 Dify
    this.sending = true
    this.streamingContent = ''

    try {
      if (this.mode === 'blocking') {
        await this.sendBlocking(content)
      } else {
        await this.sendStreaming(content)
      }
    } catch (err) {
      console.error('DifyChatViewModel sendMessage failed:', err)
      const errMsg: ChatMessage = {
        role: 'assistant',
        content: `请求失败：${String(err)}`,
        timestamp: Date.now()
      }
      this.messages.push(errMsg)
    } finally {
      this.sending = false
      this.streamingContent = ''
    }
  }

  // ========================================
  // 阻塞模式
  // ========================================

  private async sendBlocking(content: string): Promise<void> {
    const reply = await this.difyApi.chatBlocking(content, this.conversationId)

    const aiMsg: ChatMessage = {
      role: 'assistant',
      content: reply,
      timestamp: Date.now()
    }
    this.messages.push(aiMsg)
    await this.saveToHistory(content, reply)
  }

  // ========================================
  // 流式模式
  // ========================================

  private async sendStreaming(content: string): Promise<void> {
    console.log('DifyChatViewModel sendStreaming starting...')

    const callbacks: StreamCallbacks = {
      onChunk: (text: string) => {
        console.log('DifyChatViewModel onChunk:', text)
        this.streamingContent += text
      },
      onComplete: (convId: string) => {
        console.log('DifyChatViewModel onComplete, convId:', convId)
        if (convId) {
          this.conversationId = convId
        }
        const aiMsg: ChatMessage = {
          role: 'assistant',
          content: this.streamingContent,
          timestamp: Date.now()
        }
        this.messages.push(aiMsg)
        this.saveToHistory(content, this.streamingContent)
      },
      onError: (error: string) => {
        console.error('DifyChatViewModel onError:', error)
        const errMsg: ChatMessage = {
          role: 'assistant',
          content: `请求失败：${error}`,
          timestamp: Date.now()
        }
        this.messages.push(errMsg)
      }
    }

    await this.difyApi.chatStreaming(content, this.conversationId, callbacks)
  }

  // ========================================
  // 会话管理
  // ========================================

  /** 清空所有消息和会话 */
  async clearMessages(): Promise<void> {
    this.messages = []
    this.streamingContent = ''
    if (this.conversationId) {
      await this.historyManager.deleteConversation(this.conversationId)
    }
    this.conversationId = ''
    this.currentTitle = ''
    await this.loadAllHistory()
  }

  /** 新建对话（重置会话 ID） */
  async newConversation(): Promise<void> {
    this.messages = []
    this.streamingContent = ''
    this.conversationId = ''
    this.currentTitle = ''
  }

  /** 切换 blocking / streaming 模式 */
  toggleMode(): void {
    this.mode = this.mode === 'blocking' ? 'streaming' : 'blocking'
  }

  /**
   * 切换到指定历史会话
   */
  async switchConversation(record: ConversationRecord): Promise<void> {
    this.messages = []
    this.conversationId = record.conversationId
    this.currentTitle = record.title

    const welcomeMsg: ChatMessage = {
      role: 'assistant',
      content: `欢迎回来！继续"${record.title}"的对话`,
      timestamp: Date.now()
    }
    this.messages.push(welcomeMsg)

    // 更新历史记录的时间戳（标记为最新）
    await this.historyManager.updateLastMessage(
      record.conversationId,
      record.lastMessage,
      Date.now()
    )
    await this.loadAllHistory()
  }

  /**
   * 删除指定历史会话
   */
  async deleteConversation(record: ConversationRecord): Promise<void> {
    await this.historyManager.deleteConversation(record.conversationId)
    await this.loadAllHistory()

    // 如果删除的是当前会话，重置
    if (this.conversationId === record.conversationId) {
      this.conversationId = ''
      this.currentTitle = ''
      this.messages = []
    }
  }

  // ========================================
  // 历史记录管理（持久化存储）
  // ========================================

  /**
   * 保存会话到历史记录
   */
  private async saveToHistory(userMessage: string, aiReply: string): Promise<void> {
    const now = Date.now()

    // 生成标题（取用户消息的前 20 个字符）
    const title = userMessage.length > 20 ? userMessage.substring(0, 20) + '...' : userMessage

    if (!this.conversationId) {
      // 新会话，创建记录
      const record = new ConversationRecord(
        'temp-' + now,
        title,
        aiReply.substring(0, 50) + (aiReply.length > 50 ? '...' : ''),
        now,
        this.messages.length
      )
      await this.historyManager.addOrUpdate(record)
      this.currentTitle = title
    } else {
      // 已有会话，更新记录
      const record = await this.historyManager.getConversation(this.conversationId)
      if (record) {
        record.lastMessage = aiReply.substring(0, 50) + (aiReply.length > 50 ? '...' : '')
        record.timestamp = now
        record.messageCount = this.messages.length
        await this.historyManager.addOrUpdate(record)
      }
    }

    await this.loadAllHistory()
  }
}
