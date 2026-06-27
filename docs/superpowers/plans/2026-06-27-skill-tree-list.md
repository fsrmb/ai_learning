# SkillTreeList 技能树列表页面实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 实现技能树列表页面，从数据库获取技能树数据并展示，包含进度概览

**架构：** 移动端通过 HTTP API 请求后端，后端查询 skill_tree 表并结合 user_skill_progress 表计算进度，返回包含进度信息的技能树列表

**技术栈：**
- 后端：Spring Boot 3.2 + MyBatis-Plus 3.5 + MySQL 8.0
- 移动端：HarmonyOS ArkTS + HttpClient

---

## 文件结构

| 文件 | 职责 |
|------|------|
| `backend/model/vo/SkillTreeVO.java` | 添加进度字段（nodeCount, completedCount, progress）|
| `backend/service/SkillTreeService.java` | 添加计算进度方法 |
| `backend/service/impl/SkillTreeServiceImpl.java` | 实现进度计算逻辑 |
| `app/model/SkillTree.ets` | 移动端技能树数据模型 |
| `app/model/SkillNode.ets` | 移动端技能节点数据模型 |
| `app/http/SkillTreeApi.ets` | 技能树 API 接口封装 |
| `app/pages/SkillTreeList.ets` | 技能树列表页面 |
| `app/pages/MainTab.ets` | 添加技能树页面路由 |

---

## 任务 1：修改后端 SkillTreeVO 添加进度字段

**文件：**
- 修改：`backend/src/main/java/com/aicompanion/model/vo/SkillTreeVO.java`

**步骤：**

- [ ] **步骤 1：添加进度相关字段**

```java
package com.aicompanion.model.vo;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
public class SkillTreeVO {
    
    private Long id;
    private String name;
    private String description;
    private String icon;
    private String category;
    private Integer difficultyLevel;
    private Integer status;
    private Integer sortOrder;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    
    private List<SkillNodeVO> nodes;
    
    // 新增进度字段
    private Integer nodeCount;
    private Integer completedCount;
    private Double progress;
}
```

- [ ] **步骤 2：Commit**

```bash
git add backend/src/main/java/com/aicompanion/model/vo/SkillTreeVO.java
git commit -m "feat: add progress fields to SkillTreeVO"
```

---

## 任务 2：创建用户技能进度相关实体和 Mapper

**文件：**
- 创建：`backend/src/main/java/com/aicompanion/model/entity/UserSkillProgress.java`
- 创建：`backend/src/main/java/com/aicompanion/mapper/UserSkillProgressMapper.java`

**步骤：**

- [ ] **步骤 1：创建 UserSkillProgress 实体类**

```java
package com.aicompanion.model.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@EqualsAndHashCode(callSuper = true)
@TableName("user_skill_progress")
public class UserSkillProgress extends BaseEntity {
    
    @TableField("user_id")
    private Long userId;
    
    @TableField("node_id")
    private Long nodeId;
    
    @TableField("status")
    private String status;
    
    @TableField("unlock_time")
    private LocalDateTime unlockTime;
    
    @TableField("start_time")
    private LocalDateTime startTime;
    
    @TableField("complete_time")
    private LocalDateTime completeTime;
    
    @TableField("study_duration")
    private Integer studyDuration;
    
    @TableField("best_score")
    private BigDecimal bestScore;
    
    @TableField("latest_score")
    private BigDecimal latestScore;
    
    @TableField("attempt_count")
    private Integer attemptCount;
    
    @TableField("pass_count")
    private Integer passCount;
    
    @TableField("exp_points")
    private Integer expPoints;
}
```

- [ ] **步骤 2：创建 UserSkillProgressMapper**

```java
package com.aicompanion.mapper;

import com.aicompanion.model.entity.UserSkillProgress;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface UserSkillProgressMapper extends BaseMapper<UserSkillProgress> {
}
```

- [ ] **步骤 3：Commit**

```bash
git add backend/src/main/java/com/aicompanion/model/entity/UserSkillProgress.java
git add backend/src/main/java/com/aicompanion/mapper/UserSkillProgressMapper.java
git commit -m "feat: add UserSkillProgress entity and mapper"
```

