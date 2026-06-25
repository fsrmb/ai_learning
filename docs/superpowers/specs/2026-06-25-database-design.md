# AI 伴学平台 — 数据库设计规格说明书

## 一、设计概述

- **数据库类型**：MySQL 8.0
- **数据库名**：`ai_companion`
- **字符集**：`utf8mb4`
- **排序规则**：`utf8mb4_unicode_ci`
- **设计原则**：适度反规范化，在查询热点路径保留必要冗余，减少 JOIN 开销

## 二、实体关系总览

```
sys_user (1) ────< (N) user_skill_progress >──── (1) skill_node
                     │
                     ├──< (N) chat_conversation >────< (N) chat_message
                     │
                     ├──< (N) interview_session >────< (N) interview_message
                     │
                     ├──< (N) learning_record
                     │
                     └──< (N) resume_optimization

skill_tree (1) ────< (N) skill_node
```

## 三、表结构设计

### 3.1 用户与权限模块

#### sys_user（用户表）— 已存在

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| username | VARCHAR(64) | NOT NULL, UNIQUE | 用户名 |
| password | VARCHAR(128) | NOT NULL | 加密密码 |
| nickname | VARCHAR(64) | NULL | 昵称 |
| email | VARCHAR(128) | NULL | 邮箱 |
| phone | VARCHAR(20) | NULL | 手机号 |
| avatar | VARCHAR(255) | NULL | 头像URL |
| role | VARCHAR(32) | NOT NULL DEFAULT 'STUDENT' | 角色：STUDENT/TEACHER/ADMIN |
| status | TINYINT | NOT NULL DEFAULT 1 | 状态：0禁用/1正常 |
| create_time | DATETIME | NULL | 创建时间 |
| update_time | DATETIME | NULL | 更新时间 |

---

### 3.2 技能树模块

#### skill_tree（技能树表）— 已存在

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| name | VARCHAR(128) | NOT NULL | 技能树名称 |
| description | VARCHAR(500) | NULL | 描述 |
| icon | VARCHAR(255) | NULL | 图标 |
| category | VARCHAR(64) | NOT NULL | 分类：FRONTEND/BACKEND/DATABASE 等 |
| difficulty_level | TINYINT | NOT NULL DEFAULT 1 | 难度等级 1-5 |
| status | TINYINT | NOT NULL DEFAULT 1 | 状态：0禁用/1正常 |
| create_time | DATETIME | NULL | 创建时间 |
| update_time | DATETIME | NULL | 更新时间 |

#### skill_node（技能节点表）— 已存在

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| tree_id | BIGINT | NOT NULL, FK | 所属技能树ID |
| parent_id | BIGINT | NOT NULL DEFAULT 0 | 父节点ID，0表示根节点 |
| name | VARCHAR(128) | NOT NULL | 节点名称 |
| description | VARCHAR(500) | NULL | 节点描述 |
| node_type | VARCHAR(32) | NOT NULL DEFAULT 'SKILL' | 类型：SKILL/CHECKPOINT/REWARD |
| required_exp | INT | NOT NULL DEFAULT 0 | 所需经验值 |
| unlock_condition | VARCHAR(255) | NULL | 解锁条件描述 |
| reward | VARCHAR(500) | NULL | 奖励内容（JSON格式） |
| icon | VARCHAR(255) | NULL | 图标 |
| status | TINYINT | NOT NULL DEFAULT 1 | 状态：0禁用/1正常 |
| sort_order | INT | NOT NULL DEFAULT 0 | 排序 |
| create_time | DATETIME | NULL | 创建时间 |
| update_time | DATETIME | NULL | 更新时间 |

#### user_skill_progress（用户技能进度表）— 新增

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| user_id | BIGINT | NOT NULL, FK | 用户ID |
| node_id | BIGINT | NOT NULL, FK | 技能节点ID |
| status | TINYINT | NOT NULL DEFAULT 0 | 状态：0未解锁/1已解锁/2已完成 |
| current_exp | INT | NOT NULL DEFAULT 0 | 当前经验值 |
| unlocked_at | DATETIME | NULL | 解锁时间 |
| completed_at | DATETIME | NULL | 完成时间 |
| create_time | DATETIME | NULL | 创建时间 |
| update_time | DATETIME | NULL | 更新时间 |

**索引**：
- `idx_user_node` UNIQUE(user_id, node_id) — 防止重复进度记录
- `idx_user_id` (user_id) — 查询用户全部进度
- `idx_node_id` (node_id) — 查询节点被多少用户完成

---

### 3.3 AI 聊天模块

#### chat_conversation（聊天会话表）— 新增

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| user_id | BIGINT | NOT NULL, FK | 用户ID |
| title | VARCHAR(128) | NULL | 会话标题（首条消息摘要） |
| dify_conversation_id | VARCHAR(128) | NULL | Dify 平台返回的 conversation_id |
| status | TINYINT | NOT NULL DEFAULT 1 | 状态：0已结束/1进行中 |
| create_time | DATETIME | NULL | 创建时间 |
| update_time | DATETIME | NULL | 更新时间 |

**索引**：
- `idx_user_id` (user_id) — 查询用户的会话列表
- `idx_dify_conversation_id` (dify_conversation_id) — 关联 Dify 会话

#### chat_message（聊天消息表）— 新增

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| conversation_id | BIGINT | NOT NULL, FK | 所属会话ID |
| role | VARCHAR(32) | NOT NULL | 角色：USER/ASSISTANT/SYSTEM |
| content | TEXT | NOT NULL | 消息内容 |
| message_type | VARCHAR(32) | NOT NULL DEFAULT 'TEXT' | 类型：TEXT/IMAGE/FILE |
| dify_message_id | VARCHAR(128) | NULL | Dify 平台消息ID |
| create_time | DATETIME | NULL | 创建时间 |

**索引**：
- `idx_conversation_id` (conversation_id) — 查询会话内消息列表
- `idx_create_time` (create_time) — 按时间排序

---

### 3.4 模拟面试模块

