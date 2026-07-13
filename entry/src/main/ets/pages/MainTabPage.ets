import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { AppRoutes } from '../constants/AppRoutes';
import { GardenBottomBar } from '../components/GardenBottomBar';
import { VineTreeCanvas } from '../components/VineTreeCanvas';
import { Memory } from '../models/Memory';
import { MemoryViewModel } from '../viewmodels/MemoryViewModel';
import { RecallCardViewModel } from '../viewmodels/RecallCardViewModel';
import { TokenStorage } from '../services/TokenStorage';

@Entry
@Component
struct MainTabPage {
  @State selectedIndex: number = 0;
  @State memories: Memory[] = [];
  @State seed: number = 1;
  @State hasRecallCards: boolean = false;
  @State recallCardCount: number = 0;
  @State generating: boolean = false;
  @State btnOffsetX: number = 0;
  @State btnOffsetY: number = 0;
  private readonly memoryVm: MemoryViewModel = new MemoryViewModel();
  private readonly recallVm: RecallCardViewModel = new RecallCardViewModel();

  aboutToAppear(): void { this.load(); this.checkRecallCards(); }

  private async load(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) return;
    this.seed = await TokenStorage.getUserId(context);
    this.memories = await this.memoryVm.listMemories(context);
  }

  private async checkRecallCards(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) return;
      const cards = await this.recallVm.list(context);
      this.hasRecallCards = cards.length > 0;
      this.recallCardCount = cards.length;
    } catch (error) { /* ignore */ }
  }

  private async onGenerateRecall(): Promise<void> {
    if (this.generating) return;
    this.generating = true;
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) return;
      const result = await this.recallVm.generate(context);
      promptAction.showToast({ message: result.message });
      if (result.success) {
        this.hasRecallCards = true;
        this.recallCardCount = this.recallCardCount + 1;
      }
    } catch (error) {
      promptAction.showToast({ message: '总结生成失败，请稍后再试' });
    }
    this.generating = false;
  }

  private open(route: string): void {
    try { this.getUIContext().getRouter().pushUrl({ url: route }, (_error: BusinessError) => {}); } catch (_error) {}
  }

  private openDetail(memoryId: number): void {
    try {
      this.getUIContext().getRouter().pushUrl({ url: AppRoutes.MEMORY_DETAIL, params: { memoryId: memoryId } },
        (_error: BusinessError) => {});
    } catch (_error) {}
  }

  private switchTab(index: number): void {
    if (index === 3) { this.open(AppRoutes.SHARED_TREE); return; }
    if (index === 4) { this.open(AppRoutes.TOOLBOX); return; }
    this.selectedIndex = index;
  }

  @Builder
  private topBar(title: string, showProfile: boolean): void {
    Row() {
      if (showProfile) {
        Text('我的').width(72).fontSize(16).fontColor($r('app.color.primary')).textAlign(TextAlign.Start)
          .onClick(() => { this.open(AppRoutes.MINE); })
      } else {
        Blank().width(72)
      }
      Blank()
      Text(title).fontSize(34).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
      Blank()
      Text('+').width(72).fontSize(30).fontWeight(FontWeight.Lighter).fontColor($r('app.color.primary')).textAlign(TextAlign.End)
        .onClick(() => { this.open(AppRoutes.ADD_MEMORY); })
    }
    .width('100%').height(52)
  }

  @Builder
  private homeContent(): void {
    Scroll() {
      Column({ space: 20 }) {
        this.topBar('植忆', true)
        Column({ space: 8 }) {
          Text('今日').fontSize(13).fontColor($r('app.color.text_secondary'))
          Row() {
            Column({ space: 4 }) {
              Text(`${this.memories.length}`).fontSize(34).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary'))
              Text('条记忆').fontSize(13).fontColor($r('app.color.text_secondary'))
            }
            .alignItems(HorizontalAlign.Start)
            Blank()
            Button('记录此刻').fontSize(15).fontColor($r('app.color.on_primary')).backgroundColor($r('app.color.primary'))
              .borderRadius(14).onClick(() => { this.open(AppRoutes.ADD_MEMORY); })
          }
          .width('100%')
        }
        .width('100%').padding(20).borderRadius(20).backgroundColor($r('app.color.surface'))
        .border({ width: 1, color: $r('app.color.outline') })

        Text('最近记忆').fontSize(20).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).width('100%')
        if (this.memories.length === 0) {
          Text('还没有内容。').fontSize(15).fontColor($r('app.color.text_secondary')).width('100%')
        } else {
          Column({ space: 6 }) {
            Text(this.memories[0].date).fontSize(13).fontColor($r('app.color.text_secondary'))
            Text(this.memories[0].content).fontSize(16).fontColor($r('app.color.text_primary')).maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis }).lineHeight(24)
          }
          .width('100%').padding(18).borderRadius(18).backgroundColor($r('app.color.surface'))
          .border({ width: 1, color: $r('app.color.outline') }).onClick(() => { this.openDetail(this.memories[0].id); })
        }
      }
      .alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Start).width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 96 })
    }
    .align(Alignment.Top).width('100%').height('100%').scrollBar(BarState.Off).backgroundColor($r('app.color.app_background'))
  }

  @Builder
  private treeContent(): void {
    Stack() {
      Scroll() {
        Column({ space: 14 }) {
          this.topBar('记忆树', false)
          Text('每条记录都会成为一个可回看的节点。').fontSize(14).fontColor($r('app.color.text_secondary')).width('100%')
          if (this.memories.length === 0) {
            Column({ space: 8 }) {
              Image($r('app.media.empty_memory_illustration')).width(170).height(170).objectFit(ImageFit.Contain)
              Text('还没有记忆').fontSize(17).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
              Button('新建记忆').fontSize(15).fontColor($r('app.color.on_primary')).backgroundColor($r('app.color.primary'))
                .borderRadius(14).margin({ top: 4 }).onClick(() => { this.open(AppRoutes.ADD_MEMORY); })
            }
            .width('100%').padding(24).borderRadius(20).backgroundColor($r('app.color.surface'))
          } else {
            VineTreeCanvas({
              memories: this.memories,
              seed: this.seed,
              hasRecallCards: this.hasRecallCards,
              onLeafSelected: (id: number) => { this.openDetail(id); },
              onRecallCardSelected: () => { this.open(AppRoutes.RECALL_CARD_LIST); }
            })
            Text(`${this.memories.length} 条记忆 · 点击叶片查看详情`).fontSize(13).fontColor($r('app.color.text_secondary'))
          }
        }
        .alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Start).width('100%')
        .padding({ left: 20, right: 20, top: 12, bottom: 96 })
      }
      .align(Alignment.Top).width('100%').height('100%').scrollBar(BarState.Off).backgroundColor($r('app.color.app_background'))

      // 浮动按钮 — 拖动 + 点击
      Column() {
        if (this.generating) {
          LoadingProgress().width(12).height(12).color(Color.White)
        } else {
          Text('✦').fontSize(13).fontColor(Color.White)
        }
      }
      .width(26).height(26)
      .borderRadius(13)
      .backgroundColor('#4CAF50')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .shadow({ radius: 4, color: '#4CAF5080', offsetY: 1 })
      .position({ x: 10, y: 25 })
      .offset({ x: this.btnOffsetX, y: this.btnOffsetY })
      .gesture(
        GestureGroup(GestureMode.Parallel,
          TapGesture({ count: 1 })
            .onAction(() => { this.onGenerateRecall(); }),
          PanGesture({ fingers: 1, distance: 5 })
            .onActionUpdate((event: GestureEvent) => {
              this.btnOffsetX = this.btnOffsetX + event.offsetX;
              this.btnOffsetY = this.btnOffsetY + event.offsetY;
            })
        )
      )
    }
    .width('100%').height('100%')
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.selectedIndex === 0) {
        this.homeContent()
      } else {
        this.treeContent()
      }
      GardenBottomBar({ selectedIndex: this.selectedIndex, onSelected: (index: number) => { this.switchTab(index); } })
        .align(Alignment.Bottom)
    }
    .width('100%').height('100%')
  }
}
