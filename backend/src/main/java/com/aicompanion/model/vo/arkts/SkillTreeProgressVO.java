package com.aicompanion.model.vo.arkts;

import lombok.Data;

import java.util.List;

/**
 * 移动端技能树进度 VO
 * 包含用户学习进度信息
 */
@Data
public class SkillTreeProgressVO {
    
    private Long id;
    private String name;
    private String description;
    private String icon;
    private String category;
    private Integer difficultyLevel;
    
    private Integer nodeCount;
    private Integer completedCount;
    private Double progress;
    
    private List<SkillNodeProgressVO> nodes;
}