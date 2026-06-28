package com.aicompanion.service.impl.arkts;

import com.aicompanion.common.util.SecurityUtil;
import com.aicompanion.mapper.SkillNodeMapper;
import com.aicompanion.mapper.SkillTreeMapper;
import com.aicompanion.mapper.UserSkillProgressMapper;
import com.aicompanion.model.entity.SkillNode;
import com.aicompanion.model.entity.SkillTree;
import com.aicompanion.model.entity.UserSkillProgress;
import com.aicompanion.model.vo.arkts.SkillNodeProgressVO;
import com.aicompanion.model.vo.arkts.SkillTreeProgressVO;
import com.aicompanion.service.arkts.ArkTSSkillTreeService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 移动端技能树服务实现类
 * 专门处理移动端技能树进度相关逻辑
 */
@Service
@RequiredArgsConstructor
public class ArkTSSkillTreeServiceImpl implements ArkTSSkillTreeService {
    
    private final SkillTreeMapper skillTreeMapper;
    private final SkillNodeMapper skillNodeMapper;
    private final UserSkillProgressMapper userSkillProgressMapper;
    
    @Override
    public List<SkillTreeProgressVO> listSkillTreesWithProgress(String category) {
        LambdaQueryWrapper<SkillTree> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SkillTree::getStatus, 1);
        if (category != null && !category.isEmpty()) {
            wrapper.eq(SkillTree::getCategory, category);
        }
        
        List<SkillTree> skillTrees = skillTreeMapper.selectList(wrapper);
        List<SkillTreeProgressVO> voList = skillTrees.stream()
                .map(this::convertToTreeVO)
                .collect(Collectors.toList());
        
        Long userId = getCurrentUserId();
        if (userId != null) {
            calculateProgress(voList, userId);
        }
        
