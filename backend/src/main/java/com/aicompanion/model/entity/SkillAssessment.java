package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 评估记录实体类
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("skill_assessment")
public class SkillAssessment extends BaseEntity {

    /**
     * 用户ID
     */
    @TableField("user_id")
    private Long userId;

    /**
     * 技能节点ID
     */
    @TableField("node_id")
    private Long nodeId;

    /**
     * 评估时间
     */
    @TableField("assessment_time")
    private LocalDateTime assessmentTime;

    /**
     * 答题耗时（秒）
     */
    @TableField("duration_seconds")
    private Integer durationSeconds;

    /**
     * 本次得分
     */
    @TableField("total_score")
    private BigDecimal totalScore;

    /**
     * 通过阈值（默认70%）
     */
    @TableField("pass_threshold")
    private BigDecimal passThreshold;

    /**
     * 是否通过：0失败/1通过
     */
    @TableField("passed")
    private Integer passed;

    /**
     * 题目数量
     */
    @TableField("question_count")
    private Integer questionCount;

    /**
     * 正确数量
     */
    @TableField("correct_count")
    private Integer correctCount;

    /**
     * 难度级别1-5
     */
    @TableField("difficulty")
    private Integer difficulty;
}