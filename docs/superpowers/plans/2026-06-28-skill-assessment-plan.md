# 技能评估与答题闯关功能实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 实现技能评估与答题闯关功能，包括开始评估、答题、提交评分、更新熟练度等完整流程。

**架构：** 后端采用 Spring Boot + MyBatis-Plus，移动端采用 ArkTS。后端提供 RESTful API，移动端调用 API 实现答题流程。

**技术栈：** Java 21, Spring Boot 3.2, MyBatis-Plus 3.5, MySQL 8.0, ArkTS

---

## 文件结构

| 文件路径 | 职责 |
|----------|------|
| `mapper/SkillQuestionMapper.java` | 题目库数据访问接口 |
| `mapper/SkillAssessmentMapper.java` | 评估记录数据访问接口 |
| `mapper/SkillAssessmentDetailMapper.java` | 答题明细数据访问接口 |
| `service/arkts/ArkTSAssessmentService.java` | 移动端评估服务接口 |
| `service/impl/arkts/ArkTSAssessmentServiceImpl.java` | 移动端评估服务实现 |
| `controller/arkts/ArkTSAssessmentController.java` | 移动端评估控制器 |
| `model/dto/assessment/StartAssessmentDTO.java` | 开始评估请求 DTO |
| `model/dto/assessment/SubmitAnswerDTO.java` | 提交答案请求 DTO |
| `model/vo/arkts/AssessmentQuestionVO.java` | 题目 VO |
| `model/vo/arkts/AssessmentResultVO.java` | 评估结果 VO |
| `model/vo/arkts/DifficultyOptionVO.java` | 难度选项 VO |

---

## 任务 1：创建 Mapper 接口

**文件：**
- 创建：`backend/src/main/java/com/aicompanion/mapper/SkillQuestionMapper.java`
- 创建：`backend/src/main/java/com/aicompanion/mapper/SkillAssessmentMapper.java`
- 创建：`backend/src/main/java/com/aicompanion/mapper/SkillAssessmentDetailMapper.java`

- [ ] **步骤 1：创建 SkillQuestionMapper**

```java
package com.aicompanion.mapper;

import com.aicompanion.model.entity.SkillQuestion;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface SkillQuestionMapper extends BaseMapper<SkillQuestion> {

    @Select("SELECT * FROM skill_question WHERE node_id = #{nodeId} AND difficulty = #{difficulty} AND deleted = 0 ORDER BY RAND() LIMIT #{limit}")
    List<SkillQuestion> selectRandomByNodeAndDifficulty(@Param("nodeId") Long nodeId, @Param("difficulty") Integer difficulty, @Param("limit") Integer limit);

    @Select("SELECT COUNT(*) FROM skill_question WHERE node_id = #{nodeId} AND difficulty = #{difficulty} AND deleted = 0")
    Integer countByNodeAndDifficulty(@Param("nodeId") Long nodeId, @Param("difficulty") Integer difficulty);
}
```

- [ ] **步骤 2：创建 SkillAssessmentMapper**

```java
package com.aicompanion.mapper;

import com.aicompanion.model.entity.SkillAssessment;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface SkillAssessmentMapper extends BaseMapper<SkillAssessment> {
}
```

- [ ] **步骤 3：创建 SkillAssessmentDetailMapper**

```java
package com.aicompanion.mapper;

import com.aicompanion.model.entity.SkillAssessmentDetail;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface SkillAssessmentDetailMapper extends BaseMapper<SkillAssessmentDetail> {
}
```

- [ ] **步骤 4：验证编译通过**

运行：`mvn compile`
预期：SUCCESS

- [ ] **步骤 5：Commit**

```bash
git add backend/src/main/java/com/aicompanion/mapper/SkillQuestionMapper.java
git add backend/src/main/java/com/aicompanion/mapper/SkillAssessmentMapper.java
git add backend/src/main/java/com/aicompanion/mapper/SkillAssessmentDetailMapper.java
git commit -m "feat: add assessment mapper interfaces"
```

---

## 任务 2：创建 DTO 和 VO

**文件：**
- 创建：`backend/src/main/java/com/aicompanion/model/dto/assessment/StartAssessmentDTO.java`
- 创建：`backend/src/main/java/com/aicompanion/model/dto/assessment/SubmitAnswerDTO.java`
- 创建：`backend/src/main/java/com/aicompanion/model/vo/arkts/AssessmentQuestionVO.java`
- 创建：`backend/src/main/java/com/aicompanion/model/vo/arkts/AssessmentResultVO.java`
- 创建：`backend/src/main/java/com/aicompanion/model/vo/arkts/DifficultyOptionVO.java`

