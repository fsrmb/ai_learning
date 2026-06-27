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