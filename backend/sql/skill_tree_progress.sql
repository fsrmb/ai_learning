-- ============================================
-- 技能树进度追踪模块 - 建表 SQL
-- 创建时间: 2026-06-27
-- ============================================

USE ai_companion;

-- ============================================
-- 1. 用户技能进度表
-- ============================================
CREATE TABLE IF NOT EXISTS user_skill_progress (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    node_id BIGINT NOT NULL COMMENT '技能节点ID',
    
    -- 状态管理
    status VARCHAR(20) NOT NULL DEFAULT 'LOCKED' COMMENT '状态：LOCKED(锁定)/UNLOCKED(已解锁)/IN_PROGRESS(进行中)/COMPLETED(已完成)',
    
    -- 时间记录
    unlock_time DATETIME NULL COMMENT '解锁时间',
    start_time DATETIME NULL COMMENT '开始学习时间',
    complete_time DATETIME NULL COMMENT '完成时间',
    
    -- 学习数据
    study_duration INT DEFAULT 0 COMMENT '累计学习时长（秒）',
    
    -- 评估数据
    best_score DECIMAL(5,2) DEFAULT 0 COMMENT '最高得分',
    latest_score DECIMAL(5,2) DEFAULT 0 COMMENT '最新得分',
    attempt_count INT DEFAULT 0 COMMENT '尝试次数',
    pass_count INT DEFAULT 0 COMMENT '通过次数',
    
    -- 经验值
    exp_points INT DEFAULT 0 COMMENT '获得的经验值',
    
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    UNIQUE KEY uk_user_node (user_id, node_id),
    KEY idx_user_id (user_id),
    KEY idx_node_id (node_id),
    KEY idx_status (status),
    CONSTRAINT fk_progress_user FOREIGN KEY (user_id) REFERENCES sys_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_progress_node FOREIGN KEY (node_id) REFERENCES skill_node(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户技能进度表';

-- ============================================
-- 2. 题目库表
-- ============================================
CREATE TABLE IF NOT EXISTS skill_question (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    node_id BIGINT NOT NULL COMMENT '所属技能节点ID',
    
    -- 题目内容
    question_text TEXT NOT NULL COMMENT '题目内容',
    options_json JSON NOT NULL COMMENT '选项JSON数组，如["A. xxx", "B. xxx", ...]',
    correct_answer VARCHAR(10) NOT NULL COMMENT '正确答案，如"A"',
    explanation TEXT COMMENT '答案解析',
    
    -- 题目属性
    difficulty TINYINT DEFAULT 3 COMMENT '难度等级1-5',
    source VARCHAR(20) NOT NULL DEFAULT 'AI_GENERATED' COMMENT '来源：AI_GENERATED(AI生成)/MANUAL(人工录入)',
    
    -- 统计数据
    use_count INT DEFAULT 0 COMMENT '使用次数',
    correct_rate DECIMAL(5,2) DEFAULT 0 COMMENT '正确率统计',
    
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    
    KEY idx_node_id (node_id),
    KEY idx_difficulty (difficulty),
    KEY idx_source (source),
    CONSTRAINT fk_question_node FOREIGN KEY (node_id) REFERENCES skill_node(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='题目库表';

-- ============================================
-- 3. 评估记录表
-- ============================================
CREATE TABLE IF NOT EXISTS skill_assessment (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    node_id BIGINT NOT NULL COMMENT '技能节点ID',
    
    -- 评估信息
    assessment_time DATETIME NOT NULL COMMENT '评估时间',
    duration_seconds INT DEFAULT 0 COMMENT '答题耗时（秒）',
    
    -- 得分信息
    total_score DECIMAL(5,2) NOT NULL COMMENT '本次得分',
    pass_threshold DECIMAL(5,2) NOT NULL DEFAULT 70.00 COMMENT '通过阈值（默认70%）',
    passed TINYINT NOT NULL COMMENT '是否通过：0失败/1通过',
    
    -- 题目信息
    question_count INT NOT NULL COMMENT '题目数量',
    correct_count INT NOT NULL COMMENT '正确数量',
    
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    KEY idx_user_id (user_id),
    KEY idx_node_id (node_id),
    KEY idx_assessment_time (assessment_time),
    KEY idx_passed (passed),
    CONSTRAINT fk_assessment_user FOREIGN KEY (user_id) REFERENCES sys_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_assessment_node FOREIGN KEY (node_id) REFERENCES skill_node(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='评估记录表';

-- ============================================
-- 4. 答题明细表
-- ============================================
CREATE TABLE IF NOT EXISTS skill_assessment_detail (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
    assessment_id BIGINT NOT NULL COMMENT '评估记录ID',
    question_id BIGINT NOT NULL COMMENT '题目ID',
    
    -- 答题信息
    user_answer VARCHAR(10) NOT NULL COMMENT '用户答案',
    is_correct TINYINT NOT NULL COMMENT '是否正确：0错误/1正确',
    time_spent_seconds INT DEFAULT 0 COMMENT '本题耗时（秒）',
    
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    
    KEY idx_assessment_id (assessment_id),
    KEY idx_question_id (question_id),
    KEY idx_is_correct (is_correct),
    CONSTRAINT fk_detail_assessment FOREIGN KEY (assessment_id) REFERENCES skill_assessment(id) ON DELETE CASCADE,
    CONSTRAINT fk_detail_question FOREIGN KEY (question_id) REFERENCES skill_question(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='答题明细表';

-- ============================================
-- 5. 插入真实测试数据
-- ============================================

-- 插入用户技能进度数据（假设用户ID为1，是学生角色）
-- Java 基础阶段的进度
INSERT INTO user_skill_progress (user_id, node_id, status, unlock_time, start_time, complete_time, study_duration, best_score, latest_score, attempt_count, pass_count, exp_points) VALUES
(1, 1, 'COMPLETED', '2026-06-15 09:00:00', '2026-06-15 09:05:00', '2026-06-15 10:30:00', 5100, 85.00, 85.00, 1, 1, 50),
(1, 2, 'COMPLETED', '2026-06-15 09:05:00', '2026-06-15 09:10:00', '2026-06-15 10:00:00', 3000, 90.00, 88.00, 2, 2, 100),
(1, 3, 'COMPLETED', '2026-06-16 09:00:00', '2026-06-16 09:15:00', '2026-06-16 11:00:00', 6300, 82.00, 82.00, 1, 1, 150),
(1, 4, 'COMPLETED', '2026-06-17 09:00:00', '2026-06-17 09:30:00', '2026-06-17 12:00:00', 9000, 78.00, 75.00, 2, 1, 200),
-- Java 进阶阶段的进度
(1, 5, 'COMPLETED', '2026-06-17 12:00:00', '2026-06-18 09:00:00', '2026-06-18 15:00:00', 21600, 80.00, 80.00, 1, 1, 100),
(1, 6, 'IN_PROGRESS', '2026-06-18 15:00:00', '2026-06-19 09:00:00', NULL, 3600, 72.00, 72.00, 1, 1, 300),
(1, 7, 'UNLOCKED', '2026-06-19 12:00:00', NULL, NULL, 0, 0, 0, 0, 0, 0),
(1, 8, 'UNLOCKED', '2026-06-19 12:00:00', NULL, NULL, 0, 0, 0, 0, 0, 0),
-- 框架学习阶段（奖励节点，未解锁）
(1, 9, 'LOCKED', NULL, NULL, NULL, 0, 0, 0, 0, 0, 0);

-- 插入题目库数据（真实 Java 题目）
-- 节点ID=2: 变量与数据类型
INSERT INTO skill_question (node_id, question_text, options_json, correct_answer, explanation, difficulty, source, use_count, correct_rate) VALUES
(2, 'Java 中 int 类型的取值范围是多少？', 
 '["A. -128 到 127", "B. -32768 到 32767", "C. -2³¹ 到 2³¹-1", "D. -2⁶³ 到 2⁶³-1"]', 
 'C', 
 'int 类型占用 4 字节（32位），取值范围为 -2³¹ 到 2³¹-1，即 -2147483648 到 2147483647。', 
 2, 'MANUAL', 15, 73.33),

(2, '下列哪种数据类型可以存储小数？', 
 '["A. int", "B. long", "C. double", "D. char"]', 
 'C', 
 'double 是双精度浮点型，可以存储小数。float 也可以，但需要加 f 后缀。int 和 long 是整数类型。', 
 2, 'MANUAL', 12, 83.33),

(2, '声明一个常量应该使用哪个关键字？', 
 '["A. static", "B. final", "C. const", "D. volatile"]', 
 'B', 
 'final 关键字用于声明常量，值不可改变。const 不是 Java 的关键字。', 
 2, 'MANUAL', 10, 90.00);

-- 节点ID=3: 控制流程
INSERT INTO skill_question (node_id, question_text, options_json, correct_answer, explanation, difficulty, source, use_count, correct_rate) VALUES
(3, '以下哪种循环至少会执行一次？', 
 '["A. for 循环", "B. while 循环", "C. do-while 循环", "D. 以上都不会"]', 
 'C', 
 'do-while 循环先执行一次循环体，再判断条件，因此至少执行一次。', 
 2, 'MANUAL', 8, 87.50),

(3, 'switch 语句中，防止继续执行下一个 case 的关键字是？', 
 '["A. continue", "B. break", "C. return", "D. default"]', 
 'B', 
 'break 用于跳出 switch 语句，防止继续执行下一个 case。', 
 2, 'MANUAL', 12, 91.67),

(3, '下列哪个是合法的 if 语句？', 
 '["A. if (x = 5) {}", "B. if (x == 5) {}", "C. if x == 5 {}", "D. if (x.equals(5)) {}（x为int）"]', 
 'B', 
 'if 条件必须是布尔表达式。x = 5 是赋值语句，不是比较。x == 5 是正确的比较运算。', 
 3, 'MANUAL', 6, 66.67);

-- 节点ID=4: 面向对象
INSERT INTO skill_question (node_id, question_text, options_json, correct_answer, explanation, difficulty, source, use_count, correct_rate) VALUES
(4, 'Java 中哪个关键字用于继承一个类？', 
 '["A. implements", "B. extends", "C. inherits", "D. superclass"]', 
 'B', 
 'extends 用于继承类，implements 用于实现接口。', 
 3, 'MANUAL', 10, 80.00),

(4, '下列关于多态的说法，正确的是？', 
 '["A. 多态只能用于方法重载", "B. 多态只能用于方法重写", "C. 父类引用可以指向子类对象", "D. 子类引用可以指向父类对象"]', 
 'C', 
 '多态的核心是父类引用指向子类对象，调用方法时执行子类的实现。', 
 4, 'MANUAL', 8, 62.50),

(4, '构造方法的特点不包括？', 
 '["A. 名字与类名相同", "B. 没有返回值", "C. 可以被重载", "D. 可以被继承"]', 
 'D', 
 '构造方法不能被继承，子类默认调用父类无参构造方法（super()）。', 
 3, 'MANUAL', 6, 83.33);

-- 节点ID=6: 集合框架
INSERT INTO skill_question (node_id, question_text, options_json, correct_answer, explanation, difficulty, source, use_count, correct_rate) VALUES
(6, 'ArrayList 和 LinkedList 的主要区别是？', 
 '["A. ArrayList 是链表结构", "B. LinkedList 查询更快", "C. ArrayList 底层是数组，LinkedList 是链表", "D. 它们没有区别"]', 
 'C', 
 'ArrayList 底层是动态数组，查询快增删慢；LinkedList 底层是双向链表，增删快查询慢。', 
 3, 'MANUAL', 5, 80.00),

(6, 'HashMap 中键可以重复吗？', 
 '["A. 可以", "B. 不可以", "C. 只能重复一次", "D. 取决于值"]', 
 'B', 
 'HashMap 的键是唯一的，不能重复。如果重复，后面的值会覆盖前面的值。', 
 2, 'MANUAL', 7, 71.43),

(6, '以下哪个集合不允许存储 null 元素？', 
 '["A. ArrayList", "B. HashMap", "C. HashSet", "D. TreeSet"]', 
 'D', 
 'TreeSet 需要对元素排序，null 无法比较，因此不允许存储 null。', 
 4, 'MANUAL', 4, 50.00);

-- 插入评估记录数据（用户ID=1的真实评估历史）
INSERT INTO skill_assessment (user_id, node_id, assessment_time, duration_seconds, total_score, pass_threshold, passed, question_count, correct_count) VALUES
(1, 2, '2026-06-15 09:45:00', 900, 90.00, 70.00, 1, 5, 4),
(1, 2, '2026-06-15 09:50:00', 840, 88.00, 70.00, 1, 5, 4),
(1, 3, '2026-06-16 10:30:00', 1800, 82.00, 70.00, 1, 5, 4),
(1, 4, '2026-06-17 10:00:00', 2700, 75.00, 70.00, 0, 5, 3),
(1, 4, '2026-06-17 11:00:00', 2400, 78.00, 70.00, 1, 5, 4),
(1, 5, '2026-06-18 14:00:00', 3600, 80.00, 70.00, 1, 5, 4),
(1, 6, '2026-06-19 10:00:00', 1200, 72.00, 70.00, 1, 5, 4);

-- 插入答题明细数据（评估ID=1的答题详情）
INSERT INTO skill_assessment_detail (assessment_id, question_id, user_answer, is_correct, time_spent_seconds) VALUES
(1, 1, 'C', 1, 180),
(1, 2, 'C', 1, 150),
(1, 3, 'B', 1, 200),
(1, 11, 'C', 0, 250),
(1, 12, 'B', 1, 120);

-- ============================================
-- 6. 数据统计查询（用于看板验证）
-- ============================================

-- 用户1的学习总时长（秒）: 5100+3000+6300+9000+21600+3600 = 48600秒 ≈ 13.5小时
-- 用户1的已完成节点数: 6个
-- 用户1的总经验值: 50+100+150+200+100+300 = 900

-- 验证查询示例
-- SELECT 
--     SUM(study_duration) as total_duration,
--     COUNT(CASE WHEN status='COMPLETED' THEN 1 END) as completed_count,
--     SUM(exp_points) as total_exp
-- FROM user_skill_progress WHERE user_id = 1;

-- ============================================
-- 7. 索引优化建议
-- ============================================

-- 如果评估记录表数据量大，可考虑添加复合索引
-- ALTER TABLE skill_assessment ADD INDEX idx_user_node_time (user_id, node_id, assessment_time);

-- 如果题目库表数据量大，可考虑添加复合索引
-- ALTER TABLE skill_question ADD INDEX idx_node_difficulty (node_id, difficulty);