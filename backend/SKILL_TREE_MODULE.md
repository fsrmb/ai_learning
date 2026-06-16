# 技能树管理模块 - 开发文档

## 📋 模块概述

技能树管理模块用于管理和展示学习路径的技能树结构，支持树形节点的增删改查操作。

## 🏗️ 架构设计

### 核心概念

1. **技能树（SkillTree）**：代表一个完整的学习路径或技能体系
2. **技能节点（SkillNode）**：技能树中的具体节点，支持树形结构

### 节点类型

- **SKILL**：技能点，需要学习和掌握的具体技能
- **CHECKPOINT**：检查点，阶段性目标或里程碑
- **REWARD**：奖励节点，完成特定条件后获得的奖励

## 📁 文件结构

```
backend/src/main/java/com/aicompanion/
├── model/
│   ├── entity/
│   │   ├── SkillTree.java          # 技能树实体
│   │   └── SkillNode.java          # 技能节点实体
│   ├── dto/
│   │   ├── SkillTreeDTO.java       # 技能树 DTO
│   │   └── SkillNodeDTO.java       # 技能节点 DTO
│   └── vo/
│       ├── SkillTreeVO.java        # 技能树 VO（包含节点树）
│       └── SkillNodeVO.java        # 技能节点 VO（树形结构）
├── mapper/
│   ├── SkillTreeMapper.java        # 技能树 Mapper
│   └── SkillNodeMapper.java        # 技能节点 Mapper
├── service/
│   ├── SkillTreeService.java       # 服务接口
│   └── impl/
│       └── SkillTreeServiceImpl.java  # 服务实现
└── controller/
    └── SkillTreeController.java    # 控制器

backend/sql/
└── skill_tree.sql                  # 建表 SQL
```

## 🗄️ 数据库设计

### 技能树表（skill_tree）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键ID |
| name | VARCHAR(100) | 技能树名称 |
| description | TEXT | 技能树描述 |
| icon | VARCHAR(255) | 图标URL |
| category | VARCHAR(50) | 分类（编程、设计、语言等） |
| difficulty_level | TINYINT | 难度等级（1-5） |
| status | TINYINT | 状态：0禁用/1正常 |
| sort_order | INT | 排序 |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |

### 技能节点表（skill_node）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键ID |
| tree_id | BIGINT | 技能树ID（外键） |
| parent_id | BIGINT | 父节点ID（0表示根节点） |
| name | VARCHAR(100) | 节点名称 |
| description | TEXT | 节点描述 |
| node_type | VARCHAR(20) | 节点类型：SKILL/CHECKPOINT/REWARD |
| required_exp | INT | 所需经验值 |
| unlock_condition | TEXT | 解锁条件描述 |
| reward | TEXT | 奖励内容（JSON格式） |
| icon | VARCHAR(255) | 图标URL |
| status | TINYINT | 状态：0禁用/1正常 |
| sort_order | INT | 排序 |
| create_time | DATETIME | 创建时间 |
| update_time | DATETIME | 更新时间 |

## 🔌 API 接口

### 技能树管理

#### 1. 创建技能树
- **URL**: `POST /api/skill-trees`
- **请求体**:
```json
{
  "name": "Java 开发技能树",
  "description": "从入门到精通的 Java 学习路径",
  "icon": "/icons/java.png",
  "category": "编程",
  "difficultyLevel": 3,
  "status": 1,
  "sortOrder": 1
}
```
- **响应**:
```json
{
  "code": 200,
  "message": "创建成功",
  "data": 1
}
```

#### 2. 更新技能树
- **URL**: `PUT /api/skill-trees/{id}`
- **请求体**: 同创建接口
- **响应**:
```json
{
  "code": 200,
  "message": "更新成功",
  "data": null
}
```

#### 3. 删除技能树
- **URL**: `DELETE /api/skill-trees/{id}`
- **响应**:
```json
{
  "code": 200,
  "message": "删除成功",
  "data": null
}
```
- **注意**: 会级联删除该技能树下的所有节点

