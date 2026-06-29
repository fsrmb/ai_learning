export interface BreadcrumbItem {
  id: number
  name: string
}

@Component
export struct Breadcrumb {
  @Prop items: BreadcrumbItem[] = []
  @Link currentNodeId: number

  build() {
    Row({ space: 4 }) {
      if (this.items.length > 0) {
        ForEach(this.items, (item: BreadcrumbItem, index: number) => {
          Row() {
            if (index === 0) {
              Text('🏠')
                .fontSize(14)
            } else {
              Text('>')
                .fontSize(12)
                .fontColor('#cccccc')
                .margin({ right: 8 })
              Text(item.name)
                .fontSize(14)
                .fontColor(index === this.items.length - 1 ? '#1a1a2e' : '#667eea')
                .fontWeight(index === this.items.length - 1 ? FontWeight.Medium : FontWeight.Normal)
            }
          }
          .onClick(() => {
            this.currentNodeId = item.id
          })
        })
      }
    }
    .width('100%')
    .padding({ left: 4 })
  }
}
