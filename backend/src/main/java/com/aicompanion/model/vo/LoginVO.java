package com.aicompanion.model.vo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 登录 VO
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class LoginVO {
    
    private String token;
    private UserVO user;
}
