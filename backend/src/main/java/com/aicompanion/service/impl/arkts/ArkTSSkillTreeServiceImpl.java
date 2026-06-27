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
        wrapper.orderByAsc(SkillTree::getSortOrder);
        
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
        wrapper.orderByAsc(SkillNode::getSortOrder);
        
        List<SkillNode> allNodes = skillNodeMapper.selectList(wrapper);
        
        Long userId = getCurrentUserId();
        Map<Long, UserSkillProgress> progressMap = null;
        if (userId != null) {
            LambdaQueryWrapper<UserSkillProgress> progressQuery = new LambdaQueryWrapper<>();
            progressQuery.eq(UserSkillProgress::getUserId, userId);
            List<UserSkillProgress> progressList = userSkillProgressMapper.selectList(progressQuery);
            progressMap = progressList.stream()
                    .collect(Collectors.toMap(UserSkillProgress::getNodeId, p -> p));
        }
        
        List<SkillNodeProgressVO> allNodeVOs = allNodes.stream()
                .map(node -> convertToNodeVO(node, progressMap))
                .collect(Collectors.toList());
        
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
        
        Map<Long, Long> completedNodeCountMap = progressList.stream()
                .filter(p -> "COMPLETED".equals(p.getStatus()))
                .collect(Collectors.groupingBy(
                        p -> {
                            SkillNode node = skillNodeMapper.selectById(p.getNodeId());
                            return node != null ? node.getTreeId() : null;
                        },
                        Collectors.counting()
                ));
        
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
        vo.setNodeCount((int) skillNodeMapper.selectCount(nodeQuery));
        vo.setCompletedCount(0);
        vo.setProgress(0.0);
        
        return vo;
    }
    
    private SkillNodeProgressVO convertToNodeVO(SkillNode node, Map<Long, UserSkillProgress> progressMap) {
        SkillNodeProgressVO vo = new SkillNodeProgressVO();
        BeanUtils.copyProperties(node, vo);
        vo.setChildren(new ArrayList<>());
        
        if (progressMap != null && progressMap.containsKey(node.getId())) {
            UserSkillProgress progress = progressMap.get(node.getId());
            vo.setUserStatus(progress.getStatus());
            vo.setBestScore(progress.getBestScore());
            vo.setLatestScore(progress.getLatestScore());
            vo.setAttemptCount(progress.getAttemptCount());
            vo.setExpPoints(progress.getExpPoints());
        } else {
            vo.setUserStatus("LOCKED");
            vo.setBestScore(null);
            vo.setLatestScore(null);
            vo.setAttemptCount(0);
            vo.setExpPoints(0);
        }
        
        return vo;
    }
    
    private List<SkillNodeProgressVO> buildNodeTree(List<SkillNodeProgressVO> allNodes, Long parentId) {
        return allNodes.stream()
                .filter(node -> node.getParentId().equals(parentId))
                .peek(node -> {
                    List<SkillNodeProgressVO> children = buildNodeTree(allNodes, node.getId());
                    node.setChildren(children);
                })
                .collect(Collectors.toList());
    }
}