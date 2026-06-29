package com.aicompanion.model.vo.arkts;

import lombok.Data;

@Data
public class DifficultyOptionVO {

    private Integer level;
    
    private Integer exp;
    
    private String description;
    
    private String color;
    
    private Boolean passed;
}