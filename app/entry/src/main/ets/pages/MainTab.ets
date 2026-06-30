import { router } from '@kit.ArkUI'
import { TokenUtil } from '../common/TokenUtil'
//首页
@Entry
@Component
struct MainTab {
  @State currentTab: number = 0
  @State username: string = ''
  @State isLoaded: boolean = false

  private tabs: TabItem[] = [
    { name: '首页', icon: '🏠', path: '' },
    { name: '技能树', icon: '🌳', path: 'pages/SkillTreeList' },
    { name: 'AI 聊天', icon: '💬', path: 'pages/Chat' },
    { name: '我的', icon: '👤', path: 'pages/Profile' }
  ]

  aboutToAppear(): void {
    this.loadUserData()
  }

  private async loadUserData(): Promise<void> {
    try {
      const storedUsername = await TokenUtil.getUsername()
      this.username = storedUsername
      console.info(`MainTab: Loaded username: "${this.username}"`)
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to load user data'
      console.error('MainTab: Failed to load username:', errorMessage)
      this.username = ''
    } finally {
      this.isLoaded = true
    }
  }

  private handleTabClick(index: number): void {
    this.currentTab = index
    const tab = this.tabs[index]
    if (tab.path !== '') {
      router.pushUrl({ url: tab.path })
    }
  }

  build() {
    Column() {
      Column() {
        Text('AI 伴学平台')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a2e')
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .justifyContent(FlexAlign.Center)
      .shadow({ radius: 4, color: '#000000' })

      Column() {
        if (this.isLoaded && this.username !== '') {
          Text(`欢迎回来，${this.username}！`)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1a1a2e')
            .margin({ bottom: 8 })
        } else {
          Text('欢迎使用 AI 伴学平台！')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1a1a2e')
            .margin({ bottom: 8 })
        }

        Text('智能学习，助力成长')
          .fontSize(14)
          .fontColor('#8898aa')
          .margin({ bottom: 20 })

        Column() {
          Row() {
            Text('📄')
              .fontSize(24)
              .margin({ right: 12 })
            Column() {
              Text('简历优化')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#1a1a2e')
              Text('上传简历，AI 帮你优化')
                .fontSize(12)
                .fontColor('#8898aa')
                .margin({ top: 4 })
            }
            Blank()
            Text('→')
              .fontSize(16)
              .fontColor('#ccc')
          }
          .width('100%')
          .padding(16)
        }
        .width('90%')
        .backgroundColor('#fff')
        .borderRadius(12)
        .shadow({ radius: 4, color: '#000000', offsetY: 2 })
        .onClick(() => {
          router.pushUrl({ url: 'pages/ResumeOptimize' })
        })
      }
      .flexGrow(1)
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      Row() {
        ForEach(this.tabs, (item: TabItem, index: number) => {
          Column() {
            Text(item.icon)
              .fontSize(22)
              .fontColor(this.currentTab === index ? '#667eea' : '#8898aa')

            Text(item.name)
              .fontSize(10)
              .fontColor(this.currentTab === index ? '#667eea' : '#8898aa')
              .margin({ top: 4 })
          }
          .width('25%')
          .height(56)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.handleTabClick(index)
          })
        })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 16, topRight: 16 })
      .shadow({ radius: 8, color: '#000000', offsetY: -4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
  }

  async onPageShow(): Promise<void> {
    try {
      const hasToken = await TokenUtil.hasToken()
      if (!hasToken) {
        router.replaceUrl({ url: 'pages/Login' })
        return
      }
      this.loadUserData()
    } catch (err) {
      router.replaceUrl({ url: 'pages/Login' })
    }
  }
}

interface TabItem {
  name: string
  icon: string
  path: string
}