package com.aicompanion.model.vo.arkts;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ConversationVO {
    private Long conversationId;
    private String title;
    private String agentType;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
