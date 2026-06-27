import { router } from '@kit.ArkUI'
import { NavBar } from '../components/NavBar'
import { SkillTreeApi } from '../http/SkillTreeApi'
import { SkillTree, SkillNode } from '../model/SkillTree'

@Entry
@Component
struct SkillTreeDetail {
  @State skillTree: SkillTree = new SkillTree()
  @State skillNodes: SkillNode[] = []
  @State isLoading: boolean = false

  aboutToAppear(): void {
    this.loadSkillTree()
  }

  private async loadSkillTree(): Promise<void> {
    this.isLoading = true
    try {
      const params = new URLSearchParams(decodeURIComponent(router.getParams()?.['url'] || ''))
      const id = parseInt(params.get('id') || '0')
      if (id > 0) {
        this.skillTree = await SkillTreeApi.getSkillTreeDetail(id)
        this.skillNodes = await SkillTreeApi.getSkillNodeTree(id)
      }
    } catch (error) {
      console.error('SkillTreeDetail: Failed to load skill tree:', error)
    } finally {
      this.isLoading = false
    }
  }

  build() {
    Column() {
      NavBar({ title: this.skillTree.name || '技能树详情', showBack: true })

      Column({ space: 16 }) {
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
          .margin({ top: 16 })

          Text('技能节点')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1a1a2e')
            .margin({ top: 16 })

          List({ space: 8 }) {
            ForEach(this.skillNodes, (node: SkillNode) => {
              ListItem() {
                Column() {
                  Row() {
                    Text('📌')
                      .fontSize(18)
                      .margin({ right: 12 })
                    Text(node.name)
                      .fontSize(16)
                      .fontColor('#1a1a2e')
                    Blank()
                    Text(node.userStatus === 'COMPLETED' ? '✓' : '○')
                      .fontSize(16)
                      .fontColor(node.userStatus === 'COMPLETED' ? '#4caf50' : '#8898aa')
                  }
                  .width('100%')
                  
                  if (node.children.length > 0) {
                    Column({ space: 8 }) {
                      ForEach(node.children, (child: SkillNode) => {
                        Row() {
                          Text('    ')
                          Text('🔹')
                            .fontSize(14)
                            .margin({ right: 8 })
                          Text(child.name)
                            .fontSize(14)
                            .fontColor('#666666')
                          Blank()
                          Text(child.userStatus === 'COMPLETED' ? '✓' : '○')
                            .fontSize(12)
                            .fontColor(child.userStatus === 'COMPLETED' ? '#4caf50' : '#cccccc')
                        }
                      })
                    }
                    .width('100%')
                    .margin({ top: 8 })
                  }
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#ffffff')
                .borderRadius(12)
              }
            })
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