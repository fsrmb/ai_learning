package com.aicompanion.service.arkts;

import com.aicompanion.model.dto.ChatRequestDTO;
import com.aicompanion.model.dto.CreateConversationDTO;
import com.aicompanion.model.vo.arkts.ChatResponseVO;
import com.aicompanion.model.vo.arkts.ConversationVO;
import com.aicompanion.model.vo.arkts.MessageVO;

import java.util.List;
import java.util.function.Consumer;

public interface ChatService {
    ConversationVO createConversation(CreateConversationDTO dto, Long userId);
    
    ChatResponseVO sendMessage(ChatRequestDTO dto, Long userId);
    
    void streamMessage(ChatRequestDTO dto, Long userId, Consumer<String> onChunk, Runnable onComplete);
    
    List<MessageVO> getMessageHistory(Long conversationId, Long userId, Integer page, Integer size);
    
    List<ConversationVO> getConversations(Long userId);
    
    void deleteConversation(Long conversationId, Long userId);
}
