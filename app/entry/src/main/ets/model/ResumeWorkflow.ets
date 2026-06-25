/**
 * 简历优化工作流输入参数
 */
export class WorkflowInputs {
  resume_content: string = ''
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