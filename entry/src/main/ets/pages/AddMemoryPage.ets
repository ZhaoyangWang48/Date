import { BusinessError } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';
import { AppRoutes } from '../constants/AppRoutes';
import { MoodSelector } from '../components/MoodSelector';
import { ImagePickerService } from '../services/ImagePickerService';
import { MemoryViewModel } from '../viewmodels/MemoryViewModel';
import { WidgetPhotoCache } from '../services/WidgetPhotoCache';
import { Memory } from '../models/Memory';

@Entry
@Component
struct AddMemoryPage {
  @State content: string = '';
  @State mood: string = 'calm';
  @State imageUri: string = '';
  @State message: string = '';
  @State loading: boolean = false;
  private readonly imagePicker: ImagePickerService = new ImagePickerService();
  private readonly viewModel: MemoryViewModel = new MemoryViewModel();

  private async chooseImage(): Promise<void> {
    const uri = await this.imagePicker.pickOneImage();
    if (uri.length > 0) this.imageUri = uri;
  }

  private async publish(): Promise<void> {
    if (this.loading) return;
    this.loading = true;
    this.message = '';
    try {
      const context = getContext(this) as Context;
      if (context === undefined) {
        this.message = '暂时无法提交，请重试';
        return;
      }

      const result = await this.viewModel.createMemory(context, this.content, this.imageUri, this.mood);
      if (!result.success) {
        this.message = result.message;
        return;
      }
      // 创建成功后更新 Widget 缓存，确保桌面卡片能获取最新照片
      this.refreshWidgetCache(context);
      this.getUIContext().getRouter().replaceUrl({ url: AppRoutes.HOME }, (_error: BusinessError) => {});
    } catch (_error) {
      this.message = '提交未完成，请重新尝试';
    } finally {
      this.loading = false;
    }
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
          Blank().width(56)
          Blank()
          Text('新记忆')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Blank()
          Blank().width(72)
        }
        .width('100%')
        .height(52)

        TextArea({ placeholder: '写下此刻的记忆...', text: this.content })
          .width('100%')
          .height(190)
          .padding(16)
          .fontSize(17)
          .backgroundColor($r('app.color.surface'))
          .border({ width: 1, color: $r('app.color.outline') })
          .borderRadius(20)
          .onChange((value: string) => {
            this.content = value;
          })

        MoodSelector({
          selectedMood: this.mood,
          onMoodChanged: (mood: string) => {
            this.mood = mood;
          }
        })

        if (this.imageUri.length > 0) {
          Column({ space: 8 }) {
            Image(this.imageUri)
              .width('100%')
              .height(190)
              .objectFit(ImageFit.Cover)
              .borderRadius(18)
            Button('移除照片')
              .fontSize(14)
              .fontColor($r('app.color.error'))
              .backgroundColor($r('app.color.danger_soft'))
              .borderRadius(12)
              .onClick(() => {
                this.imageUri = '';
              })
          }
          .width('100%')
        } else {
          Button('添加照片')
            .width('100%')
            .height(50)
            .fontSize(16)
            .fontColor($r('app.color.primary'))
            .backgroundColor($r('app.color.primary_soft'))
            .borderRadius(14)
            .onClick(() => {
              this.chooseImage();
            })
        }

        Button(this.loading ? '发布中...' : '发布记忆')
          .width('100%')
          .height(52)
          .fontSize(17)
          .fontColor($r('app.color.on_primary'))
          .enabled(!this.loading)
          .backgroundColor($r('app.color.primary'))
          .borderRadius(16)
          .onClick(() => {
            this.publish();
          })

        if (this.message.length > 0) {
          Text(this.message)
            .fontSize(14)
            .fontColor($r('app.color.error'))
            .width('100%')
        }
      }
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 32 })
    }
    .align(Alignment.Top)
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.app_background'))
  }
}
