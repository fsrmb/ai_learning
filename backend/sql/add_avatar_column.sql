-- 为 sys_user 表添加 avatar 字段
-- 执行此 SQL 以支持头像功能

ALTER TABLE sys_user ADD COLUMN avatar VARCHAR(100) DEFAULT NULL COMMENT '头像文件名，格式: avatar_${username}.jpg';