package com.aicompanion.model.dto.assessment;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class StartAssessmentDTO {

    @NotNull(message = "技能节点ID不能为空")
    private Long nodeId;

    @NotNull(message = "难度级别不能为空")
    private Integer difficulty;
}