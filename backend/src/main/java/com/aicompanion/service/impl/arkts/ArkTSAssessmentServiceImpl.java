package com.aicompanion.service.impl.arkts;

import com.aicompanion.common.exception.BusinessException;
import com.aicompanion.mapper.SkillAssessmentDetailMapper;
import com.aicompanion.mapper.SkillAssessmentMapper;
import com.aicompanion.mapper.SkillQuestionMapper;
import com.aicompanion.mapper.UserSkillProgressMapper;
import com.aicompanion.model.dto.assessment.StartAssessmentDTO;
import com.aicompanion.model.dto.assessment.SubmitAnswerDTO;
import com.aicompanion.model.entity.SkillAssessment;
import com.aicompanion.model.entity.SkillAssessmentDetail;
import com.aicompanion.model.entity.SkillQuestion;
import com.aicompanion.model.entity.UserSkillProgress;
import com.aicompanion.model.vo.arkts.AssessmentQuestionVO;
import com.aicompanion.model.vo.arkts.AssessmentResultVO;
import com.aicompanion.model.vo.arkts.DifficultyOptionVO;
import com.aicompanion.service.arkts.ArkTSAssessmentService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ArkTSAssessmentServiceImpl implements ArkTSAssessmentService {

    private final SkillQuestionMapper skillQuestionMapper;
    private final SkillAssessmentMapper skillAssessmentMapper;
    private final SkillAssessmentDetailMapper skillAssessmentDetailMapper;
    private final UserSkillProgressMapper userSkillProgressMapper;

    private static final int QUESTION_COUNT_PER_LEVEL = 5;
    private static final double PASS_THRESHOLD = 70.0;

    private static final Map<Integer, String> DIFFICULTY_DESCRIPTIONS = new HashMap<>();
    private static final Map<Integer, String> DIFFICULTY_COLORS = new HashMap<>();

    static {
        DIFFICULTY_DESCRIPTIONS.put(1, "入门级，适合新手");
        DIFFICULTY_DESCRIPTIONS.put(2, "基础级，适合初学者");
        DIFFICULTY_DESCRIPTIONS.put(3, "进阶级，适合有一定基础");
        DIFFICULTY_DESCRIPTIONS.put(4, "高手级，适合熟练开发者");
        DIFFICULTY_DESCRIPTIONS.put(5, "专家级，适合资深工程师");

        DIFFICULTY_COLORS.put(1, "#22c55e");
        DIFFICULTY_COLORS.put(2, "#eab308");
        DIFFICULTY_COLORS.put(3, "#f97316");
        DIFFICULTY_COLORS.put(4, "#ef4444");
        DIFFICULTY_COLORS.put(5, "#1f2937");
    }

    @Override
    @Transactional
    public Map<String, Object> startAssessment(StartAssessmentDTO dto, Long userId) {
        Integer difficulty = dto.getDifficulty();
        if (difficulty < 1 || difficulty > 5) {
            throw new BusinessException("难度级别必须在1-5之间");
        }

        int questionCount = skillQuestionMapper.countByNodeAndDifficulty(dto.getNodeId(), difficulty);
        if (questionCount < QUESTION_COUNT_PER_LEVEL) {
            throw new BusinessException("该难度题目数量不足，请联系管理员");
        }

        List<SkillQuestion> questions = skillQuestionMapper.selectRandomByNodeAndDifficulty(
                dto.getNodeId(), difficulty, QUESTION_COUNT_PER_LEVEL);

        SkillAssessment assessment = new SkillAssessment();
        assessment.setUserId(userId);
        assessment.setNodeId(dto.getNodeId());
        assessment.setAssessmentTime(LocalDateTime.now());
        assessment.setQuestionCount(QUESTION_COUNT_PER_LEVEL);
        assessment.setPassThreshold(BigDecimal.valueOf(PASS_THRESHOLD));
        assessment.setDifficulty(difficulty);
        skillAssessmentMapper.insert(assessment);

        List<AssessmentQuestionVO> questionVOs = questions.stream()
                .map(this::convertToQuestionVO)
                .collect(Collectors.toList());

        Map<String, Object> result = new HashMap<>();
        result.put("assessmentId", assessment.getId());
        result.put("nodeId", dto.getNodeId());
        result.put("difficulty", difficulty);
        result.put("questions", questionVOs);
        result.put("passThreshold", PASS_THRESHOLD);
        result.put("totalQuestions", QUESTION_COUNT_PER_LEVEL);

        return result;
    }

    @Override
    @Transactional
    public AssessmentResultVO submitAnswer(Long assessmentId, SubmitAnswerDTO dto, Long userId) {
        SkillAssessment assessment = skillAssessmentMapper.selectById(assessmentId);
        if (assessment == null) {
            throw new BusinessException("评估记录不存在");
        }

        if (!assessment.getUserId().equals(userId)) {
            throw new BusinessException("无权访问该评估记录");
        }

        List<SkillQuestion> questions = skillQuestionMapper.selectBatchIds(
                dto.getAnswers().stream()
                        .map(SubmitAnswerDTO.AnswerItem::getQuestionId)
                        .collect(Collectors.toList()));

        Map<Long, SkillQuestion> questionMap = questions.stream()
                .collect(Collectors.toMap(SkillQuestion::getId, q -> q));

        int correctCount = 0;
        List<AssessmentResultVO.AnswerDetail> details = new ArrayList<>();

        for (SubmitAnswerDTO.AnswerItem item : dto.getAnswers()) {
            SkillQuestion question = questionMap.get(item.getQuestionId());
            boolean isCorrect = question != null && question.getCorrectAnswer().equals(item.getAnswer());

            if (isCorrect) {
                correctCount++;
            }

            AssessmentResultVO.AnswerDetail detail = new AssessmentResultVO.AnswerDetail();
            detail.setQuestionId(item.getQuestionId());
            detail.setUserAnswer(item.getAnswer());
            detail.setCorrectAnswer(question != null ? question.getCorrectAnswer() : null);
            detail.setIsCorrect(isCorrect);
            detail.setExplanation(question != null ? question.getExplanation() : null);
            details.add(detail);

            SkillAssessmentDetail assessmentDetail = new SkillAssessmentDetail();
            assessmentDetail.setAssessmentId(assessmentId);
            assessmentDetail.setQuestionId(item.getQuestionId());
            assessmentDetail.setUserAnswer(item.getAnswer());
            assessmentDetail.setIsCorrect(isCorrect ? 1 : 0);
            assessmentDetail.setTimeSpentSeconds(item.getTimeSpent());
            skillAssessmentDetailMapper.insert(assessmentDetail);
        }

        double score = (double) correctCount / dto.getAnswers().size() * 100;
        boolean passed = score >= PASS_THRESHOLD;

        assessment.setCorrectCount(correctCount);
        assessment.setTotalScore(BigDecimal.valueOf(score));
        assessment.setDurationSeconds(dto.getTotalTime());
        assessment.setPassed(passed ? 1 : 0);
        skillAssessmentMapper.updateById(assessment);

        int previousExp = 0;
        int newExp = 0;
        boolean expIncreased = false;
        boolean nodeCompleted = false;

        if (passed) {
            int difficultyExp = assessment.getDifficulty() != null ? assessment.getDifficulty() * 20 : 20;

            LambdaQueryWrapper<UserSkillProgress> wrapper = new LambdaQueryWrapper<>();
            wrapper.eq(UserSkillProgress::getUserId, userId)
                    .eq(UserSkillProgress::getNodeId, assessment.getNodeId());
            UserSkillProgress progress = userSkillProgressMapper.selectOne(wrapper);

            if (progress == null) {
                progress = new UserSkillProgress();
                progress.setUserId(userId);
                progress.setNodeId(assessment.getNodeId());
                progress.setStatus(1);
                progress.setCurrentExp(0);
                progress.setUnlockedAt(LocalDateTime.now());
                userSkillProgressMapper.insert(progress);
            }

            previousExp = progress.getCurrentExp();
            newExp = Math.max(previousExp, difficultyExp);
            expIncreased = newExp > previousExp;

            if (expIncreased) {
                progress.setCurrentExp(newExp);
                if (newExp >= 100) {
                    progress.setStatus(2);
                    progress.setCompletedAt(LocalDateTime.now());
                    nodeCompleted = true;
                }
                userSkillProgressMapper.updateById(progress);
            } else {
                newExp = previousExp;
            }
        }

        AssessmentResultVO result = new AssessmentResultVO();
        result.setAssessmentId(assessmentId);
        result.setCorrectCount(correctCount);
        result.setWrongCount(dto.getAnswers().size() - correctCount);
        result.setScore(score);
        result.setPassed(passed);
        result.setPreviousExp(previousExp);
        result.setNewExp(newExp);
        result.setExpIncreased(expIncreased);
        result.setNodeCompleted(nodeCompleted);
        result.setDetails(details);

        return result;
    }

    @Override
    public List<DifficultyOptionVO> getDifficultyOptions(Long nodeId, Long userId) {
        List<DifficultyOptionVO> options = new ArrayList<>();

        LambdaQueryWrapper<UserSkillProgress> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(UserSkillProgress::getUserId, userId)
                .eq(UserSkillProgress::getNodeId, nodeId);
        UserSkillProgress progress = userSkillProgressMapper.selectOne(wrapper);

        int currentExp = progress != null ? progress.getCurrentExp() : 0;

        for (int level = 1; level <= 5; level++) {
            DifficultyOptionVO option = new DifficultyOptionVO();
            option.setLevel(level);
            option.setExp(level * 20);
            option.setDescription(DIFFICULTY_DESCRIPTIONS.get(level));
            option.setColor(DIFFICULTY_COLORS.get(level));
            option.setPassed(currentExp >= level * 20);
            options.add(option);
        }

        return options;
    }

    private AssessmentQuestionVO convertToQuestionVO(SkillQuestion question) {
        AssessmentQuestionVO vo = new AssessmentQuestionVO();
        vo.setQuestionId(question.getId());
        vo.setQuestionText(question.getQuestionText());
        
        try {
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            List<String> options = mapper.readValue(question.getOptionsJson(), 
                    new com.fasterxml.jackson.core.type.TypeReference<List<String>>() {});
            vo.setOptions(options);
        } catch (Exception e) {
            vo.setOptions(Collections.emptyList());
        }
        
        vo.setDifficulty(question.getDifficulty());
        return vo;
    }
}