@Entry
@Component
struct SplashPage {
  @State message: string = '正在连接服务器…';

  build() {
    Column({ space: 20 }) {
      Text('植忆')
        .fontSize(42)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Text('你的记忆，树洞记得')
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))

      LoadingProgress()
        .width(32)
        .height(32)
        .margin({ top: 16 })
        .color($r('app.color.primary'))

      Text(this.message)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.app_background'))
  }
}
