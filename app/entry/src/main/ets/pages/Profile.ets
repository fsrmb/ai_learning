import { router } from '@kit.ArkUI'
import { TokenUtil } from '../common/TokenUtil'

@Entry
@Component
struct Profile {
  // 状态变量
  @State isEditing: boolean = false;
  @State name: string = 'WXB';
  @State job: string = '全栈开发工程师';
  // 个人简介不可编辑（固定内容）
  private bio: string = '热爱技术，专注 HarmonyOS 与 AI 应用开发，喜欢分享与创造。';

  build() {
    Column({ space: 20 }) {
      // 1. 头像
      Image($r('app.media.avatar'))
        .width(120)
        .height(120)
        .borderRadius(60)          // 圆形
        .objectFit(ImageFit.Cover) // 覆盖裁剪
        .backgroundColor('#f0f0f0')

      // 2. 姓名（可编辑）
      if (this.isEditing) {
        TextInput({ text: this.name, placeholder: '请输入姓名' })
          .width('80%')
          .maxLength(20)
          .onChange((value: string) => {
            this.name = value;
          })
      } else {
        Text(this.name)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }

      // 3. 职业（可编辑）
      if (this.isEditing) {
        TextInput({ text: this.job, placeholder: '请输入职业' })
          .width('80%')
          .maxLength(30)
          .onChange((value: string) => {
            this.job = value;
          })
      } else {
        Text(this.job)
          .fontSize(18)
          .fontColor('#666666')
      }

      // 4. 个人简介（始终只读）
      Text(this.bio)
        .fontSize(16)
        .fontColor('#444444')
        .textAlign(TextAlign.Center)
        .padding({ left: 30, right: 30 })
        .lineHeight(24)

      // 5. 切换按钮
      Button(this.isEditing ? '保存' : '编辑')
        .width('60%')
        .height(44)
        .borderRadius(22)
        .backgroundColor(this.isEditing ? '#4A90D9' : '#F5A623')
        .fontColor(Color.White)
        .fontSize(16)
        .onClick(() => {
          // 切换编辑状态
          this.isEditing = !this.isEditing;
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)  // 垂直居中
    .padding(20)
    .backgroundColor('#F8F9FA')
  }
}