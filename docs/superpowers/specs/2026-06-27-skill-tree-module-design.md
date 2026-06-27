# 技能树模块设计文档

**创建时间：** 2026-06-27  
**目标用户：** 学生用户（移动端 App）  
**核心功能：** 技能标签体系、技能学习进度追踪、答题闯关评估、学习数据看板

---

## 一、项目概述

### 1.1 功能定位

AI 伴学平台的技能树模块，为学生用户提供可视化的技能学习路径、进度追踪和闯关评估机制，帮助学生系统化地掌握专业技能。

### 1.2 核心特性

- **技能标签体系**：多层级树形结构，支持无限层级嵌套
- **进度追踪**：记录解锁时间、完成时间、学习时长、经验值、评估成绩
- **答题闯关**：AI 动态生成题目，达到 70% 阈值即可通关
- **顺序推荐**：基于已完成技能推荐下一技能节点
- **数据看板**：ECharts 可视化展示学习数据

---

## 二、权责划分

| 功能模块 | 移动端（学生用户）| 管理后台（管理员）| 后端 API |
|---------|-----------------|------------------|---------|
| 技能树列表展示 | ✅ 你的权责 | ❌ | GET `/api/skill-trees` |
| 技能节点详情页 | ✅ 你的权责 | ❌ | GET `/api/skill-trees/{id}/nodes`<br>GET `/api/skill-nodes/{id}` |
| 答题闯关页面 | ✅ 你的权责 | ❌ | POST `/api/assessments/start`<br>POST `/api/assessments/{id}/submit` |
| 进度追踪展示 | ✅ 你的权责 | ❌ | GET `/api/progress/me`<br>POST `/api/progress/unlock`<br>POST `/api/progress/start` |
| 学习数据看板（学生视角）| ✅ 你的权责 | ❌ | GET `/api/dashboard/me` |
| 推荐系统 | ✅ 你的权责 | ❌ | GET `/api/recommendations/me` |
| 技能树 CRUD 管理 | ❌ | ✅ 协作者权责 | POST/PUT/DELETE `/api/skill-trees` |
| 技能节点 CRUD 管理 | ❌ | ✅ 协作者权责 | POST/PUT/DELETE `/api/skill-nodes` |
| 题库管理（人工补充题目）| ❌ | ✅ 协作者权责 | GET `/api/questions`<br>POST/PUT/DELETE `/api/questions` |
| 学习数据看板（管理视角）| ❌ | ✅ 协作者权责 | GET `/api/dashboard/all`<br>GET `/api/dashboard/statistics` |
| 用户进度查看（管理视角）| ❌ | ✅ 协作者权责 | GET `/api/progress/all`<br>GET `/api/progress/{userId}` |

---

## 三、数据库设计

### 3.1 表结构总览

**现有表（保持不变）：**
- `skill_tree` - 技能树定义
- `skill_node` - 技能节点定义（支持多层级树形结构）

**新增表：**
- `user_skill_progress` - 用户技能进度（核心表）
- `skill_question` - 题目库
- `skill_assessment` - 评估记录
- `skill_assessment_detail` - 答题明细

### 3.2 user_skill_progress（用户技能进度表）

```sql
CREATE TABLE user_skill_progress (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    node_id BIGINT NOT NULL COMMENT '技能节点ID',
    
    -- 状态管理
    status VARCHAR(20) NOT NULL DEFAULT 'LOCKED' COMMENT '状态：LOCKED(锁定)/UNLOCKED(已解锁)/IN_PROGRESS(进行中)/COMPLETED(已完成)',
    
    -- 时间记录
    unlock_time DATETIME NULL COMMENT '解锁时间',
    start_time DATETIME NULL COMMENT '开始学习时间',
    complete_time DATETIME NULL COMMENT '完成时间',
    
    -- 学习数据
    study_duration INT DEFAULT 0 COMMENT '累计学习时长（秒）',
    
    -- 评估数据
    best_score DECIMAL(5,2) DEFAULT 0 COMMENT '最高得分',
    latest_score DECIMAL(5,2) DEFAULT 0 COMMENT '最新得分',
    attempt_count INT DEFAULT 0 COMMENT '尝试次数',
    pass_count INT DEFAULT 0 COMMENT '通过次数',
    
    -- 经验值
    exp_points INT DEFAULT 0 COMMENT '获得的经验值',
    
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    UNIQUE KEY uk_user_node (user_id, node_id),
    KEY idx_user_id (user_id),
    KEY idx_node_id (node_id),
    KEY idx_status (status),
    CONSTRAINT fk_progress_user FOREIGN KEY (user_id) REFERENCES sys_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_progress_node FOREIGN KEY (node_id) REFERENCES skill_node(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户技能进度表';
```

