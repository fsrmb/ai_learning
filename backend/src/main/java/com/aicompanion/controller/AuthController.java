package com.aicompanion.controller;

import com.aicompanion.common.response.Result;
import com.aicompanion.model.dto.LoginDTO;
import com.aicompanion.model.dto.RegisterDTO;
import com.aicompanion.model.vo.UserVO;
import com.aicompanion.service.UserService;
import com.aicompanion.model.vo.LoginVO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 认证控制器
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {
    
    private final UserService userService;
    
    /**
     * 用户注册（管理后台，角色默认为 ADMIN）
     */
    @PostMapping("/register")
    public Result<Long> register(@Valid @RequestBody RegisterDTO registerDTO) {
        userService.register(registerDTO);
        return Result.success("注册成功", null);
    }
    
    /**
     * 用户登录
     */
    @PostMapping("/login")
    public Result<LoginVO> login(@Valid @RequestBody LoginDTO loginDTO) {
        LoginVO loginVO = userService.login(loginDTO);
        return Result.success("登录成功", loginVO);
    }
    
    /**
     * 移动端用户注册（角色默认为 STUDENT，与管理后台用户区分）
     */
    @PostMapping("/app/register")
    public Result<Long> appRegister(@Valid @RequestBody RegisterDTO registerDTO) {
        userService.register(registerDTO, "STUDENT");
        return Result.success("注册成功", null);
    }
}
