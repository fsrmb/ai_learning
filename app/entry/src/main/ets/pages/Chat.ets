import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'
import { ChatApiService } from '../http/ChatApiService'
import { ChatMessage } from '../model/ChatMessage'
import { MarkdownUtil } from '../common/MarkdownUtil'
import { webview } from '@kit.ArkWeb'
import { DateUtil } from '../common/DateUtil'

interface ConversationRecord {
  conversationId: number
  title: string
  updatedAt: string
}
interface HistoryItem {
  conversationId: number
  title: string
  updatedAt: string   // 假设是字符串，根据你实际的类型调整
}
@Entry
@Component
struct Chat {
  @State messages: ChatMessage[] = []
  @State inputText: string = ''
  @State isStreaming: boolean = false
  @State streamingContent: string = ''
  @State showHistory: boolean = false
  @State mainContentOffset: number = 0
  @State historyPanelOffset: number = -100
  @State history: ConversationRecord[] = []
  @State currentTitle: string = 'AI 伴学助手'
  
  private scroller: Scroller = new Scroller()
  private lastUpdateTime: number = 0

  private sanitizeForUri(text: string): string {
    try {
      encodeURIComponent(text)
      return text
    } catch (e) {
      return text
        .replace(/%[0-9A-Fa-f]{2}/g, ' ')
        .replace(/[^\x00-\x7F]/g, '?')
    }
  }

  private getSafeWebSrc(content: string): string {
    try {
      const html = MarkdownUtil.toHtmlWithCustomStyle(content)
      return `data:text/html,${encodeURIComponent(html)}`
    } catch (e) {
      const safeText = this.sanitizeForUri(content)
      return `data:text/html,${encodeURIComponent(`<html><body style="font-family:sans-serif;padding:12px;">${safeText}</body></html>`)}`
    }
  }

  onPageShow(): void {
    this.loadHistory()
  }

  async loadHistory(): Promise<void> {
    try {
      const conversations = await ChatApiService.getConversations()
      this.history = conversations.map((c): HistoryItem => ({
        conversationId: c.conversationId,
        title: c.title,
        updatedAt: c.updatedAt
      }))
    } catch (err) {
      console.error('loadHistory failed:', err)
    }
  }

  openHistory(): void {
    this.loadHistory()
    animateTo({
      duration: 300,
      curve: Curve.EaseOut
    }, () => {
      this.showHistory = true
      this.mainContentOffset = 75
      this.historyPanelOffset = 0
    })
  }

  closeHistory(): void {
    animateTo({
      duration: 300,
      curve: Curve.EaseOut
    }, () => {
      this.mainContentOffset = 0
      this.historyPanelOffset = -100
    })
    setTimeout(() => {
      this.showHistory = false
    }, 300)
  }

  async selectConversation(record: ConversationRecord): Promise<void> {
    try {
      ChatApiService.setConversationId(record.conversationId)
      this.currentTitle = record.title
      
      const messageVOs = await ChatApiService.getMessageHistory(record.conversationId)
      this.messages = messageVOs.map(msg => new ChatMessage(msg.role.toLowerCase(), msg.content, false))
      
      setTimeout(() => {
        this.scroller.scrollToIndex(this.messages.length - 1)
      }, 100)
    } catch (err) {
      console.error('selectConversation failed:', err)
    }
    this.closeHistory()
  }

  async deleteConversation(conversationId: number): Promise<void> {
    try {
      await ChatApiService.deleteConversation(conversationId)
      
      this.history = this.history.filter(h => h.conversationId !== conversationId)
      
      if (ChatApiService.getConversationId() === conversationId) {
        await this.newConversation()
      }
    } catch (err) {
      console.error('deleteConversation failed:', err)
    }
  }

