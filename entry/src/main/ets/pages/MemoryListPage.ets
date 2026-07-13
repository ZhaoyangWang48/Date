import { BusinessError } from '@kit.BasicServicesKit';
import { AppRoutes } from '../constants/AppRoutes';
import { MemoryCard } from '../components/MemoryCard';
import { StatePanel } from '../components/StatePanel';
import { Memory } from '../models/Memory';
import { MemoryViewModel } from '../viewmodels/MemoryViewModel';

@Entry
@Component
struct MemoryListPage {
  @State memories: Memory[] = [];
  @State loaded: boolean = false;
  @State errorMessage: string = '';
  private readonly viewModel: MemoryViewModel = new MemoryViewModel();

  aboutToAppear(): void {
    this.loadMemories();
  }

  private async loadMemories(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      this.memories = await this.viewModel.listMemories(context);
      this.errorMessage = '';
    } catch (error) {
      this.errorMessage = '记忆列表加载失败，请稍后重试';
    }
    this.loaded = true;
  }

  private openAddMemory(): void {
    this.pushPage(AppRoutes.ADD_MEMORY);
  }

  private openDetail(memory: Memory): void {
    try {
      this.getUIContext().getRouter().pushUrl({ url: AppRoutes.MEMORY_DETAIL, params: { memoryId: memory.id } },
        (error: BusinessError) => {});
    } catch (error) {
    }
  }

  private pushPage(route: string): void {
    try {
      this.getUIContext().getRouter().pushUrl({ url: route }, (error: BusinessError) => {});
    } catch (error) {
    }
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        Row() {
          Text('我的记忆')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Blank()
          Button('添加')
            .fontSize(14)
            .fontColor($r('app.color.on_primary'))
            .backgroundColor($r('app.color.primary'))
            .borderRadius(14)
            .onClick(() => {
              this.openAddMemory();
            })
        }
        .width('100%')

        if (!this.loaded) {
          StatePanel({ title: '正在读取记忆', description: '稍等一下，叶片正在归位。', stateIcon: '⏳' })
        } else if (this.errorMessage.length > 0) {
          StatePanel({ title: '加载失败', description: this.errorMessage, stateIcon: '!' })
        } else if (this.memories.length === 0) {
          Column({ space: 12 }) {
            StatePanel({ title: '还没有记忆叶片', description: '从一段文字或一张图片开始，种下今天的记忆。', stateIcon: '🌱' })
            Button('添加第一段记忆')
              .fontSize(16)
              .fontColor($r('app.color.on_primary'))
              .backgroundColor($r('app.color.primary'))
              .borderRadius(14)
              .onClick(() => {
                this.openAddMemory();
              })
          }
          .width('100%')
          .margin({ top: 58 })
        } else {
          Column({ space: 14 }) {
            ForEach(this.memories, (memory: Memory) => {
              MemoryCard({
                memory: memory,
                onOpen: () => {
                  this.openDetail(memory);
                }
              })
            }, (memory: Memory) => memory.id.toString())
          }
          .width('100%')
          .margin({ top: 24 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 20, right: 20, top: 38, bottom: 28 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.app_background'))
  }
}