**字段说明：**
- `status` 四种状态对应学习流程：LOCKED → UNLOCKED → IN_PROGRESS → COMPLETED
- `best_score` 和 `latest_score` 区分历史最高和最近一次得分
- `study_duration` 用于学习数据看板展示总学习时长（秒）
- 每个用户对每个技能节点有一条唯一进度记录

### 3.3 skill_question（题目库表）

```sql
CREATE TABLE skill_question (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    node_id BIGINT NOT NULL COMMENT '所属技能节点ID',
    
    -- 题目内容
    question_text TEXT NOT NULL COMMENT '题目内容',
    options_json JSON NOT NULL COMMENT '选项JSON数组，如["A. xxx", "B. xxx", ...]',
    correct_answer VARCHAR(10) NOT NULL COMMENT '正确答案，如"A"',
    explanation TEXT COMMENT '答案解析',
    
    -- 题目属性
    difficulty TINYINT DEFAULT 3 COMMENT '难度等级1-5',
    source VARCHAR(20) NOT NULL DEFAULT 'AI_GENERATED' COMMENT '来源：AI_GENERATED(AI生成)/MANUAL(人工录入)',
    
    -- 统计数据
    use_count INT DEFAULT 0 COMMENT '使用次数',
    correct_rate DECIMAL(5,2) DEFAULT 0 COMMENT '正确率统计',
    
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    KEY idx_node_id (node_id),
    KEY idx_difficulty (difficulty),
    KEY idx_source (source),
    CONSTRAINT fk_question_node FOREIGN KEY (node_id) REFERENCES skill_node(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='题目库表';
```

**字段说明：**
- AI 生成的题目存入此表，后续可复用
- 管理员可手动补充题目（source='MANUAL'）
- `options_json` 使用 JSON 类型存储选项数组
- `correct_rate` 用于分析题目难度和用户薄弱点

### 3.4 skill_assessment（评估记录表）

```sql
CREATE TABLE skill_assessment (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    node_id BIGINT NOT NULL COMMENT '技能节点ID',
    
    -- 评估信息
    assessment_time DATETIME NOT NULL COMMENT '评估时间',
    duration_seconds INT DEFAULT 0 COMMENT '答题耗时（秒）',
    
    -- 得分信息
    total_score DECIMAL(5,2) NOT NULL COMMENT '本次得分',
    pass_threshold DECIMAL(5,2) NOT NULL DEFAULT 70.00 COMMENT '通过阈值（默认70%）',
    passed TINYINT NOT NULL COMMENT '是否通过：0失败/1通过',
    
    -- 题目信息
    question_count INT NOT NULL COMMENT '题目数量',
    correct_count INT NOT NULL COMMENT '正确数量',
    
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    KEY idx_user_id (user_id),
    KEY idx_node_id (node_id),
    KEY idx_assessment_time (assessment_time),
    KEY idx_passed (passed),
    CONSTRAINT fk_assessment_user FOREIGN KEY (user_id) REFERENCES sys_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_assessment_node FOREIGN KEY (node_id) REFERENCES skill_node(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评估记录表';
```

**字段说明：**
- 每次答题闯关产生一条评估记录
- `pass_threshold` 可配置，默认 70% 通关
- 支持历史评估记录查询（学习数据看板）

### 3.5 skill_assessment_detail（答题明细表）

```sql
CREATE TABLE skill_assessment_detail (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    assessment_id BIGINT NOT NULL COMMENT '评估记录ID',
    question_id BIGINT NOT NULL COMMENT '题目ID',
    
    -- 答题信息
    user_answer VARCHAR(10) NOT NULL COMMENT '用户答案',
    is_correct TINYINT NOT NULL COMMENT '是否正确：0错误/1正确',
    time_spent_seconds INT DEFAULT 0 COMMENT '本题耗时（秒）',
    
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    KEY idx_assessment_id (assessment_id),
    KEY idx_question_id (question_id),
    KEY idx_is_correct (is_correct),
    CONSTRAINT fk_detail_assessment FOREIGN KEY (assessment_id) REFERENCES skill_assessment(id) ON DELETE CASCADE,
    CONSTRAINT fk_detail_question FOREIGN KEY (question_id) REFERENCES skill_question(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='答题明细表';
```

**字段说明：**
- 存储每道题的答题详情
- 用于分析用户薄弱知识点（推荐算法优化）
- 可在学习数据看板展示错题分布

