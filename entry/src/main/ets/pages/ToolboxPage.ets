import { ServerEndpointStorage } from '../services/ServerEndpointStorage';
import { ApiConfig } from '../constants/ApiConfig';
import { AppRoutes } from '../constants/AppRoutes';

@Entry
@Component
struct ToolboxPage {
  @State serverUrl: string = ApiConfig.BASE_URL;
  @State serverMessage: string = '';

  aboutToAppear(): void { this.loadEndpoint(); }

  private async loadEndpoint(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context !== undefined) this.serverUrl = await ServerEndpointStorage.load(context);
  }

  private async saveEndpoint(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) return;
    const saved = await ServerEndpointStorage.save(context, this.serverUrl);
    if (saved.length === 0) {
      this.serverMessage = '地址格式：http://电脑IPv4:8080';
      return;
    }
    this.serverUrl = saved;
    this.serverMessage = '已保存';
  }

  private open(route: string): void {
    this.getUIContext().getRouter().pushUrl({ url: route });
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('工具箱').fontSize(32).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).width('100%')
        Text('连接与扩展').fontSize(13).fontColor($r('app.color.text_secondary')).width('100%')
        Column({ space: 10 }) {
          Text('服务器地址').fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
          TextInput({ placeholder: 'http://127.0.0.1:8080', text: this.serverUrl })
            .width('100%').height(48).padding({ left: 14, right: 14 }).fontSize(14).backgroundColor($r('app.color.app_background'))
            .borderRadius(12).onChange((value: string) => { this.serverUrl = value; })
          Button('保存').width('100%').height(44).fontSize(15).fontColor($r('app.color.on_primary'))
            .backgroundColor($r('app.color.primary')).borderRadius(12).onClick(() => { this.saveEndpoint(); })
          if (this.serverMessage.length > 0) {
            Text(this.serverMessage).fontSize(13).fontColor(this.serverMessage === '已保存' ? $r('app.color.primary') : $r('app.color.error'))
          }
        }
        .width('100%').padding(16).borderRadius(16).backgroundColor($r('app.color.surface')).border({ width: 1, color: $r('app.color.outline') })
        Text('记忆实验室').fontSize(13).fontColor($r('app.color.text_secondary')).width('100%').margin({ top: 8 })
        Column({ space: 10 }) {
          this.feature('时光胶囊', '写给未来的自己，到期后开启与朗读。', AppRoutes.TIME_CAPSULE_GARDEN)
          this.feature('记忆电台', '把个人记忆变成可以朗读的回忆频道。', AppRoutes.MEMORY_RADIO)
          this.feature('漂流瓶', '匿名投入一句话，接住远方的共鸣。', AppRoutes.DRIFT_BOTTLE)
        }.width('100%')
      }
      .alignItems(HorizontalAlign.Start).width('100%').padding({ left: 20, right: 20, top: 28, bottom: 28 })
    }
    .width('100%').height('100%').scrollBar(BarState.Off).backgroundColor($r('app.color.app_background'))
  }

  @Builder
  private feature(title: string, description: string, route: string): void {
    Row() {
      Column({ space: 4 }) { Text(title).fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')); Text(description).fontSize(13).fontColor($r('app.color.text_secondary')).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }); }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Text('›').fontSize(24).fontColor($r('app.color.primary'))
    }.width('100%').padding(16).borderRadius(16).backgroundColor($r('app.color.surface')).border({ width: 1, color: $r('app.color.outline') }).onClick(() => { this.open(route); })
  }
}
