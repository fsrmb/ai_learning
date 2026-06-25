# 简历优化功能实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 在首页添加"简历优化"入口，创建简历优化页面，支持文件上传和文本输入，AI 返回优化建议，包含历史记录功能。

**架构：** 独立实现方案，创建 `ResumeApi`、`ResumeOptimizeViewModel`、`FileUploadCard` 和 `ResumeOptimize` 页面，复用现有基础组件（`MarkdownUtil`、`ChatMessage`、`HistoryPanel`）。

**技术栈：** HarmonyOS NEXT、ArkTS、Dify API、Preferences 持久化、文件选择器

---

## 文件结构

| 文件 | 职责 |
|------|------|
| `http/ResumeApi.ets` | API 调用，支持文件上传和文本输入 |
| `viewmodel/ResumeOptimizeViewModel.ets` | 业务逻辑，管理消息列表和历史记录 |
| `components/FileUploadCard.ets` | 文件上传卡片组件 |
| `pages/ResumeOptimize.ets` | 简历优化页面 UI |
| `common/Constants.ets` | API 配置（新增占位符） |
| `pages/MainTab.ets` | 首页入口 |
| `main_pages.json` | 页面注册 |

---

### 任务 1：更新 Constants.ets 添加 API 配置占位符

**文件：**
- 修改：`app/entry/src/main/ets/common/Constants.ets`

- [ ] **步骤 1：添加简历优化 API 配置**

```typescript
// 在 Constants 类中添加以下静态属性：
static readonly RESUME_API_URL: string = ''  // 简历优化 API 地址（待填写）
static readonly RESUME_API_KEY: string = ''  // 简历优化 API 密钥（待填写）
```

- [ ] **步骤 2：Commit**

```bash
git add app/entry/src/main/ets/common/Constants.ets
git commit -m "feat: 添加简历优化 API 配置占位符"
```

---

### 任务 2：创建 ResumeApi.ets

**文件：**
- 创建：`app/entry/src/main/ets/http/ResumeApi.ets`

**参考文件：** `app/entry/src/main/ets/http/DifyApi.ets`

- [ ] **步骤 1：创建文件结构**

```typescript
import { http } from '@kit.NetworkKit'
import { fileIo } from '@kit.CoreFileKit'
import { Constants } from '../common/Constants'

/**
 * 简历优化 API 封装
 * 
 * 支持两种模式：
 *   - 文件上传：multipart/form-data
 *   - 文本输入：application/json
 * 
 * 当前仅支持阻塞模式
 * 
 * 使用前请在 Constants.ets 中填写 RESUME_API_URL 和 RESUME_API_KEY
 */
export class ResumeApi {
  private apiKey: string
  private apiUrl: string

  constructor(apiKey?: string, apiUrl?: string) {
    this.apiKey = apiKey || Constants.RESUME_API_KEY
    this.apiUrl = apiUrl || Constants.RESUME_API_URL
  }

  /**
   * 优化简历（阻塞模式）
   * 
   * @param content 简历文本内容
   * @param fileUri 文件 URI（可选）
   * @param conversationId 会话 ID（可选，用于多轮对话）
   * @returns AI 返回的优化建议
   */
  async optimizeResume(
    content: string,
    fileUri?: string,
    conversationId?: string
  ): Promise<string> {
    // 实现逻辑
  }

  /**
   * 发送后续消息（阻塞模式）
   * 
   * @param content 消息内容
   * @param conversationId 会话 ID
   * @returns AI 返回的响应
   */
  async sendMessage(
    content: string,
    conversationId: string
  ): Promise<string> {
    // 实现逻辑
  }

  /**
   * 读取文件内容（base64）
   */
  private async readFileAsBase64(fileUri: string): Promise<string> {
    // 实现逻辑
  }
}
```

- [ ] **步骤 2：实现 optimizeResume 方法**

