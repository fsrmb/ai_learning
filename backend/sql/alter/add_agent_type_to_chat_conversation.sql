-- ============================================================
-- 修改时间: 2026-06-29
-- 修改内容: 为 chat_conversation 表添加 agent_type 字段
-- ============================================================

ALTER TABLE `chat_conversation` 
ADD COLUMN `agent_type` VARCHAR(32) DEFAULT 'CHAT' COMMENT '代理类型：CHAT/INTERVIEW/RESUME' AFTER `status`;

-- 为已有数据设置默认值
UPDATE `chat_conversation` SET `agent_type` = 'CHAT' WHERE `agent_type` IS NULL;
