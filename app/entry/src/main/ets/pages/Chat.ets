import { ChatApiService } from '../http/ChatApiService'
import { ChatMessage } from '../model/ChatMessage'
import { MarkdownUtil } from '../common/MarkdownUtil'
import { webview } from '@kit.ArkWeb'

@Entry
@Component
struct Chat {
  @State messages: ChatMessage[] = []
  @State inputText: string = ''
  @State isStreaming: boolean = false
  @State streamingContent: string = ''
  
  private scroller: Scroller = new Scroller()
  
  private lastUpdateTime: number = 0

  build() {
    Column() {
      Row() {
        Text('AI 伴学助手')
          .fontSize(20).fontColor('#FFFFFF')
      }
      .width('100%').height(56).backgroundColor('#4A90D9')
      .justifyContent(FlexAlign.Center)

      List({ scroller: this.scroller }) {
        ForEach(this.messages, (msg: ChatMessage) => {
          ListItem() {
            if (msg.role === 'user') {
              Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.End }) {
                Column() {
                  Text(msg.content)
                    .fontSize(18)
                    .fontColor('#FFFFFF')
                    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                    .borderRadius(18)
                    .backgroundColor('#4A90D9')
                }
                .width('auto')
                .constraintSize({ maxWidth: '75%' })
              }
              .width('100%')
              .padding({ left: 16, right: 12, top: 4, bottom: 4 })
            } else {
              Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Start }) {
                Column() {
                  Web({
                    src: `data:text/html,${encodeURIComponent(MarkdownUtil.toHtmlWithCustomStyle(msg.content))}`,
                    controller: new webview.WebviewController(),
                    renderMode: RenderMode.SYNC_RENDER
                  })
                    .layoutMode(WebLayoutMode.FIT_CONTENT)
                    .overScrollMode(OverScrollMode.NEVER)
                    .width('100%')
                    .backgroundColor('#F0F0F0')
                    .borderRadius(18)
                    .javaScriptAccess(true)
                    .zoomAccess(false)
                    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                }
                .width('75%')
                .borderRadius(18)
                .backgroundColor('#F0F0F0')
              }
              .width('100%')
              .padding({ left: 12, right: 16, top: 4, bottom: 4 })
            }
          }
        })

        if (this.isStreaming) {
          ListItem() {
            Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Start }) {
              Column() {
                Web({
                  src: `data:text/html,${encodeURIComponent(MarkdownUtil.toHtmlWithCustomStyle(this.streamingContent))}`,
                  controller: new webview.WebviewController(),
                  renderMode: RenderMode.SYNC_RENDER
                })
                  .layoutMode(WebLayoutMode.FIT_CONTENT)
                  .overScrollMode(OverScrollMode.NEVER)
                  .width('100%')
                  .backgroundColor('#F0F0F0')
                  .borderRadius(18)
                  .javaScriptAccess(true)
                  .zoomAccess(false)
                  .padding({ left: 16, right: 16, top: 12, bottom: 12 })
              }
              .width('75%')
              .borderRadius(18)
              .backgroundColor('#F0F0F0')
            }
            .width('100%')
            .padding({ left: 12, right: 16, top: 4, bottom: 4 })
          }
        }
      }
      .layoutWeight(1).width('100%')

      Row() {
        TextInput({ placeholder: '输入你的问题...', text: this.inputText })
          .layoutWeight(1).height(44).borderRadius(22).backgroundColor('#F5F5F5')
          .onChange((value: string) => { this.inputText = value })

        Button('发送')
          .height(44).margin({ left: 8 }).borderRadius(22)
          .backgroundColor('#4A90D9').fontColor('#FFFFFF')
          .enabled(this.inputText.trim().length > 0 && !this.isStreaming)
          .onClick(() => { this.sendMessage() })
      }
      .width('100%').padding(12)
    }
    .width('100%').height('100%')
  }

  sendMessage() {
    const userMsg = this.inputText.trim()
    if (userMsg.length === 0 || this.isStreaming) return

    this.messages.push(new ChatMessage('user', userMsg))
    this.inputText = ''
    this.isStreaming = true
    this.streamingContent = ''
    this.lastUpdateTime = 0

    setTimeout(() => {
      this.scroller.scrollToIndex(this.messages.length - 1)
    }, 100)

    ChatApiService.streamChat(
      userMsg,
      (chunk: string) => {
        this.streamingContent += chunk
        
        const now = Date.now()
        if (now - this.lastUpdateTime >= 100) {
          this.lastUpdateTime = now
          setTimeout(() => {
            this.scroller.scrollToIndex(this.messages.length)
          }, 50)
        }
      },
      () => {
        if (this.streamingContent) {
          this.messages.push(new ChatMessage('assistant', this.streamingContent, false))
        }
        this.streamingContent = ''
        this.isStreaming = false
        setTimeout(() => {
          this.scroller.scrollToIndex(this.messages.length - 1)
        }, 200)
      },
      (err: string) => {
        this.messages.push(new ChatMessage('assistant', 'AI 暂时无法回复：' + err, false))
        this.streamingContent = ''
        this.isStreaming = false
        setTimeout(() => {
          this.scroller.scrollToIndex(this.messages.length - 1)
        }, 200)
      }
    )
  }
}