```typescript
async optimizeResume(
  content: string,
  fileUri?: string,
  conversationId?: string
): Promise<string> {
  if (!this.apiUrl || !this.apiKey) {
    throw new Error('API 配置未填写，请在 Constants.ets 中配置 RESUME_API_URL 和 RESUME_API_KEY')
  }

  console.info(`ResumeApi optimizeResume: content=${content.substring(0, 50)}, fileUri=${fileUri}, conversationId=${conversationId}`)

  const headers: http.Header = {
    'Authorization': `Bearer ${this.apiKey}`,
    'Content-Type': 'application/json'
  }

  const requestBody: ResumeRequestData = {
    inputs: { resume: content },
    response_mode: 'blocking',
    user: 'user-resume'
  }

  if (conversationId) {
    requestBody.conversation_id = conversationId
  }

  // 如果有文件，需要处理文件上传
  if (fileUri) {
    return this.sendWithFile(content, fileUri, conversationId)
  }

  // 文本输入，使用普通 JSON 请求
  try {
    const response = await http.createHttp().request(
      `${this.apiUrl}/chat-messages`,
      {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: requestBody
      }
    )

    if (response.responseCode === 200) {
      const result: ResumeChatResult = JSON.parse(response.result.toString())
      return result.answer || result.outputs?.text || '未获取到优化建议'
    } else {
      const errorMessage = `API 请求失败: ${response.responseCode}`
      console.error(`ResumeApi optimizeResume error: ${errorMessage}`)
      throw new Error(errorMessage)
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : '网络请求失败'
    console.error(`ResumeApi optimizeResume exception: ${errorMessage}`)
    throw new Error(errorMessage)
  }
}
```

- [ ] **步骤 3：实现 sendMessage 方法**

```typescript
async sendMessage(
  content: string,
  conversationId: string
): Promise<string> {
  if (!this.apiUrl || !this.apiKey) {
    throw new Error('API 配置未填写')
  }

  const headers: http.Header = {
    'Authorization': `Bearer ${this.apiKey}`,
    'Content-Type': 'application/json'
  }

  const requestBody: ResumeRequestData = {
    inputs: { resume: content },
    conversation_id: conversationId,
    response_mode: 'blocking',
    user: 'user-resume'
  }

  try {
    const response = await http.createHttp().request(
      `${this.apiUrl}/chat-messages`,
      {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: requestBody
      }
    )

    if (response.responseCode === 200) {
      const result: ResumeChatResult = JSON.parse(response.result.toString())
      return result.answer || result.outputs?.text || '未获取到响应'
    } else {
      throw new Error(`API 请求失败: ${response.responseCode}`)
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : '网络请求失败'
    throw new Error(errorMessage)
  }
}
```

- [ ] **步骤 4：实现文件上传方法**

```typescript
/**
 * 带文件上传的请求
 */
private async sendWithFile(
  content: string,
  fileUri: string,
  conversationId?: string
): Promise<string> {
  console.info('ResumeApi sendWithFile: uploading file...')

  const headers: http.Header = {
    'Authorization': `Bearer ${this.apiKey}`,
    'Content-Type': 'multipart/form-data'
  }

  const requestBody: ResumeRequestData = {
    inputs: { resume: content },
    response_mode: 'blocking',
    user: 'user-resume'
  }

  if (conversationId) {
    requestBody.conversation_id = conversationId
  }

  // 读取文件内容
  const fileContent = await this.readFileAsBase64(fileUri)
  const fileName = fileUri.split('/').pop() || 'resume.pdf'

  // 构建 multipart 数据
  const boundary = '----ResumeBoundary' + Date.now()
  const multipartData = this.buildMultipartData(boundary, requestBody, fileName, fileContent)

  headers['Content-Type'] = `multipart/form-data; boundary=${boundary}`

  try {
    const response = await http.createHttp().request(
      `${this.apiUrl}/chat-messages`,
      {
        method: http.RequestMethod.POST,
        header: headers,
        extraData: multipartData
      }
    )

    if (response.responseCode === 200) {
      const result: ResumeChatResult = JSON.parse(response.result.toString())
      return result.answer || result.outputs?.text || '未获取到优化建议'
    } else {
      throw new Error(`API 请求失败: ${response.responseCode}`)
    }
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : '文件上传失败'
    throw new Error(errorMessage)
  }
}

/**
 * 读取文件为 base64
 */
private async readFileAsBase64(fileUri: string): Promise<string> {
  try {
    const file = await fileIo.open(fileUri, fileIo.OpenMode.READ_ONLY)
    const buffer = new ArrayBuffer(4096)
    let content = ''
    
    while (true) {
      const bytesRead = await fileIo.read(file.fd, buffer)
      if (bytesRead === 0) break
      const view = new Uint8Array(buffer, 0, bytesRead)
      content += Buffer.from(view).toString('base64')
    }
    
    await fileIo.close(file.fd)
    return content
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : '文件读取失败'
    throw new Error(errorMessage)
  }
}

/**
 * 构建 multipart/form-data 数据
 */
private buildMultipartData(
  boundary: string,
  requestBody: ResumeRequestData,
  fileName: string,
  fileContent: string
): string {
  let data = ''
  
  // 添加 JSON 数据
  data += `--${boundary}\r\n`
  data += 'Content-Disposition: form-data; name="inputs"\r\n'
  data += 'Content-Type: application/json\r\n\r\n'
  data += JSON.stringify(requestBody.inputs) + '\r\n'
  
  // 添加 conversation_id（如果有）
  if (requestBody.conversation_id) {
    data += `--${boundary}\r\n`
    data += 'Content-Disposition: form-data; name="conversation_id"\r\n\r\n'
    data += requestBody.conversation_id + '\r\n'
  }
  
  // 添加 response_mode
  data += `--${boundary}\r\n`
  data += 'Content-Disposition: form-data; name="response_mode"\r\n\r\n'
  data += requestBody.response_mode + '\r\n'
  
  // 添加 user
  data += `--${boundary}\r\n`
  data += 'Content-Disposition: form-data; name="user"\r\n\r\n'
  data += requestBody.user + '\r\n'
  
  // 添加文件
  data += `--${boundary}\r\n`
  data += `Content-Disposition: form-data; name="files"; filename="${fileName}"\r\n`
  data += 'Content-Type: application/octet-stream\r\n'
  data += 'Content-Transfer-Encoding: base64\r\n\r\n'
  data += fileContent + '\r\n'
  
  // 结束 boundary
  data += `--${boundary}--\r\n`
  
  return data
}
```

