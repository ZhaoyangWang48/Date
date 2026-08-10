import { ServerEndpointStorage } from '../services/ServerEndpointStorage';
import { ApiConfig } from '../constants/ApiConfig';

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

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('工具箱').fontSize(32).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')).width('100%')
        Text('连接与扩展').fontSize(13).fontColor($r('app.color.text_secondary')).width('100%')
        Column({ space: 10 }) {
          Text('服务器地址').fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
          TextInput({ placeholder: 'http://server-host:8080', text: this.serverUrl })
            .width('100%').height(48).padding({ left: 14, right: 14 }).fontSize(14).backgroundColor($r('app.color.app_background'))
            .borderRadius(12).onChange((value: string) => { this.serverUrl = value; })
          Button('保存').width('100%').height(44).fontSize(15).fontColor($r('app.color.on_primary'))
            .backgroundColor($r('app.color.primary')).borderRadius(12).onClick(() => { this.saveEndpoint(); })
          if (this.serverMessage.length > 0) {
            Text(this.serverMessage).fontSize(13).fontColor(this.serverMessage === '已保存' ? $r('app.color.primary') : $r('app.color.error'))
          }
        }
        .width('100%').padding(16).borderRadius(16).backgroundColor($r('app.color.surface')).border({ width: 1, color: $r('app.color.outline') })
        Text('即将推出').fontSize(13).fontColor($r('app.color.text_secondary')).width('100%').margin({ top: 8 })
        Column({ space: 8 }) {
          Text('数据导出').fontSize(16).fontColor($r('app.color.text_primary'))
          Text('回忆统计与主题设置将在后续版本提供。').fontSize(13).fontColor($r('app.color.text_secondary'))
        }
        .width('100%').padding(16).borderRadius(16).backgroundColor($r('app.color.surface')).border({ width: 1, color: $r('app.color.outline') })
      }
      .alignItems(HorizontalAlign.Start).width('100%').padding({ left: 20, right: 20, top: 28, bottom: 28 })
    }
    .width('100%').height('100%').scrollBar(BarState.Off).backgroundColor($r('app.color.app_background'))
  }
}