---

## 任务 3：修改 SkillTreeService 添加进度计算方法

**文件：**
- 修改：`backend/src/main/java/com/aicompanion/service/SkillTreeService.java`
- 修改：`backend/src/main/java/com/aicompanion/service/impl/SkillTreeServiceImpl.java`

**步骤：**

- [ ] **步骤 1：修改 SkillTreeService 接口**

```java
package com.aicompanion.service;

import com.aicompanion.model.dto.SkillNodeDTO;
import com.aicompanion.model.dto.SkillTreeDTO;
import com.aicompanion.model.vo.SkillNodeVO;
import com.aicompanion.model.vo.SkillTreeVO;

import java.util.List;

public interface SkillTreeService {
    
    Long createSkillTree(SkillTreeDTO dto);
    
    void updateSkillTree(Long id, SkillTreeDTO dto);
    
    void deleteSkillTree(Long id);
    
    SkillTreeVO getSkillTreeDetail(Long id);
    
    List<SkillTreeVO> listSkillTrees(String category);
    
    Long createSkillNode(SkillNodeDTO dto);
    
    void updateSkillNode(Long id, SkillNodeDTO dto);
    
    void deleteSkillNode(Long id);
    
    List<SkillNodeVO> getSkillNodeTree(Long treeId);
    
    // 新增方法
    List<SkillTreeVO> listSkillTreesWithProgress(String category);
}
```

- [ ] **步骤 2：修改 SkillTreeServiceImpl 实现**

```java
package com.aicompanion.service.impl;

import com.aicompanion.common.exception.BusinessException;
import com.aicompanion.common.util.SecurityUtil;
import com.aicompanion.mapper.SkillNodeMapper;
import com.aicompanion.mapper.SkillTreeMapper;
import com.aicompanion.mapper.UserSkillProgressMapper;
import com.aicompanion.model.dto.SkillNodeDTO;
import com.aicompanion.model.dto.SkillTreeDTO;
import com.aicompanion.model.entity.SkillNode;
import com.aicompanion.model.entity.SkillTree;
import com.aicompanion.model.entity.UserSkillProgress;
import com.aicompanion.model.vo.SkillNodeVO;
import com.aicompanion.model.vo.SkillTreeVO;
import com.aicompanion.service.SkillTreeService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class SkillTreeServiceImpl extends ServiceImpl<SkillTreeMapper, SkillTree> implements SkillTreeService {
    
    private final SkillTreeMapper skillTreeMapper;
    private final SkillNodeMapper skillNodeMapper;
    private final UserSkillProgressMapper userSkillProgressMapper;
    
    @Override
    public List<SkillTreeVO> listSkillTrees(String category) {
        LambdaQueryWrapper<SkillTree> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(SkillTree::getStatus, 1);
        if (category != null && !category.isEmpty()) {
            queryWrapper.eq(SkillTree::getCategory, category);
        }
        queryWrapper.orderByAsc(SkillTree::getSortOrder);
        
        List<SkillTree> list = skillTreeMapper.selectList(queryWrapper);
        return list.stream().map(this::convertToVO).collect(Collectors.toList());
    }
    
    @Override
    public List<SkillTreeVO> listSkillTreesWithProgress(String category) {
        LambdaQueryWrapper<SkillTree> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(SkillTree::getStatus, 1);
        if (category != null && !category.isEmpty()) {
            queryWrapper.eq(SkillTree::getCategory, category);
        }
        queryWrapper.orderByAsc(SkillTree::getSortOrder);
        
        List<SkillTree> list = skillTreeMapper.selectList(queryWrapper);
        List<SkillTreeVO> voList = list.stream().map(this::convertToVO).collect(Collectors.toList());
        
        Long userId = SecurityUtil.getCurrentUserId();
        if (userId != null) {
            LambdaQueryWrapper<UserSkillProgress> progressQuery = new LambdaQueryWrapper<>();
            progressQuery.eq(UserSkillProgress::getUserId, userId);
            List<UserSkillProgress> progressList = userSkillProgressMapper.selectList(progressQuery);
            
            Map<Long, Long> completedNodeCountMap = progressList.stream()
                    .filter(p -> "COMPLETED".equals(p.getStatus()))
                    .collect(Collectors.groupingBy(
                            p -> {
                                SkillNode node = skillNodeMapper.selectById(p.getNodeId());
                                return node != null ? node.getTreeId() : null;
                            },
                            Collectors.counting()
                    ));
            
            for (SkillTreeVO vo : voList) {
                Integer totalCount = vo.getNodeCount();
                Long completedCount = completedNodeCountMap.getOrDefault(vo.getId(), 0L);
                vo.setCompletedCount(completedCount.intValue());
                if (totalCount != null && totalCount > 0) {
                    vo.setProgress(Math.round(completedCount * 1000.0 / totalCount) / 10.0);
                } else {
                    vo.setProgress(0.0);
                }
            }
        }
        
        return voList;
    }
    
    private SkillTreeVO convertToVO(SkillTree entity) {
        SkillTreeVO vo = new SkillTreeVO();
        vo.setId(entity.getId());
        vo.setName(entity.getName());
        vo.setDescription(entity.getDescription());
        vo.setIcon(entity.getIcon());
        vo.setCategory(entity.getCategory());
        vo.setDifficultyLevel(entity.getDifficultyLevel());
        vo.setStatus(entity.getStatus());
        vo.setSortOrder(entity.getSortOrder());
        vo.setCreateTime(entity.getCreateTime());
        vo.setUpdateTime(entity.getUpdateTime());
        
        LambdaQueryWrapper<SkillNode> nodeQuery = new LambdaQueryWrapper<>();
        nodeQuery.eq(SkillNode::getTreeId, entity.getId());
        nodeQuery.eq(SkillNode::getStatus, 1);
        vo.setNodeCount((int) skillNodeMapper.selectCount(nodeQuery));
        vo.setCompletedCount(0);
        vo.setProgress(0.0);
        
        return vo;
    }
    
    // 其他方法保持不变...
}
```

