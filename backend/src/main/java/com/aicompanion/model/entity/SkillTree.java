package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 技能树实体类
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("skill_tree")
public class SkillTree extends BaseEntity {
    
    /**
     * 技能树名称
     */
    @TableField("name")
    private String name;
    
    /**
     * 技能树描述
     */
    @TableField("description")
    private String description;
    
    /**
     * 图标
     */
    @TableField("icon")
    private String icon;
    
    /**
     * 分类（如：编程、设计、语言等）
     */
    @TableField("category")
    private String category;
    
    /**
     * 难度等级（1-5）
     */
    @TableField("difficulty_level")
    private Integer difficultyLevel;
    
    /**
     * 状态：0禁用/1正常
     */
    @TableField("status")
    private Integer status;
    
    /**
     * 排序
     */
    @TableField("sort_order")
    private Integer sortOrder;
}
