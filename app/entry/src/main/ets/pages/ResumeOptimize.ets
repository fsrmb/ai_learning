import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'
import { ResumeOptimizeViewModel } from '../viewmodel/ResumeOptimizeViewModel'
import { ChatMessage } from '../model/ChatMessage'
import { DateUtil } from '../common/DateUtil'
import { MarkdownUtil } from '../common/MarkdownUtil'
import { webview } from '@kit.ArkWeb'
import { FileUploadCard } from '../components/FileUploadCard'
import { ConversationRecord } from '../common/ConversationHistory'
import GlobalContext from '../common/GlobalContext'

@Entry
@Component
struct ResumeOptimizePage {
  @State viewModel: ResumeOptimizeViewModel = new ResumeOptimizeViewModel()
  @State inputText: string = ''
  @State selectedFileUri: string = ''
  @State showHistory: boolean = false
  @State mainContentOffset: number = 0
  @State historyPanelOffset: number = -100
  @State fileUploadKey: string = '0'
  private scroller: Scroller = new Scroller()

  onPageShow(): void {
    const context = GlobalContext.getInstance().getContext()
    if (context) {
      this.viewModel.initHistory(context)
    }
  }

  openHistory(): void {
    animateTo({
      duration: 300,
      curve: Curve.EaseOut,
      iterations: 1,
      playMode: PlayMode.Normal
    }, () => {
      this.showHistory = true
      this.mainContentOffset = 75
      this.historyPanelOffset = 0
    })
  }

  closeHistory(): void {
    animateTo({
      duration: 300,
      curve: Curve.EaseOut,
      iterations: 1,
      playMode: PlayMode.Normal
    }, () => {
      this.mainContentOffset = 0
      this.historyPanelOffset = -100
    })
    setTimeout(() => {
      this.showHistory = false
    }, 300)
  }

  async selectConversation(record: ConversationRecord): Promise<void> {
    await this.viewModel.switchConversation(record)
    this.closeHistory()
  }

  async deleteConversation(record: ConversationRecord): Promise<void> {
    await this.viewModel.deleteConversation(record)
  }

  onFileSelect(uri: string): void {
    this.selectedFileUri = uri
  }

  async sendResume(): Promise<void> {
    const content = this.inputText.trim()

    if (!this.selectedFileUri && !content) {
      promptAction.showToast({
        message: '请上传文件或输入简历内容',
        duration: 3000
      })
      return
    }

    await this.viewModel.sendResume(content, this.selectedFileUri)

    this.inputText = ''
    this.selectedFileUri = ''
    this.fileUploadKey = Date.now().toString()

    setTimeout(() => {
      this.scroller.scrollToIndex(this.viewModel.messages.length - 1)
    }, 100)
  }

  async newConversation(): Promise<void> {
    await this.viewModel.newConversation()
    this.selectedFileUri = ''
    this.inputText = ''
    this.fileUploadKey = Date.now().toString()
  }

  showDeleteConfirm(record: ConversationRecord): void {
    promptAction.showDialog({
      title: '删除确认',
      message: '确定要删除这条对话记录吗？',
      buttons: [
        {
          text: '取消',
          color: '#666666'
        },
        {
          text: '删除',
          color: '#F56C6C'
        }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index === 1) {
        this.deleteConversation(record)
      }
    }).catch((error: Error) => {
      console.error('showDialog error:', error)
    })
  }

