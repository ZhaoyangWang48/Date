@Component
export struct FeatureEntryCard {
  @Prop icon: string = '';
  @Prop title: string = '';
  @Prop description: string = '';
  onOpen: () => void = () => {};

  build() {
    Row({ space: 14 }) {
      Stack() {
        Text(this.icon)
          .fontSize(26)
          .fontColor($r('app.color.primary'))
          .fontWeight(FontWeight.Medium)
      }
      .width(54)
      .height(54)
      .borderRadius(20)
      .backgroundColor($r('app.color.accent_gold_soft'))

      Column({ space: 6 }) {
        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width('100%')

        Text(this.description)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Column({ space: 2 }) {
        Text('打开')
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
        Text('↗')
          .fontSize(18)
          .fontColor($r('app.color.primary'))
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .height(108)
    .padding({ left: 16, right: 18, top: 14, bottom: 14 })
    .borderRadius(24)
    .backgroundColor($r('app.color.surface'))
    .border({ width: 1, color: $r('app.color.outline') })
    .shadow({
      radius: 18,
      color: $r('app.color.card_shadow'),
      offsetX: 0,
      offsetY: 7
    })
    .onClick(() => {
      this.onOpen();
    })
  }
}