---

## 四、API 接口设计

### 4.1 技能树展示接口

#### GET `/api/skill-trees` - 获取技能树列表

**请求参数：**
- `category`（可选）：分类筛选，如"编程"
- `status`（可选）：状态筛选，1=正常

**响应示例：**
```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "id": 1,
      "name": "Java 开发技能树",
      "description": "从入门到精通的 Java 学习路径",
      "icon": "/icons/java.png",
      "category": "编程",
      "difficultyLevel": 3,
      "nodeCount": 8,
      "completedCount": 3,
      "progress": 37.5
    }
  ]
}
```

#### GET `/api/skill-trees/{id}` - 获取技能树详情（含节点树）

**响应示例：**
```json
{
  "code": 200,
  "data": {
    "id": 1,
    "name": "Java 开发技能树",
    "nodes": [
      {
        "id": 1,
        "parentId": 0,
        "name": "Java 基础",
        "nodeType": "CHECKPOINT",
        "status": "COMPLETED",
        "bestScore": 85.0,
        "children": [...]
      }
    ]
  }
}
```

### 4.2 技能节点详情接口

#### GET `/api/skill-nodes/{id}` - 获取单个节点详情

**响应示例：**
```json
{
  "code": 200,
  "data": {
    "id": 2,
    "name": "变量与数据类型",
    "description": "理解 Java 的基本数据类型和变量声明",
    "nodeType": "SKILL",
    "requiredExp": 100,
    "unlockCondition": "开始学习",
    "status": "COMPLETED",
    "bestScore": 90.0,
    "latestScore": 88.0,
    "attemptCount": 2,
    "studyDuration": 3600
  }
}
```

### 4.3 进度追踪接口

#### GET `/api/progress/me` - 获取当前用户全部进度

**响应示例：**
```json
{
  "code": 200,
  "data": {
    "totalNodes": 24,
    "completedNodes": 8,
    "inProgressNodes": 3,
    "totalStudyDuration": 12600,
    "totalExp": 850,
    "overallProgress": 33.3
  }
}
```

#### POST `/api/progress/unlock` - 解锁技能节点

**请求体：**
```json
{
  "nodeId": 2
}
```

**解锁逻辑：**
- 检查父节点是否已完成（满足 `unlockCondition`）
- 更新 `user_skill_progress.status` 为 `UNLOCKED`

#### POST `/api/progress/start` - 开始学习技能节点

**请求体：**
```json
{
  "nodeId": 2
}
```

### 4.4 答题闯关接口

#### POST `/api/assessments/start` - 开始评估（生成题目）

**请求体：**
```json
{
  "nodeId": 2,
  "questionCount": 5
}
```

**响应示例：**
```json
{
  "code": 200,
  "data": {
    "assessmentId": 123,
    "nodeId": 2,
    "questions": [
      {
        "questionId": 45,
        "questionText": "Java 中 int 类型的取值范围是？",
        "options": ["A. -128~127", "B. -32768~32767", "C. -2³¹~2³¹-1", "D. 不确定"],
        "difficulty": 3
      }
    ],
    "passThreshold": 70.0
  }
}
```

**后端逻辑：**
1. 调用 Dify API 动态生成题目
2. 存入 `skill_question` 表（source='AI_GENERATED'）
3. 创建 `skill_assessment` 记录
4. 返回题目列表给前端

#### POST `/api/assessments/{id}/submit` - 提交答案

**请求体：**
```json
{
  "answers": [
    {
      "questionId": 45,
      "answer": "C",
      "timeSpent": 15
    }
  ],
  "totalTime": 120
}
```

**响应示例：**
```json
{
  "code": 200,
  "data": {
    "assessmentId": 123,
    "totalScore": 80.0,
    "passed": true,
    "correctCount": 4,
    "wrongCount": 1,
    "details": [
      {
        "questionId": 45,
        "userAnswer": "C",
        "isCorrect": true,
        "explanation": "int 类型占用 4 字节..."
      }
    ],
    "expGained": 100,
    "nodeCompleted": true
  }
}
```

**后端逻辑：**
1. 计算得分（correctCount / questionCount * 100）
2. 判断是否通过（score >= 70%）
3. 更新 `skill_assessment`（passed, total_score）
4. 插入 `skill_assessment_detail` 记录
5. 更新 `user_skill_progress`（best_score, latest_score, attempt_count）
6. 如果首次通过，更新 status 为 `COMPLETED`

### 4.5 推荐系统接口

#### GET `/api/recommendations/me` - 获取推荐技能

