package com.aicompanion.model.vo;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 技能节点 VO
 */
@Data
public class SkillNodeVO {
    
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
    private Integer status;
    private Integer sortOrder;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    
    /**
     * 子节点列表
     */
    private List<SkillNodeVO> children;
}