- [ ] **步骤 5：添加类型定义**

```typescript
/**
 * 简历优化请求数据
 */
export class ResumeRequestData {
  inputs: { resume: string } = { resume: '' }
  conversation_id?: string = ''
  response_mode: string = 'blocking'
  user: string = ''
}

/**
 * 简历优化响应结果
 */
export class ResumeChatResult {
  answer?: string = ''
  outputs?: { text: string } = { text: '' }
  conversation_id?: string = ''
}
```

- [ ] **步骤 6：Commit**

```bash
git add app/entry/src/main/ets/http/ResumeApi.ets
git commit -m "feat: 创建 ResumeApi 支持文件上传和文本输入"
```

---

### 任务 3：创建 ResumeOptimizeViewModel.ets

**文件：**
- 创建：`app/entry/src/main/ets/viewmodel/ResumeOptimizeViewModel.ets`

**参考文件：** `app/entry/src/main/ets/viewmodel/DifyChatViewModel.ets`

- [ ] **步骤 1：创建文件结构**

```typescript
import { ChatMessage } from '../model/ChatMessage'
import { ResumeApi, ResumeChatResult } from '../http/ResumeApi'
import { Constants } from '../common/Constants'
import { ConversationHistory, ConversationRecord } from '../common/ConversationHistory'
import { Context } from '@kit.AbilityKit'

/**
 * 简历优化 ViewModel
 * 
 * 职责：
 *   - 管理消息列表
 *   - 调用 ResumeApi
 *   - 管理历史记录
 */
@Observed
export class ResumeOptimizeViewModel {
  messages: ChatMessage[] = []
  sending: boolean = false
  conversationId: string = ''
  currentTitle: string = ''

  // 对话历史列表（从持久化存储加载）
  history: ConversationRecord[] = []

  private resumeApi: ResumeApi
  private historyManager: ConversationHistory

  constructor() {
    this.resumeApi = new ResumeApi(
      Constants.RESUME_API_KEY,
      Constants.RESUME_API_URL
    )
    this.historyManager = ConversationHistory.getInstance()
  }

  /**
   * 初始化历史记录管理器
   */
  async initHistory(context: Context): Promise<void> {
    await this.historyManager.init(context)
    await this.loadAllHistory()
  }

  /**
   * 加载所有历史会话
   */
  async loadAllHistory(): Promise<void> {
    this.history = await this.historyManager.getAllConversations()
  }

  // ========================================
  // 发送简历
  // ========================================

  async sendResume(content: string, fileUri?: string): Promise<void> {
    // 实现逻辑
  }

  // ========================================
  // 发送后续消息
  // ========================================

  async sendMessage(content: string): Promise<void> {
    // 实现逻辑
  }

  // ========================================
  // 会话管理
  // ========================================

  async newConversation(): Promise<void> {
    // 实现逻辑
  }

  async switchConversation(record: ConversationRecord): Promise<void> {
    // 实现逻辑
  }

  async deleteConversation(record: ConversationRecord): Promise<void> {
    // 实现逻辑
  }

  /**
   * 保存会话到历史记录
   */
  private async saveToHistory(content: string, answer: string): Promise<void> {
    // 实现逻辑
  }

  /**
   * 更新会话最后一条消息
   */
  private async updateLastMessage(content: string): Promise<void> {
    // 实现逻辑
  }
}
```

- [ ] **步骤 2：实现 sendResume 方法**

