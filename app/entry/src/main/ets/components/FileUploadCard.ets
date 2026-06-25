import picker from '@ohos.file.picker'
import promptAction from '@ohos.promptAction'

@Component
export struct FileUploadCard {
  @State selectedFileName: string = ''
  @State isUploading: boolean = false

  onFileSelect: (uri: string) => void = () => {}
  supportedFormats: string[] = ['.pdf', '.docx', '.txt']

  build() {
    Column() {
      Column() {
        Text('📎')
          .fontSize(48)
          .fontColor('#409EFF')

        Text(this.selectedFileName || '选择文件')
          .fontSize(16)
          .fontColor('#333')
          .margin({ top: 12 })

        Text(`支持 ${this.supportedFormats.join('/')} 格式`)
          .fontSize(12)
          .fontColor('#999')
          .margin({ top: 8 })

        if (this.isUploading) {
          Text('上传中...')
            .fontSize(12)
            .fontColor('#409EFF')
            .margin({ top: 8 })
        }
      }
      .width('100%')
      .height(160)
      .backgroundColor('#f5f7fa')
      .borderRadius(12)
      .border({ width: 2, color: '#e0e0e0', style: BorderStyle.Dashed })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => this.selectFile())
    }
    .width('100%')
    .padding(12)
  }

  private async selectFile(): Promise<void> {
    try {
      const documentPicker = new picker.DocumentViewPicker()

      const result = await documentPicker.select({
        fileSuffixFilters: this.supportedFormats
      })

      if (result && result.length > 0) {
        const fileUri: string = result[0]
        const fileName: string = fileUri.split('/').pop() || ''

        if (this.validateFile(fileUri)) {
          this.selectedFileName = fileName
          this.onFileSelect(fileUri)
        } else {
          promptAction.showToast({
            message: `不支持该文件格式，仅支持 ${this.supportedFormats.join('/')}`,
            duration: 3000
          })
        }
      }
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : '文件选择失败'
      console.error(`FileUploadCard selectFile error: ${errorMessage}`)

      promptAction.showToast({
        message: errorMessage,
        duration: 3000
      })
    }
  }

  private validateFile(uri: string): boolean {
    const lowerUri: string = uri.toLowerCase()
    return this.supportedFormats.some((format: string) => lowerUri.endsWith(format.toLowerCase()))
  }

  reset(): void {
    this.selectedFileName = ''
    this.isUploading = false
  }

  setUploading(isUploading: boolean): void {
    this.isUploading = isUploading
  }

  getSelectedFileName(): string {
    return this.selectedFileName
  }
}