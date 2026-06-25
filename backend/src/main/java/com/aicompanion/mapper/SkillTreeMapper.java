package com.aicompanion.mapper;

import com.aicompanion.model.entity.SkillTree;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/**
 * 技能树 Mapper
 */
//声明即用，自带单表操作方法
@Mapper
public interface SkillTreeMapper extends BaseMapper<SkillTree> {
}