- [ ] **步骤 1：创建 StartAssessmentDTO**

```java
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
```

- [ ] **步骤 2：创建 SubmitAnswerDTO**

```java
package com.aicompanion.model.dto.assessment;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
public class SubmitAnswerDTO {

    @NotEmpty(message = "答案列表不能为空")
    private List<AnswerItem> answers;

    @NotNull(message = "总耗时不能为空")
    private Integer totalTime;

    @Data
    public static class AnswerItem {
        @NotNull(message = "题目ID不能为空")
        private Long questionId;
        
        private String answer;
        
        private Integer timeSpent;
    }
}
```

- [ ] **步骤 3：创建 AssessmentQuestionVO**

```java
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
```

- [ ] **步骤 4：创建 AssessmentResultVO**

```java
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
```

- [ ] **步骤 5：创建 DifficultyOptionVO**

```java
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
```

- [ ] **步骤 6：验证编译通过**

运行：`mvn compile`
预期：SUCCESS

- [ ] **步骤 7：Commit**

```bash
git add backend/src/main/java/com/aicompanion/model/dto/assessment/
git add backend/src/main/java/com/aicompanion/model/vo/arkts/
git commit -m "feat: add assessment DTO and VO classes"
```

---

## 任务 3：创建 Service 接口和实现

**文件：**
- 创建：`backend/src/main/java/com/aicompanion/service/arkts/ArkTSAssessmentService.java`
- 创建：`backend/src/main/java/com/aicompanion/service/impl/arkts/ArkTSAssessmentServiceImpl.java`

- [ ] **步骤 1：创建 ArkTSAssessmentService 接口**

```java
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
```

- [ ] **步骤 2：创建 ArkTSAssessmentServiceImpl 实现类**

```java
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
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
        assessment.setPassThreshold(PASS_THRESHOLD);
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
        assessment.setTotalScore(score);
        assessment.setDurationSeconds(dto.getTotalTime());
        assessment.setPassed(passed ? 1 : 0);
        skillAssessmentMapper.updateById(assessment);

        int previousExp = 0;
        int newExp = 0;
        boolean expIncreased = false;
        boolean nodeCompleted = false;

        if (passed) {
            int difficultyExp = assessment.getNodeId() != null ? assessment.getNodeId().intValue() % 5 * 20 + 20 : 0;
            difficultyExp = assessment.getDifficulty() != null ? assessment.getDifficulty() * 20 : 20;

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
```

- [ ] **步骤 3：验证编译通过**

运行：`mvn compile`
预期：SUCCESS

- [ ] **步骤 4：Commit**

```bash
git add backend/src/main/java/com/aicompanion/service/arkts/ArkTSAssessmentService.java
git add backend/src/main/java/com/aicompanion/service/impl/arkts/ArkTSAssessmentServiceImpl.java
git commit -m "feat: add assessment service implementation"
```

---

## 任务 4：创建 Controller

**文件：**
- 创建：`backend/src/main/java/com/aicompanion/controller/arkts/ArkTSAssessmentController.java`

- [ ] **步骤 1：创建 ArkTSAssessmentController**

```java
package com.aicompanion.controller.arkts;

import com.aicompanion.common.response.Result;
import com.aicompanion.model.dto.assessment.StartAssessmentDTO;
import com.aicompanion.model.dto.assessment.SubmitAnswerDTO;
import com.aicompanion.model.vo.arkts.AssessmentResultVO;
import com.aicompanion.model.vo.arkts.DifficultyOptionVO;
import com.aicompanion.service.arkts.ArkTSAssessmentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Tag(name = "移动端技能评估", description = "ArkTS 移动端技能评估相关接口")
@RestController
@RequestMapping("/api/arkts/assessments")
@RequiredArgsConstructor
public class ArkTSAssessmentController {

    private final ArkTSAssessmentService arkTSAssessmentService;

    @Operation(summary = "开始评估", description = "创建评估记录，获取题目")
    @PostMapping("/start")
    public Result<Map<String, Object>> startAssessment(
            @Parameter(description = "开始评估请求")
            @Valid @RequestBody StartAssessmentDTO dto,
            @Parameter(description = "用户ID")
            @RequestHeader("X-User-Id") Long userId) {
        Map<String, Object> result = arkTSAssessmentService.startAssessment(dto, userId);
        return Result.success(result);
    }

    @Operation(summary = "提交答案", description = "提交答案，计算得分，更新熟练度")
    @PostMapping("/{id}/submit")
    public Result<AssessmentResultVO> submitAnswer(
            @Parameter(description = "评估记录ID")
            @PathVariable Long id,
            @Parameter(description = "提交答案请求")
            @Valid @RequestBody SubmitAnswerDTO dto,
            @Parameter(description = "用户ID")
            @RequestHeader("X-User-Id") Long userId) {
        AssessmentResultVO result = arkTSAssessmentService.submitAnswer(id, dto, userId);
        return Result.success(result);
    }

    @Operation(summary = "获取难度选项", description = "获取指定技能节点的难度选项列表")
    @GetMapping("/difficulty-options/{nodeId}")
    public Result<List<DifficultyOptionVO>> getDifficultyOptions(
            @Parameter(description = "技能节点ID")
            @PathVariable Long nodeId,
            @Parameter(description = "用户ID")
            @RequestHeader("X-User-Id") Long userId) {
        List<DifficultyOptionVO> options = arkTSAssessmentService.getDifficultyOptions(nodeId, userId);
        return Result.success(options);
    }
}
```

