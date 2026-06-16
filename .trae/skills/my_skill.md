---
name: my-skill
description: 创建完整的 Spring Boot 业务模块
globs: []
alwaysApply: false
---

# 创建新业务模块的步骤

1. 创建 Entity（继承 BaseEntity）
2. 创建 DTO（带 @Valid）和 VO
3. 创建 Mapper（继承 BaseMapper）
4. 创建 Service 接口和实现
5. 创建 Controller（带 Swagger 注解）
6. 编写建表 SQL
7. 用 Postman 测试

## 参考
- 参考 UserController 的写法
- 参考 UserServiceImpl 的写法