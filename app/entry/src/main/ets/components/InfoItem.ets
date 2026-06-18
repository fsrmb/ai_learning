@Component
export struct InfoItem {
  @Prop label: string = ''
  @Prop value: string = ''
  @Prop showArrow: boolean = false
  onTap: () => void = () => {}

  build() {
    Column() {
      Row() {
        Text(this.label)
          .fontSize(15)
          .fontColor('#666666')

        Blank()

        Text(this.value)
          .fontSize(15)
          .fontColor('#333333')
          .maxLines(1)

        if (this.showArrow) {
          Text('→')
            .fontSize(14)
            .fontColor('#cccccc')
            .margin({ left: 8 })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 18, bottom: 18 })
      .backgroundColor('#FFFFFF')
      .onClick(this.onTap)

      Divider()
        .width('100%')
        .height(0.5)
        .color('#f5f5f5')
    }
    .width('100%')
  }
}