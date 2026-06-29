# Spring AI Chat 模块实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 实现 Spring AI Chat 接口，支持同步聊天、SSE 流式聊天、会话管理和历史记录查询

**架构：** 基于 Spring AI + DeepSeek API，使用 MyBatis-Plus 进行数据库持久化，支持多轮对话上下文（最近 10 条历史消息）

**技术栈：** Spring AI 1.0.0、DeepSeek API、MyBatis-Plus、SSE、Java 21

---

## 文件结构

| 文件 | 职责 |
|------|------|
| `model/dto/ChatRequestDTO.java` | 发送消息请求参数 |
| `model/dto/CreateConversationDTO.java` | 创建会话请求参数 |
| `model/vo/ChatResponseVO.java` | 聊天响应数据 |
| `model/vo/ConversationVO.java` | 会话信息 |
| `model/vo/MessageVO.java` | 消息信息 |
| `mapper/ChatConversationMapper.java` | 会话数据访问接口 |
| `mapper/ChatMessageMapper.java` | 消息数据访问接口 |
| `resources/mapper/ChatConversationMapper.xml` | 会话 SQL |
| `resources/mapper/ChatMessageMapper.xml` | 消息 SQL |
| `service/arkts/ChatService.java` | 业务接口定义 |
| `service/arkts/ChatServiceImpl.java` | 业务实现（含 AI 调用） |
| `controller/arkts/ChatController.java` | REST API 入口 |

---

### 任务 1：创建 DTO 和 VO 类

**文件：**
- 创建：`backend/src/main/java/com/aicompanion/model/dto/ChatRequestDTO.java`
- 创建：`backend/src/main/java/com/aicompanion/model/dto/CreateConversationDTO.java`
- 创建：`backend/src/main/java/com/aicompanion/model/vo/ChatResponseVO.java`
- 创建：`backend/src/main/java/com/aicompanion/model/vo/ConversationVO.java`
- 创建：`backend/src/main/java/com/aicompanion/model/vo/MessageVO.java`

- [ ] **步骤 1：创建 ChatRequestDTO**

```java
package com.aicompanion.model.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ChatRequestDTO {
    @NotNull(message = "会话ID不能为空")
    private Long conversationId;

    @NotBlank(message = "消息内容不能为空")
    private String message;
}
```

- [ ] **步骤 2：创建 CreateConversationDTO**

```java
package com.aicompanion.model.dto;

import lombok.Data;

@Data
public class CreateConversationDTO {
    private String title;
}
```

- [ ] **步骤 3：创建 ChatResponseVO**

```java
package com.aicompanion.model.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ChatResponseVO {
    private Long messageId;
    private String content;
    private LocalDateTime createdAt;
}
```

- [ ] **步骤 4：创建 ConversationVO**

