import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { picker } from '@kit.CoreFileKit'
import { TokenUtil } from '../common/TokenUtil'
import { AvatarUtil } from '../common/AvatarUtil'
import { NavBar } from '../components/NavBar'
import { InfoItem } from '../components/InfoItem'
import { LoadingView } from '../components/LoadingView'
import { AuthApi } from '../http/AuthApi'
import { UserVO, UpdateUserRequest } from '../model/User'

@Entry
@Component
struct Profile {
  @State isEditing: boolean = false
  @State loading: boolean = true
  @State saveLoading: boolean = false
  @State avatarLoading: boolean = false
  @State userInfo: UserVO = new UserVO()
  @State editNickname: string = ''
  @State avatarPath: string = ''

  async aboutToAppear(): Promise<void> {
    await this.loadUserInfo()
  }

  private async loadUserInfo(): Promise<void> {
    this.loading = true
    try {
      const user: UserVO = await AuthApi.getCurrentUser()
      this.userInfo = user
      this.editNickname = user.nickname
      console.info('Profile: Loaded user info - id:', user.id, 'nickname:', user.nickname, 'avatar:', user.avatar)
      if (user.avatar && AvatarUtil.avatarExists(user.avatar)) {
        this.avatarPath = user.avatar
      } else {
        this.avatarPath = ''
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '获取用户信息失败'
      console.error('Profile: Failed to load user info:', errorMessage)
      promptAction.showToast({
        message: errorMessage,
        duration: 2000
      })
    } finally {
      this.loading = false
    }
  }

  private async handleAvatarClick(): Promise<void> {
    if (this.avatarLoading) {
      return
    }

    promptAction.showDialog({
      title: '选择图片来源',
      message: '请选择要使用的图片来源',
      buttons: [
        {
          text: '相册',
          color: '#667eea'
        },
        {
          text: '文件',
          color: '#667eea'
        }
      ]
    }).then(async (result) => {
      if (result.index === 0) {
        await this.selectFromGallery()
      } else if (result.index === 1) {
        await this.selectFromFiles()
      }
    }).catch((error: Error) => {
      console.error('Profile: Dialog error:', error)
    })
  }

  private async selectFromGallery(): Promise<void> {
    try {
      const photoPicker = new photoAccessHelper.PhotoViewPicker()
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions()
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      photoSelectOptions.maxSelectNumber = 1

      const photoSelectResult = await photoPicker.select(photoSelectOptions)
      if (photoSelectResult.photoUris.length === 0) {
        return
      }

      const selectedUri = photoSelectResult.photoUris[0]
      console.info('Profile: Selected from Gallery - URI:', selectedUri)
      await this.processAvatar(selectedUri)
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '从相册选择失败'
      console.error('Profile: Failed to select from gallery:', errorMessage)
      promptAction.showToast({
        message: errorMessage,
        duration: 2000
      })
    }
  }

  private async selectFromFiles(): Promise<void> {
    try {
      const documentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.maxSelectNumber = 1

      const documentPicker = new picker.DocumentViewPicker()
      const documentSelectResult = await documentPicker.select(documentSelectOptions)
      if (documentSelectResult.length === 0) {
        return
      }

      const selectedUri = documentSelectResult[0]
      console.info('Profile: Selected from Files - URI:', selectedUri)
      await this.processAvatar(selectedUri)
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '从文件选择失败'
      console.error('Profile: Failed to select from files:', errorMessage)
      promptAction.showToast({
        message: errorMessage,
        duration: 2000
      })
    }
  }

  private async processAvatar(selectedUri: string): Promise<void> {
    this.avatarLoading = true
    promptAction.showToast({
      message: '正在更新头像...',
      duration: 1000
    })

    try {
      const avatarPath = await AvatarUtil.saveAvatar(selectedUri, this.userInfo.username)
      this.avatarPath = avatarPath

      const updateRequest = new UpdateUserRequest()
      updateRequest.avatar = avatarPath
      await AuthApi.updateUser(updateRequest)

      this.userInfo.avatar = avatarPath
      promptAction.showToast({
        message: '头像更新成功',
        duration: 2000
      })
      console.info('Profile: Avatar updated successfully -', avatarPath)
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '头像更新失败'
      console.error('Profile: Failed to process avatar:', errorMessage)
      promptAction.showToast({
        message: errorMessage,
        duration: 2000
      })
    } finally {
      this.avatarLoading = false
    }
  }

  private async handleSave(): Promise<void> {
    if (this.editNickname.trim() === '') {
      promptAction.showToast({
        message: '昵称不能为空',
        duration: 2000
      })
      return
    }

    this.saveLoading = true
    try {
      const updateRequest = new UpdateUserRequest()
      updateRequest.nickname = this.editNickname
      await AuthApi.updateUser(updateRequest)
      this.userInfo.nickname = this.editNickname
      this.isEditing = false
      await TokenUtil.saveNickname(this.editNickname)
      promptAction.showToast({
        message: '保存成功',
        duration: 2000
      })
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : '保存失败'
      console.error('Profile: Failed to save user info:', errorMessage)
      promptAction.showToast({
        message: errorMessage,
        duration: 2000
      })
    } finally {
      this.saveLoading = false
    }
  }

  build() {
    Column() {
      NavBar({ title: '我的资料', showBack: true })

      if (this.loading) {
        LoadingView({ color: '#667eea' })
      } else {
        Column({ space: 0 }) {
          Column() {
            Stack() {
              if (this.avatarPath !== '') {
                Image(this.avatarPath)
                  .width(100)
                  .height(100)
                  .borderRadius(50)
                  .objectFit(ImageFit.Cover)
                  .backgroundColor('#f0f0f0')
              } else {
                Image($r('app.media.default_avatar'))
                  .width(100)
                  .height(100)
                  .borderRadius(50)
                  .objectFit(ImageFit.Cover)
                  .backgroundColor('#f0f0f0')
              }

              if (this.avatarLoading) {
                Column() {
                  LoadingProgress()
                    .width(30)
                    .height(30)
                    .color('#667eea')
                }
                .width(100)
                .height(100)
                .borderRadius(50)
                .backgroundColor('rgba(0,0,0,0.3)')
                .justifyContent(FlexAlign.Center)
              }

              Text('更换')
                .fontSize(12)
                .fontColor(Color.White)
                .backgroundColor('rgba(0,0,0,0.5)')
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(8)
                .position({ x: 70, y: 70 })
            }
            .width(100)
            .height(100)
            .onClick(() => {
              this.handleAvatarClick()
            })

            if (this.isEditing) {
              TextInput({ text: this.editNickname, placeholder: '请输入昵称' })
                .width('80%')
                .maxLength(20)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .margin({ top: 16 })
                .onChange((value: string) => {
                  this.editNickname = value
                })
            } else {
              Text(this.userInfo.nickname || this.userInfo.username)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .margin({ top: 16 })
            }

            Text(this.userInfo.role === 'ADMIN' ? '管理员' : '学生')
              .fontSize(12)
              .fontColor('#667eea')
              .backgroundColor('#e8edff')
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(10)
              .margin({ top: 8 })
          }
          .width('100%')
          .padding({ top: 30, bottom: 30 })
          .backgroundColor('#FFFFFF')

          Divider()
            .width('100%')
            .height(1)
            .color('#f0f0f0')

          InfoItem({ label: '用户名', value: this.userInfo.username })
          InfoItem({ label: '昵称', value: this.userInfo.nickname || this.userInfo.username })
          InfoItem({ label: '邮箱', value: this.userInfo.email || '未绑定' })
          InfoItem({ label: '手机号', value: this.userInfo.phone || '未绑定' })
          InfoItem({ label: '角色', value: this.userInfo.role === 'ADMIN' ? '管理员' : '学生' })
          InfoItem({ label: '注册时间', value: this.userInfo.createTime ? this.userInfo.createTime.substring(0, 10) : '未知' })

          Button(this.isEditing ? (this.saveLoading ? '保存中...' : '保存') : '编辑')
            .width('90%')
            .height(44)
            .borderRadius(22)
            .backgroundColor(this.isEditing ? '#4A90D9' : '#F5A623')
            .fontColor(Color.White)
            .fontSize(16)
            .margin({ top: 20 })
            .enabled(!this.saveLoading)
            .onClick(() => {
              if (this.isEditing) {
                this.handleSave()
              } else {
                this.isEditing = true
              }
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
}