**响应示例：**
```json
{
  "code": 200,
  "data": {
    "recommendations": [
      {
        "nodeId": 3,
        "name": "控制流程",
        "reason": "已完成前置技能「变量与数据类型」",
        "priority": 1
      }
    ]
  }
}
```

**推荐逻辑：**
- 查询已完成节点的子节点（优先推荐）
- 查询已解锁但未开始的节点
- 按 `sort_order` 和 `priority` 排序

### 4.6 学习数据看板接口

#### GET `/api/dashboard/me` - 移动端看板（学生视角）

**响应示例：**
```json
{
  "code": 200,
  "data": {
    "overview": {
      "totalStudyDuration": 12600,
      "completedNodes": 8,
      "totalExp": 850,
      "avgScore": 82.5
    },
    "skillProgress": [
      {"category": "编程", "completed": 8, "total": 24},
      {"category": "设计", "completed": 2, "total": 10}
    ],
    "scoreHistory": [
      {"date": "2026-06-20", "score": 75},
      {"date": "2026-06-25", "score": 85}
    ],
    "weeklyStudyTime": [
      {"week": "W1", "duration": 1800},
      {"week": "W2", "duration": 3600}
    ]
  }
}
```

---

## 五、移动端页面设计（ArkTS）

### 5.1 页面总览

| 页面 | 文件路径 | 核心功能 |
|------|---------|---------|
| 技能树列表 | `pages/SkillTreeList.ets` | 展示技能树列表 + 进度概览 |
| 技能树详情 | `pages/SkillTreeDetail.ets` | 展示技能树节点树形结构 |
| 技能节点详情 | `pages/SkillNodeDetail.ets` | 单个技能节点的详细信息 |
| 答题闯关 | `pages/SkillAssessment.ets` | AI 生成题目 → 答题 → 评分 |
| 学习进度 | `pages/SkillProgress.ets` | 用户整体进度追踪 |
| 学习看板 | `pages/SkillDashboard.ets` | ECharts 数据可视化 |

### 5.2 技能树列表页面

**文件路径：** `pages/SkillTreeList.ets`

**UI 结构：**
- NavBar: "技能树"
- 搜索框：支持按名称搜索
- 分类筛选 Tabs：[全部] [编程] [设计] [语言]
- 技能树卡片列表：
  - 显示：图标、名称、描述、难度星级、进度百分比
  - 进度条：已完成节点数/总节点数
  - 操作按钮：[继续学习]

**交互逻辑：**
- 点击卡片跳转到 `SkillTreeDetail` 页面
- 点击"继续学习"按钮跳转到推荐节点的答题页面

### 5.3 技能树详情页面

**文件路径：** `pages/SkillTreeDetail.ets`

**UI 结构：**
- NavBar: 技能树名称
- 技能树信息卡片：名称、描述、总进度
- 技能节点树（可折叠的树形结构）：
  - 状态图标：✓ 已完成、⏳ 进行中、🔓 已解锁、🔒 未解锁
  - 点击节点展开/折叠子节点
  - 显示节点名称、得分（已完成节点）
- 推荐继续学习卡片：推荐节点 + [开始答题]按钮

**交互逻辑：**
- 点击节点跳转到 `SkillNodeDetail` 页面
- 点击"开始答题"跳转到 `SkillAssessment` 页面

### 5.4 技能节点详情页面

**文件路径：** `pages/SkillNodeDetail.ets`

**UI 结构：**
- NavBar: 节点名称
- 状态卡片：状态、最高得分、学习时长、经验值
- 技能描述：节点描述内容
- 解锁条件：解锁条件描述
- 评估历史列表：日期、得分、是否通过
- 操作按钮：[再次答题闯关] [查看答题详情]

**交互逻辑：**
- 点击"再次答题闯关"跳转到 `SkillAssessment` 页面
- 点击"查看答题详情"跳转到历史答题详情页

### 5.5 答题闯关页面

**文件路径：** `pages/SkillAssessment.ets`

**UI 结构（答题页）：**
- NavBar: "节点名称 - 答题闯关"
- 进度指示器：题目 1/5 + 进度条 + 倒计时
- 题目内容：题干文本
- 选项卡片：4 个单选选项，选中后高亮
- 操作按钮：[下一题]（最后一题显示"提交答案"）

**UI 结构（结果页）：**
- 结果卡片：
  - 得分动画 + 总分
  - 正确数/错误数
  - 是否通关 + 获得经验值
- 答题详情列表：每题的正确/错误状态
- 操作按钮：[查看详细解析] [继续学习下一个技能] [返回技能树]