- [ ] **步骤 2：验证编译通过**

运行：`mvn compile`
预期：SUCCESS

- [ ] **步骤 3：Commit**

```bash
git add backend/src/main/java/com/aicompanion/controller/arkts/ArkTSAssessmentController.java
git commit -m "feat: add assessment controller"
```

---

## 任务 5：编写测试用例

**文件：**
- 创建：`backend/src/test/java/com/aicompanion/service/impl/arkts/ArkTSAssessmentServiceImplTest.java`

- [ ] **步骤 1：创建测试类**

```java
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
```

- [ ] **步骤 2：运行测试**

运行：`mvn test -Dtest=ArkTSAssessmentServiceImplTest`
预期：PASS

- [ ] **步骤 3：Commit**

```bash
git add backend/src/test/java/com/aicompanion/service/impl/arkts/ArkTSAssessmentServiceImplTest.java
git commit -m "test: add assessment service tests"
```

---

## 任务 6：数据库初始化数据

**文件：**
- 修改：`backend/sql/init_database.sql`

- [ ] **步骤 1：添加测试题目数据**

在 `skill_question` 表的 INSERT 语句后添加：

```sql
INSERT INTO `skill_question` (`node_id`, `question_text`, `options_json`, `correct_answer`, `explanation`, `difficulty`, `source`) VALUES
(1, 'Java中int类型占用多少字节？', '["A. 1字节", "B. 2字节", "C. 4字节", "D. 8字节"]', 'C', 'int类型占用4字节，取值范围是-2³¹到2³¹-1', 1, 'MANUAL'),
(1, 'Java中哪个关键字用于声明类？', '["A. interface", "B. class", "C. struct", "D. type"]', 'B', 'class关键字用于声明类', 1, 'MANUAL'),
(1, 'Java中main方法的正确签名是？', '["A. public void main()", "B. public static void main(String[] args)", "C. static void main(String args)", "D. void main()"]', 'B', 'main方法必须是public static void，参数为String数组', 1, 'MANUAL'),
(1, 'Java中==和equals()的区别是？', '["A. 完全相同", "B. ==比较引用，equals()比较内容", "C. ==比较内容，equals()比较引用", "D. 没有区别"]', 'B', '==比较对象引用是否相同，equals()默认也比较引用，但可重写比较内容', 2, 'MANUAL'),
(1, 'Java中ArrayList和LinkedList的区别是？', '["A. 没有区别", "B. ArrayList基于数组，LinkedList基于链表", "C. ArrayList基于链表，LinkedList基于数组", "D. ArrayList是线程安全的"]', 'B', 'ArrayList基于动态数组实现，查询快；LinkedList基于双向链表，插入删除快', 2, 'MANUAL'),
(1, 'Java中HashMap的底层实现原理是？', '["A. 数组", "B. 链表", "C. 数组+链表/红黑树", "D. 红黑树"]', 'C', 'HashMap底层是数组+链表/红黑树，当链表长度超过阈值时转为红黑树', 3, 'MANUAL'),
(1, 'Java中volatile关键字的作用是？', '["A. 保证原子性", "B. 保证可见性和有序性", "C. 保证线程安全", "D. 提高性能"]', 'B', 'volatile保证可见性和有序性，但不保证原子性', 3, 'MANUAL'),
(1, 'Java中线程池的核心参数有哪些？', '["A. corePoolSize", "B. maximumPoolSize", "C. keepAliveTime", "D. 以上都是"]', 'D', '线程池核心参数包括corePoolSize、maximumPoolSize、keepAliveTime、workQueue等', 4, 'MANUAL'),
(1, 'Java中CAS操作的原理是？', '["A. Compare And Swap", "B. Compare And Set", "C. Compare And Sort", "D. Compare And Share"]', 'A', 'CAS即Compare And Swap，是一种无锁算法，比较并交换', 4, 'MANUAL'),
(1, 'Java中JVM内存模型分为哪几个区域？', '["A. 堆、栈、方法区", "B. 堆、栈、方法区、程序计数器、本地方法栈", "C. 堆和栈", "D. 只有堆"]', 'B', 'JVM内存模型包括：堆、栈、方法区、程序计数器、本地方法栈', 5, 'MANUAL'),
(2, 'Vue3中使用哪个API创建响应式对象？', '["A. Vue.observable()", "B. reactive()", "C. ref()", "D. createApp()"]', 'B', 'Vue3中使用reactive()创建响应式对象，ref()创建响应式引用', 1, 'MANUAL'),
(2, 'Vue3中setup()函数的作用是？', '["A. 渲染组件", "B. 组合式API的入口", "C. 创建路由", "D. 注册插件"]', 'B', 'setup()是组合式API的入口函数，在组件创建之前执行', 1, 'MANUAL'),
(2, 'Vue3中computed的特点是？', '["A. 每次调用都重新计算", "B. 有缓存，依赖不变时返回缓存值", "C. 只能是只读的", "D. 不能接收参数"]', 'B', 'computed有缓存机制，只有依赖变化时才重新计算', 2, 'MANUAL'),
(2, 'Vue3中watch和watchEffect的区别是？', '["A. 没有区别", "B. watch需要明确指定依赖，watchEffect自动追踪", "C. watchEffect需要明确指定依赖", "D. watch只能监听ref"]', 'B', 'watch需要明确指定监听的数据源，watchEffect自动追踪依赖', 2, 'MANUAL'),
(2, 'Vue3中组件通信有哪些方式？', '["A. props/emits", "B. provide/inject", "C. Pinia状态管理", "D. 以上都是"]', 'D', 'Vue3组件通信方式包括props/emits、provide/inject、事件总线、Pinia等', 3, 'MANUAL'),
(2, 'Vue3中VNode的作用是？', '["A. 虚拟DOM节点", "B. 真实DOM节点", "C. 组件实例", "D. 路由对象"]', 'A', 'VNode是虚拟DOM的节点对象，描述了DOM节点的结构', 3, 'MANUAL'),
(2, 'Vue3中Diff算法的优化策略是？', '["A. 双端比较", "B. 最长递增子序列", "C. 跳过静态节点", "D. 以上都是"]', 'D', 'Vue3的Diff算法采用双端比较、最长递增子序列、跳过静态节点等优化策略', 4, 'MANUAL'),
(2, 'Vue3中响应式系统的底层原理是？', '["A. Object.defineProperty", "B. Proxy", "C. Reflect", "D. Symbol"]', 'B', 'Vue3使用Proxy实现响应式系统，相比Vue2的Object.defineProperty更强大', 4, 'MANUAL'),
(2, 'Vue3中Teleport组件的作用是？', '["A. 实现组件懒加载", "B. 将组件渲染到DOM的任意位置", "C. 实现路由跳转", "D. 实现状态管理"]', 'B', 'Teleport可以将组件渲染到DOM的任意位置，常用于模态框等场景', 5, 'MANUAL');
```

- [ ] **步骤 2：Commit**

```bash
git add backend/sql/init_database.sql
git commit -m "data: add test questions for skill assessment"
```

---

## 规格覆盖度检查

| 规格章节 | 对应任务 |
|----------|----------|
| 核心规则 | 任务3（Service实现） |
| 数据模型 | 已有实体类 |
| API设计 | 任务4（Controller） |
| 移动端页面设计 | 需在移动端实现 |
| 业务逻辑流程 | 任务3（Service实现） |
| 异常处理 | 任务3（Service实现） |

---

**计划已完成并保存到 `docs/superpowers/plans/2026-06-28-skill-assessment-plan.md`。**

**两种执行方式：**

1. **子代理驱动（推荐）** - 每个任务调度一个新的子代理，任务间进行审查，快速迭代

2. **内联执行** - 在当前会话中使用 executing-plans 执行任务，批量执行并设有检查点

**选哪种方式？**