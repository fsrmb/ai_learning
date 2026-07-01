package com.aicompanion.controller;

import com.aicompanion.common.response.Result;
import com.aicompanion.model.entity.LearningRecord;
import com.aicompanion.service.LearningRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/learning-records")
@RequiredArgsConstructor
public class LearningRecordController {

    private final LearningRecordService learningRecordService;

    @GetMapping
    public Result<List<LearningRecord>> searchRecords(
            @RequestParam(required = false) String userName,
            @RequestParam(required = false) String courseType) {
        List<LearningRecord> list = learningRecordService.searchRecords(userName, courseType);
        return Result.success(list);
    }

    @GetMapping("/{id}")
    public Result<LearningRecord> getRecord(@PathVariable Long id) {
        LearningRecord record = learningRecordService.getById(id);
        return Result.success(record);
    }

    @PostMapping
    public Result<Void> createRecord(@RequestBody LearningRecord record) {
        learningRecordService.createRecord(record);
        return Result.success("创建成功", null);
    }

    @PutMapping("/{id}")
    public Result<Void> updateRecord(@PathVariable Long id, @RequestBody LearningRecord record) {
        learningRecordService.updateRecord(id, record);
        return Result.success("更新成功", null);
    }

    @DeleteMapping("/{id}")
    public Result<Void> deleteRecord(@PathVariable Long id) {
        learningRecordService.deleteRecord(id);
        return Result.success("删除成功", null);
    }

    @GetMapping("/user/{userId}")
    public Result<List<LearningRecord>> getByUserId(@PathVariable Long userId) {
        List<LearningRecord> list = learningRecordService.getByUserId(userId);
        return Result.success(list);
    }
}