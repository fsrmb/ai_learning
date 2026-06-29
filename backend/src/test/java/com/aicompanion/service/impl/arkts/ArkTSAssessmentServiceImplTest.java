package com.aicompanion.service.impl.arkts;

import com.aicompanion.mapper.SkillAssessmentDetailMapper;
import com.aicompanion.mapper.SkillAssessmentMapper;
import com.aicompanion.mapper.SkillQuestionMapper;
import com.aicompanion.mapper.UserSkillProgressMapper;
import com.aicompanion.model.dto.assessment.StartAssessmentDTO;
import com.aicompanion.model.dto.assessment.SubmitAnswerDTO;
import com.aicompanion.model.entity.SkillAssessment;
import com.aicompanion.model.entity.SkillQuestion;
import com.aicompanion.model.entity.UserSkillProgress;
import com.aicompanion.model.vo.arkts.AssessmentQuestionVO;
import com.aicompanion.model.vo.arkts.AssessmentResultVO;
import com.aicompanion.model.vo.arkts.DifficultyOptionVO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ArkTSAssessmentServiceImplTest {

    @Mock
    private SkillQuestionMapper skillQuestionMapper;

    @Mock
    private SkillAssessmentMapper skillAssessmentMapper;

    @Mock
    private SkillAssessmentDetailMapper skillAssessmentDetailMapper;

    @Mock
    private UserSkillProgressMapper userSkillProgressMapper;

    @InjectMocks
    private ArkTSAssessmentServiceImpl assessmentService;

    private SkillQuestion mockQuestion1;
    private SkillQuestion mockQuestion2;

    @BeforeEach
    void setUp() {
        mockQuestion1 = new SkillQuestion();
        mockQuestion1.setId(1L);
        mockQuestion1.setQuestionText("Test question 1");
        mockQuestion1.setOptionsJson("[\"A. Option 1\", \"B. Option 2\", \"C. Option 3\", \"D. Option 4\"]");
        mockQuestion1.setCorrectAnswer("A");
        mockQuestion1.setExplanation("Correct explanation");
        mockQuestion1.setDifficulty(1);

        mockQuestion2 = new SkillQuestion();
        mockQuestion2.setId(2L);
        mockQuestion2.setQuestionText("Test question 2");
        mockQuestion2.setOptionsJson("[\"A. Option 1\", \"B. Option 2\", \"C. Option 3\", \"D. Option 4\"]");
        mockQuestion2.setCorrectAnswer("B");
        mockQuestion2.setExplanation("Correct explanation");
        mockQuestion2.setDifficulty(1);
    }

    @Test
    @DisplayName("测试开始评估 - 题目数量充足")
    void testStartAssessment_Success() {
        when(skillQuestionMapper.countByNodeAndDifficulty(1L, 1)).thenReturn(10);
        when(skillQuestionMapper.selectRandomByNodeAndDifficulty(1L, 1, 5))
                .thenReturn(Arrays.asList(mockQuestion1, mockQuestion2));
        when(skillAssessmentMapper.insert(any(SkillAssessment.class))).thenAnswer(i -> {
            SkillAssessment a = i.getArgument(0);
            a.setId(1L);
            return 1;
        });

        StartAssessmentDTO dto = new StartAssessmentDTO();
        dto.setNodeId(1L);
        dto.setDifficulty(1);

        Map<String, Object> result = assessmentService.startAssessment(dto, 1L);

        assertNotNull(result);
        assertEquals(1L, result.get("assessmentId"));
        assertEquals(1L, result.get("nodeId"));
        assertEquals(1, result.get("difficulty"));
        List<?> questions = (List<?>) result.get("questions");
        assertEquals(2, questions.size());
    }

    @Test
    @DisplayName("测试开始评估 - 题目数量不足")
    void testStartAssessment_InsufficientQuestions() {
        when(skillQuestionMapper.countByNodeAndDifficulty(1L, 1)).thenReturn(3);

        StartAssessmentDTO dto = new StartAssessmentDTO();
        dto.setNodeId(1L);
        dto.setDifficulty(1);

        assertThrows(com.aicompanion.common.exception.BusinessException.class, () -> {
            assessmentService.startAssessment(dto, 1L);
        });
    }

    @Test
    @DisplayName("测试提交答案 - 通过评估")
    void testSubmitAnswer_Passed() {
        SkillAssessment assessment = new SkillAssessment();
        assessment.setId(1L);
        assessment.setUserId(1L);
        assessment.setNodeId(1L);
        assessment.setDifficulty(1);

        when(skillAssessmentMapper.selectById(1L)).thenReturn(assessment);
        when(skillQuestionMapper.selectBatchIds(any())).thenReturn(Arrays.asList(mockQuestion1, mockQuestion2));
        when(skillAssessmentDetailMapper.insert(any())).thenReturn(1);
        when(skillAssessmentMapper.updateById(any())).thenReturn(1);
        when(userSkillProgressMapper.selectOne(any())).thenReturn(null);
        when(userSkillProgressMapper.insert(any())).thenAnswer(i -> {
            UserSkillProgress p = i.getArgument(0);
            p.setId(1L);
            return 1;
        });
        when(userSkillProgressMapper.updateById(any())).thenReturn(1);

        SubmitAnswerDTO dto = new SubmitAnswerDTO();
        SubmitAnswerDTO.AnswerItem item1 = new SubmitAnswerDTO.AnswerItem();
        item1.setQuestionId(1L);
        item1.setAnswer("A");
        SubmitAnswerDTO.AnswerItem item2 = new SubmitAnswerDTO.AnswerItem();
        item2.setQuestionId(2L);
        item2.setAnswer("B");
        dto.setAnswers(Arrays.asList(item1, item2));
        dto.setTotalTime(60);

        AssessmentResultVO result = assessmentService.submitAnswer(1L, dto, 1L);

        assertNotNull(result);
        assertTrue(result.getPassed());
        assertEquals(100.0, result.getScore());
        assertEquals(2, result.getCorrectCount());
        assertEquals(0, result.getWrongCount());
        assertEquals(20, result.getNewExp());
        assertTrue(result.getExpIncreased());
    }

    @Test
    @DisplayName("测试获取难度选项")
    void testGetDifficultyOptions() {
        UserSkillProgress progress = new UserSkillProgress();
        progress.setCurrentExp(40);
        when(userSkillProgressMapper.selectOne(any())).thenReturn(progress);

        List<DifficultyOptionVO> options = assessmentService.getDifficultyOptions(1L, 1L);

        assertEquals(5, options.size());
        assertEquals(1, options.get(0).getLevel());
        assertEquals(20, options.get(0).getExp());
        assertTrue(options.get(0).getPassed());
        assertTrue(options.get(1).getPassed());
        assertFalse(options.get(2).getPassed());
    }
}