# 技能评估与答题闯关功能设计

## 一、概述

本功能为 AI 伴学平台的核心学习模块之一，实现技能节点的分级答题闯关机制。用户可以选择不同难度级别进行答题，通过后获得对应的熟练度，达到100熟练度即完成该技能节点。

## 二、核心规则

| 规则项 | 内容 |
|--------|------|
| **题目来源** | 分级题库（skill_question 表，按难度1-5分类） |
| **每级题目数** | 5道选择题 |
| **通过阈值** | 70%正确率（答对≥4题） |
| **熟练度计算** | 只记录最高通过难度：难度1=20, 2=40, 3=60, 4=80, 5=100（节点完成） |
| **难度解锁** | 完全自由，用户可任意选择难度挑战 |

## 三、难度级别定义

| 难度 | 熟练度 | 描述文本 | 颜色标识 |
|------|--------|----------|----------|
| 难度1 | 20 | 入门级，适合新手 | 🟢 绿色 |
| 难度2 | 40 | 基础级，适合初学者 | 🟡 黄色 |
| 难度3 | 60 | 进阶级，适合有一定基础 | 🟠 橙色 |
| 难度4 | 80 | 高手级，适合熟练开发者 | 🔴 红色 |
| 难度5 | 100 | 专家级，适合资深工程师 | ⚫ 黑色 |

## 四、数据模型

### 4.1 已有表结构

**skill_question（题目库）**

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT | 主键 |
| node_id | BIGINT | 所属技能节点ID |
| question_text | VARCHAR(500) | 题目内容 |
| options_json | VARCHAR(1000) | 选项JSON数组 |
| correct_answer | VARCHAR(10) | 正确答案（如"A"） |
| explanation | VARCHAR(1000) | 答案解析 |
| difficulty | TINYINT | 难度等级1-5 |
| source | VARCHAR(32) | 来源 |

**skill_assessment（评估记录）**

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT | 主键 |
| user_id | BIGINT | 用户ID |
| node_id | BIGINT | 技能节点ID |
| assessment_time | DATETIME | 评估时间 |
| duration_seconds | INT | 答题耗时（秒） |
| total_score | DECIMAL(5,2) | 本次得分 |
| pass_threshold | DECIMAL(5,2) | 通过阈值 |
| passed | TINYINT | 是否通过：0失败/1通过 |
| question_count | INT | 题目数量 |
| correct_count | INT | 正确数量 |

**skill_assessment_detail（答题明细）**

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT | 主键 |
| assessment_id | BIGINT | 评估记录ID |
| question_id | BIGINT | 题目ID |
| user_answer | VARCHAR(10) | 用户答案 |
| is_correct | TINYINT | 是否正确：0错误/1正确 |
| time_spent_seconds | INT | 本题耗时（秒） |

**user_skill_progress（用户技能进度）**

| 字段名 | 类型 | 说明 |
|--------|------|------|
| id | BIGINT | 主键 |
| user_id | BIGINT | 用户ID |
| node_id | BIGINT | 技能节点ID |
| status | TINYINT | 状态：0未解锁/1已解锁/2已完成 |
| current_exp | INT | 当前熟练度（0-100） |
| unlocked_at | DATETIME | 解锁时间 |
| completed_at | DATETIME | 完成时间 |

## 五、后端API设计

### 5.1 API列表

| API | 方法 | 路径 | 说明 |
|-----|------|------|------|
| 开始评估 | POST | /api/assessments/start | 创建评估记录，获取题目 |
| 提交答案 | POST | /api/assessments/{id}/submit | 提交答案，计算得分，更新熟练度 |
| 获取评估详情 | GET | /api/assessments/{id} | 获取评估记录详情 |
| 获取评估列表 | GET | /api/assessments | 获取用户评估历史 |

### 5.2 开始评估

**请求：**
```
POST /api/assessments/start
```

**请求体：**
```json
{
  "nodeId": 2,
  "difficulty": 3
}
```

**响应：**
```json
{
  "code": 200,
  "data": {
    "assessmentId": 123,
    "nodeId": 2,
    "difficulty": 3,
    "questions": [
      {
        "questionId": 45,
        "questionText": "Java中int类型的取值范围是？",
        "options": ["A. -128~127", "B. -32768~32767", "C. -2³¹~2³¹-1", "D. 不确定"],
        "difficulty": 3
      }
    ],
    "passThreshold": 70.0,
    "totalQuestions": 5
  }
}
```

### 5.3 提交答案

**请求：**
```
POST /api/assessments/{id}/submit
```

