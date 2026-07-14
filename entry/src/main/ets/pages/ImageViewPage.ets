import { router } from '@kit.ArkUI';

@Entry
@Component
struct ImageViewPage {
  @State imageUrl: string = '';

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, Object>;
    if (params !== null && typeof params['imageUrl'] === 'string') {
      this.imageUrl = params['imageUrl'] as string;
    }
  }

  build() {
    Stack() {
      Image(this.imageUrl)
        .width('100%').height('100%')
        .objectFit(ImageFit.Contain)
    }
    .width('100%').height('100%')
    .backgroundColor('#000000')
    .onClick(() => { router.back(); })
  }
}
