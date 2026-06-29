package com.aicompanion.mapper;

import com.aicompanion.model.entity.SkillQuestion;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface SkillQuestionMapper extends BaseMapper<SkillQuestion> {

    @Select("SELECT * FROM skill_question WHERE node_id = #{nodeId} AND difficulty = #{difficulty} AND deleted = 0 ORDER BY RAND() LIMIT #{limit}")
    List<SkillQuestion> selectRandomByNodeAndDifficulty(@Param("nodeId") Long nodeId, @Param("difficulty") Integer difficulty, @Param("limit") Integer limit);

    @Select("SELECT COUNT(*) FROM skill_question WHERE node_id = #{nodeId} AND difficulty = #{difficulty} AND deleted = 0")
    Integer countByNodeAndDifficulty(@Param("nodeId") Long nodeId, @Param("difficulty") Integer difficulty);
}