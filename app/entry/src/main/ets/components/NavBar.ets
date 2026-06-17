import { router } from '@kit.ArkUI'

@Component
export struct NavBar {
  @Prop title: string = ''
  @Prop showBack: boolean = true
  @Prop backUrl: string = ''

  build() {
    Row() {
      if (this.showBack) {
        Text('←')
          .fontSize(24)
          .fontColor('#333333')
          .padding({ left: 16 })
          .onClick(() => {
            if (this.backUrl !== '') {
              router.pushUrl({ url: this.backUrl })
            } else {
              router.back()
            }
          })
      }

      Blank()

      Text(this.title)
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
  }
}