**交互逻辑：**
- 进入页面时调用 `POST /api/assessments/start` 生成题目
- 选择答案后点击"下一题"
- 提交后调用 `POST /api/assessments/{id}/submit`
- 显示结果 + 错题解析

### 5.6 学习进度页面

**文件路径：** `pages/SkillProgress.ets`

**UI 结构：**
- NavBar: "学习进度"
- 总体进度卡片：已完成数、进行中数、未解锁数、总进度百分比
- 学习统计卡片：总学习时长、总经验值、平均得分、尝试次数
- 各技能树进度列表：技能树名称 + 进度条 + 百分比
- 操作按钮：[查看详细数据看板]

**交互逻辑：**
- 点击"查看详细数据看板"跳转到 `SkillDashboard` 页面

### 5.7 学习数据看板页面

**文件路径：** `pages/SkillDashboard.ets`

**UI 结构：**
- NavBar: "学习数据看板"
- Tab 切换：[总览] [技能进度] [得分趋势] [学习时长]
- ECharts 图表区域（Web 组件）：
  - Tab 1 总览：饼图（状态分布）+ 折线图（7天学习时长）+ 柱状图（各技能树进度）
  - Tab 2 技能进度：横向柱状图（各分类完成进度）
  - Tab 3 得分趋势：折线图（评估得分历史）
  - Tab 4 学习时长：柱状图（每周学习时长）

**技术实现：**
- 使用 ArkTS 的 `Web` 组件加载 ECharts
- 使用 `WebLayoutMode.FIT_CONTENT` 自适应高度
- 通过 URL 参数或 postMessage 传递数据给 Web 组件

---

## 六、完整 SQL 脚本

详见：`backend/sql/skill_tree_progress.sql`

包含：
1. 4 个新增表的完整建表语句
2. 真实可靠的测试数据（基于 Java 学习路径设计）
3. 数据验证注释

---

## 七、后续实现步骤

### 7.1 协作者任务（管理后台开发）

**文件路径：** `admin/src/views/SkillTree.vue`

1. 技能树 CRUD 管理页面
2. 技能节点管理页面（树形结构编辑）
3. 题库管理页面（人工补充题目）
4. 学习数据看板（管理视角，全局统计）

**文件路径：** `admin/src/api/skillTree.js`

1. 技能树管理接口封装
2. 技能节点管理接口封装
3. 题库管理接口封装
4. 数据看板接口封装

### 7.2 你的任务（移动端开发）

**文件路径：** `app/entry/src/main/ets/pages/`

1. `SkillTreeList.ets` - 技能树列表页面
2. `SkillTreeDetail.ets` - 技能树详情页面
3. `SkillNodeDetail.ets` - 技能节点详情页面
4. `SkillAssessment.ets` - 答题闯关页面
5. `SkillProgress.ets` - 学习进度页面
6. `SkillDashboard.ets` - 学习数据看板页面

**文件路径：** `app/entry/src/main/ets/http/`

1. `SkillTreeApi.ets` - 技能树接口封装
2. `SkillProgressApi.ets` - 进度追踪接口封装
3. `SkillAssessmentApi.ets` - 答题闯关接口封装
4. `SkillDashboardApi.ets` - 数据看板接口封装

**文件路径：** `app/entry/src/main/ets/model/`

1. `SkillTree.ets` - 技能树数据模型
2. `SkillNode.ets` - 技能节点数据模型
3. `SkillProgress.ets` - 进度数据模型
4. `SkillQuestion.ets` - 题目数据模型
5. `SkillAssessment.ets` - 评估数据模型

---

## 八、技术栈与约束

### 8.1 后端约束

- 语言：Java 17
- 框架：Spring Boot 3.2 + MyBatis-Plus 3.5
- 分层架构：Controller → Service → Mapper
- 统一返回：`Result<T>` 格式
- 使用 DTO 接收参数，使用 VO 返回数据
- 所有新增接口必须在 Swagger 能正常调通

### 8.2 移动端约束

- 语言：ArkTS
- 不使用 TypeScript，使用 JavaScript 风格
- API 地址通过 Constants 类管理
- 禁止使用 `any` 和 `unknown` 类型，必须显式类型声明
- 禁止使用对象字面量作为类型声明
- Web 组件用于 ECharts 图表渲染
- 回调函数使用普通属性，不使用 @Prop 装饰器

### 8.3 前端约束

- 语言：Vue3 + JavaScript + Vite + Element Plus
- Axios baseURL 配置在 .env 文件中
- 响应式设计
- ECharts 用于数据可视化