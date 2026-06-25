/**
 * 文件输入对象（Dify Workflow 文件类型变量格式）
 * 在inputs中使用，例如: { file_field: [ { type: 'document', transfer_method: 'local_file', upload_file_id: 'xxx' } ] }
 */
export class InputFileObject {
  type: string = 'document'
  transfer_method: string = 'local_file'
  upload_file_id: string = ''
}

/**
 * 简历优化工作流输入参数
 * 包含文本输入和文件输入
 */
export class WorkflowInputs {
  resume_content: string = ''
  resume_file?: InputFileObject[] = undefined
}

/**
 * 简历优化工作流请求体（Dify Workflow 模式）
 * 端点: POST /v1/workflows/run
 */
export class WorkflowRequestData {
  inputs: WorkflowInputs = new WorkflowInputs()
  response_mode: string = 'blocking'
  user: string = ''
}

/**
 * 简历优化工作流输出结果
 */
export class WorkflowOutputs {
  text?: string
  result?: string
  output?: string
  answer?: string
  resume?: string
  optimized_resume?: string
}

/**
 * 简历优化工作流响应数据
 */
export class WorkflowResultData {
  outputs?: WorkflowOutputs = undefined
  error?: string = undefined
}

/**
 * 简历优化工作流响应结果（Dify Workflow 模式）
 * 注意：工作流返回 data.outputs，而非 answer
 */
export class WorkflowResult {
  data?: WorkflowResultData = undefined
}

/**
 * 文件上传响应结果（Dify Files API）
 * 端点: POST /v1/files/upload
 */
export class FileUploadResult {
  id?: string = undefined
  name?: string = undefined
  size?: number = undefined
  extension?: string = undefined
  mime_type?: string = undefined
}