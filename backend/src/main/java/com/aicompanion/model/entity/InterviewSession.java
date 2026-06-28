package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 面试会话实体类
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("interview_session")
public class InterviewSession extends BaseEntity {

    /**
     * 用户ID
     */
    @TableField("user_id")
    private Long userId;

    /**
     * 关联技能节点ID
     */
    @TableField("skill_node_id")
    private Long skillNodeId;

    /**
     * 面试标题
     */
    @TableField("title")
    private String title;

    /**
     * 状态：0未开始/1进行中/2已完成
     */
    @TableField("status")
    private Integer status;

    /**
     * 综合总分0-100
     */
    @TableField("total_score")
    private Integer totalScore;

    /**
     * 综合评价文本
     */
    @TableField("evaluation")
    private String evaluation;

    /**
     * 开始时间
     */
    @TableField("start_time")
    private LocalDateTime startTime;

    /**
     * 结束时间
     */
    @TableField("end_time")
    private LocalDateTime endTime;
}