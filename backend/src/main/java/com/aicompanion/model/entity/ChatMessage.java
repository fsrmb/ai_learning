package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 聊天消息实体类
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("chat_message")
public class ChatMessage extends BaseEntity {

    /**
     * 所属会话ID
     */
    @TableField("conversation_id")
    private Long conversationId;

    /**
     * 角色：USER/ASSISTANT/SYSTEM
     */
    @TableField("role")
    private String role;

    /**
     * 消息内容
     */
    @TableField("content")
    private String content;

    /**
     * 类型：TEXT/IMAGE/FILE
     */
    @TableField("message_type")
    private String messageType;

    /**
     * Dify平台消息ID
     */
    @TableField("dify_message_id")
    private String difyMessageId;
}