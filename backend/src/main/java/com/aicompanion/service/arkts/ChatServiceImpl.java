package com.aicompanion.service.arkts;

import com.aicompanion.common.exception.BusinessException;
import com.aicompanion.mapper.ChatConversationMapper;
import com.aicompanion.mapper.ChatMessageMapper;
import com.aicompanion.model.dto.ChatRequestDTO;
import com.aicompanion.model.dto.CreateConversationDTO;
import com.aicompanion.model.entity.ChatConversation;
import com.aicompanion.model.entity.ChatMessage;
import com.aicompanion.model.vo.arkts.ChatResponseVO;
import com.aicompanion.model.vo.arkts.ConversationVO;
import com.aicompanion.model.vo.arkts.MessageVO;
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
//    private static final String SYSTEM_PROMPT = """
//            你是"面试审查官"，目的是测试求职者的Java相关的能力。
//
//            要求：
//            1.提问Java相关的内容，不可超纲
//            2.不要说和回复与面试无关的内容
//            3.接收到求职者的开始信号后再出题
//            4.每次只问一题、根据回答追问
//            5.你公正严明，一丝不苟，求职者回答后会进行评判正确与否
//
//            """;
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
        conversation.setStatus(1);
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
    public void streamMessage(ChatRequestDTO dto, Long userId, Consumer<String> onChunk, Runnable onComplete) {
        log.info("[ChatServiceImpl] streamMessage called, conversationId={}, userId={}, message={}", 
                dto.getConversationId(), userId, dto.getMessage().substring(0, Math.min(30, dto.getMessage().length())));
        
        validateConversation(dto.getConversationId(), userId);

        saveUserMessageTransactional(dto.getConversationId(), dto.getMessage());
        log.info("[ChatServiceImpl] user message saved");
        
        List<ChatMessage> history = getMessageHistory(dto.getConversationId());
        log.info("[ChatServiceImpl] loaded {} history messages", history.size());
        
        StringBuilder fullReply = new StringBuilder();
        
        ChatClient chatClient = chatClientBuilder
                .defaultSystem(SYSTEM_PROMPT)
                .build();
        
        try {
            log.info("[ChatServiceImpl] starting AI streaming...");
            chatClient.prompt()
                    .messages(buildMessages(history, dto.getMessage()))
                    .stream()
                    .content()
                    .doOnNext(chunk -> {
                        log.info("[ChatServiceImpl] received AI chunk: {}", chunk);
                        fullReply.append(chunk);
                        onChunk.accept(chunk);
                    })
                    .doOnError(error -> {
                        log.error("[ChatServiceImpl] AI streaming error", error);
                    })
                    .doOnComplete(() -> {
                        log.info("[ChatServiceImpl] AI streaming completed, full reply length={}", fullReply.length());
                        saveAssistantMessageTransactional(dto.getConversationId(), fullReply.toString());
                        updateConversationUpdateTimeTransactional(dto.getConversationId());
                        onComplete.run();
                    })
                    .onErrorComplete()
                    .blockLast();
        } catch (Exception e) {
            log.error("[ChatServiceImpl] AI streaming failed", e);
            onComplete.run();
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

    @Override
    @Transactional
    public void deleteConversation(Long conversationId, Long userId) {
        validateConversation(conversationId, userId);
        messageMapper.deleteByConversationId(conversationId);
        conversationMapper.deleteById(conversationId);
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

    @Transactional
    public void saveUserMessageTransactional(Long conversationId, String content) {
        saveUserMessage(conversationId, content);
    }

    @Transactional
    public void saveAssistantMessageTransactional(Long conversationId, String content) {
        saveAssistantMessage(conversationId, content);
    }

    @Transactional
    public void updateConversationUpdateTimeTransactional(Long conversationId) {
        updateConversationUpdateTime(conversationId);
    }
}
