import { http } from '@kit.NetworkKit'
import { TokenUtil } from "../common/TokenUtil"

/**
 * Dify 流式事件回调接口
 */
export interface StreamCallbacks {
  /** 每收到一段文字时回调 */
  onChunk: (text: string) => void
  /** 流式结束时回调，conversationId 用于多轮对话 */
  onComplete: (conversationId: string) => void
  /** 出错时回调 */
  onError: (error: string) => void
}

/**
 * Dify 平台 API 封装
 * 包含两种调用模式：
 *   1. blocking（阻塞）— 等 AI 全部生成完再返回
 *   2. streaming（流式）— 逐步接收，打字机效果
 */
export class DifyApi {
  private apiKey: string
  private baseUrl: string

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

    console.log('DifyApi chatBlocking:', message)
    try {
      const username = await TokenUtil.getUsername()
      const response = await httpRequest.request(
        `${this.baseUrl}/chat-messages`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`
          },
          extraData: {
            // 必须保留 inputs.text 字段，Dify 平台依赖此字段解析消息
            inputs: {
              text: message
            },
            query:message,
            conversation_id: conversationId,
            response_mode: 'blocking',
            user: 'user-' + (username || 'default')
          },
          connectTimeout: 15000,
          readTimeout: 30000
        }
      )

      console.log('DifyApi chatBlocking response:', JSON.stringify(response))

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
    const username = await TokenUtil.getUsername()
    const httpRequest = http.createHttp()

    console.log('DifyApi chatStreaming sending request...')

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
            // 必须保留 inputs.text 字段，Dify 平台依赖此字段解析消息
            inputs: {
              text: message
            },
            query:message,
            conversation_id: conversationId,
            response_mode: 'streaming',
            user: 'user-' + (username || 'default')
          },
          connectTimeout: 30000,
          readTimeout: 60000
        }
      )

      console.log('DifyApi chatStreaming response code:', response.responseCode)

      if (response.responseCode !== 200) {
        callbacks.onError(`HTTP ${response.responseCode}`)
        return
      }

      // 解析 SSE 格式的响应结果
      const result = response.result as string
      console.log('DifyApi chatStreaming parsing SSE result...')

      // 解析 SSE 数据
      this.parseSseResponse(result, callbacks)

    } catch (err) {
      console.error('DifyApi chatStreaming error:', err)
      callbacks.onError(String(err))
    } finally {
      httpRequest.destroy()
    }
  }

  // ========================================
  // SSE 解析方法
  // ========================================

  /**
   * 解析 SSE 格式的响应数据
   * SSE 格式示例：
   *   event: ping
   *   data: {"event":"workflow_started",...}
   *   data: {"event":"message","answer":"你好",...}
   *   data: {"event":"message_end",...}
   */
  private parseSseResponse(sseData: string, callbacks: StreamCallbacks): void {
    let fullAnswer: string = ''
    let conversationId: string = ''

    // 按行分割
    const lines = sseData.split('\n')

    for (let line of lines) {
      line = line.trim()
      if (line === '' || line.startsWith('event:')) continue

      // 处理 data: 行
      if (line.startsWith('data:')) {
        const jsonStr = line.substring(5).trim()
        if (jsonStr === '' || jsonStr === '[DONE]') continue

        try {
          const obj = JSON.parse(jsonStr) as Record<string, Object>
          const eventType = obj['event'] as string

          // 提取 conversation_id
          if (obj['conversation_id']) {
            conversationId = obj['conversation_id'] as string
          }

          // 处理消息事件 - 逐步输出答案
          if (eventType === 'message') {
            const answer = obj['answer'] as string || ''
            if (answer) {
              console.log('DifyApi parseSseResponse onChunk:', answer)
              fullAnswer += answer
              callbacks.onChunk(answer)
            }
          }
          // 处理消息结束事件
          else if (eventType === 'message_end') {
            console.log('DifyApi parseSseResponse message_end, fullAnswer:', fullAnswer)
            callbacks.onComplete(conversationId)
            return
          }
        } catch (e) {
          console.warn('DifyApi parseSseResponse JSON parse error:', e)
        }
      }
    }

    // 如果没有收到 message_end 事件，但有累积的答案，也触发完成
    if (fullAnswer) {
      console.log('DifyApi parseSseResponse no message_end, but has answer:', fullAnswer)
      callbacks.onComplete(conversationId)
    } else {
      callbacks.onError('未收到有效回复')
    }
  }

  // ========================================
  // 工具方法
  // ========================================

  /**
   * ArrayBuffer 转字符串
   */
  private arrayBufferToString(buffer: ArrayBuffer): string {
    const uint8Array = new Uint8Array(buffer)
    let result = ''
    for (let i = 0; i < uint8Array.length; i++) {
      result += String.fromCharCode(uint8Array[i])
    }
    return result
  }
}