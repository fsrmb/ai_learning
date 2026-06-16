# AI 伴学平台 - HarmonyOS 移动端

## 技术栈
- 语言：ArkTS（基于 TypeScript，强类型）
- 框架：HarmonyOS NEXT SDK
- UI 组件：ArkUI（声明式 UI）
- 状态管理：@State、@Prop、@Link、@Provide/@Consume、AppStorage
- 网络请求：`@ohos.net.http` 或 axios 鸿蒙适配版（推荐封装为 service）
- 路由：Router 模块（`@ohos.router`）或 Navigation 组件
- 数据持久化：Preferences、DataAbilityHelper
- 构建工具：DevEco Studio 内置

## 目录结构
```
entry/src/main/ets/
├── pages/                  # 页面（每个页面一个 .ets 文件）
│   ├── LoginPage.ets       # 登录/注册页
│   ├── HomePage.ets        # 首页（功能导航）
│   ├── InterviewPage.ets   # AI 模拟面试页
│   ├── SkillAssessmentPage.ets  # 技能评估页
│   ├── StudyPlanPage.ets   # 学习计划页
│   └── ProfilePage.ets     # 个人中心页
├── components/             # 自定义组件（可复用）
│   ├── TabBar.ets          # 底部 Tab 栏
│   ├── SkillCard.ets       # 技能卡片
│   └── ChatBubble.ets      # 对话气泡（面试/聊天）
├── model/                  # 数据模型（接口/类）
│   ├── User.ets            # 用户信息模型
│   ├── Skill.ets           # 技能树模型
│   ├── Interview.ets       # 面试题目/回答模型
│   └── ApiResponse.ets     # 统一响应模型
├── api/                    # API 请求函数（按模块）
│   ├── userApi.ets         # 用户相关（登录、个人资料）
│   ├── skillApi.ets        # 技能树、技能评估
│   ├── interviewApi.ets    # 面试相关
│   └── studyApi.ets        # 学习记录、计划
├── utils/                  # 工具函数
│   ├── http.ets            # HTTP 封装（baseURL、Token、拦截器）
│   ├── storage.ets         # 本地存储（Preferences 封装）
│   ├── dateUtil.ets        # 日期格式化
│   └── validator.ets       # 表单校验
├── constants/              # 常量
│   ├── AppConstants.ets    # 应用常量（API 路径、角色等）
│   └── RoutePath.ets       # 路由路径常量
└── Application.ets         # 应用入口
```

## 编码规范

### 1. 语言与类型
- **必须使用 ArkTS**（禁止使用 JavaScript 或 TS 忽略类型）
- 所有变量、函数参数、返回值必须明确类型注解，避免 `any`
- 使用 `interface` 定义数据模型，使用 `class` 定义服务/工具类
- 示例：
  ```typescript
  // 良好
  let userName: string = "张三";
  function fetchUserInfo(userId: number): Promise<User> { ... }
  
  // 禁止
  let data: any = {};
  function doSomething(params) { ... }
  ```

### 2. 组件开发
- 使用 **声明式语法**（`@Component`、`@State`、`build()`）
- 组件命名采用 **大驼峰**（PascalCase），文件名与组件名一致
- 页面组件放在 `pages/`，公共组件放在 `components/`
- 组件内部状态用 `@State`，父子传值用 `@Prop` / `@Link`
- 避免在 `build()` 方法中写复杂逻辑，抽取为独立方法

### 3. 状态管理
- 页面级状态使用 `@State` + `@Provide`/`@Consume`
- 全局共享状态（用户登录信息、主题）使用 `AppStorage` 或 `LocalStorage`
- 不推荐使用 `@Observed` + `@ObjectLink` 除非对象嵌套较深

### 4. 网络请求
- 所有 HTTP 请求统一封装在 `utils/http.ets` 中
- 每个 API 模块（如 `userApi.ets`）导出函数，返回 `Promise<T>`
- 请求自动携带 Token（从 Preferences 读取放入 Header）
- 统一处理错误码（如 401 跳转登录页）
- 示例：
  ```typescript
  // http.ets
  export function request<T>(url: string, method: string, data?: object): Promise<T> { ... }
  
  // userApi.ets
  export function login(username: string, password: string): Promise<LoginResponse> {
    return request<LoginResponse>('/api/login', 'POST', { username, password });
  }
  ```

