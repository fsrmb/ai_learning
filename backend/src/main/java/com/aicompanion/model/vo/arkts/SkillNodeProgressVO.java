package com.aicompanion.model.vo.arkts;

import lombok.Data;

import java.math.BigDecimal;
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
    
    private String userStatus;
    private BigDecimal bestScore;
    private BigDecimal latestScore;
    private Integer attemptCount;
    private Integer expPoints;
    
    private List<SkillNodeProgressVO> children;
}