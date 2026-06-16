package com.aicompanion.model.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 技能节点创建/更新 DTO
 */
@Data
public class SkillNodeDTO {
    
    private Long id;
    
    @NotNull(message = "技能树ID不能为空")
    private Long treeId;
    
    private Long parentId;
    
    @NotBlank(message = "节点名称不能为空")
    private String name;
    
    private String description;
    
    @NotBlank(message = "节点类型不能为空")
    private String nodeType;
    
    private Integer requiredExp;
    
    private String unlockCondition;
    
    private String reward;
    
    private String icon;
    
    private Integer status;
    
    private Integer sortOrder;
}
