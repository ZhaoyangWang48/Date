import { BusinessError } from '@kit.BasicServicesKit';
import { AppRoutes } from '../constants/AppRoutes';
import { MoodOption, MoodTypes } from '../constants/MoodTypes';
import { StatePanel } from '../components/StatePanel';
import { VineTreeCanvas } from '../components/VineTreeCanvas';
import { Memory } from '../models/Memory';
import { MemoryViewModel } from '../viewmodels/MemoryViewModel';
import { TokenStorage } from '../services/TokenStorage';

@Entry
@Component
struct MemoryTreePage {
  @State memories: Memory[] = [];
  @State loaded: boolean = false;
  @State errorMessage: string = '';
  @State userSeed: number = 1;
  private readonly viewModel: MemoryViewModel = new MemoryViewModel();

  aboutToAppear(): void {
    this.loadMemories();
  }

  private async loadMemories(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      this.userSeed = await TokenStorage.getUserId(context);
      this.memories = await this.viewModel.listMemories(context);
      this.errorMessage = '';
    } catch (error) {
      this.errorMessage = '记忆树加载失败，请稍后重试';
    }
    this.loaded = true;
  }

  private openDetail(memoryId: number): void {
    try {
      this.getUIContext().getRouter().pushUrl({ url: AppRoutes.MEMORY_DETAIL, params: { memoryId: memoryId } },
        (error: BusinessError) => {});
    } catch (error) {
    }
  }

  private openAddMemory(): void {
    try {
      this.getUIContext().getRouter().pushUrl({ url: AppRoutes.ADD_MEMORY }, (error: BusinessError) => {});
    } catch (error) {
    }
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        Row() {
          Column({ space: 6 }) {
            Text('MEMORY CANOPY')
              .fontSize(11)
              .letterSpacing(1.8)
              .fontColor($r('app.color.accent_gold'))
            Text('记忆树')
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
            Text('在夜色里，收藏被认真对待的瞬间。')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
          }
          .alignItems(HorizontalAlign.Start)
          Blank()
          Button('+ 种下')
            .fontSize(14)
            .fontColor($r('app.color.on_primary'))
            .backgroundColor($r('app.color.primary'))
            .borderRadius(16)
            .onClick(() => {
              this.openAddMemory();
            })
        }
        .width('100%')

        Row({ space: 10 }) {
          Column({ space: 4 }) {
            Text(`${this.memories.length}`)
              .fontSize(23)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.primary'))
            Text('全部叶片')
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          Column({ space: 4 }) {
            Text('此刻')
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.accent_gold'))
            Text('继续生长')
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          Column({ space: 4 }) {
            Text('∞')
              .fontSize(24)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.primary'))
            Text('故事未完')
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding(16)
        .margin({ top: 22 })
        .borderRadius(22)
        .backgroundColor($r('app.color.surface'))
        .border({ width: 1, color: $r('app.color.outline') })

        if (!this.loaded) {
          StatePanel({ title: '正在生成记忆树', description: '叶片颜色和位置正在计算。', stateIcon: '⏳' })
            .margin({ top: 72 })
        } else if (this.errorMessage.length > 0) {
          StatePanel({ title: '加载失败', description: this.errorMessage, stateIcon: '!' })
            .margin({ top: 72 })
        } else if (this.memories.length === 0) {
          Column({ space: 14 }) {
            StatePanel({ title: '一棵树正等待第一片叶子', description: '添加一段记忆后，它会按心情长成不同颜色的叶片。', stateIcon: '🌱' })
            Button('种下第一段记忆')
              .fontSize(16)
              .fontColor($r('app.color.on_primary'))
              .backgroundColor($r('app.color.primary'))
              .borderRadius(14)
              .onClick(() => {
                this.openAddMemory();
              })
          }
          .width('100%')
          .margin({ top: 70 })
        } else {
          VineTreeCanvas({
            memories: this.memories,
            seed: this.userSeed,
            onLeafSelected: (memoryId: number) => {
              this.openDetail(memoryId);
            }
          })
          .margin({ top: 24 })

          Row() {
            Text('点击一片叶子，打开那一刻的记忆。')
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
            Blank()
            Text('筛选  ·  全部')
              .fontSize(12)
              .fontColor($r('app.color.primary'))
          }
          .width('100%')
          .margin({ top: 16 })

          Row({ space: 10 }) {
            ForEach(MoodTypes.OPTIONS, (option: MoodOption) => {
              Row({ space: 4 }) {
                Text(option.icon)
                  .fontSize(16)
                  .fontColor($r('app.color.primary'))
                Text(option.label)
                  .fontSize(12)
                  .fontColor($r('app.color.text_secondary'))
              }
            }, (option: MoodOption) => option.key)
          }
          .width('100%')
          .padding(12)
          .borderRadius(18)
          .backgroundColor($r('app.color.surface'))
          .margin({ top: 14 })
        }
      }
      .alignItems(HorizontalAlign.Center)
      .width('100%')
      .padding({ left: 20, right: 20, top: 38, bottom: 28 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.app_background'))
  }
}
