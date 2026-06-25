import { http } from '@kit.NetworkKit'
import { fileIo } from '@kit.CoreFileKit'
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
      const requestBody = JSON.stringify(data)
      console.info(`DifyHttpClient post: url=${DifyHttpClient.getBaseUrl()}${path}`)
      console.info(`DifyHttpClient post: body=${requestBody}`)

      const response = await httpRequest.request(`${DifyHttpClient.getBaseUrl()}${path}`, {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': `Bearer ${DifyHttpClient.getApiKey()}`,
          'Content-Type': 'application/json'
        },
        extraData: requestBody,
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

  /**
   * 上传文件到 Dify（使用二进制方式）
   * 端点: POST /v1/files/upload
   * 返回: { id: string, name: string, ... }
   */
  static async uploadFile<T>(
    path: string,
    fileUri: string,
    fileName: string,
    contentType: string
  ): Promise<T> {
    const httpRequest = http.createHttp()
    try {
      const fileBuffer: ArrayBuffer = await DifyHttpClient.readFileAsBuffer(fileUri)
      console.info(`DifyHttpClient uploadFile: fileSize=${fileBuffer.byteLength}, fileName=${fileName}, contentType=${contentType}`)

      const boundary: string = '----DifyFileBoundary' + Date.now()
      const multipartData: ArrayBuffer = DifyHttpClient.buildFileMultipart(boundary, fileBuffer, fileName, contentType)

      const url = `${DifyHttpClient.getBaseUrl()}${path}`
      console.info(`DifyHttpClient uploadFile: url=${url}`)

      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Authorization': `Bearer ${DifyHttpClient.getApiKey()}`,
          'Content-Type': `multipart/form-data; boundary=${boundary}`
        },
        extraData: multipartData,
        connectTimeout: 15000,
        readTimeout: 120000
      })

      console.info(`DifyHttpClient uploadFile: responseCode=${response.responseCode}`)
      return DifyHttpClient.handleResponse<T>(response)
    } finally {
      httpRequest.destroy()
    }
  }

  /**
   * 读取文件为 ArrayBuffer
   */
  private static async readFileAsBuffer(fileUri: string): Promise<ArrayBuffer> {
    const file = await fileIo.open(fileUri, fileIo.OpenMode.READ_ONLY)
    try {
      const stat = await fileIo.stat(fileUri)
      const fileSize = stat.size
      const buffer = new ArrayBuffer(fileSize)
      await fileIo.read(file.fd, buffer)
      return buffer
    } finally {
      await fileIo.close(file.fd)
    }
  }

  /**
   * 构建文件上传的 multipart 数据（包含二进制文件内容）
   */
  private static buildFileMultipart(
    boundary: string,
    fileBuffer: ArrayBuffer,
    fileName: string,
    contentType: string
  ): ArrayBuffer {
    const header = `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${fileName}"\r\nContent-Type: ${contentType}\r\n\r\n`
    const footer = `\r\n--${boundary}\r\nContent-Disposition: form-data; name="user"\r\n\r\nuser-resume\r\n--${boundary}--\r\n`

    const headerBytes = new Uint8Array(header.length)
    for (let i = 0; i < header.length; i++) {
      headerBytes[i] = header.charCodeAt(i)
    }

    const footerBytes = new Uint8Array(footer.length)
    for (let i = 0; i < footer.length; i++) {
      footerBytes[i] = footer.charCodeAt(i)
    }

    const totalSize = headerBytes.length + fileBuffer.byteLength + footerBytes.length
    const result = new Uint8Array(totalSize)

    result.set(headerBytes, 0)
    result.set(new Uint8Array(fileBuffer), headerBytes.length)
    result.set(footerBytes, headerBytes.length + fileBuffer.byteLength)

    return result.buffer
  }

  private static handleResponse<T>(response: http.HttpResponse): T {
    if (response.responseCode === 200 || response.responseCode === 201) {
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