        return voList;
    }
    
    @Override
    public SkillTreeProgressVO getSkillTreeDetailWithProgress(Long treeId) {
        SkillTree skillTree = skillTreeMapper.selectById(treeId);
        if (skillTree == null) {
            return null;
        }
        
        SkillTreeProgressVO vo = convertToTreeVO(skillTree);
        
        Long userId = getCurrentUserId();
        if (userId != null) {
            List<SkillNodeProgressVO> nodes = getSkillNodeTreeWithProgress(treeId);
            vo.setNodes(nodes);
            calculateProgress(vo, userId);
        }
        
        return vo;
    }
    
    @Override
    public List<SkillNodeProgressVO> getSkillNodeTreeWithProgress(Long treeId) {
        LambdaQueryWrapper<SkillNode> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SkillNode::getTreeId, treeId);
        wrapper.eq(SkillNode::getStatus, 1);
        
        List<SkillNode> allNodes = skillNodeMapper.selectList(wrapper);
        
        Long userId = getCurrentUserId();
        // 使用 final Map 解决 lambda 变量问题
        final Map<Long, UserSkillProgress> progressMap = new HashMap<>();
        if (userId != null) {
            LambdaQueryWrapper<UserSkillProgress> progressQuery = new LambdaQueryWrapper<>();
            progressQuery.eq(UserSkillProgress::getUserId, userId);
            List<UserSkillProgress> progressList = userSkillProgressMapper.selectList(progressQuery);
            for (UserSkillProgress p : progressList) {
                progressMap.put(p.getNodeId(), p);
            }
        }
        
        List<SkillNodeProgressVO> allNodeVOs = new ArrayList<>();
        for (SkillNode node : allNodes) {
            allNodeVOs.add(convertToNodeVO(node, progressMap));
        }
        
        return buildNodeTree(allNodeVOs, 0L);
    }
    
    private Long getCurrentUserId() {
        try {
            return SecurityUtil.getCurrentUserId();
        } catch (Exception e) {
            return null;
        }
    }
    
    private void calculateProgress(List<SkillTreeProgressVO> voList, Long userId) {
        LambdaQueryWrapper<UserSkillProgress> progressQuery = new LambdaQueryWrapper<>();
        progressQuery.eq(UserSkillProgress::getUserId, userId);
        List<UserSkillProgress> progressList = userSkillProgressMapper.selectList(progressQuery);
        
        Map<Long, Long> completedNodeCountMap = new HashMap<>();
        for (UserSkillProgress p : progressList) {
            if ("COMPLETED".equals(p.getStatus())) {
                SkillNode node = skillNodeMapper.selectById(p.getNodeId());
                if (node != null) {
                    Long treeId = node.getTreeId();
                    completedNodeCountMap.put(treeId, completedNodeCountMap.getOrDefault(treeId, 0L) + 1);
                }
            }
        }
        
        for (SkillTreeProgressVO vo : voList) {
            Integer totalCount = vo.getNodeCount();
            Long completedCount = completedNodeCountMap.getOrDefault(vo.getId(), 0L);
            vo.setCompletedCount(completedCount.intValue());
            if (totalCount != null && totalCount > 0) {
                vo.setProgress(Math.round(completedCount * 1000.0 / totalCount) / 10.0);
            } else {
                vo.setProgress(0.0);
            }
        }
    }
    
    private void calculateProgress(SkillTreeProgressVO vo, Long userId) {
        if (vo.getNodes() != null) {
            int totalCount = countAllNodes(vo.getNodes());
            int completedCount = countCompletedNodes(vo.getNodes());
            vo.setNodeCount(totalCount);
            vo.setCompletedCount(completedCount);
            if (totalCount > 0) {
                vo.setProgress(Math.round(completedCount * 1000.0 / totalCount) / 10.0);
            } else {
                vo.setProgress(0.0);
            }
        }
    }
    
    private int countAllNodes(List<SkillNodeProgressVO> nodes) {
        int count = 0;
        for (SkillNodeProgressVO node : nodes) {
            count++;
            if (node.getChildren() != null) {
                count += countAllNodes(node.getChildren());
            }
        }
        return count;
    }
    
    private int countCompletedNodes(List<SkillNodeProgressVO> nodes) {
        int count = 0;
        for (SkillNodeProgressVO node : nodes) {
            if ("COMPLETED".equals(node.getUserStatus())) {
                count++;
            }
            if (node.getChildren() != null) {
                count += countCompletedNodes(node.getChildren());
            }
        }
        return count;
    }
    
    private SkillTreeProgressVO convertToTreeVO(SkillTree entity) {
        SkillTreeProgressVO vo = new SkillTreeProgressVO();
        BeanUtils.copyProperties(entity, vo);
        
        LambdaQueryWrapper<SkillNode> nodeQuery = new LambdaQueryWrapper<>();
        nodeQuery.eq(SkillNode::getTreeId, entity.getId());
        nodeQuery.eq(SkillNode::getStatus, 1);
        Long count = skillNodeMapper.selectCount(nodeQuery);
        vo.setNodeCount(count.intValue());
        vo.setCompletedCount(0);
        vo.setProgress(0.0);
        
        return vo;
    }
    
    private SkillNodeProgressVO convertToNodeVO(SkillNode node, Map<Long, UserSkillProgress> progressMap) {
        SkillNodeProgressVO vo = new SkillNodeProgressVO();
        BeanUtils.copyProperties(node, vo);
        vo.setChildren(new ArrayList<>());
        
        UserSkillProgress progress = progressMap.get(node.getId());
        if (progress != null) {
            // 将 Integer status 转换为 String: 0->LOCKED, 1->UNLOCKED, 2->COMPLETED
            vo.setUserStatus(convertStatusToString(progress.getStatus()));
            vo.setCurrentExp(progress.getCurrentExp());
            vo.setUnlockedAt(progress.getUnlockedAt());
            vo.setCompletedAt(progress.getCompletedAt());
        } else {
            vo.setUserStatus("LOCKED");
            vo.setCurrentExp(0);
            vo.setUnlockedAt(null);
            vo.setCompletedAt(null);
        }
        
        return vo;
    }
    
    /**
     * 将数据库状态值转换为字符串状态
     * @param status 0未解锁/1已解锁/2已完成
     * @return LOCKED/UNLOCKED/COMPLETED
     */
    private String convertStatusToString(Integer status) {
        if (status == null) {
            return "LOCKED";
        }
        switch (status) {
            case 0:
                return "LOCKED";
            case 1:
                return "UNLOCKED";
            case 2:
                return "COMPLETED";
            default:
                return "LOCKED";
        }
    }
    
    private List<SkillNodeProgressVO> buildNodeTree(List<SkillNodeProgressVO> allNodes, Long parentId) {
        List<SkillNodeProgressVO> result = new ArrayList<>();
        for (SkillNodeProgressVO node : allNodes) {
            if (node.getParentId().equals(parentId)) {
                List<SkillNodeProgressVO> children = buildNodeTree(allNodes, node.getId());
                node.setChildren(children);
                result.add(node);
            }
        }
        return result;
    }
}