package com.aicompanion.service.arkts;

import com.aicompanion.model.vo.arkts.SkillTreeProgressVO;
import com.aicompanion.model.vo.arkts.SkillNodeProgressVO;

import java.util.List;

/**
 * 移动端技能树服务接口
 * 专门为 ArkTS 移动端应用提供技能树相关功能
 */
public interface ArkTSSkillTreeService {
    
    /**
     * 获取技能树列表（包含用户进度）
     * @param category 分类筛选（可选）
     * @return 技能树列表，包含进度信息
     */
    List<SkillTreeProgressVO> listSkillTreesWithProgress(String category);
    
    /**
     * 获取技能树详情（包含用户进度）
     * @param treeId 技能树ID
     * @return 技能树详情，包含节点树和用户进度
     */
    SkillTreeProgressVO getSkillTreeDetailWithProgress(Long treeId);
    
    /**
     * 获取技能节点树（包含用户进度）
     * @param treeId 技能树ID
     * @return 技能节点树，包含用户状态
     */
    List<SkillNodeProgressVO> getSkillNodeTreeWithProgress(Long treeId);
}