- [ ] **步骤 3：Commit**

```bash
git add backend/src/main/java/com/aicompanion/service/SkillTreeService.java
git add backend/src/main/java/com/aicompanion/service/impl/SkillTreeServiceImpl.java
git commit -m "feat: add progress calculation to skill tree service"
```

---

## 任务 4：修改 SkillTreeController 添加带进度的列表接口

**文件：**
- 修改：`backend/src/main/java/com/aicompanion/controller/SkillTreeController.java`

**步骤：**

- [ ] **步骤 1：添加新接口**

```java
package com.aicompanion.controller;

import com.aicompanion.common.response.Result;
import com.aicompanion.model.dto.SkillNodeDTO;
import com.aicompanion.model.dto.SkillTreeDTO;
import com.aicompanion.model.vo.SkillNodeVO;
import com.aicompanion.model.vo.SkillTreeVO;
import com.aicompanion.service.SkillTreeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "技能树管理", description = "技能树和节点的增删改查接口")
@RestController
@RequestMapping("/api/skill-trees")
@RequiredArgsConstructor
public class SkillTreeController {
    
    private final SkillTreeService skillTreeService;
    
    @Operation(summary = "创建技能树", description = "创建一个新的技能树")
    @PostMapping
    public Result<Long> createSkillTree(@Valid @RequestBody SkillTreeDTO dto) {
        Long id = skillTreeService.createSkillTree(dto);
        return Result.success("创建成功", id);
    }
    
    @Operation(summary = "更新技能树", description = "更新指定ID的技能树信息")
    @PutMapping("/{id}")
    public Result<Void> updateSkillTree(@PathVariable Long id, @Valid @RequestBody SkillTreeDTO dto) {
        skillTreeService.updateSkillTree(id, dto);
        return Result.success("更新成功", null);
    }
    
    @Operation(summary = "删除技能树", description = "删除指定ID的技能树及其所有节点")
    @DeleteMapping("/{id}")
    public Result<Void> deleteSkillTree(@PathVariable Long id) {
        skillTreeService.deleteSkillTree(id);
        return Result.success("删除成功", null);
    }
    
    @Operation(summary = "获取技能树详情", description = "获取技能树详细信息，包含完整的节点树形结构")
    @GetMapping("/{id}")
    public Result<SkillTreeVO> getSkillTreeDetail(@PathVariable Long id) {
        SkillTreeVO vo = skillTreeService.getSkillTreeDetail(id);
        return Result.success(vo);
    }
    
    @Operation(summary = "获取技能树列表", description = "获取技能树列表，可按分类筛选")
    @GetMapping
    public Result<List<SkillTreeVO>> listSkillTrees(
            @Parameter(description = "分类筛选", required = false)
            @RequestParam(required = false) String category) {
        List<SkillTreeVO> list = skillTreeService.listSkillTreesWithProgress(category);
        return Result.success(list);
    }
    
    @Operation(summary = "创建技能节点", description = "在指定技能树下创建新的技能节点")
    @PostMapping("/nodes")
    public Result<Long> createSkillNode(@Valid @RequestBody SkillNodeDTO dto) {
        Long id = skillTreeService.createSkillNode(dto);
        return Result.success("创建成功", id);
    }
    
    @Operation(summary = "更新技能节点", description = "更新指定ID的技能节点信息")
    @PutMapping("/nodes/{id}")
    public Result<Void> updateSkillNode(@PathVariable Long id, @Valid @RequestBody SkillNodeDTO dto) {
        skillTreeService.updateSkillNode(id, dto);
        return Result.success("更新成功", null);
    }
    
    @Operation(summary = "删除技能节点", description = "删除指定ID的技能节点及其所有子节点")
    @DeleteMapping("/nodes/{id}")
    public Result<Void> deleteSkillNode(@PathVariable Long id) {
        skillTreeService.deleteSkillNode(id);
        return Result.success("删除成功", null);
    }
    
    @Operation(summary = "获取节点树形结构", description = "获取指定技能树的完整节点树形结构")
    @GetMapping("/{treeId}/nodes")
    public Result<List<SkillNodeVO>> getSkillNodeTree(@PathVariable Long treeId) {
        List<SkillNodeVO> tree = skillTreeService.getSkillNodeTree(treeId);
        return Result.success(tree);
    }
}
```

