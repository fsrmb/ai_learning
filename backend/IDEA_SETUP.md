# IntelliJ IDEA 配置指南

## ❗ 重要：项目重构后需要重新配置

由于代码已从 `d:\ai_learning\` 移动到 `d:\ai_learning\backend\`，需要更新 IDEA 配置。

---

## 🔧 方法 1：重新导入项目（推荐）

### 步骤：

1. **关闭当前项目**
   - File → Close Project

2. **重新打开 backend 目录**
   - File → Open
   - 选择 `d:\ai_learning\backend` 目录
   - IDEA 会自动识别为 Maven 项目

3. **等待 Maven 导入完成**
   - 右下角会显示 "Importing Maven projects"
   - 等待导入完成

4. **配置运行配置**
   - 点击右上角 "Add Configuration..."
   - 点击 "+" → Spring Boot
   - 配置如下：
     - Name: AiCompanionApplication
     - Main class: com.aicompanion.AiCompanionApplication
     - Working directory: `d:\ai_learning\backend`
     - Use classpath of module: ai-companion

5. **运行项目**
   - 点击绿色运行按钮

---

## 🔧 方法 2：修改现有配置

如果不想重新导入项目，可以修改现有配置：

### 步骤：

1. **打开运行配置**
   - 点击右上角的运行配置下拉菜单
   - 选择 "Edit Configurations..."

2. **修改 Working directory**
   - 找到你的 Spring Boot 配置
   - 将 "Working directory" 改为：
     ```
     d:\ai_learning\backend
     ```

3. **检查 Module classpath**
   - 确保 "Use classpath of module" 选择的是正确的模块
   - 应该是 `ai-companion`

4. **应用并保存**
   - 点击 "Apply" → "OK"

5. **重新构建项目**
   - Build → Rebuild Project (Ctrl+Shift+F9)

6. **运行项目**

---

## 🔧 方法 3：使用命令行启动

如果 IDEA 配置有问题，可以使用命令行：

### Windows PowerShell：

```powershell
cd d:\ai_learning\backend
mvn spring-boot:run
```

### Windows CMD：

```cmd
cd /d d:\ai_learning\backend
mvn spring-boot:run
```

### 使用提供的脚本：

双击运行 `d:\ai_learning\backend\start.bat`

---

## ⚠️ 常见问题

### 问题 1：找不到主类

**错误信息：**
```
错误: 找不到或无法加载主类 com.aicompanion.AiCompanionApplication
```

**解决方案：**
- 确保 Working directory 设置为 `d:\ai_learning\backend`
- 执行 Build → Rebuild Project
- 检查 src/main/java 目录结构是否正确

### 问题 2：Maven 依赖未下载

**解决方案：**
- 右侧 Maven 面板 → 点击刷新按钮 🔄
- 或者右键 pom.xml → Maven → Reload project

### 问题 3：端口被占用

**错误信息：**
```
Web server failed to start. Port 8080 was already in use.
```

**解决方案：**
- 修改 `src/main/resources/application.yml` 中的端口
- 或者停止占用 8080 端口的程序

---

## ✅ 验证配置是否正确

启动成功后，应该看到类似输出：

```
Started AiCompanionApplication in X.XXX seconds
```

然后在浏览器访问：
- http://localhost:8080/api/test/hello

应该返回：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": "Hello, Spring Boot is running!"
}
```

---

## 📝 项目结构确认

确保目录结构如下：

```
backend/
├── pom.xml
├── src/
│   └── main/
│       ├── java/com/aicompanion/
│       │   ├── AiCompanionApplication.java  ← 主启动类
│       │   ├── model/
│       │   ├── controller/
│       │   ├── service/
│       │   └── ...
│       └── resources/
│           └── application.yml
```

---

## 🆘 仍然有问题？

1. **清理 Maven 缓存**
   ```bash
   mvn clean
   mvn compile
   ```

2. **删除 IDEA 缓存**
   - File → Invalidate Caches / Restart
   - 选择 "Invalidate and Restart"

3. **检查 JDK 配置**
   - File → Project Structure → Project
   - 确保 SDK 是 Java 17

4. **查看完整日志**
   - Run → Show Log in Explorer
   - 查看 idea.log 文件
