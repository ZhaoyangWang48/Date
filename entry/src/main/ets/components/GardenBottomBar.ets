@Component
export struct GardenBottomBar {
  @Prop selectedIndex: number = 0;
  onSelected: (index: number) => void = () => {};

  @Builder
  private navItem(index: number, icon: string, label: string, iconOffsetY: number = 0): void {
    Column({ space: 2 }) {
      Text(icon)
        .fontSize(20)
        .fontColor(this.selectedIndex === index ? $r('app.color.primary') : $r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .offset({ x: 0, y: iconOffsetY })
      Text(label)
        .fontSize(10)
        .fontColor(this.selectedIndex === index ? $r('app.color.primary') : $r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
    }
    .width(64)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => { this.onSelected(index); })
  }

  build() {
    Row() {
      this.navItem(0, '⌂', '首页')
      this.navItem(1, '♧', '记忆树')
      this.navItem(3, '◎', '树洞')
      this.navItem(4, '◇', '工具箱')
    }
    .justifyContent(FlexAlign.SpaceAround)
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .height(64)
    .padding({ top: 10, bottom: 6 })
    .border({ width: { top: 1 }, color: $r('app.color.outline') })
    .backgroundColor('#FDFCFAF2')
  }
}
