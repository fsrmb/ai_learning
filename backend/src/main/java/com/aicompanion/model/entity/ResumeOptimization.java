package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.time.LocalDateTime;

/**
 * 简历优化记录实体类
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("resume_optimization")
public class ResumeOptimization extends BaseEntity {

    /**
     * 用户ID
     */
    @TableField("user_id")
    private Long userId;

    /**
     * 原始文件名
     */
    @TableField("original_file_name")
    private String originalFileName;

    /**
     * 原始文件URL
     */
    @TableField("original_file_url")
    private String originalFileUrl;

    /**
     * 优化后文件URL
     */
    @TableField("optimized_file_url")
    private String optimizedFileUrl;

    /**
     * 原始简历评分0-100
     */
    @TableField("original_score")
    private Integer originalScore;

    /**
     * 优化后评分0-100
     */
    @TableField("optimized_score")
    private Integer optimizedScore;

    /**
     * 优化类型：OPTIMIZE/REWRITE
     */
    @TableField("optimization_type")
    private String optimizationType;

    /**
     * 优化建议/修改说明
     */
    @TableField("suggestions")
    private String suggestions;

    /**
     * 优化后的简历内容（文本版）
     */
    @TableField("optimized_content")
    private String optimizedContent;

    /**
     * 状态：0处理中/1完成/2失败
     */
    @TableField("status")
    private Integer status;
}