@Component
export struct IconInput {
  @Prop icon: string = ''
  @Prop placeholder: string = ''
  @Prop inputType: InputType = InputType.Normal
  @Link value: string
  @Prop showPasswordToggle: boolean = false
  @State isPasswordVisible: boolean = false
  // 回调函数不能使用 @Prop 装饰器，使用普通属性即可
  onChangeCallback: (value: string) => void = () => {}

  build() {
    Row() {
      Text(this.icon)
        .fontSize(18)
        .margin({ right: 12 })

      TextInput({ placeholder: this.placeholder, text: this.value })
        .type(this.showPasswordToggle && !this.isPasswordVisible ? InputType.Password : InputType.Normal)
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontColor('#1a1a2e')
        .placeholderColor('#c0c4cc')
        .backgroundColor('#f5f7fa')
        .borderRadius(12)
        .padding({ left: 12 })
        .onChange((val: string) => {
          this.value = val
          this.onChangeCallback(val)
        })

      if (this.showPasswordToggle) {
        Text(this.isPasswordVisible ? '👁' : '👁️‍🗨')
          .fontSize(18)
          .margin({ left: 12 })
          .onClick(() => {
            this.isPasswordVisible = !this.isPasswordVisible
          })
      }
    }
    .width('100%')
    .backgroundColor('#f5f7fa')
    .borderRadius(12)
    .padding({ left: 16 })
    .padding({ right: this.showPasswordToggle ? 16 : 0 })
  }
}