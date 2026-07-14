import { Memory } from '../models/Memory';

@Component
export struct RecentPhotoCard {
  @Prop photos: Memory[] = [];
  onPhotoClick: (memory: Memory) => void = () => {};

  build() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text('📷')
          .fontSize(18)
        Text('最近照片')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Blank()
        if (this.photos.length > 0) {
          Text(`${this.photos.length}张`)
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(10)
            .backgroundColor($r('app.color.accent_gold_soft'))
        }
      }
      .width('100%')

      if (this.photos.length === 0) {
        Row() {
          Column({ space: 6 }) {
            Text('🖼️')
              .fontSize(28)
            Text('暂无照片')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
            Text('记录你的第一张记忆照片吧')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
              .opacity(0.6)
          }
          .width('100%')
          .padding({ top: 20, bottom: 20 })
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .borderRadius(16)
        .backgroundColor($r('app.color.accent_gold_soft'))
        .opacity(0.4)
      } else {
        Scroll() {
          Row({ space: 10 }) {
            ForEach(this.photos, (memory: Memory, index: number) => {
              Stack({ alignContent: Alignment.BottomStart }) {
                Column() {
                  Text('叶')
                    .fontSize(20)
                    .fontColor($r('app.color.primary'))
                    .opacity(0.24)
                }
                .width('100%')
                .height('100%')
                .justifyContent(FlexAlign.Center)
                .backgroundColor($r('app.color.surface'))

                Image(memory.imageUrl)
                  .width(120)
                  .height(150)
                  .borderRadius(14)
                  .objectFit(ImageFit.Cover)
                  .onClick(() => {
                    this.onPhotoClick(memory);
                  })

                // 底部渐变遮罩 + 日期标签
                Column() {
                  Text(memory.date)
                    .fontSize(11)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Medium)
                    .padding({ left: 8, right: 8, top: 3, bottom: 6 })
                }
                .width('100%')
                .borderRadius({ bottomLeft: 14, bottomRight: 14 })
                .linearGradient({
                  direction: GradientDirection.Bottom,
                  colors: [['#00000000', 0], ['#66000000', 1]]
                })
                .alignItems(HorizontalAlign.Start)
              }
              .width(120)
              .height(150)
              .borderRadius(14)
              .shadow({
                radius: 8,
                color: '#20000000',
                offsetX: 0,
                offsetY: 3
              })
            })
          }
          .padding({ left: 2, right: 2, top: 2, bottom: 2 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor($r('app.color.accent_gold_soft'))
  }
}
