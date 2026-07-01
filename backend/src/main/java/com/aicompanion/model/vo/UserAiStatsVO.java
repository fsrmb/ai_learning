package com.aicompanion.model.vo;

import lombok.Data;

@Data
public class UserAiStatsVO {

    private Long userId;

    private String username;

    private String nickname;

    private Long chatCount;

    private Long totalTokens;

    private Long totalDurationMs;
}