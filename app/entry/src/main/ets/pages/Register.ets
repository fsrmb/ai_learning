import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { IconInput } from '../components/IconInput'
import { ErrorTip } from '../components/ErrorTip'

@Entry
@Component
struct Register {
  @State username: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
  @State email: string = ''
  @State loading: boolean = false
  @State errorMessage: string = ''

  build() {
    Column() {
      Column() {
        Column() {
          Column() {
            Text('👤')
              .fontSize(48)
              .fontColor('#667eea')
          }
          .width(80)
          .height(80)
          .backgroundColor('#f0f0f0')
          .borderRadius(40)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .margin({ bottom: 20 })

        Text('用户注册')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a2e')
          .margin({ bottom: 8 })

        Text('创建账号，开始学习之旅')
          .fontSize(14)
          .fontColor('#8898aa')
      }
      .margin({ top: 60, bottom: 40 })

      Column() {
        Column() {
          Column() {
            Text('注册账号')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1a1a2e')
              .margin({ bottom: 4 })

            Text('请填写以下信息')
              .fontSize(14)
              .fontColor('#8898aa')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 24 })

          IconInput({
            icon: '👤',
            placeholder: '请输入用户名（6-20位）',
            value: $username,
            onChangeCallback: () => {
              this.errorMessage = ''
            }
          })
          .width('100%')
          .margin({ bottom: 16 })

          IconInput({
            icon: '📧',
            placeholder: '请输入邮箱',
            value: $email,
            onChangeCallback: () => {
              this.errorMessage = ''
            }
          })
          .width('100%')
          .margin({ bottom: 16 })

          IconInput({
            icon: '🔒',
            placeholder: '请输入密码（6位以上）',
            value: $password,
            showPasswordToggle: true,
            onChangeCallback: () => {
              this.errorMessage = ''
            }
          })
          .width('100%')
          .margin({ bottom: 16 })

          IconInput({
            icon: '🔒',
            placeholder: '请再次输入密码',
            value: $confirmPassword,
            showPasswordToggle: true,
            onChangeCallback: () => {
              this.errorMessage = ''
            }
          })
          .width('100%')
          .margin({ bottom: 16 })

          ErrorTip({ message: this.errorMessage })

          Button(this.loading ? '注册中...' : '注 册')
            .width('100%')
            .height(48)
            .backgroundColor('#667eea')
            .fontColor('#FFFFFF')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .borderRadius(12)
            .shadow({ radius: 8, color: '#667eea', offsetY: 4 })
            .onClick(() => {
              this.handleRegister()
            })
            .enabled(!this.loading)

          Row() {
            Text('已有账号？')
              .fontSize(14)
              .fontColor('#8898aa')

            Text('立即登录')
              .fontSize(14)
              .fontColor('#667eea')
              .fontWeight(FontWeight.Medium)
              .margin({ left: 4 })
              .onClick(() => {
                router.back()
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ top: 20 })
        }
        .width('100%')
        .padding(32)
        .backgroundColor('#FFFFFF')
        .borderRadius(20)
        .shadow({ radius: 15, color: '#000000', offsetY: 10 })
      }
      .width('100%')
      .padding({ left: 24, right: 24 })

      Blank()

      Text('© 2024 AI 伴学平台')
        .fontSize(12)
        .fontColor('#c0c4cc')
        .margin({ bottom: 30 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
  }

  private async handleRegister(): Promise<void> {
    if (this.username === '') {
      this.errorMessage = '请输入用户名'
      return
    }

    if (this.username.length < 6 || this.username.length > 20) {
      this.errorMessage = '用户名长度应为6-20位'
      return
    }

    if (this.email === '') {
      this.errorMessage = '请输入邮箱'
      return
    }

    if (this.password === '') {
      this.errorMessage = '请输入密码'
      return
    }

    if (this.password.length < 6) {
      this.errorMessage = '密码长度应至少6位'
      return
    }

    if (this.password !== this.confirmPassword) {
      this.errorMessage = '两次输入的密码不一致'
      return
    }

    this.loading = true
    this.errorMessage = ''

    try {
      await new Promise<void>((resolve) => setTimeout(resolve, 1000))

      promptAction.showToast({
        message: '注册成功！',
        duration: 2000,
        bottom: 100
      })

      setTimeout(() => {
        router.back()
      }, 1500)
    } catch (error) {
      this.errorMessage = '注册失败，请重试'
    } finally {
      this.loading = false
    }
  }
}