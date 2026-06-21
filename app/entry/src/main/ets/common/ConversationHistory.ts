import preferences from '@ohos.data.preferences'
import { Context } from '@kit.AbilityKit'

/**
 * 会话历史记录项
 */
export class ConversationRecord {
  conversationId: string = ''
  title: string = ''
  lastMessage: string = ''
  timestamp: number = 0
  messageCount: number = 0

  constructor(
    conversationId: string = '',
    title: string = '',
    lastMessage: string = '',
    timestamp: number = 0,
    messageCount: number = 0
  ) {
    this.conversationId = conversationId
    this.title = title
    this.lastMessage = lastMessage
    this.timestamp = timestamp
    this.messageCount = messageCount
  }
}

/**
 * 会话历史记录管理类
 * 使用 Preferences 持久化存储会话列表
 */
export class ConversationHistory {
  private static instance: ConversationHistory | null = null
  private pref: preferences.Preferences | null = null
  private prefName: string = 'conversation_history'
  private listKey: string = 'conversation_list'
  private maxHistory: number = 50

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): ConversationHistory {
    if (!ConversationHistory.instance) {
      ConversationHistory.instance = new ConversationHistory()
    }
    return ConversationHistory.instance
  }

  /**
   * 初始化 Preferences
   */
  async init(context: Context): Promise<void> {
    if (this.pref) return
    try {
      this.pref = await preferences.getPreferences(context, this.prefName)
    } catch (err) {
      console.error('ConversationHistory init failed:', err)
      throw new Error('Failed to initialize preferences')
    }
  }

  /**
   * 获取所有历史会话列表
   */
  async getAllConversations(): Promise<ConversationRecord[]> {
    if (!this.pref) return []
    try {
      const json = await this.pref.get(this.listKey, '[]') as string
      const list = JSON.parse(json) as ConversationRecord[]
      // 按时间戳降序排列（最新的在前）
      list.sort((a, b) => b.timestamp - a.timestamp)
      return list
    } catch (err) {
      console.error('ConversationHistory getAllConversations failed:', err)
      return []
    }
  }

  /**
   * 添加或更新会话记录
   */
  async addOrUpdate(record: ConversationRecord): Promise<void> {
    if (!this.pref) return
    try {
      const list = await this.getAllConversations()
      const index = list.findIndex(item => item.conversationId === record.conversationId)
      
      if (index >= 0) {
        // 更新现有记录
        list[index] = record
      } else {
        // 添加新记录
        list.unshift(record)
      }

      // 限制最大记录数
      if (list.length > this.maxHistory) {
        list.splice(this.maxHistory)
      }

      // 保存到 Preferences
      await this.pref.put(this.listKey, JSON.stringify(list))
      await this.pref.flush()
    } catch (err) {
      console.error('ConversationHistory addOrUpdate failed:', err)
    }
  }

  /**
   * 删除指定会话记录
   */
  async deleteConversation(conversationId: string): Promise<void> {
    if (!this.pref) return
    try {
      const list = await this.getAllConversations()
      const filtered = list.filter(item => item.conversationId !== conversationId)
      await this.pref.put(this.listKey, JSON.stringify(filtered))
      await this.pref.flush()
    } catch (err) {
      console.error('ConversationHistory deleteConversation failed:', err)
    }
  }

  /**
   * 删除所有历史记录
   */
  async clearAll(): Promise<void> {
    if (!this.pref) return
    try {
      await this.pref.put(this.listKey, '[]')
      await this.pref.flush()
    } catch (err) {
      console.error('ConversationHistory clearAll failed:', err)
    }
  }

  /**
   * 获取指定会话记录
   */
  async getConversation(conversationId: string): Promise<ConversationRecord | undefined> {
    const list = await this.getAllConversations()
    return list.find(item => item.conversationId === conversationId)
  }

  /**
   * 更新会话的最后一条消息
   */
  async updateLastMessage(conversationId: string, message: string, timestamp: number): Promise<void> {
    const record = await this.getConversation(conversationId)
    if (record) {
      record.lastMessage = message
      record.timestamp = timestamp
      record.messageCount++
      await this.addOrUpdate(record)
    }
  }

  /**
   * 更新会话标题（通常取第一条消息作为标题）
   */
  async updateTitle(conversationId: string, title: string): Promise<void> {
    const record = await this.getConversation(conversationId)
    if (record && !record.title) {
      record.title = title
      await this.addOrUpdate(record)
    }
  }
}
