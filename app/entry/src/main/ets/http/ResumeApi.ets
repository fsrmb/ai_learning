import { fileIo } from '@kit.CoreFileKit'
import { Constants } from '../common/Constants'
import { DifyHttpClient } from './DifyHttpClient'
import { WorkflowRequestData, WorkflowResult, WorkflowInputs } from '../model/ResumeWorkflow'

/**
 * 简历优化 API
 * 调用 Dify 工作流完成简历优化
 */
export class ResumeApi {
  /**
   * 调用工作流优化简历
   * 端点: POST /v1/workflows/run
   * 工作流内部完成：评分 → 分支判断 → 优化 → 返回结果
   */
  static async optimizeResume(
    content: string,
    fileUri?: string
  ): Promise<string> {
    if (!Constants.RESUME_API_URL || !Constants.RESUME_API_KEY) {
      throw new Error('API 配置未填写，请在 Constants.ets 中配置 RESUME_API_URL 和 RESUME_API_KEY')
    }

    console.info(`ResumeApi optimizeResume: content=${content.substring(0, 50)}, fileUri=${fileUri}`)

    if (fileUri) {
      return ResumeApi.sendWithFile(content, fileUri)
    }

    const inputs: WorkflowInputs = new WorkflowInputs()
    inputs.resume_content = content

    const requestBody: WorkflowRequestData = new WorkflowRequestData()
    requestBody.inputs = inputs
    requestBody.response_mode = 'blocking'
    requestBody.user = 'user-resume'

    try {
      const result: WorkflowResult = await DifyHttpClient.post<WorkflowResult>('/workflows/run', requestBody)
      return ResumeApi.extractWorkflowOutput(result)
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : '网络请求失败'
      console.error(`ResumeApi optimizeResume exception: ${errorMessage}`)
      throw new Error(errorMessage)
    }
  }

  /**
   * 从工作流响应中提取输出文本
   * 工作流输出在 data.outputs 中，可能包含多个字段
   */
  private static extractWorkflowOutput(result: WorkflowResult): string {
    if (!result.data) {
      throw new Error('工作流响应缺少 data 字段')
    }

    if (result.data.error) {
      throw new Error(`工作流执行错误: ${result.data.error}`)
    }

    const outputs = result.data.outputs
    if (!outputs) {
      throw new Error('工作流响应缺少 outputs 字段')
    }

    let text: string = ''
    if (outputs.text) {
      text = outputs.text
    } else if (outputs.result) {
      text = outputs.result
    } else if (outputs.output) {
      text = outputs.output
    } else if (outputs.answer) {
      text = outputs.answer
    } else if (outputs.resume) {
      text = outputs.resume
    } else if (outputs.optimized_resume) {
      text = outputs.optimized_resume
    }

    if (!text) {
      throw new Error('工作流输出为空')
    }

    return ResumeApi.removeThinkTags(text)
  }

  /**
   * 移除 AI 响应中的 <think> 思考标签
   */
  private static removeThinkTags(text: string): string {
    return text.replace(/<think>[\s\S]*?<\/think>/g, '').trim()
  }

  /**
   * 带文件的请求（multipart/form-data）
   */
  private static async sendWithFile(
    content: string,
    fileUri: string
  ): Promise<string> {
    console.info('ResumeApi sendWithFile: uploading file...')

    const fileName: string = fileUri.split('/').pop() || 'resume.pdf'
    const fileExtension: string = fileName.split('.').pop()?.toLowerCase() || ''

    const fileContentBase64: string = await ResumeApi.readFileAsBase64(fileUri)

    let resumeContent: string = content
    if (!resumeContent && (fileExtension === 'txt' || fileExtension === 'md')) {
      resumeContent = ResumeApi.base64ToString(fileContentBase64)
    }

    const inputs: WorkflowInputs = new WorkflowInputs()
    inputs.resume_content = resumeContent

    const requestBody: WorkflowRequestData = new WorkflowRequestData()
    requestBody.inputs = inputs
    requestBody.response_mode = 'blocking'
    requestBody.user = 'user-resume'

    const boundary: string = '----ResumeBoundary' + Date.now()
    const multipartData: string = ResumeApi.buildMultipartData(boundary, requestBody, fileName, fileContentBase64, fileExtension)

    try {
      const result: WorkflowResult = await DifyHttpClient.postMultipart<WorkflowResult>(
        '/workflows/run',
        multipartData,
        `multipart/form-data; boundary=${boundary}`
      )
      return ResumeApi.extractWorkflowOutput(result)
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : '文件上传失败'
      throw new Error(errorMessage)
    }
  }

