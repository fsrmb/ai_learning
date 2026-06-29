package com.aicompanion.model.vo.arkts;

import lombok.Data;

import java.util.List;

@Data
public class AssessmentResultVO {

    private Long assessmentId;
    
    private Integer correctCount;
    
    private Integer wrongCount;
    
    private Double score;
    
    private Boolean passed;
    
    private Integer newExp;
    
    private Integer previousExp;
    
    private Boolean expIncreased;
    
    private Boolean nodeCompleted;
    
    private List<AnswerDetail> details;

    @Data
    public static class AnswerDetail {
        private Long questionId;
        private String userAnswer;
        private String correctAnswer;
        private Boolean isCorrect;
        private String explanation;
    }
}