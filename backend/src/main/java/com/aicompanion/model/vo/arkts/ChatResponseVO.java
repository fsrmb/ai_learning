package com.aicompanion.model.vo.arkts;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ChatResponseVO {
    private Long messageId;
    private String content;
    private LocalDateTime createdAt;
}
