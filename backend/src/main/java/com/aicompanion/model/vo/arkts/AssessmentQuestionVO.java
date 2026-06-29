package com.aicompanion.model.vo.arkts;

import lombok.Data;

import java.util.List;

@Data
public class AssessmentQuestionVO {

    private Long questionId;
    
    private String questionText;
    
    private List<String> options;
    
    private Integer difficulty;
}