#### 4. 获取技能树详情
- **URL**: `GET /api/skill-trees/{id}`
- **响应**:
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 1,
    "name": "Java 开发技能树",
    "description": "从入门到精通的 Java 学习路径",
    "icon": "/icons/java.png",
    "category": "编程",
    "difficultyLevel": 3,
    "status": 1,
    "sortOrder": 1,
    "createTime": "2026-06-14T10:00:00",
    "updateTime": "2026-06-14T10:00:00",
    "nodes": [
      {
        "id": 1,
        "treeId": 1,
        "parentId": 0,
        "name": "Java 基础",
        "nodeType": "CHECKPOINT",
        "children": [
          {
            "id": 2,
            "name": "变量与数据类型",
            "nodeType": "SKILL",
            "requiredExp": 100,
            "children": []
          }
        ]
      }
    ]
  }
}
```

#### 5. 获取技能树列表
- **URL**: `GET /api/skill-trees?category=编程`
- **参数**: 
  - `category`（可选）：按分类筛选
- **响应**: 返回技能树列表（不包含节点）

### 技能节点管理

#### 6. 创建技能节点
- **URL**: `POST /api/skill-trees/nodes`
- **请求体**:
```json
{
  "treeId": 1,
  "parentId": 0,
  "name": "Java 基础",
  "description": "掌握 Java 核心语法",
  "nodeType": "CHECKPOINT",
  "requiredExp": 0,
  "unlockCondition": "无",
  "icon": "/icons/java-basic.png",
  "status": 1,
  "sortOrder": 1
}
```

#### 7. 更新技能节点
- **URL**: `PUT /api/skill-trees/nodes/{id}`
- **请求体**: 同创建接口

#### 8. 删除技能节点
- **URL**: `DELETE /api/skill-trees/nodes/{id}`
- **注意**: 会递归删除所有子节点

#### 9. 获取技能树的节点树
- **URL**: `GET /api/skill-trees/{treeId}/nodes`
- **响应**: 返回完整的树形结构

## 💡 核心功能

### 1. 树形结构构建

Service 层实现了递归算法来构建树形结构：

```java
private List<SkillNodeVO> buildTree(List<SkillNodeVO> allNodes, Long parentId) {
    return allNodes.stream()
            .filter(node -> node.getParentId().equals(parentId))
            .peek(node -> {
                List<SkillNodeVO> children = buildTree(allNodes, node.getId());
                node.setChildren(children);
            })
            .collect(Collectors.toList());
}
```

### 2. 级联删除

删除技能树或节点时，会自动删除关联的子节点：

```java
private void deleteChildNodes(Long parentId) {
    List<SkillNode> childNodes = skillNodeMapper.selectList(
            new LambdaQueryWrapper<SkillNode>()
                    .eq(SkillNode::getParentId, parentId)
    );
    for (SkillNode child : childNodes) {
        deleteChildNodes(child.getId());
        skillNodeMapper.deleteById(child.getId());
    }
}
```

### 3. 数据校验

使用 Jakarta Validation 进行参数校验：
- `@NotBlank`: 必填字符串字段
- `@NotNull`: 必填对象字段

## 🚀 部署步骤

### 1. 执行建表 SQL

```bash
mysql -u root -p < backend/sql/skill_tree.sql
```

或在 MySQL 客户端中执行 `skill_tree.sql` 文件。

### 2. 重启后端服务

```bash
cd backend
mvn spring-boot:run
```

### 3. 测试接口

使用 Postman 或 curl 测试 API 接口。

## 📝 示例数据

SQL 文件中包含了示例数据：
- 3 个技能树（Java、前端、Python）
- Java 技能树的完整节点结构

可以直接使用这些数据进行测试。

## ⚠️ 注意事项

1. **Lombok 问题**: 如果 IDE 显示 Lombok 相关错误，请刷新 Maven 依赖或重启 IDEA
2. **外键约束**: 删除技能树时会级联删除节点（ON DELETE CASCADE）
3. **树形结构**: parentId 为 0 表示根节点
4. **事务管理**: 所有写操作都使用了 `@Transactional` 保证数据一致性

## 🔍 扩展建议

1. **用户进度追踪**: 添加用户技能节点完成状态表
2. **前置依赖**: 添加节点之间的依赖关系（需要先完成 A 才能解锁 B）
3. **成就系统**: 基于技能节点完成情况发放成就
4. **推荐算法**: 根据用户已完成的节点推荐下一个学习目标
5. **可视化编辑器**: 前端提供拖拽式技能树编辑器

## 📊 性能优化

1. **索引优化**: 已为常用查询字段添加索引
2. **缓存**: 可以考虑使用 Redis 缓存技能树结构
3. **懒加载**: 获取列表时不加载节点，详情时才加载
4. **分页**: 如果节点数量很大，考虑分页查询
