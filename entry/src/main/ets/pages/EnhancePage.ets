import { router } from '@kit.ArkUI';
import { http } from '@kit.NetworkKit';
import { ApiConfig } from '../constants/ApiConfig';
import { ImageEditSession } from '../services/ImageEditSession';
import { TokenStorage } from '../services/TokenStorage';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct EnhancePage {
  @State originalUrl: string = '';
  @State enhancedUrl: string = '';
  @State loading: boolean = true;
  @State viewingOriginal: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params !== null && typeof params['imageUrl'] === 'string') {
      this.originalUrl = params['imageUrl'] as string;
      this.enhance();
    } else { router.back(); }
  }

  private async enhance(): Promise<void> {
    this.loading = true;
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) { router.back(); return; }
      const token = await TokenStorage.getToken(context);
      const req = http.createHttp();
      const resp = await req.request(`${ApiConfig.BASE_URL}/api/files/enhance`, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
        extraData: JSON.stringify({ imageUrl: this.originalUrl }),
        connectTimeout: 5000, readTimeout: 15000
      });
      const body = JSON.parse(resp.result as string) as Record<string, Object>;
      if (body['code'] === 200 && body['data'] !== null) {
        const data = body['data'] as Record<string, Object>;
        if (typeof data['imageUrl'] === 'string') this.enhancedUrl = data['imageUrl'] as string;
      }
    } catch (e) { this.enhancedUrl = this.originalUrl; }
    this.loading = false;
  }

  private getDisplayUrl(): string {
    const raw = this.loading ? this.originalUrl :
      (this.enhancedUrl.length === 0 ? this.originalUrl :
        (this.viewingOriginal ? this.originalUrl : this.enhancedUrl));
    if (raw.length === 0 || raw.startsWith('http')) return raw;
    return ApiConfig.BASE_URL + raw;
  }

  build() {
    Column() {
      Row() {
        Text('✕').fontSize(24).fontColor('#FFFFFF').onClick(() => { router.back(); })
        Blank()
        Text(this.viewingOriginal ? '原图预览' :
          (this.loading ? '增强处理中...' : '画质增强')).fontSize(14).fontColor('#FFFFFF80')
        Blank()
        Text('✓').fontSize(24).fontColor('#4CAF50').onClick(() => {
          if (this.enhancedUrl.length > 0) ImageEditSession.updateUrl(this.enhancedUrl);
          router.back();
        })
      }
      .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 }).backgroundColor('#000000')

      Image(this.getDisplayUrl())
        .width('100%').layoutWeight(1)
        .objectFit(ImageFit.Contain)
        .backgroundColor('#000000')

      Row() {
        Button('查看原图')
          .fontSize(14).height(44).fontColor('#FFFFFF')
          .backgroundColor('#666666').borderRadius(12).layoutWeight(1)
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) this.viewingOriginal = true;
            else if (event.type === TouchType.Up) this.viewingOriginal = false;
          })
      }
      .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 24 }).backgroundColor('#000000')
    }
    .width('100%').height('100%').backgroundColor('#000000')
  }
}
