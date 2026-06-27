package com.aicompanion.controller.arkts;

import com.aicompanion.common.response.Result;
import com.aicompanion.model.vo.arkts.SkillNodeProgressVO;
import com.aicompanion.model.vo.arkts.SkillTreeProgressVO;
import com.aicompanion.service.arkts.ArkTSSkillTreeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 移动端技能树控制器
 * 专门为 ArkTS 移动端应用提供 API 接口
 * API 路径前缀：/api/arkts/skill-trees
 */
@Tag(name = "移动端技能树", description = "ArkTS 移动端技能树相关接口")
@RestController
@RequestMapping("/api/arkts/skill-trees")
@RequiredArgsConstructor
public class ArkTSSkillTreeController {
    
    private final ArkTSSkillTreeService arkTSSkillTreeService;
    
    @Operation(summary = "获取技能树列表", description = "获取技能树列表，包含用户学习进度")
    @GetMapping
    public Result<List<SkillTreeProgressVO>> listSkillTrees(
            @Parameter(description = "分类筛选", required = false)
            @RequestParam(required = false) String category) {
        List<SkillTreeProgressVO> list = arkTSSkillTreeService.listSkillTreesWithProgress(category);
        return Result.success(list);
    }
    
    @Operation(summary = "获取技能树详情", description = "获取技能树详情，包含节点树和用户学习进度")
    @GetMapping("/{treeId}")
    public Result<SkillTreeProgressVO> getSkillTreeDetail(
            @Parameter(description = "技能树ID")
            @PathVariable Long treeId) {
        SkillTreeProgressVO vo = arkTSSkillTreeService.getSkillTreeDetailWithProgress(treeId);
        return Result.success(vo);
    }
    
    @Operation(summary = "获取技能节点树", description = "获取指定技能树的节点树，包含用户学习状态")
    @GetMapping("/{treeId}/nodes")
    public Result<List<SkillNodeProgressVO>> getSkillNodeTree(
            @Parameter(description = "技能树ID")
            @PathVariable Long treeId) {
        List<SkillNodeProgressVO> tree = arkTSSkillTreeService.getSkillNodeTreeWithProgress(treeId);
        return Result.success(tree);
    }
}