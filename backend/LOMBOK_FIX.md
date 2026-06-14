# Lombok JDK 17 兼容性修复指南

## ❗ 问题描述

```
java: java.lang.ExceptionInInitializerError
com.sun.tools.javac.code.TypeTag :: UNKNOWN
```

这个错误是因为 **Lombok 版本与 JDK 17 不兼容**导致的。

## ✅ 已完成的修复

已在 `pom.xml` 中将 Lombok 版本升级到 **1.18.34**（支持 JDK 17+）：

```xml
<properties>
    <lombok.version>1.18.34</lombok.version>
</properties>

<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <version>${lombok.version}</version>
    <optional>true</optional>
</dependency>
```

## 🔧 下一步操作

### 方法 1：在 IntelliJ IDEA 中刷新 Maven（推荐）

1. **打开 Maven 工具窗口**
   - 右侧边栏 → Maven
   
2. **刷新项目**
   - 点击刷新按钮 🔄 (Reload All Maven Projects)
   
3. **等待依赖下载完成**

4. **重新构建项目**
   - Build → Rebuild Project

5. **运行项目**

### 方法 2：使用命令行

```powershell
cd D:\ai_learning\backend
mvn clean install
```

如果 Maven 不在 PATH 中，可以使用 IDEA 内置的 Maven：
- 右键点击 `pom.xml` → Maven → Reload Project

### 方法 3：清除缓存并重启

如果刷新后仍有问题：

1. **File → Invalidate Caches / Restart**
2. 选择 "Invalidate and Restart"
3. 等待 IDEA 重启并重新索引

## 📝 版本说明

| 组件 | 版本 | 说明 |
|------|------|------|
| JDK | 17 | Java 开发工具包 |
| Spring Boot | 3.2.0 | Spring 框架 |
| Lombok | 1.18.34 | 代码生成工具（已升级） |
| MyBatis-Plus | 3.5.5 | ORM 框架 |

Lombok 1.18.34 完全支持 JDK 17 和 JDK 21。

## ⚠️ 常见问题

### Q: 为什么会出现这个错误？

A: Lombok 通过修改编译器内部类来工作。JDK 更新后，内部类的结构可能发生变化，导致旧版本的 Lombok 无法正常工作。

### Q: 升级 Lombok 会影响现有代码吗？

A: 不会。Lombok 向后兼容，升级版本不会影响已有的注解使用（@Data、@Builder 等）。

### Q: 如果还有问题怎么办？

A: 可以尝试：
1. 删除 `.idea` 文件夹和 `*.iml` 文件
2. 重新导入项目
3. 确保 IDEA 使用的是正确的 JDK 版本

## 🎯 验证修复

编译成功后，应该看到：

```
[INFO] BUILD SUCCESS
[INFO] Total time: XX.XXX s
```

然后可以正常运行 Spring Boot 应用了！
