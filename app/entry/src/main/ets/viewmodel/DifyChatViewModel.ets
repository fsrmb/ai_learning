import { ChatMessage } from '../model/ChatMessage'
import { DifyApi } from '../http/DifyApi'

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
 */

// 对话会话（历史记录用）
export class Conversation {
  id: string = ''
  title: string = ''
  createdAt: number = 0
  messageCount: number = 0
}

@Observed
export class DifyChatViewModel {
  messages: ChatMessage[] = []
  sending: boolean = false
  // 流式输出
  streamingContent: string = ''
  // 会话ID， 传了会话ID，多轮对话
  conversationId: string = ''

  // 对话历史列表
  history: Conversation[] = []
  showHistory: boolean = false

  // 模式切换：'blocking' 或 'streaming'
  mode: string = 'streaming'

  private difyApi: DifyApi

  constructor() {
    // TODO: 替换为你自己的 Dify API Key 和地址
    this.difyApi = new DifyApi(
      'app-X0fv7zO7CmnXfWmM105irTRN',
      'http://172.20.10.3/v1'
    )
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
    // 页面中直接显示
    this.messages.push(userMsg)

    // ② 调用 Dify
    this.sending = true
    // 逐步拼接每次返回数据值
    this.streamingContent = ''

    try {
      if (this.mode === 'blocking') {
        await this.sendBlocking(content)
      } else {
        await this.sendStreaming(content)
      }
    } catch (err) {
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

    //
    const aiMsg: ChatMessage = {
      role: 'assistant',
      content: reply,
      timestamp: Date.now()
    }
    //
    this.messages.push(aiMsg)
    this.saveToHistory(content)
  }

  // ========================================
  // 流式模式
  // ========================================

  private async sendStreaming(content: string): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      this.difyApi.chatStreaming(content, this.conversationId, {
        onChunk: (text: string) => {
          // 每收到一段文字，实时更新 streamingContent
          // @Observed 会自动触发 UI 刷新
          this.streamingContent += text
        },
        onComplete: (convId: string) => {
          // 流式结束，将完整内容作为一条 AI 消息加入列表
          if (convId) {
            this.conversationId = convId
          }
          const aiMsg: ChatMessage = {
            role: 'assistant',
            content: this.streamingContent,
            timestamp: Date.now()
          }
          this.messages.push(aiMsg)
          this.saveToHistory(content)
          resolve()
        },
        onError: (error: string) => {
          reject(new Error(error))
        }
      })
    })
  }

  // ========================================
  // 会话管理
  // ========================================

  /** 清空所有消息和会话 */
  clearMessages(): void {
    this.messages = []
    this.streamingContent = ''
    this.conversationId = ''
  }

  /** 新建对话（重置会话 ID，但不清消息） */
  newConversation(): void {
    this.conversationId = ''
  }

  /** 切换 blocking / streaming 模式 */
  toggleMode(): void {
    this.mode = this.mode === 'blocking' ? 'streaming' : 'blocking'
  }

  /** 切换历史面板显示 */
  toggleHistory(): void {
    this.showHistory = !this.showHistory
  }

  /** 加载历史对话 */
  loadHistory(conv: Conversation): void {
    this.messages = []
    this.conversationId = ''
    this.showHistory = false

    const tipMsg: ChatMessage = {
      role: 'assistant',
      content: `已切换到对话：${conv.title}\n（后端接口实现后会加载完整历史消息）`,
      timestamp: Date.now()
    }
    this.messages.push(tipMsg)
  }

  // ========================================
  // 历史记录（内存模拟）存储在前端模拟，  后端设计的数据库，或者是直接依赖Dify
  // ========================================

  private saveToHistory(content: string): void {
    const title = content.length > 20 ? content.substring(0, 20) + '...' : content

    if (!this.conversationId) {
      const conv: Conversation = {
        id: Date.now().toString(),
        title: title,
        createdAt: Date.now(),
        messageCount: this.messages.length
      }
      this.history.unshift(conv)
    } else if (this.history.length > 0) {
      this.history[0].messageCount = this.messages.length
    }
  }
}
