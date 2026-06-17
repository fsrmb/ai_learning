import { http } from '@kit.NetworkKit'
import { TokenUtil } from "../common/TokenUtil"
/**
 * Dify 平台 API 封装
 * 包含两种调用模式：
 *   1. blocking（阻塞）— 等 AI 全部生成完再返回
 *   2. streaming（流式）— 逐步接收，打字机效果
 *
 * 使用方式：
 *   const api = new DifyApi('app-xxxxxxxxxxxx', 'http://10.0.2.2/v1')
 *   const reply = await api.chatBlocking('你好')          // 阻塞
 *   await api.chatStreaming('你好', (chunk) => { ... })   // 流式
 */

/** Dify 流式事件回调 */
export interface StreamCallbacks {
  /** 每收到一段文字时回调 */
  onChunk: (text: string) => void
  /** 流式结束时回调，conversationId 用于多轮对话 */
  onComplete: (conversationId: string) => void
  /** 出错时回调 */
  onError: (error: string) => void
}

export class DifyApi {
  private apiKey: string
  private baseUrl: string



  // 构造器
  constructor(apiKey: string, baseUrl: string) {
    this.apiKey = apiKey
    this.baseUrl = baseUrl
  }

  // ========================================
  // 阻塞模式（blocking）
  // ========================================

  /**
   * 阻塞式对话 — 等待 AI 完整生成后一次性返回
   * @param message 用户消息
   * @param conversationId 会话 ID，空字符串表示新会话
   * @returns AI 回复文本
   */
  async chatBlocking(message: string, conversationId: string = ''): Promise<string> {
    const httpRequest = http.createHttp()
    const context = getContext()

    console.log(message)
    try {
      const response = await httpRequest.request(
        `${this.baseUrl}/chat-messages`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`
          },
          extraData: {
            inputs:{},
            query: message,
            conversation_id: conversationId,
            response_mode: 'blocking',
            user: "user-123"
          },
          connectTimeout: 30000,
          readTimeout: 60000
        }
      )

      console.log(JSON.stringify(response))

      if (response.responseCode !== 200) {
        throw new Error(`HTTP ${response.responseCode}`)
      }

      const result = JSON.parse(response.result as string) as Record<string, Object>
      return (result['answer'] as string) || '未收到回复'
    } finally {
      httpRequest.destroy()
    }
  }

  // ========================================
  // 流式模式（streaming）
  // ========================================

  /**
   * 流式对话 — 逐步接收 AI 生成的文字片段
   * @param message 用户消息
   * @param conversationId 会话 ID
   * @param callbacks 回调函数（onChunk / onComplete / onError）
   */
  async chatStreaming(
    message: string,
    conversationId: string = '',
    callbacks: StreamCallbacks
  ): Promise<void> {
    const httpRequest = http.createHttp()
    let buffer: string = ''
    let resolved: boolean = false

    httpRequest.on('dataReceive', (data: ArrayBuffer) => {
      const chunk = this.arrayBufferToString(data)
      buffer += chunk

      // 按行分割，处理完整的 SSE 事件
      const lines = buffer.split('\n')
      buffer = lines.pop() || ''   // 最后一个可能不完整，留到下次

      for (const line of lines) {
        if (!line.startsWith('data: ')) continue

        const jsonStr = line.substring(6).trim()
        if (jsonStr === '[DONE]') continue

        try {
          const event = JSON.parse(jsonStr) as Record<string, Object>
          const eventType = event['event'] as string

          if (eventType === 'message') {
            // 每收到一段文字，回调通知
            const answer = event['answer'] as string || ''
            callbacks.onChunk(answer)
          } else if (eventType === 'message_end') {
            // 流式结束，提取 conversation_id
            const convId = event['conversation_id'] as string || ''
            callbacks.onComplete(convId)
            resolved = true
          }
        } catch {
          // 忽略解析失败的行
        }
      }
    })

    httpRequest.on('dataEnd', () => {
      if (!resolved) {
        callbacks.onComplete('')
      }
    })

    // 发起请求（错误通过 .catch 处理，http 模块没有 'error' 事件）
    httpRequest.request(`${this.baseUrl}/chat-messages`, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`
      },
      extraData: JSON.stringify({
        query: message,
        conversation_id: conversationId,
        response_mode: 'streaming',
        user: 'student-001'
      }),
      connectTimeout: 30000,
      readTimeout: 120000
    }).catch((err: object) => {
      callbacks.onError(String(err))
    })
  }

  // ========================================
  // 工具方法
  // ========================================

  private arrayBufferToString(buffer: ArrayBuffer): string {
    const uint8Array = new Uint8Array(buffer)
    let result = ''
    for (let i = 0; i < uint8Array.length; i++) {
      result += String.fromCharCode(uint8Array[i])
    }
    return result
  }
}
