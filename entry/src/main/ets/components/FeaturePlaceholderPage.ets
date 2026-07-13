@Component
export struct FeaturePlaceholderPage {
  @Prop icon: string = '';
  @Prop title: string = '';
  @Prop description: string = '';

  private goBack(): void {
    this.getUIContext().getRouter().back();
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        Text('‹')
          .fontSize(34)
          .fontWeight(FontWeight.Lighter)
          .fontColor($r('app.color.primary'))
          .onClick(() => {
            this.goBack();
          })

        Text(this.title)
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .height(56)

      Column({ space: 18 }) {
        Stack() {
          Text(this.icon)
            .fontSize(54)
            .fontColor($r('app.color.primary'))
            .fontWeight(FontWeight.Medium)
        }
        .width(112)
        .height(112)
        .borderRadius(40)
        .backgroundColor($r('app.color.primary_soft'))

        Text(this.title)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))

        Text(this.description)
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
          .textAlign(TextAlign.Center)
          .lineHeight(25)
          .width('88%')

        Text('第一轮原型 · 页面入口已接通')
          .fontSize(13)
          .fontColor($r('app.color.primary'))
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .borderRadius(16)
          .backgroundColor($r('app.color.primary_soft'))
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .width('100%')

      Button('返回首页')
        .width('100%')
        .height(52)
        .fontSize(17)
        .fontColor($r('app.color.on_primary'))
        .backgroundColor($r('app.color.primary'))
        .borderRadius(18)
        .onClick(() => {
          this.goBack();
        })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, top: 28, bottom: 24 })
    .backgroundColor($r('app.color.app_background'))
  }
}
