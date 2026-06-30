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

  build() {
    Column() {
      Row() {
        Text('AI 伴学助手')
          .fontSize(20).fontColor('#FFFFFF')
      }
      .width('100%').height(56).backgroundColor('#4A90D9')
      .justifyContent(FlexAlign.Center)

      List() {
        ForEach(this.messages, (msg: ChatMessage) => {
          ListItem() {
            if (msg.role === 'user') {
              Row() {
                Blank()
                Column() {
                  Text(msg.content)
                    .fontSize(16)
                    .fontColor('#FFFFFF')
                    .padding(12)
                    .borderRadius(16)
                    .backgroundColor('#4A90D9')
                }
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
                    .backgroundColor('#F0F0F0')
                    .borderRadius(16)
                    .javaScriptAccess(true)
                    .zoomAccess(false)
                    .padding(12)
                }
                .width('70%')
              }
              .width('100%')
              .padding({ left: 12, right: 60, top: 8, bottom: 8 })
            }
          }
        })

        if (this.isStreaming) {
          ListItem() {
            Row() {
              Column() {
                if (this.streamingContent) {
                  Web({
                    src: `data:text/html,${encodeURIComponent(MarkdownUtil.toHtmlWithCustomStyle(this.streamingContent))}`,
                    controller: new webview.WebviewController(),
                    renderMode: RenderMode.SYNC_RENDER
                  })
                    .layoutMode(WebLayoutMode.FIT_CONTENT)
                    .overScrollMode(OverScrollMode.NEVER)
                    .width('100%')
                    .backgroundColor('#F0F0F0')
                    .borderRadius(16)
                    .javaScriptAccess(true)
                    .zoomAccess(false)
                    .padding(12)
                } else {
                  Text('💭 AI 正在思考...')
                    .fontSize(14)
                    .fontColor('#999')
                    .padding(12)
                    .backgroundColor('#F0F0F0')
                    .borderRadius(16)
                }
              }
              .width('70%')
            }
            .width('100%')
            .padding({ left: 12, right: 60, top: 8, bottom: 8 })
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

    ChatApiService.streamChat(
      userMsg,
      (chunk: string) => {
        this.streamingContent += chunk
      },
      () => {
        if (this.streamingContent) {
          this.messages.push(new ChatMessage('assistant', this.streamingContent, false))
        }
        this.streamingContent = ''
        this.isStreaming = false
      },
      (err: string) => {
        this.messages.push(new ChatMessage('assistant', 'AI 暂时无法回复：' + err, false))
        this.streamingContent = ''
        this.isStreaming = false
      }
    )
  }
}
