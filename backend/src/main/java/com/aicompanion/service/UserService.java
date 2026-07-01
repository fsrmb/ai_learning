package com.aicompanion.service;

import com.aicompanion.model.dto.LoginDTO;
import com.aicompanion.model.dto.RegisterDTO;
import com.aicompanion.model.dto.UserDTO;
import com.aicompanion.model.vo.LoginVO;
import com.aicompanion.model.vo.PageResult;
import com.aicompanion.model.vo.UserVO;

import java.util.List;

/**
 * 用户服务接口
 */
public interface UserService {

    /**
     * 用户注册（默认 ADMIN 角色）
     */
    void register(RegisterDTO registerDTO);
    
    /**
     * 用户注册（指定角色）
     * @param registerDTO 注册信息
     * @param role 用户角色（ADMIN/STUDENT）
     */
    void register(RegisterDTO registerDTO, String role);

    /**
     * 用户登录
     */
    LoginVO login(LoginDTO loginDTO);

    /**
     * 获取当前登录用户信息
     */
    UserVO getCurrentUser();

    /**
     * 获取用户信息
     */
    UserVO getUserInfo(Long userId);

    /**
     * 更新用户信息
     */
    void updateUser(Long userId, UserDTO userDTO);

    /**
     * 根据 ID 获取用户
     */
    UserVO getById(Long id);

    /**
     * 搜索用户 - 支持按角色筛选 + 关键词模糊搜索
     * @param role 角色（可选）
     * @param keyword 关键词（可选），匹配 username 或 nickname
     * @return 用户列表
     */
    List<UserVO> searchUsers(String role, String keyword);

    /**
     * 搜索用户 - 分页版本
     * @param role 角色（可选）
     * @param keyword 关键词（可选），匹配 username 或 nickname
     * @param page 页码（从1开始）
     * @param size 每页大小
     * @return 分页结果
     */
    PageResult<UserVO> searchUsers(String role, String keyword, Integer page, Integer size);

    /**
     * 创建用户（管理后台）
     */
    void createUser(UserDTO userDTO);

    /**
     * 删除用户（逻辑删除）
     */
    void deleteUser(Long userId);
}
