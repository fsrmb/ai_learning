package com.aicompanion.service.impl;

import com.aicompanion.mapper.SkillAssessmentMapper;
import com.aicompanion.mapper.SkillNodeMapper;
import com.aicompanion.mapper.SkillTreeMapper;
import com.aicompanion.mapper.UserMapper;
import com.aicompanion.model.entity.SkillAssessment;
import com.aicompanion.model.entity.SkillNode;
import com.aicompanion.model.entity.SkillTree;
import com.aicompanion.model.entity.User;
import com.aicompanion.model.vo.SkillAssessmentVO;
import com.aicompanion.service.SkillAssessmentService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SkillAssessmentServiceImpl implements SkillAssessmentService {

    private final SkillAssessmentMapper skillAssessmentMapper;
    private final UserMapper userMapper;
    private final SkillNodeMapper skillNodeMapper;
    private final SkillTreeMapper skillTreeMapper;

    @Override
    public List<SkillAssessmentVO> getUserAssessments(Long userId) {
        List<SkillAssessment> assessments = skillAssessmentMapper.selectList(
                new LambdaQueryWrapper<SkillAssessment>()
                        .eq(SkillAssessment::getUserId, userId)
                        .eq(SkillAssessment::getDeleted, 0)
                        .orderByDesc(SkillAssessment::getAssessmentTime)
        );
        return convertToVO(assessments);
    }

    @Override
    public List<SkillAssessmentVO> getAllAssessments() {
        List<SkillAssessment> assessments = skillAssessmentMapper.selectList(
                new LambdaQueryWrapper<SkillAssessment>()
                        .eq(SkillAssessment::getDeleted, 0)
                        .orderByDesc(SkillAssessment::getAssessmentTime)
        );
        return convertToVO(assessments);
    }

    @Override
    public List<SkillAssessmentVO> getAssessmentByNode(Long nodeId) {
        List<SkillAssessment> assessments = skillAssessmentMapper.selectList(
                new LambdaQueryWrapper<SkillAssessment>()
                        .eq(SkillAssessment::getNodeId, nodeId)
                        .eq(SkillAssessment::getDeleted, 0)
                        .orderByDesc(SkillAssessment::getAssessmentTime)
        );
        return convertToVO(assessments);
    }

    private List<SkillAssessmentVO> convertToVO(List<SkillAssessment> assessments) {
        if (assessments.isEmpty()) {
            return List.of();
        }

        List<Long> userIds = assessments.stream()
                .map(SkillAssessment::getUserId)
                .distinct()
                .collect(Collectors.toList());
        Map<Long, User> userMap = userMapper.selectBatchIds(userIds).stream()
                .collect(Collectors.toMap(User::getId, Function.identity()));

        List<Long> nodeIds = assessments.stream()
                .map(SkillAssessment::getNodeId)
                .distinct()
                .collect(Collectors.toList());
        Map<Long, SkillNode> nodeMap = skillNodeMapper.selectBatchIds(nodeIds).stream()
                .collect(Collectors.toMap(SkillNode::getId, Function.identity()));

        List<Long> treeIds = nodeMap.values().stream()
                .map(SkillNode::getTreeId)
                .distinct()
                .collect(Collectors.toList());
        Map<Long, SkillTree> treeMap = skillTreeMapper.selectBatchIds(treeIds).stream()
                .collect(Collectors.toMap(SkillTree::getId, Function.identity()));

        return assessments.stream().map(assessment -> {
            SkillAssessmentVO vo = new SkillAssessmentVO();
            BeanUtils.copyProperties(assessment, vo);

            User user = userMap.get(assessment.getUserId());
            vo.setUserName(user != null ? user.getUsername() : "");

            SkillNode node = nodeMap.get(assessment.getNodeId());
            vo.setNodeName(node != null ? node.getName() : "");

            if (node != null) {
                SkillTree tree = treeMap.get(node.getTreeId());
                vo.setTreeName(tree != null ? tree.getName() : "");
            }

            vo.setPassedText(assessment.getPassed() == 1 ? "通过" : "未通过");
            vo.setDifficultyText(getDifficultyText(assessment.getDifficulty()));

            return vo;
        }).collect(Collectors.toList());
    }

    private String getDifficultyText(Integer difficulty) {
        return switch (difficulty) {
            case 1 -> "入门";
            case 2 -> "初级";
            case 3 -> "中级";
            case 4 -> "高级";
            case 5 -> "专家";
            default -> "未知";
        };
    }
}