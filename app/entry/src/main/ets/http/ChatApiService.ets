import { http } from '@kit.NetworkKit'
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
            'Authorization': token ? `Bearer ${token}` : ''
          },
          extraData: JSON.stringify({ conversationId: ChatApiService.conversationId, message }),
          readTimeout: 300000,
          connectTimeout: 15000
        })

        console.info('CHAT_RESPONSE_CODE:', response.responseCode)
        
        if (response.responseCode !== 200) {
          onError('请求失败: HTTP ' + response.responseCode)
          return
        }

        // 将响应结果转换为字符串
        const resultStr = ChatApiService.resultToString(response.result)
        console.info('CHAT_RESPONSE_LENGTH:', resultStr.length)
        console.info('CHAT_RESPONSE_PREVIEW:', resultStr.substring(0, 200))

        // 解析 SSE 数据
        ChatApiService.parseSseResponse(resultStr, onData, onComplete)
        
      } finally {
        httpRequest.destroy()
      }
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : String(err)
      console.error('CHAT_ERROR:', errorMsg)
      onError('请求失败: ' + errorMsg)
    }
  }

  private static resultToString(result: string | Object | ArrayBuffer): string {
    if (typeof result === 'string') {
      return result
    } else if (result instanceof ArrayBuffer) {
      return ChatApiService.arrayBufferToString(result)
    } else {
      return JSON.stringify(result)
    }
  }

  private static parseSseResponse(
    sseData: string,
    onData: (chunk: string) => void,
    onComplete: () => void
  ): void {
    console.info('CHAT_PARSE_START, total length:', sseData.length)
    
    // 按行分割
    const lines = sseData.split(/\r?\n/)
    console.info('CHAT_PARSE_LINES:', lines.length)
    
    let chunkCount = 0
    for (const line of lines) {
      const trimmedLine = line.trim()
      
      if (trimmedLine === '') continue
      
      console.info('CHAT_LINE:', trimmedLine)
      
      if (trimmedLine.startsWith('data:')) {
        let content = trimmedLine.substring(5).trim()
        console.info('CHAT_SSE_DATA:', content)
        
        if (content === '[DONE]') {
          console.info('CHAT_DONE')
          onComplete()
          return
        }
        
        // 去掉首尾引号（如果存在）
        if (content.startsWith('"') && content.endsWith('"')) {
          content = content.slice(1, -1)
        }
        
        if (content) {
          chunkCount++
          onData(content)
        }
      }
    }
    
    console.info('CHAT_PARSE_COMPLETE, chunks:', chunkCount)
    onComplete()
  }

  private static arrayBufferToString(buffer: ArrayBuffer): string {
    const uint8Array = new Uint8Array(buffer)
    let result = ''
    for (let i = 0; i < uint8Array.length; i++) {
      result += String.fromCharCode(uint8Array[i])
    }
    return result
  }
}
