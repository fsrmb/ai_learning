package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

/**
 * 技能节点实体类
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("skill_node")
public class SkillNode extends BaseEntity {
    
    /**
     * 技能树ID
     */
    @TableField("tree_id")
    private Long treeId;
    
    /**
     * 父节点ID（0表示根节点）
     */
    @TableField("parent_id")
    private Long parentId;
    
    /**
     * 节点名称
     */
    @TableField("name")
    private String name;
    
    /**
     * 节点描述
     */
    @TableField("description")
    private String description;
    
    /**
     * 节点类型：SKILL(技能点)、CHECKPOINT(检查点)、REWARD(奖励)
     */
    @TableField("node_type")
    private String nodeType;
    
    /**
     * 所需经验值
     */
    @TableField("required_exp")
    private Integer requiredExp;
    
    /**
     * 解锁条件描述
     */
    @TableField("unlock_condition")
    private String unlockCondition;
    
    /**
     * 奖励内容（JSON格式）
     */
    @TableField("reward")
    private String reward;
    
    /**
     * 图标
     */
    @TableField("icon")
    private String icon;
    
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
