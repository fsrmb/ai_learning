package com.aicompanion.model.vo;

import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class SkillAssessmentVO {

    private Long id;

    private Long userId;

    private String userName;

    private Long nodeId;

    private String nodeName;

    private String treeName;

    private LocalDateTime assessmentTime;

    private Integer durationSeconds;

    private BigDecimal totalScore;

    private BigDecimal passThreshold;

    private Integer passed;

    private String passedText;

    private Integer questionCount;

    private Integer correctCount;

    private Integer difficulty;

    private String difficultyText;

    private LocalDateTime createTime;
}