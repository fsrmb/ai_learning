package com.aicompanion.model.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 技能树创建/更新 DTO
 */
@Data
public class SkillTreeDTO {
    
    private Long id;
    
    @NotBlank(message = "技能树名称不能为空")
    private String name;
    
    private String description;
    
    private String icon;
    
    @NotBlank(message = "分类不能为空")
    private String category;
    
    @NotNull(message = "难度等级不能为空")
    private Integer difficultyLevel;
    
    private Integer status;
    
    private Integer sortOrder;
}