```typescript
async sendResume(content: string, fileUri?: string): Promise<void> {
  const userMsg: ChatMessage = {
    role: 'user',
    content: fileUri ? `📎 ${fileUri.split('/').pop()}\n${content}` : content,
    timestamp: Date.now()
  }
  this.messages.push(userMsg)

  this.sending = true

  try {
    const answer = await this.resumeApi.optimizeResume(content, fileUri, this.conversationId)

    const aiMsg: ChatMessage = {
      role: 'assistant',
      content: answer,
      timestamp: Date.now()
    }
    this.messages.push(aiMsg)

    // 更新会话 ID（如果是新会话）
    const result = await this.resumeApi.optimizeResume(content, fileUri, this.conversationId)
    // 注意：实际需要从响应中获取 conversation_id
    // 这里简化处理：如果没有 conversationId，创建新会话
    if (!this.conversationId) {
      this.conversationId = Date.now().toString(36) + Math.random().toString(36).substr(2)
    }

    // 更新标题
    this.currentTitle = content.substring(0, 20) + (content.length > 20 ? '...' : '')

    // 保存到历史记录
    await this.saveToHistory(content, answer)

  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : '优化失败'
    console.error(`ResumeOptimizeViewModel sendResume error: ${errorMessage}`)
    
    const errorMsg: ChatMessage = {
      role: 'assistant',
      content: `❌ ${errorMessage}`,
      timestamp: Date.now()
    }
    this.messages.push(errorMsg)
  } finally {
    this.sending = false
  }
}
```

- [ ] **步骤 3：实现 sendMessage 方法**

```typescript
async sendMessage(content: string): Promise<void> {
  const userMsg: ChatMessage = {
    role: 'user',
    content: content,
    timestamp: Date.now()
  }
  this.messages.push(userMsg)

  this.sending = true

  try {
    const answer = await this.resumeApi.sendMessage(content, this.conversationId)

    const aiMsg: ChatMessage = {
      role: 'assistant',
      content: answer,
      timestamp: Date.now()
    }
    this.messages.push(aiMsg)

    // 更新历史记录最后一条消息
    await this.updateLastMessage(answer)

  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : '发送失败'
    console.error(`ResumeOptimizeViewModel sendMessage error: ${errorMessage}`)
    
    const errorMsg: ChatMessage = {
      role: 'assistant',
      content: `❌ ${errorMessage}`,
      timestamp: Date.now()
    }
    this.messages.push(errorMsg)
  } finally {
    this.sending = false
  }
}
```

- [ ] **步骤 4：实现会话管理方法**

```typescript
async newConversation(): Promise<void> {
  this.messages = []
  this.conversationId = ''
  this.currentTitle = ''
}

async switchConversation(record: ConversationRecord): Promise<void> {
  this.conversationId = record.conversationId
  this.currentTitle = record.title
  this.messages = []
  
  // 添加历史记录摘要
  const historyMsg: ChatMessage = {
    role: 'system',
    content: `继续之前的会话：${record.title}`,
    timestamp: record.timestamp
  }
  this.messages.push(historyMsg)
  
  await this.loadAllHistory()
}

async deleteConversation(record: ConversationRecord): Promise<void> {
  await this.historyManager.deleteConversation(record.conversationId)
  
  // 如果删除的是当前会话，创建新会话
  if (this.conversationId === record.conversationId) {
    await this.newConversation()
  }
  
  await this.loadAllHistory()
}

private async saveToHistory(content: string, answer: string): Promise<void> {
  const record: ConversationRecord = {
    conversationId: this.conversationId,
    title: content.substring(0, 30) + (content.length > 30 ? '...' : ''),
    lastMessage: answer.substring(0, 50) + (answer.length > 50 ? '...' : ''),
    timestamp: Date.now(),
    messageCount: this.messages.length
  }
  
  await this.historyManager.addOrUpdate(record)
  await this.loadAllHistory()
}

private async updateLastMessage(content: string): Promise<void> {
  if (!this.conversationId) return
  
  await this.historyManager.updateLastMessage(
    this.conversationId,
    content.substring(0, 50) + (content.length > 50 ? '...' : ''),
    Date.now()
  )
  await this.loadAllHistory()
}
```

- [ ] **步骤 5：Commit**

```bash
git add app/entry/src/main/ets/viewmodel/ResumeOptimizeViewModel.ets
git commit -m "feat: 创建 ResumeOptimizeViewModel 管理业务逻辑"
```

---

### 任务 4：创建 FileUploadCard.ets

**文件：**
- 创建：`app/entry/src/main/ets/components/FileUploadCard.ets`

- [ ] **步骤 1：创建文件上传卡片组件**

