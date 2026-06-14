package com.aicompanion.model.dto;

import jakarta.validation.constraints.Email;
import lombok.Data;

/**
 * 用户信息更新 DTO
 */
@Data
public class UserDTO {
    
    private String nickname;
    
    @Email(message = "邮箱格式不正确")
    private String email;
    
    private String phone;
    
    private String avatar;
}
