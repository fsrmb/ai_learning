# Spring AI Chat 模块设计文档

**日期：** 2026-06-29  
**状态：** 待审查  
**范围：** 后端 Spring AI Chat 接口实现

---

## 1. 概述

### 1.1 目标
重构后端 Chat 模块，实现完整的 AI 对话功能，支持：
- 多轮对话上下文（数据库持久化）
- SSE 流式输出（打字机效果）
- 会话管理（创建、查询、历史记录）
- 移动端友好接口

### 1.2 技术栈
- Spring AI 1.0.0（已集成）
- DeepSeek API（`deepseek-v4-flash` 模型）
- MyBatis-Plus（数据库访问）
- SSE（Server-Sent Events，流式响应）

---

## 2. API 设计

### 2.1 接口列表

| 接口 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 创建会话 | POST | `/api/chat/conversation` | 返回 conversationId |
| 同步聊天 | POST | `/api/chat/message` | 返回完整回复 |
| 流式聊天 | POST | `/api/chat/stream` | SSE 打字机效果 |
| 查询历史 | GET | `/api/chat/history/{conversationId}` | 返回消息列表（分页） |
| 会话列表 | GET | `/api/chat/conversations` | 返回用户所有会话 |

### 2.2 认证方式
使用 `X-User-Id` 请求头，与现有移动端接口保持一致。

### 2.3 请求数据结构

#### 创建会话
```json
{
  "agentType": "CHAT",  // 必填：CHAT/CODING/WRITING
  "title": "可选，默认自动生成"
}
```

#### 发送消息
```json
{
  "conversationId": 123,
  "message": "用户输入的内容"
}
```

### 2.4 响应数据结构

#### 会话创建响应
```json
{
  "code": 200,
  "data": {
    "conversationId": 123,
    "title": "关于 Java 的讨论",
    "createdAt": "2026-06-29 10:00:00"
  }
}
```

#### 同步聊天响应
```json
{
  "code": 200,
  "data": {
    "messageId": 456,
    "content": "AI 回复内容",
    "createdAt": "2026-06-29 10:01:00"
  }
}
```

#### 消息历史响应
```json
{
  "code": 200,
  "data": {
    "total": 50,
    "page": 1,
    "size": 20,
    "messages": [
      {
        "id": 1,
        "role": "USER",
        "content": "用户消息",
        "createdAt": "2026-06-29 09:00:00"
      },
      {
        "id": 2,
        "role": "ASSISTANT",
        "content": "AI 回复",
        "createdAt": "2026-06-29 09:01:00"
      }
    ]
  }
}
```

---

## 3. 数据流设计

### 3.1 同步聊天流程
```
移动端 POST /api/chat/message
    ↓
ChatController 接收请求（提取 X-User-Id）
    ↓
ChatService.sendMessage(conversationId, message, userId)
    ↓
┌─────────────────────────────────────────────┐
│  1. 验证会话归属（userId 匹配）              │
│  2. 加载历史消息（最近 N 条）                │
│  3. 保存用户消息到数据库                     │
│  4. 构建 ChatClient Prompt（历史+新消息）    │
│  5. 调用 DeepSeek API                        │
│  6. 保存 AI 回复到数据库                     │
│  7. 返回响应                                 │
└─────────────────────────────────────────────┘
    ↓
返回 ChatResponseVO
```

### 3.2 SSE 流式聊天流程
```
移动端 POST /api/chat/stream
    ↓
ChatController 创建 SseEmitter（超时 2 分钟）
    ↓
异步执行 ChatService.streamMessage(...)
    ↓
┌─────────────────────────────────────────────┐
│  1. 验证会话归属                             │
│  2. 加载历史消息                             │
│  3. 保存用户消息                             │
│  4. ChatClient.stream() 调用 DeepSeek        │
│  5. 每个 chunk → emitter.send(chunk)        │
│  6. 完成后保存完整回复                       │
│  7. emitter.complete()                      │
└─────────────────────────────────────────────┘
```

### 3.3 多轮对话上下文策略
- 加载最近 10 条历史消息作为上下文
- 按 `createdAt` 升序排列
- 包含 USER 和 ASSISTANT 角色
- 超过 10 条时丢弃最早的消息（避免 token 超限）

---

## 4. 组件架构

### 4.1 文件结构
```
com.aicompanion
├── controller
│   └── ChatController          # REST API 入口
├── service
│   ├── ChatService             # 接口定义
│   └── ChatServiceImpl         # 业务实现
├── mapper
│   ├── ChatConversationMapper  # 会话数据访问
│   └── ChatMessageMapper       # 消息数据访问
├── model
│   ├── dto
│   │   ├── ChatRequestDTO      # 发送消息请求
│   │   └── CreateConversationDTO  # 创建会话请求
│   └── vo
│       ├── ChatResponseVO      # 聊天响应
│       ├── ConversationVO      # 会话信息
│       └── MessageVO           # 消息信息
│   └── entity
│       ├── ChatConversation    # 已存在
│       └── ChatMessage         # 已存在
```

