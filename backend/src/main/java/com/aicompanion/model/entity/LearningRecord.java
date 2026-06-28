package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 学习记录实体类
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("learning_record")
public class LearningRecord extends BaseEntity {

    /**
     * 用户ID
     */
    @TableField("user_id")
    private Long userId;

    /**
     * 用户名（冗余，便于管理后台查询）
     */
    @TableField("user_name")
    private String userName;

    /**
     * 课程/内容名称
     */
    @TableField("course_name")
    private String courseName;

    /**
     * 课程类型：PROGRAMMING/MATH/ENGLISH/ALGORITHM/DATABASE
     */
    @TableField("course_type")
    private String courseType;

    /**
     * 学习时长（分钟）
     */
    @TableField("duration")
    private Integer duration;

    /**
     * 成绩/得分
     */
    @TableField("score")
    private Integer score;

    /**
     * 状态：COMPLETED/IN_PROGRESS
     */
    @TableField("status")
    private String status;

    /**
     * 学习日期
     */
    @TableField("learn_date")
    private LocalDate learnDate;
}