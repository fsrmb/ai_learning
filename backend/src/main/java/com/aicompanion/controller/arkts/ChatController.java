package com.aicompanion.controller.arkts;

import com.aicompanion.common.response.Result;
import com.aicompanion.model.dto.ChatRequestDTO;
import com.aicompanion.model.dto.CreateConversationDTO;
import com.aicompanion.model.vo.arkts.ChatResponseVO;
import com.aicompanion.model.vo.arkts.ConversationVO;
import com.aicompanion.model.vo.arkts.MessageVO;
import com.aicompanion.service.arkts.ChatService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

@RequestMapping("/api/chat")
@RestController
@RequiredArgsConstructor
public class ChatController {
    
    private final ChatService chatService;
    private final ChatClient.Builder chatClientBuilder;

    private Long getUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated()) {
            return Long.parseLong(authentication.getName());
        }
        throw new RuntimeException("用户未登录");
    }

    @PostMapping("/conversation")
    public Result<ConversationVO> createConversation(@RequestBody CreateConversationDTO dto) {
        ConversationVO conversation = chatService.createConversation(dto, getUserId());
        return Result.success(conversation);
    }

    @PostMapping("/message")
    public Result<ChatResponseVO> sendMessage(@Valid @RequestBody ChatRequestDTO dto) {
        ChatResponseVO response = chatService.sendMessage(dto, getUserId());
        return Result.success(response);
    }

    @PostMapping("/simple")
    public Result<Map<String, Object>> simpleChat(@RequestBody Map<String, Object> request) {
        String message = (String) request.get("message");
        if (message == null || message.trim().isEmpty()) {
            return Result.error("消息内容不能为空");
        }

        List<org.springframework.ai.chat.messages.Message> historyMessages = new ArrayList<>();
        
        @SuppressWarnings("unchecked")
        List<Map<String, String>> history = (List<Map<String, String>>) request.get("history");
        if (history != null) {
            for (Map<String, String> item : history) {
                String role = item.get("role");
                String content = item.get("content");
                if ("user".equalsIgnoreCase(role)) {
                    historyMessages.add(new org.springframework.ai.chat.messages.UserMessage(content));
                } else if ("assistant".equalsIgnoreCase(role)) {
                    historyMessages.add(new org.springframework.ai.chat.messages.AssistantMessage(content));
                }
            }
        }

        historyMessages.add(new org.springframework.ai.chat.messages.UserMessage(message));

        String response = chatClientBuilder.build()
                .prompt()
                .system(SYSTEM_PROMPT)
                .messages(historyMessages)
                .call()
                .content();

        return Result.success(Map.of("response", response));
    }

    private static final String SYSTEM_PROMPT = """
            你是一位专业的Java技术面试官。你的角色是提出问题并评估求职者的回答，而不是直接给出答案。
            
            核心职责：
            1. 主动提问：你负责提出问题，求职者负责回答。不要在求职者回答前给出答案。
            2. 问题范围：仅限Java基础知识，包括但不限于：变量与数据类型、运算符与表达式、流程控制（if-else、for、while、switch）、数组与字符串、面向对象（封装、继承、多态、抽象、接口）、异常处理、集合框架（List、Set、Map）、泛型、多线程、Java内存模型、常用类库等。
            3. 单次一题：每次回复只包含一个问题，不要在一个回复中问多个问题。
            4. 追问策略：
               - 如果求职者回答正确且完整：提出一个更深入的相关问题
               - 如果求职者回答错误：指出错误点（简单提示），然后让求职者重新回答
               - 如果求职者回答不完整：追问缺失的部分
               - 如果求职者表示不知道：给出简单提示后再次提问
            5. 语言风格：使用简洁、专业的提问方式，避免冗长。
            6. 难度递进：从基础问题开始，根据求职者的表现逐步提高难度。
            
            对话流程：
            - 用户说"开始" → 你提出第一个基础问题
            - 用户回答问题 → 你评估后进行追问或提出下一题
            
            注意：你的回复应该是一个问题，而不是答案。只有在指出错误时才简要解释。
            """;


    @PostMapping("/stream")
    public SseEmitter streamChat(@Valid @RequestBody ChatRequestDTO dto) {
        SseEmitter emitter = new SseEmitter(120000L);
        Long userId = getUserId();

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
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer size) {
        List<MessageVO> history = chatService.getMessageHistory(conversationId, getUserId(), page, size);
        return Result.success(history);
    }

    @GetMapping("/conversations")
    public Result<List<ConversationVO>> getConversations() {
        List<ConversationVO> conversations = chatService.getConversations(getUserId());
        return Result.success(conversations);
    }
}
