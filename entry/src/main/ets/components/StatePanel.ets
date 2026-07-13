@Component
export struct StatePanel {
  @Prop title: string;
  @Prop description: string = '';
  @Prop stateIcon: string = '○';
  onAction: () => void = () => {};
  @Prop actionLabel: string = '';

  build() {
    Column({ space: 8 }) {
      Text(this.stateIcon).fontSize(24).fontColor($r('app.color.text_secondary'))
      Text(this.title).fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
      if (this.description.length > 0) {
        Text(this.description).fontSize(13).fontColor($r('app.color.text_secondary')).textAlign(TextAlign.Center).lineHeight(19)
      }
      if (this.actionLabel.length > 0) {
        Button(this.actionLabel).fontSize(14).fontColor($r('app.color.primary'))
          .backgroundColor($r('app.color.primary_soft')).borderRadius(14).margin({ top: 4 })
          .onClick(() => { this.onAction(); })
      }
    }
    .width('100%').padding(24).margin({ top: 18 }).borderRadius(16)
    .backgroundColor($r('app.color.surface')).border({ width: 1, color: $r('app.color.outline') })
  }
}