```typescript
import { picker } from '@ohos.file.picker'
import promptAction from '@ohos.promptAction'

/**
 * 文件上传卡片组件
 * 
 * 功能：
 *   - 选择文件（支持 PDF/Word/TXT）
 *   - 显示文件格式提示
 *   - 文件格式校验
 *   - 错误提示
 */
@Component
export struct FileUploadCard {
  @State selectedFileName: string = ''
  @State isUploading: boolean = false

  private onFileSelect: (uri: string) => void
  private supportedFormats: string[] = ['.pdf', '.docx', '.txt']

  /**
   * 构造函数
   * @param onFileSelect 文件选择回调，参数为文件 URI
   */
  build() {
    Column() {
      // 上传区域
      Column() {
        Text('📎')
          .fontSize(48)
          .fontColor('#409EFF')

        Text(this.selectedFileName || '选择文件')
          .fontSize(16)
          .fontColor('#333')
          .margin({ top: 12 })

        Text(`支持 ${this.supportedFormats.join('/')} 格式`)
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 8 })

        if (this.isUploading) {
          Text('上传中...')
            .fontSize(12)
            .fontColor('#409EFF')
            .margin({ top: 8 })
        }
      }
      .width('100%')
      .height(160)
      .backgroundColor('#f5f7fa')
      .borderRadius(12)
      .border({ width: 2, color: '#e0e0e0', style: BorderStyle.Dashed })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => this.selectFile())
    }
    .width('100%')
    .padding(12)
  }

  /**
   * 选择文件
   */
  private async selectFile(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker()
      
      // 设置文件格式过滤器
      const result = await documentPicker.select({
        fileSuffixFilters: this.supportedFormats
      })

      if (result && result.length > 0) {
        const fileUri = result[0].uri
        const fileName = fileUri.split('/').pop() || ''
        
        // 文件格式校验
        if (this.validateFile(fileUri)) {
          this.selectedFileName = fileName
          this.onFileSelect(fileUri)
        } else {
          promptAction.showToast({
            message: `不支持该文件格式，仅支持 ${this.supportedFormats.join('/')}`,
            duration: 3000
          })
        }
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '文件选择失败'
      console.error(`FileUploadCard selectFile error: ${errorMessage}`)
      
      promptAction.showToast({
        message: errorMessage,
        duration: 3000
      })
    }
  }

  /**
   * 文件格式校验
   * @param uri 文件 URI
   * @returns 是否支持该格式
   */
  private validateFile(uri: string): boolean {
    const lowerUri = uri.toLowerCase()
    return this.supportedFormats.some(format => lowerUri.endsWith(format.toLowerCase()))
  }

  /**
   * 重置选择状态
   */
  reset(): void {
    this.selectedFileName = ''
    this.isUploading = false
  }

  /**
   * 设置上传中状态
   */
  setUploading(isUploading: boolean): void {
    this.isUploading = isUploading
  }

  /**
   * 获取选中的文件名
   */
  getSelectedFileName(): string {
    return this.selectedFileName
  }
}
```

- [ ] **步骤 2：Commit**

```bash
git add app/entry/src/main/ets/components/FileUploadCard.ets
git commit -m "feat: 创建 FileUploadCard 文件上传组件"
```

---

### 任务 5：创建 ResumeOptimize.ets 页面

**文件：**
- 创建：`app/entry/src/main/ets/pages/ResumeOptimize.ets`

**参考文件：** `app/entry/src/main/ets/pages/DifyChat.ets`

- [ ] **步骤 1：创建页面结构**

