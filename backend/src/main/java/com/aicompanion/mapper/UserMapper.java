package com.aicompanion.mapper;

import com.aicompanion.model.entity.User;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 用户 Mapper
 */
@Mapper
public interface UserMapper extends BaseMapper<User> {

    /**
     * 搜索用户 - 支持按角色筛选 + 关键词模糊搜索
     * @param role 角色（可选）
     * @param keyword 关键词（可选），匹配 username 或 nickname
     * @return 用户列表
     */
    List<User> searchUsers(@Param("role") String role, @Param("keyword") String keyword);
}