**请求体：**
```json
{
  "answers": [
    { "questionId": 45, "answer": "C", "timeSpent": 15 },
    { "questionId": 46, "answer": "A", "timeSpent": 20 },
    { "questionId": 47, "answer": "B", "timeSpent": 18 },
    { "questionId": 48, "answer": "D", "timeSpent": 22 },
    { "questionId": 49, "answer": "C", "timeSpent": 15 }
  ],
  "totalTime": 90
}
```

**响应：**
```json
{
  "code": 200,
  "data": {
    "assessmentId": 123,
    "correctCount": 4,
    "wrongCount": 1,
    "score": 80.0,
    "passed": true,
    "newExp": 60,
    "previousExp": 40,
    "expIncreased": true,
    "nodeCompleted": false,
    "details": [
      {
        "questionId": 45,
        "userAnswer": "C",
        "correctAnswer": "C",
        "isCorrect": true,
        "explanation": "int类型占用4字节，取值范围是-2³¹到2³¹-1"
      }
    ]
  }
}
```

## 六、移动端页面设计

### 6.1 页面1：难度选择页（SkillDifficultySelect.ets）

**功能：** 用户选择技能节点后，选择答题难度

**页面参数：**
- nodeId: 技能节点ID

**UI结构：**
- 顶部区域：技能节点名称 + 描述 + 图标
- 熟练度区域：进度条（显示当前熟练度数值和状态）
- 难度选择区域：可展开/收起的列表
  - 展开后显示5个难度选项
  - 每个选项：难度标签（图标+文字）、描述文本（如"入门级，适合新手"）、熟练度值、已通过标记
- 底部按钮：开始答题

**交互流程：**
1. 页面加载时显示技能节点信息和当前熟练度
2. 点击"选择难度"展开列表
3. 用户点击某个难度选项，该选项高亮，列表自动收起
4. 点击"开始答题"按钮，调用开始评估API，进入答题页

### 6.2 页面2：答题页（SkillAssessment.ets）

**功能：** 用户逐一答题

**页面参数：**
- assessmentId: 评估记录ID
- nodeId: 技能节点ID
- difficulty: 难度级别
- questions: 题目列表

**UI结构：**
- 顶部栏：难度级别显示 + 进度指示（第X题/共5题）
- 题目内容区：题目文本
- 选项区域：4个选项卡片（单选，点击后高亮）
- 底部按钮：下一题/提交

**交互流程：**
1. 显示第1题和4个选项
2. 用户点击某个选项，选项高亮
3. 点击"下一题"，记录答案，显示下一题
4. 第5题时按钮变为"提交"
5. 点击"提交"，调用提交答案API，进入结果页

### 6.3 页面3：结果页（SkillResult.ets）

**功能：** 展示答题结果，更新熟练度

**页面参数：**
- result: 评估结果数据

**UI结构：**
- 结果卡片：正确数/错误数 + 得分 + 是否通过（通过显示绿色对勾，失败显示红色叉号）
- 熟练度变化：之前数值 → 现在数值（如果有提升，显示绿色箭头向上）
- 答题详情列表：每题正确/错误状态 + 用户答案 + 正确答案 + 解析
- 操作按钮：[再次挑战] [选择其他难度] [返回节点详情]

**交互流程：**
1. 展示评估结果
2. 用户可选择再次挑战同一难度、选择其他难度或返回上一页

## 七、业务逻辑流程

### 7.1 开始评估流程

```
用户选择难度 → 验证节点存在 → 查询题库（按node_id+difficulty筛选）→ 随机抽取5道题 → 创建assessment记录 → 返回题目列表
```

### 7.2 提交答案流程

```
用户提交答案 → 查询assessment记录 → 比对答案计算得分 → 判断是否通过（≥70%）→ 
如果通过：查询用户当前熟练度 → 判断新难度是否高于当前 → 如果是：更新熟练度和状态 → 
保存assessment_detail记录 → 返回评估结果
```

### 7.3 熟练度更新规则

1. 查询 `user_skill_progress` 中该用户该节点的记录
2. 如果不存在，创建新记录（status=1, current_exp=0）
3. 根据通过难度计算新熟练度：难度1=20, 难度2=40, 难度3=60, 难度4=80, 难度5=100
4. 如果新熟练度 > 当前熟练度，则更新
5. 如果熟练度达到100，更新状态为COMPLETED（status=2），设置completed_at

## 八、异常处理

| 异常场景 | 处理方式 |
|----------|----------|
| 题库中该难度题目不足5道 | 返回错误："该难度题目数量不足，请联系管理员" |
| 评估记录不存在 | 返回404错误 |
| 用户未登录 | 返回401错误 |
| 技能节点不存在 | 返回400错误 |
| 提交答案数量与题目数量不一致 | 返回400错误 |
