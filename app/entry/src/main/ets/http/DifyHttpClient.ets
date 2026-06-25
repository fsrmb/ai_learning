import { http } from '@kit.NetworkKit'
import { Constants } from '../common/Constants'

/**
 * Dify API 客户端
 * 用于调用 Dify 工作流和对话流 API
 */
export class DifyHttpClient {
  private static getApiKey(): string {
    return Constants.RESUME_API_KEY
  }

  private static getBaseUrl(): string {
    return Constants.RESUME_API_URL
  }

  /**
   * 发送 JSON 格式的 POST 请求
   */
  static async post<T>(path: string, data: object): Promise<T> {
    const httpRequest = http.createHttp()
    try {
      const response = await httpRequest.request(`${DifyHttpClient.getBaseUrl()}${path}`, {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': `Bearer ${DifyHttpClient.getApiKey()}`,
          'Content-Type': 'application/json'
        },
        extraData: data,
        connectTimeout: 15000,
        readTimeout: 120000
      })
      return DifyHttpClient.handleResponse<T>(response)
    } finally {
      httpRequest.destroy()
    }
  }

  /**
   * 发送 multipart/form-data 格式的 POST 请求（用于文件上传）
   */
  static async postMultipart<T>(
    path: string,
    formData: string,
    contentType: string
  ): Promise<T> {
    const httpRequest = http.createHttp()
    try {
      const response = await httpRequest.request(`${DifyHttpClient.getBaseUrl()}${path}`, {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': `Bearer ${DifyHttpClient.getApiKey()}`,
          'Content-Type': contentType
        },
        extraData: formData,
        connectTimeout: 15000,
        readTimeout: 120000
      })
      return DifyHttpClient.handleResponse<T>(response)
    } finally {
      httpRequest.destroy()
    }
  }

  private static handleResponse<T>(response: http.HttpResponse): T {
    if (response.responseCode === 200) {
      const resultStr = DifyHttpClient.resultToString(response.result)
      return JSON.parse(resultStr) as T
    } else {
      throw new Error(`HTTP error: ${response.responseCode}`)
    }
  }

  private static resultToString(result: string | Object | ArrayBuffer): string {
    if (typeof result === 'string') {
      return result
    } else if (result instanceof ArrayBuffer) {
      const uint8Array = new Uint8Array(result)
      let str = ''
      for (let i = 0; i < uint8Array.length; i++) {
        str += String.fromCharCode(uint8Array[i])
      }
      return str
    } else {
      return JSON.stringify(result)
    }
  }
}