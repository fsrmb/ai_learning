# AI 伴学平台 - 前端管理后台

## 技术栈
- 框架：Vue 3 + JavaScript（非 TypeScript）
- 构建工具：Vite
- UI 组件库：Element Plus
- 路由：Vue Router 4
- HTTP 客户端：Axios
- 图表：ECharts

## 目录结构
admin/src/
├── views/              # 页面组件（每个页面一个文件夹）
│   ├── Login.vue       # 登录页
│   ├── Dashboard.vue   # 首页仪表盘
│   └── Users.vue       # 用户管理
├── components/         # 公共可复用组件
├── layout/             # 布局组件（侧边栏+顶栏+内容区）
├── router/             # 路由配置
│   └── index.js        # 路由表 + 导航守卫
├── utils/              # 工具函数
│   └── request.js      # Axios 封装（baseURL、Token 拦截器、错误处理）
├── api/                # API 请求函数（按模块拆分）
│   └── user.js         # 用户相关 API
├── stores/             # Pinia 状态管理（如果使用）
└── App.vue             # 根组件

## 编码规范
- 使用 Composition API（<script setup>），不要用 Options API
- 使用 JavaScript，不要用 TypeScript
- API 请求统一封装在 api/ 目录，不要在组件中直接写 axios
- 使用 Element Plus 组件，不自己写 UI
- 样式使用 <style scoped> 避免污染
- 路由使用 history 模式

## 约束条件
- 禁止使用 TypeScript
- 禁止在组件中硬编码 API 地址
- 禁止使用 any 类型（即使是 JS 也要注意类型安全）
- 禁止修改 request.js 的拦截器逻辑（除非有充分理由）
- 所有 API 函数返回 Promise，组件中用 async/await 调用
- 所有 API 函数的参数和返回值都要有类型注释（除非是动态类型）
- 所有函数都要注释完备，包括参数、返回值、异常类型等
## 参考文件
- 登录页：views/Login.vue
- 布局组件：layout/MainLayout.vue
- Axios 封装：utils/request.js
- 路由配置：router/index.js