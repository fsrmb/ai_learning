import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { SkillTreeApi } from '../http/SkillTreeApi'
import { SkillTree } from '../model/SkillTree'
import { NavBar } from '../components/NavBar'
import { TokenUtil } from '../common/TokenUtil'

@Entry
@Component
struct SkillTreeList {
  @State skillTrees: SkillTree[] = []
  @State categories: string[] = ['全部', '编程', '设计', '语言']
  @State selectedCategory: string = '全部'
  @State isLoading: boolean = false
  @State searchText: string = ''
  @State isLoggedIn: boolean = false

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
      this.loadSkillTrees()
    } catch (err) {
      router.replaceUrl({ url: 'pages/Login' })
    }
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
      url: 'pages/SkillTreeDetail',
      params: { id: tree.id }
    })
  }

  private getDifficultyStars(level: number): string {
    let stars: string = ''
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