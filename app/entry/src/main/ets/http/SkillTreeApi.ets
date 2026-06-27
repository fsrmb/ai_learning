import { HttpClient } from './HttpClient'
import { SkillTree, SkillNode } from '../model/SkillTree'

export class SkillTreeApi {
  static async getSkillTrees(category?: string): Promise<SkillTree[]> {
    const path = category ? `/api/arkts/skill-trees?category=${encodeURIComponent(category)}` : '/api/arkts/skill-trees'
    return HttpClient.get<SkillTree[]>(path)
  }

  static async getSkillTreeDetail(id: number): Promise<SkillTree> {
    return HttpClient.get<SkillTree>(`/api/arkts/skill-trees/${id}`)
  }

  static async getSkillNodeTree(treeId: number): Promise<SkillNode[]> {
    return HttpClient.get<SkillNode[]>(`/api/arkts/skill-trees/${treeId}/nodes`)
  }
}