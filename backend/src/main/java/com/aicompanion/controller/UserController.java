package com.aicompanion.controller;
import com.aicompanion.model.entity.User;
import com.aicompanion.common.response.Result;
import com.aicompanion.model.dto.UserDTO;
import com.aicompanion.service.UserService;
import com.aicompanion.model.vo.PageResult;
import com.aicompanion.model.vo.UserVO;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 用户控制器
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    @Autowired
    private UserService userService;

    @GetMapping("/me")
    public Result<UserVO> getCurrentUser() {
        UserVO user = userService.getCurrentUser();
        return Result.success(user);
    }
    
    /**
     * 更新当前用户信息（移动端专用，只允许修改自己的昵称、邮箱、手机号等基础信息）
     */
    @PutMapping("/me")
    public Result<Void> updateCurrentUser(@RequestBody UserDTO userDTO) {
        UserVO currentUser = userService.getCurrentUser();
        userDTO.setRole(null);
        userDTO.setPassword(null);
        userService.updateUser(currentUser.getId(), userDTO);
        return Result.success("更新成功", null);
    }

    @GetMapping("/{id}")
    public Result<UserVO> getUser(@PathVariable Long id) {
        UserVO user = userService.getById(id);
        return Result.success(user);
    }

    @GetMapping
    public Result<PageResult<UserVO>> searchUsers(
            @RequestParam(required = false) String role,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer size) {
        PageResult<UserVO> pageResult = userService.searchUsers(role, keyword, page, size);
        return Result.success(pageResult);
    }

    @PostMapping
    public Result<Void> createUser(@Valid @RequestBody UserDTO userDTO) {
        userService.createUser(userDTO);
        return Result.success("创建成功", null);
    }

    @PutMapping("/{id}")
    public Result<Void> updateUser(@PathVariable Long id, @Valid @RequestBody UserDTO userDTO) {
        userService.updateUser(id, userDTO);
        return Result.success("更新成功", null);
    }

    @DeleteMapping("/{id}")
    public Result<Void> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);
        return Result.success("删除成功", null);
    }
}
