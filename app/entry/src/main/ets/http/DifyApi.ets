import { http } from '@kit.NetworkKit'
import { TokenUtil } from "../common/TokenUtil"
import { ChatMessage } from '../model/ChatMessage'

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
 * 阻塞模式返回结果
 */
export class ChatResult {
  answer: string = ''
  conversationId: string = ''
  constructor(answer: string, conversationId: string) {
    this.answer = answer
    this.conversationId = conversationId
  }
}

/**
 * 输入参数类
 */
class InputsData {
  text: string = ''
  constructor(text: string) {
    this.text = text
  }
}

/**
 * 聊天请求参数类
 */
class ChatRequestBody {
  inputs: InputsData = new InputsData('')
  query: string = ''
  conversation_id: string = ''
  response_mode: string = ''
  user: string = ''

  constructor(
    text: string,
    query: string,
    conversationId: string,
    responseMode: string,
    user: string
  ) {
    this.inputs = new InputsData(text)
    this.query = query
    this.conversation_id = conversationId
    this.response_mode = responseMode
    this.user = user
  }
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

  /**
   * 将响应结果转换为字符串
   * response.result 可能是 string | Object | ArrayBuffer
   */
  private resultToString(result: string | Object | ArrayBuffer): string {
    if (typeof result === 'string') {
      return result
    } else if (result instanceof ArrayBuffer) {
      return this.arrayBufferToString(result)
    } else {
      return JSON.stringify(result)
    }
  }

  // ========================================
  // 阻塞模式（blocking）
  // ========================================

  /**
   * 阻塞式对话 — 等待 AI 完整生成后一次性返回
   * @param message 用户消息
   * @param conversationId 会话 ID，空字符串表示新会话
   * @returns AI 回复文本和会话 ID
   */
  async chatBlocking(message: string, conversationId: string = ''): Promise<ChatResult> {
    const httpRequest = http.createHttp()

    console.log('DifyApi chatBlocking:', message)
    try {
      const username = await TokenUtil.getUsername()

      const requestBody = new ChatRequestBody(
        message,
        message,
        conversationId,
        'blocking',
        'user-' + (username || 'default')
      )

      const response = await httpRequest.request(
        `${this.baseUrl}/chat-messages`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`
          },
          extraData: requestBody,
          connectTimeout: 15000,
          readTimeout: 30000
        }
      )

      console.log('DifyApi chatBlocking response code:', response.responseCode)

      if (response.responseCode !== 200) {
        throw new Error(`HTTP ${response.responseCode}`)
      }

      const resultStr = this.resultToString(response.result)
      console.log('DifyApi chatBlocking response result:', resultStr.substring(0, 200))

      const result = JSON.parse(resultStr) as Record<string, Object>
      let answer = (result['answer'] as string) || '未收到回复'
      
      // 过滤掉 <think>...</think> 思考过程标签
      answer = answer.replace(/<think>[\s\S]*?<\/think>/g, '').trim()
      
      const convId = (result['conversation_id'] as string) || ''
      return new ChatResult(answer, convId)
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
      const requestBody = new ChatRequestBody(
        message,
        message,
        conversationId,
        'streaming',
        'user-' + (username || 'default')
      )

      const response = await httpRequest.request(
        `${this.baseUrl}/chat-messages`,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`
          },
          extraData: requestBody,
          connectTimeout: 30000,
          readTimeout: 120000
        }
      )

      console.log('DifyApi chatStreaming response code:', response.responseCode)

      if (response.responseCode !== 200) {
        callbacks.onError(`HTTP ${response.responseCode}`)
        return
      }

      // 将响应结果转换为字符串（可能是 ArrayBuffer）
      const resultStr = this.resultToString(response.result)
      console.log('DifyApi chatStreaming response length:', resultStr.length)
      console.log('DifyApi chatStreaming response preview:', resultStr.substring(0, 300))

      // 解析 SSE 数据
      this.parseSseResponse(resultStr, callbacks)

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

    console.log('DifyApi parseSseResponse starting, total length:', sseData.length)

    // 按行分割（处理 \r\n 和 \n）
    const lines = sseData.split(/\r?\n/)
    console.log('DifyApi parseSseResponse total lines:', lines.length)

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim()
      
      if (line === '') continue

      // 处理 event: 行
      if (line.startsWith('event:')) {
        const eventType = line.substring(6).trim()
        console.log('DifyApi parseSseResponse event:', eventType)
        continue
      }