- [ ] **步骤 2：Commit**

```bash
git add backend/src/main/java/com/aicompanion/controller/SkillTreeController.java
git commit -m "feat: update listSkillTrees to return progress"
```

---

## 任务 5：创建移动端数据模型

**文件：**
- 创建：`app/entry/src/main/ets/model/SkillTree.ets`
- 创建：`app/entry/src/main/ets/model/SkillNode.ets`

**步骤：**

- [ ] **步骤 1：创建 SkillTree.ets**

```typescript
export class SkillTree {
  id: number = 0
  name: string = ''
  description: string = ''
  icon: string = ''
  category: string = ''
  difficultyLevel: number = 0
  status: number = 0
  sortOrder: number = 0
  nodeCount: number = 0
  completedCount: number = 0
  progress: number = 0
}
```

- [ ] **步骤 2：创建 SkillNode.ets**

```typescript
export class SkillNode {
  id: number = 0
  treeId: number = 0
  parentId: number = 0
  name: string = ''
  description: string = ''
  nodeType: string = ''
  requiredExp: number = 0
  unlockCondition: string = ''
  reward: string = ''
  icon: string = ''
  status: number = 0
  sortOrder: number = 0
  children: SkillNode[] = []
  userStatus: string = ''
  bestScore: number = 0
}
```

- [ ] **步骤 3：Commit**

```bash
git add app/entry/src/main/ets/model/SkillTree.ets
git add app/entry/src/main/ets/model/SkillNode.ets
git commit -m "feat: add SkillTree and SkillNode models"
```

---

## 任务 6：创建移动端 API 封装

**文件：**
- 创建：`app/entry/src/main/ets/http/SkillTreeApi.ets`

**步骤：**

- [ ] **步骤 1：创建 SkillTreeApi.ets**