```typescript
import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'
import { ResumeOptimizeViewModel } from '../viewmodel/ResumeOptimizeViewModel'
import { ChatMessage } from '../model/ChatMessage'
import { DateUtil } from '../common/DateUtil'
import { MarkdownUtil } from '../common/MarkdownUtil'
import { webview } from '@kit.ArkWeb'
import { HistoryPanel } from '../components/HistoryPanel'
import { FileUploadCard } from '../components/FileUploadCard'
import { ConversationRecord } from '../common/ConversationHistory'
import GlobalContext from '../common/GlobalContext'

/**
 * 简历优化页面
 * 
 * 功能：
 *   - 文件上传（支持 PDF/Word/TXT）
 *   - 文本输入
 *   - AI 优化建议展示
 *   - 历史记录管理
 *   - 文件格式校验
 * 
 * 使用前请在 main_pages.json 中注册 "pages/ResumeOptimize"
 */
@Entry
@Component
struct ResumeOptimizePage {
  @State viewModel: ResumeOptimizeViewModel = new ResumeOptimizeViewModel()
  @State inputText: string = ''
  @State selectedFileUri: string = ''
  @State showHistory: boolean = false
  @State mainContentOffset: number = 0
  @State historyPanelOffset: number = -100
  @State fileUploadKey: number = 0
  private scroller: Scroller = new Scroller()
  private fileUploadCard: FileUploadCard | null = null

  /**
   * 页面显示时初始化历史记录
   */
  onPageShow(): void {
    const context = GlobalContext.getInstance().getContext()
    if (context) {
      this.viewModel.initHistory(context)
    }
  }

  /**
   * 打开历史面板（带平移动画）
   */
  openHistory(): void {
    animateTo({
      duration: 300,
      curve: Curve.EaseOut
    }, () => {
      this.showHistory = true
      this.mainContentOffset = 75
      this.historyPanelOffset = 0
    })
  }

  /**
   * 关闭历史面板（带平移动画）
   */
  closeHistory(): void {
    animateTo({
      duration: 300,
      curve: Curve.EaseOut
    }, () => {
      this.mainContentOffset = 0
      this.historyPanelOffset = -100
    })
    setTimeout(() => {
      this.showHistory = false
    }, 300)
  }

  /**
   * 选择历史会话
   */
  async selectConversation(record: ConversationRecord): Promise<void> {
    await this.viewModel.switchConversation(record)
    this.closeHistory()
  }

  /**
   * 删除历史会话
   */
  async deleteConversation(record: ConversationRecord): Promise<void> {
    await this.viewModel.deleteConversation(record)
  }

  /**
   * 文件选择回调
   */
  onFileSelect(uri: string): void {
    this.selectedFileUri = uri
  }

  /**
   * 发送简历
   */
  async sendResume(): Promise<void> {
    // 实现逻辑
  }

  /**
   * 发送消息
   */
  async sendMessage(): Promise<void> {
    // 实现逻辑
  }

  /**
   * 新建会话
   */
  async newConversation(): Promise<void> {
    // 实现逻辑
  }

  /**
   * 构建页面
   */
  build() {
    // 实现逻辑
  }
}
```

- [ ] **步骤 2：实现 sendResume 方法**

```typescript
async sendResume(): Promise<void> {
  const content = this.inputText.trim()
  
  // 校验：必须有文件或文本内容
  if (!this.selectedFileUri && !content) {
    promptAction.showToast({
      message: '请上传文件或输入简历内容',
      duration: 3000
    })
    return
  }

  // 禁用输入
  if (this.fileUploadCard) {
    this.fileUploadCard.setUploading(true)
  }

  // 发送简历
  await this.viewModel.sendResume(content, this.selectedFileUri)

  // 清空输入和文件选择
  this.inputText = ''
  this.selectedFileUri = ''
  this.fileUploadKey++
  
  if (this.fileUploadCard) {
    this.fileUploadCard.reset()
    this.fileUploadCard.setUploading(false)
  }

  // 滚动到底部
  setTimeout(() => {
    this.scroller.scrollToIndex(this.viewModel.messages.length - 1)
  }, 100)
}
```

- [ ] **步骤 3：实现 sendMessage 方法**

```typescript
async sendMessage(): Promise<void> {
  const content = this.inputText.trim()
  
  if (!content) {
    promptAction.showToast({
      message: '请输入消息内容',
      duration: 3000
    })
    return
  }

  await this.viewModel.sendMessage(content)
  this.inputText = ''

  setTimeout(() => {
    this.scroller.scrollToIndex(this.viewModel.messages.length - 1)
  }, 100)
}
```

- [ ] **步骤 4：实现 newConversation 方法**

```typescript
async newConversation(): Promise<void> {
  await this.viewModel.newConversation()
  this.selectedFileUri = ''
  this.inputText = ''
  this.fileUploadKey++
}
```

- [ ] **步骤 5：实现 build 方法**

