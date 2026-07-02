package com.aicompanion.service;

import com.aicompanion.model.vo.SkillAssessmentVO;

import java.util.List;

public interface SkillAssessmentService {

    List<SkillAssessmentVO> getUserAssessments(Long userId);

    List<SkillAssessmentVO> getAllAssessments();

    List<SkillAssessmentVO> getAssessmentByNode(Long nodeId);
}