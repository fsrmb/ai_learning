import { router } from '@kit.ArkUI'
import { UserViewModel } from '../viewmodel/UserViewModel'
import { TokenUtil } from '../common/TokenUtil'
import { IconInput } from '../components/IconInput'
import { ErrorTip } from '../components/ErrorTip'

@Entry
@Component
struct Login {
  @State username: string = ''
  @State password: string = ''
  @State loading: boolean = false
  @State errorMessage: string = ''
  @State rememberMe: boolean = false

  private userViewModel: UserViewModel = new UserViewModel()

  async aboutToAppear(): Promise<void> {
    await this.loadSavedCredentials()
  }

  private async loadSavedCredentials(): Promise<void> {
    try {
      const credentials = await TokenUtil.getLoginCredentials()
      if (credentials.rememberMe) {
        this.username = credentials.username
        this.password = credentials.password
        this.rememberMe = true
        console.info('Login: Loaded saved credentials')
      }
    } catch (err) {
      console.error('Login: Failed to load credentials:', err)
    }
  }

  build() {
    Column() {
      Column() {
        Column() {
          Column() {
            Text('智')
              .fontSize(48)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .width(80)
          .height(80)
          .backgroundColor('#667eea')
          .borderRadius(20)
          .shadow({ radius: 10, color: '#667eea', offsetY: 5 })
        }
        .margin({ bottom: 20 })

        Text('AI 伴学平台')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1a1a2e')
          .margin({ bottom: 8 })

        Text('智能学习，助力成长')
          .fontSize(14)
          .fontColor('#8898aa')
      }
      .margin({ top: 80, bottom: 40 })

      Column() {
        Column() {
          Column() {
            Text('欢迎回来')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1a1a2e')
              .margin({ bottom: 4 })

            Text('请登录您的账号')
              .fontSize(14)
              .fontColor('#8898aa')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 24 })

          IconInput({
            icon: '👤',
            placeholder: '请输入用户名',
            value: $username,
            onChangeCallback: () => {
              this.errorMessage = ''
            }
          })
          .width('100%')
          .margin({ bottom: 16 })

          IconInput({
            icon: '🔒',
            placeholder: '请输入密码',
            value: $password,
            showPasswordToggle: true,
            onChangeCallback: () => {
              this.errorMessage = ''
            }
          })
          .width('100%')
          .margin({ bottom: 16 })

          ErrorTip({ message: this.errorMessage })

          Row() {
            Checkbox({ name: 'remember', group: 'login' })
              .select(this.rememberMe)
              .selectedColor('#667eea')
              .onChange((value: boolean) => {
                this.rememberMe = value
              })

            Text('记住密码')
              .fontSize(13)
              .fontColor('#525f7f')
              .margin({ left: 8 })

            Blank()

            Text('忘记密码？')
              .fontSize(13)
              .fontColor('#667eea')
              .onClick(() => {
              })
          }
          .width('100%')
          .margin({ bottom: 24 })

          Button(this.loading ? '登录中...' : '登 录')
            .width('100%')
            .height(48)
            .backgroundColor('#667eea')
            .fontColor('#FFFFFF')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .borderRadius(12)
            .shadow({ radius: 8, color: '#667eea', offsetY: 4 })
            .onClick(() => {
              this.handleLogin()
            })
            .enabled(!this.loading)

          Row() {
            Text('还没有账号？')
              .fontSize(14)
              .fontColor('#8898aa')

            Text('立即注册')
              .fontSize(14)
              .fontColor('#667eea')
              .fontWeight(FontWeight.Medium)
              .margin({ left: 4 })
              .onClick(() => {
                router.pushUrl({ url: 'pages/Register' })
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

  private async handleLogin(): Promise<void> {
    if (this.username === '' || this.password === '') {
      this.errorMessage = '请输入用户名和密码'
      return
    }

    this.loading = true
    this.errorMessage = ''

    this.userViewModel.username = this.username
    this.userViewModel.password = this.password

    try {
      const success: boolean = await this.userViewModel.login()

      if (success) {
        if (this.rememberMe) {
          await TokenUtil.saveLoginCredentials(this.username, this.password, true)
          console.info('Login: Credentials saved')
        } else {
          await TokenUtil.clearLoginCredentials()
          console.info('Login: Credentials cleared')
        }

        router.replaceUrl({ url: 'pages/MainTab' })
      } else {
        this.errorMessage = this.userViewModel.errorMessage || '登录失败'
      }
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '登录失败，请重试'
    } finally {
      this.loading = false
    }
  }
}