import { ConversationRecord } from '../common/ConversationHistory'
import { DateUtil } from '../common/DateUtil'

/**
 * 历史会话项组件
 * 展示单个历史会话的标题、最后一条消息、时间戳和消息数量
 */
@Component
export struct ConversationItem {
  @Prop record: ConversationRecord
  @Prop isActive: boolean = false
  onTap: () => void = () => {}
  onDelete: () => void = () => {}

  build() {
    Row() {
      // 左侧图标
      Column() {
        Text('💬')
          .fontSize(24)
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor(this.isActive ? '#667eea' : '#f0f0f0')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .margin({ right: 12 })

      // 中间内容区域
      Column() {
        // 标题
        Text(this.record.title || '未命名对话')
          .fontSize(16)
          .fontColor('#1a1a2e')
          .fontWeight(this.isActive ? FontWeight.Medium : FontWeight.Normal)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 最后一条消息
        Text(this.record.lastMessage || '')
          .fontSize(13)
          .fontColor('#999')
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })

        // 底部信息（时间 + 消息数）
        Row() {
          Text(DateUtil.format(this.record.timestamp))
            .fontSize(10)
            .fontColor('#ccc')
          Text(`· ${this.record.messageCount} 条`)
            .fontSize(10)
            .fontColor('#ccc')
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)

      // 右侧删除按钮
      Column() {
        Text('🗑')
          .fontSize(16)
          .onClick(() => {
            this.onDelete()
          })
      }
      .padding(8)
    }
    .width('100%')
    .padding({ left: 12, right: 8, top: 12, bottom: 12 })
    .backgroundColor(this.isActive ? '#f0f4ff' : '#ffffff')
    .borderRadius(12)
    .onClick(() => {
      this.onTap()
    })
  }
}
