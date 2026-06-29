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
