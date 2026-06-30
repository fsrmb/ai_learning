import { ChatApiService } from '../http/ChatApiService'
import { ChatMessage } from '../model/ChatMessage'

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
            Row() {
              Text(msg.content)
                .fontSize(16)
                .fontColor(msg.role === 'user' ? '#FFFFFF' : '#333333')
                .padding(12)
                .backgroundColor(msg.role === 'user' ? '#4A90D9' : '#F0F0F0')
                .borderRadius(16)
            }
            .width('100%')
            .justifyContent(msg.role === 'user' ? FlexAlign.End : FlexAlign.Start)
          }
        })

        if (this.isStreaming) {
          ListItem() {
            Row() {
              Text(this.streamingContent || '思考中...')
                .fontSize(16)
                .fontColor('#333333')
                .padding(12)
                .backgroundColor('#F0F0F0')
                .borderRadius(16)
              Blank()
            }
            .width('100%')
          }
        }
      }
      .layoutWeight(1).width('100%').padding(16)

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