package com.aicompanion.service.impl;

import com.aicompanion.common.exception.BusinessException;
import com.aicompanion.mapper.LearningRecordMapper;
import com.aicompanion.model.entity.LearningRecord;
import com.aicompanion.service.LearningRecordService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class LearningRecordServiceImpl implements LearningRecordService {

    private final LearningRecordMapper learningRecordMapper;

    @Override
    public List<LearningRecord> searchRecords(String userName, String courseType) {
        return learningRecordMapper.searchRecords(userName, courseType);
    }

    @Override
    public LearningRecord getById(Long id) {
        LearningRecord record = learningRecordMapper.selectById(id);
        if (record == null) {
            throw new BusinessException("学习记录不存在");
        }
        return record;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void createRecord(LearningRecord record) {
        learningRecordMapper.insert(record);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateRecord(Long id, LearningRecord record) {
        LearningRecord existing = learningRecordMapper.selectById(id);
        if (existing == null) {
            throw new BusinessException("学习记录不存在");
        }
        record.setId(id);
        learningRecordMapper.updateById(record);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteRecord(Long id) {
        LearningRecord record = learningRecordMapper.selectById(id);
        if (record == null) {
            throw new BusinessException("学习记录不存在");
        }
        learningRecordMapper.deleteById(id);
    }

    @Override
    public List<LearningRecord> getByUserId(Long userId) {
        LambdaQueryWrapper<LearningRecord> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(LearningRecord::getUserId, userId);
        queryWrapper.orderByDesc(LearningRecord::getLearnDate);
        return learningRecordMapper.selectList(queryWrapper);
    }
}