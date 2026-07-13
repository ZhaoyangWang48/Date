import { router } from '@kit.ArkUI';
import { AppRoutes } from '../constants/AppRoutes';
import { ApiConfig } from '../constants/ApiConfig';
import { ImageEditSession } from '../services/ImageEditSession';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct ImageEditPage {
  @State imageUrl: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params !== null && typeof params['imageUrl'] === 'string') {
      ImageEditSession.begin(params['imageUrl'] as string);
      this.imageUrl = params['imageUrl'] as string;
    } else { router.back(); }
  }

  onPageShow(): void {
    this.imageUrl = ImageEditSession.imageUrl;
  }

  private goCrop(): void {
    try {
      this.getUIContext().getRouter().pushUrl({
        url: AppRoutes.CROP, params: { imageUrl: this.imageUrl }
      }, (_error: BusinessError) => {});
    } catch (e) { /* ignore */ }
  }

  private goEnhance(): void {
    try {
      this.getUIContext().getRouter().pushUrl({
        url: AppRoutes.ENHANCE, params: { imageUrl: this.imageUrl }
      }, (_error: BusinessError) => {});
    } catch (e) { /* ignore */ }
  }

  private displayUrl(): string {
    const url = this.imageUrl;
    if (url.length === 0) return url;
    return url.startsWith('/') ? ApiConfig.BASE_URL + url : url;
  }

  build() {
    Column() {
      Row() {
        Text('✕').fontSize(24).fontColor('#FFFFFF')
          .onClick(() => { ImageEditSession.confirmed = false; router.back(); })
        Blank()
        Text('编辑图片').fontSize(15).fontColor('#FFFFFF80')
        Blank()
        Text('✓').fontSize(24).fontColor('#4CAF50')
          .onClick(() => { ImageEditSession.confirm(); router.back(); })
      }
      .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 }).backgroundColor('#000000')

      Image(this.displayUrl())
        .width('100%').layoutWeight(1)
        .objectFit(ImageFit.Contain)
        .backgroundColor('#000000')

      Row({ space: 12 }) {
        Button('✂ 裁剪')
          .fontSize(14).height(44).fontColor('#FFFFFF')
          .backgroundColor('#4CAF50').borderRadius(12).layoutWeight(1)
          .onClick(() => { this.goCrop(); })
        Button('✦ 画质增强')
          .fontSize(14).height(44).fontColor('#FFFFFF')
          .backgroundColor('#FF9800').borderRadius(12).layoutWeight(1)
          .onClick(() => { this.goEnhance(); })
      }
      .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 24 }).backgroundColor('#000000')
    }
    .width('100%').height('100%').backgroundColor('#000000')
  }
}
