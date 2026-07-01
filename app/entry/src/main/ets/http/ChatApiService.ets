import { http } from '@kit.NetworkKit'
import { util } from '@kit.ArkTS'
import { Constants } from '../common/Constants'
import { TokenUtil } from '../common/TokenUtil'

interface CreateConversationData {
  conversationId: number
}

interface CreateConversationResult {
  code: number
  data: CreateConversationData
  message?: string
}

interface ConversationVO {
  conversationId: number
  title: string
  agentType: string
  createdAt: string
  updatedAt: string
}

interface MessageVO {
  id: number
  role: string
  content: string
  createdAt: string
}

interface ApiResult<T> {
  code: number
  data: T
  message?: string
}

export class ChatApiService {
  private static conversationId: number = 0

  static async createConversation(title: string = '新对话'): Promise<number> {
    const token = await TokenUtil.getToken()
    const url = Constants.BASE_URL + '/api/chat/conversation'

    return new Promise((resolve, reject) => {
      http.createHttp().request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': token ? `Bearer ${token}` : ''
        },
        extraData: JSON.stringify({ title })
      }).then((response: http.HttpResponse) => {
        const result = JSON.parse(response.result as string) as CreateConversationResult
        if (result.code === 200) {
          ChatApiService.conversationId = result.data.conversationId
          resolve(ChatApiService.conversationId)
        } else {
          reject(result.message || '创建会话失败')
        }
      }).catch((err: BusinessError) => {
        reject(err.message || '创建会话失败')
      })
    })
  }

  /**
   * SSE 流式聊天请求
   */
  static async streamChat(
    message: string,
    onData: (chunk: string) => void,
    onComplete: () => void,
    onError: (err: string) => void
  ): Promise<void> {
    console.info('CHAT_SEND:', message.substring(0, 30))
    
    try {
      const token = await TokenUtil.getToken()
      console.info('CHAT_TOKEN:', token ? token.substring(0, 20) + '...' : 'null')
      
      if (!ChatApiService.conversationId) {
        console.info('CHAT_CREATE_CONVERSATION')
        await ChatApiService.createConversation()
        console.info('CHAT_CONVERSATION_ID:', ChatApiService.conversationId)
      }

      const url = Constants.BASE_URL + '/api/chat/stream'
      console.info('CHAT_REQUEST_URL:', url)
      
      const httpRequest = http.createHttp()
      
      try {
        const response = await httpRequest.request(url, {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': token ? `Bearer ${token}` : '',
            'Accept': 'text/event-stream'
          },
          extraData: JSON.stringify({ 
            conversationId: ChatApiService.conversationId, 
            message 
          }),
          readTimeout: 300000,
          connectTimeout: 15000
        })

        console.info('CHAT_RESPONSE_CODE:', response.responseCode)
        
        if (response.responseCode !== 200) {
          onError('请求失败: HTTP ' + response.responseCode)
          return
        }

        const resultStr = ChatApiService.resultToString(response.result)
        console.info('CHAT_RESPONSE_LENGTH:', resultStr.length)
        
        const fullText = ChatApiService.parseSseResponse(resultStr)
        console.info('CHAT_FULL_TEXT_LENGTH:', fullText.length)
        
        await ChatApiService.simulateStream(fullText, onData)
        
        onComplete()
        
      } catch (err) {
        const errorMsg = err instanceof Error ? err.message : String(err)
        console.error('CHAT_REQUEST_ERROR:', errorMsg)
        onError('请求失败: ' + errorMsg)
      } finally {
        httpRequest.destroy()
      }
      
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : String(err)
      console.error('CHAT_ERROR:', errorMsg)
      onError('请求失败: ' + errorMsg)
    }
  }

  /**
   * 将 HTTP 响应结果转换为字符串
   */
  private static resultToString(result: string | Object | ArrayBuffer): string {
    if (typeof result === 'string') {
      return result
    } else if (result instanceof ArrayBuffer) {
      return ChatApiService.arrayBufferToUtf8String(result)
    } else {
      return JSON.stringify(result)
    }
  }

  /**
   * 解析 SSE 响应，提取完整文本
   * 
   * SSE 协议规范：
   * - 同一事件内连续的 data: 行之间用 \n 连接
   * - 空行表示事件结束
   * - 例如 AI 输出 'Hello\nWorld' 会被编码为 'data:Hello\ndata:World\n\n'
   */
  private static parseSseResponse(sseData: string): string {
    console.info('CHAT_PARSE_START, raw data length:', sseData.length)
    
    const preview = sseData.substring(0, 500).replace(/\n/g, '\\n').replace(/\r/g, '\\r')
    console.info('CHAT_PARSE_RAW_PREVIEW:', preview)
    
    let fullText = ''
    let eventLines: string[] = []
    const lines = sseData.split(/\r?\n/)
    
    console.info('CHAT_PARSE_LINES_COUNT:', lines.length)
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i]
      
      if (line.startsWith('data:')) {
        let content = line.substring(5)
        if (content.startsWith(' ')) {
          content = content.substring(1)
        }
        
        if (content === '[DONE]') {
          console.info('CHAT_DONE_RECEIVED')
          break
        }
        
        eventLines.push(content)
      } else if (line.length === 0) {
        if (eventLines.length > 0) {
          fullText += eventLines.join('\n')
          eventLines = []
        }
      }
    }
    
    if (eventLines.length > 0) {
      fullText += eventLines.join('\n')
    }
    
    console.info('CHAT_PARSE_COMPLETE, full text length:', fullText.length)
    
    const debugPreview = fullText.substring(0, 200).replace(/\n/g, '\\n').replace(/\r/g, '\\r')
    console.info('CHAT_FULL_TEXT_PREVIEW (debug):', debugPreview)
    
    if (fullText.length === 0 && sseData.length > 0) {
      console.warn('CHAT_WARNING: No data lines found, returning raw data')
      return sseData
    }
    
    return fullText
  }

  /**
   * 模拟流式输出（逐字符显示）
   */
  private static async simulateStream(text: string, onData: (chunk: string) => void): Promise<void> {
    const chars = text.split('')
    
    for (let i = 0; i < chars.length; i++) {
      onData(chars[i])
      
      if (i < chars.length - 1) {
        await new Promise<void>((resolve) => {
          setTimeout(() => { resolve() }, 30)
        })
      }
    }
  }

  /**
   * ArrayBuffer 转 UTF-8 字符串（支持中文）
   */
  private static arrayBufferToUtf8String(buffer: ArrayBuffer): string {
    const uint8Array = new Uint8Array(buffer)
    const textDecoder: util.TextDecoder = new util.TextDecoder('utf-8')
    return textDecoder.decodeToString(uint8Array)
  }

  /**
   * 获取所有历史会话列表
   */
  static async getConversations(): Promise<ConversationVO[]> {
    const token = await TokenUtil.getToken()
    const url = Constants.BASE_URL + '/api/chat/conversations'

    return new Promise((resolve, reject) => {
      http.createHttp().request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Authorization': token ? `Bearer ${token}` : ''
        },
        connectTimeout: 15000
      }).then((response: http.HttpResponse) => {
        const result = JSON.parse(response.result as string) as ApiResult<ConversationVO[]>
        if (result.code === 200) {
          resolve(result.data)
        } else {
          reject(result.message || '获取会话列表失败')
        }
      }).catch((err:Error) => {
        const errorMsg = err instanceof Error ? err.message : String(err)
        reject(errorMsg || '获取会话列表失败')
      })
    })
  }

  /**
   * 获取指定会话的消息历史
   */
  static async getMessageHistory(conversationId: number, page: number = 1, size: number = 50): Promise<MessageVO[]> {
    const token = await TokenUtil.getToken()
    const url = `${Constants.BASE_URL}/api/chat/history/${conversationId}?page=${page}&size=${size}`

    return new Promise((resolve, reject) => {
      http.createHttp().request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Authorization': token ? `Bearer ${token}` : ''
        },
        connectTimeout: 15000
      }).then((response: http.HttpResponse) => {
        const result = JSON.parse(response.result as string) as ApiResult<MessageVO[]>
        if (result.code === 200) {
          resolve(result.data)
        } else {
          reject(result.message || '获取消息历史失败')
        }
      }).catch((err:Error) => {
        const errorMsg = err instanceof Error ? err.message : String(err)
        reject(errorMsg || '获取消息历史失败')
      })
    })
  }

  /**
   * 获取当前会话ID
   */
  static getConversationId(): number {
    return ChatApiService.conversationId
  }

  /**
   * 设置当前会话ID
   */
  static setConversationId(id: number): void {
    ChatApiService.conversationId = id
  }

  /**
   * 重置会话（新建会话）
   */
  static resetConversation(): void {
    ChatApiService.conversationId = 0
  }

  /**
   * 删除会话
   */
  static async deleteConversation(conversationId: number): Promise<void> {
    const token = await TokenUtil.getToken()
    const url = `${Constants.BASE_URL}/api/chat/conversation/${conversationId}`

    return new Promise((resolve, reject) => {
      http.createHttp().request(url, {
        method: http.RequestMethod.DELETE,
        header: {
          'Authorization': token ? `Bearer ${token}` : ''
        },
        connectTimeout: 15000
      }).then((response: http.HttpResponse) => {
        const result = JSON.parse(response.result as string) as ApiResult<null>
        if (result.code === 200) {
          resolve()
        } else {
          reject(result.message || '删除会话失败')
        }
      }).catch((err:Error) => {
        const errorMsg = err instanceof Error ? err.message : String(err)
        reject(errorMsg || '删除会话失败')
      })
    })
  }
}
