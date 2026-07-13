@Component
export struct GardenBottomBar {
  @Prop selectedIndex: number = 0;
  onSelected: (index: number) => void = () => {};

  @Builder
  private navItem(index: number, icon: string, label: string): void {
    Column({ space: 4 }) {
      Text(icon)
        .fontSize(19)
        .fontColor(this.selectedIndex === index ? $r('app.color.primary') : $r('app.color.text_secondary'))
      Text(label)
        .fontSize(10)
        .fontColor(this.selectedIndex === index ? $r('app.color.primary') : $r('app.color.text_secondary'))
    }
    .width(60)
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
    .alignItems(VerticalAlign.Bottom)
    .width('100%')
    .height(70)
    .padding({ left: 12, right: 12, top: 12, bottom: 8 })
    .border({ width: { top: 1 }, color: $r('app.color.outline') })
    .backgroundColor('#FDFCFAF2')
  }
}
