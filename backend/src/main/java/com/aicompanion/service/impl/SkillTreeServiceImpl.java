package com.aicompanion.service.impl;

import com.aicompanion.common.exception.BusinessException;
import com.aicompanion.mapper.SkillNodeMapper;
import com.aicompanion.mapper.SkillTreeMapper;
import com.aicompanion.model.dto.SkillNodeDTO;
import com.aicompanion.model.dto.SkillTreeDTO;
import com.aicompanion.model.entity.SkillNode;
import com.aicompanion.model.entity.SkillTree;
import com.aicompanion.model.vo.SkillNodeVO;
import com.aicompanion.model.vo.SkillTreeVO;
import com.aicompanion.service.SkillTreeService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 技能树服务实现类
 * 管理后台使用，不含用户进度计算
 */
@Service
@RequiredArgsConstructor
public class SkillTreeServiceImpl implements SkillTreeService {
    
    private final SkillTreeMapper skillTreeMapper;
    private final SkillNodeMapper skillNodeMapper;
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createSkillTree(SkillTreeDTO dto) {
        SkillTree skillTree = new SkillTree();
        BeanUtils.copyProperties(dto, skillTree);
        if (skillTree.getStatus() == null) {
            skillTree.setStatus(1);
        }
        skillTreeMapper.insert(skillTree);
        return skillTree.getId();
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateSkillTree(Long id, SkillTreeDTO dto) {
        SkillTree skillTree = skillTreeMapper.selectById(id);
        if (skillTree == null) {
            throw new BusinessException("技能树不存在");
        }
        BeanUtils.copyProperties(dto, skillTree);
        skillTree.setId(id);
        skillTreeMapper.updateById(skillTree);
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteSkillTree(Long id) {
        SkillTree skillTree = skillTreeMapper.selectById(id);
        if (skillTree == null) {
            throw new BusinessException("技能树不存在");
        }
        // 删除关联的技能节点
        skillNodeMapper.delete(new LambdaQueryWrapper<SkillNode>()
                .eq(SkillNode::getTreeId, id));
        skillTreeMapper.deleteById(id);
    }
    
    @Override
    public SkillTreeVO getSkillTreeDetail(Long id) {
        SkillTree skillTree = skillTreeMapper.selectById(id);
        if (skillTree == null) {
            throw new BusinessException("技能树不存在");
        }
        
        SkillTreeVO vo = new SkillTreeVO();
        BeanUtils.copyProperties(skillTree, vo);
        
        // 获取节点树
        List<SkillNodeVO> nodeTree = getSkillNodeTree(id);
        vo.setNodes(nodeTree);
        
        return vo;
    }
    
    @Override
    public List<SkillTreeVO> listSkillTrees(String category) {
        LambdaQueryWrapper<SkillTree> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SkillTree::getStatus, 1);
        if (category != null && !category.isEmpty()) {
            wrapper.eq(SkillTree::getCategory, category);
        }
        
        List<SkillTree> skillTrees = skillTreeMapper.selectList(wrapper);
        return skillTrees.stream().map(tree -> {
            SkillTreeVO vo = new SkillTreeVO();
            BeanUtils.copyProperties(tree, vo);
            return vo;
        }).collect(Collectors.toList());
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long createSkillNode(SkillNodeDTO dto) {
        // 验证技能树是否存在
        SkillTree skillTree = skillTreeMapper.selectById(dto.getTreeId());
        if (skillTree == null) {
            throw new BusinessException("技能树不存在");
        }
        
        SkillNode skillNode = new SkillNode();
        BeanUtils.copyProperties(dto, skillNode);
        if (skillNode.getParentId() == null) {
            skillNode.setParentId(0L);
        }
        if (skillNode.getStatus() == null) {
            skillNode.setStatus(1);
        }
        skillNodeMapper.insert(skillNode);
        return skillNode.getId();
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateSkillNode(Long id, SkillNodeDTO dto) {
        SkillNode skillNode = skillNodeMapper.selectById(id);
        if (skillNode == null) {
            throw new BusinessException("技能节点不存在");
        }
        BeanUtils.copyProperties(dto, skillNode);
        skillNode.setId(id);
        skillNodeMapper.updateById(skillNode);
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteSkillNode(Long id) {
        SkillNode skillNode = skillNodeMapper.selectById(id);
        if (skillNode == null) {
            throw new BusinessException("技能节点不存在");
        }
        // 递归删除子节点
        deleteChildNodes(id);
        skillNodeMapper.deleteById(id);
    }
    
    @Override
    public List<SkillNodeVO> getSkillNodeTree(Long treeId) {
        // 获取该技能树的所有节点
        List<SkillNode> allNodes = skillNodeMapper.selectList(
                new LambdaQueryWrapper<SkillNode>()
                        .eq(SkillNode::getTreeId, treeId)
                        .eq(SkillNode::getStatus, 1)
        );
        
        // 转换为 VO
        List<SkillNodeVO> allNodeVOs = allNodes.stream().map(node -> {
            SkillNodeVO vo = new SkillNodeVO();
            BeanUtils.copyProperties(node, vo);
            vo.setChildren(new ArrayList<>());
            return vo;
        }).collect(Collectors.toList());
        
        // 构建树形结构
        return buildTree(allNodeVOs, 0L);
    }
    
    /**
     * 递归删除子节点
     */
    private void deleteChildNodes(Long parentId) {
        List<SkillNode> childNodes = skillNodeMapper.selectList(
                new LambdaQueryWrapper<SkillNode>()
                        .eq(SkillNode::getParentId, parentId)
        );
        for (SkillNode child : childNodes) {
            deleteChildNodes(child.getId());
            skillNodeMapper.deleteById(child.getId());
        }
    }
    
    /**
     * 构建树形结构
     */
    private List<SkillNodeVO> buildTree(List<SkillNodeVO> allNodes, Long parentId) {
        return allNodes.stream()
                .filter(node -> node.getParentId().equals(parentId))
                .peek(node -> {
                    List<SkillNodeVO> children = buildTree(allNodes, node.getId());
                    node.setChildren(children);
                })
                .collect(Collectors.toList());
    }

    @Override
    public List<String> getSkillCategories() {
        List<SkillTree> skillTrees = skillTreeMapper.selectList(new LambdaQueryWrapper<SkillTree>()
                .eq(SkillTree::getStatus, 1)
                .eq(SkillTree::getDeleted, 0));
        return skillTrees.stream()
                .map(SkillTree::getCategory)
                .distinct()
                .collect(Collectors.toList());
    }
}