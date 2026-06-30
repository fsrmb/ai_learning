package com.aicompanion.controller.arkts;

import com.aicompanion.common.response.Result;
import com.aicompanion.common.util.JwtUtil;
import com.aicompanion.model.dto.ChatRequestDTO;
import com.aicompanion.model.dto.CreateConversationDTO;
import com.aicompanion.model.vo.arkts.ChatResponseVO;
import com.aicompanion.model.vo.arkts.ConversationVO;
import com.aicompanion.model.vo.arkts.MessageVO;
import com.aicompanion.service.arkts.ChatService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.List;

@RequestMapping("/api/chat")
@RestController
@RequiredArgsConstructor
@Slf4j
public class ChatController {
    
    private final ChatService chatService;
    private final JwtUtil jwtUtil;

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

    @GetMapping(value = "/stream/test", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamTest() {
        log.info("[ChatController] streamTest called");
        SseEmitter emitter = new SseEmitter(300000L);
        
        new Thread(() -> {
            try {
                String[] messages = {"你好", "这是测试", "消息", "[DONE]"};
                for (String msg : messages) {
                    log.info("[ChatController] sending test message: {}", msg);
                    emitter.send(msg);
                    Thread.sleep(500);
                }
                emitter.complete();
                log.info("[ChatController] streamTest completed");
            } catch (Exception e) {
                log.error("[ChatController] streamTest failed", e);
                emitter.completeWithError(e);
            }
        }).start();
        
        return emitter;
    }

    @PostMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter streamChat(@Valid @RequestBody ChatRequestDTO dto, @RequestHeader(value = "Authorization", required = false) String authorization) {
        log.info("[ChatController] streamChat called, conversationId={}", dto.getConversationId());
        SseEmitter emitter = new SseEmitter(300000L);
        emitter.onCompletion(() -> log.info("[ChatController] emitter completed"));
        emitter.onTimeout(() -> log.info("[ChatController] emitter timeout"));
        emitter.onError(e -> log.error("[ChatController] emitter error", e));
        
        Long userId = validateTokenAndGetUserId(authorization);

        new Thread(() -> {
            try {
                log.info("[ChatController] starting streamChat thread, userId={}", userId);
                chatService.streamMessage(dto, userId,
                        chunk -> {
                            try {
                                log.info("[ChatController] sending chunk: {}", chunk);
                                emitter.send(SseEmitter.event().data(chunk));
                                log.info("[ChatController] chunk sent successfully");
                            } catch (IOException e) {
                                log.error("[ChatController] send chunk failed", e);
                                emitter.completeWithError(e);
                            }
                        },
                        () -> {
                            try {
                                log.info("[ChatController] sending [DONE]");
                                emitter.send(SseEmitter.event().data("[DONE]"));
                                log.info("[ChatController] [DONE] sent, completing emitter");
                            } catch (IOException e) {
                                log.error("[ChatController] send [DONE] failed", e);
                                emitter.completeWithError(e);
                            }
                            emitter.complete();
                            log.info("[ChatController] emitter completed");
                        }
                );
            } catch (Exception e) {
                log.error("[ChatController] streamChat thread failed", e);
                emitter.completeWithError(e);
            }
        }).start();

        return emitter;
    }

    private Long validateTokenAndGetUserId(String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            throw new RuntimeException("未登录或Token已过期");
        }
        String token = authorization.substring(7);
        if (!jwtUtil.validateToken(token)) {
            throw new RuntimeException("Token已过期");
        }
        return jwtUtil.getUserIdFromToken(token);
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