```java
package com.aicompanion.model.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class ConversationVO {
    private Long conversationId;
    private String title;
    private String agentType;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

- [ ] **步骤 5：创建 MessageVO**

```java
package com.aicompanion.model.vo;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class MessageVO {
    private Long id;
    private String role;
    private String content;
    private LocalDateTime createdAt;
}
```

- [ ] **步骤 6：Commit**

```bash
git add backend/src/main/java/com/aicompanion/model/dto/*.java
git add backend/src/main/java/com/aicompanion/model/vo/*.java
git commit -m "feat: 添加 Chat DTO 和 VO 类"
```

---

### 任务 2：创建 Mapper 接口和 XML

**文件：**
- 创建：`backend/src/main/java/com/aicompanion/mapper/ChatConversationMapper.java`
- 创建：`backend/src/main/java/com/aicompanion/mapper/ChatMessageMapper.java`
- 创建：`backend/src/main/resources/mapper/ChatConversationMapper.xml`
- 创建：`backend/src/main/resources/mapper/ChatMessageMapper.xml`

- [ ] **步骤 1：创建 ChatConversationMapper**

```java
package com.aicompanion.mapper;

import com.aicompanion.model.entity.ChatConversation;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface ChatConversationMapper extends BaseMapper<ChatConversation> {
    @Select("SELECT * FROM chat_conversation WHERE user_id = #{userId} AND deleted = 0 ORDER BY update_time DESC")
    List<ChatConversation> selectByUserId(Long userId);
}
```

- [ ] **步骤 2：创建 ChatMessageMapper**

```java
package com.aicompanion.mapper;

import com.aicompanion.model.entity.ChatMessage;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;

import java.util.List;

@Mapper
public interface ChatMessageMapper extends BaseMapper<ChatMessage> {
    @Select("SELECT * FROM chat_message WHERE conversation_id = #{conversationId} AND deleted = 0 ORDER BY create_time ASC LIMIT #{limit}")
    List<ChatMessage> selectByConversationId(Long conversationId, Integer limit);

    @Select("SELECT COUNT(*) FROM chat_message WHERE conversation_id = #{conversationId} AND deleted = 0")
    int countByConversationId(Long conversationId);
}
```

- [ ] **步骤 3：创建 ChatConversationMapper.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.aicompanion.mapper.ChatConversationMapper">
</mapper>
```

- [ ] **步骤 4：创建 ChatMessageMapper.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.aicompanion.mapper.ChatMessageMapper">
</mapper>
```

- [ ] **步骤 5：Commit**

```bash
git add backend/src/main/java/com/aicompanion/mapper/*.java
git add backend/src/main/resources/mapper/*.xml
git commit -m "feat: 添加 Chat Mapper 接口和 XML"
```

---

### 任务 3：重写 ChatService 接口

**文件：**
- 修改：`backend/src/main/java/com/aicompanion/service/arkts/ChatService.java`

- [ ] **步骤 1：重写 ChatService 接口**

```java
package com.aicompanion.service.arkts;

import com.aicompanion.model.dto.ChatRequestDTO;
import com.aicompanion.model.dto.CreateConversationDTO;
import com.aicompanion.model.vo.ChatResponseVO;
import com.aicompanion.model.vo.ConversationVO;
import com.aicompanion.model.vo.MessageVO;

import java.util.List;
import java.util.function.Consumer;

public interface ChatService {
    ConversationVO createConversation(CreateConversationDTO dto, Long userId);
    
    ChatResponseVO sendMessage(ChatRequestDTO dto, Long userId);
    
    void streamMessage(ChatRequestDTO dto, Long userId, Consumer<String> onChunk, Runnable onComplete);
    
    List<MessageVO> getMessageHistory(Long conversationId, Long userId, Integer page, Integer size);
    
    List<ConversationVO> getConversations(Long userId);
}
```

- [ ] **步骤 2：Commit**

```bash
git add backend/src/main/java/com/aicompanion/service/arkts/ChatService.java
git commit -m "refactor: 重写 ChatService 接口，添加完整方法定义"
```

---

### 任务 4：重写 ChatServiceImpl

**文件：**
- 修改：`backend/src/main/java/com/aicompanion/service/arkts/ChatServiceImpl.java`

- [ ] **步骤 1：重写 ChatServiceImpl**

```java
package com.aicompanion.service.arkts;

import com.aicompanion.common.exception.BusinessException;
import com.aicompanion.mapper.ChatConversationMapper;
import com.aicompanion.mapper.ChatMessageMapper;
import com.aicompanion.model.dto.ChatRequestDTO;
import com.aicompanion.model.dto.CreateConversationDTO;
import com.aicompanion.model.entity.ChatConversation;
import com.aicompanion.model.entity.ChatMessage;
import com.aicompanion.model.vo.ChatResponseVO;
import com.aicompanion.model.vo.ConversationVO;
import com.aicompanion.model.vo.MessageVO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ChatServiceImpl implements ChatService {

    private final ChatClient.Builder chatClientBuilder;
    private final ChatConversationMapper conversationMapper;
    private final ChatMessageMapper messageMapper;

    private static final int MAX_HISTORY_SIZE = 10;
    private static final String SYSTEM_PROMPT = """
            你是"AI伴学助手"，一个面向大学生的智能学习伴侣。
            
            你的职责：
            1. 技术问答：回答编程问题（Java、Spring、数据库、前端等），解释概念时用通俗易懂的语言，配合代码示例
            2. 代码审查：审查代码质量，指出潜在问题，提供优化建议和最佳实践
            3. 写作助手：优化技术文章结构，修改简历，突出亮点，保持专业但友好的语气
            4. 学习规划：根据用户当前水平，提供学习路径和资源推荐
            5. 保持友好积极的语气，如果不确定，坦诚说明，不要编造答案
            """;

    @Override
    @Transactional
    public ConversationVO createConversation(CreateConversationDTO dto, Long userId) {
        ChatConversation conversation = new ChatConversation();
        conversation.setUserId(userId);
        conversation.setTitle(dto.getTitle() != null && !dto.getTitle().isEmpty() 
                ? dto.getTitle() : "新对话");
        conversation.setAgentType("CHAT");
        conversation.setStatus("ACTIVE");
        conversationMapper.insert(conversation);

        return convertToConversationVO(conversation);
    }

    @Override
    @Transactional
    public ChatResponseVO sendMessage(ChatRequestDTO dto, Long userId) {
        validateConversation(dto.getConversationId(), userId);

        ChatConversation conversation = conversationMapper.selectById(dto.getConversationId());
        
        ChatMessage userMessage = saveUserMessage(dto.getConversationId(), dto.getMessage());
        
        List<ChatMessage> history = getMessageHistory(dto.getConversationId());
        
        String reply = callAI(history, dto.getMessage());
        
        ChatMessage assistantMessage = saveAssistantMessage(dto.getConversationId(), reply);
        
        updateConversationUpdateTime(dto.getConversationId());

        return convertToChatResponseVO(assistantMessage);
    }

    @Override
    @Transactional
    public void streamMessage(ChatRequestDTO dto, Long userId, Consumer<String> onChunk, Runnable onComplete) {
        validateConversation(dto.getConversationId(), userId);

        ChatMessage userMessage = saveUserMessage(dto.getConversationId(), dto.getMessage());
        
        List<ChatMessage> history = getMessageHistory(dto.getConversationId());
        
        StringBuilder fullReply = new StringBuilder();
        
        ChatClient chatClient = chatClientBuilder
                .defaultSystem(SYSTEM_PROMPT)
                .build();
        
        try {
            chatClient.prompt()
                    .messages(buildMessages(history, dto.getMessage()))
                    .stream()
                    .content()
                    .subscribe(
                            chunk -> {
                                fullReply.append(chunk);
                                onChunk.accept(chunk);
                            },
                            error -> {
                                log.error("AI streaming error", error);
                            },
                            () -> {
                                saveAssistantMessage(dto.getConversationId(), fullReply.toString());
                                updateConversationUpdateTime(dto.getConversationId());
                                onComplete.run();
                            }
                    );
        } catch (Exception e) {
            log.error("AI streaming failed", e);
            throw new BusinessException("AI服务暂时不可用");
        }
    }

    @Override
    public List<MessageVO> getMessageHistory(Long conversationId, Long userId, Integer page, Integer size) {
        validateConversation(conversationId, userId);

        int offset = (page - 1) * size;
        List<ChatMessage> messages = messageMapper.selectByConversationId(conversationId, size + offset);
        
        if (offset > 0 && messages.size() > size) {
            messages = messages.subList(offset, offset + size);
        }

        return messages.stream()
                .map(this::convertToMessageVO)
                .collect(Collectors.toList());
    }

    @Override
    public List<ConversationVO> getConversations(Long userId) {
        List<ChatConversation> conversations = conversationMapper.selectByUserId(userId);
        return conversations.stream()
                .map(this::convertToConversationVO)
                .collect(Collectors.toList());
    }

    private void validateConversation(Long conversationId, Long userId) {
        if (conversationId == null) {
            throw new BusinessException("缺少会话ID");
        }
        
        ChatConversation conversation = conversationMapper.selectById(conversationId);
        if (conversation == null) {
            throw new BusinessException("会话已过期或不存在");
        }
        
        if (!conversation.getUserId().equals(userId)) {
            throw new BusinessException("无权访问该会话");
        }
    }

    private List<ChatMessage> getMessageHistory(Long conversationId) {
        List<ChatMessage> allMessages = messageMapper.selectByConversationId(conversationId, Integer.MAX_VALUE);
        
        if (allMessages.size() > MAX_HISTORY_SIZE) {
            return allMessages.subList(allMessages.size() - MAX_HISTORY_SIZE, allMessages.size());
        }
        return allMessages;
    }

    private String callAI(List<ChatMessage> history, String userMessage) {
        try {
            ChatClient chatClient = chatClientBuilder
                    .defaultSystem(SYSTEM_PROMPT)
                    .build();
            
            return chatClient.prompt()
                    .messages(buildMessages(history, userMessage))
                    .call()
                    .content();
        } catch (Exception e) {
            log.error("AI call failed", e);
            throw new BusinessException("AI服务暂时不可用");
        }
    }

    private List<org.springframework.ai.chat.messages.Message> buildMessages(List<ChatMessage> history, String userMessage) {
        List<org.springframework.ai.chat.messages.Message> messages = new ArrayList<>();
        
        for (ChatMessage msg : history) {
            if ("USER".equals(msg.getRole())) {
                messages.add(new org.springframework.ai.chat.messages.UserMessage(msg.getContent()));
            } else if ("ASSISTANT".equals(msg.getRole())) {
                messages.add(new org.springframework.ai.chat.messages.AssistantMessage(msg.getContent()));
            }
        }
        
        messages.add(new org.springframework.ai.chat.messages.UserMessage(userMessage));
        
        return messages;
    }

    private ChatMessage saveUserMessage(Long conversationId, String content) {
        ChatMessage message = new ChatMessage();
        message.setConversationId(conversationId);
        message.setRole("USER");
        message.setContent(content);
        message.setMessageType("TEXT");
        messageMapper.insert(message);
        return message;
    }

    private ChatMessage saveAssistantMessage(Long conversationId, String content) {
        ChatMessage message = new ChatMessage();
        message.setConversationId(conversationId);
        message.setRole("ASSISTANT");
        message.setContent(content);
        message.setMessageType("TEXT");
        messageMapper.insert(message);
        return message;
    }

    private void updateConversationUpdateTime(Long conversationId) {
        ChatConversation conversation = new ChatConversation();
        conversation.setId(conversationId);
        conversation.setUpdateTime(LocalDateTime.now());
        conversationMapper.updateById(conversation);
    }

    private ConversationVO convertToConversationVO(ChatConversation conversation) {
        ConversationVO vo = new ConversationVO();
        vo.setConversationId(conversation.getId());
        vo.setTitle(conversation.getTitle());
        vo.setAgentType(conversation.getAgentType());
        vo.setCreatedAt(conversation.getCreateTime());
        vo.setUpdatedAt(conversation.getUpdateTime());
        return vo;
    }

    private ChatResponseVO convertToChatResponseVO(ChatMessage message) {
        ChatResponseVO vo = new ChatResponseVO();
        vo.setMessageId(message.getId());
        vo.setContent(message.getContent());
        vo.setCreatedAt(message.getCreateTime());
        return vo;
    }

    private MessageVO convertToMessageVO(ChatMessage message) {
        MessageVO vo = new MessageVO();
        vo.setId(message.getId());
        vo.setRole(message.getRole());
        vo.setContent(message.getContent());
        vo.setCreatedAt(message.getCreateTime());
        return vo;
    }
}
```

- [ ] **步骤 2：Commit**

```bash
git add backend/src/main/java/com/aicompanion/service/arkts/ChatServiceImpl.java
git commit -m "feat: 重写 ChatServiceImpl，实现完整业务逻辑"
```

---

### 任务 5：重写 ChatController

**文件：**
- 修改：`backend/src/main/java/com/aicompanion/controller/arkts/ChatController.java`

- [ ] **步骤 1：重写 ChatController**

```java
package com.aicompanion.controller.arkts;

import com.aicompanion.common.response.Result;
import com.aicompanion.model.dto.ChatRequestDTO;
import com.aicompanion.model.dto.CreateConversationDTO;
import com.aicompanion.model.vo.ChatResponseVO;
import com.aicompanion.model.vo.ConversationVO;
import com.aicompanion.model.vo.MessageVO;
import com.aicompanion.service.arkts.ChatService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@RequestMapping("/api/chat")
@RestController
@RequiredArgsConstructor
public class ChatController {
    
    private final ChatService chatService;

    @PostMapping("/conversation")
    public Result<ConversationVO> createConversation(
            @RequestBody CreateConversationDTO dto,
            @RequestHeader("X-User-Id") Long userId) {
        ConversationVO conversation = chatService.createConversation(dto, userId);
        return Result.success(conversation);
    }

    @PostMapping("/message")
    public Result<ChatResponseVO> sendMessage(
            @Valid @RequestBody ChatRequestDTO dto,
            @RequestHeader("X-User-Id") Long userId) {
        ChatResponseVO response = chatService.sendMessage(dto, userId);
        return Result.success(response);
    }

    @PostMapping("/stream")
    public SseEmitter streamChat(
            @Valid @RequestBody ChatRequestDTO dto,
            @RequestHeader("X-User-Id") Long userId) {
        SseEmitter emitter = new SseEmitter(120000L);

        CompletableFuture.runAsync(() -> {
            try {
                chatService.streamMessage(dto, userId,
                        chunk -> {
                            try {
                                emitter.send(chunk);
                            } catch (IOException e) {
                                emitter.completeWithError(e);
                            }
                        },
                        () -> emitter.complete()
                );
            } catch (Exception e) {
                emitter.completeWithError(e);
            }
        });

        return emitter;
    }

    @GetMapping("/history/{conversationId}")
    public Result<List<MessageVO>> getMessageHistory(
            @PathVariable Long conversationId,
            @RequestHeader("X-User-Id") Long userId,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer size) {
        List<MessageVO> history = chatService.getMessageHistory(conversationId, userId, page, size);
        return Result.success(history);
    }

    @GetMapping("/conversations")
    public Result<List<ConversationVO>> getConversations(
            @RequestHeader("X-User-Id") Long userId) {
        List<ConversationVO> conversations = chatService.getConversations(userId);
        return Result.success(conversations);
    }
}
```

- [ ] **步骤 2：Commit**

```bash
git add backend/src/main/java/com/aicompanion/controller/arkts/ChatController.java
git commit -m "feat: 重写 ChatController，实现 5 个 REST API"
```

---

### 任务 6：编译验证

**文件：**
- 无新文件，编译验证所有代码

- [ ] **步骤 1：运行编译命令**

```bash
cd backend
.\mvnw.cmd compile -q
```

预期：编译成功，无错误

- [ ] **步骤 2：如果有错误，修复后重新编译**

根据错误信息修复代码，可能涉及：
- 缺少 import 语句
- 类型不匹配
- 方法签名问题

- [ ] **步骤 3：Commit 修复（如果有）**

```bash
git add -u
git commit -m "fix: 修复编译错误"
```

---

### 任务 7：API 测试

**文件：**
- 无新文件，测试 API 功能

- [ ] **步骤 1：启动后端服务**

```bash
cd backend
.\mvnw.cmd spring-boot:run -q
```

预期：服务启动成功，监听 8080 端口

- [ ] **步骤 2：测试创建会话**

```bash
curl -X POST http://localhost:8080/api/chat/conversation \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 1" \
  -d '{"title": "测试对话"}'
```

预期：返回 `{"code":200,"data":{"conversationId":1,"title":"测试对话",...}}`

- [ ] **步骤 3：测试同步聊天**

```bash
curl -X POST http://localhost:8080/api/chat/message \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 1" \
  -d '{"conversationId":1,"message":"你好"}'
```

预期：返回 `{"code":200,"data":{"content":"你好！我是AI伴学助手...",...}}`

- [ ] **步骤 4：测试会话列表**

```bash
curl -X GET "http://localhost:8080/api/chat/conversations" \
  -H "X-User-Id: 1"
```

预期：返回会话列表

- [ ] **步骤 5：测试消息历史**

```bash
curl -X GET "http://localhost:8080/api/chat/history/1?page=1&size=20" \
  -H "X-User-Id: 1"
```

预期：返回消息列表

---

### 任务 8：数据库表验证

**文件：**
- 无新文件，验证数据库表结构

- [ ] **步骤 1：验证 chat_conversation 表**

```sql
DESCRIBE chat_conversation;
```

预期：包含 user_id, title, agent_type, status, create_time, update_time, deleted 字段

- [ ] **步骤 2：验证 chat_message 表**

```sql
DESCRIBE chat_message;
```

预期：包含 conversation_id, role, content, message_type, create_time, update_time, deleted 字段

- [ ] **步骤 3：验证数据插入**

```sql
SELECT * FROM chat_conversation WHERE user_id = 1;
SELECT * FROM chat_message WHERE conversation_id = 1;
```

预期：能看到创建的会话和消息记录

---

## 规格覆盖度自检

| 规格需求 | 对应任务 |
|---------|---------|
| 创建会话接口 | 任务 5（POST /api/chat/conversation） |
| 同步聊天接口 | 任务 5（POST /api/chat/message） |
| SSE 流式聊天 | 任务 5（POST /api/chat/stream） |
| 查询消息历史 | 任务 5（GET /api/chat/history/{id}） |
| 查询会话列表 | 任务 5（GET /api/chat/conversations） |
| 数据库持久化 | 任务 2、4 |
| 多轮对话上下文 | 任务 4（getMessageHistory 方法） |
| 单一系统提示词 | 任务 4（SYSTEM_PROMPT 常量） |
| 用户隔离验证 | 任务 4（validateConversation 方法） |

---

## 占位符扫描

✅ 无占位符

✅ 无 TODO

✅ 无重复代码

✅ 所有类型、方法签名一致