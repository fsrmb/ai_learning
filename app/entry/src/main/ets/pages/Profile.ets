import { router } from '@kit.ArkUI'
import { TokenUtil } from '../common/TokenUtil'

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
    Column({ space: 20 }) {
      if (this.loading) {
        LoadingProgress()
          .width(50)
          .height(50)
          .color('#667eea')
      } else {
        Image($r('app.media.avatar'))
          .width(120)
          .height(120)
          .borderRadius(60)
          .objectFit(ImageFit.Cover)
          .backgroundColor('#f0f0f0')

        if (this.isEditing) {
          TextInput({ text: this.name, placeholder: '请输入姓名' })
            .width('80%')
            .maxLength(20)
            .onChange((value: string) => {
              this.name = value
            })
        } else {
          Text(this.name)
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
        }

        if (this.isEditing) {
          TextInput({ text: this.job, placeholder: '请输入职业' })
            .width('80%')
            .maxLength(30)
            .onChange((value: string) => {
              this.job = value
            })
        } else {
          Text(this.job)
            .fontSize(18)
            .fontColor('#666666')
        }

        Text(this.bio)
          .fontSize(16)
          .fontColor('#444444')
          .textAlign(TextAlign.Center)
          .padding({ left: 30, right: 30 })
          .lineHeight(24)

        Button(this.isEditing ? '保存' : '编辑')
          .width('60%')
          .height(44)
          .borderRadius(22)
          .backgroundColor(this.isEditing ? '#4A90D9' : '#F5A623')
          .fontColor(Color.White)
          .fontSize(16)
          .onClick(() => {
            this.isEditing = !this.isEditing
          })

        Button('退出登录')
          .width('60%')
          .height(44)
          .borderRadius(22)
          .backgroundColor('#f56c6c')
          .fontColor(Color.White)
          .fontSize(16)
          .margin({ top: 10 })
          .onClick(async () => {
            await TokenUtil.clearAll()
            router.replaceUrl({ url: 'pages/Login' })
          })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(20)
    .backgroundColor('#F8F9FA')
  }
}