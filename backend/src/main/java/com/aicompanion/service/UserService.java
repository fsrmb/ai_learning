package com.aicompanion.service;

import com.aicompanion.model.dto.LoginDTO;
import com.aicompanion.model.dto.RegisterDTO;
import com.aicompanion.model.dto.UserDTO;
import com.aicompanion.model.vo.LoginVO;
import com.aicompanion.model.vo.UserVO;

/**
 * 用户服务接口
 */
public interface UserService {
    
    /**
     * 用户注册
     */
    void register(RegisterDTO registerDTO);
    
    /**
     * 用户登录
     */
    LoginVO login(LoginDTO loginDTO);
    
    /**
     * 获取用户信息
     */
    UserVO getUserInfo(Long userId);
    
    /**
     * 更新用户信息
     */
    void updateUser(Long userId, UserDTO userDTO);
}
