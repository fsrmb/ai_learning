package com.aicompanion.model.vo.arkts;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 移动端技能节点进度 VO
 * 包含用户学习状态
 */
@Data
public class SkillNodeProgressVO {
    
    private Long id;
    private Long treeId;
    private Long parentId;
    private String name;
    private String description;
    private String nodeType;
    private Integer requiredExp;
    private String unlockCondition;
    private String reward;
    private String icon;
    
    /**
     * 用户状态：LOCKED(未解锁)/UNLOCKED(已解锁)/COMPLETED(已完成)
     */
    private String userStatus;
    
    /**
     * 当前经验值
     */
    private Integer currentExp;
    
    /**
     * 解锁时间
     */
    private LocalDateTime unlockedAt;
    
    /**
     * 完成时间
     */
    private LocalDateTime completedAt;
    
    private List<SkillNodeProgressVO> children;
}