package com.aicompanion.model.vo;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 技能树 VO
 */
@Data
public class SkillTreeVO {
    
    private Long id;
    private String name;
    private String description;
    private String icon;
    private String category;
    private Integer difficultyLevel;
    private Integer status;
    private Integer sortOrder;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    
    /**
     * 节点列表（树形结构）
     */
    private List<SkillNodeVO> nodes;
}
