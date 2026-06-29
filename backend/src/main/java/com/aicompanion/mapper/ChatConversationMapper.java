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
