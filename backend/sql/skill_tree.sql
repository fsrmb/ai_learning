-- ============================================
-- 技能树管理模块 - 建表 SQL
-- ============================================

USE ai_companion;

-- 技能树表
CREATE TABLE IF NOT EXISTS skill_tree (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    name VARCHAR(100) NOT NULL COMMENT '技能树名称',
    description TEXT COMMENT '技能树描述',
    icon VARCHAR(255) COMMENT '图标URL',
    category VARCHAR(50) NOT NULL COMMENT '分类（编程、设计、语言等）',
    difficulty_level TINYINT DEFAULT 1 COMMENT '难度等级（1-5）',
    status TINYINT DEFAULT 1 COMMENT '状态：0禁用/1正常',
    sort_order INT DEFAULT 0 COMMENT '排序',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    KEY idx_category (category),
    KEY idx_status (status),
    KEY idx_sort_order (sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='技能树表';

-- 技能节点表
CREATE TABLE IF NOT EXISTS skill_node (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    tree_id BIGINT NOT NULL COMMENT '技能树ID',
    parent_id BIGINT DEFAULT 0 COMMENT '父节点ID（0表示根节点）',
    name VARCHAR(100) NOT NULL COMMENT '节点名称',
    description TEXT COMMENT '节点描述',
    node_type VARCHAR(20) NOT NULL COMMENT '节点类型：SKILL(技能点)、CHECKPOINT(检查点)、REWARD(奖励)',
    required_exp INT DEFAULT 0 COMMENT '所需经验值',
    unlock_condition TEXT COMMENT '解锁条件描述',
    reward TEXT COMMENT '奖励内容（JSON格式）',
    icon VARCHAR(255) COMMENT '图标URL',
    status TINYINT DEFAULT 1 COMMENT '状态：0禁用/1正常',
    sort_order INT DEFAULT 0 COMMENT '排序',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    KEY idx_tree_id (tree_id),
    KEY idx_parent_id (parent_id),
    KEY idx_node_type (node_type),
    KEY idx_status (status),
    CONSTRAINT fk_skill_node_tree FOREIGN KEY (tree_id) REFERENCES skill_tree(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='技能节点表';

-- 插入示例数据
INSERT INTO skill_tree (name, description, icon, category, difficulty_level, status, sort_order) VALUES
('Java 开发技能树', '从入门到精通的 Java 学习路径', '/icons/java.png', '编程', 3, 1, 1),
('前端开发技能树', '现代 Web 前端技术栈', '/icons/frontend.png', '编程', 2, 1, 2),
('Python 数据分析', 'Python 数据处理与可视化', '/icons/python.png', '编程', 2, 1, 3);

-- 插入 Java 技能树的示例节点
INSERT INTO skill_node (tree_id, parent_id, name, description, node_type, required_exp, unlock_condition, icon, status, sort_order) VALUES
(1, 0, 'Java 基础', '掌握 Java 核心语法和面向对象编程', 'CHECKPOINT', 0, '无', '/icons/java-basic.png', 1, 1),
(1, 1, '变量与数据类型', '理解 Java 的基本数据类型和变量声明', 'SKILL', 100, '开始学习', '/icons/variable.png', 1, 1),
(1, 1, '控制流程', '掌握 if-else、switch、循环等控制结构', 'SKILL', 150, '完成变量学习', '/icons/control-flow.png', 1, 2),
(1, 1, '面向对象', '理解类、对象、继承、多态等概念', 'SKILL', 200, '完成控制流程学习', '/icons/oop.png', 1, 3),
(1, 0, 'Java 进阶', '深入学习 Java 高级特性', 'CHECKPOINT', 500, '完成 Java 基础', '/icons/java-advanced.png', 1, 2),
(1, 5, '集合框架', '掌握 List、Set、Map 等集合类', 'SKILL', 300, '进入进阶阶段', '/icons/collection.png', 1, 1),
(1, 5, '多线程', '理解线程、并发编程', 'SKILL', 400, '完成集合学习', '/icons/thread.png', 1, 2),
(1, 5, 'IO 流', '掌握文件读写和网络编程', 'SKILL', 350, '完成集合学习', '/icons/io.png', 1, 3),
(1, 0, '框架学习', '学习主流 Java 框架', 'REWARD', 1000, '完成进阶阶段', '/icons/framework.png', 1, 3);
