package com.aicompanion.controller;

import com.aicompanion.common.response.Result;
import com.aicompanion.model.dto.SkillNodeDTO;
import com.aicompanion.model.dto.SkillTreeDTO;
import com.aicompanion.model.vo.SkillNodeVO;
import com.aicompanion.model.vo.SkillTreeVO;
import com.aicompanion.service.SkillTreeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 技能树控制器
 */
@Tag(name = "技能树管理", description = "技能树和节点的增删改查接口")
@RestController
@RequestMapping("/api/skill-trees")
@RequiredArgsConstructor
public class SkillTreeController {
    
    private final SkillTreeService skillTreeService;
    
    /**
     * 创建技能树
     */
    @Operation(summary = "创建技能树", description = "创建一个新的技能树")
    @PostMapping
    public Result<Long> createSkillTree(@Valid @RequestBody SkillTreeDTO dto) {
        Long id = skillTreeService.createSkillTree(dto);
        return Result.success("创建成功", id);
    }
    
    /**
     * 更新技能树
     */
    @Operation(summary = "更新技能树", description = "更新指定ID的技能树信息")
    @PutMapping("/{id}")
    public Result<Void> updateSkillTree(@PathVariable Long id, @Valid @RequestBody SkillTreeDTO dto) {
        skillTreeService.updateSkillTree(id, dto);
        return Result.success("更新成功", null);
    }
    
    /**
     * 删除技能树
     */
    @Operation(summary = "删除技能树", description = "删除指定ID的技能树及其所有节点")
    @DeleteMapping("/{id}")
    public Result<Void> deleteSkillTree(@PathVariable Long id) {
        skillTreeService.deleteSkillTree(id);
        return Result.success("删除成功", null);
    }
    
    /**
     * 获取技能树详情（包含节点树）
     */
    @Operation(summary = "获取技能树详情", description = "获取技能树详细信息，包含完整的节点树形结构")
    @GetMapping("/{id}")
    public Result<SkillTreeVO> getSkillTreeDetail(@PathVariable Long id) {
        SkillTreeVO vo = skillTreeService.getSkillTreeDetail(id);
        return Result.success(vo);
    }
    
    /**
     * 获取技能树列表
     */
    @Operation(summary = "获取技能树列表", description = "获取技能树列表，可按分类筛选")
    @GetMapping
    public Result<List<SkillTreeVO>> listSkillTrees(
            @Parameter(description = "分类筛选", required = false)
            @RequestParam(required = false) String category) {
        List<SkillTreeVO> list = skillTreeService.listSkillTrees(category);
        return Result.success(list);
    }

    /**
     * 获取技能树分类列表
     */
    @Operation(summary = "获取技能树分类列表", description = "获取所有技能树的分类，用于前端下拉框")
    @GetMapping("/categories")
    public Result<List<String>> getSkillCategories() {
        List<String> categories = skillTreeService.getSkillCategories();
        return Result.success(categories);
    }
    
    /**
     * 创建技能节点
     */
    @Operation(summary = "创建技能节点", description = "在指定技能树下创建新的技能节点")
    @PostMapping("/nodes")
    public Result<Long> createSkillNode(@Valid @RequestBody SkillNodeDTO dto) {
        Long id = skillTreeService.createSkillNode(dto);
        return Result.success("创建成功", id);
    }
    
    /**
     * 更新技能节点
     */
    @Operation(summary = "更新技能节点", description = "更新指定ID的技能节点信息")
    @PutMapping("/nodes/{id}")
    public Result<Void> updateSkillNode(@PathVariable Long id, @Valid @RequestBody SkillNodeDTO dto) {
        skillTreeService.updateSkillNode(id, dto);
        return Result.success("更新成功", null);
    }
    
    /**
     * 删除技能节点
     */
    @Operation(summary = "删除技能节点", description = "删除指定ID的技能节点及其所有子节点")
    @DeleteMapping("/nodes/{id}")
    public Result<Void> deleteSkillNode(@PathVariable Long id) {
        skillTreeService.deleteSkillNode(id);
        return Result.success("删除成功", null);
    }
    
    /**
     * 获取技能树的节点树形结构
     */
    @Operation(summary = "获取节点树形结构", description = "获取指定技能树的完整节点树形结构")
    @GetMapping("/{treeId}/nodes")
    public Result<List<SkillNodeVO>> getSkillNodeTree(@PathVariable Long treeId) {
        List<SkillNodeVO> tree = skillTreeService.getSkillNodeTree(treeId);
        return Result.success(tree);
    }
}
