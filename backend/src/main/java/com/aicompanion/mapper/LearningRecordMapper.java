package com.aicompanion.mapper;

import com.aicompanion.model.entity.LearningRecord;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface LearningRecordMapper extends BaseMapper<LearningRecord> {

    List<LearningRecord> searchRecords(@Param("userName") String userName, @Param("courseType") String courseType);

    Long searchRecordsCount(@Param("userName") String userName, @Param("courseType") String courseType);

    List<LearningRecord> searchRecordsPage(@Param("userName") String userName, @Param("courseType") String courseType, @Param("offset") Integer offset, @Param("size") Integer size);
}