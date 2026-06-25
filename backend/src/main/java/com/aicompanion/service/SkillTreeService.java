package com.aicompanion.service;

import com.aicompanion.model.dto.SkillNodeDTO;
import com.aicompanion.model.dto.SkillTreeDTO;
import com.aicompanion.model.vo.SkillNodeVO;
import com.aicompanion.model.vo.SkillTreeVO;

import java.util.List;

/**
 * 技能树服务接口
 */
public interface SkillTreeService {
    //单纯进行声明，不实现具体逻辑，逻辑在SkillTreeServiceImpl中
    /**
     * 创建技能树
     */
    Long createSkillTree(SkillTreeDTO dto);
    
    /**
     * 更新技能树
     */
    void updateSkillTree(Long id, SkillTreeDTO dto);
    
    /**
     * 删除技能树
     */
    void deleteSkillTree(Long id);
    
    /**
     * 获取技能树详情（包含节点树）
     */
    SkillTreeVO getSkillTreeDetail(Long id);
    
    /**
     * 获取技能树列表
     */
    List<SkillTreeVO> listSkillTrees(String category);
    
    /**
     * 创建技能节点
     */
    Long createSkillNode(SkillNodeDTO dto);
    
    /**
     * 更新技能节点
     */
    void updateSkillNode(Long id, SkillNodeDTO dto);
    
    /**
     * 删除技能节点
     */
    void deleteSkillNode(Long id);
    
    /**
     * 获取技能树的节点树形结构
     */
    List<SkillNodeVO> getSkillNodeTree(Long treeId);
}
