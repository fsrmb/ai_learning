package com.aicompanion.controller;

import com.aicompanion.common.response.Result;
import com.aicompanion.model.vo.SkillAssessmentVO;
import com.aicompanion.service.SkillAssessmentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/skill-assessments")
@RequiredArgsConstructor
@Tag(name = "技能评估管理", description = "技能评估相关接口")
public class SkillAssessmentController {

    private final SkillAssessmentService skillAssessmentService;

    @Operation(summary = "获取所有评估记录", description = "获取所有用户的技能评估记录")
    @GetMapping
    public Result<List<SkillAssessmentVO>> getAllAssessments() {
        List<SkillAssessmentVO> list = skillAssessmentService.getAllAssessments();
        return Result.success(list);
    }

    @Operation(summary = "获取用户评估记录", description = "获取指定用户的技能评估记录")
    @GetMapping("/user/{userId}")
    public Result<List<SkillAssessmentVO>> getUserAssessments(
            @Parameter(description = "用户ID", required = true)
            @PathVariable Long userId) {
        List<SkillAssessmentVO> list = skillAssessmentService.getUserAssessments(userId);
        return Result.success(list);
    }

    @Operation(summary = "获取技能节点评估记录", description = "获取指定技能节点的评估记录")
    @GetMapping("/node/{nodeId}")
    public Result<List<SkillAssessmentVO>> getAssessmentByNode(
            @Parameter(description = "技能节点ID", required = true)
            @PathVariable Long nodeId) {
        List<SkillAssessmentVO> list = skillAssessmentService.getAssessmentByNode(nodeId);
        return Result.success(list);
    }
}