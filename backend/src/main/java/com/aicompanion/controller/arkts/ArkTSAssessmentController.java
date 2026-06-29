package com.aicompanion.controller.arkts;

import com.aicompanion.common.response.Result;
import com.aicompanion.model.dto.assessment.StartAssessmentDTO;
import com.aicompanion.model.dto.assessment.SubmitAnswerDTO;
import com.aicompanion.model.vo.arkts.AssessmentResultVO;
import com.aicompanion.model.vo.arkts.DifficultyOptionVO;
import com.aicompanion.service.arkts.ArkTSAssessmentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Tag(name = "移动端技能评估", description = "ArkTS 移动端技能评估相关接口")
@RestController
@RequestMapping("/api/arkts/assessments")
@RequiredArgsConstructor
public class ArkTSAssessmentController {

    private final ArkTSAssessmentService arkTSAssessmentService;

    @Operation(summary = "开始评估", description = "创建评估记录，获取题目")
    @PostMapping("/start")
    public Result<Map<String, Object>> startAssessment(
            @Parameter(description = "开始评估请求")
            @Valid @RequestBody StartAssessmentDTO dto,
            @Parameter(description = "用户ID")
            @RequestHeader("X-User-Id") Long userId) {
        Map<String, Object> result = arkTSAssessmentService.startAssessment(dto, userId);
        return Result.success(result);
    }

    @Operation(summary = "提交答案", description = "提交答案，计算得分，更新熟练度")
    @PostMapping("/{id}/submit")
    public Result<AssessmentResultVO> submitAnswer(
            @Parameter(description = "评估记录ID")
            @PathVariable Long id,
            @Parameter(description = "提交答案请求")
            @Valid @RequestBody SubmitAnswerDTO dto,
            @Parameter(description = "用户ID")
            @RequestHeader("X-User-Id") Long userId) {
        AssessmentResultVO result = arkTSAssessmentService.submitAnswer(id, dto, userId);
        return Result.success(result);
    }

    @Operation(summary = "获取难度选项", description = "获取指定技能节点的难度选项列表")
    @GetMapping("/difficulty-options/{nodeId}")
    public Result<List<DifficultyOptionVO>> getDifficultyOptions(
            @Parameter(description = "技能节点ID")
            @PathVariable Long nodeId,
            @Parameter(description = "用户ID")
            @RequestHeader("X-User-Id") Long userId) {
        List<DifficultyOptionVO> options = arkTSAssessmentService.getDifficultyOptions(nodeId, userId);
        return Result.success(options);
    }
}