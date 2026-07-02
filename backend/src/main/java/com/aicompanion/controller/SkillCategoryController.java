package com.aicompanion.controller;

import com.aicompanion.common.response.Result;
import com.aicompanion.model.dto.SkillCategoryDTO;
import com.aicompanion.model.vo.SkillCategoryVO;
import com.aicompanion.service.SkillCategoryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "技能分类管理", description = "技能分类的增删改查接口")
@RestController
@RequestMapping("/api/skill-categories")
@RequiredArgsConstructor
public class SkillCategoryController {

    private final SkillCategoryService skillCategoryService;

    @Operation(summary = "获取分类列表", description = "获取所有分类（不分状态）")
    @GetMapping
    public Result<List<SkillCategoryVO>> getAllCategories() {
        List<SkillCategoryVO> list = skillCategoryService.getAllCategories();
        return Result.success(list);
    }

    @Operation(summary = "获取可用分类列表", description = "获取状态为正常的分类，用于前端下拉框")
    @GetMapping("/active")
    public Result<List<SkillCategoryVO>> getActiveCategories() {
        List<SkillCategoryVO> list = skillCategoryService.getActiveCategories();
        return Result.success(list);
    }

    @Operation(summary = "获取分类详情", description = "根据ID获取分类详情")
    @GetMapping("/{id}")
    public Result<SkillCategoryVO> getCategoryById(
            @Parameter(description = "分类ID", required = true)
            @PathVariable Long id) {
        SkillCategoryVO vo = skillCategoryService.getCategoryById(id);
        return Result.success(vo);
    }

    @Operation(summary = "创建分类", description = "创建一个新的技能分类")
    @PostMapping
    public Result<Long> createCategory(@Valid @RequestBody SkillCategoryDTO dto) {
        Long id = skillCategoryService.createCategory(dto);
        return Result.success("创建成功", id);
    }

    @Operation(summary = "更新分类", description = "更新指定ID的分类信息")
    @PutMapping("/{id}")
    public Result<Void> updateCategory(
            @Parameter(description = "分类ID", required = true)
            @PathVariable Long id,
            @Valid @RequestBody SkillCategoryDTO dto) {
        skillCategoryService.updateCategory(id, dto);
        return Result.success("更新成功", null);
    }

    @Operation(summary = "删除分类", description = "删除指定ID的分类")
    @DeleteMapping("/{id}")
    public Result<Void> deleteCategory(
            @Parameter(description = "分类ID", required = true)
            @PathVariable Long id) {
        skillCategoryService.deleteCategory(id);
        return Result.success("删除成功", null);
    }
}