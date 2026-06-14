# AI Companion Platform - 项目结构说明

## 📁 项目结构

```
ai_learning/
├── admin/                    # 前端管理后台（Vue3 + Element Plus）
│   ├── src/
│   │   ├── api/             # API 请求函数（按模块拆分）
│   │   │   └── user.js      # 用户相关 API
│   │   ├── components/      # 公共可复用组件
│   │   ├── layout/          # 布局组件
│   │   ├── router/          # 路由配置
│   │   ├── stores/          # Pinia 状态管理
│   │   ├── utils/           # 工具函数
│   │   ├── views/           # 页面组件
│   │   ├── App.vue          # 根组件
│   │   └── main.js          # 入口文件
│   ├── package.json
│   ├── vite.config.js
│   └── index.html
│
├── backend/                  # 后端服务（Spring Boot 3.2）
│   ├── src/main/
│   │   ├── java/com/aicompanion/
│   │   │   ├── model/       # 数据模型层
│   │   │   │   ├── entity/  # 实体类
│   │   │   │   ├── dto/     # DTO（接收参数）
│   │   │   │   ├── vo/      # VO（返回数据）
│   │   │   │   └── query/   # 查询参数
│   │   │   ├── mapper/      # 数据访问层
│   │   │   ├── service/     # 业务逻辑层
│   │   │   ├── controller/  # 控制器层
│   │   │   ├── common/      # 公共模块
│   │   │   ├── config/      # 配置类
│   │   │   ├── exception/   # 异常处理
│   │   │   └── util/        # 工具类
│   │   └── resources/
│   │       └── application.yml
│   ├── pom.xml
│   └── sql/                 # 数据库脚本
│
├── AGENTS.md                # 项目总览文档
├── admin/AGENTS.md          # 前端开发规范
└── backend/AGENTS.md        # 后端开发规范
```

## 🚀 启动说明

### 前端启动
```bash
cd admin
npm install
npm run dev
```
访问：http://localhost:5173

### 后端启动
```bash
cd backend
mvn spring-boot:run
```
访问：http://localhost:8080

## 🔗 前后端联调

- 后端 API 基础路径：`/api/`
- 统一响应格式：`{ code: 200, message: "success", data: ... }`
- 认证方式：JWT Bearer Token
- 前端通过 Axios 请求后端，baseURL 在 `vite.config.js` 中配置代理

## 📝 开发规范

详见各子项目的 AGENTS.md 文件：
- 前端：[admin/AGENTS.md](admin/AGENTS.md)
- 后端：[backend/AGENTS.md](backend/AGENTS.md)
