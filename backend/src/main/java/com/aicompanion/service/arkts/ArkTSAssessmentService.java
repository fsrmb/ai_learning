package com.aicompanion.service.arkts;

import com.aicompanion.model.dto.assessment.StartAssessmentDTO;
import com.aicompanion.model.dto.assessment.SubmitAnswerDTO;
import com.aicompanion.model.vo.arkts.AssessmentQuestionVO;
import com.aicompanion.model.vo.arkts.AssessmentResultVO;
import com.aicompanion.model.vo.arkts.DifficultyOptionVO;

import java.util.List;
import java.util.Map;

public interface ArkTSAssessmentService {

    Map<String, Object> startAssessment(StartAssessmentDTO dto, Long userId);

    AssessmentResultVO submitAnswer(Long assessmentId, SubmitAnswerDTO dto, Long userId);

    List<DifficultyOptionVO> getDifficultyOptions(Long nodeId, Long userId);
}