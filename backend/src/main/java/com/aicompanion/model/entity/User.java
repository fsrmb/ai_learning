package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("sys_user")           // ① 指定表名
public class User extends BaseEntity {
    private String username;
    private String password;
    private String nickname;
    private String email;
    private String role;
    private Integer status;
    // id、createTime、updateTime、deleted 自动继承
}