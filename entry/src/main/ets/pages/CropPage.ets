import { router } from '@kit.ArkUI';
import { http } from '@kit.NetworkKit';
import { ApiConfig } from '../constants/ApiConfig';
import { ImageEditSession } from '../services/ImageEditSession';
import { TokenStorage } from '../services/TokenStorage';
import { CropOverlay } from '../components/CropOverlay';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct CropPage {
  @State imageUrl: string = '';
  @State cropX: number = 0.1;
  @State cropY: number = 0.2;
  @State cropW: number = 0.8;
  @State cropH: number = 0.6;
  @State loading: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params !== null && typeof params['imageUrl'] === 'string') {
      this.imageUrl = params['imageUrl'] as string;
    }
  }

  private async confirm(): Promise<void> {
    this.loading = true;
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) { router.back(); return; }
      const token = await TokenStorage.getToken(context);
      const req = http.createHttp();
      const fullUrl = `${ApiConfig.BASE_URL}/api/files/crop`;
      const resp = await req.request(fullUrl, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
        extraData: JSON.stringify({ imageUrl: this.imageUrl, cropX: this.cropX,
          cropY: this.cropY, cropW: this.cropW, cropH: this.cropH }),
        connectTimeout: 5000, readTimeout: 15000
      });
      const body = JSON.parse(resp.result as string) as Record<string, Object>;
      if (body['code'] === 200 && body['data'] !== null) {
        const data = body['data'] as Record<string, Object>;
        if (typeof data['imageUrl'] === 'string') {
          ImageEditSession.updateUrl(data['imageUrl'] as string);
        }
      }
    } catch (e) { /* ignore */ }
    this.loading = false;
    router.back();
  }

  build() {
    Column() {
      Row() {
        Text('✕').fontSize(24).fontColor('#FFFFFF').onClick(() => { router.back(); })
        Blank()
        Text('裁剪图片').fontSize(15).fontColor('#FFFFFF80')
        Blank()
        if (this.loading) {
          LoadingProgress().width(24).height(24).color('#4CAF50')
        } else {
          Text('✓').fontSize(24).fontColor('#4CAF50').onClick(() => { this.confirm(); })
        }
      }
      .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 }).backgroundColor('#000000')

      CropOverlay({
        imageUri: this.imageUrl,
        bare: true,
        onCropChange: (x: number, y: number, w: number, h: number) => {
          this.cropX = x; this.cropY = y; this.cropW = w; this.cropH = h;
        }
      })
    }
    .width('100%').height('100%').backgroundColor('#000000')
  }
}
