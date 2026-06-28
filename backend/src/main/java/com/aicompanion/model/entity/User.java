package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

/**
 * 用户实体类
 */
@Data
@TableName("sys_user")
public class User extends BaseEntity {
    
    /**
     * 用户名
     */
    private String username;
    
    /**
     * 加密密码
     */
    private String password;
    
    /**
     * 昵称
     */
    private String nickname;
    
    /**
     * 邮箱
     */
    private String email;
    
    /**
     * 手机号
     */
    private String phone;
    
    /**
     * 头像URL
     */
    private String avatar;
    
    /**
     * 角色：STUDENT/TEACHER/ADMIN
     */
    private String role;
    
    /**
     * 状态：0禁用/1正常
     */
    private Integer status;
    // id、createTime、updateTime、deleted 自动继承
}