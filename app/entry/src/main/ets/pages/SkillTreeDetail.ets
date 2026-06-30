import { router } from '@kit.ArkUI'
import { NavBar } from '../components/NavBar'
import { Breadcrumb, BreadcrumbItem } from '../components/Breadcrumb'
import { SkillTreeApi } from '../http/SkillTreeApi'
import { SkillTree, SkillNode } from '../model/SkillTree'
import { TokenUtil } from '../common/TokenUtil'
//技能树详情界面
class SkillTreeDetailParams {
  id: number = 0
}

@Entry
@Component
struct SkillTreeDetail {
  @State skillTree: SkillTree = new SkillTree()
  @State allSkillNodes: SkillNode[] = []
  @State isLoading: boolean = false
  @State treeId: number = 0
  @State isLoggedIn: boolean = false
  
  @State @Watch('onCurrentNodeChanged') currentNodeId: number = 0
  @State breadcrumbItems: BreadcrumbItem[] = []

  aboutToAppear(): void {
    this.checkLogin()
  }

  private async checkLogin(): Promise<void> {
    try {
      const hasToken = await TokenUtil.hasToken()
      if (!hasToken) {
        router.replaceUrl({ url: 'pages/Login' })
        return
      }
      this.isLoggedIn = true
      this.extractTreeId()
      this.loadSkillTree()
    } catch (err) {
      router.replaceUrl({ url: 'pages/Login' })
    }
  }

  private extractTreeId(): void {
    const params: SkillTreeDetailParams = router.getParams() as SkillTreeDetailParams
    if (params) {
      this.treeId = params.id
    }
  }

  private async loadSkillTree(): Promise<void> {
    this.isLoading = true
    try {
      if (this.treeId > 0) {
        this.skillTree = await SkillTreeApi.getSkillTreeDetail(this.treeId)
        const treeNodes = await SkillTreeApi.getSkillNodeTree(this.treeId)
        this.allSkillNodes = this.flattenNodes(treeNodes)
        this.buildBreadcrumb()
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '加载失败'
      console.error('SkillTreeDetail: Failed to load skill tree:', errorMessage)
    } finally {
      this.isLoading = false
    }
  }

  private flattenNodes(nodes: SkillNode[], parentId: number = 0): SkillNode[] {
    const result: SkillNode[] = []
    for (const node of nodes) {
      node.parentId = parentId
      result.push(node)
      if (node.children && node.children.length > 0) {
        result.push(...this.flattenNodes(node.children, node.id))
      }
    }
    return result
  }

  private getCurrentLevelNodes(): SkillNode[] {
    return this.allSkillNodes.filter(node => node.parentId === this.currentNodeId)
  }

  private hasChildren(node: SkillNode): boolean {
    return this.allSkillNodes.some(n => n.parentId === node.id)
  }

  private buildBreadcrumb(): void {
    this.breadcrumbItems = []
    
    const rootItem: BreadcrumbItem = {
      id: 0,
      name: this.skillTree.name
    }
    this.breadcrumbItems.push(rootItem)

    if (this.currentNodeId === 0) {
      return
    }

    let currentId = this.currentNodeId
    const path: BreadcrumbItem[] = []

    while (currentId !== 0) {
      const node = this.allSkillNodes.find(n => n.id === currentId)
      if (node) {
        path.unshift({
          id: node.id,
          name: node.name
        })
        currentId = node.parentId
      } else {
        break
      }
    }

    this.breadcrumbItems.push(...path)
  }

  private onCurrentNodeChanged(): void {
    this.buildBreadcrumb()
  }

  private onNodeClick(node: SkillNode): void {
    if (this.hasChildren(node)) {
      this.currentNodeId = node.id
    }
  }

  private onStartAssessment(node: SkillNode): void {
    router.pushUrl({
      url: 'pages/AssessmentPage',
      params: {
        nodeId: node.id,
        nodeName: node.name
      }
    })
  }

  build() {
    Column() {
      NavBar({ title: this.skillTree.name || '技能树', showBack: true })

      Column({ space: 12 }) {
        if (this.isLoading) {
          Text('加载中...')
            .fontSize(14)
            .fontColor('#8898aa')
        } else {
          Column() {
            Text('🌳')
              .fontSize(48)
              .margin({ bottom: 12 })
            
            Text(this.skillTree.name)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1a1a2e')
              .margin({ bottom: 8 })
            
            Text(this.skillTree.description)
              .fontSize(14)
              .fontColor('#8898aa')
              .margin({ bottom: 16 })
            
            Row({ space: 16 }) {
              Column() {
                Text('难度')
                  .fontSize(12)
                  .fontColor('#8898aa')
                Text('⭐'.repeat(this.skillTree.difficultyLevel))
                  .fontSize(16)
              }
              Column() {
                Text('分类')
                  .fontSize(12)
                  .fontColor('#8898aa')
                Text(this.skillTree.category)
                  .fontSize(14)
                  .fontColor('#667eea')
              }
              Column() {
                Text('进度')
                  .fontSize(12)
                  .fontColor('#8898aa')
                Text(`${this.skillTree.progress}%`)
                  .fontSize(14)
                  .fontColor('#667eea')
              }
            }
          }
          .width('100%')
          .padding(24)
          .backgroundColor('#ffffff')
          .borderRadius(16)

          Breadcrumb({ items: this.breadcrumbItems, currentNodeId: $currentNodeId })
            .width('100%')

          Text('技能节点')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1a1a2e')

          List({ space: 12 }) {
            ForEach(this.getCurrentLevelNodes(), (node: SkillNode) => {
              ListItem() {
                Column() {
                  Row() {
                    Text(this.hasChildren(node) ? '📁' : '📌')
                      .fontSize(20)
                      .margin({ right: 12 })
                    
                    Column({ space: 4 }) {
                      Text(node.name)
                        .fontSize(16)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#1a1a2e')
                      if (node.description) {
                        Text(node.description)
                          .fontSize(12)
                          .fontColor('#8898aa')
                          .maxLines(1)
                      }
                    }
                    .layoutWeight(1)

                    Row({ space: 8 }) {
                      Text(node.userStatus === 'COMPLETED' ? '✓' : '○')
                        .fontSize(16)
                        .fontColor(node.userStatus === 'COMPLETED' ? '#4caf50' : '#8898aa')
                      
                      if (this.hasChildren(node)) {
                        Text('>')
                          .fontSize(16)
                          .fontColor('#cccccc')
                      }
                    }
                  }
                  .width('100%')
                  .padding(16)

                  Row() {
                    Blank()
                    Button('开始评估')
                      .fontSize(14)
                      .fontColor('#ffffff')
                      .backgroundColor('#667eea')
                      .borderRadius(16)
                      .width(100)
                      .height(36)
                      .onClick(() => {
                        this.onStartAssessment(node)
                      })
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, bottom: 16 })
                }
                .width('100%')
                .backgroundColor('#ffffff')
                .borderRadius(12)
                .onClick(() => {
                  this.onNodeClick(node)
                })
              }
            }, (node: SkillNode) => node.id.toString())
          }
          .width('100%')
        }
      }
      .width('90%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
  }
}
