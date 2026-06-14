package com.aicompanion.service.impl;

import com.aicompanion.model.dto.LoginDTO;
import com.aicompanion.model.dto.RegisterDTO;
import com.aicompanion.model.dto.UserDTO;
import com.aicompanion.model.entity.User;
import com.aicompanion.common.exception.BusinessException;
import com.aicompanion.mapper.UserMapper;
import com.aicompanion.service.UserService;
import com.aicompanion.common.util.JwtUtil;
import com.aicompanion.model.vo.LoginVO;
import com.aicompanion.model.vo.UserVO;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 用户服务实现类
 */
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
    
    private final UserMapper userMapper;
    private final JwtUtil jwtUtil;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void register(RegisterDTO registerDTO) {
        // 检查用户名是否已存在
        LambdaQueryWrapper<User> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(User::getUsername, registerDTO.getUsername());
        if (userMapper.selectCount(queryWrapper) > 0) {
            throw new BusinessException("用户名已存在");
        }
        
        // 创建用户
        User user = new User();
        BeanUtils.copyProperties(registerDTO, user);
        
        // 加密密码
        user.setPassword(passwordEncoder.encode(registerDTO.getPassword()));
        
        // 设置默认角色和状态
        user.setRole("STUDENT");
        user.setStatus(1);
        
        // 插入数据库
        userMapper.insert(user);
    }
    
    @Override
    public LoginVO login(LoginDTO loginDTO) {
        // 查询用户
        LambdaQueryWrapper<User> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(User::getUsername, loginDTO.getUsername());
        User user = userMapper.selectOne(queryWrapper);
        
        if (user == null) {
            throw new BusinessException("用户名或密码错误");
        }
        
        // 校验密码
        if (!passwordEncoder.matches(loginDTO.getPassword(), user.getPassword())) {
            throw new BusinessException("用户名或密码错误");
        }
        
        // 检查用户状态
        if (user.getStatus() == 0) {
            throw new BusinessException("账号已被禁用");
        }
        
        // 生成 JWT Token
        String token = jwtUtil.generateToken(user.getId(), user.getUsername());
        
        // 构建返回结果
        LoginVO loginVO = new LoginVO();
        loginVO.setToken(token);
        loginVO.setUser(convertToUserVO(user));
        
        return loginVO;
    }
    
    @Override
    public UserVO getUserInfo(Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        return convertToUserVO(user);
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateUser(Long userId, UserDTO userDTO) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        
        // 更新用户信息
        BeanUtils.copyProperties(userDTO, user);
        user.setId(userId); // 确保 ID 不被覆盖
        
        userMapper.updateById(user);
    }
    
    /**
     * 将 User 转换为 UserVO
     */
    private UserVO convertToUserVO(User user) {
        UserVO userVO = new UserVO();
        BeanUtils.copyProperties(user, userVO);
        return userVO;
    }
}