#### interview_session（面试会话表）— 新增

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| user_id | BIGINT | NOT NULL, FK | 用户ID |
| skill_node_id | BIGINT | NULL, FK | 关联技能节点ID |
| title | VARCHAR(128) | NOT NULL | 面试标题（如"Java后端模拟面试"） |
| status | TINYINT | NOT NULL DEFAULT 0 | 状态：0未开始/1进行中/2已完成 |
| total_score | INT | NULL | 综合总分 0-100 |
| evaluation | TEXT | NULL | 综合评价文本 |
| start_time | DATETIME | NULL | 开始时间 |
| end_time | DATETIME | NULL | 结束时间 |
| create_time | DATETIME | NULL | 创建时间 |
| update_time | DATETIME | NULL | 更新时间 |

**索引**：
- `idx_user_id` (user_id) — 查询用户的面试记录
- `idx_status` (status) — 筛选进行中的面试

#### interview_message（面试消息表）— 新增

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| session_id | BIGINT | NOT NULL, FK | 所属面试会话ID |
| role | VARCHAR(32) | NOT NULL | 角色：INTERVIEWER/CANDIDATE |
| content | TEXT | NOT NULL | 内容（问题或回答） |
| question_type | VARCHAR(32) | NULL | 题目类型：TECH/BEHAVIOR/ALGORITHM |
| score | INT | NULL | 该题得分（仅回答消息） |
| comment | VARCHAR(500) | NULL | 该题点评 |
| create_time | DATETIME | NULL | 创建时间 |

**索引**：
- `idx_session_id` (session_id) — 查询面试问答列表

---

### 3.5 学习记录模块

#### learning_record（学习记录表）— 新增

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| user_id | BIGINT | NOT NULL, FK | 用户ID |
| user_name | VARCHAR(64) | NULL | 用户名（冗余，便于管理后台列表查询） |
| course_name | VARCHAR(128) | NOT NULL | 课程/内容名称 |
| course_type | VARCHAR(64) | NOT NULL | 课程类型：PROGRAMMING/MATH/ENGLISH/ALGORITHM/DATABASE |
| duration | INT | NOT NULL DEFAULT 0 | 学习时长（分钟） |
| score | INT | NULL | 成绩/得分 |
| status | VARCHAR(32) | NOT NULL DEFAULT 'IN_PROGRESS' | 状态：COMPLETED/IN_PROGRESS |
| learn_date | DATE | NOT NULL | 学习日期 |
| create_time | DATETIME | NULL | 创建时间 |
| update_time | DATETIME | NULL | 更新时间 |

**索引**：
- `idx_user_id` (user_id) — 查询用户学习记录
- `idx_course_type` (course_type) — 按类型筛选
- `idx_learn_date` (learn_date) — 按日期统计
- `idx_user_learn_date` (user_id, learn_date) — 用户学习日历统计

---

### 3.6 简历优化模块

#### resume_optimization（简历优化记录表）— 新增

| 字段名 | 数据类型 | 约束 | 说明 |
|--------|----------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| user_id | BIGINT | NOT NULL, FK | 用户ID |
| original_file_name | VARCHAR(255) | NOT NULL | 原始文件名 |
| original_file_url | VARCHAR(255) | NOT NULL | 原始文件URL |
| optimized_file_url | VARCHAR(255) | NULL | 优化后文件URL |
| original_score | INT | NULL | 原始简历评分 0-100 |
| optimized_score | INT | NULL | 优化后评分 0-100 |
| optimization_type | VARCHAR(32) | NULL | 优化类型：OPTIMIZE(优化)/REWRITE(重写) |
| suggestions | TEXT | NULL | 优化建议/修改说明（JSON或文本） |
| optimized_content | MEDIUMTEXT | NULL | 优化后的简历内容（文本版） |
| status | TINYINT | NOT NULL DEFAULT 0 | 状态：0处理中/1完成/2失败 |
| create_time | DATETIME | NULL | 创建时间 |
| update_time | DATETIME | NULL | 更新时间 |

**索引**：
- `idx_user_id` (user_id) — 查询用户的简历优化记录
- `idx_status` (status) — 筛选处理中的任务

---

## 四、外键约束建议

本项目采用 **逻辑外键**（代码层面维护关联关系），**不建立物理外键约束**。原因：
1. MyBatis-Plus 物理删除和逻辑删除场景下，物理外键容易触发级联限制
2. 便于后续分库分表扩展
3. 减少数据库层面锁竞争

**代码层面必须保证的关联关系**：
- `user_skill_progress.user_id` → `sys_user.id`
- `user_skill_progress.node_id` → `skill_node.id`
- `skill_node.tree_id` → `skill_tree.id`
- `chat_conversation.user_id` → `sys_user.id`
- `chat_message.conversation_id` → `chat_conversation.id`
- `interview_session.user_id` → `sys_user.id`
- `interview_session.skill_node_id` → `skill_node.id`
- `interview_message.session_id` → `interview_session.id`
- `learning_record.user_id` → `sys_user.id`
- `resume_optimization.user_id` → `sys_user.id`

---

## 五、完整 SQL 建库指令

