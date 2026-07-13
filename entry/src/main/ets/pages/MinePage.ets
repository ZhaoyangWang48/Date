import { BusinessError } from '@kit.BasicServicesKit';
import { AppRoutes } from '../constants/AppRoutes';
import { TokenStorage } from '../services/TokenStorage';

@Entry
@Component
struct MinePage {
  @State nickname: string = '记忆守护者';
  @State loggedIn: boolean = false;
  @State message: string = '';

  aboutToAppear(): void { this.loadSession(); }

  private async loadSession(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) return;
    try {
      this.loggedIn = await TokenStorage.hasToken(context);
      this.nickname = await TokenStorage.getNickname(context);
    } catch (_error) { this.message = '暂时无法读取账户信息'; }
  }

  private async logout(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) return;
    try {
      await TokenStorage.clearSession(context);
      this.getUIContext().getRouter().replaceUrl({ url: AppRoutes.LOGIN }, (_error: BusinessError) => {});
    } catch (_error) { this.message = '退出失败，请重试'; }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('我的').fontSize(32).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).width('100%')
        Column({ space: 6 }) {
          Text(this.loggedIn ? this.nickname : '未登录').fontSize(20).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
          Text(this.loggedIn ? '账户已登录' : '登录后可保存你的记忆').fontSize(13).fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Start).width('100%').padding(18).borderRadius(16)
        .backgroundColor($r('app.color.surface')).border({ width: 1, color: $r('app.color.outline') })

        Text('账户').fontSize(13).fontColor($r('app.color.text_secondary')).width('100%').margin({ top: 8 })
        Column() {
          Row() {
            Text('登录状态').fontSize(16).fontColor($r('app.color.text_primary'))
            Blank()
            Text(this.loggedIn ? '已登录' : '未登录').fontSize(14).fontColor($r('app.color.text_secondary'))
          }
          .width('100%').height(54).padding({ left: 16, right: 16 })
        }
        .width('100%').borderRadius(16).backgroundColor($r('app.color.surface')).border({ width: 1, color: $r('app.color.outline') })

        if (this.message.length > 0) {
          Text(this.message).fontSize(13).fontColor($r('app.color.error')).width('100%')
        }
        Button(this.loggedIn ? '退出登录' : '前往登录')
          .width('100%').height(50).margin({ top: 8 }).fontSize(16)
          .fontColor(this.loggedIn ? $r('app.color.error') : $r('app.color.on_primary'))
          .backgroundColor(this.loggedIn ? $r('app.color.danger_soft') : $r('app.color.primary')).borderRadius(14)
          .onClick(() => { this.loggedIn ? this.logout() : this.getUIContext().getRouter().replaceUrl({ url: AppRoutes.LOGIN }); })
      }
      .alignItems(HorizontalAlign.Start).width('100%').padding({ left: 20, right: 20, top: 28, bottom: 28 })
    }
    .width('100%').height('100%').scrollBar(BarState.Off).backgroundColor($r('app.color.app_background'))
  }
}
