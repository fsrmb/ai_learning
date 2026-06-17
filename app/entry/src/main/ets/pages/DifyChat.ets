import { router } from '@kit.ArkUI'
import { DifyChatViewModel, Conversation } from '../viewmodel/DifyChatViewModel'
import { ChatMessage } from '../model/ChatMessage'
import { DateUtil } from '../common/DateUtil'
import { MarkdownUtil } from '../common/MarkdownUtil'

/**
 * Dify 聊天页面
 *
 * 与 AiChat.ets 的区别：
 *   - AiChat → 调用后端 /api/ai/chat/message（依赖 Spring Boot 后端）
 *   - DifyChat → 直接调用 Dify 平台 API（独立运行，不依赖后端）
 *
 * 功能：
 *   - blocking / streaming 两种模式切换
 *   - 多轮对话（conversation_id 自动传递）
 *   - 流式打字机效果
 *   - 对话历史面板
 *   - 新建对话 / 清空消息
 *
 * 使用前请在 main_pages.json 中注册 "pages/DifyChat"
 */
@Entry
@Component
struct DifyChatPage {
  @State viewModel: DifyChatViewModel = new DifyChatViewModel()
  @State inputText: string = ''
  private scroller: Scroller = new Scroller()


  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        // ===== Header =====
        Row() {
          Text('<')
            .fontSize(20)
            .fontColor('#409EFF')
            .margin({ right: 12 })
            .onClick(() => router.back())
          Text('AI对话（Dify）')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Blank()
          // 模式切换
          Text(this.viewModel.mode === 'blocking' ? '阻塞' : '流式')
            .fontSize(12)
            .fontColor('#fff')
            .backgroundColor(this.viewModel.mode === 'blocking' ? '#E6A23C' : '#67C23A')
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(10)
            .margin({ right: 8 })
            .onClick(() => this.viewModel.toggleMode())
          // 历史
          Text('历史')
            .fontSize(14)
            .fontColor('#E6A23C')
            .margin({ right: 8 })
            .onClick(() => this.viewModel.toggleHistory())
          // 新对话
          Text('新对话')
            .fontSize(14)
            .fontColor('#67C23A')
            .margin({ right: 8 })
            .onClick(() => this.viewModel.newConversation())
          // 清空
          Text('清空')
            .fontSize(14)
            .fontColor('#F56C6C')
            .onClick(() => this.viewModel.clearMessages())
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#fff')

        // ===== 消息列表 =====
        if (this.viewModel.messages.length === 0 && !this.viewModel.sending) {
          // 空状态(组件)
          Column() {
            Text('🤖')
              .fontSize(48)
            Text('你好！我是 AI 助手')
              .fontSize(16)
              .fontColor('#333')
              .margin({ top: 12 })
            Text(`当前模式：${this.viewModel.mode === 'blocking' ? '阻塞（同步等待）' : '流式（打字机效果）'}`)
              .fontSize(12)
              .fontColor('#999')
              .margin({ top: 8 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          // 消息列表
          List({ scroller: this.scroller }) {
            ForEach(this.viewModel.messages, (msg: ChatMessage) => {
              ListItem() {
                if (msg.role === 'user') {
                  // 用户消息：蓝色气泡，右对齐
                  Row() {
                    Blank()
                    Column() {
                      Text(msg.content)
                        .fontSize(15)
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
                  // AI 消息：灰色气泡，左对齐（Markdown 渲染）
                  Row() {
                    Column() {
                      // 并没有改变源数据
                      RichText(MarkdownUtil.toHtml(msg.content))
                        .width('100%')
                        .padding(12)
                        .borderRadius(12)
                        .backgroundColor('#F4F4F5')
                      Text(DateUtil.format(msg.timestamp))
                        .fontSize(10)
                        .fontColor('#ccc')
                        .margin({ top: 4 })
                    }
                    .alignItems(HorizontalAlign.Start)
                    Blank()
                  }
                  .width('100%')
                  .padding({ left: 12, right: 60, top: 8, bottom: 8 })
                }
              }
            })

            // 流式输出中的临时消息（Markdown 渲染）
            if (this.viewModel.sending && this.viewModel.streamingContent) {
              ListItem() {
                Row() {
                  Column() {
                    RichText(MarkdownUtil.toHtml(this.viewModel.streamingContent))
                      .width('100%')
                      .padding(12)
                      .borderRadius(12)
                      .backgroundColor('#F4F4F5')
                    Text('正在输入...')
                      .fontSize(10)
                      .fontColor('#409EFF')
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  Blank()
                }
                .width('100%')
                .padding({ left: 12, right: 60, top: 8, bottom: 8 })
              }
            }

            // 流式模式下发送中但还没有内容时，显示等待提示
            if (this.viewModel.sending && !this.viewModel.streamingContent) {
              ListItem() {
                Row() {
                  Text('💭 AI 正在思考...')
                    .fontSize(14)
                    .fontColor('#999')
                    .padding(12)
                    .backgroundColor('#F4F4F5')
                    .borderRadius(12)
                  Blank()
                }
                .width('100%')
                .padding({ left: 12, right: 60, top: 8, bottom: 8 })
              }
            }
          }
          .layoutWeight(1)
          .width('100%')
          .backgroundColor('#F5F7FA')
          .onScrollIndex((first: number, last: number) => {
            // 滚动监听，可用于后续扩展
          })
        }

        // ===== 输入栏 =====
        Row() {
          TextInput({ placeholder: '输入你的问题...', text: this.inputText })
            .onChange((value: string) => this.inputText = value)
            .layoutWeight(1)
            .height(40)
            .borderRadius(20)
            .padding({ left: 16, right: 16 })

          Button(this.viewModel.sending ? '...' : '发送')
            .type(ButtonType.Capsule)
            .height(40)
            .fontSize(14)
            .backgroundColor('#409EFF')
            .margin({ left: 8 })
            .enabled(!this.viewModel.sending && this.inputText.trim().length > 0)
            .onClick(() => {
              const msg = this.inputText.trim()
              if (msg) {
                // 获取输入框消息，调用发送函数
                this.viewModel.sendMessage(msg)
                // 清空输入框
                this.inputText = ''
                // 发送后滚动到底部，让UI渲染先行
                setTimeout(() => {
                  this.scroller.scrollEdge(Edge.Bottom)
                }, 100)
                // 机制1000S，定时器，异步操作。主函数栈没有任务 异步事件栈 EventLoop
              }
            })
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#fff')
      }
      .width('100%')
      .height('100%')

      // ===== 历史面板（从右侧滑出） =====
      if (this.viewModel.showHistory) {
        Column() {
          // 面板标题
          Row() {
            Text('对话历史')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
            Blank()
            Text('✕')
              .fontSize(18)
              .fontColor('#999')
              .onClick(() => this.viewModel.toggleHistory())
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })

          if (this.viewModel.history.length === 0) {
            Column() {
              Text('📭')
                .fontSize(48)
              Text('暂无对话历史')
                .fontSize(14)
                .fontColor('#999')
                .margin({ top: 12 })
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            List({ space: 8 }) {
              ForEach(this.viewModel.history, (conv: Conversation) => {
                ListItem() {
                  Column() {
                    Text(conv.title)
                      .fontSize(14)
                      .fontColor('#333')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Row() {
                      Text(DateUtil.format(conv.createdAt))
                        .fontSize(12)
                        .fontColor('#999')
                      Blank()
                      Text(`${conv.messageCount} 条消息`)
                        .fontSize(12)
                        .fontColor('#999')
                    }
                    .width('100%')
                    .margin({ top: 4 })
                  }
                  .width('100%')
                  .padding(12)
                  .borderRadius(8)
                  .backgroundColor('#fff')
                }
                .onClick(() => this.viewModel.loadHistory(conv))
              })
            }
            .width('100%')
            .layoutWeight(1)
            .padding({ left: 16, right: 16 })
          }
        }
        .width('70%')
        .height('100%')
        .backgroundColor('#F5F7FA')
        .shadow({ radius: 16, color: 'rgba(0,0,0,0.15)' })
      }
    }
    .width('100%')
    .height('100%')
  }
}
