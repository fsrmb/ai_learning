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
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
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
