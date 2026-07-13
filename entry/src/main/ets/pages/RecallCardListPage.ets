import { RecallCard } from '../models/RecallCard';
import { RecallCardViewModel } from '../viewmodels/RecallCardViewModel';
import { AppRoutes } from '../constants/AppRoutes';
import { BusinessError } from '@kit.BasicServicesKit';

class RecallCardDetailParams {
  title: string = '';
  summary: string = '';
  moodTagList: string[] = [];
  timeRangeStart: string = '';
  timeRangeEnd: string = '';
  memoryCount: number = 0;
}

@Entry
@Component
struct RecallCardListPage {
  @State cards: RecallCard[] = [];
  @State loading: boolean = true;
  @State message: string = '';
  private readonly viewModel: RecallCardViewModel = new RecallCardViewModel();

  aboutToAppear(): void {
    this.loadCards();
  }

  private async loadCards(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      this.message = '无法获取应用上下文';
      this.loading = false;
      return;
    }
    try {
      this.cards = await this.viewModel.list(context);
    } catch (error) {
      this.message = '加载失败，请重试';
    }
    this.loading = false;
  }

  private openDetail(card: RecallCard): void {
    try {
      const params = new RecallCardDetailParams();
      params.title = card.title;
      params.summary = card.summary;
      params.moodTagList = card.getMoodTagList();
      params.timeRangeStart = card.timeRangeStart;
      params.timeRangeEnd = card.timeRangeEnd;
      params.memoryCount = card.memoryCount;
      this.getUIContext().getRouter().pushUrl({
        url: AppRoutes.RECALL_CARD_DETAIL,
        params: params
      }, (error: BusinessError) => {
        if (error) { /* ignore */ }
      });
    } catch (error) { /* ignore */ }
  }

  build() {
    Column() {
      Row({ space: 10 }) {
        Text('‹')
          .fontSize(34)
          .fontWeight(FontWeight.Lighter)
          .fontColor($r('app.color.primary'))
          .onClick(() => { this.getUIContext().getRouter().back(); })
        Text('回忆总结')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 38, bottom: 16 })

      if (this.loading) {
        Column({ space: 16 }) {
          LoadingProgress().width(32).height(32).color($r('app.color.primary'))
          Text('加载中…').fontSize(14).fontColor($r('app.color.text_secondary'))
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.cards.length === 0) {
        Column({ space: 12 }) {
          Text('🌿').fontSize(48)
          Text('还没有回忆总结').fontSize(16).fontColor($r('app.color.text_secondary'))
          Text('在记忆树页面点击绿色按钮生成').fontSize(13).fontColor($r('app.color.text_secondary'))
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.cards, (card: RecallCard) => {
            ListItem() {
              Column({ space: 8 }) {
                Text(card.title)
                  .fontSize(17)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(card.summary)
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Text(card.moodTags.split(',').filter((s: string) => s.length > 0).map((s: string) => `#${s}`).join(' '))
                  .fontSize(11)
                  .fontColor('#2E7D32')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                Row({ space: 6 }) {
                  Text(`${card.timeRangeStart} ~ ${card.timeRangeEnd}`)
                    .fontSize(11)
                    .fontColor($r('app.color.text_secondary'))
                  Text(`${card.memoryCount}条`)
                    .fontSize(11)
                    .fontColor($r('app.color.text_secondary'))
                }
                .width('100%')
              }
              .width('100%')
              .constraintSize({ maxWidth: '100%' })
              .padding(16)
              .borderRadius(14)
              .backgroundColor($r('app.color.surface'))
              .border({ width: 1, color: $r('app.color.outline') })
              .margin({ left: 20, right: 20, top: 6, bottom: 6 })
              .onClick(() => { this.openDetail(card); })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.app_background'))
  }
}
