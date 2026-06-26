package com.aicompanion.model.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 用户信息更新 DTO
 */
@Data
public class UserDTO {
    
    @NotBlank(message = "用户名不能为空")
    private String username;
    
    private String password;
    
    private String nickname;
    
    @Email(message = "邮箱格式不正确")
    private String email;
    
    private String phone;
    
    private String avatar;
    
    private String role;
    
    private Integer status;
}
