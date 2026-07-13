import { router } from '@kit.ArkUI';

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
struct RecallCardDetailPage {
  @State title: string = '';
  @State summary: string = '';
  @State moodTagList: string[] = [];
  @State timeRangeStart: string = '';
  @State timeRangeEnd: string = '';
  @State memoryCount: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as RecallCardDetailParams;
    if (params !== null) {
      this.title = params.title;
      this.summary = params.summary;
      this.moodTagList = params.moodTagList;
      this.timeRangeStart = params.timeRangeStart;
      this.timeRangeEnd = params.timeRangeEnd;
      this.memoryCount = params.memoryCount;
    }
  }

  build() {
    Column() {
      Row({ space: 10 }) {
        Text('‹')
          .fontSize(34)
          .fontWeight(FontWeight.Lighter)
          .fontColor($r('app.color.primary'))
          .onClick(() => { router.back(); })
        Text('回忆详情')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 38, bottom: 16 })

      if (this.title.length === 0) {
        Text('卡片不存在').fontSize(14).fontColor($r('app.color.text_secondary'))
          .width('100%').layoutWeight(1).textAlign(TextAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            Text(this.title)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .textAlign(TextAlign.Start)
              .width('100%')

            Row({ space: 6 }) {
              ForEach(this.moodTagList, (tag: string) => {
                Text(tag)
                  .fontSize(12)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor('#E8F5E9')
                  .borderRadius(10)
                  .fontColor('#2E7D32')
              })
            }

            Row({ space: 12 }) {
              Text(`${this.timeRangeStart} ~ ${this.timeRangeEnd}`)
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
              Text('·')
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
              Text(`共 ${this.memoryCount} 条记忆`)
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
            }

            Divider().strokeWidth(0.5).color($r('app.color.outline'))

            Text(this.summary)
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .lineHeight(26)
              .width('100%')
          }
          .width('100%')
          .padding({ left: 24, right: 24, top: 8, bottom: 32 })
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
