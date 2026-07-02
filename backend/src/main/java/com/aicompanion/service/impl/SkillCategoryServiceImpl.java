package com.aicompanion.service.impl;

import com.aicompanion.common.exception.BusinessException;
import com.aicompanion.mapper.SkillCategoryMapper;
import com.aicompanion.model.dto.SkillCategoryDTO;
import com.aicompanion.model.entity.SkillCategory;
import com.aicompanion.model.vo.SkillCategoryVO;
import com.aicompanion.service.SkillCategoryService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SkillCategoryServiceImpl implements SkillCategoryService {

    private final SkillCategoryMapper skillCategoryMapper;

    @Override
    public SkillCategoryVO getCategoryById(Long id) {
        SkillCategory category = skillCategoryMapper.selectById(id);
        if (category == null) {
            throw new BusinessException("分类不存在");
        }
        return convertToVO(category);
    }

    @Override
    public SkillCategoryVO getCategoryByCode(String code) {
        SkillCategory category = skillCategoryMapper.selectOne(
                new LambdaQueryWrapper<SkillCategory>()
                        .eq(SkillCategory::getCode, code)
                        .eq(SkillCategory::getDeleted, 0));
        if (category == null) {
            throw new BusinessException("分类不存在");
        }
        return convertToVO(category);
    }

    @Override
    public List<SkillCategoryVO> getAllCategories() {
        List<SkillCategory> categories = skillCategoryMapper.selectList(
                new LambdaQueryWrapper<SkillCategory>()
                        .eq(SkillCategory::getDeleted, 0)
                        .orderByAsc(SkillCategory::getSortOrder));
        return categories.stream().map(this::convertToVO).collect(Collectors.toList());
    }

    @Override
    public List<SkillCategoryVO> getActiveCategories() {
        List<SkillCategory> categories = skillCategoryMapper.selectList(
                new LambdaQueryWrapper<SkillCategory>()
                        .eq(SkillCategory::getStatus, 1)
                        .eq(SkillCategory::getDeleted, 0)
                        .orderByAsc(SkillCategory::getSortOrder));
        return categories.stream().map(this::convertToVO).collect(Collectors.toList());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createCategory(SkillCategoryDTO dto) {
        SkillCategory existing = skillCategoryMapper.selectOne(
                new LambdaQueryWrapper<SkillCategory>()
                        .eq(SkillCategory::getCode, dto.getCode())
                        .eq(SkillCategory::getDeleted, 0));
        if (existing != null) {
            throw new BusinessException("分类编码已存在");
        }

        SkillCategory category = new SkillCategory();
        BeanUtils.copyProperties(dto, category);
        if (category.getStatus() == null) {
            category.setStatus(1);
        }
        if (category.getSortOrder() == null) {
            category.setSortOrder(0);
        }
        skillCategoryMapper.insert(category);
        return category.getId();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateCategory(Long id, SkillCategoryDTO dto) {
        SkillCategory category = skillCategoryMapper.selectById(id);
        if (category == null) {
            throw new BusinessException("分类不存在");
        }

        if (!category.getCode().equals(dto.getCode())) {
            SkillCategory existing = skillCategoryMapper.selectOne(
                    new LambdaQueryWrapper<SkillCategory>()
                            .eq(SkillCategory::getCode, dto.getCode())
                            .eq(SkillCategory::getDeleted, 0)
                            .ne(SkillCategory::getId, id));
            if (existing != null) {
                throw new BusinessException("分类编码已存在");
            }
        }

        BeanUtils.copyProperties(dto, category);
        skillCategoryMapper.updateById(category);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteCategory(Long id) {
        SkillCategory category = skillCategoryMapper.selectById(id);
        if (category == null) {
            throw new BusinessException("分类不存在");
        }
        category.setDeleted(1);
        skillCategoryMapper.updateById(category);
    }

    private SkillCategoryVO convertToVO(SkillCategory entity) {
        SkillCategoryVO vo = new SkillCategoryVO();
        BeanUtils.copyProperties(entity, vo);
        return vo;
    }
}