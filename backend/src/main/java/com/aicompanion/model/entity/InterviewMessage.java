package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 面试消息实体类
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("interview_message")
public class InterviewMessage extends BaseEntity {

    /**
     * 所属面试会话ID
     */
    @TableField("session_id")
    private Long sessionId;

    /**
     * 角色：INTERVIEWER/CANDIDATE
     */
    @TableField("role")
    private String role;

    /**
     * 内容（问题或回答）
     */
    @TableField("content")
    private String content;

    /**
     * 题目类型：TECH/BEHAVIOR/ALGORITHM
     */
    @TableField("question_type")
    private String questionType;

    /**
     * 该题得分（仅回答消息）
     */
    @TableField("score")
    private Integer score;

    /**
     * 该题点评
     */
    @TableField("comment")
    private String comment;
}