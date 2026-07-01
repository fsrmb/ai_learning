package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("ai_chat_history")
public class AIChatHistory extends BaseEntity {

    @TableField("user_id")
    private Long userId;

    @TableField("conversation_id")
    private Long conversationId;

    @TableField("query_text")
    private String queryText;

    @TableField("response_text")
    private String responseText;

    @TableField("model_name")
    private String modelName;

    @TableField("token_count")
    private Integer tokenCount;

    @TableField("duration_ms")
    private Integer durationMs;
}