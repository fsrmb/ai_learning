@Component
export struct LoadingView {
  @Prop color: string = '#667eea'
  @Prop loadingSize: number = 50

  build() {
    Column() {
      LoadingProgress()
        .width(this.loadingSize)
        .height(this.loadingSize)
        .color(this.color)
    }
    .width('100%')
    .flexGrow(1)
    .justifyContent(FlexAlign.Center)
  }
}