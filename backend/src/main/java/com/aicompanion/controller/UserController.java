package com.aicompanion.controller;
import com.aicompanion.model.entity.User;
import com.aicompanion.common.response.Result;
import com.aicompanion.model.dto.UserDTO;
import com.aicompanion.service.UserService;
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

    @GetMapping("/{id}")
    public Result<User> getUser(@PathVariable Long id) {
        User user = userService.getById(id);
        return Result.success(user);
    }

    @GetMapping
    public Result<List<User>> searchUsers(
            @RequestParam(required = false) String role,
            @RequestParam(required = false) String keyword) {
        List<User> list = userService.searchUsers(role, keyword);
        return Result.success(list);
    }

    @PostMapping
    public Result<Void> createUser(@RequestBody User user) {
        userService.save(user);
        return Result.success("创建成功", null);
    }
}