```sql
-- ============================================================
-- AI 伴学平台 — 数据库初始化脚本
-- 数据库：ai_companion
-- 字符集：utf8mb4
-- ============================================================

-- 1. 创建数据库
CREATE DATABASE IF NOT EXISTS `ai_companion`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE `ai_companion`;

-- 2. 用户表（已存在，此处提供完整DDL便于新环境初始化）
CREATE TABLE IF NOT EXISTS `sys_user` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `username` VARCHAR(64) NOT NULL COMMENT '用户名',
    `password` VARCHAR(128) NOT NULL COMMENT '加密密码',
    `nickname` VARCHAR(64) DEFAULT NULL COMMENT '昵称',
    `email` VARCHAR(128) DEFAULT NULL COMMENT '邮箱',
    `phone` VARCHAR(20) DEFAULT NULL COMMENT '手机号',
    `avatar` VARCHAR(255) DEFAULT NULL COMMENT '头像URL',
    `role` VARCHAR(32) NOT NULL DEFAULT 'STUDENT' COMMENT '角色：STUDENT/TEACHER/ADMIN',
    `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态：0禁用/1正常',
    `create_time` DATETIME DEFAULT NULL COMMENT '创建时间',
    `update_time` DATETIME DEFAULT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_username` (`username`),
    KEY `idx_role` (`role`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';

-- 3. 技能树表
CREATE TABLE IF NOT EXISTS `skill_tree` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `name` VARCHAR(128) NOT NULL COMMENT '技能树名称',
    `description` VARCHAR(500) DEFAULT NULL COMMENT '技能树描述',
    `icon` VARCHAR(255) DEFAULT NULL COMMENT '图标',
    `category` VARCHAR(64) NOT NULL COMMENT '分类：FRONTEND/BACKEND/DATABASE等',
    `difficulty_level` TINYINT NOT NULL DEFAULT 1 COMMENT '难度等级 1-5',
    `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态：0禁用/1正常',
    `create_time` DATETIME DEFAULT NULL COMMENT '创建时间',
    `update_time` DATETIME DEFAULT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_category` (`category`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='技能树表';

-- 4. 技能节点表
CREATE TABLE IF NOT EXISTS `skill_node` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `tree_id` BIGINT NOT NULL COMMENT '所属技能树ID',
    `parent_id` BIGINT NOT NULL DEFAULT 0 COMMENT '父节点ID，0表示根节点',
    `name` VARCHAR(128) NOT NULL COMMENT '节点名称',
    `description` VARCHAR(500) DEFAULT NULL COMMENT '节点描述',
    `node_type` VARCHAR(32) NOT NULL DEFAULT 'SKILL' COMMENT '节点类型：SKILL/CHECKPOINT/REWARD',
    `required_exp` INT NOT NULL DEFAULT 0 COMMENT '所需经验值',
    `unlock_condition` VARCHAR(255) DEFAULT NULL COMMENT '解锁条件描述',
    `reward` VARCHAR(500) DEFAULT NULL COMMENT '奖励内容（JSON格式）',
    `icon` VARCHAR(255) DEFAULT NULL COMMENT '图标',
    `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态：0禁用/1正常',
    `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序',
    `create_time` DATETIME DEFAULT NULL COMMENT '创建时间',
    `update_time` DATETIME DEFAULT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_tree_id` (`tree_id`),
    KEY `idx_parent_id` (`parent_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='技能节点表';

-- 5. 用户技能进度表
CREATE TABLE IF NOT EXISTS `user_skill_progress` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `node_id` BIGINT NOT NULL COMMENT '技能节点ID',
    `status` TINYINT NOT NULL DEFAULT 0 COMMENT '状态：0未解锁/1已解锁/2已完成',
    `current_exp` INT NOT NULL DEFAULT 0 COMMENT '当前经验值',
    `unlocked_at` DATETIME DEFAULT NULL COMMENT '解锁时间',
    `completed_at` DATETIME DEFAULT NULL COMMENT '完成时间',
    `create_time` DATETIME DEFAULT NULL COMMENT '创建时间',
    `update_time` DATETIME DEFAULT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_user_node` (`user_id`, `node_id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_node_id` (`node_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户技能进度表';

-- 6. 聊天会话表
CREATE TABLE IF NOT EXISTS `chat_conversation` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `title` VARCHAR(128) DEFAULT NULL COMMENT '会话标题',
    `dify_conversation_id` VARCHAR(128) DEFAULT NULL COMMENT 'Dify平台conversation_id',
    `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态：0已结束/1进行中',
    `create_time` DATETIME DEFAULT NULL COMMENT '创建时间',
    `update_time` DATETIME DEFAULT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_dify_conversation_id` (`dify_conversation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='聊天会话表';

-- 7. 聊天消息表
CREATE TABLE IF NOT EXISTS `chat_message` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `conversation_id` BIGINT NOT NULL COMMENT '所属会话ID',
    `role` VARCHAR(32) NOT NULL COMMENT '角色：USER/ASSISTANT/SYSTEM',
    `content` TEXT NOT NULL COMMENT '消息内容',
    `message_type` VARCHAR(32) NOT NULL DEFAULT 'TEXT' COMMENT '类型：TEXT/IMAGE/FILE',
    `dify_message_id` VARCHAR(128) DEFAULT NULL COMMENT 'Dify平台消息ID',
    `create_time` DATETIME DEFAULT NULL COMMENT '创建时间',
    PRIMARY KEY (`id`),
    KEY `idx_conversation_id` (`conversation_id`),
    KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='聊天消息表';

-- 8. 面试会话表
CREATE TABLE IF NOT EXISTS `interview_session` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `skill_node_id` BIGINT DEFAULT NULL COMMENT '关联技能节点ID',
    `title` VARCHAR(128) NOT NULL COMMENT '面试标题',
    `status` TINYINT NOT NULL DEFAULT 0 COMMENT '状态：0未开始/1进行中/2已完成',
    `total_score` INT DEFAULT NULL COMMENT '综合总分0-100',
    `evaluation` TEXT DEFAULT NULL COMMENT '综合评价文本',
    `start_time` DATETIME DEFAULT NULL COMMENT '开始时间',
    `end_time` DATETIME DEFAULT NULL COMMENT '结束时间',
    `create_time` DATETIME DEFAULT NULL COMMENT '创建时间',
    `update_time` DATETIME DEFAULT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_skill_node_id` (`skill_node_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='面试会话表';

-- 9. 面试消息表
CREATE TABLE IF NOT EXISTS `interview_message` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `session_id` BIGINT NOT NULL COMMENT '所属面试会话ID',
    `role` VARCHAR(32) NOT NULL COMMENT '角色：INTERVIEWER/CANDIDATE',
    `content` TEXT NOT NULL COMMENT '内容（问题或回答）',
    `question_type` VARCHAR(32) DEFAULT NULL COMMENT '题目类型：TECH/BEHAVIOR/ALGORITHM',
    `score` INT DEFAULT NULL COMMENT '该题得分（仅回答消息）',
    `comment` VARCHAR(500) DEFAULT NULL COMMENT '该题点评',
    `create_time` DATETIME DEFAULT NULL COMMENT '创建时间',
    PRIMARY KEY (`id`),
    KEY `idx_session_id` (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='面试消息表';

-- 10. 学习记录表
CREATE TABLE IF NOT EXISTS `learning_record` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `user_name` VARCHAR(64) DEFAULT NULL COMMENT '用户名（冗余，便于管理后台查询）',
    `course_name` VARCHAR(128) NOT NULL COMMENT '课程/内容名称',
    `course_type` VARCHAR(64) NOT NULL COMMENT '课程类型：PROGRAMMING/MATH/ENGLISH/ALGORITHM/DATABASE',
    `duration` INT NOT NULL DEFAULT 0 COMMENT '学习时长（分钟）',
    `score` INT DEFAULT NULL COMMENT '成绩/得分',
    `status` VARCHAR(32) NOT NULL DEFAULT 'IN_PROGRESS' COMMENT '状态：COMPLETED/IN_PROGRESS',
    `learn_date` DATE NOT NULL COMMENT '学习日期',
    `create_time` DATETIME DEFAULT NULL COMMENT '创建时间',
    `update_time` DATETIME DEFAULT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_course_type` (`course_type`),
    KEY `idx_learn_date` (`learn_date`),
    KEY `idx_user_learn_date` (`user_id`, `learn_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学习记录表';

-- 11. 简历优化记录表
CREATE TABLE IF NOT EXISTS `resume_optimization` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `original_file_name` VARCHAR(255) NOT NULL COMMENT '原始文件名',
    `original_file_url` VARCHAR(255) NOT NULL COMMENT '原始文件URL',
    `optimized_file_url` VARCHAR(255) DEFAULT NULL COMMENT '优化后文件URL',
    `original_score` INT DEFAULT NULL COMMENT '原始简历评分0-100',
    `optimized_score` INT DEFAULT NULL COMMENT '优化后评分0-100',
    `optimization_type` VARCHAR(32) DEFAULT NULL COMMENT '优化类型：OPTIMIZE/REWRITE',
    `suggestions` TEXT DEFAULT NULL COMMENT '优化建议/修改说明',
    `optimized_content` MEDIUMTEXT DEFAULT NULL COMMENT '优化后的简历内容（文本版）',
    `status` TINYINT NOT NULL DEFAULT 0 COMMENT '状态：0处理中/1完成/2失败',
    `create_time` DATETIME DEFAULT NULL COMMENT '创建时间',
    `update_time` DATETIME DEFAULT NULL COMMENT '更新时间',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='简历优化记录表';

-- ============================================================
-- 初始数据
-- ============================================================

-- 1. 插入用户数据（密码均为 123456，BCrypt加密后）
INSERT INTO `sys_user` (`username`, `password`, `nickname`, `email`, `phone`, `avatar`, `role`, `status`, `create_time`, `update_time`) VALUES
('admin', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5E', '管理员', 'admin@example.com', '13800138000', 'https://api.dicebear.com/7.x/avataaars/svg?seed=admin', 'ADMIN', 1, '2024-01-01 08:00:00', '2024-01-01 08:00:00'),
('zhangsan', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5E', '张三', 'zhangsan@example.com', '13800138001', 'https://api.dicebear.com/7.x/avataaars/svg?seed=zhangsan', 'STUDENT', 1, '2024-01-15 10:30:00', '2024-06-20 14:00:00'),
('lisi', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5E', '李四', 'lisi@example.com', '13800138002', 'https://api.dicebear.com/7.x/avataaars/svg?seed=lisi', 'STUDENT', 1, '2024-02-10 09:15:00', '2024-06-18 16:30:00'),
('wangwu', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5E', '王五', 'wangwu@example.com', '13800138003', 'https://api.dicebear.com/7.x/avataaars/svg?seed=wangwu', 'STUDENT', 1, '2024-03-05 11:45:00', '2024-06-15 10:00:00'),
('teacher_zhao', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iAt6Z5E', '赵老师', 'zhao@example.com', '13800138004', 'https://api.dicebear.com/7.x/avataaars/svg?seed=zhao', 'TEACHER', 1, '2024-01-20 08:30:00', '2024-06-10 09:00:00');

-- 2. 插入技能树数据
INSERT INTO `skill_tree` (`name`, `description`, `icon`, `category`, `difficulty_level`, `status`, `create_time`, `update_time`) VALUES
('前端开发', '涵盖 HTML、CSS、JavaScript、主流框架等前端技能', 'FrontEndIcon', 'FRONTEND', 3, 1, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
('后端开发', 'Java、Spring Boot、微服务、数据库等后端技能', 'BackEndIcon', 'BACKEND', 3, 1, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
('数据库', 'MySQL、Redis、MongoDB、数据库设计等', 'DatabaseIcon', 'DATABASE', 2, 1, '2024-01-12 10:00:00', '2024-01-12 10:00:00'),
('算法与数据结构', '常用算法、刷题技巧、面试算法题', 'AlgorithmIcon', 'ALGORITHM', 4, 1, '2024-01-15 10:00:00', '2024-01-15 10:00:00'),
('移动开发', 'HarmonyOS、iOS、Android 移动端开发', 'MobileIcon', 'MOBILE', 3, 1, '2024-02-01 10:00:00', '2024-02-01 10:00:00');

-- 3. 插入技能节点数据（前端开发技能树）
INSERT INTO `skill_node` (`tree_id`, `parent_id`, `name`, `description`, `node_type`, `required_exp`, `unlock_condition`, `reward`, `icon`, `status`, `sort_order`, `create_time`, `update_time`) VALUES
-- 前端技能树根节点
(1, 0, '前端开发入门', '前端开发基础知识体系', 'SKILL', 0, NULL, NULL, 'FrontendRoot', 1, 0, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
-- HTML/CSS 分支
(1, 1, 'HTML 基础', '掌握 HTML 标签、表单、语义化', 'SKILL', 50, '完成前端入门', NULL, 'HtmlIcon', 1, 1, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
(1, 1, 'CSS 基础', '掌握选择器、盒模型、布局', 'SKILL', 50, '完成 HTML 基础', NULL, 'CssIcon', 1, 2, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
(1, 1, 'CSS 进阶', '掌握 Flexbox、Grid、动画', 'SKILL', 80, '完成 CSS 基础', NULL, 'CssAdvancedIcon', 1, 3, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
-- JavaScript 分支
(1, 1, 'JavaScript 基础', '掌握变量、函数、DOM 操作', 'SKILL', 100, '完成 HTML/CSS 基础', NULL, 'JsIcon', 1, 4, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
(1, 5, 'JavaScript 进阶', '原型链、闭包、异步编程', 'SKILL', 150, '完成 JS 基础', NULL, 'JsAdvancedIcon', 1, 5, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
(1, 5, 'ES6+ 新特性', 'let/const、Promise、async/await', 'SKILL', 100, '完成 JS 基础', NULL, 'Es6Icon', 1, 6, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
-- 框架分支
(1, 1, 'Vue.js', '掌握 Vue3、Composition API', 'SKILL', 200, '完成 JS 进阶', NULL, 'VueIcon', 1, 7, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
(1, 8, 'Vue 项目实战', '完成一个完整的 Vue 项目', 'CHECKPOINT', 300, '完成 Vue.js', '{"project_count": 1}', 'VueProjectIcon', 1, 8, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
(1, 1, 'React', '掌握 React、Hooks、Redux', 'SKILL', 200, '完成 JS 进阶', NULL, 'ReactIcon', 1, 9, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
-- 后端技能树节点
(2, 0, 'Java 基础', '掌握 Java 语法、OOP 思想', 'SKILL', 0, NULL, NULL, 'JavaIcon', 1, 0, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
(2, 11, 'Spring Boot', '掌握 Spring Boot 快速开发', 'SKILL', 150, '完成 Java 基础', NULL, 'SpringIcon', 1, 1, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
(2, 12, 'Spring Cloud', '掌握微服务、注册中心、网关', 'SKILL', 300, '完成 Spring Boot', NULL, 'SpringCloudIcon', 1, 2, '2024-01-10 10:00:00', '2024-01-10 10:00:00'),
-- 数据库技能树节点
(3, 0, 'MySQL 基础', '掌握 SQL、索引、事务', 'SKILL', 0, NULL, NULL, 'MysqlIcon', 1, 0, '2024-01-12 10:00:00', '2024-01-12 10:00:00'),
(3, 14, 'MySQL 进阶', '掌握慢查询优化、分库分表', 'SKILL', 150, '完成 MySQL 基础', NULL, 'MysqlAdvancedIcon', 1, 1, '2024-01-12 10:00:00', '2024-01-12 10:00:00'),
(3, 14, 'Redis', '掌握缓存、分布式锁、消息队列', 'SKILL', 120, '完成 MySQL 基础', NULL, 'RedisIcon', 1, 2, '2024-01-12 10:00:00', '2024-01-12 10:00:00');

-- 4. 插入用户技能进度数据
INSERT INTO `user_skill_progress` (`user_id`, `node_id`, `status`, `current_exp`, `unlocked_at`, `completed_at`, `create_time`, `update_time`) VALUES
-- 张三的进度
(2, 1, 1, 50, '2024-02-01 10:00:00', NULL, '2024-02-01 10:00:00', '2024-03-15 14:00:00'),
(2, 2, 2, 50, '2024-02-01 10:00:00', '2024-02-10 15:00:00', '2024-02-01 10:00:00', '2024-02-10 15:00:00'),
(2, 3, 2, 80, '2024-02-10 16:00:00', '2024-02-25 18:00:00', '2024-02-10 16:00:00', '2024-02-25 18:00:00'),
(2, 4, 1, 30, '2024-02-25 19:00:00', NULL, '2024-02-25 19:00:00', '2024-03-01 10:00:00'),
(2, 5, 1, 100, '2024-03-01 11:00:00', NULL, '2024-03-01 11:00:00', '2024-03-10 09:00:00'),
-- 李四的进度
(3, 1, 1, 100, '2024-02-15 10:00:00', NULL, '2024-02-15 10:00:00', '2024-03-20 16:00:00'),
(3, 2, 2, 50, '2024-02-15 10:00:00', '2024-03-05 14:00:00', '2024-02-15 10:00:00', '2024-03-05 14:00:00'),
(3, 3, 2, 80, '2024-03-05 15:00:00', '2024-03-15 17:00:00', '2024-03-05 15:00:00', '2024-03-15 17:00:00'),
(3, 4, 1, 80, '2024-03-15 18:00:00', NULL, '2024-03-15 18:00:00', '2024-03-25 11:00:00'),
(3, 5, 1, 100, '2024-03-15 18:00:00', NULL, '2024-03-15 18:00:00', '2024-04-01 10:00:00'),
(3, 6, 1, 50, '2024-04-01 11:00:00', NULL, '2024-04-01 11:00:00', '2024-04-10 15:00:00'),
-- 王五的进度（进度较少）
(4, 1, 1, 50, '2024-03-10 09:00:00', NULL, '2024-03-10 09:00:00', '2024-03-20 14:00:00'),
(4, 2, 1, 30, '2024-03-20 15:00:00', NULL, '2024-03-20 15:00:00', '2024-04-01 10:00:00');

-- 5. 插入聊天会话数据
INSERT INTO `chat_conversation` (`user_id`, `title`, `dify_conversation_id`, `status`, `create_time`, `update_time`) VALUES
(2, '关于 Vue3 响应式原理的讨论', 'dify_conv_001', 0, '2024-05-10 14:00:00', '2024-05-10 15:30:00'),
(2, 'Spring Boot 面试问题', 'dify_conv_002', 0, '2024-05-15 09:00:00', '2024-05-15 10:00:00'),
(2, '职业规划咨询', 'dify_conv_003', 1, '2024-06-20 19:00:00', '2024-06-20 20:00:00'),
(3, '算法学习建议', 'dify_conv_004', 0, '2024-05-18 11:00:00', '2024-05-18 12:00:00'),
(3, '前端框架对比', 'dify_conv_005', 1, '2024-06-18 15:00:00', '2024-06-18 16:00:00'),
(4, '如何准备秋招', 'dify_conv_006', 0, '2024-06-10 10:00:00', '2024-06-10 11:00:00');

-- 6. 插入聊天消息数据
INSERT INTO `chat_message` (`conversation_id`, `role`, `content`, `message_type`, `dify_message_id`, `create_time`) VALUES
-- 会话1：Vue3 响应式
(1, 'USER', '你好，我想了解一下 Vue3 的响应式原理', 'TEXT', 'msg_001', '2024-05-10 14:00:00'),
(1, 'ASSISTANT', 'Vue3 的响应式系统基于 ES6 的 Proxy 实现。相比 Vue2 的 Object.defineProperty，Proxy 可以劫持整个对象，包括新增属性和数组索引。核心代码在 reactivity 包中，通过 track 和 trigger 函数实现依赖收集和派发更新。', 'TEXT', 'msg_002', '2024-05-10 14:01:00'),
(1, 'USER', '那 ref 和 reactive 有什么区别？', 'TEXT', 'msg_003', '2024-05-10 14:05:00'),
(1, 'ASSISTANT', '主要区别：\n1. ref 接收基本类型值，通过 .value 访问；reactive 只接收对象\n2. ref 在模板中会自动解包，reactive 需要保持响应式对象的引用\n3. ref 可以包含对象，内部会调用 reactive 转换', 'TEXT', 'msg_004', '2024-05-10 14:06:00'),
(1, 'USER', '明白了，谢谢！', 'TEXT', 'msg_005', '2024-05-10 15:30:00'),
(1, 'ASSISTANT', '不客气！还有其他问题随时问我。', 'TEXT', 'msg_006', '2024-05-10 15:30:00'),
-- 会话2：Spring Boot 面试
(2, 'USER', '帮我模拟一下 Spring Boot 相关的面试问题', 'TEXT', 'msg_007', '2024-05-15 09:00:00'),
(2, 'ASSISTANT', '好的，下面开始 Spring Boot 模拟面试。\n\n第一题：请解释 Spring Boot 的自动配置原理', 'TEXT', 'msg_008', '2024-05-15 09:00:30'),
(2, 'USER', 'Spring Boot 通过 @EnableAutoConfiguration 注解启用自动配置，它会读取 META-INF/spring.factories 文件中定义的 AutoConfiguration 类，然后根据条件注解 @ConditionalOnClass 等判断是否需要实例化这些 Bean。', 'TEXT', 'msg_009', '2024-05-15 09:02:00'),
(2, 'ASSISTANT', '回答得很好！下一个问题：Spring Boot 如何实现事务管理？', 'TEXT', 'msg_010', '2024-05-15 09:03:00'),
(2, 'USER', '使用 @Transactional 注解即可，需要在启动类或配置类上添加 @EnableTransactionManagement 开启事务支持。', 'TEXT', 'msg_011', '2024-05-15 09:05:00'),
-- 会话3：职业规划
(3, 'USER', '我现在研二，马上要秋招了，该如何准备？', 'TEXT', 'msg_012', '2024-06-20 19:00:00'),
(3, 'ASSISTANT', '研二暑期是黄金准备期，建议分三个方向：\n1. 技术基础：数据结构算法、系统设计、编程语言\n2. 项目经历：梳理实验室项目、保证 2-3 个亮点项目\n3. 刷题：每天 2-3 道算法题，保持手感\n\n你现在最想了解哪个方向的详细建议？', 'TEXT', 'msg_013', '2024-06-20 19:01:00'),
(3, 'USER', '先说说项目经历怎么梳理吧', 'TEXT', 'msg_014', '2024-06-20 19:30:00'),
(3, 'ASSISTANT', '项目梳理建议：\n1. 每个项目准备 3 分钟介绍（背景、技术栈、难点、成果）\n2. 准备 2-3 个深挖点：技术难点、创新点、性能优化\n3. 用 STAR 法则描述项目经历\n4. 准备一个项目 demo 或演示视频', 'TEXT', 'msg_015', '2024-06-20 19:31:00'),
-- 会话4：算法学习
(4, 'USER', '我算法比较薄弱，应该怎么学习？', 'TEXT', 'msg_016', '2024-05-18 11:00:00'),
(4, 'ASSISTANT', '算法学习路径建议：\n1. 基础：数组、链表、栈队列（1-2周）\n2. 核心：哈希表、二叉树、图（2-3周）\n3. 进阶：动态规划、回溯、贪心（3-4周）\n4. 高频：排序、位运算、双指针（持续）\n\n建议按类别刷题，每类掌握 20-30 道高频题即可。', 'TEXT', 'msg_017', '2024-05-18 11:01:00');

-- 7. 插入面试会话数据
INSERT INTO `interview_session` (`user_id`, `skill_node_id`, `title`, `status`, `total_score`, `evaluation`, `start_time`, `end_time`, `create_time`, `update_time`) VALUES
(2, 8, 'Vue.js 项目实战面试', 2, 78, '项目经验较丰富，对 Vue3 响应式原理理解深入，但在工程化方面（如 Webpack 配置、CI/CD）经验不足。建议加强前端工程化知识。', '2024-06-15 14:00:00', '2024-06-15 15:00:00', '2024-06-15 14:00:00', '2024-06-15 15:00:00'),
(2, 12, 'Spring Boot 基础面试', 2, 85, 'Java 基础扎实，Spring Boot 使用熟练，对常见问题（如事务、缓存）有较好理解。表达清晰，回答有条理。', '2024-06-18 10:00:00', '2024-06-18 10:45:00', '2024-06-18 10:00:00', '2024-06-18 10:45:00'),
(3, 2, 'HTML/CSS 基础面试', 2, 92, '前端基础非常扎实，HTML 语义化、CSS 布局都有实战经验。回答问题全面且有条理，推荐！', '2024-06-10 09:00:00', '2024-06-10 09:30:00', '2024-06-10 09:00:00', '2024-06-10 09:30:00'),
(3, 11, 'Java 基础面试', 2, 70, 'Java 基础概念清晰，但多线程和并发编程是薄弱环节。建议加强 java.util.concurrent 包的学习。', '2024-06-12 14:00:00', '2024-06-12 14:40:00', '2024-06-12 14:00:00', '2024-06-12 14:40:00'),
(4, NULL, '全栈方向模拟面试', 1, NULL, NULL, '2024-06-20 15:00:00', NULL, '2024-06-20 15:00:00', '2024-06-20 15:00:00');

-- 8. 插入面试消息数据
INSERT INTO `interview_message` (`session_id`, `role`, `content`, `question_type`, `score`, `comment`, `create_time`) VALUES
-- 面试1：Vue.js 项目实战
(1, 'INTERVIEWER', '请介绍一下你做过的 Vue 项目，以及项目的技术架构', 'TECH', 80, '项目介绍清晰，技术选型合理', '2024-06-15 14:00:00'),
(1, 'CANDIDATE', '我做过一个在线教育平台，前端使用 Vue3 + Vite，后端使用 Spring Boot。使用 Vue Router 做路由管理，Pinia 做状态管理。项目采用微前端架构，主应用加载子模块。', 'TECH', NULL, NULL, '2024-06-15 14:02:00'),
(1, 'INTERVIEWER', 'Vue3 的响应式原理是什么？ref 和 reactive 有什么区别？', 'TECH', 85, '原理讲解清晰，区别说明到位', '2024-06-15 14:05:00'),
(1, 'CANDIDATE', 'Vue3 响应式基于 Proxy 实现。Proxy 可以拦截对象的各种操作，包括属性访问、赋值、删除等。ref 用于基本类型，通过 .value 访问；reactive 用于对象，在模板中会自动解包 ref。', 'TECH', NULL, NULL, '2024-06-15 14:06:00'),
(1, 'INTERVIEWER', '如何在 Vue 项目中实现性能优化？', 'TECH', 75, '提到了一些优化手段，但不够全面', '2024-06-15 14:10:00'),
(1, 'CANDIDATE', '我用过：1) keep-alive 缓存组件 2) 路由懒加载 3) 图片懒加载 4) v-memo 减少不必要的渲染。', 'TECH', NULL, NULL, '2024-06-15 14:11:00'),
-- 面试2：Spring Boot 基础
(2, 'INTERVIEWER', 'Spring Boot 如何实现自动配置？', 'TECH', 90, '讲解非常清晰，还提到了条件注解', '2024-06-18 10:00:00'),
(2, 'CANDIDATE', '通过 @EnableAutoConfiguration 启用自动配置，Spring Boot 会扫描 spring.factories 中的 AutoConfiguration 类，根据 @ConditionalOnClass 等条件注解判断是否需要创建 Bean。', 'TECH', NULL, NULL, '2024-06-18 10:01:00'),
(2, 'INTERVIEWER', 'Spring Boot 如何配置多数据源？', 'TECH', 82, '配置方法正确，但对分布式事务经验不足', '2024-06-18 10:05:00'),
(2, 'CANDIDATE', '可以使用 Druid 连接池，配置多个 DataSource，通过 @Primary 指定主数据源，使用 @Qualifier 切换。也可以使用 ShardingSphere 做分库分表。', 'TECH', NULL, NULL, '2024-06-18 10:06:00'),
-- 面试3：HTML/CSS 基础
(3, 'INTERVIEWER', 'CSS Flexbox 和 Grid 的区别是什么？分别在什么场景使用？', 'TECH', 95, '理解深入，能准确说出适用场景', '2024-06-10 09:00:00'),
(3, 'CANDIDATE', 'Flexbox 是一维布局，适合单行或单列的元素排列，如导航栏、卡片列表。Grid 是二维布局，适合复杂的页面结构，如整体页面布局、相册等。两者的选择取决于布局维度。', 'TECH', NULL, NULL, '2024-06-10 09:01:00'),
(3, 'INTERVIEWER', '如何实现一个垂直居中的布局？至少说出 3 种方法', 'TECH', 90, '方法全面，涵盖传统和现代方案', '2024-06-10 09:05:00'),
(3, 'CANDIDATE', '1) flex + justify-content + align-items 2) grid + place-items: center 3) absolute + transform: translate(-50%, -50%) 4) position + margin auto + top/bottom/left/right: 0', 'TECH', NULL, NULL, '2024-06-10 09:06:00');

-- 9. 插入学习记录数据
INSERT INTO `learning_record` (`user_id`, `user_name`, `course_name`, `course_type`, `duration`, `score`, `status`, `learn_date`, `create_time`, `update_time`) VALUES
-- 张三的学习记录
(2, '张三', 'Vue3 入门教程', 'PROGRAMMING', 120, 92, 'COMPLETED', '2024-05-01', '2024-05-01 10:00:00', '2024-05-05 18:00:00'),
(2, '张三', 'React 实战', 'PROGRAMMING', 180, 85, 'COMPLETED', '2024-05-06', '2024-05-06 09:00:00', '2024-05-10 17:00:00'),
(2, '张三', 'TypeScript 基础', 'PROGRAMMING', 90, 78, 'COMPLETED', '2024-05-12', '2024-05-12 14:00:00', '2024-05-14 16:00:00'),
(2, '张三', '数据结构与算法', 'ALGORITHM', 60, 88, 'COMPLETED', '2024-05-15', '2024-05-15 08:00:00', '2024-05-15 10:00:00'),
(2, '张三', 'MySQL 基础', 'DATABASE', 45, 95, 'COMPLETED', '2024-05-18', '2024-05-18 15:00:00', '2024-05-18 17:00:00'),
(2, '张三', 'Spring Boot 进阶', 'PROGRAMMING', 30, NULL, 'IN_PROGRESS', '2024-06-20', '2024-06-20 19:00:00', '2024-06-20 20:00:00'),
-- 李四的学习记录
(3, '李四', '高等数学', 'MATH', 90, 75, 'COMPLETED', '2024-05-02', '2024-05-02 08:00:00', '2024-05-04 17:00:00'),
(3, '李四', '线性代数', 'MATH', 60, 82, 'COMPLETED', '2024-05-05', '2024-05-05 09:00:00', '2024-05-05 11:00:00'),
(3, '李四', '大学英语四级', 'ENGLISH', 120, 68, 'COMPLETED', '2024-05-08', '2024-05-08 14:00:00', '2024-05-12 16:00:00'),
(3, '李四', '动态规划', 'ALGORITHM', 150, 90, 'COMPLETED', '2024-05-15', '2024-05-15 08:00:00', '2024-05-20 17:00:00'),
(3, '李四', 'Redis 实战', 'DATABASE', 80, 85, 'COMPLETED', '2024-05-22', '2024-05-22 10:00:00', '2024-05-25 14:00:00'),
(3, '李四', '概率论', 'MATH', 45, NULL, 'IN_PROGRESS', '2024-06-18', '2024-06-18 15:00:00', '2024-06-18 17:00:00'),
-- 王五的学习记录
(4, '王五', 'Webpack 配置', 'PROGRAMMING', 60, 70, 'COMPLETED', '2024-05-10', '2024-05-10 09:00:00', '2024-05-10 11:00:00'),
(4, '王五', '图论基础', 'ALGORITHM', 90, 65, 'COMPLETED', '2024-05-14', '2024-05-14 14:00:00', '2024-05-14 17:00:00'),
(4, '王五', 'Node.js 后端开发', 'PROGRAMMING', 120, 72, 'COMPLETED', '2024-05-18', '2024-05-18 08:00:00', '2024-05-22 16:00:00'),
(4, '王五', '排序算法', 'ALGORITHM', 30, NULL, 'IN_PROGRESS', '2024-06-19', '2024-06-19 10:00:00', '2024-06-19 11:00:00'),
-- 赵老师的教学记录
(5, '赵老师', 'Vue3 入门教程', 'PROGRAMMING', 480, NULL, 'COMPLETED', '2024-05-01', '2024-05-01 08:00:00', '2024-05-03 16:00:00'),
(5, '赵老师', 'Spring Boot 实战', 'PROGRAMMING', 540, NULL, 'COMPLETED', '2024-05-06', '2024-05-08 17:00:00', '2024-05-08 17:00:00'),
(5, '赵老师', 'MySQL 优化', 'DATABASE', 300, NULL, 'COMPLETED', '2024-05-12', '2024-05-14 16:00:00', '2024-05-14 16:00:00');

-- 10. 插入简历优化记录数据
INSERT INTO `resume_optimization` (`user_id`, `original_file_name`, `original_file_url`, `optimized_file_url`, `original_score`, `optimized_score`, `optimization_type`, `suggestions`, `optimized_content`, `status`, `create_time`, `update_time`) VALUES
-- 张三的简历
(2, 'zhangsan_resume_v1.pdf', 'https://cdn.example.com/resumes/zhangsan_v1.pdf', 'https://cdn.example.com/resumes/zhangsan_v1_optimized.pdf', 65, 88, 'OPTIMIZE', '1. 项目经历描述过于简单，建议用 STAR 法则重写\n2. 缺少技术亮点总结\n3. 教育背景应突出与职位相关的课程\n4. 技能清单应按熟练度分层', '姓名：张三\n手机：138****8001\n邮箱：zhangsan@example.com\n\n求职意向：Java 开发工程师\n\n教育背景\nXX大学 计算机科学与技术 硕士 2022-2025\n- GPA 3.8/4.0，连续三年获得奖学金\n- 主修课程：数据结构、算法设计、操作系统、计算机网络\n\n项目经历\n在线教育平台后端开发（Spring Boot + MySQL）\n2024.03 - 2024.06\n- 负责用户认证模块，采用 JWT + Redis 实现分布式会话管理，支持 10万+ 并发登录\n- 优化数据库查询，通过索引优化和 SQL 重写，将核心接口响应时间从 500ms 降至 50ms\n- 设计并实现消息队列异步处理机制，使用 RabbitMQ 解耦订单和通知系统\n\n技能清单\n- 后端开发：Java (精通)、Spring Boot (精通)、Spring Cloud (熟悉)\n- 数据库：MySQL (精通)、Redis (熟悉)、MongoDB (了解)\n- 工具：Git、Docker、Linux', 1, '2024-06-15 10:00:00', '2024-06-15 14:00:00'),
-- 李四的简历
(3, 'lisi_resume_2024.pdf', 'https://cdn.example.com/resumes/lisi_2024.pdf', 'https://cdn.example.com/resumes/lisi_2024_optimized.pdf', 58, 82, 'REWRITE', '1. 简历结构混乱，需要重新梳理\n2. 项目经历与技术栈不匹配\n3. 缺少量化成果数据\n4. 建议增加 GitHub 链接或个人技术博客', '姓名：李四\n手机：138****8002\n邮箱：lisi@example.com\nGitHub: github.com/lisi-dev\n\n求职意向：前端开发工程师\n\n教育背景\nXX大学 软件工程 本科 2020-2024\n- 综合排名 Top 10%，获国家奖学金\n\n专业技能\n- 前端框架：Vue.js (精通)、React (熟悉)\n- 构建工具：Vite、Webpack\n- 其他：TypeScript、Node.js、MySQL\n\n项目经历\n个人博客系统（Vue3 + Nuxt.js）\n2023.09 - 2023.12\n- 独立开发技术博客网站，使用 SSR 提升首屏加载速度，Google PageSpeed 得分 95+\n- 实现 Markdown 编辑器和代码高亮功能，支持 SEO 优化\n- 使用 Vite 构建，Bundle 分析优化后首包体积减少 40%\n\n校园失物招领小程序（微信小程序）\n2023.06 - 2023.08\n- 使用 Taro 框架开发，支持发布、搜索、认领等功能\n- 集成云开发，无需自建后端，降低运维成本 60%', 1, '2024-06-10 09:00:00', '2024-06-10 12:00:00'),
-- 王五的简历（处理中）
(4, 'wangwu_resume.pdf', 'https://cdn.example.com/resumes/wangwu.pdf', NULL, NULL, NULL, 'OPTIMIZE', NULL, NULL, 0, '2024-06-20 15:00:00', '2024-06-20 15:00:00');
```

---

## 六、设计决策说明

1. **聊天消息表无主键自增以外的 update_time**：消息为不可变数据，创建后不再修改，因此不需要 update_time。
2. **面试评价合并到 interview_session**：单次面试只有一个综合评价，以 JSON 文本或字段形式存储在 session 表中，避免额外一张表。若未来需要多维度评分（技术/沟通/思维），可在 evaluation 字段存结构化 JSON。
3. **learning_record.user_name 冗余**：管理后台学习记录列表页需要展示用户名，若通过 JOIN sys_user 查询，在数据量大时分页性能下降。此冗余字段在用户信息修改时**不强制同步更新**（历史记录保留当时的用户名），符合业务语义。
4. **resume_optimization 同时保留 file_url 和 content**：file_url 用于下载优化后的简历文件，content 用于在 App 内直接展示文本内容，避免前端需要额外解析文件。
5. **不使用物理外键**：所有表间关联通过代码层和索引保证，提升扩展性和性能。
