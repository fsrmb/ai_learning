import { router } from '@kit.ArkUI'
import { TokenUtil } from '../common/TokenUtil'

@Entry
@Component
struct MainTab {
  @State currentTab: number = 0

  private tabs: TabItem[] = [
    { name: '首页', icon: '🏠', path: '' },
    { name: '技能树', icon: '🌳', path: '' },
    { name: 'AI 聊天', icon: '💬', path: '' },
    { name: '我的', icon: '👤', path: '' }
  ]

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
        Text('欢迎使用 AI 伴学平台！')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1a1a2e')
          .margin({ bottom: 8 })

        Text('智能学习，助力成长')
          .fontSize(14)
          .fontColor('#8898aa')
      }
      .width('100%')
      .height('100%')
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
            this.currentTab = index
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
    const hasToken: boolean = await TokenUtil.hasToken()
    if (!hasToken) {
      router.replaceUrl({ url: 'pages/Login' })
    }
  }
}

interface TabItem {
  name: string
  icon: string
  path: string
}
