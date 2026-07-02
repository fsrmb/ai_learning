package com.aicompanion.model.vo;

import lombok.Data;

@Data
public class SkillCategoryVO {

    private Long id;

    private String name;

    private String code;

    private String description;

    private String icon;

    private Integer sortOrder;

    private Integer status;
}