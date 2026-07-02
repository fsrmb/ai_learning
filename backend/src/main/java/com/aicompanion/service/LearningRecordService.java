package com.aicompanion.service;

import com.aicompanion.model.entity.LearningRecord;
import com.aicompanion.model.vo.PageResult;

import java.util.List;

public interface LearningRecordService {

    List<LearningRecord> searchRecords(String userName, String courseType);

    PageResult<LearningRecord> searchRecordsPage(String userName, String courseType, Integer page, Integer size);

    LearningRecord getById(Long id);

    void createRecord(LearningRecord record);

    void updateRecord(Long id, LearningRecord record);

    void deleteRecord(Long id);

    List<LearningRecord> getByUserId(Long userId);
}