```typescript
import { HttpClient } from './HttpClient'
import { SkillTree, SkillNode } from '../model/SkillTree'

export class SkillTreeApi {
  static async getSkillTrees(category?: string): Promise<SkillTree[]> {
    const path = category ? `/api/skill-trees?category=${encodeURIComponent(category)}` : '/api/skill-trees'
    return HttpClient.get<SkillTree[]>(path)
  }

  static async getSkillTreeDetail(id: number): Promise<SkillTree> {
    return HttpClient.get<SkillTree>(`/api/skill-trees/${id}`)
  }

  static async getSkillNodeTree(treeId: number): Promise<SkillNode[]> {
    return HttpClient.get<SkillNode[]>(`/api/skill-trees/${treeId}/nodes`)
  }
}
```

- [ ] **步骤 2：Commit**

```bash
git add app/entry/src/main/ets/http/SkillTreeApi.ets
git commit -m "feat: add SkillTreeApi for API calls"
```

---

## 任务 7：创建 SkillTreeList.ets 页面

**文件：**
- 创建：`app/entry/src/main/ets/pages/SkillTreeList.ets`

**步骤：**

- [ ] **步骤 1：创建页面结构**

```typescript
import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { SkillTreeApi } from '../http/SkillTreeApi'
import { SkillTree } from '../model/SkillTree'
import { NavBar } from '../components/NavBar'

@Entry
@Component
struct SkillTreeList {
  @State skillTrees: SkillTree[] = []
  @State categories: string[] = ['全部', '编程', '设计', '语言']
  @State selectedCategory: string = '全部'
  @State isLoading: boolean = false
  @State searchText: string = ''

  aboutToAppear(): void {
    this.loadSkillTrees()
  }

  private async loadSkillTrees(): Promise<void> {
    this.isLoading = true
    try {
      const category = this.selectedCategory === '全部' ? undefined : this.selectedCategory
      const trees = await SkillTreeApi.getSkillTrees(category)
      this.skillTrees = trees
      console.info('SkillTreeList: Loaded skill trees - count:', trees.length)
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '获取技能树列表失败'
      console.error('SkillTreeList: Failed to load skill trees:', errorMessage)
      promptAction.showToast({
        message: errorMessage,
        duration: 2000
      })
    } finally {
      this.isLoading = false
    }
  }

  private handleCategoryClick(category: string): void {
    this.selectedCategory = category
    this.loadSkillTrees()
  }

  private handleSkillTreeClick(tree: SkillTree): void {
    router.pushUrl({
      url: `pages/SkillTreeDetail?id=${tree.id}`
    })
  }

  private getDifficultyStars(level: number): string {
    let stars = ''
    for (let i = 0; i < 5; i++) {
      stars += i < level ? '⭐' : '☆'
    }
    return stars
  }

  build() {
    Column() {
      NavBar({ title: '技能树', showBack: false })

      Column({ space: 16 }) {
        Row() {
          Text('🔍')
            .fontSize(16)
            .margin({ left: 16 })
          TextInput({ placeholder: '搜索技能树...' })
            .width('70%')
            .height(40)
            .backgroundColor('#f5f7fa')
            .borderRadius(8)
            .onChange((value: string) => {
              this.searchText = value
            })
        }

        Row({ space: 8 }) {
          ForEach(this.categories, (category: string) => {
            Text(category)
              .fontSize(14)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .backgroundColor(this.selectedCategory === category ? '#667eea' : '#ffffff')
              .fontColor(this.selectedCategory === category ? '#ffffff' : '#666666')
              .borderRadius(20)
              .onClick(() => {
                this.handleCategoryClick(category)
              })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
        .padding({ left: 16 })

        if (this.isLoading) {
          Column() {
            Text('加载中...')
              .fontSize(14)
              .fontColor('#8898aa')
          }
          .width('100%')
          .height(200)
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 12 }) {
            ForEach(this.skillTrees, (tree: SkillTree) => {
              ListItem() {
                Column() {
                  Row() {
                    Column() {
                      Text('🌳')
                        .fontSize(32)
                    }
                    .width(60)
                    .height(60)
                    .backgroundColor('#667eea')
                    .borderRadius(12)
                    .justifyContent(FlexAlign.Center)
                    .margin({ right: 12 })

                    Column({ space: 4 }) {
                      Text(tree.name)
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#1a1a2e')

                      Text(tree.description)
                        .fontSize(12)
                        .fontColor('#8898aa')
                        .maxLines(1)

                      Row({ space: 8 }) {
                        Text(this.getDifficultyStars(tree.difficultyLevel))
                          .fontSize(12)
                        Text(tree.category)
                          .fontSize(10)
                          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                          .backgroundColor('#f0f0f0')
                          .borderRadius(4)
                          .fontColor('#666666')
                      }
                    }
                    .flexGrow(1)

                    Column({ space: 4 }) {
                      Text(`${tree.completedCount}/${tree.nodeCount}`)
                        .fontSize(12)
                        .fontColor('#667eea')
                        .fontWeight(FontWeight.Medium)
                      Text(`${tree.progress}%`)
                        .fontSize(10)
                        .fontColor('#8898aa')
                    }
                  }
                  .width('100%')

                  Row() {
                    Row() {
                      ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], (i: number) => {
                        Column() {
                          Text('')
                            .width('10%')
                            .height(4)
                            .backgroundColor(i <= tree.progress / 10 ? '#667eea' : '#e0e0e0')
                            .borderRadius(2)
                        }
                      })
                    }
                    .width('70%')
                  }
                  .width('100%')
                  .margin({ top: 8 })

                  Row() {
                    Blank()
                    Text('继续学习 →')
                      .fontSize(12)
                      .fontColor('#667eea')
                  }
                  .width('100%')
                  .margin({ top: 8 })
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#ffffff')
                .borderRadius(12)
                .shadow({ radius: 4, color: '#000000', offsetY: 2 })
              }
              .onClick(() => {
                this.handleSkillTreeClick(tree)
              })
            })
          }
          .width('90%')
          .layoutWeight(1)
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
  }
}
```

