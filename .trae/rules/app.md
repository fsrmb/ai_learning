---
alwaysApply: false
description: 编写/app下的文件（即移动端应用时）使用
---
# AiApp — AI 伴学与职业成长平台（HarmonyOS 客户端）

## 一、项目概述

AiApp 是"AI 伴学与职业成长平台"的 HarmonyOS NEXT 客户端，基于 ArkTS + ArkUI 声明式开发。

核心功能：
- 用户登录/注册：JWT 鉴权，Preferences 本地持久化 Token
- AI 聊天助手：与后端 AI Agent 对话（/api/ai/chat/message）
- AI 模拟面试：技术面试模拟、评分、报告（/api/interview/*）
- 技能树展示：分类展示技能点，支持点亮（/api/skills/*）
- 个人中心：用户信息查看与编辑（/api/users/me）

---

## 二、技术栈

| 项 | 技术 |
|------|------|
| 语言 | ArkTS（TypeScript 子集 + ArkTS 扩展） |
| UI 框架 | ArkUI 声明式开发范式 |
| 状态管理 | @State / @Prop / @Observed / @ObjectLink |
| 网络请求 | @kit.NetworkKit（http 模块） |
| 本地存储 | @kit.ArkData（preferences 模块） |
| 路由 | @kit.ArkUI（router 模块） |
| 目标系统 | HarmonyOS NEXT（API 12+） |
| SDK 版本 | compatibleSdkVersion: 6.0.0(20) |
| 构建工具 | Hvigor |
| 包管理 | ohpm（oh-package.json5） |

---

## 三、目录结构

```
app/
├── AppScope/
│   └── app.json5                    # 应用级配置（bundleName: com.mashang.aiapp）
├── entry/
│   ├── oh-package.json5             # 模块依赖声明
│   ├── build-profile.json5          # 构建配置
│   └── src/main/
│       ├── module.json5             # 模块配置（abilities、permissions）
│       ├── resources/               # 资源文件（图片、字符串、颜色）
│       │   └── base/profile/
│       │       └── main_pages.json  # 页面路由注册
│       └── ets/
│           ├── entryability/
│           │   └── EntryAbility.ets # 应用入口 Ability
│           ├── common/              # 工具类
│           │   ├── Constants.ets    # 常量（BASE_URL、TOKEN_KEY 等）
│           │   ├── TokenUtil.ets    # Token/用户信息持久化（Preferences）
│           │   └── DateUtil.ets     # 日期格式化工具
│           ├── model/               # 数据模型（纯类定义）
│           │   ├── User.ets         # User、LoginRequest、LoginResponse、RegisterRequest
│           │   ├── Skill.ets        # Skill（含 children: Skill[] 递归树结构）
│           │   └── ChatMessage.ets  # ChatMessage、ChatRequest、InterviewSession、InterviewQuestion
│           ├── http/                # 网络层
│           │   ├── HttpClient.ets   # 封装 http 请求，统一 Authorization、错误处理
│           │   ├── AuthApi.ets      # 认证接口（login / register）
│           │   ├── UserApi.ets      # 用户接口（getCurrentUser / updateUser）
│           │   ├── SkillApi.ets     # 技能树接口（getSkillTree / toggleSkill）
│           │   └── AiApi.ets        # AI 接口（sendMessage / startInterview / submitAnswer）
│           ├── viewmodel/           # 视图模型（@Observed）
│           │   ├── UserViewModel.ets
│           │   └── ChatViewModel.ets
│           ├── components/          # 可复用组件
│           │   ├── TabBar.ets       # 底部导航栏
│           │   ├── SkillTag.ets     # 技能标签（按分类着色）
│           │   └── EmptyView.ets    # 空状态占位
│           └── pages/               # 页面（@Entry @Component）
│               ├── Login.ets        # 登录页
│               ├── Register.ets     # 注册页
│               ├── MainTab.ets      # 主 Tab 容器
│               ├── Home.ets         # 首页（快捷入口 + 热门技能）
│               ├── SkillTree.ets    # 技能树页面
│               ├── AiChat.ets       # AI 聊天页面
│               ├── Interview.ets    # AI 面试页面
│               └── Profile.ets      # 个人中心
├── oh-package.json5                 # 工程级依赖
└── build-profile.json5              # 工程级构建配置
```

---

## 四、编码规范

### 4.1 ArkTS 类型要求（重要）

ArkTS 对类型有严格要求，必须遵守：

**接口和数组必须显式声明类型：**

```typescript
// ✅ 正确：interface 显式声明
interface TabItem {
  name: string
  icon: string
  path: string
}

// ❌ 错误：使用隐式对象字面量
const tab = { name: '首页', icon: '🏠', path: 'pages/Home' }  // 类型不明确

// ✅ 正确：数组显式标注类型
private tabs: TabItem[] = [
  { name: '首页', icon: '🏠', path: 'pages/Home' }
]

// ❌ 错误：不标注数组元素类型
private tabs = [{ name: '首页' }]  // 编译报错
```

**不要使用 any：**

```typescript
// ❌ 错误
let data: any = {}

// ✅ 正确：定义具体类型
interface ApiData {
  id: number
  name: string
}
let data: ApiData = { id: 0, name: '' }
```

**Record 类型用于键值映射：**

```typescript
// ✅ 正确
private getCategoryColor(): string {
  const colors: Record<string, string> = {
    'FRONTEND': '#409EFF',
    'BACKEND': '#67C23A'
  }
  return colors[this.category] || '#409EFF'
}
```

### 4.2 数据模型规范

数据模型放在 `model/` 目录，使用 `class` 定义（不用 interface），所有字段必须有默认值：

```typescript
// model/User.ets
export class User {
  id: number = 0
  username: string = ''
  nickname: string = ''
  email: string = ''
  role: string = ''
  avatar: string = ''
  createdAt: string = ''
}
```

接口请求/响应也用 class 定义：

```typescript
export class LoginRequest {
  username: string = ''
  password: string = ''
}

export class LoginResponse {
  token: string = ''
  userId: number = 0
  username: string = ''
  role: string = ''
}
```

### 4.3 网络层规范

所有 HTTP 请求统一通过 `HttpClient` 封装类，不要直接使用 `http.createHttp()`：

```typescript
// ✅ 正确
import { HttpClient } from '../http/HttpClient'

static async getSkillTree(): Promise<Skill[]> {
  return HttpClient.get<Skill[]>('/api/skills/tree')
}

// ❌ 错误：直接创建 http 请求
const httpRequest = http.createHttp()
httpRequest.request(url, { ... })
```

泛型参数 `<T>` 指定返回类型，确保类型安全。

### 4.4 页面规范

页面文件放在 `pages/` 目录，使用 `@Entry @Component struct`：

```typescript
@Entry
@Component
struct PageName {
  @State loading: boolean = false

  private context = getContext(this)

  build() {
    Column() {
      // UI 内容
    }
    .width('100%')
    .height('100%')
  }
}
```

新增页面后，必须在 `main_pages.json` 中注册：

```json
{
  "src": [
    "pages/Login",
    "pages/NewPage"
  ]
}
```

### 4.5 组件规范

可复用组件放在 `components/` 目录，使用 `@Component export struct`：

```typescript
@Component
export struct MyComponent {
  @Prop title: string = ''
  onTap: () => void = () => {}

  build() {
    // UI 内容
  }
}
```

### 4.6 状态管理规范

| 装饰器 | 用途 | 场景 |
|--------|------|------|
| @State | 组件内部状态 | 页面级可变数据 |
| @Prop | 父→子单向同步 | 组件接收外部参数 |
| @Observed | 可观察类 | ViewModel 中的数据类 |
| @ObjectLink | 搭配 @Observed | 子组件引用可观察对象 |

ViewModel 使用 `@Observed class`，放在 `viewmodel/` 目录。

### 4.7 路由规范

页面间跳转使用 `router` 模块：

```typescript
import { router } from '@kit.ArkUI'

// 跳转（可返回）
router.pushUrl({ url: 'pages/Register' })

// 替换（不可返回，用于登录→主页）
router.replaceUrl({ url: 'pages/MainTab' })
```

---

## 五、约束条件

1. **不要使用 TypeScript 特有的高级类型**（条件类型、模板字面量类型、Mapped Types 等），ArkTS 不支持
2. **不要使用 `any` 类型**，所有变量和参数必须有明确类型
3. **不要使用 `as` 进行不安全类型断言**，应使用类型守卫或定义正确的类型
4. **不要使用 `enum`**，使用 `const` 常量或字符串字面量替代
5. **不要使用 `require()` 导入**，统一使用 ESM `import`
6. **不要直接操作 DOM**，ArkUI 是声明式 UI，通过状态驱动渲染
7. **不要在 build() 函数中执行副作用**（网络请求、文件读写），应在生命周期函数中处理
8. **数组遍历必须使用 ForEach 并提供 keyGenerator**，不要用 `.map()`
9. **接口地址不要硬编码**，统一使用 `Constants.BASE_URL` + 路径
10. **Token 操作不要直接读写 Preferences**，统一使用 `TokenUtil` 工具类

---

## 六、后端接口参考

所有接口以 `Constants.BASE_URL`（当前为 `http://10.0.2.2:8080`）为基础地址。

| 模块 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 认证 | POST | /api/auth/login | 登录，返回 token |
| 认证 | POST | /api/auth/register | 注册 |
| 用户 | GET | /api/users/me | 获取当前用户信息 |
| 用户 | PUT | /api/users/{id} | 更新用户信息 |
| 技能 | GET | /api/skills/tree | 获取技能树 |
| 技能 | GET | /api/skills/tree/category/{category} | 按分类获取技能树 |
| 技能 | POST | /api/skills/toggle/{skillId} | 点亮/取消技能点 |
| AI | POST | /api/ai/chat/message | 发送聊天消息 |
| 面试 | POST | /api/interview/start | 开始面试（传 skillId） |
| 面试 | POST | /api/interview/answer | 提交面试答案 |
| 面试 | GET | /api/interview/session/{id} | 获取面试会话 |
| 面试 | GET | /api/interview/my | 获取我的面试记录 |

统一响应格式：
```typescript
interface ApiResponse<T> {
  code: number      // 200 表示成功
  message: string
  data: T
}
```

---

## 七、常见任务示例

### 7.1 新增一个页面

1. 在 `pages/` 下创建 `XxxPage.ets`
2. 在 `main_pages.json` 的 `src` 数组中添加 `"pages/XxxPage"`
3. 页面结构：

```typescript
import { router } from '@kit.ArkUI'

@Entry
@Component
struct XxxPage {
  @State loading: boolean = false

  build() {
    Column() {
      Text('页面标题')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}
```

### 7.2 新增一个 API 调用

1. 如果是新模块，在 `http/` 下创建 `XxxApi.ts`
2. 如果是已有模块，直接在对应 Api 文件中添加方法

```typescript
import { HttpClient } from './HttpClient'

// 定义响应类型
export class XxxData {
  id: number = 0
  name: string = ''
}

export class XxxApi {
  static async getXxxList(): Promise<XxxData[]> {
    return HttpClient.get<XxxData[]>('/api/xxx/list')
  }

  static async createXxx(data: XxxData): Promise<XxxData> {
    return HttpClient.post<XxxData>('/api/xxx', data)
  }
}
```

### 7.3 新增一个数据模型

在 `model/` 下创建 `.ets` 文件，使用 `class` + 默认值：

```typescript
export class NewModel {
  id: number = 0
  title: string = ''
  items: string[] = []        // 数组必须显式声明类型
  nested: SubModel[] = []     // 嵌套数组也必须显式声明
}

export class SubModel {
  key: string = ''
  value: number = 0
}
```

### 7.4 新增一个可复用组件

在 `components/` 下创建 `.ets` 文件：

```typescript
@Component
export struct MyCard {
  @Prop title: string = ''
  @Prop content: string = ''
  onClick: () => void = () => {}

  build() {
    Column() {
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
      Text(this.content)
        .fontSize(14)
        .fontColor('#666')
        .margin({ top: 8 })
    }
    .padding(16)
    .borderRadius(8)
    .backgroundColor('#fff')
    .width('100%')
    .onClick(this.onClick)
  }
}
```
