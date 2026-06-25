# 简历优化功能设计文档

**日期：** 2026-06-23
**方案：** 方案 2（独立实现，共享基础组件）

---

## 1. 功能概述

在首页添加"简历优化"入口，用户可以通过文件上传或文本输入两种方式提供简历内容，AI 返回**优化后的简历**。

**工作流：**
1. 获取文件 → 2. 初步分析并评分 → 3. 通过代码获取分数 → 4. 根据分数进入不同分支（A优化/B大改）→ 5. 输出优化后的简历

**重要说明：**
- 所有工作流（评分、分支判断、优化）都在**单个 API 内部完成**
- 前端只需调用一次 API，API 返回最终优化后的简历
- API 端点：`POST {RESUME_API_URL}/chat-messages`

**核心功能：**
- 文件上传（支持 PDF、Word、TXT）
- 文本输入
- AI 返回优化后的简历（直接返回修改后的结果）
- 历史记录管理
- 文件格式校验

---

## 2. 架构设计

### 2.1 组件结构

```
app/entry/src/main/ets/
├── pages/
│   └── ResumeOptimize.ets          # 简历优化页面
├── viewmodel/
│   └── ResumeOptimizeViewModel.ets # 业务逻辑
├── http/
│   └── ResumeApi.ets               # API 调用（支持文件上传）
├── components/
│   └── FileUploadCard.ets          # 文件上传卡片组件
└── common/
    ├── ResumeHistory.ts            # 历史记录管理
    └── Constants.ets               # API 配置（新增占位符）
```

### 2.2 数据流

```
用户操作
  ↓
ResumeOptimizePage（UI）
  ↓
ResumeOptimizeViewModel（业务逻辑）
  ↓
ResumeApi（API 调用）
  ↓
Dify API（简历优化工作流）
  ↓
返回优化建议
  ↓
ResumeOptimizeViewModel 更新消息列表
  ↓
ResumeOptimizePage 刷新 UI
```

---

## 3. 页面设计

### 3.1 首页入口（MainTab.ets）

在欢迎语下方添加卡片式入口：

```
┌─────────────────────────────┐
│  欢迎回来，username！         │
│  智能学习，助力成长           │
├─────────────────────────────┤
│  ┌─────────────────────────┐ │
│  │ 📄 简历优化              │ │
│  │ 上传简历或输入内容，AI   │ │
│  │ 帮你优化简历             │ │
│  └─────────────────────────┘ │
└─────────────────────────────┘
```

**实现：**
- 使用 `Column` 布局
- 卡片使用 `backgroundColor: #fff` + `borderRadius: 12` + `shadow`
- 点击跳转到 `pages/ResumeOptimize`

### 3.2 简历优化页面（ResumeOptimize.ets）

**布局结构：**

```
┌─────────────────────────────┐
│ ← 简历优化              +   │  ← Header（返回 + 新对话）
├─────────────────────────────┤
│                             │
│  ┌─────────────────────┐    │
│  │ 📎 选择文件         │    │  ← 文件上传区域
│  │ 支持 PDF/Word/TXT   │    │
│  └─────────────────────┘    │
│  或                          │
│  ┌─────────────────────┐    │
│  │ [输入简历内容...]   │    │  ← 文本输入区域
│  └─────────────────────┘    │
│                             │
│  [发送]                      │  ← 发送按钮
│                             │
│  ┌─────────────────────┐    │
│  │ 用户：简历内容...    │    │  ← 消息列表
│  │ AI：优化建议...      │    │
│  └─────────────────────┘    │
│                             │
├─────────────────────────────┤
│ [输入优化需求...] [发送]    │  ← 底部输入栏
└─────────────────────────────┘
```

**交互逻辑：**
1. 用户选择文件或输入文本
2. 点击"发送"按钮
3. 显示用户消息
4. 调用 API
5. 显示 AI 优化建议
6. 底部输入栏可继续输入优化需求

### 3.3 历史记录面板

复用 `HistoryPanel` 组件（与 DifyChat 一致）。

---

## 4. 核心组件设计

### 4.1 ResumeOptimizePage

**职责：**
- 页面 UI 渲染
- 处理用户交互（文件选择、文本输入、发送）
- 调用 ViewModel 方法

**状态：**
```typescript
@State viewModel: ResumeOptimizeViewModel
@State inputText: string
@State selectedFileUri: string | null
@State showHistory: boolean
```

**方法：**
- `selectFile()`：调用文件选择器
- `sendResume()`：发送简历内容
- `sendMessage()`：发送后续优化需求
- `openHistory()` / `closeHistory()`：历史记录面板控制

### 4.2 ResumeOptimizeViewModel

**职责：**
- 管理消息列表
- 调用 ResumeApi
- 管理历史记录

**属性：**
```typescript
messages: ChatMessage[]
sending: boolean
conversationId: string
currentTitle: string
history: ConversationRecord[]
```

**方法：**
- `sendResume(content: string, fileUri?: string)`：发送简历
- `sendMessage(content: string)`：发送后续消息
- `newConversation()`：新建会话
- `switchConversation(record)`：切换会话
- `deleteConversation(record)`：删除会话

### 4.3 ResumeApi

