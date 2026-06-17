@Component
export struct ErrorTip {
  @Prop message: string = ''

  build() {
    if (this.message !== '') {
      Text(this.message)
        .fontSize(12)
        .fontColor('#f56c6c')
        .width('100%')
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })
    }
  }
}