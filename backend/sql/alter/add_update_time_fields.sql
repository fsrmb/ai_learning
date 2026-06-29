-- ============================================================
-- 修改时间: 2026-06-29
-- 修改内容: 为缺少 update_time 字段的表添加该字段
-- ============================================================

-- 1. 为 chat_message 表添加 update_time 字段
ALTER TABLE `chat_message` 
ADD COLUMN `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `create_time`;

-- 2. 为 skill_assessment_detail 表添加 update_time 字段
ALTER TABLE `skill_assessment_detail` 
ADD COLUMN `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `create_time`;

-- 3. 为 interview_message 表添加 update_time 字段
ALTER TABLE `interview_message` 
ADD COLUMN `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间' AFTER `create_time`;

-- 4. 创建 ai_chat_history 表（如果不存在）
CREATE TABLE IF NOT EXISTS `ai_chat_history` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `user_id` BIGINT NOT NULL COMMENT '用户ID',
    `conversation_id` BIGINT DEFAULT NULL COMMENT '会话ID',
    `query_text` TEXT NOT NULL COMMENT '用户查询文本',
    `response_text` TEXT DEFAULT NULL COMMENT 'AI响应文本',
    `model_name` VARCHAR(64) DEFAULT NULL COMMENT '使用的模型名称',
    `token_count` INT DEFAULT 0 COMMENT '消耗token数量',
    `duration_ms` INT DEFAULT 0 COMMENT '响应耗时(毫秒)',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    `deleted` INT NOT NULL DEFAULT 0 COMMENT '删除标志：0未删除/1已删除',
    PRIMARY KEY (`id`),
    KEY `idx_user_id` (`user_id`),
    KEY `idx_conversation_id` (`conversation_id`),
    KEY `idx_deleted` (`deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI聊天历史记录表';
