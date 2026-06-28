package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * 题目库实体类
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("skill_question")
public class SkillQuestion extends BaseEntity {

    /**
     * 所属技能节点ID
     */
    @TableField("node_id")
    private Long nodeId;

    /**
     * 题目内容
     */
    @TableField("question_text")
    private String questionText;

    /**
     * 选项JSON数组
     */
    @TableField("options_json")
    private String optionsJson;

    /**
     * 正确答案，如"A"
     */
    @TableField("correct_answer")
    private String correctAnswer;

    /**
     * 答案解析
     */
    @TableField("explanation")
    private String explanation;

    /**
     * 难度等级1-5
     */
    @TableField("difficulty")
    private Integer difficulty;

    /**
     * 来源：AI_GENERATED(AI生成)/MANUAL(人工录入)
     */
    @TableField("source")
    private String source;

    /**
     * 使用次数
     */
    @TableField("use_count")
    private Integer useCount;

    /**
     * 正确率统计
     */
    @TableField("correct_rate")
    private BigDecimal correctRate;
}