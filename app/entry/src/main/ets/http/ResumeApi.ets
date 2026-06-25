import { fileIo } from '@kit.CoreFileKit'
import { Constants } from '../common/Constants'
import { DifyHttpClient } from './DifyHttpClient'
import { WorkflowRequestData, WorkflowResult, WorkflowInputs, FileUploadResult, InputFileObject } from '../model/ResumeWorkflow'

/**
 * 简历优化 API
 * 调用 Dify 工作流完成简历优化
 * 文件上传流程：先调用 /v1/files/upload 获取 upload_file_id，再调用 /v1/workflows/run
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
   * 带文件的请求（先上传文件获取 upload_file_id，再将文件ID传给工作流）
   * 文件直接由工作流处理，不在移动端转换为文本
   * 请求格式: POST /v1/workflows/run
   * {
   *   "inputs": {
   *     "resume_content": "用户补充说明",
   *     "resume_file": [{"type": "document", "transfer_method": "local_file", "upload_file_id": "xxx"}]
   *   },
   *   "response_mode": "blocking",
   *   "user": "user-resume"
   * }
   */
  private static async sendWithFile(
    content: string,
    fileUri: string
  ): Promise<string> {
    console.info('ResumeApi sendWithFile: uploading file...')

    const fileName: string = fileUri.split('/').pop() || 'resume.txt'
    const fileExtension: string = fileName.split('.').pop()?.toLowerCase() || ''
    const contentType: string = ResumeApi.getContentType(fileExtension)

    try {
      const uploadResult: FileUploadResult = await DifyHttpClient.uploadFile<FileUploadResult>(
        '/files/upload',
        fileUri,
        fileName,
        contentType
      )

      if (!uploadResult.id) {
        throw new Error('文件上传失败，未返回文件ID')
      }

      console.info(`ResumeApi sendWithFile: file uploaded successfully, id=${uploadResult.id}`)

      const fileObject: InputFileObject = new InputFileObject()
      fileObject.upload_file_id = uploadResult.id
      fileObject.type = 'document'

      const inputs: WorkflowInputs = new WorkflowInputs()
      inputs.resume_content = content
      inputs.resume_file = [fileObject]

      const requestBody: WorkflowRequestData = new WorkflowRequestData()
      requestBody.inputs = inputs
      requestBody.response_mode = 'blocking'
      requestBody.user = 'user-resume'

      const result: WorkflowResult = await DifyHttpClient.post<WorkflowResult>('/workflows/run', requestBody)
      return ResumeApi.extractWorkflowOutput(result)

    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : '文件上传失败'
      console.error(`ResumeApi sendWithFile exception: ${errorMessage}`)
      throw new Error(errorMessage)
    }
  }

  /**
   * 读取文本文件内容
   */
  private static async readFileContent(fileUri: string): Promise<string> {
    try {
      const file = await fileIo.open(fileUri, fileIo.OpenMode.READ_ONLY)
      const stat = await fileIo.stat(fileUri)
      const fileSize = stat.size
      const buffer = new ArrayBuffer(fileSize)
      await fileIo.read(file.fd, buffer)
      await fileIo.close(file.fd)

      const uint8Array = new Uint8Array(buffer)
      let content = ''
      for (let i = 0; i < uint8Array.length; i++) {
        content += String.fromCharCode(uint8Array[i])
      }
      return content
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : '文件读取失败'
      throw new Error(errorMessage)
    }
  }

  /**
   * 根据文件扩展名获取 Content-Type
   */
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
}