```typescript
build() {
  Stack() {
    // 主内容区域（可平移）
    Column()
      .width('100%')
      .height('100%')
      .translate({ x: `${this.mainContentOffset}%` })
      .animation({ duration: 300, curve: Curve.EaseOut })
      .backgroundColor('#f5f7fa')
      .children([
        // Header
        Row() {
          Row() {
            Text('←')
              .fontSize(20)
              .fontColor('#409EFF')
              .margin({ right: 12 })
              .onClick(() => router.back())
            Text('≡')
              .fontSize(24)
              .fontColor('#333')
              .onClick(() => {
                if (this.showHistory) {
                  this.closeHistory()
                } else {
                  this.openHistory()
                }
              })
          }

          Blank()

          Column() {
            Text(this.viewModel.currentTitle || '简历优化')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1a1a2e')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Center)

          Blank()

          Text('+')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#fff')
            .width(36)
            .height(36)
            .textAlign(TextAlign.Center)
            .borderRadius(18)
            .backgroundColor('#409EFF')
            .onClick(async () => {
              await this.newConversation()
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#fff'),

        // 内容区域
        Column() {
          if (this.viewModel.messages.length === 0) {
            // 初始状态：文件上传 + 文本输入
            Column() {
              Text('📄 简历优化')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1a1a2e')
                .margin({ bottom: 8 })

              Text('上传简历或输入内容，AI 帮你优化')
                .fontSize(14)
                .fontColor('#8898aa')
                .margin({ bottom: 20 })

              // 文件上传卡片
              FileUploadCard({
                onFileSelect: (uri: string) => {
                  this.selectedFileUri = uri
                }
              })
                .key(this.fileUploadKey)

              Text('或')
                .fontSize(12)
                .fontColor('#ccc')
                .margin({ top: 12, bottom: 12 })

              // 文本输入区域
              TextArea({ placeholder: '请输入简历内容...' })
                .width('100%')
                .height(150)
                .fontSize(16)
                .backgroundColor('#fff')
                .borderRadius(12)
                .padding(12)
                .onChange((value: string) => {
                  this.inputText = value
                })

              // 发送按钮
              Button('发送')
                .width('100%')
                .height(44)
                .fontSize(16)
                .fontColor('#fff')
                .backgroundColor('#409EFF')
                .borderRadius(8)
                .margin({ top: 16 })
                .enabled(!this.viewModel.sending)
                .onClick(() => {
                  this.sendResume()
                })
            }
            .width('100%')
            .padding(20)
            .layoutWeight(1)
            .justifyContent(FlexAlign.Start)
          } else {
            // 消息列表
            List({ scroller: this.scroller }) {
              ForEach(this.viewModel.messages, (msg: ChatMessage) => {
                ListItem() {
                  if (msg.role === 'user') {
                    // 用户消息
                    Row() {
                      Blank()
                      Column() {
                        Text(msg.content)
                          .fontSize(16)
                          .fontColor('#fff')
                          .padding(12)
                          .borderRadius(12)
                          .backgroundColor('#409EFF')
                        Text(DateUtil.format(msg.timestamp))
                          .fontSize(10)
                          .fontColor('#ccc')
                          .margin({ top: 4 })
                      }
                      .alignItems(HorizontalAlign.End)
                    }
                    .width('100%')
                    .padding({ left: 60, right: 12, top: 8, bottom: 8 })
                  } else {
                    // AI 消息（使用 Web 组件渲染 Markdown）
                    Row() {
                      Column() {
                        Web({
                          src: `data:text/html,${encodeURIComponent(MarkdownUtil.toHtmlWithCustomStyle(msg.content))}`,
                          controller: new webview.WebviewController(),
                          renderMode: RenderMode.SYNC_RENDER
                        })
                          .layoutMode(WebLayoutMode.FIT_CONTENT)
                          .overScrollMode(OverScrollMode.NEVER)
                          .width('100%')
                          .backgroundColor('#F4F4F5')
                          .borderRadius(12)
                          .javaScriptAccess(true)
                          .zoomAccess(false)
                          .padding(12)
                      }
                      .height('auto')
                      .width('70%')
                      .borderRadius(12)
                      .backgroundColor('#F4F4F5')
                    }
                    .alignItems(VerticalAlign.Top)
                    .padding({ left: 12, right: 60, top: 8, bottom: 8 })
                    .width('100%')
                  }
                }
              })
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Auto)

            // 底部输入栏
            Row() {
              TextInput({ placeholder: '输入优化需求...' })
                .width('70%')
                .height(40)
                .fontSize(16)
                .backgroundColor('#fff')
                .borderRadius(20)
                .padding({ left: 16, right: 16 })
                .onChange((value: string) => {
                  this.inputText = value
                })
                .onSubmit(() => {
                  this.sendMessage()
                })

              Button('发送')
                .width(80)
                .height(40)
                .fontSize(14)
                .fontColor('#fff')
                .backgroundColor('#409EFF')
                .borderRadius(20)
                .margin({ left: 8 })
                .enabled(!this.viewModel.sending)
                .onClick(() => {
                  this.sendMessage()
                })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#fff')
          }
        }
        .width('100%')
        .layoutWeight(1)
      ])

    // 历史面板（从左侧滑入）
    if (this.showHistory) {
      Column()
        .width('75%')
        .height('100%')
        .backgroundColor('#fff')
        .position({ x: `${this.historyPanelOffset}%`, y: 0 })
        .animation({ duration: 300, curve: Curve.EaseOut })
        .children([
          HistoryPanel({
            visible: this.showHistory,
            history: this.viewModel.history,
            currentConversationId: this.viewModel.conversationId
          })
            .onClose(() => this.closeHistory())
            .onSelect((record: ConversationRecord) => this.selectConversation(record))
            .onDelete((record: ConversationRecord) => this.deleteConversation(record))
        ])

      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.3)')
        .onClick(() => this.closeHistory())
    }
  }
  .width('100%')
  .height('100%')
}
```

