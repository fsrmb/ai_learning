import { router } from '@kit.ArkUI'
import { TokenUtil } from '../common/TokenUtil'
import { NavBar } from '../components/NavBar'
import { InfoItem } from '../components/InfoItem'
import { LoadingView } from '../components/LoadingView'

@Entry
@Component
struct Profile {
  @State isEditing: boolean = false
  @State name: string = ''
  @State job: string = '全栈开发工程师'
  @State loading: boolean = true
  private bio: string = '热爱技术，专注 HarmonyOS 与 AI 应用开发，喜欢分享与创造。'

  async aboutToAppear(): Promise<void> {
    const username = await TokenUtil.getUsername()
    this.name = username !== '' ? username : '未登录'
    this.loading = false
  }

  build() {
    Column() {
      NavBar({ title: '我的资料', showBack: true })

      if (this.loading) {
        LoadingView({ color: '#667eea' })
      } else {
        Column({ space: 0 }) {
          Column() {
            Image($r('app.media.avatar'))
              .width(100)
              .height(100)
              .borderRadius(50)
              .objectFit(ImageFit.Cover)
              .backgroundColor('#f0f0f0')

            if (this.isEditing) {
              TextInput({ text: this.name, placeholder: '请输入姓名' })
                .width('80%')
                .maxLength(20)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .margin({ top: 16 })
                .onChange((value: string) => {
                  this.name = value
                })
            } else {
              Text(this.name)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .margin({ top: 16 })
            }

            Text(this.bio)
              .fontSize(14)
              .fontColor('#888888')
              .textAlign(TextAlign.Center)
              .padding({ left: 30, right: 30 })
              .margin({ top: 8 })
              .lineHeight(22)
          }
          .width('100%')
          .padding({ top: 30, bottom: 30 })
          .backgroundColor('#FFFFFF')

          Divider()
            .width('100%')
            .height(1)
            .color('#f0f0f0')

          InfoItem({ label: '昵称', value: this.name })
          InfoItem({ label: '职业', value: this.job })
          InfoItem({ label: '邮箱', value: 'example@email.com' })
          InfoItem({ label: '手机号', value: '138****8888' })
          InfoItem({ label: '注册时间', value: '2024-01-15' })

          Button(this.isEditing ? '保存' : '编辑')
            .width('90%')
            .height(44)
            .borderRadius(22)
            .backgroundColor(this.isEditing ? '#4A90D9' : '#F5A623')
            .fontColor(Color.White)
            .fontSize(16)
            .margin({ top: 20 })
            .onClick(() => {
              this.isEditing = !this.isEditing
            })

          Button('退出登录')
            .width('90%')
            .height(44)
            .borderRadius(22)
            .backgroundColor('#f56c6c')
            .fontColor(Color.White)
            .fontSize(16)
            .margin({ top: 12 })
            .onClick(async () => {
              await TokenUtil.clearAll()
              router.replaceUrl({ url: 'pages/Login' })
            })
        }
        .width('100%')
        .flexGrow(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }
}