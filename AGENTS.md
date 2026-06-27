# AI Companion Platform - AI 伴学平台

## 项目概述

AI 伴学平台是一个面向大学生的智能学习辅助系统，核心功能：
- AI 聊天助手（基于大模型的智能问答）
- 技能评估（AI 出题 → 答题 → 评分）
- 模拟面试（AI 驱动的技术面试模拟）
- 学习记录（跟踪用户学习进度）
- 管理后台（数据看板、内容管理）

项目采用前后端分离架构：
- 前端管理后台：admin/ （Vue3 + Element Plus）
- 后端服务：backend/ （Spring Boot3 + MyBatis-Plus）
- 移动端应用：app/  

## 子项目文档索引

| 文档 | 路径 | 适用场景 |
|------|------|----------|
| 前端开发规范 | admin/AGENTS.md | 使用 Trae CN 进行前端开发时阅读 |
| 后端开发规范 | backend/AGENTS.md | 进行后端开发时阅读 |
| 移动端开发规范 | app/AGENTS.md | 使用 Trae CN 进行移动端开发时阅读 |
> **渐进式披露规则：** AI 应先读取本文件了解项目全貌，再根据当前任务读取对应的子文件。
> 不要一次性加载所有文档——先读顶层获取上下文，再读子文件获取细节。
# 项目开发规范索引

本项目包含三个子模块，各自的详细规范存放在以下文件中：
- 前端管理后台：`admin/AGENTS.md`
- 后端服务：`backend/AGENTS.md`
- 移动端应用：`app/AGENTS.md`

## Agent 行为规则
当用户提出涉及某个模块的任务时，你**必须先使用 `read_file` 工具读取对应模块的规范文件**，然后再根据规范执行任务。不要预先加载所有文件。

## 前后端联调约定

- 后端 API 基础路径：/api/
- 统一响应格式：{ code: 200, message: "success", data: ... }
- 认证方式：JWT Bearer Token（放在 Authorization 请求头）
- 前端通过 Axios 请求后端，baseURL 在 .env 文件中配置