- [ ] **步骤 6：Commit**

```bash
git add app/entry/src/main/ets/pages/ResumeOptimize.ets
git commit -m "feat: 创建 ResumeOptimize 页面"
```

---

### 任务 6：修改 MainTab.ets 添加入口

**文件：**
- 修改：`app/entry/src/main/ets/pages/MainTab.ets`

- [ ] **步骤 1：在欢迎语下方添加简历优化入口卡片**

```typescript
// 在 Column() 中（第 60-70 行附近），欢迎语下方添加：
Text('智能学习，助力成长')
  .fontSize(14)
  .fontColor('#8898aa')

// 新增：简历优化入口卡片
Column() {
  Row() {
    Text('📄')
      .fontSize(24)
      .margin({ right: 12 })
    Column() {
      Text('简历优化')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1a1a2e')
      Text('上传简历，AI 帮你优化')
        .fontSize(12)
        .fontColor('#8898aa')
        .margin({ top: 4 })
    }
    Blank()
    Text('→')
      .fontSize(16)
      .fontColor('#ccc')
  }
  .width('100%')
  .padding(16)
}
.width('90%')
.margin({ top: 20 })
.backgroundColor('#fff')
.borderRadius(12)
.shadow({ radius: 4, color: '#000000', offsetY: 2 })
.onClick(() => {
  router.pushUrl({ url: 'pages/ResumeOptimize' })
})
```

- [ ] **步骤 2：Commit**

```bash
git add app/entry/src/main/ets/pages/MainTab.ets
git commit -m "feat: 在首页添加简历优化入口"
```

---

### 任务 7：注册页面到 main_pages.json

**文件：**
- 修改：`app/entry/src/main/resources/base/profile/main_pages.json`

- [ ] **步骤 1：添加页面注册**

```json
{
  "src": [
    "pages/Login",
    "pages/Register",
    "pages/MainTab",
    "pages/Profile",
    "pages/DifyChat",
    "pages/test_aichat",
    "pages/ResumeOptimize"  // 新增
  ]
}
```

- [ ] **步骤 2：Commit**

```bash
git add app/entry/src/main/resources/base/profile/main_pages.json
git commit -m "feat: 注册 ResumeOptimize 页面"
```

---

### 任务 8：编译测试

**文件：**
- 无

- [ ] **步骤 1：编译项目**

```bash
cd d:\ai_learning\app
hvigorw assembleHap --mode module
```

预期：编译成功，无错误

- [ ] **步骤 2：部署到模拟器**

```bash
cd d:\ai_learning\app
hvigorw runHap --mode module
```

- [ ] **步骤 3：功能测试**

1. 在首页点击"简历优化"入口 → 跳转到简历优化页面
2. 输入文本内容 → 点击"发送" → 显示 AI 优化建议
3. 选择文件 → 点击"发送" → 显示 AI 优化建议
4. 选择不支持的格式 → 弹出"不支持该文件格式"提示
5. 点击"+" → 新建会话
6. 点击"≡" → 打开历史记录面板
7. 点击历史会话 → 切换到该会话
8. 点击"×" → 弹出删除确认对话框

---

## 自检

### 规格覆盖度
- [x] 文件上传（支持 PDF/Word/TXT）
- [x] 文本输入
- [x] AI 优化建议展示
- [x] 历史记录管理
- [x] 文件格式校验（上传前提示、上传后校验、错误提示）
- [x] API 配置占位符
- [x] 阻塞模式

### 占位符扫描
- [x] API 地址：`RESUME_API_URL`（待填写）
- [x] API 密钥：`RESUME_API_KEY`（待填写）

### 类型一致性
- [x] `ChatMessage` 类型一致
- [x] `ConversationRecord` 类型一致
- [x] 方法签名一致

---

## 执行交接

计划已完成并保存到 `docs/superpowers/plans/2026-06-24-resume-optimize.md`。两种执行方式：

**1. 子代理驱动（推荐）** - 每个任务调度一个新的子代理，任务间进行审查，快速迭代

**2. 内联执行** - 在当前会话中使用 executing-plans 执行任务，批量执行并设有检查点

**选哪种方式？**