  build() {
    Row() {
      Column() {
        Row() {
          Row() {
            Text('←')
              .fontSize(20)
              .fontColor('#409EFF')
              .margin({ right: 12 })
              .onClick(() => router.back())
            Text('≡')
              .fontSize(24)
              .fontColor('#333')
              .onClick(() => {
                if (this.showHistory) {
                  this.closeHistory()
                } else {
                  this.openHistory()
                }
              })
          }

          Blank()

          Column() {
            Text(this.viewModel.currentTitle || '简历优化')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1a1a2e')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Center)

          Blank()

          Text('+')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#fff')
            .width(36)
            .height(36)
            .textAlign(TextAlign.Center)
            .borderRadius(18)
            .backgroundColor('#409EFF')
            .onClick(async () => {
              await this.newConversation()
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#fff')

        Column() {
          if (this.viewModel.messages.length === 0) {
            Column() {
              Text('📄 简历优化')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1a1a2e')
                .margin({ bottom: 8 })

              Text('上传简历或输入内容，AI 帮你优化')
                .fontSize(14)
                .fontColor('#8898aa')
                .margin({ bottom: 20 })

              FileUploadCard({
                onFileSelect: (uri: string) => {
                  this.selectedFileUri = uri
                }
              })
                .key(this.fileUploadKey)

              Text('或')
                .fontSize(12)
                .fontColor('#ccc')
                .margin({ top: 12, bottom: 12 })

              TextArea({ placeholder: '请输入简历内容...' })
                .width('100%')
                .height(150)
                .fontSize(16)
                .backgroundColor('#fff')
                .borderRadius(12)
                .padding(12)
                .onChange((value: string) => {
                  this.inputText = value
                })

              Button('发送')
                .width('100%')
                .height(44)
                .fontSize(16)
                .fontColor('#fff')
                .backgroundColor('#409EFF')
                .borderRadius(8)
                .margin({ top: 16 })
                .enabled(!this.viewModel.sending)
                .onClick(() => {
                  this.sendResume()
                })
            }
            .width('100%')
            .padding(20)
            .layoutWeight(1)
            .justifyContent(FlexAlign.Start)
          } else {
            List({ scroller: this.scroller }) {
              ForEach(this.viewModel.messages, (msg: ChatMessage) => {
                ListItem() {
                  if (msg.role === 'user') {
                    Row() {
                      Blank()
                      Column() {
                        Text(msg.content)
                          .fontSize(16)
                          .fontColor('#fff')
                          .padding(12)
                          .borderRadius(12)
                          .backgroundColor('#409EFF')
                        Text(DateUtil.format(msg.timestamp))
                          .fontSize(10)
                          .fontColor('#ccc')
                          .margin({ top: 4 })
                      }
                      .alignItems(HorizontalAlign.End)
                    }
                    .width('100%')
                    .padding({ left: 60, right: 12, top: 8, bottom: 8 })
                  } else {
                    Row() {
                      Column() {
                        Web({
                          src: `data:text/html,${encodeURIComponent(MarkdownUtil.toHtmlWithCustomStyle(msg.content))}`,
                          controller: new webview.WebviewController(),
                          renderMode: RenderMode.SYNC_RENDER
                        })
                          .layoutMode(WebLayoutMode.FIT_CONTENT)
                          .overScrollMode(OverScrollMode.NEVER)
                          .width('100%')
                          .backgroundColor('#F4F4F5')
                          .borderRadius(12)
                          .javaScriptAccess(true)
                          .zoomAccess(false)
                          .padding(12)
                      }
                      .height('auto')
                      .width('70%')
                      .borderRadius(12)
                      .backgroundColor('#F4F4F5')
                    }
                    .alignItems(VerticalAlign.Top)
                    .padding({ left: 12, right: 60, top: 8, bottom: 8 })
                    .width('100%')
                  }
                }
              })
            }
            .width('100%')
            .layoutWeight(1)
            .scrollBar(BarState.Auto)

            Row() {
              Button('新建对话')
                .width('100%')
                .height(44)
                .fontSize(16)
                .fontColor('#fff')
                .backgroundColor('#409EFF')
                .borderRadius(8)
                .onClick(() => {
                  this.newConversation()
                })
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#fff')
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')
      .translate({ x: `${this.mainContentOffset}%`, y: 0 })
      .animation({ duration: 300, curve: Curve.EaseOut })
      .backgroundColor('#f5f7fa')

      Column() {
        Row() {
          Text('历史对话')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1a1a2e')
          Blank()
          Text('×')
            .fontSize(18)
            .fontColor('#999')
            .onClick(() => this.closeHistory())
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 12 })
        .backgroundColor('#ffffff')

        Divider()
          .color('#f0f0f0')
          .strokeWidth(1)

        if (this.viewModel.history.length === 0) {
          Column() {
            Text('📭')
              .fontSize(48)
              .margin({ bottom: 12 })
            Text('暂无历史对话')
              .fontSize(14)
              .fontColor('#999')
          }
          .width('100%')
          .flexGrow(1)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#fafafa')
        } else {
          List() {
            ForEach(this.viewModel.history, (item: ConversationRecord) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(item.title)
                      .fontSize(16)
                      .fontColor(item.conversationId === '' ? '#409EFF' : '#333')
                      .fontWeight(item.conversationId === '' ? FontWeight.Medium : FontWeight.Normal)
                    Text(item.lastMessage)
                      .fontSize(12)
                      .fontColor('#999')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ top: 4 })
                    Text(DateUtil.format(item.timestamp))
                      .fontSize(10)
                      .fontColor('#ccc')
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Text('×')
                    .fontSize(18)
                    .fontColor('#999')
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .margin({ left: 8 })
                    .onClick(() => {
                      this.showDeleteConfirm(item)
                    })
                }
                .width('100%')
                .padding(12)
                .backgroundColor(item.conversationId === '' ? '#ecf5ff' : '#fff')
                .borderRadius(8)
                .onClick(() => this.selectConversation(item))
              }
              .margin({ left: 12, right: 12, top: 8 })
            }, (item: ConversationRecord) => item.conversationId)
          }
          .width('100%')
          .flexGrow(1)
          .backgroundColor('#fafafa')
          .padding({ bottom: 12 })
        }

        Text('提示：点击对话可继续之前的会话')
          .fontSize(12)
          .fontColor('#ccc')
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(12)
          .backgroundColor('#ffffff')
      }
      .width('75%')
      .height('100%')
      .backgroundColor('#ffffff')
      .position({ x: 0, y: 0 })
      .translate({ x: `${this.historyPanelOffset}%`, y: 0 })
      .animation({ duration: 300, curve: Curve.EaseOut })
    }
    .width('100%')
    .height('100%')
  }
}