### 4.2 类职责说明

| 类 | 职责 |
|---|------|
| `ChatController` | 接收 HTTP 请求，验证参数，调用 Service，返回响应 |
| `ChatService` | 定义业务接口 |
| `ChatServiceImpl` | 实现业务逻辑：会话验证、消息保存、AI 调用 |
| `ChatConversationMapper` | 会话表 CRUD |
| `ChatMessageMapper` | 消息表 CRUD |

---

## 5. 数据库表结构

### 5.1 chat_conversation 表（已存在）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键 |
| user_id | BIGINT | 所属用户 |
| title | VARCHAR(100) | 会话标题 |
| agent_type | VARCHAR(20) | 代理类型：CHAT |
| status | VARCHAR(20) | 状态：ACTIVE/ARCHIVED |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |
| deleted | INT | 逻辑删除标志 |

### 5.2 chat_message 表（已存在）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键 |
| conversation_id | BIGINT | 所属会话 |
| role | VARCHAR(20) | 角色：USER/ASSISTANT/SYSTEM |
| content | TEXT | 消息内容 |
| message_type | VARCHAR(20) | 类型：TEXT/IMAGE/FILE |
| dify_message_id | VARCHAR(50) | 平台消息 ID（可选） |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |
| deleted | INT | 逻辑删除标志 |

---

## 6. 错误处理

| 场景 | HTTP 状态 | 错误消息 |
|------|----------|----------|
| DeepSeek API 调用失败 | 503 | AI 服务暂时不可用 |
| 会话不存在 | 404 | 会话已过期或不存在 |
| 用户无权访问他人会话 | 403 | 无权访问该会话 |
| 消息内容过长（>5000字） | 400 | 消息长度超出限制 |
| conversationId 缺失 | 400 | 缺少会话 ID |
| SSE 连接超时 | 自动关闭 | 连接超时 |

---

## 7. 移动端适配

| 特性 | 说明 |
|------|------|
| 轻量响应 | 仅返回必要字段，减少数据传输 |
| 分页查询 | 历史消息默认 20 条/页 |
| 自动标题 | 首条消息截取前 20 字作为会话标题 |
| X-User-Id 认证 | 与现有移动端接口一致 |

---

## 8. 系统提示词

### 8.1 单一提示词方案

采用单一系统提示词，AI 根据对话内容自动判断任务类型：

```
你是"AI伴学助手"，一个面向大学生的智能学习伴侣。

你的职责：
1. 技术问答：回答编程问题（Java、Spring、数据库、前端等），解释概念时用通俗易懂的语言，配合代码示例
2. 代码审查：审查代码质量，指出潜在问题，提供优化建议和最佳实践
3. 写作助手：优化技术文章结构，修改简历，突出亮点，保持专业但友好的语气
4. 学习规划：根据用户当前水平，提供学习路径和资源推荐
5. 保持友好积极的语气，如果不确定，坦诚说明，不要编造答案
```

### 8.2 设计理由

**为什么不用多角色：**
- ✅ 简单直接：一个提示词覆盖所有场景
- ✅ 灵活性高：用户不需要提前选择角色，AI 根据对话内容自动判断
- ✅ 维护成本低：只需维护一个提示词
- ✅ token 效率：比多个提示词总和更少

**何时考虑多角色：**
- 需要强制行为边界（如：面试官必须按流程走）
- 需要统计不同场景数据（如：技术问答占比）
- 需要完全不同的人设（如：严肃的面试官 vs 活泼的伴学助手）

### 8.3 提示词迭代策略

1. **初始版本**：基础提示词，覆盖核心功能
2. **数据收集**：观察用户对话模式和反馈
3. **提示词优化**：根据数据调整提示词，提升回答质量
4. **按需扩展**：如果某个场景需要独立提示词，再引入 `agent_type` 区分

---

## 9. 待办事项

- [ ] 创建 ChatRequestDTO、CreateConversationDTO
- [ ] 创建 ChatResponseVO、ConversationVO、MessageVO
- [ ] 创建 ChatConversationMapper、ChatMessageMapper（XML）
- [ ] 重写 ChatController（5 个接口）
- [ ] 重写 ChatService 接口定义
- [ ] 重写 ChatServiceImpl（完整业务逻辑，单一提示词）
- [ ] 测试同步聊天接口
- [ ] 测试 SSE 流式聊天接口
- [ ] 测试会话历史查询

---

## 10. 安全注意事项

- API Key 硬编码在 `application.yml`，仅适合开发环境
- 生产环境建议改为环境变量：`${DEEPSEEK_API_KEY}`
- 用户隔离：所有接口验证 userId 归属