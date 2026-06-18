import { ConversationRecord } from '../common/ConversationHistory'
import { ConversationItem } from './ConversationItem'

/**
 * 历史记录面板组件
 * 展示所有历史会话列表，支持点击切换和删除
 */
@Component
export struct HistoryPanel {
  @Prop visible: boolean = false
  @Prop history: ConversationRecord[] = []
  @Prop currentConversationId: string = ''
  onClose: () => void = () => {}
  onSelect: (record: ConversationRecord) => void = () => {}
  onDelete: (record: ConversationRecord) => void = () => {}

  build() {
    // 遮罩层
    if (this.visible) {
      Stack() {
        // 背景遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.3)')
          .onClick(() => {
            this.onClose()
          })

        // 侧边面板
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
              .onClick(() => {
                this.onClose()
              })
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 12 })
          .backgroundColor('#ffffff')

          // 分割线
          Divider()
            .color('#f0f0f0')
            .strokeWidth(1)

          // 历史会话列表
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
                  ConversationItem({
                    record: item,
                    isActive: item.conversationId === this.currentConversationId
                  })
                    .onTap(() => {
                      this.onSelect(item)
                    })
                    .onDelete(() => {
                      this.onDelete(item)
                    })
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
        .alignSelf(ItemAlign.End)
      }
      .width('100%')
      .height('100%')
      .position({ left: 0, top: 0 })
      .zIndex(100)
    }
  }
}