**职责：**
- 调用 Dify 简历优化 API
- 支持文件上传（multipart/form-data）

**方法：**
```typescript
async optimizeResume(
  content: string,
  fileUri?: string,
  conversationId?: string
): Promise<string>
```

**实现：**
- 如果有 `fileUri`，使用 `multipart/form-data` 上传文件
- 否则使用普通 JSON 请求
- 复用 `DifyApi` 的基础逻辑

### 4.4 FileUploadCard

**职责：**
- 文件上传卡片 UI
- 显示文件格式提示
- 错误提示

**属性：**
```typescript
@Prop onFileSelect: (uri: string) => void
@State selectedFileName: string
```

**UI：**
- 文件选择按钮
- 格式提示："支持 PDF/Word/TXT"
- 选中文件后显示文件名

---

## 5. 文件上传实现

### 5.1 文件选择器

使用 `@ohos.file.picker`：

```typescript
import { picker } from '@ohos.file.picker'

async selectFile(): Promise<string> {
  const documentPicker = new picker.DocumentViewPicker()
  const result = await documentPicker.select({
    fileSuffixFilters: ['.pdf', '.docx', '.txt']
  })
  return result[0].uri
}
```

### 5.2 文件格式校验

**上传前提示：**
- 在卡片上显示"支持 PDF/Word/TXT"

**上传后校验：**
```typescript
private validateFile(uri: string): boolean {
  const supportedFormats = ['.pdf', '.docx', '.txt']
  return supportedFormats.some(format => uri.endsWith(format))
}
```

**错误处理：**
```typescript
if (!this.validateFile(fileUri)) {
  promptAction.showToast({ message: '不支持该文件格式' })
  return
}
```

---

## 6. 历史记录管理

### 6.1 ResumeHistory

复用 `ConversationHistory` 的设计，创建独立的简历优化历史记录管理类。

**方法：**
- `init(context)`：初始化 Preferences
- `addOrUpdate(record)`：添加或更新会话
- `deleteConversation(id)`：删除会话
- `getAllConversations()`：获取所有会话

### 6.2 历史记录存储

使用 Preferences 持久化存储：

```typescript
{
  conversationId: string,
  title: string,
  lastMessage: string,
  timestamp: number,
  messageCount: number
}
```

---

## 7. API 配置

### 7.1 占位符配置

在 `Constants.ets` 中添加：

```typescript
export class Constants {
  // 简历优化 API 配置（待填写）
  static readonly RESUME_API_URL: string = ''  // 待填写
  static readonly RESUME_API_KEY: string = ''  // 待填写
}
```

### 7.2 API 调用格式

**文件上传：**
```
POST {RESUME_API_URL}/chat-messages
Content-Type: multipart/form-data

files: <file>
inputs: { resume: <content> }
conversation_id: <id>
response_mode: blocking
user: <username>
```

**文本输入：**
```
POST {RESUME_API_URL}/chat-messages
Content-Type: application/json

{
  "inputs": { "resume": <content> },
  "conversation_id": <id>,
  "response_mode": "blocking",
  "user": <username>
}
```

---

## 8. 错误处理

### 8.1 文件上传错误

| 错误类型 | 处理方式 |
|---------|---------|
| 格式不支持 | Toast 提示"不支持该文件格式" |
| 文件过大 | Toast 提示"文件大小超过限制" |
| 上传失败 | Toast 提示"上传失败，请重试" |

### 8.2 API 调用错误

| 错误类型 | 处理方式 |
|---------|---------|
| 网络错误 | Toast 提示"网络错误，请检查连接" |
| API 错误 | Toast 提示"优化失败，请稍后重试" |
| Token 失效 | 跳转到登录页 |

---

## 9. 测试计划

### 9.1 功能测试

- [ ] 文件上传（PDF、Word、TXT）
- [ ] 文本输入
- [ ] AI 优化建议展示
- [ ] 历史记录切换
- [ ] 历史记录删除
- [ ] 新建会话
- [ ] 文件格式校验

### 9.2 边界测试

- [ ] 上传不支持的格式
- [ ] 上传超大文件
- [ ] 网络断开时发送
- [ ] 空输入发送

### 9.3 兼容性测试

- [ ] 不同屏幕尺寸
- [ ] 不同文件格式版本

---

## 10. 未来扩展

### 10.1 下载优化后的简历

- 添加"下载"按钮
- 调用 API 生成优化后的简历文件
- 使用 `@ohos.file.fs` 保存文件

### 10.2 迁移到后端

- 修改 `ResumeApi` 调用后端 API
- 更新 `Constants.ets` 中的 API 地址
- 保持页面和 ViewModel 不变

---

## 11. 实现计划

1. 创建 `ResumeApi.ets`（支持文件上传）
2. 创建 `ResumeOptimizeViewModel.ets`（业务逻辑）
3. 创建 `FileUploadCard.ets`（文件上传组件）
4. 创建 `ResumeOptimize.ets`（页面 UI）
5. 修改 `MainTab.ets`（添加入口）
6. 更新 `main_pages.json`（注册页面）
7. 测试功能

---

## 12. 备注

- API 地址和密钥为占位符，待用户填写
- 当前仅支持阻塞模式
- 文件格式校验在前端进行，避免浪费 Token