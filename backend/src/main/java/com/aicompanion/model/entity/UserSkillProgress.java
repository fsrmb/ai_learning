package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("user_skill_progress")
public class UserSkillProgress extends BaseEntity {
    
    @TableField("user_id")
    private Long userId;
    
    @TableField("node_id")
    private Long nodeId;
    
    @TableField("status")
    private String status;
    
    @TableField("unlock_time")
    private LocalDateTime unlockTime;
    
    @TableField("start_time")
    private LocalDateTime startTime;
    
    @TableField("complete_time")
    private LocalDateTime completeTime;
    
    @TableField("study_duration")
    private Integer studyDuration;
    
    @TableField("best_score")
    private BigDecimal bestScore;
    
    @TableField("latest_score")
    private BigDecimal latestScore;
    
    @TableField("attempt_count")
    private Integer attemptCount;
    
    @TableField("pass_count")
    private Integer passCount;
    
    @TableField("exp_points")
    private Integer expPoints;
}