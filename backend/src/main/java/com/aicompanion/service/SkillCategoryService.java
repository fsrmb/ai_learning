package com.aicompanion.service;

import com.aicompanion.model.dto.SkillCategoryDTO;
import com.aicompanion.model.vo.SkillCategoryVO;

import java.util.List;

public interface SkillCategoryService {

    SkillCategoryVO getCategoryById(Long id);

    SkillCategoryVO getCategoryByCode(String code);

    List<SkillCategoryVO> getAllCategories();

    List<SkillCategoryVO> getActiveCategories();

    Long createCategory(SkillCategoryDTO dto);

    void updateCategory(Long id, SkillCategoryDTO dto);

    void deleteCategory(Long id);
}