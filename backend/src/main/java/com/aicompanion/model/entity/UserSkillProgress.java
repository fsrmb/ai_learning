package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 用户技能进度实体类
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("user_skill_progress")
public class UserSkillProgress extends BaseEntity {
    
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
     * 状态：0未解锁/1已解锁/2已完成
     */
    @TableField("status")
    private Integer status;
    
    /**
     * 当前经验值
     */
    @TableField("current_exp")
    private Integer currentExp;
    
    /**
     * 解锁时间
     */
    @TableField("unlocked_at")
    private LocalDateTime unlockedAt;
    
    /**
     * 完成时间
     */
    @TableField("completed_at")
    private LocalDateTime completedAt;
}