  private static async readFileAsBase64(fileUri: string): Promise<string> {
    try {
      const file = await fileIo.open(fileUri, fileIo.OpenMode.READ_ONLY)
      const buffer: ArrayBuffer = new ArrayBuffer(4096)
      let content: string = ''

      while (true) {
        const bytesRead: number = await fileIo.read(file.fd, buffer)
        if (bytesRead === 0) break
        const view: Uint8Array = new Uint8Array(buffer, 0, bytesRead)
        content += ResumeApi.arrayBufferToBase64(view)
      }

      await fileIo.close(file.fd)
      return content
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : '文件读取失败'
      throw new Error(errorMessage)
    }
  }

  private static arrayBufferToBase64(buffer: Uint8Array): string {
    const base64Chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    let result: string = ''
    const len: number = buffer.byteLength
    let i: number = 0

    while (i < len) {
      const byte1: number = buffer[i++] || 0
      const byte2: number = i < len ? buffer[i++] : 0
      const byte3: number = i < len ? buffer[i++] : 0

      const enc1: number = byte1 >> 2
      const enc2: number = ((byte1 & 3) << 4) | (byte2 >> 4)
      const enc3: number = ((byte2 & 15) << 2) | (byte3 >> 6)
      const enc4: number = byte3 & 63

      result += base64Chars[enc1]
      result += base64Chars[enc2]
      result += i > len + 1 ? '=' : base64Chars[enc3]
      result += i > len ? '=' : base64Chars[enc4]
    }

    return result
  }

  private static buildMultipartData(
    boundary: string,
    requestBody: WorkflowRequestData,
    fileName: string,
    fileContent: string,
    fileExtension: string
  ): string {
    let data: string = ''

    data += `--${boundary}\r\n`
    data += 'Content-Disposition: form-data; name="inputs"\r\n'
    data += 'Content-Type: application/json\r\n\r\n'
    data += JSON.stringify(requestBody.inputs) + '\r\n'

    data += `--${boundary}\r\n`
    data += 'Content-Disposition: form-data; name="response_mode"\r\n\r\n'
    data += requestBody.response_mode + '\r\n'

    data += `--${boundary}\r\n`
    data += 'Content-Disposition: form-data; name="user"\r\n\r\n'
    data += requestBody.user + '\r\n'

    const contentType: string = ResumeApi.getContentType(fileExtension)
    data += `--${boundary}\r\n`
    data += `Content-Disposition: form-data; name="files"; filename="${fileName}"\r\n`
    data += `Content-Type: ${contentType}\r\n`
    data += 'Content-Transfer-Encoding: base64\r\n\r\n'
    data += fileContent + '\r\n'

    data += `--${boundary}--\r\n`

    return data
  }

  private static getContentType(extension: string): string {
    const contentTypes: Record<string, string> = {
      'txt': 'text/plain',
      'md': 'text/markdown',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'rtf': 'application/rtf'
    }
    return contentTypes[extension] || 'application/octet-stream'
  }

  private static base64ToString(base64: string): string {
    const base64Chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    let result: string = ''
    let i: number = 0

    base64 = base64.replace(/[^A-Za-z0-9+/=]/g, '')

    while (i < base64.length) {
      const enc1: number = base64Chars.indexOf(base64.charAt(i++))
      const enc2: number = base64Chars.indexOf(base64.charAt(i++))
      const enc3: number = base64Chars.indexOf(base64.charAt(i++))
      const enc4: number = base64Chars.indexOf(base64.charAt(i++))

      const byte1: number = (enc1 << 2) | (enc2 >> 4)
      const byte2: number = ((enc2 & 15) << 4) | (enc3 >> 2)
      const byte3: number = ((enc3 & 3) << 6) | enc4

      result += String.fromCharCode(byte1)
      if (enc3 !== 64) {
        result += String.fromCharCode(byte2)
      }
      if (enc4 !== 64) {
        result += String.fromCharCode(byte3)
      }
    }

    return result
  }
}