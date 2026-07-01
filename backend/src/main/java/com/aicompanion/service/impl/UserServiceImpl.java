package com.aicompanion.service.impl;

import com.aicompanion.model.entity.User;
import com.aicompanion.model.dto.LoginDTO;
import com.aicompanion.model.dto.RegisterDTO;
import com.aicompanion.model.dto.UserDTO;
import com.aicompanion.common.exception.BusinessException;
import com.aicompanion.mapper.UserMapper;
import com.aicompanion.service.UserService;
import com.aicompanion.common.util.JwtUtil;
import com.aicompanion.model.vo.LoginVO;
import com.aicompanion.model.vo.PageResult;
import com.aicompanion.model.vo.UserVO;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.BeanUtils;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 用户服务实现类
 */
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
    
    private final UserMapper userMapper;
    private final JwtUtil jwtUtil;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    
    private String getTokenFromRequest() {
        HttpServletRequest request = ((ServletRequestAttributes) RequestContextHolder.getRequestAttributes()).getRequest();
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            return authHeader.substring(7);
        }
        return null;
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void register(RegisterDTO registerDTO) {
        register(registerDTO, "ADMIN");
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void register(RegisterDTO registerDTO, String role) {
        LambdaQueryWrapper<User> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(User::getUsername, registerDTO.getUsername());
        if (userMapper.selectCount(queryWrapper) > 0) {
            throw new BusinessException("用户名已存在");
        }
        if (registerDTO.getPassword() == null || registerDTO.getPassword().length() < 6) {
            throw new BusinessException(400, "密码长度不能少于6位");
        }
        User user = new User();
        BeanUtils.copyProperties(registerDTO, user);
        user.setPassword(passwordEncoder.encode(registerDTO.getPassword()));
        
        if (registerDTO.getNickname() == null || registerDTO.getNickname().isEmpty()) {
            user.setNickname(registerDTO.getUsername());
        }
        
        user.setRole(role != null ? role : "STUDENT");
        user.setStatus(1);
        userMapper.insert(user);
    }
    
    @Override
    @Transactional(rollbackFor = Exception.class)
    public LoginVO login(LoginDTO loginDTO) {
        LambdaQueryWrapper<User> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(User::getUsername, loginDTO.getUsername());
        User user = userMapper.selectOne(queryWrapper);
        
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        
        if (user.getDeleted() == 1) {
            throw new BusinessException("用户已被删除");
        }
        
        String storedPassword = user.getPassword();
        boolean passwordMatches = false;
        
        if (storedPassword != null && storedPassword.startsWith("$2a$")) {
            passwordMatches = passwordEncoder.matches(loginDTO.getPassword(), storedPassword);
        } else {
            passwordMatches = loginDTO.getPassword().equals(storedPassword);
            if (passwordMatches) {
                user.setPassword(passwordEncoder.encode(loginDTO.getPassword()));
                userMapper.updateById(user);
            }
        }
        
        if (!passwordMatches) {
            throw new BusinessException("用户名或密码错误");
        }
        
        if (user.getStatus() == 0) {
            throw new BusinessException("账号已被禁用");
        }
        
        String token = jwtUtil.generateToken(user.getId(), user.getUsername());
        
        LoginVO loginVO = new LoginVO();
        loginVO.setToken(token);
        loginVO.setUser(convertToUserVO(user));
        
        return loginVO;
    }
    
    @Override
    public UserVO getById(Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        return convertToUserVO(user);
    }

    @Override
    public UserVO getCurrentUser() {
        String token = getTokenFromRequest();
        if (token == null) {
            throw new BusinessException(401, "未登录");
        }
        
        try {
            Long userId = jwtUtil.getUserIdFromToken(token);
            User user = userMapper.selectById(userId);
            if (user == null) {
                throw new BusinessException(401, "用户不存在");
            }
            return convertToUserVO(user);
        } catch (Exception e) {
            throw new BusinessException(401, "Token 无效");
        }
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
        
        String originalPassword = user.getPassword();
        BeanUtils.copyProperties(userDTO, user);
        user.setId(userId);
        if (userDTO.getPassword() == null || userDTO.getPassword().isEmpty()) {
            user.setPassword(originalPassword);
        } else {
            user.setPassword(passwordEncoder.encode(userDTO.getPassword()));
        }
        
        userMapper.updateById(user);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void createUser(UserDTO userDTO) {
        LambdaQueryWrapper<User> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(User::getUsername, userDTO.getUsername());
        if (userMapper.selectCount(queryWrapper) > 0) {
            throw new BusinessException("用户名已存在");
        }
        
        User user = new User();
        BeanUtils.copyProperties(userDTO, user);
        
        if (userDTO.getPassword() != null && !userDTO.getPassword().isEmpty()) {
            user.setPassword(passwordEncoder.encode(userDTO.getPassword()));
        }
        
        if (user.getRole() == null) {
            user.setRole("STUDENT");
        }
        if (user.getStatus() == null) {
            user.setStatus(1);
        }
        
        userMapper.insert(user);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteUser(Long userId) {
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        
        userMapper.deleteById(userId);
    }
    
    private UserVO convertToUserVO(User user) {
        UserVO userVO = new UserVO();
        BeanUtils.copyProperties(user, userVO);
        return userVO;
    }

    @Override
    public List<UserVO> searchUsers(String role, String keyword) {
        List<User> users = userMapper.searchUsers(role, keyword);
        return users.stream().map(this::convertToUserVO).collect(Collectors.toList());
    }

    @Override
    public PageResult<UserVO> searchUsers(String role, String keyword, Integer page, Integer size) {
        LambdaQueryWrapper<User> queryWrapper = new LambdaQueryWrapper<>();
        
        if (role != null && !role.isEmpty()) {
            queryWrapper.eq(User::getRole, role);
        }
        
        if (keyword != null && !keyword.isEmpty()) {
            queryWrapper.and(wrapper -> wrapper
                    .like(User::getUsername, keyword)
                    .or()
                    .like(User::getNickname, keyword));
        }
        
        queryWrapper.eq(User::getDeleted, 0);
        queryWrapper.orderByAsc(User::getId);
        
        Long total = userMapper.selectCount(queryWrapper);
        
        int start = (page - 1) * size;
        List<User> users = userMapper.selectList(queryWrapper.last("LIMIT " + start + ", " + size));
        
        List<UserVO> userVOList = users.stream().map(this::convertToUserVO).collect(Collectors.toList());
        
        return PageResult.of(userVOList, total, page, size);
    }
}