### 5. 路由与页面跳转
- 使用 `Router` 模块（`router.pushUrl()`、`router.replaceUrl()`）
- 路由路径统一定义在 `constants/RoutePath.ets`，禁止硬编码字符串
- 页面间传参使用 `router.pushUrl({ url: 'pages/DetailPage', params: { id: 123 } })`
- 目标页面在 `aboutToAppear()` 中通过 `router.getParams()` 获取参数

### 6. 样式与布局
- 使用 ArkUI 提供的布局组件（`Column`、`Row`、`Flex`、`Grid`）
- 样式通过链式调用设置（`.width()`、`.height()`、`.backgroundColor()`）
- 全局主题色定义在 `constants/AppConstants.ets`，组件内引用常量
- 避免深层嵌套，优先使用相对布局和弹性布局

### 7. 日志与调试
- 使用 `hilog` 系统日志接口，级别 `DEBUG`、`INFO`、`ERROR`
- 禁止使用 `console.log`（在生产环境不生效，且性能差）
- 示例：`hilog.info(0x0000, 'AIChat', '用户登录成功，userId=%{public}d', userId)`

### 8. 注释规范
- 公共函数、组件必须添加注释，说明用途、参数、返回值
- 复杂业务逻辑添加行内注释
- 使用 JSDoc 风格 `/** ... */`

## 约束条件

### 必须遵守
- 禁止使用 `any` 类型，必要时使用 `unknown` 配合类型守卫
- 禁止在组件中直接调用 `http` 请求，必须通过 `api/` 层调用
- 禁止在 UI 线程中执行耗时操作（网络、数据库），必须使用异步 `async/await` 或 Promise
- 禁止硬编码字符串（如页面路径、API 地址、错误消息），统一使用常量
- 禁止修改 `utils/http.ets` 的核心拦截逻辑（除非有充分理由）
- 禁止在循环中频繁创建临时对象（ArkTS 的垃圾回收较敏感）

### 强烈建议
- 每个页面组件拆分为 300 行以内，超出则抽取子组件
- 使用 `@Builder` 装饰器抽取重复 UI 片段
- 列表渲染使用 `LazyForEach` 替代 `ForEach`（数据量大时）
- 图片资源放在 `resources/base/media/`，使用 `$r()` 引用
- 本地存储（Preferences）使用异步读写，避免阻塞 UI

## 与后端联调约定

- 后端 API 基础路径：`http://<你的后端IP>:8080/api/`（在 `constants/AppConstants.ets` 中配置）
- 统一响应格式：`{ code: number, message: string, data: T }`
- 认证方式：JWT Bearer Token（存储在 Preferences，Header 为 `Authorization: Bearer <token>`）
- 错误码处理：
  - `200`：成功
  - `401`：Token 失效或未登录 → 清除本地数据，跳转登录页
  - `403`：无权限 → 弹出提示
  - `500`：服务器错误 → 弹出“系统繁忙”
- 移动端在 `aboutToAppear()` 生命周期中检查 Token，若无效则跳转登录

## 新增页面/组件步骤

1. 在 `pages/` 下创建 `.ets` 文件（如 `NewPage.ets`）
2. 定义 `@Entry` 和 `@Component` 结构
3. 在 `constants/RoutePath.ets` 中添加路由常量
4. 如需网络请求，在 `api/` 下创建对应 API 模块，并在 `utils/http.ets` 中确认已有通用方法
5. 在需要跳转的地方调用 `router.pushUrl({ url: RoutePath.NEW_PAGE })`

## 参考文件

- 网络请求封装：`utils/http.ets`（需自己实现，参考后端规范中的 request.js 思想）
- 存储封装：`utils/storage.ets`
- 页面示例：`pages/LoginPage.ets`、`pages/HomePage.ets`

## 开发环境

- IDE：DevEco Studio 5.0+
- SDK：HarmonyOS NEXT Developer Preview 或更高版本
- 模拟器/真机：API 12+ 设备

---

> **渐进式披露规则：** AI 应先读取本文件了解移动端技术栈与规范，再根据具体需求生成代码或修改文件。