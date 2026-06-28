package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 聊天会话实体类
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("chat_conversation")
public class ChatConversation extends BaseEntity {

    /**
     * 用户ID
     */
    @TableField("user_id")
    private Long userId;

    /**
     * 会话标题
     */
    @TableField("title")
    private String title;

    /**
     * Dify平台conversation_id
     */
    @TableField("dify_conversation_id")
    private String difyConversationId;

    /**
     * 状态：0已结束/1进行中
     */
    @TableField("status")
    private Integer status;
}