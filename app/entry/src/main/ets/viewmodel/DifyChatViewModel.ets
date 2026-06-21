import { ChatMessage } from '../model/ChatMessage'
import { DifyApi, StreamCallbacks, ChatResult } from '../http/DifyApi'
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
      'http://172.19.22.89/v1'
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
    const result: ChatResult = await this.difyApi.chatBlocking(content, this.conversationId)

    const aiMsg: ChatMessage = {
      role: 'assistant',
      content: result.answer,
      timestamp: Date.now()
    }
    this.messages.push(aiMsg)

    // 更新会话 ID
    if (result.conversationId) {
      this.conversationId = result.conversationId
      // 如果之前有临时 ID 的记录，更新为真实 ID
      await this.updateConversationId(result.conversationId)
    }

    await this.saveToHistory(content, result.answer)
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
        console.log('DifyChatViewModel streamingContent length:', this.streamingContent.length)
      },
      onComplete: async (convId: string) => {
        console.log('DifyChatViewModel onComplete, convId:', convId)
        console.log('DifyChatViewModel onComplete, streamingContent:', this.streamingContent)
        
        if (convId) {
          this.conversationId = convId
          await this.updateConversationId(convId)
        }
        
        const aiMsg: ChatMessage = {
          role: 'assistant',
          content: this.streamingContent,
          timestamp: Date.now()
        }
        this.messages.push(aiMsg)
        console.log('DifyChatViewModel onComplete, messages count:', this.messages.length)
        
        await this.saveToHistory(content, this.streamingContent)
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

    // 优先从本地存储加载消息
    if (record.messages && record.messages.length > 0) {
      try {
        const savedMessages = JSON.parse(record.messages) as ChatMessage[]
        this.messages = savedMessages
        console.log('DifyChatViewModel switchConversation: loaded from local storage, messages:', savedMessages.length)
      } catch (err) {
        console.error('DifyChatViewModel switchConversation: failed to parse saved messages:', err)
      }
    }

    // 如果本地没有消息，从 Dify 加载历史消息
    if (this.messages.length === 0) {
      const historyMessages = await this.difyApi.getConversationMessages(record.conversationId)

      if (historyMessages.length > 0) {
        this.messages = historyMessages
        // 保存到本地存储
        await this.saveMessagesToStorage(record.conversationId, historyMessages)
      } else {
        // 如果 Dify 没有返回历史消息，显示欢迎提示
        const welcomeMsg: ChatMessage = {
          role: 'assistant',
          content: `欢迎回来！继续"${record.title}"的对话`,
          timestamp: Date.now()
        }
        this.messages.push(welcomeMsg)
      }
    }

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
   * 将临时会话 ID 更新为 Dify 返回的真实 ID
   */
  private async updateConversationId(realConversationId: string): Promise<void> {
    // 查找是否有以 temp- 开头的记录
    const allConversations = await this.historyManager.getAllConversations()
    const tempRecord = allConversations.find(c => c.conversationId.startsWith('temp-'))

    if (tempRecord) {
      // 删除临时记录
      await this.historyManager.deleteConversation(tempRecord.conversationId)

      // 创建真实 ID 的记录，保留消息
      const newRecord = new ConversationRecord(
        realConversationId,
        tempRecord.title,
        tempRecord.lastMessage,
        tempRecord.timestamp,
        tempRecord.messageCount,
        tempRecord.messages
      )
      await this.historyManager.addOrUpdate(newRecord)
    }
  }

  /**
   * 保存会话到历史记录
   * @param userMessage 用户消息
   * @param aiReply AI 回复
   * @param realConversationId Dify 返回的真实会话 ID（可选）
   */
  private async saveToHistory(
    userMessage: string,
    aiReply: string,
    realConversationId?: string
  ): Promise<void> {
    const now = Date.now()

    // 生成标题（取用户消息的前 20 个字符）
    const title = userMessage.length > 20 ? userMessage.substring(0, 20) + '...' : userMessage

    // 确定要使用的会话 ID
    const targetConversationId = realConversationId || this.conversationId
    const isNewConversation = !targetConversationId

    // 保存当前消息到存储
    await this.saveMessagesToStorage(targetConversationId || 'temp-' + now, this.messages)

    if (isNewConversation) {
      // 新会话，创建记录（使用临时 ID，后续会更新）
      const tempId = 'temp-' + now
      const record = new ConversationRecord(
        tempId,
        title,
        aiReply.substring(0, 50) + (aiReply.length > 50 ? '...' : ''),
        now,
        this.messages.length,
        JSON.stringify(this.messages)
      )
      await this.historyManager.addOrUpdate(record)
      this.currentTitle = title
    } else {
      // 已有会话，更新记录
      const record = await this.historyManager.getConversation(targetConversationId)
      if (record) {
        record.lastMessage = aiReply.substring(0, 50) + (aiReply.length > 50 ? '...' : '')
        record.timestamp = now
        record.messageCount = this.messages.length
        record.messages = JSON.stringify(this.messages)
        await this.historyManager.addOrUpdate(record)
      }
    }

    await this.loadAllHistory()
  }

  /**
   * 保存消息到本地存储
   * @param conversationId 会话 ID
   * @param messages 消息列表
   */
  private async saveMessagesToStorage(conversationId: string, messages: ChatMessage[]): Promise<void> {
    try {
      const record = await this.historyManager.getConversation(conversationId)
      if (record) {
        record.messages = JSON.stringify(messages)
        await this.historyManager.addOrUpdate(record)
      } else {
        // 如果记录不存在，创建新记录
        const title = messages.length > 0 && messages[0].role === 'user'
          ? (messages[0].content.length > 20 ? messages[0].content.substring(0, 20) + '...' : messages[0].content)
          : '新对话'
        const lastMessage = messages.length > 0
          ? (messages[messages.length - 1].content.substring(0, 50) + (messages[messages.length - 1].content.length > 50 ? '...' : ''))
          : ''
        const newRecord = new ConversationRecord(
          conversationId,
          title,
          lastMessage,
          Date.now(),
          messages.length,
          JSON.stringify(messages)
        )
        await this.historyManager.addOrUpdate(newRecord)
      }
    } catch (err) {
      console.error('DifyChatViewModel saveMessagesToStorage failed:', err)
    }
  }
}
