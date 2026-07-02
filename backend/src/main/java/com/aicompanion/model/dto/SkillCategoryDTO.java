package com.aicompanion.model.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SkillCategoryDTO {

    private Long id;

    @NotBlank(message = "分类名称不能为空")
    private String name;

    @NotBlank(message = "分类编码不能为空")
    private String code;

    private String description;

    private String icon;

    private Integer sortOrder;

    private Integer status;
}