      // 处理 data: 行
      if (line.startsWith('data:')) {
        const jsonStr = line.substring(5).trim()
        
        if (jsonStr === '' || jsonStr === '[DONE]') {
          continue
        }

        try {
          const obj = JSON.parse(jsonStr) as Record<string, Object>
          const eventType = obj['event'] as string

          console.log('DifyApi parseSseResponse data event:', eventType, 'keys:', Object.keys(obj))

          // 提取 conversation_id（可能在不同层级）
          if (obj['conversation_id']) {
            conversationId = obj['conversation_id'] as string
          } else if (obj['data'] && (obj['data'] as Record<string, Object>)['conversation_id']) {
            conversationId = (obj['data'] as Record<string, Object>)['conversation_id'] as string
          }

          // 处理消息事件 - 逐步输出答案
          if (eventType === 'message') {
            // 尝试从不同位置获取 answer
            let answer = ''
            if (obj['answer']) {
              answer = obj['answer'] as string
            } else if (obj['data'] && (obj['data'] as Record<string, Object>)['answer']) {
              answer = (obj['data'] as Record<string, Object>)['answer'] as string
            } else if (obj['content']) {
              answer = obj['content'] as string
            }

            // 过滤掉 <think>...</think> 思考过程标签
            if (answer) {
              answer = answer.replace(/<think>[\s\S]*?<\/think>/g, '')
              answer = answer.trim()
            }

            if (answer) {
              console.log('DifyApi parseSseResponse onChunk:', answer.substring(0, 100))
              fullAnswer += answer
              callbacks.onChunk(answer)
            } else {
              console.warn('DifyApi parseSseResponse event=message but no answer found:', jsonStr.substring(0, 100))
            }
          }
          // 处理消息结束事件
          else if (eventType === 'message_end') {
            console.log('DifyApi parseSseResponse message_end, fullAnswer:', fullAnswer.substring(0, 100))
            callbacks.onComplete(conversationId)
            return
          }
          // 其他事件
          else {
            console.log('DifyApi parseSseResponse other event:', eventType)
          }
        } catch (e) {
          console.warn('DifyApi parseSseResponse JSON parse error:', e, 'line:', jsonStr.substring(0, 50))
        }
      } else {
        console.warn('DifyApi parseSseResponse unhandled line:', line.substring(0, 50))
      }
    }

    // 如果没有收到 message_end 事件，但有累积的答案，也触发完成
    if (fullAnswer) {
      console.log('DifyApi parseSseResponse no message_end, but has answer:', fullAnswer.substring(0, 100))
      callbacks.onComplete(conversationId)
    } else {
      console.error('DifyApi parseSseResponse no answer received')
      callbacks.onError('未收到有效回复')
    }
  }

  // ========================================
  // 获取历史消息
  // ========================================

  /**
   * 获取指定会话的历史消息
   * @param conversationId 会话 ID
   * @returns 历史消息列表
   */
  async getConversationMessages(conversationId: string): Promise<ChatMessage[]> {
    const httpRequest = http.createHttp()

    console.log('DifyApi getConversationMessages:', conversationId)
    try {
      const username = await TokenUtil.getUsername()

      // 使用正确的 Dify API 端点：/conversations/{conversation_id}/messages
      const response = await httpRequest.request(
        `${this.baseUrl}/conversations/${conversationId}/messages?user=user-${username || 'default'}`,
        {
          method: http.RequestMethod.GET,
          header: {
            'Authorization': `Bearer ${this.apiKey}`
          },
          connectTimeout: 15000,
          readTimeout: 15000
        }
      )

      console.log('DifyApi getConversationMessages response code:', response.responseCode)

      if (response.responseCode !== 200) {
        console.error('DifyApi getConversationMessages failed:', response.responseCode)
        return []
      }

      const resultStr = this.resultToString(response.result)
      console.log('DifyApi getConversationMessages response preview:', resultStr.substring(0, 200))

      const result = JSON.parse(resultStr) as Record<string, Object>
      const data = result['data'] as Record<string, Object>

      if (!data || !data['messages']) {
        console.log('DifyApi getConversationMessages: no messages found')
        return []
      }

      const messages = data['messages'] as Record<string, Object>[]
      const chatMessages: ChatMessage[] = []

      for (const msg of messages) {
        // 提取用户消息
        const query = msg['query'] as string
        if (query) {
          chatMessages.push(new ChatMessage('user', query, false))
        }

        // 提取 AI 回复
        const answer = msg['answer'] as string
        if (answer) {
          chatMessages.push(new ChatMessage('assistant', answer, false))
        }
      }

      console.log('DifyApi getConversationMessages: found', chatMessages.length, 'messages')
      return chatMessages
    } catch (err) {
      console.error('DifyApi getConversationMessages error:', err)
      return []
    } finally {
      httpRequest.destroy()
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