- [ ] **步骤 2：Commit**

```bash
git add app/entry/src/main/ets/pages/SkillTreeList.ets
git commit -m "feat: create SkillTreeList page"
```

---

## 任务 8：修改 MainTab.ets 添加技能树页面路由

**文件：**
- 修改：`app/entry/src/main/ets/pages/MainTab.ets`

**步骤：**

- [ ] **步骤 1：修改 tabs 数组**

```typescript
private tabs: TabItem[] = [
  { name: '首页', icon: '🏠', path: '' },
  { name: '技能树', icon: '🌳', path: 'pages/SkillTreeList' },
  { name: 'AI 聊天', icon: '💬', path: 'pages/DifyChat' },
  { name: '我的', icon: '👤', path: 'pages/Profile' }
]
```

- [ ] **步骤 2：Commit**

```bash
git add app/entry/src/main/ets/pages/MainTab.ets
git commit -m "feat: add skill tree tab in MainTab"
```

---

## 任务 9：配置 pages.json 添加页面路由

**文件：**
- 修改：`app/entry/src/main/resources/base/profile/main_pages.json`

**步骤：**

- [ ] **步骤 1：添加页面路由**

```json
{
  "src": [
    "pages/Index",
    "pages/Login",
    "pages/Register",
    "pages/MainTab",
    "pages/DifyChat",
    "pages/Profile",
    "pages/ResumeOptimize",
    "pages/SkillTreeList",
    "pages/SkillTreeDetail",
    "pages/SkillNodeDetail",
    "pages/SkillAssessment",
    "pages/SkillProgress",
    "pages/SkillDashboard"
  ]
}
```

- [ ] **步骤 2：Commit**

```bash
git add app/entry/src/main/resources/base/profile/main_pages.json
git commit -m "feat: add skill tree pages to router"
```

---

## 自检

**1. 规格覆盖度：**
- ✅ 技能树列表展示
- ✅ 分类筛选
- ✅ 进度百分比展示
- ✅ 点击卡片跳转详情页

**2. 占位符扫描：**
- ✅ 无"待定"、"TODO"

**3. 类型一致性：**
- ✅ 后端 SkillTreeVO 与移动端 SkillTree 模型字段一致

---

## 验证步骤

1. 运行 SQL 脚本创建数据库表和测试数据
2. 启动后端服务
3. 启动前端开发服务器
4. 访问技能树列表页面，验证数据正确显示
5. 测试分类筛选功能
6. 测试点击卡片跳转功能