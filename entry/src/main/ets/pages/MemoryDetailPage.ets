import { BusinessError } from '@kit.BasicServicesKit';
import { AppRoutes } from '../constants/AppRoutes';
import { MoodTypes } from '../constants/MoodTypes';
import { MemoryViewModel } from '../viewmodels/MemoryViewModel';
import { TokenStorage } from '../services/TokenStorage';

@Entry
@Component
struct MemoryDetailPage {
  @State found: boolean = false;
  @State authorName: string = '';
  @State content: string = '';
  @State imageUrl: string = '';
  @State mood: string = 'calm';
  @State createdAt: string = '';
  @State memoryId: number = 0;
  @State authorId: number = 0;
  @State currentUserId: number = 0;
  @State message: string = '';
  private readonly viewModel: MemoryViewModel = new MemoryViewModel();

  aboutToAppear(): void {
    this.loadMemory();
  }

  private async loadMemory(): Promise<void> {
    const params = this.getUIContext().getRouter().getParams() as Record<string, number>;
    const memoryId = params['memoryId'];
    if (typeof memoryId !== 'number') {
      return;
    }
    const context = this.getUIContext().getHostContext();
    if (context === undefined) return;
    const memory = await this.viewModel.getMemory(context, memoryId);
    if (memory === undefined) {
      return;
    }
    this.found = true;
    this.memoryId = memory.id;
    this.authorId = memory.authorId;
    this.currentUserId = await TokenStorage.getUserId(context);
    this.authorName = memory.authorName;
    this.content = memory.content;
    this.imageUrl = memory.imageUrl;
    this.mood = memory.mood;
    this.createdAt = memory.createdAt;
  }

  private goBack(): void {
    this.getUIContext().getRouter().back();
  }

  private async deleteMemory(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) return;
    const result = await this.viewModel.deleteMemory(context, this.memoryId);
    if (!result.success) { this.message = result.message; return; }
    this.getUIContext().getRouter().back();
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        Row({ space: 10 }) {
          Text('‹')
            .fontSize(34)
            .fontWeight(FontWeight.Lighter)
            .fontColor($r('app.color.primary'))
            .onClick(() => {
              this.goBack();
            })
          Text('记忆详情')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')

        if (this.found) {
          Column({ space: 18 }) {
            Row({ space: 12 }) {
              Stack() {
                Text(MoodTypes.getOption(this.mood).icon)
                  .fontSize(26)
                  .fontColor($r('app.color.primary'))
              }
              .width(54)
              .height(54)
              .borderRadius(18)
              .backgroundColor($r('app.color.primary_soft'))
              Column({ space: 5 }) {
                Text(this.authorName)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                Text(`${this.createdAt} · ${MoodTypes.getOption(this.mood).label}`)
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
              }
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')

            if (this.content.length > 0) {
              Text(this.content)
                .fontSize(18)
                .lineHeight(29)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
            }

            if (this.imageUrl.length > 0) {
              Image(this.imageUrl)
                .width('100%')
                .height(260)
                .objectFit(ImageFit.Cover)
                .borderRadius(20)
                .onClick(() => {
                  try {
                    this.getUIContext().getRouter().pushUrl({
                      url: AppRoutes.IMAGE_VIEW,
                      params: { imageUrl: this.imageUrl }
                    }, (_error: BusinessError) => {});
                  } catch (e) { /* ignore */ }
                })
            }
            if (this.authorId === this.currentUserId) {
              Button('删除这段记忆')
                .width('100%')
                .fontColor($r('app.color.error'))
                .backgroundColor($r('app.color.primary_soft'))
                .borderRadius(14)
                .onClick(() => { this.deleteMemory(); })
            }
            if (this.message.length > 0) {
              Text(this.message).fontSize(14).fontColor($r('app.color.error'))
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .margin({ top: 30 })
        } else {
          Text('这段记忆暂时找不到了。')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 50 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 20, right: 20, top: 34, bottom: 28 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.app_background'))
  }
}