  showDeleteConfirm(conversationId: number, title: string): void {
    promptAction.showDialog({
      title: '删除确认',
      message: `确定要删除「${title}」吗？`,
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
        this.deleteConversation(conversationId)
      }
    }).catch((error: Error) => {
      console.error('showDialog error:', error)
    })
  }

  async newConversation(): Promise<void> {
    ChatApiService.resetConversation()
    this.messages = []
    this.currentTitle = 'AI 伴学助手'
    this.streamingContent = ''
    this.isStreaming = false
    this.closeHistory()
  }

  build() {
    Row() {
      Column() {
        Row() {
          Row() {
            // Text('←')
            //   .fontSize(20)
            //   .fontColor('#FFFFFF')
            //   .margin({ right: 12 })
            //   .onClick(() => router.back())

            Text('≡')
              .fontSize(24)
              .fontColor('#FFFFFF')
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
            Text(this.currentTitle)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .alignItems(HorizontalAlign.Center)

          Blank()

          Text('+')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .width(36)
            .height(36)
            .textAlign(TextAlign.Center)
            .borderRadius(18)
            .backgroundColor('rgba(255,255,255,0.2)')
            .onClick(async () => {
              await this.newConversation()
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#4A90D9')

        if (this.messages.length === 0 && !this.isStreaming) {
          Column() {
            Text('🤖')
              .fontSize(48)
            Text('你好！我是 AI 伴学助手')
              .fontSize(16)
              .fontColor('#333')
              .margin({ top: 12 })
            Text('点击「≡」查看历史对话')
              .fontSize(12)
              .fontColor('#999')
              .margin({ top: 8 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
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
                        src: this.getSafeWebSrc(msg.content),
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
                    Text(this.streamingContent)
                      .fontSize(18)
                      .fontColor('#333')
                      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                      .borderRadius(18)
                      .backgroundColor('#F0F0F0')
                      .width('100%')
                      .wordBreak( WordBreak.BREAK_ALL)
                    Text('正在输入...')
                      .fontSize(10)
                      .fontColor('#4A90D9')
                      .margin({ top: 4 })
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
          .layoutWeight(1)
          .width('100%')
        }

        Row() {
          TextInput({ placeholder: '输入你的问题...', text: this.inputText })
            .layoutWeight(1)
            .height(44)
            .borderRadius(22)
            .backgroundColor('#F5F5F5')
            .onChange((value: string) => { this.inputText = value })

          Button(this.isStreaming ? '...' : '发送')
            .height(44)
            .margin({ left: 8 })
            .borderRadius(22)
            .backgroundColor('#4A90D9')
            .fontColor('#FFFFFF')
            .enabled(!this.isStreaming && this.inputText.trim().length > 0)
            .onClick(() => { this.sendMessage() })
        }
        .width('100%')
        .padding(12)
      }
      .width('100%')
      .height('100%')
      .translate({ x: `${this.mainContentOffset}%`, y: 0 })
      .animation({ duration: 300, curve: Curve.EaseOut })

      Column() {
        Row() {
          Text('历史对话')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1a1a2e')
          Blank()
          Text('✕')
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

        if (this.history.length === 0) {
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
            ForEach(this.history, (item: ConversationRecord) => {
              ListItem() {
                Row() {
                  Column() {
                    Text(item.title)
                      .fontSize(16)
                      .fontColor(item.conversationId === ChatApiService.getConversationId() ? '#4A90D9' : '#333')
                      .fontWeight(item.conversationId === ChatApiService.getConversationId() ? FontWeight.Medium : FontWeight.Normal)
                    Text(DateUtil.format(new Date(item.updatedAt).getTime()))
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
                      this.showDeleteConfirm(item.conversationId, item.title)
                    })
                }
                .width('100%')
                .padding(12)
                .backgroundColor(item.conversationId === ChatApiService.getConversationId() ? '#ecf5ff' : '#fff')
                .borderRadius(8)
                .onClick(() => this.selectConversation(item))
              }
              .margin({ left: 12, right: 12, top: 8 })
            }, (item: ConversationRecord) => String(item.conversationId))
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

  sendMessage() {
    const userMsg = this.inputText.trim()
    if (userMsg.length === 0 || this.isStreaming) return

    this.messages.push(new ChatMessage('user', userMsg))
    this.inputText = ''
    this.isStreaming = true
    this.streamingContent = ''
    this.lastUpdateTime = 0

    if (!this.currentTitle || this.currentTitle === 'AI 伴学助手') {
      this.currentTitle = userMsg.substring(0, 20) + (userMsg.length > 20 ? '...' : '')
    }

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
        this.loadHistory()
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