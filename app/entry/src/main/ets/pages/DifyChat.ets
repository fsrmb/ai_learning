import { router } from '@kit.ArkUI'
import promptAction from '@ohos.promptAction'
import { DifyChatViewModel } from '../viewmodel/DifyChatViewModel'
import { ChatMessage } from '../model/ChatMessage'
import { DateUtil } from '../common/DateUtil'
import { MarkdownUtil } from '../common/MarkdownUtil'
import { webview } from '@kit.ArkWeb'
import { HistoryPanel } from '../components/HistoryPanel'
import { ConversationRecord } from '../common/ConversationHistory'
import GlobalContext from '../common/GlobalContext'

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
 *   - 对话历史面板（持久化存储，带滑出动画）
 *   - 新建对话 / 清空消息
 *   - 会话切换
 *
 * 使用前请在 main_pages.json 中注册 "pages/DifyChat"
 */
@Entry
@Component
struct DifyChatPage {
  @State viewModel: DifyChatViewModel = new DifyChatViewModel()
  @State inputText: string = ''
  @State showHistory: boolean = false
  @State mainContentOffset: number = 0
  @State historyPanelOffset: number = -100
  private scroller: Scroller = new Scroller()

  /**
   * 页面显示时初始化历史记录
   */
  onPageShow(): void {
    const context = GlobalContext.getInstance().getContext()
    if (context) {
      this.viewModel.initHistory(context)
    }
  }

  /**
   * 打开历史面板（带平移动画）
   * 主内容向右平移 75%，历史面板从左侧滑入
   */
  openHistory(): void {
    animateTo({
      duration: 300, // 动画时长 300ms
      curve: Curve.EaseOut, // 缓动曲线
      iterations: 1,
      playMode: PlayMode.Normal
    }, () => {
      this.showHistory = true
      // 主内容向右平移 75% 屏幕宽度
      this.mainContentOffset = 75
      // 历史面板从屏幕外左侧滑入到 0% 位置（即完全展开）
      this.historyPanelOffset = 0
    })
  }

  /**
   * 关闭历史面板（带平移动画）
   * 主内容向左平移恢复，历史面板向左滑出
   */
  closeHistory(): void {
    animateTo({
      duration: 300,
      curve: Curve.EaseOut,
      iterations: 1,
      playMode: PlayMode.Normal
    }, () => {
      // 主内容向左平移恢复原位
      this.mainContentOffset = 0
      // 历史面板向左滑出屏幕
      this.historyPanelOffset = -100
    })
    // 等待动画结束后才隐藏遮罩
    setTimeout(() => {
      this.showHistory = false
    }, 300)
  }

  /**
   * 选择历史会话
   */
  async selectConversation(record: ConversationRecord): Promise<void> {
    await this.viewModel.switchConversation(record)
    this.closeHistory()
  }

  /**
   * 删除历史会话
   */
  async deleteConversation(record: ConversationRecord): Promise<void> {
    await this.viewModel.deleteConversation(record)
  }

  /**
   * 显示删除确认对话框
   */
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
      // ===== 主内容区域（聊天界面）=====
      Column() {
        // ===== Header =====
        Row() {
          // 左侧：返回按钮 + 汉堡菜单
          Row() {
            // 返回按钮
            Text('←')
              .fontSize(20)
              .fontColor('#409EFF')
              .margin({ right: 12 })
              .onClick(() => router.back())

            // 汉堡菜单（打开/关闭历史）
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

          // 中间：标题 + 模式标签
          Column() {
            Text(this.viewModel.currentTitle || 'AI对话（Dify）')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1a1a2e')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.viewModel.mode === 'blocking' ? '⚡ 阻塞模式' : '⚡ 流式模式')
              .fontSize(12)
              .fontColor(this.viewModel.mode === 'blocking' ? '#E6A23C' : '#67C23A')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Center)

          Blank()

          // 右侧：模式切换 + 新对话
          Row() {
            // 模式切换
            Text(this.viewModel.mode === 'blocking' ? '阻塞' : '流式')
              .fontSize(12)
              .fontColor('#fff')
              .backgroundColor(this.viewModel.mode === 'blocking' ? '#E6A23C' : '#67C23A')
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .borderRadius(12)
              .margin({ right: 12 })
              .onClick(() => this.viewModel.toggleMode())

            // 新对话按钮（圆形 + 号）
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
                await this.viewModel.newConversation()
              })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor('#fff')

        // ===== 消息列表 =====
        if (this.viewModel.messages.length === 0 && !this.viewModel.sending) {
          // 空状态
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
            Text('点击「历史」查看过往对话')
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
                  // AI 消息：灰色气泡，左对齐（使用 Web 组件渲染 Markdown）
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

            // 流式输出中的临时消息
            if (this.viewModel.sending && this.viewModel.streamingContent) {
              ListItem() {
                Row() {
                  Column() {
                    Web({
                      src: `data:text/html,${encodeURIComponent(MarkdownUtil.toHtmlWithCustomStyle(this.viewModel.streamingContent))}`,
                      controller: new webview.WebviewController(),
                      renderMode: RenderMode.SYNC_RENDER
                    })
                      .layoutMode(WebLayoutMode.FIT_CONTENT)
                      .overScrollMode(OverScrollMode.NEVER)
                      .width('70%')
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
                this.viewModel.sendMessage(msg)
                this.inputText = ''
                setTimeout(() => {
                  this.scroller.scrollEdge(Edge.Bottom)
                }, 100)
              }
            })
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#fff')
      }
      .width('100%')
      .height('100%')
      .translate({ x: `${this.mainContentOffset}%`, y: 0 })
      .animation({ duration: 300, curve: Curve.EaseOut })

      // ===== 历史面板（从右侧滑入，固定宽度 75%）=====
      Column() {
        // 头部
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

        // 历史会话列表
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
                      .fontColor(item.conversationId === this.viewModel.conversationId ? '#409EFF' : '#333')
                      .fontWeight(item.conversationId === this.viewModel.conversationId ? FontWeight.Medium : FontWeight.Normal)
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
                .backgroundColor(item.conversationId === this.viewModel.conversationId ? '#ecf5ff' : '#fff')
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

        // 底部提示
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