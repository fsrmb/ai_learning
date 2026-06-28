package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 答题明细实体类
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("skill_assessment_detail")
public class SkillAssessmentDetail extends BaseEntity {

    /**
     * 评估记录ID
     */
    @TableField("assessment_id")
    private Long assessmentId;

    /**
     * 题目ID
     */
    @TableField("question_id")
    private Long questionId;

    /**
     * 用户答案
     */
    @TableField("user_answer")
    private String userAnswer;

    /**
     * 是否正确：0错误/1正确
     */
    @TableField("is_correct")
    private Integer isCorrect;

    /**
     * 本题耗时（秒）
     */
    @TableField("time_spent_seconds")
    private Integer timeSpentSeconds;
}