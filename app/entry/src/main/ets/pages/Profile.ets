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
    Column() {
      Row() {
        Text('←')
          .fontSize(24)
          .fontColor('#333333')
          .padding({ left: 16 })
          .onClick(() => {
            router.back()
          })

        Blank()

        Text('我的资料')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Text('')
          .width(40)
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .alignItems(VerticalAlign.Center)

      if (this.loading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#667eea')
        }
        .width('100%')
        .flexGrow(1)
        .justifyContent(FlexAlign.Center)
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

          this.buildInfoItem('昵称', this.name)
          this.buildInfoItem('职业', this.job)
          this.buildInfoItem('邮箱', 'example@email.com')
          this.buildInfoItem('手机号', '138****8888')
          this.buildInfoItem('注册时间', '2024-01-15')

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

  @Builder
  buildInfoItem(label: string, value: string): void {
    Column() {
      Row() {
        Text(label)
          .fontSize(15)
          .fontColor('#666666')

        Blank()

        Text(value)
          .fontSize(15)
          .fontColor('#333333')
          .maxLines(1)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 18, bottom: 18 })
      .backgroundColor('#FFFFFF')

      Divider()
        .width('100%')
        .height(0.5)
        .color('#f5f5f5')
    }
    .width('100%')
  }
}