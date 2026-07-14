import { BusinessError } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';
import { ApiConfig } from '../constants/ApiConfig';
import { AppRoutes } from '../constants/AppRoutes';
import { MoodSelector } from '../components/MoodSelector';
import { ImagePickerService } from '../services/ImagePickerService';
import { ImageEditSession } from '../services/ImageEditSession';
import { MemoryViewModel } from '../viewmodels/MemoryViewModel';
import { WidgetPhotoCache } from '../services/WidgetPhotoCache';
import { Memory } from '../models/Memory';
import { UploadRepository } from '../repositories/UploadRepository';

@Entry
@Component
struct AddMemoryPage {
  @State content: string = '';
  @State mood: string = 'calm';
  @State imageUri: string = '';
  @State imageUrl: string = '';
  @State message: string = '';
  @State loading: boolean = false;
  private readonly imagePicker: ImagePickerService = new ImagePickerService();
  private readonly viewModel: MemoryViewModel = new MemoryViewModel();
  private readonly uploadRepo: UploadRepository = new UploadRepository();

  onPageShow(): void {
    if (!ImageEditSession.consume()) return;
    if (ImageEditSession.confirmed) {
      this.imageUrl = ImageEditSession.finalUrl;
    } else {
      this.imageUri = ''; this.imageUrl = '';
    }
  }

  private async pickAndEdit(): Promise<void> {
    const uri = await this.imagePicker.pickOneImage();
    if (uri.length === 0) return;
    this.imageUri = uri;
    // 立即上传获取 URL
    const context = this.getUIContext().getHostContext();
    if (context === undefined) return;
    const uploaded = await this.uploadRepo.uploadImage(context, uri);
    if (uploaded.code !== 200 || uploaded.data === undefined) {
      this.message = uploaded.message; return;
    }
    this.imageUrl = uploaded.data;
    // 进入编辑页
    try {
      this.getUIContext().getRouter().pushUrl({
        url: AppRoutes.IMAGE_EDIT, params: { imageUrl: this.imageUrl }
      }, (_error: BusinessError) => {});
    } catch (e) { /* ignore */ }
  }

  private async publish(): Promise<void> {
    if (this.loading) return;
    if (this.content.trim().length === 0 && this.imageUrl.length === 0) {
      this.message = '请写下一段记忆，或选择一张图片'; return;
    }
    this.loading = true; this.message = '';
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) { this.message = '暂时无法提交'; this.loading = false; return; }
      const now = new Date();
      const date = `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}-${String(now.getDate()).padStart(2,'0')}`;
      const result = await this.viewModel.createWithUrl(context, this.content.trim(),
        this.imageUrl, this.mood, date, now.getHours());
      if (!result.success) {
        this.message = result.message; this.loading = false; return;
      }
      // 创建成功后更新 Widget 缓存，确保桌面卡片能获取最新照片
      this.refreshWidgetCache(context);
      this.getUIContext().getRouter().replaceUrl({ url: AppRoutes.HOME }, (_error: BusinessError) => {});
    } catch (_error) { this.message = '提交未完成'; }
    this.loading = false;
  }

  private displayUrl(): string {
    const url = this.imageUrl;
    if (url.length === 0) return url;
    return url.startsWith('/') ? ApiConfig.BASE_URL + url : url;
  }

  /**
   * 刷新 Widget 缓存，使桌面卡片能获取最新照片。
   */
  private refreshWidgetCache(context: Context): void {
    this.viewModel.listMemories(context).then((memories: Memory[]) => {
      const photos = memories.filter((m: Memory) => m.imageUrl && m.imageUrl.length > 0)
        .sort((a: Memory, b: Memory) =>
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
        );
      WidgetPhotoCache.saveFromMemories(context, photos);
    }).catch(() => {
      // 缓存更新失败不影响主流程
    });
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() {
          Blank().width(56); Blank()
          Text('新记忆').fontSize(34).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
          Blank(); Blank().width(72)
        }.width('100%').height(52)

        TextArea({ placeholder: '写下此刻的记忆...', text: this.content })
          .width('100%').height(190).padding(16).fontSize(17)
          .backgroundColor($r('app.color.surface'))
          .border({ width: 1, color: $r('app.color.outline') }).borderRadius(20)
          .onChange((value: string) => { this.content = value; })

        MoodSelector({ selectedMood: this.mood,
          onMoodChanged: (mood: string) => { this.mood = mood; } })

        if (this.imageUrl.length > 0) {
          Column({ space: 8 }) {
            Image(this.displayUrl())
              .width('100%').height(190).objectFit(ImageFit.Cover).borderRadius(18)
              .onClick(() => { this.pickAndEdit(); })
            Row() {
              Blank()
              Text('点击重新编辑').fontSize(12).fontColor($r('app.color.text_secondary'))
              Blank()
              Text('移除').fontSize(12).fontColor($r('app.color.error'))
                .onClick(() => { this.imageUri = ''; this.imageUrl = ''; })
            }.width('100%')
          }.width('100%')
        } else {
          Button('添加照片').width('100%').height(50).fontSize(16)
            .fontColor($r('app.color.primary'))
            .backgroundColor($r('app.color.primary_soft')).borderRadius(14)
            .onClick(() => { this.pickAndEdit(); })
        }

        Button(this.loading ? '发布中...' : '发布记忆')
          .width('100%').height(52).fontSize(17)
          .fontColor($r('app.color.on_primary')).enabled(!this.loading)
          .backgroundColor($r('app.color.primary')).borderRadius(16)
          .onClick(() => { this.publish(); })

        if (this.message.length > 0)
          Text(this.message).fontSize(14).fontColor($r('app.color.error')).width('100%')
      }
      .alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Start)
      .width('100%').padding({ left: 20, right: 20, top: 12, bottom: 32 })
    }
    .align(Alignment.Top).width('100%').height('100%')
    .scrollBar(BarState.Off).backgroundColor($r('app.color.app_background'))
  }
}
