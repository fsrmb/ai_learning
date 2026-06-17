@Component
export struct LoadingView {
  @Prop color: string = '#667eea'
  @Prop size: number = 50

  build() {
    Column() {
      LoadingProgress()
        .width(this.size)
        .height(this.size)
        .color(this.color)
    }
    .width('100%')
    .flexGrow(1)
    .justifyContent(FlexAlign.Center)
  }
}