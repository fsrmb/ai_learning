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
     * 用户注册
     */
    @PostMapping("/register")
    public Result<Long> register(@Valid @RequestBody RegisterDTO registerDTO) {
        //userService.register(registerDTO);
        Long userID=1L;
        return Result.success("注册成功", userID);
    }
    
    /**
     * 用户登录
     */
     @PostMapping("/login")
     public Result<LoginVO> login(@Valid @RequestBody LoginDTO loginDTO) {
         //LoginVO loginVO = userService.login(loginDTO);
         String testname="admin";
         String testpassword="123456";


         if(testpassword.equals(loginDTO.getPassword())&&testname.equals(loginDTO.getUsername())){
             LoginVO loginVO=new LoginVO();
             loginVO.setToken("test-token-" + System.currentTimeMillis());

             UserVO userVO=new UserVO();
             userVO.setId(1L);
             userVO.setUsername(testname);
             userVO.setNickname(testname);
             userVO.setRole("user");
             loginVO.setUser(userVO);
             return Result.success("登录成功",loginVO);
         }
         return Result.error("用户名或密码错误");
     }
//    @PostMapping("/login")
//    public Result<Long> login(@Valid @RequestBody LoginDTO loginDTO) {
//        //LoginVO loginVO = userService.login(loginDTO);
//        //return Result.success(loginVO);
//        Long userID=1L;
//        return Result.success("登录成功", userID);
//    }
}
